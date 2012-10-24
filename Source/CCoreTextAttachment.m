//
//  CCoreTextAttachment.m
//  CoreText
//
//  Created by Jonathan Wight on 10/31/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "CCoreTextAttachment.h"

#import "NSAttributedString_Extensions.h"

static CGFloat MyCTRunDelegateGetAscentCallback(void *refCon);
static CGFloat MyCTRunDelegateGetDescentCallback(void *refCon);
static CGFloat MyCTRunDelegateGetWidthCallback(void *refCon);
static void MyCTRunDelegateDeallocCallback(void *refCon);

@implementation CCoreTextAttachment

- (id)initWithType:(ECoreTextAttachmentType)inType ascent:(CGFloat)inAscent descent:(CGFloat)inDescent width:(CGFloat)inWidth representedObject:(id)inRepresentedObject
    {
    if ((self = [super init]) != NULL)
        {
		_type = inType;
        _ascent = inAscent;
        _descent = inDescent;
        _width = inWidth;
        _representedObject = inRepresentedObject;
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

- (NSDictionary *)createAttributes;
	{
	NSDictionary *theAttributes = @{
		kMarkupAttachmentAttributeName: self,
		(__bridge id)kCTRunDelegateAttributeName: (__bridge_transfer id)[self createRunDelegate],
		};
	return(theAttributes);
	}

- (NSAttributedString *)createAttributedString
	{
	// U+FFFC "Object Replacment Character" (thanks to Jens Ayton for the pointer)
	NSAttributedString *theString = [[NSAttributedString alloc] initWithString:@"\uFFFC" attributes:[self createAttributes]];
	return(theString);
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

#pragma mark -

@implementation CCoreTextAttachment (Conveniences)

+ (CCoreTextAttachment *)coreTextAttachmentWithView:(UIView *)inView
	{
	CCoreTextAttachment *theAttachment = [[CCoreTextAttachment alloc] initWithType:kCoreTextAttachmentType_View ascent:inView.frame.size.height descent:0.0 width:inView.frame.size.width representedObject:inView];
	return(theAttachment);
	}

@end
