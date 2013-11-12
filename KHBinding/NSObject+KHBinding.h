// NSObject+KHBinding.h
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

#import <Foundation/Foundation.h>

/**
 * Binding option: value transformer key
 * Passed object should be a block of type `KHBindingValueTransformerBlock`
 */
extern NSString * const KHBindingOptionValueTransformerKey;
typedef id (^KHBindingValueTransformerBlock)(id value, BOOL isReverse);

/**
 * Binding option: null placeholder key
 * Used when binded value is set to `nil`. Should be any object of type `id`
 */
extern NSString * const KHBindingOptionNullPlaceholderKey;

/**
 * Binding option: direct only
 * Used to specify that the binding works only in direct way (source -> target)
 * Should be a NSNumber constucted from BOOL
 * When no specified or specified with NO then binding is bidirectional
 */
extern NSString * const KHBindingOptionDirectOnlyKey;


/**
 * Keys used in a dictionary returned by kh_bindingsInfo
 */
extern NSString * const KHBindingObservedObjectKey;
extern NSString * const KHBindingObservedKeyPathKey;
extern NSString * const KHBindingOptionsKey;


/**
 * Transparent category that allows Cocoa-like bindings for iOS Foundation
 */
@interface NSObject (KHBinding)

// Binds `self.binding` to `target.keyPath` using the specified options
// For the list of available options see above
- (void)kh_bind:(NSString *)binding toObject:(NSObject *)target withKeyPath:(NSString *)keyPath options:(NSDictionary *)options;

// Unbinds the object from the specified binding
- (void)kh_unbind:(NSString *)binding;

// Information about all the bindings that are registered on the object
- (NSDictionary *)kh_bindingsInfo;

@end
