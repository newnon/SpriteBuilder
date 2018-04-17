//
//  PlatformSettings.m
//  SpriteBuilder
//
//  Created by Sergey on 22.05.16.
//
//

#import "PlatformSettings.h"
#import "ResourceManager.h"
#import "ResourceManager+Publishing.h"
#import "RMPackage.h"

@interface EnumTransformer: NSValueTransformer {}
@end
@implementation EnumTransformer
+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return YES; }
-(id)transformedValue:(id)value {
    return [NSNumber numberWithInteger:[value intValue]];
}
-(id)reverseTransformedValue:(id)value {
    return [NSNumber numberWithInteger:[value intValue]];
}
@end

@interface ImageFormatQulityEnabledTransformer: NSValueTransformer {}
@end
@implementation ImageFormatQulityEnabledTransformer
+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
-(id)transformedValue:(id)value {
    switch ([value intValue]) {
        case kFCImageFormatWEBP_LOSSY:
        case kFCImageFormatJPG:
            return [NSNumber numberWithBool:YES];
            
        default:
            return [NSNumber numberWithBool:NO];
    }
}
@end

@interface ImageFormatDichterEnabledTransformer: NSValueTransformer {}
@end
@implementation ImageFormatDichterEnabledTransformer
+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
-(id)transformedValue:(id)value {
    switch ([value intValue]) {
        case kFCImageFormatPVR_RGB565:
        case kFCImageFormatPVR_RGBA4444:
            return [NSNumber numberWithBool:YES];
            
        default:
            return [NSNumber numberWithBool:NO];
    }
}
@end

@interface ImageFormatCCZEnabledTransformer: NSValueTransformer {}
@end
@implementation ImageFormatCCZEnabledTransformer
+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
-(id)transformedValue:(id)value {
    switch ([value intValue]) {
        case kFCImageFormatOriginal:
        case kFCImageFormatPNG:
        case kFCImageFormatPNG_8BIT:
        case kFCImageFormatWEBP:
        case kFCImageFormatWEBP_LOSSY:
        case kFCImageFormatJPG:
        case kFCImageFormatPNG_NO_ALPHA:
        case kFCImageFormatPNG_8BIT_NO_ALPHA:
        case kFCImageFormatWEBP_NO_ALPHA:
        case kFCImageFormatWEBP_LOSSY_NO_ALPHA:
            return [NSNumber numberWithBool:NO];
            
        default:
            return [NSNumber numberWithBool:YES];
    }
}
@end

@interface ImageFormatPOTEnabledTransformer: NSValueTransformer {}
@end
@implementation ImageFormatPOTEnabledTransformer
+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
-(id)transformedValue:(id)value {
    switch ([value intValue]) {
        case kFCImageFormatOriginal:
        case kFCImageFormatPVRTC_4BPP:
        case kFCImageFormatPVRTC_2BPP:
            return [NSNumber numberWithBool:NO];
            
        default:
            return [NSNumber numberWithBool:YES];
    }
}
@end

@interface PacketPublish : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger publish;
@property (nonatomic, assign) NSMutableDictionary *packets;
@end

@implementation PacketPublish
- (void) setPublish:(NSInteger) value
{
    _publish = value;
    if(value)
    {
        [_packets setObject:[NSNumber numberWithInteger:value] forKey:_name];
    }
    else
    {
        [_packets removeObjectForKey:_name];
    }
}
@end

@implementation PlatformSettings

- (NSArray*) packetsPublish
{
    NSMutableArray *ret = [NSMutableArray array];
    PacketPublish *mainPacket = [[PacketPublish alloc] init];
    mainPacket.name = @"Main";
    mainPacket.publish = [[_packets objectForKey:@"Main"] integerValue];
    mainPacket.packets = _packets;
    [ret addObject:mainPacket];
    for (RMPackage *package in [[ResourceManager sharedManager] allPackages])
    {
        PacketPublish *packetPublish = [[PacketPublish alloc] init];
        packetPublish.name = package.name;
        packetPublish.publish = [[_packets objectForKey:packetPublish.name] integerValue];
        packetPublish.packets = _packets;
        [ret addObject:packetPublish];
    }
    return ret;
}

