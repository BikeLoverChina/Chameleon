//  Created by Sean Heber on 5/27/10.
#import "UIImageView.h"
#import "UIImage.h"
#import "UIGraphics.h"
#import "UIKit+Private.h"
#import <QuartzCore/QuartzCore.h>

static NSArray *CGImagesWithUIImages(NSArray *images)
{
	NSMutableArray *CGImages = [NSMutableArray arrayWithCapacity:[images count]];
	for (UIImage *img in images) {
		[CGImages addObject:(id)[img CGImage]];
	}
	return CGImages;
}

@implementation UIImageView
@synthesize image=_image, animationImages=_animationImages, animationDuration=_animationDuration, highlightedImage=_highlightedImage, highlighted=_highlighted;
@synthesize animationRepeatCount=_animationRepeatCount, highlightedAnimationImages=_highlightedAnimationImages;

+ (BOOL)_instanceImplementsDrawRect
{
	return NO;
}

- (id)initWithFrame:(CGRect)frame
{
	if ((self=[super initWithFrame:frame])) {
		_drawMode = _UIImageViewDrawModeNormal;
		self.userInteractionEnabled = NO;
		self.opaque = NO;
	}
	return self;
}

- (id)initWithImage:(UIImage *)theImage
{
	CGSize imageSize = theImage.size;
	if ((self = [self initWithFrame:CGRectMake(0,0,imageSize.width,imageSize.height)])) {
		self.image = theImage;
	}
	return self;
}

- (void)dealloc
{
	[_animationImages release];
	[_image release];
	[_highlightedImage release];
	[_highlightedAnimationImages release];
	[super dealloc];
}

- (CGSize)sizeThatFits:(CGSize)size
{
	return _image.size;
}

- (void)setHighlighted:(BOOL)h
{
	if (h != _highlighted) {
		_highlighted = h;
		[self setNeedsDisplay];

		if ([self isAnimating]) {
			[self startAnimating];
		}
	}
}

- (void)setImage:(UIImage *)newImage
{
	if (_image != newImage) {
		[_image release];
		_image = [newImage retain];
		if (!_highlighted || !_highlightedImage) {
			[self setNeedsDisplay];
		}
	}
}

- (void)setHighlightedImage:(UIImage *)newImage
{
	if (_highlightedImage != newImage) {
		[_highlightedImage release];
		_highlightedImage = [newImage retain];
		if (_highlighted) {
			[self setNeedsDisplay];
		}
	}
}

- (BOOL)_hasResizableImage
{
	return (_image.topCapHeight > 0 || _image.leftCapWidth > 0);
}

- (void)_setDrawMode:(NSInteger)drawMode
{
	if (drawMode != _drawMode) {
		_drawMode = drawMode;
		[self setNeedsDisplay];
	}
}

- (void)displayLayer:(CALayer *)theLayer
{
	UIImage *sourceImage = (_highlighted && _highlightedImage)? _highlightedImage : _image;
	UIImage *displayImage = sourceImage;
	const CGRect bounds = self.bounds;
	
	if (self._hasResizableImage && bounds.size.width > 0 && bounds.size.height > 0) {
		UIGraphicsBeginImageContext(bounds.size);
		[sourceImage drawInRect:bounds];
		displayImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}
	
	// adjust the image if required.
	// this will likely only ever be used UIButton, but it seemed a good place for it.
	// I wonder how the real UIKit does this...
	if (displayImage && (_drawMode != _UIImageViewDrawModeNormal)) {
		CGRect imageBounds;
		imageBounds.origin = CGPointZero;
		imageBounds.size = displayImage.size;

		UIGraphicsBeginImageContext(imageBounds.size);
		
		CGBlendMode blendMode = kCGBlendModeNormal;
		CGFloat alpha = 1;
		
		if (_drawMode == _UIImageViewDrawModeDisabled) {
			alpha = 0.5;
		} else if (_drawMode == _UIImageViewDrawModeHighlighted) {
			[[[UIColor blackColor] colorWithAlphaComponent:0.4] setFill];
			UIRectFill(imageBounds);
			blendMode = kCGBlendModeDestinationAtop;
		}
		
		[displayImage drawInRect:imageBounds blendMode:blendMode alpha:alpha];
		displayImage = UIGraphicsGetImageFromCurrentImageContext();

		UIGraphicsEndImageContext();
	}

	theLayer.contents = (id)[displayImage CGImage];
}

- (void)_displayIfNeededChangingFromOldSize:(CGSize)oldSize toNewSize:(CGSize)newSize
{
	if (!CGSizeEqualToSize(newSize,oldSize) && self._hasResizableImage) {
		[self setNeedsDisplay];
	}
}

- (void)setFrame:(CGRect)newFrame
{
	[self _displayIfNeededChangingFromOldSize:self.frame.size toNewSize:newFrame.size];
	[super setFrame:newFrame];
}

- (void)setBounds:(CGRect)newBounds
{
	[self _displayIfNeededChangingFromOldSize:self.bounds.size toNewSize:newBounds.size];
	[super setBounds:newBounds];
}

- (void)startAnimating
{
	NSArray *images = _highlighted? _highlightedAnimationImages : _animationImages;

	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	animation.calculationMode = kCAAnimationDiscrete;
	animation.duration = self.animationDuration ?: ([images count] * (1/30.0));
	animation.repeatCount = self.animationRepeatCount ?: HUGE_VALF;
	animation.values = CGImagesWithUIImages(images);

	[self.layer addAnimation:animation forKey:@"contents"];
}

- (void)stopAnimating
{
	[self.layer removeAnimationForKey:@"contents"];
}

- (BOOL)isAnimating
{
	return ([self.layer animationForKey:@"contents"] != nil);
}

@end
