//
//  LoginViewController.m
//  Ribbit
//
//  Created by Aries on 5/5/14.
//  Copyright (c) 2014年 Aries. All rights reserved.
//

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "TPKeyboardAvoidingScrollView.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollView;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *imageURL;

//For translate
@property (weak, nonatomic) IBOutlet UILabel *noAccountLabel;
@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (nonatomic) BOOL isChineseSelected;


@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isChineseSelected"]) {
        [self translation];
        self.isChineseSelected = YES;

    }
    // hide the nav bar
    [self.navigationController.navigationBar setHidden:YES];
    self.activityIndicator.hidden = YES;
    //if ([UIScreen mainScreen].bounds.size.height == 568 ) {
    //    self.backgroundImageView.image = [UIImage imageNamed:@"loginBackground-568h"];
   // }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - normal Login
- (IBAction)logIn:(id)sender {
    
    NSString *username = [self.usernameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *email = [self.emailField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([username length] == 0 || [email length] == 0){
        if (self.isChineseSelected) {
            [self alert:@"請確保你輸入了名稱及電郵。"];
        }else{
            [self alert:@"Make sure you enter a username & email address"];
        }
    }else{
        [PFUser logInWithUsernameInBackground:username password:@"1234" block:^(PFUser *user, NSError *error) {
            if (error) {
                [self alert:[error userInfo][@"error"]];
            }else{
                if ([user.email isEqualToString:email]) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }else{
                    [PFUser logOut];
                    if (self.isChineseSelected) {
                        [self alert:@"請確保你輸入正確的電郵。"];
                    }else{
                        [self alert:@"Make sure you enter a corrent email"];
                    }
                }
            }
        }];
    }
}

#pragma mark - translation
-(void)translation
{
    self.noAccountLabel.text = @"沒有帳戶？";
    [self.logInButton setTitle:@"登入" forState:UIControlStateNormal];
    [self.signUpButton setTitle:@"註冊" forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
}

#pragma mark - Alerts

- (void)alert:(NSString *)msg
{
    NSString *sorry;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isChineseSelected"]) {
        sorry = @"不好意思";
    }else{
        sorry = @"Sorry";
    }
    
    [[[UIAlertView alloc] initWithTitle:sorry
                                message:msg
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
}



@end
