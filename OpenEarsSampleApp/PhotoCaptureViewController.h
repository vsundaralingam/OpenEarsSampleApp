//
//  PhotoCaptureViewController.h
//  OpenEarsSampleApp
//
//  Created by Vasanth Sundaralingam on 5/13/14.
//  Copyright (c) 2014 Politepix. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCaptureViewController : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
   IBOutlet UIButton *takePictureButton;
   IBOutlet UIImageView *imageView;
}
@property (strong, nonatomic) IBOutlet UIView *PhotoCapture;

@property (strong, nonatomic) IBOutlet UIButton *takePictureButton;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction) takePhoto: (UIButton *) sender;

@end


