//
//  BWViewController.m
//  BookWalkerLive
//
//  Created by Aries on 20/9/14.
//  Copyright (c) 2014年 Aries. All rights reserved.
//

#import "LeaveBookVC.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#include <stdlib.h>

@interface LeaveBookVC ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    MBProgressHUD *refreshHUD;
}

@property (weak, nonatomic) IBOutlet UITextField *bookNumberField;
@property (weak, nonatomic) IBOutlet UIView *labelView;
@property (weak, nonatomic) IBOutlet UILabel *reminderLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalBooksLabel;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;

@property (strong, nonatomic) NSMutableArray *labels;

//for translate
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UILabel *questionLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) NSString *bookChinese;

@end

@implementation LeaveBookVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.navigationBar setHidden:YES];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isChineseSelected"]) {
        [self translation];
    }
    self.bookChinese = @"書本";
    if (self.totalBooks) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isChineseSelected"]) {
                self.totalBooksLabel.text = [NSString stringWithFormat:@"%@: %@",self.bookChinese, self.totalBooks];
        }else{
            self.totalBooksLabel.text = [NSString stringWithFormat:@"Books: %@", self.totalBooks];
        }
    }
    self.submitButton.hidden = NO;
    self.bookNumberField.enabled = YES;
    self.bookNumberField.text = @"";
    self.doneButton.hidden = YES;
    self.moreButton.hidden = YES;
    self.reminderLabel.hidden = YES;
    for (id view in self.labelView.subviews){
        [view removeFromSuperview];
    }
    self.labelView.hidden = YES;
    
}

- (IBAction)logout:(id)sender
{
    [PFUser logOut];
    [self performSegueWithIdentifier:@"Show LogIn" sender:self];
}

- (IBAction)submit:(id)sender {
    PFUser *currentUser = [PFUser currentUser];
    
    [self.bookNumberField resignFirstResponder];
    NSString *bookNumber = self.bookNumberField.text;
    int number = [self.bookNumberField.text intValue];
    //TO-DO: Check if booknumber start with contain alphabet NSscanner
    if ([bookNumber length] == 0 || number <= 0){
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isChineseSelected"]) {
            [self alert:@"請確保輸入數字。"];
        }else{
            [self alert:@"Make sure you enter the number"];
        }
    }else if(number > 40){
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isChineseSelected"]) {
            [self alert:@"請輸入少於40。"];
        }else{
            [self alert:@"Please enter a number smaller than 40"];
        }
    }else{
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        // Set determinate mode
        HUD.mode = MBProgressHUDModeDeterminate;
        HUD.delegate = self;
        HUD.labelText = @"Uploading";
        [HUD show:YES];
        
        //Change the totalBooksLabel
        int newTotal = number + [self.totalBooks intValue];
        self.totalBooksLabel.text = [NSString stringWithFormat:@"Books: %d", newTotal];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isChineseSelected"]) {
            self.totalBooksLabel.text = [NSString stringWithFormat:@"%@: %d",self.bookChinese, newTotal];
        }
        self.totalBooks = [NSNumber numberWithInt:newTotal];
        
        //handle submit button
        self.submitButton.hidden = YES;
        self.bookNumberField.enabled = NO;
        
        //Line the label
        int i = 0;
        int numberOfLine = (number-1)/4 + 1;
        int left = number % 4;
        int itemNumber =4;
        //NSLog(@"%d",numberOfLine);
        //NSLog(@"%d",left);
        for (int b = 0; b < numberOfLine; b++){
            if (b == numberOfLine-1 && left > 0) {
                itemNumber = left;
            }
            while (i < itemNumber) {
                NSArray *preHolderName = @[currentUser.username];
                NSArray *preHolderId = @[currentUser.objectId];
                NSArray *transferedAt = @[[NSDate date]];
                
                PFObject *book = [PFObject objectWithClassName:@"Book"];
                book[@"noOfTransfer"] = @0;
                book[@"previousHolderName"] = preHolderName;
                book[@"previousHolderId"] = preHolderId;
                book[@"transferedAt"] = transferedAt;
                book[@"location"] = @"Oil Street";
                
                [book saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        //NSLog(@"Done");
                        [self.labels addObject:book.objectId];
                        self.reminderLabel.hidden = NO;
                        UILabel *label;
                        label = [[UILabel alloc] initWithFrame:CGRectMake((self.labelView.frame.size.width/ 4) *i , 50*b,
                                                                              (self.labelView.frame.size.width/ 4) - 10, 40)];
                        
                        label.backgroundColor = [UIColor yellowColor];
                        label.textAlignment = NSTextAlignmentCenter;
                        label.text = book.objectId;
                        [self.labelView addSubview:label];
                    }else{
                        NSLog(@"Error %@ %@", error, [error userInfo]);
                        [HUD hide:YES];
                    }
                }];
                i++;
            }
            i = 0;
        }
        self.labelView.hidden = NO;
        self.doneButton.hidden = NO;
        self.moreButton.hidden = NO;
        [HUD hide:YES];
    }
}
- (IBAction)done:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];

}
- (IBAction)cancel:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)more:(id)sender {
    [self viewDidLoad];
}

#pragma mark - translation
-(void)translation
{
    self.headerLabel.text = @"放書";
    self.questionLabel.text = @"你會漂出多少本書？";
    self.reminderLabel.text = @"請將條碼寫在貼紙上，並貼到書本。";
    [self.submitButton setTitle:@"提交" forState:UIControlStateNormal];
    [self.moreButton setTitle:@"更多書本" forState:UIControlStateNormal];
    [self.doneButton setTitle:@"完成" forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
}

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






















