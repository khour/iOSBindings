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
    
    KHBindingValueTransformerBlock factor2Transformer = (id)^(id value, BOOL isReverse) {
        if(![value isKindOfClass:[NSNumber class]])
        {
            return value;
        }
        
        double transformedValue = [value doubleValue] * (isReverse ? 0.5 : 2);
        return (id)[NSNumber numberWithDouble:transformedValue];
    };
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:factor2Transformer
                                                        forKey:KHBindingValueTransformerBindingOption];
    
    [foo kh_bind:@"foo" toObject:bar withKeyPath:@"bar" options:options];
    
    bar.bar = 42.0;
    STAssertEqualsWithAccuracy(foo.foo, 84.0, kDoubleAccuracy, @"Directly transformed 42.0 value should be 84.0");
    
    foo.foo = 42.0;
    STAssertEqualsWithAccuracy(bar.bar, 21.0, kDoubleAccuracy, @"Reversely transformed 42.0 value should be 21.0");
    
    [foo kh_unbind:@"foo"];
}

@end
