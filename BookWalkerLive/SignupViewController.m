//
//  SignupViewController.m
//  Ribbit
//
//  Created by Aries on 5/5/14.
//  Copyright (c) 2014年 Aries. All rights reserved.
//

#import "SignupViewController.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#include <stdlib.h>

@interface SignupViewController  ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate,MBProgressHUDDelegate>
{
    MBProgressHUD *HUD;
    MBProgressHUD *refreshHUD;
}
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic) BOOL isMale;

//for translate
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UILabel *sexLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *instructionLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstStepLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondStepLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdStepLabel;
@property (nonatomic) BOOL isChineseSelected;

@end

@implementation SignupViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
  //  if ([UIScreen mainScreen].bounds.size.height == 568 ) {
  //      self.backgroundImageView.image = [UIImage imageNamed:@"loginBackground-568h"];
  //  }
    [self.segmentedControl setSelectedSegmentIndex:-1];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isChineseSelected"]) {
        [self translation];
        self.isChineseSelected = YES;
    }
}
- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}



#pragma mark - Sign Up
- (IBAction)signUp:(id)sender {
    
    NSString *username = [self.username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *email = [self.email.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([username length] == 0 || [email length] == 0 ){
        if (self.isChineseSelected) {
            [self alert:@"請確保你輸入了名稱及電郵。"];
        }else{
            [self alert:@"Make sure you enter a username & email address"];
        }
        
    }else if (self.segmentedControl.selectedSegmentIndex == -1){
        if (self.isChineseSelected) {
            [self alert:@"請確保你挑選了性別。"];
        }else{
            [self alert:@"Make sure you you select the sex"];
        }
    }else{
        //Take photo
        if ([UIImagePickerController isSourceTypeAvailable:
             UIImagePickerControllerSourceTypeCamera] == YES){
            // Create image picker controller
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            
            // Set source to the camera
            imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
            
            imagePicker.cameraDevice=UIImagePickerControllerCameraDeviceFront;
            
            // Delegate is self
            imagePicker.delegate = self;
            
            // Show image picker
            imagePicker.allowsEditing = NO;
            [self presentViewController:imagePicker animated:YES completion:NULL];
        }
        
    }
}

- (IBAction)switchSegment:(id)sender {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0:
            self.isMale = YES;
            break;
        case 1:
            self.isMale = NO;
            break;
    }
}


-(void)signUpUser:(NSData *)imageData
{
    NSString *username = [self.username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *email = [self.email.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    PFUser *newUser = [PFUser user];
    newUser.username = username;
    newUser.password = @"1234";
    newUser.email = email;
    if (self.isMale) {
        newUser[@"sex"] = @"M";
    }else{
        newUser[@"sex"] = @"F";
    }
    [newUser setObject:username forKey:@"name"];
    
    [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [self alert:[error userInfo][@"error"]];
        }else{
            [self uploadImage:imageData];
        }
    }];
    
}

- (void)uploadImage:(NSData *)imageData
{

    PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:imageData];
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    // Set determinate mode
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.delegate = self;
    HUD.labelText = @"Uploading";
    [HUD show:YES];
    
    // Save PFFile
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            //Hide determinate HUD
            [HUD hide:YES];
            
            // Show checkmark
            HUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:HUD];
            
            // The sample image is based on the work by http://www.pixelpressicons.com, http://creativecommons.org/licenses/by/2.5/ca/
            // Make the customViews 37 by 37 pixels for best results (those are the bounds of the build-in progress indicators)
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
            
            // Set custom view mode
            HUD.mode = MBProgressHUDModeCustomView;
            
            HUD.delegate = self;
            
            // Create a PFObject around a PFFile and associate it with the current user
            PFObject *userPhoto = [PFObject objectWithClassName:@"UserPhoto"];
            [userPhoto setObject:imageFile forKey:@"imageFile"];
            
            PFUser *user = [PFUser currentUser];
            [userPhoto setObject:user.objectId forKey:@"user"];
            if (self.isMale) {
                [userPhoto setObject:@"M" forKey:@"sex"];
            }else{
                [userPhoto setObject:@"F" forKey:@"sex"];
            }
            
            [userPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    // [self refresh:nil];
                }
                else{
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
        }
        else{
            [HUD hide:YES];
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    } progressBlock:^(int percentDone) {
        // Update your progress spinner here. percentDone will be between 0 and 100.
        HUD.progress = (float)percentDone/100;
        [self.navigationController popToRootViewControllerAnimated:YES];
    }];
}



#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    // Access the uncropped image from info dictionary
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    // Dismiss controller
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // Resize image
    UIGraphicsBeginImageContext(CGSizeMake(640, 960));
    [image drawInRect: CGRectMake(0, 0, 640, 960)];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Upload image
    NSData *imageData = UIImageJPEGRepresentation(smallImage, 1.0);
    [self signUpUser:imageData];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.isChineseSelected) {
        [self alert:@"請在拍攝過程中，不要按Cancel"];
    }else{
        [self alert:@"Please do not press Cancel during photo taking"];
    }
    
    
}


#pragma mark - Hud
- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD hides
    [HUD removeFromSuperview];
    HUD = nil;
}

#pragma mark - translation
-(void)translation
{
    self.sexLabel.text = @"性別";

    [self.signUpButton setTitle:@"註冊" forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    self.instructionLabel.text = @"指示";
    self.firstStepLabel.text = @"1. 請輸入你的名稱及電郵。";
    self.secondStepLabel.text = @"2. 按註冊，並拍攝頭像。";
    self.thirdStepLabel.text = @"3. 請在拍攝過程不要按Cancel。否則將未能成功註冊。";
    [self.segmentedControl setTitle:@"男" forSegmentAtIndex:0];
    [self.segmentedControl setTitle:@"女" forSegmentAtIndex:1];
    
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
