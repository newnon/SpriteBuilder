#import "PublishSpriteSheetOperation.h"

#import "CCBFileUtil.h"
#import "Tupac.h"
#import "PublishingTaskStatusProgress.h"
#import "ProjectSettings.h"
#import "ResourcePropertyKeys.h"
#import "MiscConstants.h"
#import "PlatformSettings.h"
#import "SettingsManager.h"
#import "ResourceManager.h"

@interface PublishSpriteSheetOperation()

@property (nonatomic, strong) Tupac *packer;
@property (nonatomic, copy) NSString *previewFilePath;
@property (nonatomic) int format;
@property (nonatomic) BOOL trim;
@property (nonatomic) int format_padding;
@property (nonatomic) int format_extrude;

@end


// To prevent generation of previews for the same sprite sheet across resolutions
// the names are stored and queried in this var
static NSMutableSet *__spriteSheetPreviewsGenerated;


@implementation PublishSpriteSheetOperation

+ (void)initialize
{
    [self resetSpriteSheetPreviewsGeneration];
}

+ (void)resetSpriteSheetPreviewsGeneration
{
    __spriteSheetPreviewsGenerated = [NSMutableSet set];
}

- (void)main
{
    [super main];

    [self assertProperties];

    [self publishSpriteSheet];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)assertProperties
{
    NSAssert(_spriteSheetFile != nil, @"spriteSheetFile should not be nil");
    NSAssert(_subPath != nil, @"subPath should not be nil");
    NSAssert(_srcDirs != nil, @"srcDirs should not be nil");
    NSAssert(_resolution != nil, @"resolution should not be nil");
    NSAssert(_srcSpriteSheetDate != nil, @"srcSpriteSheetDate should not be nil");
    NSAssert(_publishDirectory != nil, @"publishDirectory should not be nil");
}

- (void)publishSpriteSheet
{
    [_publishingTaskStatusProgress updateStatusText:[NSString stringWithFormat:@"Generating sprite sheet %@...", [_subPath lastPathComponent]]];

    [self loadSettings];

    [self configurePacker];

    NSArray *createdFiles = [_packer createTextureAtlasFromDirectoryPathsRecursive:_srcDirs ignoreDirs:[ResourceManager resIndependentDirs]];

    [self processWarnings];

    [self setDateForCreatedFiles:createdFiles];
}

- (void)setDateForCreatedFiles:(NSArray *)createFiles
{
    for (NSString *filePath in createFiles)
    {
        [CCBFileUtil setModificationDate:_srcSpriteSheetDate forFile:filePath];
    }
}

- (void)processWarnings
{
    if (_packer.errorMessage)
    {
        [_warnings addWarningWithDescription:_packer.errorMessage
                                     isFatal:NO
                                 relatedFile:_subPath
                                  resolution:_resolution];
    }
}

- (void)generatePreviewFilePath
{
    self.previewFilePath = nil;
    if (![__spriteSheetPreviewsGenerated containsObject:_subPath])
    {
//        NSString *filePath = [SBSettings miscFilesPathForFile:_publishDirectory projectPathDir:self.projectSettings.projectPathDir];
//        self.previewFilePath = [filePath stringByAppendingPathExtension:MISC_FILE_PPNG];
        [__spriteSheetPreviewsGenerated addObject:_subPath];
    }
    //NSLog(@"%@",_subPath);
    //this method called more than 2 times..why? so .previewFilePath becomes nil, method generatePreviewImage in Tupac always do nothing
    //because [spriteSheetPreviewsGenerated containsObject:_subPath]
    //probably should be re-fxied
    //and has a small problem - preview will be generated from tablethd image, too big for preview..
    //check addintional quick fix for that in Tupac.mm method - generatePreviewImage
    //actually I've resized preview to even smaller size for speed
    NSString *filePath = [SBSettings miscFilesPathForFile:_publishDirectory projectPathDir:self.projectSettings.projectPathDir];
    self.previewFilePath = [filePath stringByAppendingPathExtension:MISC_FILE_PPNG];
}

- (void)configurePacker
{
    [self generatePreviewFilePath];

    self.packer = [[Tupac alloc] init];
    _packer.outputName = _spriteSheetFile;
    _packer.previewFile = _previewFilePath;
    _packer.directoryPrefix = _subPath;
    _packer.border = YES;
    _packer.trim = _trim;
    _packer.padding = self.format_padding;
    _packer.extrude = self.format_extrude;
    _packer.optimize = self.projectSettings.publishEnvironment == kCCBPublishEnvironmentRelease;

    [self setImageFormatDependingOnTarget];

    [self setTextureMaxSize];
}

- (void)setImageFormatDependingOnTarget
{
    _packer.imageFormat = [_platformSettings imageFormat:self.format];
    _packer.compress = [_platformSettings imageCCZCompression:self.format];
    _packer.dither = [_platformSettings imageDither:self.format];
    _packer.imageQuality = [_platformSettings imageQuality:self.format];
    _packer.pot = [_platformSettings imagePOT:self.format];
}

- (void)setTextureMaxSize
{
    if ([_resolution isEqualToString:RESOLUTION_PHONE])
    {
        _packer.maxTextureSize = 2048;
    }
    else if ([_resolution isEqualToString:RESOLUTION_PHONE_HD])
    {
        _packer.maxTextureSize = 4096;
    }
    else if ([_resolution isEqualToString:RESOLUTION_TABLET])
    {
        _packer.maxTextureSize = 4096;
    }
    else if ([_resolution isEqualToString:RESOLUTION_TABLET_HD])
    {
        _packer.maxTextureSize = 4096;
    }
    else if ([_resolution isEqualToString:RESOLUTION_UNIVERSAL])
    {
        _packer.maxTextureSize = 4096;
    }
}

- (void)loadSettings
{
    self.format = [[_projectSettings propertyForRelPath:_subPath andKey:RESOURCE_PROPERTY_IMAGE_FORMAT] intValue];
    self.trim = [[_projectSettings propertyForRelPath:_subPath andKey:RESOURCE_PROPERTY_TRIM_SPRITES] boolValue];
    self.format_padding = [[_projectSettings propertyForRelPath:_subPath andKey:RESOURCE_PROPERTY_FORMAT_PADDING] integerValue];
    self.format_extrude = [[_projectSettings propertyForRelPath:_subPath andKey:RESOURCE_PROPERTY_FORMAT_EXTRUDE] integerValue];
}

- (void)cancel
{
    [super cancel];
    [_packer cancel];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"file: %@, res: %@, osType: %@, filefull: %@, srcdirs: %@, publishDirectory: %@, date: %@",
                                      [_spriteSheetFile lastPathComponent], _resolution, _platformName, _spriteSheetFile, _srcDirs, _publishDirectory, _srcSpriteSheetDate];
}


@end
