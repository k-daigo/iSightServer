#import "CameraViewer.h"

#define myPreferences [NSUserDefaults standardUserDefaults]
#define FRAMEWORK_BUNDLE [NSBundle bundleWithIdentifier:@"com.bruji.pediabase"]

@implementation CameraViewer

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self exec];
}

- (void)exec {
	[self startPreview];
}

// カメラ動画表示を開始する
- (void)startPreview {
    CGRect cropArea = CGRectZero;
	CGSize displaySize = CGSizeMake(640.0, 480.0);

	// QuicktimeのVersionをチェックする
	if([self checkQTVersion] == false){
		return;
	}

	// デバイスを取得
	QTCaptureDevice *videoDevice = [CameraViewer selectAndOpenVideoDevice:@"iSight ID"];

	NSString *cameraDescription = [videoDevice modelUniqueID];
	NSString *cameraName = [videoDevice localizedDisplayName];
	NSLog(@"cameraDescription = %@", cameraDescription);
	NSLog(@"cameraName = %@", cameraName);
    
    NSError *error = nil;

    mCaptureSession = [[QTCaptureSession alloc] init];

    QTCaptureDeviceInput *mCaptureVideoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:videoDevice];
    BOOL success = [mCaptureSession addInput:mCaptureVideoDeviceInput error:&error];
    [mCaptureVideoDeviceInput release];
    if (!success) {
        NSLog(@"Error: video device could not be added as input: %@", [error localizedDescription]);
        [self closeiSight];
        return;
    }
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                       [NSNumber numberWithDouble:displaySize.width], (id)kCVPixelBufferWidthKey, 
                                       [NSNumber numberWithDouble:displaySize.height], (id)kCVPixelBufferHeightKey,
                                       [NSNumber numberWithBool:YES], (id)kCVPixelBufferOpenGLCompatibilityKey,
                                       [NSNumber numberWithUnsignedInt:k2vuyPixelFormat], (id)kCVPixelBufferPixelFormatTypeKey,
                                       nil];
    
    // QTCaptureVideoPreviewOutput could be if frame rate is not so important
    QTCaptureDecompressedVideoOutput *mCaptureDecompress = [[QTCaptureDecompressedVideoOutput alloc] init];
    [mCaptureDecompress setDelegate:self];
    [mCaptureDecompress setPixelBufferAttributes:attributes];
    if ([mCaptureDecompress respondsToSelector:@selector(setAutomaticallyDropsLateVideoFrames:)]){
        NSLog(@"10.6 only");
        [mCaptureDecompress setAutomaticallyDropsLateVideoFrames:YES]; //!!! 10.6 only
    }
    success = [mCaptureSession addOutput:mCaptureDecompress error:&error];
    [mCaptureDecompress release];
    if (!success) {
        NSLog(@"Error: could not add output device: %@", [error localizedDescription]);
        [self closeiSight];
        return;
    }
    
    // Associate the capture view in the UI with the session
    [self setupPreviewWindowWithTitle:@"iSightServer Preview" crop:cropArea];
    
    [mCaptureSession startRunning];
}

// QuicktimeのVersionをチェックする
- (Boolean)checkQTVersion {
	// We need at least version 721 of quicktime for the QTKit to be installed
	SInt32 quickTimeVersionNumber;
	Gestalt(gestaltQuickTime, &quickTimeVersionNumber);

	NSLog(@"Quicktime version is %x", quickTimeVersionNumber);
	
	if (quickTimeVersionNumber < 0x721000) {
		NSRunAlertPanel(NSLocalizedStringWithDefaultValue(@"Action Required", nil, [NSBundle mainBundle], nil, nil),
			NSLocalizedStringWithDefaultValue(@"NoQuickTime721", nil, [NSBundle mainBundle],
				@"The version of QuickTime installed is lower than 7.2.1, please install the latest QuickTime from http://www.apple.com/quicktime/download ", nil),
			@"OK", nil, nil);
		return false;
	}
	
	return true;
}

