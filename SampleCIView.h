#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreImage.h>

@interface SampleCIView: NSOpenGLView
{
    CIContext *context;
    CIImage   *theImage;
    NSRect     lastBounds;
	CGSize     captureSize;
		
	BOOL mirrored, goodScan;
	BOOL cropImage;
	CGRect cropRect;
	
	CIFilter *mirroredFilter, *redLinesFilter, *greenLinesFilter;
	BOOL captureMode;
	NSColor *defaultColor;
}

- (void)setImage:(CIImage *)image;
- (void)setCaptureSize:(CGSize)aSize;
- (void)setCropRect:(CGRect)cropRect;
- (CIImage *)image;
- (void)viewBoundsDidChange:(NSRect)bounds;
- (void)setGoodScan:(BOOL)aBool;
- (void)setMirrored:(BOOL)aBool;
- (void)setCapture:(BOOL)aMode;
@end