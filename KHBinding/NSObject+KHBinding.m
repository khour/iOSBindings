// NSObject+KHBinding.m
//
// Copyright (c) 2013 Alexander Nazarenko
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "NSObject+KHBinding.h"
#import <objc/runtime.h>

static void * const __KHBindingHelperContextDirect = (void *)&__KHBindingHelperContextDirect;
static void * const __KHBindingHelperContextReverse = (void *)&__KHBindingHelperContextReverse;
static void * const __KHBindingDictionaryKey = (void *)&__KHBindingDictionaryKey;

NSString * const KHBindingValueTransformerBindingOption = @"KHValueTransformerBindingOption";

NSString * const KHBindingObservedObjectKey = @"KHBindingObservedObjectKey";
NSString * const KHBindingObservedKeyPathKey = @"KHBindingObservedKeyPathKey";
NSString * const KHBindingOptionsKey = @"KHBindingOptionsKey";

@interface __KHBindingHelper : NSObject

@property (nonatomic, weak) id object;
@property (nonatomic, strong) NSString *binding;
@property (nonatomic, weak) id target;
@property (nonatomic, strong) NSString *keyPath;
@property (nonatomic, strong) NSDictionary *options;

- (id)initWithObject:(id)object binding:(NSString *)binding target:(id)target keyPath:(id)keyPath options:(NSDictionary *)options;

@end


@interface __KHBindingHelperWithStubKVO : __KHBindingHelper
@end
@implementation __KHBindingHelperWithStubKVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // stub method to ignore a recursive `observeValueForKeyPath:ofObject:change:context:` call from below
    // the only way codeflow gets here is from the same method of __KHBindingHelper
    NSAssert([self class] == [__KHBindingHelperWithStubKVO class], @"Unexpected class %@ instead of %@, \nBacktrace:\n%@", [self class], [__KHBindingHelper class], [NSThread callStackSymbols]);
}
@end


@implementation __KHBindingHelper

- (id)initWithObject:(id)object binding:(NSString *)binding target:(id)target keyPath:(id)keyPath options:(NSDictionary *)options
{
    if ((self = [super init]))
    {
        _object = object;
        _binding = [binding copy];
        _target = target;
        _keyPath = [keyPath copy];
        _options = [options copy];
        
        [_target addObserver:self forKeyPath:_keyPath options:NSKeyValueObservingOptionNew context:__KHBindingHelperContextDirect];
        [_object addObserver:self forKeyPath:_binding options:NSKeyValueObservingOptionNew context:__KHBindingHelperContextReverse];
    }
    
    return self;
}

- (id)processedValue:(id)value usingOptions:(NSDictionary *)options reverse:(BOOL)isReverse
{
    // TODO: implement other options
    
    KHBindingValueTransformerBlock transformer = [options objectForKey:KHBindingValueTransformerBindingOption];
    if (transformer)
    {
        value = transformer(value, isReverse);
    }
    return value;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != __KHBindingHelperContextDirect && context != __KHBindingHelperContextReverse)
    {
        // not gonna happen, but a bit of safecoding won't hurt
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    // get right object and keyPath to set the observed value to
    // since this observation could come from either `_object` or `_target`
    BOOL isDirect = (context == __KHBindingHelperContextDirect);
    id destinationObject = (isDirect) ? _object : _target;
    NSString *destinationKeyPath = (isDirect) ? _binding : _keyPath;
    
    // retrieve new value and apply rules specified in `options` to it
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    newValue = [self processedValue:newValue usingOptions:_options reverse:!isDirect];
    if(newValue == [NSNull null])
    {
        // graceful fallback
        newValue = nil;
    }
    
    // this will trigger a recursive `observeValueForKeyPath:ofObject:change:context:` call,
    // which will be ignored thanks to self isa switch
    // @synchronized is here to ensure the thread-safety
    @synchronized (self)
    {
        object_setClass(self, [__KHBindingHelperWithStubKVO class]);
        @try {
            [destinationObject setValue:newValue forKeyPath:destinationKeyPath];
        }
        @catch (NSException *exception) {
            // eyecandy for exception display (include backtrace with it)
            [NSException raise:exception.name format:@"%@\nBacktrace:\n%@", exception.reason, [NSThread callStackSymbols]];
        }
        
        object_setClass(self, [__KHBindingHelper class]);
    }
}

- (void)dealloc
{
    [_target removeObserver:self forKeyPath:_keyPath context:__KHBindingHelperContextDirect];
    [_object removeObserver:self forKeyPath:_binding context:__KHBindingHelperContextReverse];
}

@end

@implementation NSObject (KHBinding)

- (void)kh_bind:(NSString *)binding toObject:(id)target withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
    NSAssert(binding, @"Binding cannot be nil\nBacktrace:\n%@", [NSThread callStackSymbols]);
    NSAssert(target, @"Target cannot be nil\nBacktrace:\n%@", [NSThread callStackSymbols]);
    NSAssert(keyPath, @"KeyPath cannot be nil\nBacktrace:\n%@", [NSThread callStackSymbols]);
    @synchronized (self)
    {
        NSMutableDictionary *helpers = objc_getAssociatedObject(self, __KHBindingDictionaryKey);
        if (!helpers)
        {
            helpers = [NSMutableDictionary new];
            objc_setAssociatedObject(self, __KHBindingDictionaryKey, helpers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        __KHBindingHelper *helper = [helpers objectForKey:binding];
        
        NSAssert(!helper, @"Binding %@ already exists for %@\nBacktrace:\n%@", binding, self, [NSThread callStackSymbols]);
        
        helper = [[__KHBindingHelper alloc] initWithObject:self binding:binding target:target keyPath:keyPath options:options];
        [helpers setObject:helper forKey:binding];
    }
}

- (void)kh_unbind:(NSString *)binding
{
    @synchronized (self)
    {
        NSMutableDictionary *helpers = objc_getAssociatedObject(self, __KHBindingDictionaryKey);
        __KHBindingHelper *helper = [helpers objectForKey:binding];
        
        NSAssert(helper, @"Trying to unbind unexisting binding %@ for %@\nBacktrace:\n%@", binding, self, [NSThread callStackSymbols]);
        
        [helpers removeObjectForKey:binding];
    }
}

- (NSDictionary *)kh_bindingsInfo
{
    NSMutableDictionary *helpers = objc_getAssociatedObject(self, __KHBindingDictionaryKey);
    NSMutableDictionary *bindingsInfo = [NSMutableDictionary dictionaryWithCapacity:helpers.count];
    for (__KHBindingHelper *helper in helpers.allValues)
    {
        NSDictionary *bindingInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                     helper.target, KHBindingObservedObjectKey,
                                     helper.keyPath, KHBindingObservedKeyPathKey,
                                     [NSDictionary dictionaryWithDictionary:helper.options], KHBindingOptionsKey,
                                     nil];
        
        [bindingsInfo setObject:bindingInfo forKey:helper.binding];
    }
    
    return bindingsInfo;
}

@end
