//
//  SettingsManager.m
//  SpriteBuilderX
//
//  Created by Sergey on 08.02.17.
//
//

#import "SettingsManager.h"
#import "AppDelegate.h"
#import "CocosScene.h"

@implementation SettingsManager

+ (instancetype)instance {
    static SettingsManager *sharedSettingsManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSettingsManager = [[self alloc] init];
    });
    return sharedSettingsManager;
}

- (id)init {
    if (self = [super init]) {
        //someProperty = [[NSString alloc] initWithString:@"Default Property Value"];
    }
    return self;
}

-(NSString *) defaultSBFolderPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *productName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    NSString *defaultPath = [[paths firstObject] stringByAppendingPathComponent:productName];
    return defaultPath;
}

-(NSString *) defaultBackupPath {
    NSString *defaultPath = [[self defaultSBFolderPath] stringByAppendingPathComponent:@"Backups"];
    return defaultPath;
}

-(NSString *) defaultMiscFilesPath {
    NSString *defaultPath = [[self defaultSBFolderPath] stringByAppendingPathComponent:@"MiscFiles"];
    return defaultPath;
}

- (void) setStoreMiscFilesAtPath:(BOOL)storeMiscFilesAtPath  {
    [SBUserDefaults setObject:[NSNumber numberWithBool:storeMiscFilesAtPath] forKey:@"storeMiscFilesAtPath"];
}

- (BOOL) storeMiscFilesAtPath {
    id storeMiscFilesAtPath = [SBUserDefaults valueForKey:@"storeMiscFilesAtPath"];
    if(!storeMiscFilesAtPath)
        return YES;
    return [storeMiscFilesAtPath boolValue];
}

- (void) setMiscFilesPath:(NSString *)miscFilesPath {
    [SBUserDefaults setObject:miscFilesPath forKey:@"miscFilesPath"];
}

- (NSString*) miscFilesPath {
    id miscFilesPath = [SBUserDefaults valueForKey:@"miscFilesPath"];
    if(!miscFilesPath)
        return [self defaultMiscFilesPath];
    return miscFilesPath;
}

- (void) setBackupPath:(NSString *)backupPath
{
    [SBUserDefaults setObject:backupPath forKey:@"backupPath"];
}

- (NSString*) backupPath
{
    id backupPath = [SBUserDefaults valueForKey:@"backupPath"];
    if(!backupPath)
        return [self defaultBackupPath];
    return backupPath;
}

- (void) setBackupInterval:(NSInteger)backupInterval
{
    [SBUserDefaults setObject:[NSNumber numberWithInteger:backupInterval] forKey:@"backupInterval"];
}

- (NSInteger) backupInterval
{
    id backupInterval = [SBUserDefaults valueForKey:@"backupInterval"];
    if(!backupInterval)
        return 10;
    return [backupInterval integerValue];
}

- (void) setEnableBackup:(BOOL)enableBackup
{
    [SBUserDefaults setObject:[NSNumber numberWithBool:enableBackup] forKey:@"enableBackup"];
}

- (BOOL) enableBackup
{
    id enableBackup = [SBUserDefaults valueForKey:@"enableBackup"];
    if(!enableBackup)
        return YES;
    return [enableBackup boolValue];
}

-(void) setSelectedSettingsTab:(int)selectedSettingsTab {
    [SBUserDefaults setObject:@(selectedSettingsTab) forKey:@"selectedSettingsTab"];
}

-(int) selectedSettingsTab {
    id selectedTab = [SBUserDefaults objectForKey:@"selectedSettingsTab"];
    if (!selectedTab) {
        return 0;
    }
    return [selectedTab intValue];
}

-(void) setDefaultSpriteAnchorX:(float)defaultSpriteAnchorX {
    [SBUserDefaults setObject:@(defaultSpriteAnchorX) forKey:@"defaultSpriteAnchorX"];
}

-(float) defaultSpriteAnchorX {
    id anchorX = [SBUserDefaults objectForKey:@"defaultSpriteAnchorX"];
    if (!anchorX) {
        return 0.5;
    }
    return [anchorX floatValue];
}

-(void) setDefaultSpriteAnchorY:(float)defaultSpriteAnchorY {
    [SBUserDefaults setObject:@(defaultSpriteAnchorY) forKey:@"defaultSpriteAnchorY"];
}

-(float) defaultSpriteAnchorY {
    id anchorY = [SBUserDefaults objectForKey:@"defaultSpriteAnchorY"];
    if (!anchorY) {
        return 0.5;
    }
    return [anchorY floatValue];
}

-(void) setDefaultSpritePositionUnit:(CCPositionUnit)defaultSpritePositionUnit {
    [SBUserDefaults setObject:@(defaultSpritePositionUnit) forKey:@"defaultSpritePositionUnit"];
}

-(CCPositionUnit) defaultSpritePositionUnit {
    id defaultSpritePositionUnit = [SBUserDefaults objectForKey:@"defaultSpritePositionUnit"];
    if (!defaultSpritePositionUnit) {
        return CCPositionUnitUIPoints;
    }
    return [defaultSpritePositionUnit intValue];
}

-(void) setRestoreOpenedDocuments:(BOOL)restoreOpenedDocuments {
    [SBUserDefaults setObject:[NSNumber numberWithBool:restoreOpenedDocuments] forKey:@"restoreOpenedDocuments"];
}

