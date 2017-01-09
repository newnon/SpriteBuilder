#import "PublishGeneratedFilesOperation.h"

#import "ProjectSettings.h"
#import "PublishRenamedFilesLookup.h"
#import "PublishingTaskStatusProgress.h"


@implementation PublishGeneratedFilesOperation

- (void)main
{
    [super main];

    [self assertProperties];

    [self publishGeneratedFiles];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)assertProperties
{
    NSAssert(_outputDir != nil, @"outputDir should not be nil");
    NSAssert(_publishedSpriteSheetFiles != nil, @"publishedSpriteSheetFiles should not be nil");
    NSAssert(_fileLookup != nil, @"fileLookup should not be nil");
}

- (void)publishGeneratedFiles
{
    [_publishingTaskStatusProgress updateStatusText:@"Generating misc files"];

    // Create the directory if it doesn't exist
    BOOL createdDirs = [[NSFileManager defaultManager] createDirectoryAtPath:_outputDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    if (!createdDirs)
    {
        [_warnings addWarningWithDescription:@"Failed to create output directory %@" isFatal:YES];
        return;
    }

    [self generateFileLookup];

    [self generateSpriteFrameFileList];

    [self generateCocos2dSetupFile];
}

- (void)generateCocos2dSetupFile
{
    NSMutableDictionary* configCocos2d = [NSMutableDictionary dictionary];

    NSString* sceneScaleType = @"CCSceneScaleDefault";
    if (_projectSettings.sceneScaleType == kCCBSceneScaleTypeNONE)
    {
        sceneScaleType = @"CCSceneScaleNone";
    }
    else if (_projectSettings.sceneScaleType == kCCBSceneScaleTypeCUSTOM)
    {
        sceneScaleType = @"CCSceneScaleCustom";
    }
    else if (_projectSettings.sceneScaleType == kCCBSceneScaleTypeMINSIZE)
    {
        sceneScaleType = @"CCSceneScaleMinSize";
    }
    else if (_projectSettings.sceneScaleType == kCCBSceneScaleTypeMAXSIZE)
    {
        sceneScaleType = @"CCSceneScaleMaxSize";
    }
    else if (_projectSettings.sceneScaleType == kCCBSceneScaleTypeMINSCALE)
    {
        sceneScaleType = @"CCSceneScaleMinScale";
    }
    else if (_projectSettings.sceneScaleType == kCCBSceneScaleTypeMAXSCALE)
    {
        sceneScaleType = @"CCSceneScaleMaxScale";
    }
    [configCocos2d setObject:sceneScaleType forKey:@"CCSceneScaleType"];

    if((_projectSettings.designSizeHeight !=0) && (_projectSettings.designSizeWidth !=0) && (_projectSettings.designResourceScale !=0.0f))
    {
        [configCocos2d setObject:[NSNumber numberWithInt:_projectSettings.designSizeHeight] forKey:@"CCSetupDesignSizeHeight"];
        [configCocos2d setObject:[NSNumber numberWithInt:_projectSettings.designSizeWidth] forKey:@"CCSetupDesignSizeWidth"];
        [configCocos2d setObject:[NSNumber numberWithFloat:_projectSettings.designResourceScale] forKey:@"CCSetupDesignResourceScale"];
    }

    NSString *configCocos2dFile = [_outputDir stringByAppendingPathComponent:@"configCocos2d.plist"];
    [configCocos2d writeToFile:configCocos2dFile atomically:YES];
}

- (void)generateSpriteFrameFileList
{
    NSMutableDictionary*spriteFrameFileList = [NSMutableDictionary dictionary];

    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    [metadata setObject:[NSNumber numberWithInt:1] forKey:@"version"];

    [spriteFrameFileList setObject:metadata forKey:@"metadata"];
    [spriteFrameFileList setObject:[_publishedSpriteSheetFiles allObjects] forKey:@"spriteFrameFiles"];

    NSString* spriteSheetLookupFile = [_outputDir stringByAppendingPathComponent:@"spriteFrameFileList.plist"];
    [spriteFrameFileList writeToFile:spriteSheetLookupFile atomically:YES];
}

- (void)generateFileLookup
{
    if (![_fileLookup writeToFileAtomically:[_outputDir stringByAppendingPathComponent:@"fileLookup.plist"]])
    {
        [_warnings addWarningWithDescription:@"Could not write fileLookup.plist."];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"target: %@, outputdir: %@, ", _platformName, _outputDir];
}

@end
