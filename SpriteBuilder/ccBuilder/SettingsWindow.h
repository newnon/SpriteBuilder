//
//  SettingsWindow.h
//  SpriteBuilderX
//
//  Created by Volodymyr Klymenko on 2/5/17.
//
//

#import "CCBModalSheetController.h"

@interface SettingsWindow : CCBModalSheetController <NSOpenSavePanelDelegate> {
}
@property (weak) IBOutlet NSButton *enableBackupCheckBox;
@property (weak) IBOutlet NSPopUpButton *backupIntervalPopUpButton;
@property (weak) IBOutlet NSTextField *backupPathField;
@property (weak) IBOutlet NSButton *selectPathButton;

@property (weak) IBOutlet NSTabView *settingsTabView;

@property (weak) IBOutlet NSTextField *defaultSpriteAnchorX;
@property (weak) IBOutlet NSTextField *defaultSpriteAnchorY;

@property (weak) IBOutlet NSStepper *stepAnchorX;
@property (weak) IBOutlet NSStepper *stepAnchorY;

@property (weak) IBOutlet NSButton *storeMiscFilesCheckBox;
@property (weak) IBOutlet NSTextField *storeMiscFilesPathField;
@property (weak) IBOutlet NSTextField *storeAlongProjectField;
@property (weak) IBOutlet NSButton *selectMiscPathButton;

@property (weak) IBOutlet NSPopUpButton *defaultSpritePositionType;

@property (weak) IBOutlet NSButton *restoreOpenedDocuments;
@property (weak) IBOutlet NSButton *moveNodeOnCopy;
@property (weak) IBOutlet NSButton *autoPublish;

@end
