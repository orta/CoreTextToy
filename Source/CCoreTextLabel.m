//
//  CCoreTextLabel.m
//  TouchCode
//
//  Created by Jonathan Wight on 07/12/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import "CCoreTextLabel.h"

#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

#import "CMarkupValueTransformer.h"
#import "CCoreTextRenderer.h"
#import "UIFont_CoreTextExtensions.h"
#import "UIColor+Hex.h"
#import "NSAttributedString_Extensions.h"

// For conenience CCoreTextRenderer deals with CFRanges, CCoreTextLabel deals with NSRanges.
#define CFRangeToNSRange_(r) ({ const CFRange r_ = (r); (NSRange){ (NSUInteger)r_.location, (NSUInteger)r_.length }; })
#define NSRangeToCFRange_(r) ({ const NSRange r_ = (r); (CFRange){ (CFIndex)r_.location, (CFIndex)r_.length }; })

@interface CCoreTextLabel ()
@property (readwrite, nonatomic, strong) CCoreTextRenderer *renderer;
+ (Class)rendererClass;

+ (CTParagraphStyleRef)createParagraphStyleForAttributes:(NSDictionary *)inAttributes alignment:(CTTextAlignment)inTextAlignment lineBreakMode:(CTLineBreakMode)inLineBreakMode;
+ (NSAttributedString *)normalizeString:(NSAttributedString *)inString settings:(id)inSettings;
+ (CTLineBreakMode)CTLineBreakModeForUITextAlignment:(UITextAlignment)inAlignment;
@end

@implementation CCoreTextLabel

@synthesize renderer = _renderer;

// TODO rename thatFits -> constrainedToSize
+ (CGSize)sizeForString:(NSAttributedString *)inString font:(UIFont *)inBaseFont alignment:(UITextAlignment)inTextAlignment lineBreakMode:(UILineBreakMode)inLineBreakMode contentInsets:(UIEdgeInsets)inContentInsets thatFits:(CGSize)inSize 
    {
    NSDictionary *theSettings = @{
		@"font": inBaseFont,
        @"textAlignment": @(inTextAlignment),
        @"lineBreakMode": @(inLineBreakMode),
		};
        
    NSAttributedString *theNormalizedText = [self normalizeString:inString settings:theSettings];
        
    CGRect theRect = (CGRect){ .size = inSize };
    theRect = UIEdgeInsetsInsetRect(theRect, inContentInsets);
    inSize = theRect.size; 
    
    CGSize theSize = [CCoreTextRenderer sizeForString:theNormalizedText thatFits:inSize];
    return(theSize);
    }

#pragma mark -

- (id)initWithFrame:(CGRect)frame
    {
    if ((self = [super initWithFrame:frame]) != NULL)
        {
        self.contentMode = UIViewContentModeRedraw;
        self.backgroundColor = [UIColor whiteColor];

        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitStaticText;
        self.accessibilityLabel = @"";

        _font = [UIFont systemFontOfSize:17];
        _textColor = [UIColor blackColor];
        _textAlignment = UITextAlignmentLeft;
        _lineBreakMode = UILineBreakModeTailTruncation;
        _lastLineBreakMode = UILineBreakModeTailTruncation;
        _shadowColor = NULL;
        _shadowOffset = (CGSize){ 0.0, -1.0 };
        _shadowBlurRadius = 0.0;
        _highlightedTextColor = [UIColor whiteColor];
        _enabled = YES;

		_preferredMaxLayoutWidth = CGFLOAT_MAX;
        }
    return(self);
    }

- (id)initWithCoder:(NSCoder *)inCoder
    {
    if ((self = [super initWithCoder:inCoder]) != NULL)
        {
        self.contentMode = UIViewContentModeRedraw;

        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitStaticText;
        self.accessibilityLabel = @"";

        _font = [UIFont systemFontOfSize:17];
        _textColor = [UIColor blackColor];
        _textAlignment = UITextAlignmentLeft;
        _lineBreakMode = UILineBreakModeTailTruncation;
        _lastLineBreakMode = UILineBreakModeTailTruncation;
        _shadowColor = NULL;
        _shadowOffset = (CGSize){ 0.0, -1.0 };
        _shadowBlurRadius = 0.0;
        _highlightedTextColor = [UIColor whiteColor];
        _enabled = YES;

		_preferredMaxLayoutWidth = CGFLOAT_MAX;
        }
    return(self);
    }

#pragma mark -

