//
//  CSelectableCoreTextLabel.h
//  CoreText
//
//  Created by Jonathan Wight on 2/12/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CCoreTextLabel.h"

@interface CSelectableCoreTextLabel : CCoreTextLabel

@property (readwrite, nonatomic, assign) NSRange selectedRange;

@end
