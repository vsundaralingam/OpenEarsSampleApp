//  ViewController.m
//  OpenEarsSampleApp
//
//  ViewController.m demonstrates the use of the OpenEars framework. 
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

#import "ViewController.h"
#import <OpenEars/PocketsphinxController.h> // Please note that unlike in previous versions of OpenEars, we now link the headers through the framework.
#import <OpenEars/FliteController.h>
#import <OpenEars/LanguageModelGenerator.h>
#import <OpenEars/OpenEarsLogging.h>
#import <OpenEars/AcousticModel.h>

@implementation ViewController

@synthesize imageView;
@synthesize speakButton;
@synthesize pocketsphinxController;
@synthesize price1TextField;
@synthesize upc1TextField;
@synthesize openEarsEventsObserver;
@synthesize usingStartLanguageModel;
@synthesize pathToFirstDynamicallyGeneratedLanguageModel;
@synthesize pathToFirstDynamicallyGeneratedDictionary;
@synthesize pathToSecondDynamicallyGeneratedLanguageModel;
@synthesize pathToSecondDynamicallyGeneratedDictionary;
@synthesize uiUpdateTimer;
@synthesize restartAttemptsDueToPermissionRequests;
@synthesize startupFailedDueToLackOfPermissions;
@synthesize totalItems;
@synthesize currentItemIndex;
@synthesize IsListening;
@synthesize activityIndicatorView;
@synthesize statusLabel;
@synthesize itemsCountLabel;
@synthesize previousButton;


#define kLevelUpdatesPerSecond 18 // We'll have the ui update 18 times a second to show some fluidity without hitting the CPU too hard.

//#define kGetNbest // Uncomment this if you want to try out nbest
#pragma mark - 
#pragma mark Memory Management

- (void)dealloc {
	openEarsEventsObserver.delegate = nil;
}

#pragma mark -
#pragma mark Lazy Allocation

// Lazily allocated PocketsphinxController.
- (PocketsphinxController *)pocketsphinxController { 
	if (pocketsphinxController == nil) {
		pocketsphinxController = [[PocketsphinxController alloc] init];
        //pocketsphinxController.verbosePocketSphinx = TRUE; // Uncomment me for verbose debug output
        pocketsphinxController.outputAudio = TRUE;
#ifdef kGetNbest        
        pocketsphinxController.returnNbest = TRUE;
        pocketsphinxController.nBestNumber = 5;
#endif        
	}
	return pocketsphinxController;
}

// Lazily allocated OpenEarsEventsObserver.
- (OpenEarsEventsObserver *)openEarsEventsObserver {
	if (openEarsEventsObserver == nil) {
		openEarsEventsObserver = [[OpenEarsEventsObserver alloc] init];
	}
	return openEarsEventsObserver;
}

// The last class we're using here is LanguageModelGenerator but I don't think it's advantageous to lazily instantiate it. You can see how it's used below.