- (void)setBounds:(CGRect)inBounds
    {
	CGSize theOldSize = self.bounds.size;

    [super setBounds:inBounds];

	if (CGSizeEqualToSize(theOldSize, inBounds.size) == NO)
		{
		self.renderer = NULL;
		}
    }

#pragma mark -

- (void)setText:(NSAttributedString *)inText
    {
    if (_text != inText)
        {
        _text = inText;
        
        self.accessibilityLabel = inText.string;
        
        self.renderer = NULL;
		[self invalidateIntrinsicContentSize];
        }
    }

- (void)setFont:(UIFont *)inFont
    {
    if (_font != inFont)
        {
        _font = inFont;
        
        self.renderer = NULL;
		[self invalidateIntrinsicContentSize];
        }
    }

- (void)setTextColor:(UIColor *)inTextColor
    {
    if (_textColor != inTextColor)
        {
        _textColor = inTextColor;
        
        if (self.highlighted == NO)
            {
            self.renderer = NULL;
            }
        }
    }

- (void)setTextAlignment:(UITextAlignment)inTextAlignment
    {
    if (_textAlignment != inTextAlignment)
        {
        _textAlignment = inTextAlignment;
        
        self.renderer = NULL;
		[self invalidateIntrinsicContentSize];
        }
    }
    
- (void)setLineBreakMode:(UILineBreakMode)inLineBreakMode
    {
    if (_lineBreakMode != inLineBreakMode)
        {
        _lineBreakMode = inLineBreakMode;
        
        self.renderer = NULL;
		[self invalidateIntrinsicContentSize];
        }
    }

- (void)setLastLineBreakMode:(UILineBreakMode)inLastLineBreakMode
    {
    if (_lastLineBreakMode != inLastLineBreakMode)
        {
        _lastLineBreakMode = inLastLineBreakMode;
        
        self.renderer = NULL;
		[self invalidateIntrinsicContentSize];
        }
    }

- (void)setShadowColor:(UIColor *)inShadowColor
    {
    if (_shadowColor != inShadowColor)
        {
        _shadowColor = inShadowColor;
        
        self.renderer = NULL;
        }
    }

- (void)setShadowOffset:(CGSize)inShadowOffset
    {
    _shadowOffset = inShadowOffset;
    
    self.renderer = NULL;
    }

- (void)setShadowBlurRadius:(CGFloat)inShadowBlurRadius
    {
    if (_shadowBlurRadius != inShadowBlurRadius)
        {
        _shadowBlurRadius = inShadowBlurRadius;
        
        self.renderer = NULL;
        }
    }

- (void)setHighlightedTextColor:(UIColor *)inHighlightedTextColor
    {
    if (_highlightedTextColor != inHighlightedTextColor)
        {
        _highlightedTextColor = inHighlightedTextColor;
        
        if (self.highlighted == NO)
            {
            self.renderer = NULL;
            }
        }
    }

- (void)setHighlighted:(BOOL)inHighlighted
    {
    if (_highlighted != inHighlighted)
        {
        _highlighted = inHighlighted;

        self.renderer = NULL;
        }
    }

- (void)setEnabled:(BOOL)inEnabled
    {
    if (_enabled != inEnabled)
        {
        _enabled = inEnabled;
        
        // Disabling also turns off shadow, so we need to reset the renderer.
        self.renderer = NULL;
        }
    }

- (void)setInsets:(UIEdgeInsets)inInsets
    {
    _insets = inInsets;

    self.renderer = NULL;
	[self invalidateIntrinsicContentSize];
    }

#pragma mark -

+ (Class)rendererClass
    {
    return [CCoreTextRenderer class];
    }

