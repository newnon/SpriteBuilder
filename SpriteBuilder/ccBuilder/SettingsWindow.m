//
//  SettingsWindow.m
//  SpriteBuilderX
//
//  Created by Volodymyr Klymenko on 2/5/17.
//
//

#import "SettingsWindow.h"
#import "NSString+RelativePath.h"
#import "SettingsManager.h"

typedef void (^DirectorySetterBlock)(NSString *directoryPath);

@interface SettingsWindow ()
{
    BOOL _enableBackup;
    bool _storeMiscFilesAtPath;
}

@end

@implementation SettingsWindow

- (instancetype)init {
    self = [self initWithWindowNibName:@"SettingsWindow"];
    
    if (self) {
        _enableBackup = SBSettings.enableBackup;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirBackup;
        if(![fileManager fileExistsAtPath: SBSettings.backupPath isDirectory:&isDirBackup]) {
            if(![fileManager createDirectoryAtPath: SBSettings.backupPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
                NSLog(@"Error: Create backups folder failed %@",  SBSettings.backupPath);
            }
        }
        _storeMiscFilesAtPath = SBSettings.storeMiscFilesAtPath;
        BOOL isDirMiscFile;
        if(![fileManager fileExistsAtPath: SBSettings.miscFilesPath isDirectory:&isDirMiscFile]) {
            if(![fileManager createDirectoryAtPath: SBSettings.miscFilesPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
                NSLog(@"Error: Create miscFilesPath folder failed %@",  SBSettings.miscFilesPath);
            }
        }
        
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self updateUIValues];
    [self updateBackupButtons];
    [self updatePathsButtons];
    [self.backupPathField.window makeFirstResponder:nil];
    [self.settingsTabView selectTabViewItemAtIndex:SBSettings.selectedSettingsTab];
}

-(void) updateBackupButtons {
    if (_enableBackup) {
        self.enableBackupCheckBox.state = NSOnState;
        self.backupIntervalPopUpButton.enabled = YES;
        self.backupPathField.enabled = YES;
        self.selectPathButton.enabled = YES;
    } else {
        self.enableBackupCheckBox.state = NSOffState;;
        self.backupIntervalPopUpButton.enabled = NO;
        self.backupPathField.enabled = NO;
        self.selectPathButton.enabled = NO;
    }
}

-(void) updatePathsButtons {
    if (_storeMiscFilesAtPath) {
        self.storeMiscFilesCheckBox.state = NSOnState;
        self.storeMiscFilesPathField.hidden = NO;
        self.storeAlongProjectField.hidden = YES;
        self.selectMiscPathButton.enabled = YES;
    } else {
        self.storeMiscFilesCheckBox.state = NSOffState;
        self.storeMiscFilesPathField.hidden = YES;
        self.storeAlongProjectField.hidden = NO;
        self.selectMiscPathButton.enabled = NO;
    }
}

-(void) updateUIValues {
    [self.backupIntervalPopUpButton selectItemWithTag: SBSettings.backupInterval];
    [self.backupPathField setStringValue: SBSettings.backupPath];
    
    self.stepAnchorX.floatValue = SBSettings.defaultSpriteAnchorX;
    self.stepAnchorY.floatValue = SBSettings.defaultSpriteAnchorY;
    
    self.storeMiscFilesPathField.stringValue = SBSettings.miscFilesPath;
    
    [self.defaultSpritePositionType selectItemWithTag:SBSettings.defaultSpritePositionUnit];
    self.restoreOpenedDocuments.state = SBSettings.restoreOpenedDocuments;
    self.moveNodeOnCopy.state = SBSettings.moveNodeOnCopy;
    self.autoPublish.state = SBSettings.autoPublish;
}

- (IBAction)enableBackup:(NSButton *)sender {
    if (sender.state == NSOnState) {
        _enableBackup = YES;
    } else {
        _enableBackup = NO;
    }
    [self updateBackupButtons];
}

- (IBAction)resetBackupSettings:(id)sender {
    [SBSettings resetBackupSettings];
    _enableBackup = SBSettings.enableBackup;
    [self updateUIValues];
    [self updateBackupButtons];
}

- (IBAction)resetPathsSettings:(NSButton *)sender {
    [SBSettings resetPathsSettings];
    _storeMiscFilesAtPath = SBSettings.storeMiscFilesAtPath;
    [self updateUIValues];
    [self updatePathsButtons];
}


- (IBAction)storeMiscFiles:(NSButton *)sender {
    if (sender.state == NSOnState) {
        _storeMiscFilesAtPath = YES;
    } else {
        _storeMiscFilesAtPath = NO;
    }
    [self updatePathsButtons];
}


- (IBAction)acceptSheet:(id)sender {
    SBSettings.backupInterval = self.backupIntervalPopUpButton.selectedTag;
    SBSettings.enableBackup = _enableBackup;
    SBSettings.backupPath = self.backupPathField.stringValue;
    SBSettings.selectedSettingsTab = [self.settingsTabView.selectedTabViewItem.identifier intValue];
    SBSettings.defaultSpriteAnchorX = self.stepAnchorX.floatValue;
    SBSettings.defaultSpriteAnchorY = self.stepAnchorY.floatValue;
    SBSettings.storeMiscFilesAtPath = _storeMiscFilesAtPath;
    SBSettings.miscFilesPath = self.storeMiscFilesPathField.stringValue;
    SBSettings.defaultSpritePositionUnit = self.defaultSpritePositionType.selectedTag;
    SBSettings.restoreOpenedDocuments = self.restoreOpenedDocuments.state;
    SBSettings.moveNodeOnCopy = self.moveNodeOnCopy.state;
    SBSettings.autoPublish = self.autoPublish.state;
    
    [SBSettings save];
    [super acceptSheet:sender];
}


- (IBAction)cancelSheet:(id)sender {
    [super cancelSheet:sender];
}

- (IBAction)selectMiscFilesDirectory:(id)sender {
    
    [self selectPublishCurrentPath:self.storeMiscFilesPathField.stringValue dirSetterBlock:^(NSString *directoryPath) {
        self.storeMiscFilesPathField.stringValue = directoryPath;
    }];
}

- (IBAction)selectBackupsDirectory:(id)sender {
    
    [self selectPublishCurrentPath:self.backupPathField.stringValue dirSetterBlock:^(NSString *directoryPath) {
         self.backupPathField.stringValue = directoryPath;
     }];
}

- (void)selectPublishCurrentPath:(NSString *)currentPath dirSetterBlock:(DirectorySetterBlock)dirSetterBlock {
    if (!dirSetterBlock) {
        return;
    }
    if (!currentPath) {
        return;
    }
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setCanCreateDirectories:YES];
    [openDlg setDirectoryURL:[NSURL fileURLWithPath:currentPath]];
    openDlg.delegate = self;
    
    [openDlg beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
         if (result == NSOKButton) {
             NSArray *files = [openDlg URLs];
             for (NSUInteger i = 0; i < [files count]; i++) {
                 NSString *dirName = [files[i] path];
                 dirSetterBlock(dirName);
             }
         }
     }];
}


@end
