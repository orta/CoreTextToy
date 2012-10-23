//
//  CSimpleViewController.m
//  CoreText
//
//  Created by Jonathan Wight on 10/22/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CSimpleViewController.h"

#import "CCoreTextLabel.h"

@interface CSimpleViewController ()
@property (readwrite, nonatomic, weak) IBOutlet CCoreTextLabel *label;
@end

@implementation CSimpleViewController

- (void)viewDidLoad
	{
	[super viewDidLoad];

	self.label.insets = (UIEdgeInsets){ 10, 10, 10, 10 };

    NSURL *theURL = [[NSBundle mainBundle] URLForResource:@"Lorem" withExtension:@"txt"];
    NSString *theString = [NSString stringWithContentsOfURL:theURL encoding:NSUTF8StringEncoding error:NULL];
    self.label.text = [[NSAttributedString alloc] initWithString:theString];
	self.label.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.1];

	self.label.lineBreakMode = UILineBreakModeWordWrap;
	self.label.preferredMaxLayoutWidth = 300.0;
	}

@end
