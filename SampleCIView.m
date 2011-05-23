#import "SampleCIView.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

static CGRect centerSizeWithinRect(CGSize size, CGRect rect);

@interface SampleCIView (Private)
- (CIImage *)lineImageWithColor:(NSColor *)aColor;
@end

@implementation SampleCIView

- (void)dealloc {
	[defaultColor release];
	[mirroredFilter release];
	[redLinesFilter release];
	[greenLinesFilter release];
    [theImage release];
    [context release];	
    [super dealloc];
}


- (void)setGoodScan:(BOOL)aBool {
}


- (void)setMirrored:(BOOL)aBool {
}

- (void)setCropRect:(CGRect)aCropRect {
}

- (CIImage *)image
{
    return nil;
}

- (void)setImage:(CIImage *)image
{
	if (theImage != image)
    {
		[theImage release];
		theImage = [image retain];
		[self setNeedsDisplay:YES];
    }
}

- (void)setCaptureSize:(CGSize)aSize
{
}

- (void)viewBoundsDidChange:(NSRect)bounds
{
}

- (void)updateMatrices
{
    NSRect r = [self bounds];
	
    if (!NSEqualRects (r, lastBounds))
    {
		[[self openGLContext] update];
		glViewport (0, 0, r.size.width, r.size.height);
		
		glMatrixMode (GL_PROJECTION);
		glLoadIdentity ();
		glOrtho (0, r.size.width, 0, r.size.height, -1, 1);
		
		glMatrixMode (GL_MODELVIEW);
		glLoadIdentity ();
		
		lastBounds = r;
		
		[self viewBoundsDidChange:r];
    }
}

- (void)drawRect:(NSRect)r
{
    CGRect ir, rr;
	
    [[self openGLContext] makeCurrentContext];
	
    /* Allocate a CoreImage rendering context using the view's OpenGL
     * context as its destination if none already exists. */
	
    if (context == nil)
    {
		NSOpenGLPixelFormat *pf;
		
		pf = [self pixelFormat];
		if (pf == nil){
			pf = [[self class] defaultPixelFormat];
		}
        
		context = [[CIContext contextWithCGLContext: CGLGetCurrentContext() pixelFormat: [pf CGLPixelFormatObj] options: nil] retain];
    }
	
    ir = CGRectIntegral (*(CGRect *)&r);
	
    [self updateMatrices];
    
    /* Clear the specified subrect of the OpenGL surface then
     * render the image into the view. Use the GL scissor test to
     * clip to * the subrect. Ask CoreImage to generate an extra
     * pixel in case * it has to interpolate (allow for hardware
     * inaccuracies) */
    
    rr = CGRectIntersection (CGRectInset (ir, -1.0f, -1.0f), *(CGRect *)&lastBounds);
    
    glScissor (ir.origin.x, ir.origin.y, ir.size.width, ir.size.height);
    glEnable (GL_SCISSOR_TEST);
    
    glClear (GL_COLOR_BUFFER_BIT);
    
    //NSLog(@"Display %@", theImage);
    
    if (theImage != nil)
    {
        CIImage *displayImage = [[theImage retain] autorelease];
        
        //mirror filter
        if (mirrored) {
            [mirroredFilter setValue:displayImage forKey:@"inputImage"];
            displayImage = [mirroredFilter valueForKey:@"outputImage"];
        }
        
        //Add lines showing scan area
        if (goodScan) {
            [greenLinesFilter setValue:displayImage forKey:@"inputBackgroundImage"];
            displayImage = [greenLinesFilter valueForKey:@"outputImage"];
        }
        else if (redLinesFilter) { //Could be empty if it's a capture window
            [redLinesFilter setValue:displayImage forKey:@"inputBackgroundImage"];
            displayImage = [redLinesFilter valueForKey:@"outputImage"];
        }			
                
        //RELEVANT_SECTION
        //Display the center part of a high resolution grab 
        if (cropImage) {
            //[context drawImage:displayImage atPoint:rr.origin fromRect:rr];
            [context drawImage:displayImage atPoint:rr.origin fromRect:cropRect];
        }
        else {
            [context drawImage:displayImage atPoint:rr.origin fromRect:rr];
        }
        // use the commented out method if you want to perform scaling
        //CGRect where = centerSizeWithinRect(captureSize, *(CGRect *)&lastBounds);
        //[context drawImage:displayImage inRect:where fromRect:_cleanRect];
        
    }
    
    glDisable (GL_SCISSOR_TEST);
    
    /* Flush the OpenGL command stream. If the view is double
     * buffered this should be replaced by [[self openGLContext]
     * flushBuffer]. */
    
    glFlush();
}

- (void)setCapture:(BOOL)aMode {
}

@end
