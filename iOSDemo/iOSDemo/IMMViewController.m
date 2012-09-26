//
//  IMMViewController.m
//  iOSDemo
//
//  Created by Josh Abernathy on 9/24/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "IMMViewController.h"
#import "NSObject+RAC.h"
#import "RACSubscriptingAssignmentTrampoline.h"

@interface IMMViewController ()
@property (nonatomic, weak) IBOutlet UITextField *firstNameField;
@property (nonatomic, weak) IBOutlet UITextField *lastNameField;
@property (nonatomic, weak) IBOutlet UITextField *emailField;
@property (nonatomic, weak) IBOutlet UITextField *reEmailField;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UIButton *createButton;
@property (nonatomic, assign) BOOL processing;
@property (nonatomic, strong) NSError *error;
@end

@implementation IMMViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	srand(time(NULL));

	RACSubscribable *allEntriesValid = [RACSubscribable combineLatest:@[ self.firstNameField.rac_textSubscribable, self.lastNameField.rac_textSubscribable, self.emailField.rac_textSubscribable, self.reEmailField.rac_textSubscribable ] reduce:^(RACTuple *xs) {
		NSString *firstName = xs[0];
		NSString *lastName = xs[1];
		NSString *email = xs[2];
		NSString *reEmail = xs[3];
		return @(firstName.length > 0 && lastName.length > 0 && email.length > 0 && reEmail.length > 0 && [email isEqualToString:reEmail]);
	}];

	RACSubscribable *processing = RACAbleSelf(self.processing);

	RACSubscribable *buttonEnabled = [RACSubscribable combineLatest:@[ processing, allEntriesValid ] reduce:^(RACTuple *xs) {
		BOOL processing = [xs[0] boolValue];
		BOOL valid = [xs[1] boolValue];
		return @(!processing && valid);
	}];

	RAC(self.createButton.enabled) = buttonEnabled;
	
	UIColor *defaultButtonTitleColor = self.createButton.titleLabel.textColor;
	id buttonTextColor = [buttonEnabled select:^(NSNumber *x) {
		return x.boolValue ? defaultButtonTitleColor : [UIColor lightGrayColor];
	}];

	[self.createButton.rac setTitleColor:buttonTextColor forState:UIControlStateNormal];
	
	RACSubscribable *labelColor = [processing select:^(NSNumber *x) {
		return x.boolValue ? [UIColor lightGrayColor] : [UIColor blackColor];
	}];

	RAC(self.firstNameField.textColor) = labelColor;
	RAC(self.lastNameField.textColor) = labelColor;
	RAC(self.emailField.textColor) = labelColor;
	RAC(self.reEmailField.textColor) = labelColor;

	RACSubscribable *notProcessing = [processing select:^(NSNumber *x) {
		return @(!x.boolValue);
	}];
	
	RAC(self.firstNameField.enabled) = notProcessing;
	RAC(self.lastNameField.enabled) = notProcessing;
	RAC(self.emailField.enabled) = notProcessing;
	RAC(self.reEmailField.enabled) = notProcessing;

//	[notProcessing toProperty:RAC_KEYPATH_SELF(self.emailField.enabled) onObject:self];

	RACSubscribable *submit = [self.createButton rac_subscribableForControlEvents:UIControlEventTouchUpInside];
	RACSubscribable *submitCount = [[RACSubscribable combineLatest:@[ submit, [[processing skip:1] where:^BOOL(id x) { return ![x boolValue]; }] ]] foldWithStart:@0 combine:^(NSNumber *running, id next) {
		return @(running.integerValue + 1);
	}];

	RAC(self.statusLabel.hidden) = [[submitCount doNext:^(id x) {
		
	}] select:^(NSNumber *x) {
		return @(x.integerValue < 1);
	}];

	RACSubscribable *error = RACAbleSelf(self.error);
	
	RAC(self.statusLabel.text) = [error select:^(id x) {
		return x != nil ? NSLocalizedString(@"An error occurred", @"") : NSLocalizedString(@"You're good!", @"");
	}];
	RAC(self.statusLabel.textColor) = [error select:^id(id x) {
		return x != nil ? [UIColor redColor] : [UIColor greenColor];
	}];

	[processing subscribeNext:^(NSNumber *x) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:x.boolValue];
	}];

	self.error = nil;
	self.processing = NO;

	__weak id weakSelf = self;
	[submit subscribeNext:^(id _) {
		IMMViewController *strongSelf = weakSelf;
		strongSelf.processing = YES;
		
		[[[strongSelf doSomeNetworkStuff] finally:^{
			strongSelf.processing = NO;
		}] subscribeNext:^(id x) {
			strongSelf.error = nil;
		} error:^(NSError *error) {
			strongSelf.error = error;
		}];
	}];


	[repository updateStatus:^(id x) {
		[repository updateBranch:^(id x) {
			
		}];
	}];

	[[[repository updateStatus] sequenceNext:^{
		return [repository updateBranch];
	}] sequenceNext:^{
		return [repository pushBranch];
	}];

	[[[[[error select:^id(id x) {

	}] where:^BOOL(id x) {

	}] foldWithStart:nil combine:^id(id running, id next) {

	}] deliverOn:[RACScheduler backgroundScheduler]] subscribeNext:^(id x) {

	} completed:^{

	}];
}

- (RACSubscribable *)doSomeNetworkStuff {
	return [[[RACSubscribable interval:3.0f] take:1] selectMany:^(id _) {
		int r = rand() % 2;
		NSLog(@"%d", r);
		BOOL success = r;
		return success ? [RACSubscribable return:[RACUnit defaultUnit]] : [RACSubscribable error:[NSError errorWithDomain:@"" code:0 userInfo:nil]];
	}];
}

@end
