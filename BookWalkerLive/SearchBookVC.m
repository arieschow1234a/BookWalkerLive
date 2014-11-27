//
//  SearchBookVC.m
//  BookWalkerLive
//
//  Created by Aries on 18/10/14.
//  Copyright (c) 2014年 Aries. All rights reserved.
//

#import "SearchBookVC.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#include <stdlib.h>
@interface SearchBookVC()<MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    MBProgressHUD *refreshHUD;
}
@property (weak, nonatomic) IBOutlet UILabel *bigHeaderLabel;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UITextField *labelField;
@property (weak, nonatomic) IBOutlet UILabel *peopleLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UILabel *questionLabel;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (strong, nonatomic)NSMutableArray *previousHolderImage;
@property (strong, nonatomic)NSMutableArray *previousHolderId;
@property (strong, nonatomic)NSMutableArray *previousHolderName;
@property (strong, nonatomic)NSMutableArray *transferedAt;
@property (strong, nonatomic)PFObject *book;
@property (weak, nonatomic) IBOutlet UILabel *mindTheseLabel;
@property (weak, nonatomic) IBOutlet UILabel *letterLabel;

//for translate
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;

@end


@implementation SearchBookVC
#define PADDING_TOP 0 // For placing the images nicely in the grid
#define PADDING 50
#define THUMBNAIL_COLS 3
#define THUMBNAIL_WIDTH 150
#define THUMBNAIL_HEIGHT 150

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isChineseSelected"]) {
        self.isChineseSelected = YES;
        [self translation];
    }
    
    [self.navigationController.navigationBar setHidden:YES];
    self.confirmButton.hidden = YES;
    self.questionLabel.hidden = YES;
    self.peopleLabel.hidden = YES;
    self.scrollView.hidden = YES;
    for (id view in self.scrollView.subviews){
        [view removeFromSuperview];
    }
    self.labelField.text = @"";
    self.nextButton.hidden = YES;
    
    if (self.isReturnBook) {
        self.bigHeaderLabel.text = @"Return Books";
    }else{
        self.bigHeaderLabel.text = @"Pick Books";
    }
    if (self.isChineseSelected) {
        self.bigHeaderLabel.text = @"漂書";
    }
}


- (IBAction)searchBook:(id)sender {
    [self.labelField resignFirstResponder];
    self.nextButton.hidden = YES;

    refreshHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:refreshHUD];
    
    // Register for HUD callbacks so we can remove it from the window at the right time
    refreshHUD.delegate = self;
    
    // Show the HUD while the provided method executes in a new thread
    [refreshHUD show:YES];
    
    NSString *label = [self.labelField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([label length] == 0){
        NSString *msg;
        if (self.isChineseSelected) {
            msg = @"請確保你輸入了編碼。";
        }else{
            msg = @"Make sure you enter the code on the label.";
        }
        [self alert:msg];
        
        [refreshHUD hide:YES];

    }else{
        PFQuery *query = [PFQuery queryWithClassName:@"Book"];
        [query whereKey:@"objectId" equalTo:label];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *book, NSError *error) {
            if (error) {
                //Code 101 is no results matched the query
                if ([[error userInfo][@"code"] isEqualToNumber:@101]) {
                    self.mindTheseLabel.hidden = NO;
                    self.letterLabel.hidden = NO;
                    NSString *msg;
                    if (self.isChineseSelected) {
                        msg = @"請確保你輸入了正確的編碼。留意大小寫";
                        self.mindTheseLabel.text = @"常錯組合:";
                    }else{
                        msg = @"Make sure you enter correct number. Mind the capital letter.";
                    }
                    [self alert:msg];
                }
                [refreshHUD hide:YES];
                NSLog(@"Error %@ %@", error, [error userInfo]);
            }else{
                
                if (refreshHUD) {
                    [refreshHUD hide:YES];
                    refreshHUD = [[MBProgressHUD alloc] initWithView:self.view];
                    [self.view addSubview:refreshHUD];
                    refreshHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
                    refreshHUD.mode = MBProgressHUDModeCustomView;
                    refreshHUD.delegate = self;
                }
                
                self.book = book;
                self.previousHolderId = book[@"previousHolderId"] ;
                self.previousHolderName = book[@"previousHolderName"];
                self.transferedAt = book[@"transferedAt"];
                if ([self.previousHolderId count]){
                    self.scrollView.hidden = NO;
                    self.peopleLabel.hidden = NO;
                    NSString *translation;
                    if (self.isChineseSelected) {
                        translation = @"人閱讀過這本書。";
                    }else{
                        translation = @"people have read this book before you.";
                    }
                    
                    self.peopleLabel.text = [NSString stringWithFormat:@"%lu %@", (unsigned long)[self.previousHolderId count], translation];
                    
                    self.questionLabel.hidden = NO;
                    self.confirmButton.hidden = NO;
                    if (self.isReturnBook) {
                        if (self.isChineseSelected) {
                            self.questionLabel.text = @"還書?";
                        }else{
                            self.questionLabel.text = @"Return the book?";
                        }
                    }else{
                        if (self.isChineseSelected) {
                            self.questionLabel.text = @"成為下一位讀者？";
                        }else{
                            self.questionLabel.text = @"Be the next Reader?";
                        }
                    }
                    [self getPreviousHolderImage:self.previousHolderId];
                }
                
            }
        }];

        
    }
    
}