// 動画取得を開始
+ (QTCaptureDevice *)selectAndOpenVideoDevice:(NSString *)prefsDefaultKey {
	QTCaptureDevice *videoDevice = nil;
	NSMutableArray *videoDevices = [NSMutableArray array];
	
	//Get default if there already is one and control is not held down
	BOOL selectDefault = YES;
	NSUInteger flags = [[NSApp currentEvent] modifierFlags];
	if (flags & NSControlKeyMask && !(flags & NSShiftKeyMask)){
		selectDefault = NO;
	}
	
	if (selectDefault) {
		NSString *defaultDevice = [myPreferences objectForKey:prefsDefaultKey];
		videoDevice = [QTCaptureDevice deviceWithUniqueID:defaultDevice];
	}
	
	// default not found run the regular check 
	if (videoDevice == nil) {
		NSLog(@"videoDevice is null");
		
		[videoDevices addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]];
		[videoDevices addObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
		
		NSUInteger count = [videoDevices count];
		NSLog(@"count %ld", count);
		if (count == 1) {
			videoDevice = [videoDevices objectAtIndex:0];
        }
		else if (count > 1) {
			NSString *firstDevice = [[videoDevices objectAtIndex:0] localizedDisplayName];
			NSString *secondDevice = [[videoDevices objectAtIndex:1] localizedDisplayName];
			NSString *thirdDevice = nil;
			if (count > 2){
				thirdDevice = [[videoDevices objectAtIndex:2] localizedDisplayName];
			}
            
			// isConnected  isInUseByAnotherApplication
			NSInteger buttonPressed = NSRunAlertPanel(
                    NSLocalizedStringWithDefaultValue(@"Action Required", nil, FRAMEWORK_BUNDLE, nil, nil), 
                    NSLocalizedStringWithDefaultValue(@"Several video sources", nil, FRAMEWORK_BUNDLE, @"Several video sources have been found. Which one would you like to use?", nil), 
													  firstDevice, 
													  secondDevice,
													  thirdDevice);
			
			if (buttonPressed == NSAlertDefaultReturn) {
				videoDevice = [videoDevices objectAtIndex:0];
			}
			else if (buttonPressed == NSAlertAlternateReturn) {
				videoDevice = [videoDevices objectAtIndex:1];
			}
			else if (buttonPressed == NSAlertOtherReturn) {
				videoDevice = [videoDevices objectAtIndex:2];
			}
			
			//Save as default device to use
			NSString *uniqueID = [videoDevice uniqueID];
			[myPreferences setObject:uniqueID forKey:prefsDefaultKey];
		}
	}
	
	NSError *error = nil;
	BOOL success = [videoDevice open:&error];	
	if (!success) {
		// Write error to the console log 
		NSLog(@"Error: failed to opened selected video device: %@", [error localizedDescription]);
		
		// Try one last ditch attempt at the default devices for Video and Muxed
		videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
		if (videoDevice)
			success = [videoDevice open:&error];
		
		if (!success) {			
			videoDevice = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeMuxed];
			if (videoDevice)
				success = [videoDevice open:&error];
			
			if (!success) {
				videoDevice = nil;
				NSLog(@"Error: failed to opened default video device: %@", [error localizedDescription]);
			}	
		}
	}
	
	return videoDevice;	
}

- (BOOL)closeiSight {
    
	//NSLog(@"Close iSight: %@", mCaptureSession);
	BOOL returnValue = NO;
	if (mCaptureSession) {
		[mCaptureSession stopRunning];
		QTCaptureDevice *captureDevice = [[[mCaptureSession inputs] lastObject] device];
		if ([captureDevice isOpen])
			[captureDevice close];
		
		[mCaptureSession release];
		mCaptureSession = nil;
		
		returnValue = YES;
	}	
	
	if (returnValue) {
		if ([delegate respondsToSelector:@selector(iSightWillClose)]) {
			[delegate iSightWillClose];
		}
	}

	return returnValue;
}

- (void)setupPreviewWindowWithTitle:(NSString *)aTitle crop:(CGRect)aCropRect {
	NSRect screenRect = [[[NSApp mainWindow] screen] visibleFrame];
	NSRect windowRect = NSMakeRect(0, 0, 640, 480);
	if (aCropRect.size.width && aCropRect.size.width != 640) {
		windowRect.size.width = aCropRect.size.width;
		windowRect.size.height = aCropRect.size.height;
	}
	
	windowRect.origin.x = screenRect.origin.x + 16;
	windowRect.origin.y = screenRect.origin.y + screenRect.size.height - windowRect.size.height - 22;

	previewPanel = [[NSPanel alloc] initWithContentRect:windowRect 
                                                styleMask:NSTitledWindowMask | NSClosableWindowMask
                                                backing:NSBackingStoreBuffered 
                                                defer:YES
                                                screen:[[NSApp mainWindow] screen]];
	
	previewView = [[SampleCIView alloc] initWithFrame:windowRect];
	[previewPanel setContentView:previewView];
	[previewView release];
    
	[previewPanel setTitle:aTitle];
	[previewPanel setDelegate:self];
	[previewPanel orderFront:self];
}

- (void)setDelegate:(id)aDelegate {
	[delegate release];
	delegate = [aDelegate retain];
}

- (void)captureOutput:(QTCaptureOutput *)captureOutput
                didOutputVideoFrame:(CVImageBufferRef)videoFrame
                withSampleBuffer:(QTSampleBuffer *)sampleBuffer
                fromConnection:(QTCaptureConnection *)connection
{
	uint64_t ht = CVGetCurrentHostTime();
    uint64_t iht = [[sampleBuffer attributeForKey:QTSampleBufferHostTimeAttribute] unsignedLongLongValue];
	double hts = ht / clockFrequency;
    double ihts = iht / clockFrequency;
	
	if(hts > ihts + 0.1) { // 1/10 of a second
		return;
	}
	
	if (previewPanel != nil)
    {
		CIImage * ciImage = [CIImage imageWithCVImageBuffer:videoFrame];
		[previewView setImage:ciImage];	
		
		[previewView setGoodScan:NO];
	}
}

@end
