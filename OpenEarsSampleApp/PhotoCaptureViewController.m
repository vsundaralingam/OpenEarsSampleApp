//
//  PhotoCaptureViewController.m
//  OpenEarsSampleApp
//
//  Created by Vasanth Sundaralingam on 5/13/14.
//  Copyright (c) 2014 Politepix. All rights reserved.
//

#import "PhotoCaptureViewController.h"

@interface PhotoCaptureViewController ()

@end

@implementation PhotoCaptureViewController

@synthesize takePictureButton;
@synthesize imageView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/                                                                                                                                                                      

- (IBAction) takePhoto: (UIButton *) sender{
   NSLog(@"Take Picture");
   
   UIImagePickerController *picker = [[UIImagePickerController alloc] init];
   picker.delegate = self;
   picker.allowsEditing = YES;
   picker.sourceType = UIImagePickerControllerSourceTypeCamera;
   
   [self presentViewController:picker animated:YES completion:NULL];
   
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
   
   UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
   self.imageView.image = chosenImage;
   
   [picker dismissViewControllerAnimated:YES completion:NULL];
   
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
   
   [picker dismissViewControllerAnimated:YES completion:NULL];
   
}


@end
