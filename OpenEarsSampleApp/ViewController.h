//  ViewController.h
//  OpenEarsSampleApp
//
//  ViewController.h demonstrates the use of the OpenEars framework. 
//
//  Copyright Politepix UG (haftungsbeschränkt) 2012. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  This file is licensed under the Politepix Shared Source license found in the root of the source distribution.

// ********************************************************************************************************************************************************************
// ********************************************************************************************************************************************************************
// ********************************************************************************************************************************************************************
// IMPORTANT NOTE: This version of OpenEars introduces a much-improved low-latency audio driver for recognition. However, it is no longer compatible with the Simulator.
// Because I understand that it can be very frustrating to not be able to debug application logic in the Simulator, I have provided a second driver that is based on
// Audio Queue Services instead of Audio Units for use with the Simulator exclusively. However, this is purely provided as a convenience for you: please do not evaluate
// OpenEars' recognition quality based on the Simulator because it is better on the device, and please do not report Simulator-only bugs since I only actively support 
// the device driver and generally, audio code should never be seriously debugged on the Simulator since it is just hosting your own desktop audio devices. Thanks!
// ********************************************************************************************************************************************************************
// ********************************************************************************************************************************************************************
// ********************************************************************************************************************************************************************

#import <UIKit/UIKit.h>
#import <Slt/Slt.h>
#import "PhotoCaptureViewController.h"
#import "Item.h"
#import <QuartzCore/QuartzCore.h>

@class PocketsphinxController;
@class FliteController;
#import <OpenEars/OpenEarsEventsObserver.h> // We need to import this here in order to use the delegate.

@interface ViewController : UIViewController <OpenEarsEventsObserverDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
   
   NSMutableArray *items;
   NSNumber *totalItems;
   NSNumber *currentItemIndex;
   
	// These three are important OpenEars classes that ViewController demonstrates the use of. There is a fourth important class (LanguageModelGenerator) demonstrated
	// inside the ViewController implementation in the method viewDidLoad.
	
	OpenEarsEventsObserver *openEarsEventsObserver; // A class whose delegate methods which will allow us to stay informed of changes in the Flite and Pocketsphinx statuses.
	PocketsphinxController *pocketsphinxController; // The controller for Pocketsphinx (voice recognition).
	 
	// Some UI, not specifically related to OpenEars.
   IBOutlet UITextField *upc1TextField;
   IBOutlet UITextField *price1TextField;
   IBOutlet UIButton *speakButton;
   IBOutlet UIImageView *imageView;
   IBOutlet UILabel *statusLabel;
   IBOutlet UILabel *itemsCountLabel;
   IBOutlet UIButton *previousButton;
   
   
	BOOL usingStartLanguageModel;
	int restartAttemptsDueToPermissionRequests;
    BOOL startupFailedDueToLackOfPermissions;
	// Strings which aren't required for OpenEars but which will help us show off the dynamic language features in this sample app.
	NSString *pathToFirstDynamicallyGeneratedLanguageModel;
	NSString *pathToFirstDynamicallyGeneratedDictionary;
	
	NSString *pathToSecondDynamicallyGeneratedLanguageModel;
	NSString *pathToSecondDynamicallyGeneratedDictionary;

	
	// Our NSTimer that will help us read and display the input and output levels without locking the UI
	NSTimer *uiUpdateTimer;
   BOOL IsListening;
   UIActivityIndicatorView * activityIndicatorView;
}

- (IBAction) priceListenerAction;
- (IBAction) nextButtonAction;
- (IBAction) takePhotoAction;
- (IBAction) previousButtonAction;

// These three are the important OpenEars objects that this class demonstrates the use of.
@property (nonatomic, strong) OpenEarsEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) PocketsphinxController *pocketsphinxController;

// Some UI, not specifically related to OpenEars.
@property (nonatomic, strong) IBOutlet UITextField *upc1TextField;
@property (nonatomic, strong) IBOutlet UITextField *price1TextField;
@property (nonatomic, strong) IBOutlet UIButton *speakButton;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *itemsCountLabel;
@property (strong, nonatomic) IBOutlet UIButton *previousButton;

@property (nonatomic, assign) BOOL usingStartLanguageModel;
@property (nonatomic, assign) int restartAttemptsDueToPermissionRequests;
@property (nonatomic, assign) BOOL startupFailedDueToLackOfPermissions;
@property (nonatomic, assign) BOOL IsListening;

// Things which help us show off the dynamic language features.
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedDictionary;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedDictionary;

// Our NSTimer that will help us read and display the input and output levels without locking the UI
@property (nonatomic, strong) 	NSTimer *uiUpdateTimer;
@property (nonatomic, strong) NSNumber *totalItems;
@property (nonatomic, strong) NSNumber *currentItemIndex;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