-(BOOL) restoreOpenedDocuments {
    id restoreOpenedDocuments = [SBUserDefaults valueForKey:@"restoreOpenedDocuments"];
    if(!restoreOpenedDocuments)
        return YES;
    return [restoreOpenedDocuments boolValue];
}

-(void) setOpenedDocuments:(NSMutableDictionary *) openedDocuments {
    [SBUserDefaults setObject: openedDocuments forKey:@"openedDocs"];
}

-(NSMutableDictionary *) openedDocuments {
    id openedDocuments = [SBUserDefaults objectForKey:@"openedDocs"];
    if (!openedDocuments) {
        return [NSMutableDictionary dictionary];
    }
    return openedDocuments;
}

-(void) setMoveNodeOnCopy:(BOOL)moveNodeOnCopy {
    [SBUserDefaults setObject:[NSNumber numberWithBool:moveNodeOnCopy] forKey:@"moveNodeOnCopy"];
}

-(BOOL) moveNodeOnCopy {
    id moveNodeOnCopy = [SBUserDefaults valueForKey:@"moveNodeOnCopy"];
    if(!moveNodeOnCopy)
        return NO;
    return [moveNodeOnCopy boolValue];
}

-(void) setAutoPublish:(BOOL)autoPublish {
    [SBUserDefaults setObject:[NSNumber numberWithBool:autoPublish] forKey:@"autoPublish"];
}

-(BOOL) autoPublish {
    id autoPublish = [SBUserDefaults valueForKey:@"autoPublish"];
    if(!autoPublish)
        return YES;
    return [autoPublish boolValue];
}

-(void) setShowPrefabs:(BOOL)showPrefabs {
    [SBUserDefaults setObject:[NSNumber numberWithBool:showPrefabs] forKey:@"showPrefabs"];
}

-(BOOL) showPrefabs {
    id showPrefabs = [SBUserDefaults valueForKey:@"showPrefabs"];
    if(!showPrefabs)
        return YES;
    return [showPrefabs boolValue];
}

-(void) setShowPrefabPreview:(BOOL)showPrefabPreview {
    [SBUserDefaults setObject:[NSNumber numberWithBool:showPrefabPreview] forKey:@"showPrefabPreview"];
}

-(BOOL) showPrefabPreview {
    id showPrefabPreview = [SBUserDefaults valueForKey:@"showPrefabPreview"];
    if(!showPrefabPreview)
        return YES;
    return [showPrefabPreview boolValue];
}

-(void) setSortCustomProperties:(BOOL)sortCustomProperties {
    [SBUserDefaults setObject:[NSNumber numberWithBool:sortCustomProperties] forKey:@"sortCustomProperties"];
}

-(BOOL) sortCustomProperties {
    id sortCustomProperties = [SBUserDefaults valueForKey:@"sortCustomProperties"];
    if(!sortCustomProperties)
        return NO;
    return [sortCustomProperties boolValue];
}

-(void) setShowRulers:(BOOL)showRulers {
    [SBUserDefaults setObject:[NSNumber numberWithBool:showRulers] forKey:@"showRulers"];
}

-(BOOL) showRulers {
    id showRulers = [SBUserDefaults valueForKey:@"showRulers"];
    if(!showRulers)
        return YES;
    return [showRulers boolValue];
}

-(void) setExpandedSeparators:(NSMutableDictionary *) expandedSeparators {
    [SBUserDefaults setObject:expandedSeparators forKey:@"expandedSeparators"];
}

-(NSMutableDictionary *) expandedSeparators {
    id expandedSeparators = [SBUserDefaults objectForKey:@"expandedSeparators"];
    if(!expandedSeparators){
        return [NSMutableDictionary dictionary];
    }
    return expandedSeparators;
}

-(void) setBgLayerColor:(int)bgLayerColor {
    [SBUserDefaults setObject:@(bgLayerColor) forKey:@"bgLayerColor"];
}

-(int) bgLayerColor {
    id bgLayerColor = [SBUserDefaults objectForKey:@"bgLayerColor"];
    if (!bgLayerColor) {
        return kCCBCanvasColorLightGray;
    }
    return [bgLayerColor intValue];
}

-(void) setMainStageColor:(int)mainStageColor {
    [SBUserDefaults setObject:@(mainStageColor) forKey:@"mainStageColor"];
}

-(int) mainStageColor {
    id mainStageColor = [SBUserDefaults objectForKey:@"mainStageColor"];
    if (!mainStageColor) {
        return -1; //stageColor used by default
    }
    return [mainStageColor intValue];
}

//------------------------------------------------------------------------
- (void) save
{
    [SBUserDefaults synchronize];
}

- (void)resetBackupSettings
{
    self.enableBackup = YES;
    self.backupInterval = 10;
    self.backupPath = [self defaultBackupPath];
}

- (void) resetPathsSettings {
    self.storeMiscFilesAtPath = YES;
    self.miscFilesPath = [self defaultMiscFilesPath];
}

- (NSString *) miscFilesPathForFile:(NSString *) filePath projectPathDir:(NSString *) projectPathDir {
    if (!self.storeMiscFilesAtPath) {
        return filePath;
    }
    NSString *projPath = [projectPathDir stringByDeletingLastPathComponent];
    NSString *miscFilePath = [filePath stringByReplacingOccurrencesOfString:projPath withString:self.miscFilesPath];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[miscFilePath stringByDeletingLastPathComponent]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    return miscFilePath;
}


@end
