//
//  testAppDelegate.h
//  test
//
//  Created by katu on 11/05/02.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <QuartzCore/CoreImage.h>
#import "SampleCIView.h"
//#import "MainWindow.h"

@interface CameraViewer : NSObject <NSWindowDelegate> {
    NSWindow *window;

@private
    id delegate;
	QTCaptureSession *mCaptureSession;
	double clockFrequency;
	SampleCIView *previewView;
	NSPanel *previewPanel;
	BOOL  mirrored;

}

@property (assign) IBOutlet NSWindow *window;

- (void)exec;
- (void)startPreview;
- (Boolean)checkQTVersion;
- (BOOL)closeiSight;
- (void)setupPreviewWindowWithTitle:(NSString *)aTitle crop:(CGRect)aCropRect;
- (void)setDelegate:(id)aDelegate;

+ (QTCaptureDevice *)selectAndOpenVideoDevice:(NSString *)prefsDefaultKey;

@end

@interface NSObject (BarcodeScanningProtocolOptional)
- (void)iSightWillClose;
@end
