//
//  NSObject+RAC.m
//  iOSDemo
//
//  Created by Josh Abernathy on 9/24/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "NSObject+RAC.h"

@interface RACCaptureProxy : NSProxy
@property (nonatomic, strong) NSObject *object;
- (id)initWithObject:(NSObject *)object;
@end

@implementation RACCaptureProxy

- (id)initWithObject:(NSObject *)object {
	self.object = object;

	return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	[invocation retainArguments];

	if ([NSStringFromSelector(invocation.selector) hasPrefix:@"set"] && invocation.methodSignature.numberOfArguments == 3) {
		const char *argType = [invocation.methodSignature getArgumentTypeAtIndex:2];
		NSAssert(strcmp(argType, "@") == 0, @"rac proxy only works for object properties.");

		id object = nil;
		[invocation getArgument:&object atIndex:2];
		NSAssert1([object conformsToProtocol:@protocol(RACSubscribable)], @"The new value must conform to RACSubscribable: %@", object);

		id<RACSubscribable> subscribable = object;
		[subscribable subscribeNext:^(id x) {
			[invocation setArgument:&x atIndex:2];
			[invocation invokeWithTarget:self.object];
		}];
		return;
	}

	for (NSUInteger i = 2; i < invocation.methodSignature.numberOfArguments; i++) {
		const char *argType = [invocation.methodSignature getArgumentTypeAtIndex:i];
		if (strcmp(argType, "@") != 0) continue;

		id object = nil;
		[invocation getArgument:&object atIndex:i];
		if ([object conformsToProtocol:@protocol(RACSubscribable)]) {
			id<RACSubscribable> subscribable = object;
			[subscribable subscribeNext:^(id x) {
				[invocation setArgument:&x atIndex:i];
				[invocation invokeWithTarget:self.object];
			}];
		}
	}
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
	return [self.object methodSignatureForSelector:sel];
}

@end

@implementation NSObject (RAC)

- (instancetype)rac {
	return (NSObject *) [[RACCaptureProxy alloc] initWithObject:self];
}

@end