- (CCoreTextRenderer *)renderer
    {
    if (_renderer == NULL)
        {
        NSMutableAttributedString *theNormalizedText = [[[self class] normalizeString:self.text settings:self] mutableCopy];

        CGRect theBounds = self.bounds;
        theBounds = UIEdgeInsetsInsetRect(theBounds, self.insets);
        
        Class theRendererClass = [[self class] rendererClass];
        _renderer = [[theRendererClass alloc] initWithText:theNormalizedText size:theBounds.size];
        
        // Some way to do this check before allocation? I know of no way to check with just a Class
        NSAssert2([_renderer isKindOfClass:[CCoreTextRenderer class]], @"-[%@ rendererClass] must return a sublass of CCoreTextRenderer, got %@", NSStringFromClass([self class]), NSStringFromClass(theRendererClass));
            
        if (self.lineBreakMode != self.lastLineBreakMode && _renderer.visibleLines.count > 1)
            {
            NSRange theLastLineRange = CFRangeToNSRange_([_renderer rangeOfLastLine]);
            
            CTParagraphStyleRef theParagraphStyle = [[self class] createParagraphStyleForAttributes:NULL alignment:[[self class] CTLineBreakModeForUITextAlignment:self.textAlignment] lineBreakMode:kCTLineBreakByTruncatingTail];

            [theNormalizedText addAttribute:(__bridge NSString *)kCTParagraphStyleAttributeName value:(__bridge id)theParagraphStyle range:theLastLineRange];
            
            _renderer.text = theNormalizedText;
            }
        


        [_renderer addPrerendererBlock:^(CGContextRef inContext, CTRunRef inRun, CGRect inRect) {
            NSDictionary *theAttributes2 = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
            CGColorRef theColor2 = (__bridge CGColorRef)theAttributes2[kMarkupBackgroundColorAttributeName];
            CGContextSetFillColorWithColor(inContext, theColor2);
            CGContextFillRect(inContext, inRect);
            } forAttributeKey:kMarkupBackgroundColorAttributeName];

        [_renderer addPostRendererBlock:^(CGContextRef inContext, CTRunRef inRun, CGRect inRect) {
            NSDictionary *theAttributes2 = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
            
            CTFontRef theFont = (__bridge CTFontRef)theAttributes2[(__bridge NSString *)kCTFontAttributeName];
            
            CGFloat theXHeight = CTFontGetXHeight(theFont);
            
            CGColorRef theColor2 = (__bridge CGColorRef)theAttributes2[kMarkupStrikeColorAttributeName];
            CGContextSetStrokeColorWithColor(inContext, theColor2);
            const CGFloat Y = CGRectGetMidY(inRect) - theXHeight * 0.5f;
            
            CGContextMoveToPoint(inContext, CGRectGetMinX(inRect), Y);
            CGContextAddLineToPoint(inContext, CGRectGetMaxX(inRect), Y);
            CGContextStrokePath(inContext);
            } forAttributeKey:kMarkupStrikeColorAttributeName];
        }
    return(_renderer);
    }

- (void)setRenderer:(CCoreTextRenderer *)inRenderer
    {
    if (_renderer != inRenderer)
        {
        _renderer = inRenderer;
        
        [self setNeedsDisplay];
        }
    }

#pragma mark -

- (CGSize)sizeThatFits:(CGSize)size
    {
    CGSize theSize = size;
    theSize.width -= self.insets.left + self.insets.right;
    theSize.height -= self.insets.top + self.insets.bottom;
    
    theSize = [self.renderer sizeThatFits:theSize];
    theSize.width += self.insets.left + self.insets.right;
    theSize.height += self.insets.top + self.insets.bottom;
    
    return(theSize);
    }

- (void)drawRect:(CGRect)rect
    {
    CGContextRef theContext = UIGraphicsGetCurrentContext();

    // ### Work out the inset bounds...
	CGRect theBounds = self.bounds;
    CGRect theInsetBounds = UIEdgeInsetsInsetRect(theBounds, self.insets);

//	CGRect theRect = { .size = self.intrinsicContentSize };
//	CGContextStrokeRect(theContext, theRect);

    // ### Get and set up the context...
    CGContextSaveGState(theContext);

    CGContextTranslateCTM(theContext, theInsetBounds.origin.x, theInsetBounds.origin.y);

    if (self.enabled == NO)
        {
        // 0.44 seems to be magic number (at least with black text).
        CGContextSetAlpha(theContext, 0.44f);
        }

    [self.renderer drawInContext:theContext];

    CGContextRestoreGState(theContext);    
    }

#pragma mark -

- (CGSize)intrinsicContentSize
	{
	CGSize theSize = [[self class ] sizeForString:self.text font:self.font alignment:self.textAlignment lineBreakMode:self.lineBreakMode contentInsets:self.insets thatFits:(CGSize){ self.preferredMaxLayoutWidth, CGFLOAT_MAX }];
	return(theSize);
	}

#pragma mark -

- (CGSize)sizeForString:(NSAttributedString *)inText constrainedToSize:(CGSize)inSize
    {
    CGSize theSize = [[self class] sizeForString:inText font:self.font alignment:self.textAlignment lineBreakMode:self.lineBreakMode contentInsets:self.insets thatFits:inSize];
    return(theSize);
    }
    
- (NSArray *)rectsForRange:(NSRange)inRange;
    {
    return([self.renderer rectsForRange:NSRangeToCFRange_(inRange)]);
    }