- (void) startListening {
    
    // startListeningWithLanguageModelAtPath:dictionaryAtPath:languageModelIsJSGF always needs to know the grammar file being used,
    // the dictionary file being used, and whether the grammar is a JSGF. You must put in the correct value for languageModelIsJSGF.
    // Inside of a single recognition loop, you can only use JSGF grammars or ARPA grammars, you can't switch between the two types.
    
    // An ARPA grammar is the kind with a .languagemodel or .DMP file, and a JSGF grammar is the kind with a .gram file.
    
    // If you wanted to just perform recognition on an isolated wav file for testing, you could do it as follows:
    
    // But under normal circumstances you'll probably want to do continuous recognition as follows:
    
    [self.pocketsphinxController startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to perform Spanish recognition instead of English.
    
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
    self.restartAttemptsDueToPermissionRequests = 0;
    self.startupFailedDueToLackOfPermissions = FALSE;
    
    //[OpenEarsLogging startOpenEarsLogging]; // Uncomment me for OpenEarsLogging
    
	[self.openEarsEventsObserver setDelegate:self]; // Make this class the delegate of OpenEarsObserver so we can get all of the messages about what OpenEars is doing.
    
    
    
    // This is the language model we're going to start up with. The only reason I'm making it a class property is that I reuse it a bunch of times in this example, 
	// but you can pass the string contents directly to PocketsphinxController:startListeningWithLanguageModelAtPath:dictionaryAtPath:languageModelIsJSGF:
	 
    NSArray *firstLanguageArray = [[NSArray alloc] initWithArray:[NSArray arrayWithObjects: // All capital letters.
                                                             @"1",
                                                              @"2",
                                                              @"3",
                                                              @"4",
                                                              @"5",
                                                              @"6",
                                                              @"7",
                                                              @"8",
                                                              @"9",
                                                              @"0",
                                                              @"NEXT",
                                                              @"PHOTO",
                                                              @"PREVIOUS",
                                                              nil]];
    
	LanguageModelGenerator *languageModelGenerator = [[LanguageModelGenerator alloc] init]; 
    
	NSError *error = [languageModelGenerator generateLanguageModelFromArray:firstLanguageArray withFilesNamed:@"FirstOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[AcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to create a language model for Spanish recognition instead of English.

	NSDictionary *firstDynamicLanguageGenerationResultsDictionary = nil;
	if([error code] != noErr) {
		NSLog(@"Dynamic language generator reported error %@", [error description]);	
	} else {
		firstDynamicLanguageGenerationResultsDictionary = [error userInfo];
		
		NSString *lmFile = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"LMFile"];
		NSString *dictionaryFile = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"DictionaryFile"];
		NSString *lmPath = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"LMPath"];
		NSString *dictionaryPath = [firstDynamicLanguageGenerationResultsDictionary objectForKey:@"DictionaryPath"];
		
		NSLog(@"Dynamic language generator completed successfully, you can find your new files %@\n and \n%@\n at the paths \n%@ \nand \n%@", lmFile,dictionaryFile,lmPath,dictionaryPath);	

		self.pathToFirstDynamicallyGeneratedLanguageModel = lmPath;
		self.pathToFirstDynamicallyGeneratedDictionary = dictionaryPath;
	}
    
	self.usingStartLanguageModel = TRUE; // This is not an OpenEars thing, this is just so I can switch back and forth between the two models in this sample app.
	
   self.IsListening = false;
   [self startListening];
   
   
   items = [[NSMutableArray alloc] initWithCapacity: 100];
   self.totalItems = [NSNumber numberWithInt:0];
   self.currentItemIndex = [NSNumber numberWithInt:0];
   
   self.activityIndicatorView = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(150, 200, 30, 30)];
   [activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
   [activityIndicatorView setColor:[UIColor whiteColor]];
   [self.view addSubview: activityIndicatorView];
   self.statusLabel.Hidden = true;
   statusLabel.layer.cornerRadius = 8;
   [self updateItemsCountLabel];
   
}

#pragma mark -
#pragma mark OpenEarsEventsObserver delegate methods
// An optional delegate method of OpenEarsEventsObserver which delivers the text of speech that Pocketsphinx heard and analyzed, along with its accuracy score and utterance ID.
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    
	NSLog(@"The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID); // Log it.
   
   

   
	if([hypothesis isEqualToString:@"NEXT"]) {
      [self showLoadingWithMessage: @"Detected Next..."];
      [self performSelector:@selector(nextButtonAction) withObject:activityIndicatorView afterDelay:1.0];
      return;
	}
   else if([hypothesis isEqualToString:@"PREVIOUS"]) {
      [self showLoadingWithMessage: @"Detected Previos..."];
      [self performSelector:@selector(previousButtonAction) withObject:activityIndicatorView afterDelay:1.0];
      return;
	}
   else if([hypothesis isEqualToString:@"PHOTO"]) {
      [self showLoadingWithMessage: @"Detected Photo..."];
      [self performSelector:@selector(takePhotoAction) withObject:activityIndicatorView afterDelay:1.0];
      return;
	}
   else{
      
         if([self.price1TextField isFirstResponder])
         {
            BOOL valid;
            NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
            NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString: [NSMutableString stringWithString:[hypothesis stringByReplacingOccurrencesOfString:@" " withString:@""]]];
            valid = [alphaNums isSupersetOfSet:inStringSet];
            if (valid) 
            {
               NSMutableString *price = [NSMutableString stringWithString:[hypothesis stringByReplacingOccurrencesOfString:@" " withString:@""]];
               switch (price.length) {
                  case 1:
                     [price insertString:@"0.0" atIndex: 0];
                     break;
                  case 2:
                     [price insertString:@"0." atIndex: 0];
                     break;
                  default:
                     [price insertString:@"." atIndex:price.length - 2];
                     break;
               }
               self.price1TextField.text = [NSString stringWithFormat:@"$%@", price]; // Show it in the status box.
               [self.price1TextField endEditing: TRUE];
            }
         }
      }
}

