/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "AboutWindow.h"
#import "AppDelegate.h"

@interface AboutWindow ()
@property (weak) IBOutlet NSButton *buttonViewOnGithub;

@end

@implementation AboutWindow

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Load version file into version text field
	

    NSString* version = [self versionAboutInfo];
    
    if (version)
    {
        [txtVersion setStringValue:version];
    }
    else
    {
        [btnVersion setEnabled:NO];
    }
    
    self.version = [version substringWithRange:NSMakeRange(version.length-11, 10)];
    
    // Add close button
    NSButton* closeButton = [NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:NSTitledWindowMask];
    [closeButton setFrameOrigin:NSMakePoint(21, 317)];
    NSView* contentView = self.window.contentView;
    [contentView addSubview:closeButton];
	

}

-(NSString*)versionAboutInfo
{
	ProjectSettings* projectSettings = [[ProjectSettings alloc] init];
	NSDictionary * versionDictionary = [projectSettings getVersionDictionary];

    NSString * aboutInfo = @"";
	aboutInfo = [aboutInfo stringByAppendingString:[NSString stringWithFormat:@"SB Version: %@\n", versionDictionary[@"version"]]];
	aboutInfo = [aboutInfo stringByAppendingString:[NSString stringWithFormat:@"SB Revision: %@\n", versionDictionary[@"revision"]]];
	
	return aboutInfo;
}

- (IBAction)btnViewOnGithub:(id)sender
{

    [[NSWorkspace sharedWorkspace] openURL:
     [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/KAMIKAZEUA/SpriteBuilderX"]]];
    
    [self.window orderOut:sender];
}

- (IBAction)btnSupportForum:(id)sender
{
    [[AppDelegate appDelegate] visitCommunity:sender];
    [self.window orderOut:sender];
}


@end