- (NSDictionary *)attributesAtPoint:(CGPoint)inPoint effectiveRange:(NSRange *)outRange
    {
    NSDictionary *theDictionary = [self.renderer attributesAtPoint:inPoint effectiveRange:(CFRange *)outRange];
    return(theDictionary);
    }
    
#pragma mark -

+ (CTParagraphStyleRef)createParagraphStyleForAttributes:(NSDictionary *)inAttributes alignment:(CTTextAlignment)inTextAlignment lineBreakMode:(CTLineBreakMode)inLineBreakMode
    {
    CGFloat theFirstLineHeadIndent;
    CGFloat theHeadIndent;
    CGFloat theTailIndent;
    CFArrayRef theTabStops;
    CGFloat theDefaultTabInterval;
    CGFloat theLineHeightMultiple;
    CGFloat theMaximumLineHeight;
    CGFloat theMinimumLineHeight;
    CGFloat theLineSpacing;
    CGFloat theParagraphSpacing;
    CGFloat theParagraphSpacingBefore;
    CTWritingDirection theBaseWritingDirection; 

    BOOL createdCurrentStyle = NO;
    CTParagraphStyleRef currentParagraphStyle = (__bridge CTParagraphStyleRef)inAttributes[(__bridge NSString *)kCTParagraphStyleAttributeName];
    if (currentParagraphStyle == NULL)
        {
        // Create default style
        currentParagraphStyle = CTParagraphStyleCreate(NULL, 0);
        createdCurrentStyle = YES;
        }
    
    // Grab all but the alignment and line break mode
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(theFirstLineHeadIndent), &theFirstLineHeadIndent);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierHeadIndent, sizeof(theHeadIndent), &theHeadIndent);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierTailIndent, sizeof(theTailIndent), &theTailIndent);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierTabStops, sizeof(theTabStops), &theTabStops);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(theDefaultTabInterval), &theDefaultTabInterval);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(theLineHeightMultiple), &theLineHeightMultiple);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(theMaximumLineHeight), &theMaximumLineHeight);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(theMinimumLineHeight), &theMinimumLineHeight);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierLineSpacing, sizeof(theLineSpacing), &theLineSpacing);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacing, sizeof(theParagraphSpacing), &theParagraphSpacing);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(theParagraphSpacingBefore), &theParagraphSpacingBefore);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(theBaseWritingDirection), &theBaseWritingDirection);
    
    CFRetain(theTabStops);
        
    if (createdCurrentStyle)
        {
        CFRelease(currentParagraphStyle);
        }
    
    CTParagraphStyleSetting newSettings[] = {
        { .spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(inTextAlignment), .value = &inTextAlignment, },
        { .spec = kCTParagraphStyleSpecifierFirstLineHeadIndent, .valueSize = sizeof(theFirstLineHeadIndent), .value = &theFirstLineHeadIndent, },
        { .spec = kCTParagraphStyleSpecifierHeadIndent, .valueSize = sizeof(theHeadIndent), .value = &theHeadIndent, },
        { .spec = kCTParagraphStyleSpecifierTailIndent, .valueSize = sizeof(theTailIndent), .value = &theTailIndent, },
        { .spec = kCTParagraphStyleSpecifierTabStops, .valueSize = sizeof(theTabStops), .value = &theTabStops, },
        { .spec = kCTParagraphStyleSpecifierDefaultTabInterval, .valueSize = sizeof(theDefaultTabInterval), .value = &theDefaultTabInterval, },
        { .spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(inLineBreakMode), .value = &inLineBreakMode, },
        { .spec = kCTParagraphStyleSpecifierLineHeightMultiple, .valueSize = sizeof(theLineHeightMultiple), .value = &theLineHeightMultiple, },
        { .spec = kCTParagraphStyleSpecifierMaximumLineHeight, .valueSize = sizeof(theMaximumLineHeight), .value = &theMaximumLineHeight, },
        { .spec = kCTParagraphStyleSpecifierMinimumLineHeight, .valueSize = sizeof(theMinimumLineHeight), .value = &theMinimumLineHeight, },
        { .spec = kCTParagraphStyleSpecifierLineSpacing, .valueSize = sizeof(theLineSpacing), .value = &theLineSpacing, },
        { .spec = kCTParagraphStyleSpecifierParagraphSpacing, .valueSize = sizeof(theParagraphSpacing), .value = &theParagraphSpacing, },
        { .spec = kCTParagraphStyleSpecifierParagraphSpacingBefore, .valueSize = sizeof(theParagraphSpacingBefore), .value = &theParagraphSpacingBefore, },
        { .spec = kCTParagraphStyleSpecifierBaseWritingDirection, .valueSize = sizeof(theBaseWritingDirection), .value = &theBaseWritingDirection, },
        };

    CTParagraphStyleRef newStyle = CTParagraphStyleCreate( newSettings, sizeof(newSettings)/sizeof(CTParagraphStyleSetting) );
    CFRelease(theTabStops);
    return newStyle;
    }

