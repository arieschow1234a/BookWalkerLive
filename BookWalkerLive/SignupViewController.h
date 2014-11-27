//
//  SignupViewController.h
//  Ribbit
//
//  Created by Aries on 5/5/14.
//  Copyright (c) 2014年 Aries. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupViewController : UIViewController


@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *email;


- (IBAction)signUp:(id)sender;
- (IBAction)cancel:(id)sender;


@end
