//
//  CSelectableCoreTextLabel.m
//  CoreText
//
//  Created by Jonathan Wight on 2/12/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CSelectableCoreTextLabel.h"

#import <QuartzCore/QuartzCore.h>

#import "CCoreTextRenderer.h"

@interface CSelectableCoreTextLabel ()
@end

#pragma mark -

@implementation CSelectableCoreTextLabel

@synthesize selectedRange;

- (id)initWithFrame:(CGRect)frame
    {
    if ((self = [super initWithFrame:frame]) != NULL)
        {
        }
    return(self);
    }

- (id)initWithCoder:(NSCoder *)inCoder
    {
    if ((self = [super initWithCoder:inCoder]) != NULL)
        {
        }
    return(self);
    }

- (void)setText:(NSAttributedString *)inText
    {
    [super setText:inText];
    
    self.selectedRange = (NSRange){ .location = 8, .length = inText.length - 8 };

    [self setNeedsDisplay];
    }

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
//- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

- (void)setSelectedRange:(NSRange)inSelectedRange
    {
    if (NSEqualRanges(inSelectedRange, selectedRange) == NO)
        {
        selectedRange = inSelectedRange;
        //
        [self setNeedsDisplay];
        }
    }
    
- (void)drawRect:(CGRect)rect
    {
    CGContextRef theContext = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(theContext);
    
    [[UIColor colorWithRed:0.773 green:0.839 blue:0.902 alpha:1.000] setFill];
    [[UIColor redColor] setStroke];
    
    NSArray *theRectsForSelectedRange = [self rectsForRange:self.selectedRange];
    NSLog(@"%@", theRectsForSelectedRange);
    for (NSValue *theValue in theRectsForSelectedRange)
        {
        CGRect theRect = [theValue CGRectValue];
        
        UIRectFill(theRect);
        UIRectFrame(theRect);
        }

    CGContextRestoreGState(theContext);
    
    [super drawRect:rect];
    
    }
   

@end