- (id) serialize
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    dict[@"name"] = _name;
    
    dict[@"publishEnabled"] = @(_publishEnabled);
    dict[@"publishCCB"] = @(_publishCCB);
    dict[@"publishOther"] = @(_publishOther);
    dict[@"publishDirectory"] = _publishDirectory;
    dict[@"separatePackagesDirectory"] = _separatePackagesDirectory;
    
    dict[@"publish1x"] = @(_publish1x);
    dict[@"publish2x"] = @(_publish2x);
    dict[@"publish4x"] = @(_publish4x);
    
    dict[@"publishSound"] = @(_publishSound);
    dict[@"effectFormat"] = @(_effectFormat);
    dict[@"effectStereo"] = @(_effectStereo);
    dict[@"effectQuality"] = @(_effectQuality);
    dict[@"musicFormat"] = @(_musicFormat);
    dict[@"musicStereo"] = @(_musicStereo);
    dict[@"musicQuality"] = @(_musicQuality);
    dict[@"customSoundFormat"] = @(_customSoundFormat);
    dict[@"customSoundStereo"] = @(_customSoundStereo);
    dict[@"customSoundQuality"] = @(_customSoundQuality);
    
    dict[@"compressedImageFormat"] = @(_compressedImageFormat);
    dict[@"compressedImageQuality"] = @(_compressedImageQuality);
    dict[@"compressedImageCCZCompression"] = @(_compressedImageCCZCompression);
    dict[@"compressedImageDither"] = @(_compressedImageDither);
    dict[@"compressedImageAnySize"] = @(_compressedImageAnySize);

    dict[@"compressedNoAlphaImageFormat"] = @(_compressedNoAlphaImageFormat);
    dict[@"compressedNoAlphaImageQuality"] = @(_compressedNoAlphaImageQuality);
    dict[@"compressedNoAlphaImageCCZCompression"] = @(_compressedNoAlphaImageCCZCompression);
    dict[@"compressedNoAlphaImageDither"] = @(_compressedNoAlphaImageDither);
    dict[@"compressedNoAlphaImageAnySize"] = @(_compressedNoAlphaImageAnySize);
    
    dict[@"uncompressedImageFormat"] = @(_uncompressedImageFormat);
    dict[@"uncompressedImageQuality"] = @(_uncompressedImageQuality);
    dict[@"uncompressedImageCCZCompression"] = @(_uncompressedImageCCZCompression);
    dict[@"uncompressedImageDither"] = @(_uncompressedImageDither);
    dict[@"uncompressedImageAnySize"] = @(_uncompressedImageAnySize);
    
    dict[@"customImageFormat"] = @(_customImageFormat);
    dict[@"customImageQuality"] = @(_customImageQuality);
    dict[@"customImageCCZCompression"] = @(_customImageCCZCompression);
    dict[@"customImageDither"] = @(_customImageDither);
    dict[@"customImageAnySize"] = @(_customImageAnySize);
    
    dict[@"packets"] = _packets;
    
    return dict;
}

- (id) init
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }
    _packets = [NSMutableDictionary dictionary];
    _name = @"Empty";
    
    _publishEnabled = YES;
    _publishCCB = YES;
    _publishOther = YES;
    _publishDirectory = @"./publish";
    _separatePackagesDirectory = @"./publish_packages";
    
    _publish1x = YES;
    _publish2x = YES;
    _publish4x = YES;
    
    _publishSound = YES;
    _effectFormat = kFCSoundFormatMP3;
    _effectStereo= YES;
    _effectQuality = -1;
    _musicFormat = kFCSoundFormatMP3;
    _musicStereo = YES;
    _musicQuality = -1;
    _customSoundFormat = kFCSoundFormatMP3;
    _customSoundStereo = YES;
    _customSoundQuality = -1;
    
    _compressedImageFormat = kFCImageFormatPNG;
    _compressedImageQuality = 75;
    _compressedImageCCZCompression = YES;
    _compressedImageDither = YES;
    _compressedImageAnySize = NO;
    
    _compressedNoAlphaImageFormat = kFCImageFormatPNG;
    _compressedNoAlphaImageQuality = 75;
    _compressedNoAlphaImageCCZCompression = YES;
    _compressedNoAlphaImageDither = YES;
    _compressedNoAlphaImageAnySize = NO;
    
    _uncompressedImageFormat = kFCImageFormatPNG;
    _uncompressedImageQuality = 75;
    _uncompressedImageCCZCompression = YES;
    _uncompressedImageDither = YES;
    _uncompressedImageAnySize = NO;
    
    _customImageFormat = kFCImageFormatPNG;
    _customImageQuality = 75;
    _customImageCCZCompression = YES;
    _customImageDither = YES;
    _customImageAnySize = NO;
    return self;
}