#ifdef kGetNbest   
- (void) pocketsphinxDidReceiveNBestHypothesisArray:(NSArray *)hypothesisArray { // Pocketsphinx has an n-best hypothesis dictionary.
    NSLog(@"hypothesisArray is %@",hypothesisArray);   
}
#endif
// An optional delegate method of OpenEarsEventsObserver which informs that there was an interruption to the audio session (e.g. an incoming phone call).
- (void) audioSessionInterruptionDidBegin {
	NSLog(@"AudioSession interruption began."); // Log it.
	[self.pocketsphinxController stopListening]; // React to it by telling Pocketsphinx to stop listening since it will need to restart its loop after an interruption.
}

// An optional delegate method of OpenEarsEventsObserver which informs that the interruption to the audio session ended.
- (void) audioSessionInterruptionDidEnd {
	NSLog(@"AudioSession interruption ended."); // Log it.
	 // We're restarting the previously-stopped listening loop.
    [self startListening];
	
}

// An optional delegate method of OpenEarsEventsObserver which informs that the audio input became unavailable.
- (void) audioInputDidBecomeUnavailable {
	NSLog(@"The audio input has become unavailable"); // Log it.
	[self.pocketsphinxController stopListening]; // React to it by telling Pocketsphinx to stop listening since there is no available input
}

// An optional delegate method of OpenEarsEventsObserver which informs that the unavailable audio input became available again.
- (void) audioInputDidBecomeAvailable {
	NSLog(@"The audio input is available"); // Log it.
	[self startListening];
}

// An optional delegate method of OpenEarsEventsObserver which informs that there was a change to the audio route (e.g. headphones were plugged in or unplugged).
- (void) audioRouteDidChangeToRoute:(NSString *)newRoute {
	NSLog(@"Audio route change. The new audio route is %@", newRoute); // Log it.
	
   [self.pocketsphinxController stopListening]; // React to it by telling the Pocketsphinx loop to shut down and then start listening again on the new route
    [self startListening];
}

// An optional delegate method of OpenEarsEventsObserver which informs that the Pocketsphinx recognition loop hit the calibration stage in its startup.
// This might be useful in debugging a conflict between another sound class and Pocketsphinx. Another good reason to know when you're in the middle of
// calibration is that it is a timeframe in which you want to avoid playing any other sounds including speech so the calibration will be successful.
- (void) pocketsphinxDidStartCalibration {
	NSLog(@"Pocketsphinx calibration has started."); // Log it.
}

// An optional delegate method of OpenEarsEventsObserver which informs that the Pocketsphinx recognition loop completed the calibration stage in its startup.
// This might be useful in debugging a conflict between another sound class and Pocketsphinx.
- (void) pocketsphinxDidCompleteCalibration {
	NSLog(@"Pocketsphinx calibration is complete."); // Log it.
   [self suspendListeningButtonAction];
}

// An optional delegate method of OpenEarsEventsObserver which informs that the Pocketsphinx recognition loop has entered its actual loop.
// This might be useful in debugging a conflict between another sound class and Pocketsphinx.
- (void) pocketsphinxRecognitionLoopDidStart {
    
	NSLog(@"Pocketsphinx is starting up."); // Log it.
}

// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx is now listening for speech.
- (void) pocketsphinxDidStartListening {
	
	NSLog(@"Pocketsphinx is now listening."); // Log it.
   
	
}

// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx detected speech and is starting to process it.
- (void) pocketsphinxDidDetectSpeech {
	NSLog(@"Pocketsphinx has detected speech."); // Log it.
}

// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx detected a second of silence, indicating the end of an utterance. 
// This was added because developers requested being able to time the recognition speed without the speech time. The processing time is the time between 
// this method being called and the hypothesis being returned.
- (void) pocketsphinxDidDetectFinishedSpeech {
	NSLog(@"Pocketsphinx has detected a second of silence, concluding an utterance."); // Log it.
}


// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx has exited its recognition loop, most 
// likely in response to the PocketsphinxController being told to stop listening via the stopListening method.
- (void) pocketsphinxDidStopListening {
	NSLog(@"Pocketsphinx has stopped listening."); // Log it.
}

// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx is still in its listening loop but it is not
// Going to react to speech until listening is resumed.  This can happen as a result of Flite speech being
// in progress on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the PocketsphinxController being told to suspend recognition via the suspendRecognition method.
- (void) pocketsphinxDidSuspendRecognition {
	NSLog(@"Pocketsphinx has suspended recognition."); // Log it.
}

