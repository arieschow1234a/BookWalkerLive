//
//  LoginViewController.h
//  Ribbit
//
//  Created by Aries on 5/5/14.
//  Copyright (c) 2014年 Aries. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController 
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;


- (IBAction)logIn:(id)sender;



@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

@end
