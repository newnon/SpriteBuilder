//  ProjectSettings2WindowController.m
//  SpriteBuilder
//
//
//  Created by Nicky Weber on 24.07.14.
//
//

#import "ProjectSettingsWindowController.h"
#import "ProjectSettings.h"
#import "PackagePublishSettings.h"
#import "PlatformSettings.h"
#import "PlatformSettingsDetailView.h"
#import "RMPackage.h"
#import "ResourceManager.h"
#import "NSString+RelativePath.h"
#import "MiscConstants.h"
#import "PublishUtil.h"
#import "NSAlert+Convenience.h"

typedef void (^DirectorySetterBlock)(NSString *directoryPath);

@interface SettingsListEntry : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic) BOOL canBeModified;
@property (nonatomic, strong) PlatformSettings *platformSettings;

@end


@implementation SettingsListEntry

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.canBeModified = NO;
        self.platformSettings = [[PlatformSettings alloc] init];
    }
    return self;
}

- (instancetype)initWithPlatformSettings:(PlatformSettings*)platformSettings
{
    self = [super init];
    if (self)
    {
        self.canBeModified = NO;
        self.platformSettings = platformSettings;
    }
    return self;
}

- (NSString *)name
{
    return self.platformSettings.name;
}

@end


#pragma mark --------------------------------

@implementation ProjectSettingsWindowController

- (instancetype)initWithProjectSettings:(ProjectSettings*) projectSettings;
{
    self = [self initWithWindowNibName:@"ProjectSettingsWindow"];
    
    if (self)
    {
        self.projectSettings = projectSettings;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    NSIndexSet *firstRow = [[NSIndexSet alloc] initWithIndex:0];
    [_tableView selectRowIndexes:firstRow byExtendingSelection:NO];

    [self loadDetailViewForPlatform:_projectSettings.platformsSettings[(NSUInteger) 0]];
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self loadDetailViewForPlatform:_projectSettings.platformsSettings[(NSUInteger) _tableView.selectedRow]];
}

- (void)removeAllSubviewsOfDetailView
{
    for (NSView *subview in _detailView.subviews)
    {
        [subview removeFromSuperview];
    }
}

- (void)loadDetailViewForPlatform:(PlatformSettings *)settings
{
    NSAssert(settings != nil, @"packagePublishSettings must not be nil");
    self.currentPlatformSettings = settings;

    //PlatformSettingsDetailView *view =
    [self loadViewWithNibName:@"PlatformSettingsDetailView" viewClass:[PlatformSettingsDetailView class]];
    //view.showAndroidSettings = YES;
}

- (id)loadViewWithNibName:(NSString *)nibName viewClass:(Class)viewClass
{
    NSArray *topObjects;
    [[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:&topObjects];

    [self removeAllSubviewsOfDetailView];

    for (id object in topObjects)
    {
        if ([object isKindOfClass:viewClass])
        {
            [self.detailView addSubview:object];
            return object;
        }
    }
    return nil;
}

- (IBAction)acceptSheet:(id)sender
{
    [self saveAllSettings];
    [super acceptSheet:sender];
}


- (IBAction)cancelSheet:(id)sender {
    //do nothing, also use "esc" to close this settings
    //an so project will not be republished
    //before that, just with "acceptSheet:" - even if you didn't modified anything - all res. wil be republished
    [super cancelSheet:sender];
}

- (void)saveAllSettings
{
    [_projectSettings store];
}

- (IBAction)selectPackagePublishingCustomDirectory:(id)sender;
{
    PlatformSettings *platformSettings = _projectSettings.platformsSettings[(NSUInteger) _tableView.selectedRow];

    [self selectPublishCurrentPath:platformSettings.publishDirectory
                    dirSetterBlock:^(NSString *directoryPath)
    {
        platformSettings.publishDirectory = directoryPath;
    }];
}

- (void)selectPublishCurrentPath:(NSString *)currentPath dirSetterBlock:(DirectorySetterBlock)dirSetterBlock
{
    if (!dirSetterBlock)
    {
        return;
    }

    NSString *projectDir = [_projectSettings.projectPath stringByDeletingLastPathComponent];
    NSURL *openDirectory = currentPath
        ? [NSURL fileURLWithPath:[currentPath absolutePathFromBaseDirPath:projectDir]]
        : [NSURL fileURLWithPath:projectDir];

    if (!openDirectory)
    {
        return;
    }

    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setCanCreateDirectories:YES];
    [openDlg setDirectoryURL:openDirectory];
    openDlg.delegate = self;

    [openDlg beginSheetModalForWindow:self.window completionHandler:^(NSInteger result)
    {
        if (result == NSOKButton)
        {
            NSArray *files = [openDlg URLs];
            for (NSUInteger i = 0; i < [files count]; i++)
            {
                NSString *dirName = [files[i] path];
                dirSetterBlock([dirName relativePathFromBaseDirPath:projectDir]);
            }
        }
    }];
}

- (BOOL)panel:(id)sender validateURL:(NSURL *)url error:(NSError **)outError
{
    PublishDirectoryDeletionRisk risk = [PublishUtil riskForPublishDirectoryBeingDeletedUponPublish:url.path
                                                                                      projectSettings:_projectSettings];
    if (risk == PublishDirectoryDeletionRiskSafe)
    {
        return YES;
    }

    if (risk == PublishDirectoryDeletionRiskDirectoryContainingProject)
    {
        [NSAlert showModalDialogWithTitle:@"Error" message:@"Chosen directory contains project directory. Please choose another one."];
        return NO;
    }

    if (risk == PublishDirectoryDeletionRiskNonEmptyDirectory)
    {
        NSInteger warningResult = [[NSAlert alertWithMessageText:@"Warning"
                                                   defaultButton:@"Yes"
                                                 alternateButton:@"No"
                                                     otherButton:nil
                                       informativeTextWithFormat:@"%@", @"The chosen directory is not empty, its contents will be deleted upon publishing. Are you sure?"] runModal];

        return warningResult == NSAlertDefaultReturn;
    }
    return YES;
}

@end
