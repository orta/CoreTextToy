//
//  CSimpleViewController.m
//  CoreText
//
//  Created by Jonathan Wight on 10/22/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CSimpleViewController.h"

#import "CCoreTextLabel.h"
#import "CCoreTextLabel_HTMLExtensions.h"
#import "CCoreTextAttachment.h"
#import "NSAttributedString_Extensions.h"

@interface CSimpleViewController ()
@property (readwrite, nonatomic, weak) IBOutlet CCoreTextLabel *label;
@end

@implementation CSimpleViewController

- (void)viewDidLoad
	{
	[super viewDidLoad];

	self.label.insets = (UIEdgeInsets){ 10, 10, 10, 10 };

	NSMutableAttributedString *theText = [[NSMutableAttributedString alloc] init];
	[theText appendAttributedString:[[NSAttributedString alloc] initWithString:@"Here is a button: "]];

	// #########################################################################
	UIButton *theButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[theButton addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
	[theButton setTitle:@"Hello CoreText" forState:UIControlStateNormal];
	[theButton sizeToFit];

	CCoreTextAttachment *theAttachment = [CCoreTextAttachment coreTextAttachmentWithView:theButton];
	[theText appendAttributedString:[theAttachment createAttributedString]];
	// #########################################################################

	UIActivityIndicatorView *theActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[theActivityIndicatorView startAnimating];
	[theText appendAttributedString:[[CCoreTextAttachment coreTextAttachmentWithView:theActivityIndicatorView] createAttributedString]];



	// #########################################################################

	[theText appendAttributedString:[[NSAttributedString alloc] initWithString:@"Did it work?"]];


    self.label.text = theText;
	self.label.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.1];

	self.label.lineBreakMode = UILineBreakModeWordWrap;
	self.label.preferredMaxLayoutWidth = 300.0;
	}

- (IBAction)click:(id)sender
	{
	UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"It does!" message:NULL delegate:NULL cancelButtonTitle:@"By jove!" otherButtonTitles:NULL];
	[theAlert show];
	}

@end