// An optional delegate method of OpenEarsEventsObserver which informs that Pocketsphinx is still in its listening loop and after recognition
// having been suspended it is now resuming.  This can happen as a result of Flite speech completing
// on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the PocketsphinxController being told to resume recognition via the resumeRecognition method.
- (void) pocketsphinxDidResumeRecognition {
	NSLog(@"Pocketsphinx has resumed recognition."); // Log it.
}

// An optional delegate method which informs that Pocketsphinx switched over to a new language model at the given URL in the course of
// recognition. This does not imply that it is a valid file or that recognition will be successful using the file.
- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
	NSLog(@"Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
}

// An optional delegate method of OpenEarsEventsObserver which informs that Flite is speaking, most likely to be useful if debugging a
// complex interaction between sound classes. You don't have to do anything yourself in order to prevent Pocketsphinx from listening to Flite talk and trying to recognize the speech.
- (void) fliteDidStartSpeaking {
	NSLog(@"Flite has started speaking"); // Log it.
}

// An optional delegate method of OpenEarsEventsObserver which informs that Flite is finished speaking, most likely to be useful if debugging a
// complex interaction between sound classes.
- (void) fliteDidFinishSpeaking {
	NSLog(@"Flite has finished speaking"); // Log it.
}

- (void) pocketSphinxContinuousSetupDidFail { // This can let you know that something went wrong with the recognition loop startup. Turn on [OpenEarsLogging startOpenEarsLogging] to learn why.
	NSLog(@"Setting up the continuous recognition loop has failed for some reason, please turn on [OpenEarsLogging startOpenEarsLogging] in OpenEarsConfig.h to learn more."); // Log it.
}

- (void) testRecognitionCompleted { // A test file which was submitted for direct recognition via the audio driver is done.
	NSLog(@"A test file which was submitted for direct recognition via the audio driver is done."); // Log it.
    [self.pocketsphinxController stopListening];
    
}
/** Pocketsphinx couldn't start because it has no mic permissions (will only be returned on iOS7 or later).*/
- (void) pocketsphinxFailedNoMicPermissions {
    NSLog(@"The user has never set mic permissions or denied permission to this app's mic, so listening will not start.");
    self.startupFailedDueToLackOfPermissions = TRUE;
}

/** The user prompt to get mic permissions, or a check of the mic permissions, has completed with a TRUE or a FALSE result  (will only be returned on iOS7 or later).*/
- (void) micPermissionCheckCompleted:(BOOL)result {
    if(result == TRUE) {
        self.restartAttemptsDueToPermissionRequests++;
        if(self.restartAttemptsDueToPermissionRequests == 1 && self.startupFailedDueToLackOfPermissions == TRUE) { // If we get here because there was an attempt to start which failed due to lack of permissions, and now permissions have been requested and they returned true, we restart exactly once with the new permissions.
            [self startListening]; // Only do this once.
            self.startupFailedDueToLackOfPermissions = FALSE;
        }
    }
}

#pragma mark -
#pragma mark UI

// This is not OpenEars-specific stuff, just some UI behavior

- (IBAction) suspendListeningButtonAction { // This is the action for the button which suspends listening without ending the recognition loop
	[self.pocketsphinxController suspendRecognition];	
	
}

- (IBAction) resumeListeningButtonAction { // This is the action for the button which resumes listening if it has been suspended
	[self.pocketsphinxController resumeRecognition];
	
}

- (IBAction) stopButtonAction { // This is the action for the button which shuts down the recognition loop.
	[self.pocketsphinxController stopListening];
	
}

- (IBAction) startButtonAction { // This is the action for the button which starts up the recognition loop again if it has been shut down.
    [self startListening];
	
}

- (IBAction) priceListenerAction
{
   if(self.IsListening)
   {
      [self suspendListeningButtonAction];
      UIImage *backgroundImage = [UIImage imageNamed: @"Microphone-icon.png"];
      [self.speakButton setImage: backgroundImage forState:UIControlStateNormal];
      [self.speakButton setBackgroundImage: backgroundImage forState:UIControlStateNormal];
   }
   else
   {
      [self resumeListeningButtonAction];
      UIImage *backgroundImage = [UIImage imageNamed: @"microphone.png"];
      [self.speakButton setImage: backgroundImage forState:UIControlStateNormal];
      [self.speakButton setBackgroundImage: backgroundImage forState:UIControlStateNormal];
   }
   self.IsListening = !self.IsListening;
}

