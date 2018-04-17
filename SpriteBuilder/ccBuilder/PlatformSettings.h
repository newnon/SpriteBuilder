//
//  PlatformSettings.h
//  SpriteBuilder
//
//  Created by Sergey on 22.05.16.
//
//

#import <Foundation/Foundation.h>
#import "FCFormatConverter.h"

typedef enum {
    kPlatformSettingsImageTypesCompressed = 0,
    kPlatformSettingsImageTypesCompressedWOAlpha = 1,
    kPlatformSettingsImageTypesUncompressed = 2,
    kPlatformSettingsImageTypesCustom = 3,
} PlatformSettingsImageTypes;

typedef enum {
    kPlatformSettingsSoundTypesEffect = 0,
    kPlatformSettingsSoundTypesMusic = 1,
    kPlatformSettingsSoundTypesCustom = 2,
} PlatformSettingsSoundTypes;

typedef enum {
    kPlatformSettingsPublishTypesSkip = 0,
    kPlatformSettingsPublishTypesPublish = 1,
    kPlatformSettingsPublishTypesSeparate = 2,
} PlatformSettingsPublishTypes;

@interface PlatformSettings : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString* publishDirectory;
@property (nonatomic, copy) NSString* separatePackagesDirectory;
@property (nonatomic, assign) BOOL publishEnabled;
@property (nonatomic, assign) BOOL publishCCB;
@property (nonatomic, assign) BOOL publishOther;
@property (nonatomic, assign) BOOL publishImages;
@property (nonatomic, assign) BOOL publish1x;
@property (nonatomic, assign) BOOL publish2x;
@property (nonatomic, assign) BOOL publish4x;

@property (nonatomic, assign) kFCImageFormat compressedImageFormat;
@property (nonatomic, assign) int compressedImageQuality;
@property (nonatomic, assign) BOOL compressedImageCCZCompression;
@property (nonatomic, assign) BOOL compressedImageDither;
@property (nonatomic, assign) BOOL compressedImageAnySize;

@property (nonatomic, assign) kFCImageFormat compressedNoAlphaImageFormat;
@property (nonatomic, assign) int compressedNoAlphaImageQuality;
@property (nonatomic, assign) BOOL compressedNoAlphaImageCCZCompression;
@property (nonatomic, assign) BOOL compressedNoAlphaImageDither;
@property (nonatomic, assign) BOOL compressedNoAlphaImageAnySize;

@property (nonatomic, assign) kFCImageFormat uncompressedImageFormat;
@property (nonatomic, assign) int uncompressedImageQuality;
@property (nonatomic, assign) BOOL uncompressedImageCCZCompression;
@property (nonatomic, assign) BOOL uncompressedImageDither;
@property (nonatomic, assign) BOOL uncompressedImageAnySize;

@property (nonatomic, assign) kFCImageFormat customImageFormat;
@property (nonatomic, assign) int customImageQuality;
@property (nonatomic, assign) BOOL customImageCCZCompression;
@property (nonatomic, assign) BOOL customImageDither;
@property (nonatomic, assign) BOOL customImageAnySize;

@property (nonatomic, assign) BOOL publishSound;
@property (nonatomic, assign) kFCSoundFormat effectFormat;
@property (nonatomic, assign) BOOL effectStereo;
@property (nonatomic, assign) int effectQuality;
@property (nonatomic, assign) kFCSoundFormat musicFormat;
@property (nonatomic, assign) BOOL musicStereo;
@property (nonatomic, assign) int musicQuality;
@property (nonatomic, assign) kFCSoundFormat customSoundFormat;
@property (nonatomic, assign) BOOL customSoundStereo;
@property (nonatomic, assign) int customSoundQuality;
@property (nonatomic, retain) NSMutableDictionary *packets;
@property (nonatomic, retain, readonly) NSArray *packetsPublish;
@property (nonatomic, copy, readonly) NSDictionary *inputDirs;


- (id) initWithSerialization:(id)dict;
- (id) init;
- (id) serialize;

- (kFCImageFormat) imageFormat:(int)type;
- (int) imageQuality:(int)type;
- (BOOL) imageCCZCompression:(int)type;
- (BOOL) imageDither:(int)type;
- (BOOL) imagePOT:(int)type;

- (kFCSoundFormat) soundFormat:(int)type;
- (BOOL) soundStereo:(int)type;
- (int) soundQuality:(int)type;

@end