- (id) initWithSerialization:(id)dict
{
    self = [super init];
    if (!self)
    {
        return NULL;
    }
    
    _name = [dict objectForKey:@"name"];
    self.publishEnabled = [[dict objectForKey:@"publishEnabled"] boolValue];
    self.publishCCB = [[dict objectForKey:@"publishCCB"] boolValue];
    self.publishOther = [[dict objectForKey:@"publishOther"] boolValue];
    self.publishDirectory = [dict objectForKey:@"publishDirectory"];
    self.separatePackagesDirectory = [dict objectForKey:@"separatePackagesDirectory"];
    
    self.publish1x = [[dict objectForKey:@"publish1x"] boolValue];
    self.publish2x = [[dict objectForKey:@"publish2x"] boolValue];
    self.publish4x = [[dict objectForKey:@"publish4x"] boolValue];
    
    self.publishSound = [[dict objectForKey:@"publishSound"] boolValue];
    self.effectFormat = [[dict objectForKey:@"effectFormat"] intValue];
    self.effectStereo= [[dict objectForKey:@"effectStereo"] intValue];
    self.effectQuality = [[dict objectForKey:@"effectQuality"] intValue];
    self.musicFormat = [[dict objectForKey:@"musicFormat"] intValue];
    self.musicStereo = [[dict objectForKey:@"musicStereo"] intValue];
    self.musicQuality = [[dict objectForKey:@"musicQuality"] intValue];
    self.customSoundFormat = [[dict objectForKey:@"customSoundFormat"] intValue];
    self.customSoundStereo = [[dict objectForKey:@"customSoundStereo"] intValue];
    self.customSoundQuality = [[dict objectForKey:@"customSoundQuality"] intValue];
    
    self.compressedImageFormat = [[dict objectForKey:@"compressedImageFormat"] intValue];
    self.compressedImageQuality = [[dict objectForKey:@"compressedImageQuality"] intValue];
    self.compressedImageCCZCompression = [[dict objectForKey:@"compressedImageCCZCompression"] intValue];
    self.compressedImageDither = [[dict objectForKey:@"compressedImageDither"] intValue];
    self.compressedImageAnySize = [[dict objectForKey:@"compressedImageAnySize"] intValue];
    
    self.compressedNoAlphaImageFormat = [[dict objectForKey:@"compressedNoAlphaImageFormat"] intValue];
    self.compressedNoAlphaImageQuality = [[dict objectForKey:@"compressedNoAlphaImageQuality"] intValue];
    self.compressedNoAlphaImageCCZCompression = [[dict objectForKey:@"compressedNoAlphaImageCCZCompression"] intValue];
    self.compressedNoAlphaImageDither = [[dict objectForKey:@"compressedNoAlphaImageDither"] intValue];
    self.compressedNoAlphaImageAnySize = [[dict objectForKey:@"compressedNoAlphaImageAnySize"] intValue];
    
    self.uncompressedImageFormat = [[dict objectForKey:@"uncompressedImageFormat"] intValue];
    self.uncompressedImageQuality = [[dict objectForKey:@"uncompressedImageQuality"] intValue];
    self.uncompressedImageCCZCompression = [[dict objectForKey:@"uncompressedImageCCZCompression"] intValue];
    self.uncompressedImageDither = [[dict objectForKey:@"uncompressedImageDither"] intValue];
    self.uncompressedImageAnySize = [[dict objectForKey:@"uncompressedImageAnySize"] intValue];
    
    self.customImageFormat = [[dict objectForKey:@"customImageFormat"] intValue];
    self.customImageQuality = [[dict objectForKey:@"customImageQuality"] intValue];
    self.customImageCCZCompression = [[dict objectForKey:@"customImageCCZCompression"] intValue];
    self.customImageDither = [[dict objectForKey:@"customImageDither"] intValue];
    self.customImageAnySize = [[dict objectForKey:@"customImageAnySize"] intValue];
    
    id packets = [dict objectForKey:@"packets"];
    if(packets && [packets isKindOfClass:[NSArray class]])
    {
        self.packets = [NSMutableDictionary dictionary];
        for(id packet in packets)
        {
            [self.packets setObject:[NSNumber numberWithInteger:kPlatformSettingsPublishTypesPublish] forKey:packet];
        }
    }
    else
    {
        self.packets = packets;
    }
    if(!self.packets)
        self.packets = [NSMutableDictionary dictionary];
    
    return self;
}