- (void)getPreviousHolderImage:(NSArray *)previousHolderId
{

    PFQuery *query = [PFQuery queryWithClassName:@"UserPhoto"];
    [query whereKey:@"user" containedIn:previousHolderId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.previousHolderImage = [[NSMutableArray alloc]initWithArray:objects];
        }
    }];
    
}

- (void)getPreviousHolderWithId:(NSArray *)previousHolderId
{
        PFQuery *query = [PFUser query];
        [query whereKey:@"objectId" containedIn:previousHolderId];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                self.previousHolderImage = [[NSMutableArray alloc]initWithArray:objects];
            }
        }];

}

#pragma mark - scroll view
- (void)setScrollView:(UIScrollView *)scrollView
{
    _scrollView = scrollView;
    
    // next three lines are necessary for zooming
    //_scrollView.minimumZoomScale = 0.2;
    //_scrollView.maximumZoomScale = 2.0;
    //_scrollView.delegate = self;
    
    // next line is necessary in case self.image gets set before self.scrollView does
    // for example, prepareForSegue:sender: is called before outlet-setting phase
    //self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
}

- (void)setPreviousHolderImage:(NSMutableArray *)previousHolderImage
{
    _previousHolderImage = previousHolderImage;
    [self setJourneyImage];
}

- (void)setJourneyImage
{
    // Adjust scroll view content size, set background colour and turn on paging
    self.automaticallyAdjustsScrollViewInsets = NO;

    int rows = [self.previousHolderId count] / THUMBNAIL_COLS;
    if (((float)[self.previousHolderId count] / THUMBNAIL_COLS) - rows != 0) {
        rows++;
    }
    int height = THUMBNAIL_HEIGHT * rows + PADDING * rows + PADDING + PADDING_TOP;
    
    self.scrollView.contentSize = self.previousHolderImage? CGSizeMake(self.scrollView.frame.size.width, height) : CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height);;
    self.scrollView.clipsToBounds = YES;
    
    // Generate content for our scroll view using the frame height and width as the reference point
    int i = 0;
    while (i < [self.previousHolderId count]) {
        /* Ori
        UIImageView *views = [[UIImageView alloc]
                              initWithFrame:CGRectMake(100, 200*i,
                                                       150, 150)];
        views.backgroundColor = [UIColor yellowColor];
        */
        
        NSString *objectID = self.previousHolderId[i];
        PFObject *reader;
        PFFile *imagefile;
        
        for (PFObject *eachObject in self.previousHolderImage) {
            if ([eachObject[@"user"] isEqualToString:objectID]) {
                reader = eachObject;
            }
        }
        if (reader != nil) {
            imagefile = reader[@"imageFile"];
        }
        
        if (imagefile) {
            [imagefile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                if (!error) {
                    UIImage *image = [UIImage imageWithData:imageData];
                
                    /* Ori
                    views.image = image;
                    [views setTag:i];
                    [views setUserInteractionEnabled:YES];
                    UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapping:)];
                    [singleTap setNumberOfTapsRequired:1];
                    [views addGestureRecognizer:singleTap];
                    */
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    [button setImage:image forState:UIControlStateNormal];
                    button.showsTouchWhenHighlighted = YES;
                    [button addTarget:self action:@selector(buttonTouched:) forControlEvents:UIControlEventTouchUpInside];
                    button.tag = i;
                    button.frame = CGRectMake(THUMBNAIL_WIDTH * (i % THUMBNAIL_COLS) + PADDING * (i % THUMBNAIL_COLS) + PADDING,
                                              THUMBNAIL_HEIGHT * (i / THUMBNAIL_COLS) + PADDING * (i / THUMBNAIL_COLS) + PADDING + PADDING_TOP,
                                              THUMBNAIL_WIDTH,
                                              THUMBNAIL_HEIGHT);
                    button.imageView.contentMode = UIViewContentModeScaleAspectFill;
                    [button setTitle:reader[@"sex"] forState:UIControlStateReserved];
                    [self.scrollView addSubview:button];
                }
            }];
        }
        
        /* Ori
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(300 , 200*i,
                                                                   400, 150)];
        textView.backgroundColor = [UIColor grayColor];
        textView.textAlignment = NSTextAlignmentLeft;
        textView.text = [NSString stringWithFormat:@"Name: %@", self.previousHolderName[i]];
        
        */

        i++;
    }
    if (HUD) {
        //Hide determinate HUD
        [HUD hide:YES];
        
        // Show checkmark
        HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.delegate = self;
    }
}

