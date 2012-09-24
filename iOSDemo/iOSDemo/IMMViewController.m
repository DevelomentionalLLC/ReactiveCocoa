//
//  IMMViewController.m
//  iOSDemo
//
//  Created by Josh Abernathy on 9/24/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "IMMViewController.h"
#import "NSObject+RAC.h"

#define RAC_FANCY - (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key { \
	[self rac_deriveProperty:(NSString *) key from:obj]; \
}

#define RAC(keypath) self[RAC_KEYPATH_SELF(keypath)]

@interface UIButton ()
@property (nonatomic, strong) RACSubscribable *enabled;
@end

@interface IMMViewController ()
@property (nonatomic, weak) IBOutlet UITextField *firstNameField;
@property (nonatomic, weak) IBOutlet UITextField *lastNameField;
@property (nonatomic, weak) IBOutlet UITextField *emailField;
@property (nonatomic, weak) IBOutlet UITextField *reEmailField;
@property (nonatomic, weak) IBOutlet UILabel *errorsLabel;
@property (nonatomic, weak) IBOutlet UIButton *createButton;
@end

@implementation IMMViewController

RAC_FANCY

- (void)viewDidLoad {
    [super viewDidLoad];

	RACSubscribable *allEntriesValid = [RACSubscribable combineLatest:@[ self.firstNameField.rac_textSubscribable, self.lastNameField.rac_textSubscribable, self.emailField.rac_textSubscribable, self.reEmailField.rac_textSubscribable ] reduce:^(RACTuple *xs) {
		NSString *firstName = xs[0];
		NSString *lastName = xs[1];
		NSString *email = xs[2];
		NSString *reEmail = xs[3];
		return @(firstName.length > 0 && lastName.length > 0 && email.length > 0 && reEmail.length > 0 && [email isEqualToString:reEmail]);
	}];

	RAC(self.createButton.enabled) = allEntriesValid;

	UIColor *defaultButtonTitleColor = self.createButton.titleLabel.textColor;
	[self.createButton.rac setTitleColor:(id)[allEntriesValid select:^(NSNumber *x) {
		return x.boolValue ? defaultButtonTitleColor : [UIColor redColor];
	}] forState:UIControlStateNormal];

	self.firstNameField.rac.textColor = (id) [allEntriesValid select:^(NSNumber *x) {
		return x.boolValue ? defaultButtonTitleColor : [UIColor redColor];
	}];

	self.firstNameField.rac.font = (id) [allEntriesValid select:^(NSNumber *x) {
		return x.boolValue ? [UIFont fontWithName:@"Helvetica" size:11.0f] : [UIFont fontWithName:@"Helvetica Bold" size:14.0f];
	}];
}

@end