- (NSDictionary *)inputDirs
{
    NSMutableDictionary *inputDirs = [NSMutableDictionary dictionary];
    
    if([[_packets objectForKey:@"Main"] integerValue])
    {
        NSArray * oldResourcePaths = [[ResourceManager sharedManager] oldResourcePaths];
        for (RMDirectory *oldResourcePath in oldResourcePaths)
        {
            [inputDirs setObject:@{@"path":oldResourcePath.dirPath, @"type":[_packets objectForKey:@"Main"]} forKey:@"Main"];
        }
    }
    
    for (RMPackage *package in [[ResourceManager sharedManager] allPackages])
    {
        if([[_packets objectForKey:package.name] integerValue])
        {
            [inputDirs setObject:@{@"path":package.dirPath, @"type":[_packets objectForKey:package.name]} forKey:package.name];
        }
    }
    return inputDirs;
}
- (kFCImageFormat) imageFormat:(int)type
{
    switch (type) {
        case kPlatformSettingsImageTypesCompressed:
            return _compressedImageFormat;
            
        case kPlatformSettingsImageTypesCompressedWOAlpha:
            return _compressedNoAlphaImageFormat;
            
        case kPlatformSettingsImageTypesUncompressed:
            return _uncompressedImageFormat;
            
        case kPlatformSettingsImageTypesCustom:
            return _customImageFormat;
            
        default:
            return kFCImageFormatOriginal;
    }
}
- (int) imageQuality:(int)type
{
    switch (type) {
        case kPlatformSettingsImageTypesCompressed:
            return _compressedImageQuality;
            
        case kPlatformSettingsImageTypesCompressedWOAlpha:
            return _compressedNoAlphaImageQuality;
            
        case kPlatformSettingsImageTypesUncompressed:
            return _uncompressedImageQuality;
            
        case kPlatformSettingsImageTypesCustom:
            return _customImageQuality;
            
        default:
            return 75;
    }
}

- (BOOL) imageCCZCompression:(int)type
{
    switch (type) {
        case kPlatformSettingsImageTypesCompressed:
            return _compressedImageCCZCompression;
            
        case kPlatformSettingsImageTypesCompressedWOAlpha:
            return _compressedNoAlphaImageCCZCompression;
            
        case kPlatformSettingsImageTypesUncompressed:
            return _uncompressedImageCCZCompression;
            
        case kPlatformSettingsImageTypesCustom:
            return _customImageCCZCompression;
            
        default:
            return YES;
    }
}

- (BOOL) imageDither:(int)type
{
    switch (type) {
        case kPlatformSettingsImageTypesCompressed:
            return _compressedImageDither;
            
        case kPlatformSettingsImageTypesCompressedWOAlpha:
            return _compressedNoAlphaImageDither;
            
        case kPlatformSettingsImageTypesUncompressed:
            return _uncompressedImageDither;
            
        case kPlatformSettingsImageTypesCustom:
            return _customImageDither;
            
        default:
            return YES;
    }
}

- (BOOL) imagePOT:(int)type
{
    switch (type) {
        case kPlatformSettingsImageTypesCompressed:
            return !_compressedImageAnySize;
            
        case kPlatformSettingsImageTypesCompressedWOAlpha:
            return !_compressedNoAlphaImageAnySize;
            
        case kPlatformSettingsImageTypesUncompressed:
            return !_uncompressedImageAnySize;
            
        case kPlatformSettingsImageTypesCustom:
            return !_customImageAnySize;
            
        default:
            return YES;
    }
}

- (kFCSoundFormat) soundFormat:(int)type
{
    switch (type) {
        case kPlatformSettingsSoundTypesEffect:
            return _effectFormat;
            
        case kPlatformSettingsSoundTypesMusic:
            return _musicFormat;
            
        case kPlatformSettingsSoundTypesCustom:
            return _customSoundFormat;
            
        default:
            return YES;
    }
}

- (BOOL) soundStereo:(int)type
{
    switch (type) {
        case kPlatformSettingsSoundTypesEffect:
            return _effectStereo;
            
        case kPlatformSettingsSoundTypesMusic:
            return _musicStereo;
            
        case kPlatformSettingsSoundTypesCustom:
            return _customSoundStereo;
            
        default:
            return YES;
    }
}
- (int) soundQuality:(int)type
{
    switch (type) {
        case kPlatformSettingsSoundTypesEffect:
            return _effectQuality;
            
        case kPlatformSettingsSoundTypesMusic:
            return _musicQuality;
            
        case kPlatformSettingsSoundTypesCustom:
            return _customSoundQuality;
            
        default:
            return 4;
    }
}

- (void) setPublish1x:(BOOL)value
{
    _publish1x = value;
    self.publishImages = _publish1x || _publish2x || _publish4x;
}

- (void) setPublish2x:(BOOL)value
{
    _publish2x = value;
    self.publishImages = _publish1x || _publish2x || _publish4x;
}

- (void) setPublish4x:(BOOL)value
{
    _publish4x = value;
    self.publishImages = _publish1x || _publish2x || _publish4x;
}

-(BOOL) publishImages
{
    return _publish1x || _publish2x || _publish4x;
}

@end
