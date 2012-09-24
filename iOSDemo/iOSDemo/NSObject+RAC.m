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
	if ([NSStringFromSelector(invocation.selector) hasPrefix:@"set"] && invocation.methodSignature.numberOfArguments == 3) {
		id object = nil;
		[invocation getArgument:&object atIndex:2];
		NSAssert1([object conformsToProtocol:@protocol(RACSubscribable)], @"The new value must conform to RACSubscribable: %@", object);

		id<RACSubscribable> subscribable = object;
		[subscribable subscribeNext:^(id x) {
			const char *argType = [invocation.methodSignature getArgumentTypeAtIndex:2];
			if (strcmp(argType, "c") == 0) {
				char c = [x charValue];
				[invocation setArgument:&c atIndex:2];
			} else if (strcmp(argType, "@") == 0) {
				[invocation setArgument:&x atIndex:2];
			}

			[invocation invokeWithTarget:self.object];
		}];
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
	NSMethodSignature *signature = [self.object methodSignatureForSelector:sel];
	if ([NSStringFromSelector(sel) hasPrefix:@"set"] && signature.numberOfArguments == 3) {
		const char *argType = [signature getArgumentTypeAtIndex:2];
		if (strcmp(argType, "@") != 0) {
			NSString *typeSig = [NSString stringWithFormat: @"%s%s%s%s",
								 @encode(void),
								 @encode(id), @encode(SEL),
								 @encode(id)];
			NSLog(@"%@", typeSig);
			return [NSMethodSignature signatureWithObjCTypes:"v12@0:4@8"];//[typeSig UTF8String]];
		}
	}

	return signature;
}

@end

@implementation NSObject (RAC)

- (instancetype)rac {
	return (NSObject *) [[RACCaptureProxy alloc] initWithObject:self];
}

@end