- (void)buttonTouched:(id)sender {
    int i = [sender tag];
    NSString *sex = [sender titleForState:UIControlStateReserved];
    NSDate* date = self.transferedAt[i];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"dd/MM/yy";
    
    NSString *dateString = [dateFormatter stringFromDate: date];
    NSString *heShe;
    if ([sex isEqualToString:@"M"]) {
        heShe = @"He";
        if (self.isChineseSelected) {
            heShe = @"他";
        }
    }else{
        heShe = @"She";
        if (self.isChineseSelected) {
            heShe = @"她";
        }
    }
    if (self.isChineseSelected) {
            self.peopleLabel.text = [NSString stringWithFormat:@"%@是%@. %@在%@漂出這本書", heShe, self.previousHolderName[i], heShe, dateString];
    }else{
        self.peopleLabel.text = [NSString stringWithFormat:@"%@ is %@. %@ finished reading on %@", heShe, self.previousHolderName[i], heShe, dateString];
    }
}

- (IBAction)reload:(id)sender {
    [self viewDidLoad];
}

#pragma mark - IBAction
- (IBAction)confirm:(id)sender {
    PFUser *currentUser = [PFUser currentUser];
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Uploading";
    [HUD show:YES];
    
    
    if (self.book) {
        NSMutableArray *preHolderName = self.book[@"previousHolderName"];
        NSMutableArray *preHolderId = self.book[@"previousHolderId"];
        NSMutableArray *transferedAt = self.book[@"transferedAt"];
        NSNumber *noOfTransfer = self.book[@"noOfTransfer"];
        
        if (self.isReturnBook) {
            //Everyone can return the book if even he pick it up on the street.
            self.book[@"location"] = @"Oil Street";
            [self.book saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    NSLog(@"Error %@ %@", error, [error userInfo]);
                }else{
                    self.confirmButton.hidden = YES;
                    self.questionLabel.text = @"The book has returned.";
                    if (self.isChineseSelected) {
                        self.questionLabel.text = @"你已完成還書。";
                    }
                    self.nextButton.hidden = NO;
                }
                [HUD hide:YES];
            }];
            
        }else{
            if ([[preHolderId lastObject] isEqual:currentUser.objectId]) {
                [HUD hide:YES];
                NSString *msg;
                if (self.isChineseSelected) {
                    msg = @"你是書本持有人，你不能成為下任漂書者。";
                }else{
                    msg = @"You are the current reader. You can't be the next one.";
                }
                [self alert:msg];
                
                
            }else{
                [preHolderName addObject:currentUser.username];
                [preHolderId addObject:currentUser.objectId];
                [transferedAt addObject:[NSDate date]];
                int transfer = [noOfTransfer intValue] + 1;
                
                self.book[@"previousHolderName"] = preHolderName;
                self.book[@"previousHolderId"] = preHolderId;
                self.book[@"transferedAt"] = transferedAt;
                self.book[@"location"] = @"Out";
                self.book[@"noOfTransfer"] = [NSNumber numberWithInt:transfer];
                [self.book saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        NSLog(@"Error %@ %@", error, [error userInfo]);
                        [HUD hide:YES];
                    }else{
                        //Add the user image to the view
                        self.confirmButton.hidden = YES;
                        
                        self.questionLabel.text = @"You are now the current reader.";
                        if (self.isChineseSelected) {
                            self.questionLabel.text = @"你已成為下任漂書者。";
                        }
                        self.nextButton.hidden = NO;
                        [self getPreviousHolderImage:self.book[@"previousHolderId"]];
                    }
                }];
            }
        }
    }else{
        [HUD hide:YES];
        NSString *msg;
        if (self.isChineseSelected) {
            msg = @"請確保你輸入了編碼。";
        }else{
            msg = @"Make sure you enter the code on the label.";
        }
        [self alert:msg];
    }
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - translation
-(void)translation
{
    self.headerLabel.text = @"請輸入貼紙上的編碼，注意大小寫。特別是小寫l和大寫I。";
    [self.nextButton setTitle:@"下一本書" forState:UIControlStateNormal];
    [self.confirmButton setTitle:@"確認" forState:UIControlStateNormal];
    [self.searchButton setTitle:@"搜尋" forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
}


#pragma mark - Helper methods


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
