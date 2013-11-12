// KHBindingTests.m
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

#import "KHBindingTests.h"

#import "NSObject+KHBinding.h"
#import <Foundation/Foundation.h>

static double const kDoubleAccuracy = 0.0000001;

@class Bar;

@interface Foo : NSObject
@property (nonatomic, strong) Bar *bar;
@property (nonatomic, assign) double foo;
@end

@implementation Foo
@end

@interface Bar : NSObject
@property (nonatomic, assign) double bar;
@end

@implementation Bar
@end


@implementation KHBindingTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testBasicFunctionalityAndValueTransforming
{
    Foo *foo = [Foo new];
    Bar *bar = [Bar new];
    
    KHBindingValueTransformerBlock factor2Transformer = (id)^(id value, BOOL isDirect) {
        if(![value isKindOfClass:[NSNumber class]])
        {
            return value;
        }
        
        double transformedValue = [value doubleValue] * (isDirect ? 2 : 0.5);
        return (id)@(transformedValue);
    };
    
    NSDictionary *options = @{ KHBindingOptionValueTransformerKey: factor2Transformer,
                               KHBindingOptionNullPlaceholderKey: @265.0 };
    
    [foo kh_bind:@"foo" toObject:bar withKeyPath:@"bar" options:options];
    
    bar.bar = 42.0;
    STAssertEqualsWithAccuracy(foo.foo, 84.0, kDoubleAccuracy, @"Directly transformed 42.0 value should be 84.0");
    
    foo.foo = 42.0;
    STAssertEqualsWithAccuracy(bar.bar, 21.0, kDoubleAccuracy, @"Reversely transformed 42.0 value should be 21.0");
    
    [foo kh_unbind:@"foo"];
}

- (void)testNilSetting
{
    Foo *foo = [Foo new];
    foo.bar = [Bar new];
    Bar *bar = [Bar new];
    
    [bar kh_bind:@"bar" toObject:foo withKeyPath:@"bar.bar" options:nil];
    foo.bar.bar = 42;
    
    STAssertEqualsWithAccuracy(bar.bar, 42.0, kDoubleAccuracy, @"Binded value should be 42.0");
    
    // this will try to set bar.bar with boxed foo.bar.bar, which will be NSNull
    // so expect a throw here
    STAssertThrows(foo.bar = nil, @"");
    
    [bar kh_unbind:@"bar"];
}

- (void)testDirectWayOnlyOption
{
    Foo *foo = [Foo new];
    Bar *bar = [Bar new];
    
    foo.foo = 1.0;
    bar.bar = 2.0;
    
    NSDictionary *options = @{ KHBindingOptionDirectOnlyKey : @YES };
    
    [foo kh_bind:@"foo" toObject:bar withKeyPath:@"bar" options:options];
    
    bar.bar = 42.0;
    STAssertEqualsWithAccuracy(foo.foo, 42.0, kDoubleAccuracy, @"Binded value should be 42.0");
    
    foo.foo = 265.0;
    STAssertEqualsWithAccuracy(bar.bar, 42.0, kDoubleAccuracy, @"One-way binded value of the source should be unchanged 42.0");
    
    [foo kh_unbind:@"foo"];
    
    options = @{ KHBindingOptionDirectOnlyKey : @NO };
    
    [foo kh_bind:@"foo" toObject:bar withKeyPath:@"bar" options:options];
    
    bar.bar = 42.0;
    STAssertEqualsWithAccuracy(foo.foo, 42.0, kDoubleAccuracy, @"Binded value should be 42.0");
    
    foo.foo = 265.0;
    STAssertEqualsWithAccuracy(bar.bar, 265.0, kDoubleAccuracy, @"Binded value should be 265.0");
    
    [foo kh_unbind:@"foo"];
}

@end
