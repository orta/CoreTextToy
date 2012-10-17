//
//  CCoreTextAttachment.m
//  CoreText
//
//  Created by Jonathan Wight on 10/31/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "CCoreTextAttachment.h"

static CGFloat MyCTRunDelegateGetAscentCallback(void *refCon);
static CGFloat MyCTRunDelegateGetDescentCallback(void *refCon);
static CGFloat MyCTRunDelegateGetWidthCallback(void *refCon);
static void MyCTRunDelegateDeallocCallback(void *refCon);

@implementation CCoreTextAttachment

@synthesize ascent = _ascent;
@synthesize descent = _descent;
@synthesize width = _width;
@synthesize representedObject = _representedObject;
@synthesize renderer = _renderer;

- (id)initWithAscent:(CGFloat)inAscent descent:(CGFloat)inDescent width:(CGFloat)inWidth representedObject:(id)inRepresentedObject renderer:(void (^)(CCoreTextAttachment *,CGContextRef,CGRect))inRenderer;
    {
    if ((self = [super init]) != NULL)
        {
        _ascent = inAscent;
        _descent = inDescent;
        _width = inWidth;
        _representedObject = inRepresentedObject;
        _renderer = [inRenderer copy];
        }
    return self;
    }

- (CTRunDelegateRef)createRunDelegate
    {
    CTRunDelegateCallbacks theCallbacks = {
        .version = kCTRunDelegateVersion1,
        .getAscent = MyCTRunDelegateGetAscentCallback,
        .getDescent = MyCTRunDelegateGetDescentCallback,
        .getWidth = MyCTRunDelegateGetWidthCallback,
        .dealloc = MyCTRunDelegateDeallocCallback,
        };
    
    CTRunDelegateRef theRunDelegate = CTRunDelegateCreate(&theCallbacks, (void *)(__bridge_retained CFTypeRef)self);
    return(theRunDelegate);
    }

@end

static CGFloat MyCTRunDelegateGetAscentCallback(void *refCon)
    {
    CCoreTextAttachment *theAttachment = (__bridge CCoreTextAttachment *)refCon;
    return(theAttachment.ascent);
    }

static CGFloat MyCTRunDelegateGetDescentCallback(void *refCon)
    {
    CCoreTextAttachment *theAttachment = (__bridge CCoreTextAttachment *)refCon;
    return(theAttachment.descent);
    }

static CGFloat MyCTRunDelegateGetWidthCallback(void *refCon)
    {
    CCoreTextAttachment *theAttachment = (__bridge CCoreTextAttachment *)refCon;
    return(theAttachment.width);
    }

static void MyCTRunDelegateDeallocCallback(void *refCon)
    {
    // TODO This is __strange__ but it works.
    
    CFRelease(refCon);
    }
