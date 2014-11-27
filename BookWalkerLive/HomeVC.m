//
//  HomeVC.m
//  BookWalkerLive
//
//  Created by Aries on 20/10/14.
//  Copyright (c) 2014年 Aries. All rights reserved.
//

#import "HomeVC.h"
#import <Parse/Parse.h>
#import "LeaveBookVC.h"
#import "SearchBookVC.h"
#import "MBProgressHUD.h"
#include <stdlib.h>

@interface HomeVC ()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    MBProgressHUD *refreshHUD;
}
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UILabel *readerNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *hereNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *outsideNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *hiLabel;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *leaveButton;
@property (weak, nonatomic) IBOutlet UIButton *pickButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;

@property (weak, nonatomic) IBOutlet UIButton *englishButton;
@property (weak, nonatomic) IBOutlet UIButton *chineseButton;


@property (strong, nonatomic) NSNumber *totalBooks;
@property (strong, nonatomic) NSNumber *booksHere;
@property (strong, nonatomic) NSNumber *readerNumber;

//for translate
@property (nonatomic) BOOL isChineseSelected;
@property (weak, nonatomic) IBOutlet UILabel *hereLabel;
@property (weak, nonatomic) IBOutlet UILabel *outsideLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;

@end

@implementation HomeVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isChineseSelected"]) {
        [self translation];
        self.isChineseSelected = YES;
    }
}





- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser) {
        self.loginButton.hidden = YES;
        self.logoutButton.hidden = NO;
        self.leaveButton.hidden = NO;
        self.returnButton.hidden = NO;
        self.pickButton.hidden = NO;
        self.hiLabel.text = [NSString stringWithFormat:@"Hello %@!", currentUser[@"name"]];
    }else{
        self.loginButton.hidden = NO;
        self.leaveButton.hidden = YES;
        self.pickButton.hidden = YES;
        self.returnButton.hidden = YES;
        self.logoutButton.hidden = YES;
    }
    [self fetchNumber];
}


- (IBAction)logOut:(id)sender {
    [PFUser logOut];
    self.logoutButton.hidden = YES;
    self.loginButton.hidden = NO;
    self.leaveButton.hidden = YES;
    self.pickButton.hidden = YES;
    self.returnButton.hidden = YES;
    self.hiLabel.text = @"";
    [self translation];
}


- (void)fetchNumber{
    refreshHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:refreshHUD];
    
    // Register for HUD callbacks so we can remove it from the window at the right time
    refreshHUD.delegate = self;
    
    // Show the HUD while the provided method executes in a new thread
    [refreshHUD show:YES];

    
    PFQuery *bookQuery = [PFQuery queryWithClassName:@"Book"];
    [bookQuery countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (!error) {
            self.totalBooks = [NSNumber numberWithInt:count];
            NSString *totalBooks = [NSString stringWithFormat:@"%d", count];
            self.totalNumberLabel.text = totalBooks;
            self.totalBooks = [NSNumber numberWithInt:count];
            [refreshHUD hide:YES];
            
            PFQuery *booksOutQuery = [PFQuery queryWithClassName:@"Book"];
            [booksOutQuery whereKey:@"location" equalTo:@"Out"];
            [booksOutQuery countObjectsInBackgroundWithBlock:^(int outside, NSError *error) {
                if (!error) {
                    self.outsideNumberLabel.text = [NSString stringWithFormat:@"%d", outside];
                    int total = [self.totalBooks intValue];
                    self.hereNumberLabel.text = [NSString stringWithFormat:@"%d", total - outside];
                    [refreshHUD hide:YES];
                    [self fetchReader];
                } else {
                    NSLog(@"Error %@ %@", error, [error userInfo]);
                    [refreshHUD hide:YES];
                }
            }];
        } else {
            NSLog(@"Error %@ %@", error, [error userInfo]);
            [refreshHUD hide:YES];
        }
    }];
    
    /*
    PFQuery *booksHereQuery = [PFQuery queryWithClassName:@"Book"];
    [booksHereQuery whereKey:@"location" equalTo:@"Oil Street"];
    [booksHereQuery countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (!error) {
            self.booksHere = [NSNumber numberWithInt:count];
            self.hereNumberLabel.text = [NSString stringWithFormat:@"%d", count];
        } else {
            // The request failed
        }
    }];
    */
    
}

- (void)fetchReader
{
    PFQuery *query = [PFUser query];
    [query countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (!error) {
            self.readerNumber = [NSNumber numberWithInt: count];
            NSString *readerString = [NSString stringWithFormat:@"%d readers have joined this game!", count];
            if (self.isChineseSelected) {
                readerString = [NSString stringWithFormat:@"現在有%d位漂書者參加這活動！", count];
            }
            self.readerNumberLabel.text = readerString;
            [refreshHUD hide:YES];
        } else {
            NSLog(@"Error %@ %@", error, [error userInfo]);
            [refreshHUD hide:YES];
        }
    }];
}

- (IBAction)chineseSelected:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isChineseSelected"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self translation];
    self.isChineseSelected = YES;

}
- (IBAction)englishSelected:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isChineseSelected"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self translation];
    self.isChineseSelected = NO;

}

- (void)translation
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isChineseSelected"]) {
        self.headerLabel.text = @"歡迎來到閱行者自助漂書";
        self.hereLabel.text = @"現場書本:";
        self.outsideLabel.text = @"在外書本:";
        self.totalLabel.text = @"合共:";
        self.readerNumberLabel.text = [NSString stringWithFormat:@"現在有%@漂書者參加這活動！", self.readerNumber];
        [self.pickButton setTitle:@"取書" forState:UIControlStateNormal];
        [self.leaveButton setTitle:@"放書" forState:UIControlStateNormal];
        [self.returnButton setTitle:@"還書" forState:UIControlStateNormal];
        [self.loginButton setTitle:@"開始" forState:UIControlStateNormal];
        [self.logoutButton setTitle:@"登出" forState:UIControlStateNormal];
        
    }else{
        self.headerLabel.text = @"Welcome to BookWalker Zone";
        self.hereLabel.text = @"Books here:";
        self.outsideLabel.text = @"Books outside";
        self.totalLabel.text = @"Total:";
        self.readerNumberLabel.text = [NSString stringWithFormat:@"%@ readers have joined this game!", self.readerNumber];
        [self.pickButton setTitle:@"Pick Books" forState:UIControlStateNormal];
        [self.leaveButton setTitle:@"Leave Books" forState:UIControlStateNormal];
        [self.returnButton setTitle:@"Return Books" forState:UIControlStateNormal];
        [self.loginButton setTitle:@"Let's Start" forState:UIControlStateNormal];
        [self.logoutButton setTitle:@"Log Out" forState:UIControlStateNormal];
    }
}


#pragma mark - navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    if([segue.identifier isEqualToString:@"Leave Book"]){
        LeaveBookVC *lbvc = (LeaveBookVC *)segue.destinationViewController;
        if (self.totalBooks) {
            lbvc.totalBooks = self.totalBooks;
        }
    }else if ([segue.identifier isEqualToString:@"Return Book"]){
        SearchBookVC *sbvc = (SearchBookVC *)segue.destinationViewController;
        sbvc.isReturnBook = YES;
    
    }else if ([segue.identifier isEqualToString:@"Pick Book"]){
        SearchBookVC *sbvc = (SearchBookVC *)segue.destinationViewController;
        sbvc.isReturnBook = NO;
    }
}









@end