+ (NSAttributedString *)normalizeString:(NSAttributedString *)inString settings:(id)inSettings;
    {
    UIFont *theFont = [inSettings valueForKey:@"font"] ?: [UIFont systemFontOfSize:17.0];
    
    NSMutableAttributedString *theMutableText = [[NSAttributedString normalizedAttributedStringForAttributedString:inString baseFont:theFont] mutableCopy];

    UIColor *theTextColor = [inSettings valueForKey:@"textColor"] ?: [UIColor blackColor];
    [theMutableText enumerateAttributesInRange:(NSRange){ .length = theMutableText.length } options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if (attrs[(__bridge NSString *)kCTFontAttributeName] == NULL)
            {
            [theMutableText addAttribute:(__bridge NSString *)kCTFontAttributeName value:(__bridge id)theFont.CTFont range:range];
            }
        if (attrs[(__bridge NSString *)kCTForegroundColorAttributeName] == NULL)
            {
            [theMutableText addAttribute:(__bridge NSString *)kCTForegroundColorAttributeName value:(__bridge id)theTextColor.CGColor range:range];
            }
        }];

    if ([[inSettings valueForKey:@"highlighted"] boolValue] == YES)
        {
        UIColor *theHighlightColor = [inSettings valueForKey:@"highlightedTextColor"];
        [theMutableText addAttribute:(__bridge NSString *)kCTForegroundColorAttributeName value:(__bridge id)theHighlightColor.CGColor range:(NSRange){ .length = theMutableText.length }];
        }

    UIColor *theShadowColor = [inSettings valueForKey:@"shadowColor"];
    if (theShadowColor != NULL && [[inSettings valueForKey:@"enabled"] boolValue] == YES)
        {
        NSMutableDictionary *theShadowAttributes = [NSMutableDictionary dictionary];
        theShadowAttributes[kShadowColorAttributeName] = (__bridge id)theShadowColor.CGColor;
        
        NSValue *theShadowOffset = [inSettings valueForKey:@"shadowOffset"];
        theShadowAttributes[kShadowOffsetAttributeName] = theShadowOffset;

        NSNumber *theShadowBlueRadius = [inSettings valueForKey:@"shadowBlurRadius"];
        theShadowAttributes[kShadowBlurRadiusAttributeName] = theShadowBlueRadius;

        [theMutableText addAttributes:theShadowAttributes range:(NSRange){ .length = [theMutableText length] }];
        }
    
    CTTextAlignment theTextAlignment;
    switch ([[inSettings valueForKey:@"textAlignment"] integerValue])
        {
        case UITextAlignmentCenter:
            theTextAlignment = kCTCenterTextAlignment;
            break;
        case UITextAlignmentRight:
            theTextAlignment = kCTRightTextAlignment;
            break;
        case UITextAlignmentLeft:
        default:
            theTextAlignment = kCTLeftTextAlignment;
            break;
        }
    
    // UILineBreakMode maps 1:1 to CTLineBreakMode
    CTLineBreakMode theLineBreakMode = (CTLineBreakMode)[[inSettings valueForKey:@"lineBreakMode"] unsignedIntegerValue];

    [theMutableText enumerateAttributesInRange:(NSRange){ .length = theMutableText.length } options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        CTParagraphStyleRef newParagraphStyle = [self createParagraphStyleForAttributes:attrs alignment:theTextAlignment lineBreakMode:theLineBreakMode];
        [theMutableText addAttribute:(__bridge NSString *)kCTParagraphStyleAttributeName value:(__bridge id)newParagraphStyle range:range];
        CFRelease(newParagraphStyle);
        }];
        
    return(theMutableText);
    }

+ (CTLineBreakMode)CTLineBreakModeForUITextAlignment:(UITextAlignment)inAlignment
    {
    CTTextAlignment theTextAlignment;
    switch (inAlignment)
        {
        case UITextAlignmentCenter:
            theTextAlignment = kCTCenterTextAlignment;
            break;
        case UITextAlignmentRight:
            theTextAlignment = kCTRightTextAlignment;
            break;
        case UITextAlignmentLeft:
        default:
            theTextAlignment = kCTLeftTextAlignment;
            break;
        }
    return(theTextAlignment);
    }

@end
