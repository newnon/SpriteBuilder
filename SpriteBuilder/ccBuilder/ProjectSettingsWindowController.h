//
//  ProjectSettingsWindowController.h
//  SpriteBuilder
//
//  Created by Nicky Weber on 24.07.14.
//
//

#import <Cocoa/Cocoa.h>
#import "CCBModalSheetController.h"

@class ProjectSettings;
@class PackagePublishSettings;
@class PlatformSettings;

@interface ProjectSettingsWindowController : CCBModalSheetController <NSTableViewDelegate, NSOpenSavePanelDelegate>

@property (nonatomic, weak) ProjectSettings* projectSettings;
@property (nonatomic, strong) PackagePublishSettings *currentPackageSettings;
@property (nonatomic, strong) PlatformSettings *currentPlatformSettings;

@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSView *detailView;


- (IBAction)selectPackagePublishingCustomDirectory:(id)sender;

- (instancetype)initWithProjectSettings:(ProjectSettings*) projectSettings;

@end