- (IBAction) nextButtonAction
{
   if([self.currentItemIndex intValue] == [items count] ){
      [self addItem];
      [self clearInputs];
      [self incrementItemsCount];
   }
   else
   {
         Item *newItem = [items objectAtIndex:[self.currentItemIndex intValue]];
         newItem.upc = self.upc1TextField.text;
         newItem.price = self.price1TextField.text;
         newItem.image = self.imageView.image;
      
         int value = [self.currentItemIndex intValue];
         self.currentItemIndex = [NSNumber numberWithInt:value + 1];
      
         if([items count] > ([self.currentItemIndex intValue]) )
         {
            Item *nextItem = [items objectAtIndex:[self.currentItemIndex intValue]];
            self.upc1TextField.text = nextItem.upc;
            self.price1TextField.text = nextItem.price;
            self.imageView.image = nextItem.image;
         }
         else
         {
            value = [self.totalItems intValue];
            self.totalItems = [NSNumber numberWithInt:value + 1];
            [self clearInputs];
         }
   }
   [self hideLoadingMessage];
   [self updateItemsCountLabel];
}

- (IBAction) previousButtonAction
{
   if([self.currentItemIndex intValue] == [items count]){
      [self addItem];
   }
   else
   {
      Item *newItem = [items objectAtIndex:[self.currentItemIndex intValue]];
      newItem.upc = self.upc1TextField.text;
      newItem.price = self.price1TextField.text;
      newItem.image = self.imageView.image;
   }
   
   if([self.currentItemIndex intValue] > 0){
      int value = [self.currentItemIndex intValue];
      self.currentItemIndex = [NSNumber numberWithInt:value - 1];
   }
   Item *newItem = [items objectAtIndex: [self.currentItemIndex intValue] ];
   self.upc1TextField.text = newItem.upc;
   self.price1TextField.text = newItem.price;
   self.imageView.image = newItem.image;
   
   [self hideLoadingMessage];
   [self updateItemsCountLabel];
   
}

-(void) addItem
{
   Item *newItem = [[Item alloc]init];
   
   newItem.upc = self.upc1TextField.text;
   newItem.price = self.price1TextField.text;
   newItem.image = self.imageView.image;

   [items addObject: newItem];
   
   
}

-(void) clearInputs
{
   self.upc1TextField.text = @"";
   self.price1TextField.text = @"";
   self.imageView.image = NULL;
}

- (IBAction) takePhotoAction
{
   if(self.IsListening)
   {
      [self suspendListeningButtonAction];
   }
   
   UIImagePickerController *picker = [[UIImagePickerController alloc] init];
   picker.delegate = self;
   picker.allowsEditing = YES;
   picker.sourceType = UIImagePickerControllerSourceTypeCamera;
   
   [self presentViewController:picker animated:YES completion:NULL];
   [self hideLoadingMessage];
   
}

-(void) showLoadingWithMessage: (NSString *) msg
{
   [self.activityIndicatorView startAnimating];
   self.statusLabel.Hidden = FALSE;
   self.statusLabel.Text = msg;
}

-(void) hideLoadingMessage
{
   [self.activityIndicatorView stopAnimating];
   self.statusLabel.Hidden = true;
}

-(void) updateItemsCountLabel
{
   self.itemsCountLabel.text = [NSString stringWithFormat:@"Current/Total:     %d/%d", ([self.currentItemIndex intValue]+ 1), ([self.totalItems intValue]+ 1)];
   if([self.currentItemIndex intValue] == 0)
      self.previousButton.hidden = true;
   else
      self.previousButton.hidden = false;
}

#pragma mark -

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
   
   UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
   self.imageView.image = chosenImage;
   
   [picker dismissViewControllerAnimated:YES completion:NULL];
   if(self.IsListening)
   {
      [self resumeListeningButtonAction];
   }
   
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
   
   [picker dismissViewControllerAnimated:YES completion:NULL];
   if(self.IsListening)
   {
      [self resumeListeningButtonAction];
   }
   
}

-(void) incrementItemsCount
{
   int value = [self.currentItemIndex intValue];
   self.currentItemIndex = [NSNumber numberWithInt:value + 1];
   
   value = [self.totalItems intValue];
   self.totalItems = [NSNumber numberWithInt:value + 1];
}



@end
