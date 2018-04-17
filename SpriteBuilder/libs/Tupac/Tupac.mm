
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

#import "Tupac.h"
#import "FCFormatConverter.h"
#import "FCFormatConverter.h"
#import "MaxRectsBinPack.h"
#import "vector"

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CGImage.h>

#import "pvrtc.h"
#import <CommonCrypto/CommonDigest.h>

unsigned long upper_power_of_two(unsigned long v)
{
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;
    return v;
}

typedef struct _PVRTexHeader
{
    uint32_t headerLength;
    uint32_t height;
    uint32_t width;
    uint32_t numMipmaps;
    uint32_t flags;
    uint32_t dataLength;
    uint32_t bpp;
    uint32_t bitmaskRed;
    uint32_t bitmaskGreen;
    uint32_t bitmaskBlue;
    uint32_t bitmaskAlpha;
    uint32_t pvrTag;
    uint32_t numSurfs;
} PVRTexHeader;


@interface Tupac ()
@property (nonatomic, strong) FCFormatConverter *formatConverter;
@end

@implementation Tupac {
    BOOL cancelled_;
}

@synthesize scale=scale_, border=border_, filenames=filenames_, outputName=outputName_, imageFormat=imageFormat_, imageQuality=imageQuality_, directoryPrefix=directoryPrefix_, maxTextureSize=maxTextureSize_, padding=padding_, extrude=extrude_, dither=dither_, compress=compress_, optimize=optimize_;
@synthesize errorMessage;

+ (Tupac*) tupac
{
    return [[Tupac alloc] init];
}

- (id)init
{
    if ((self = [super init]))
    {
        scale_ = 1.0;
        border_ = NO;
        cancelled_ = NO;
        imageFormat_ = kFCImageFormatPNG;
        self.maxTextureSize = 2048;
        self.padding = 1;
        self.trim = YES;
        self.extrude = 1;
        self.pot = YES;
    }
    return self;
}


- (void)setErrorMessage:(NSString *)em
{
    if (em != errorMessage)
    {
        errorMessage = em;
    }
}

+ (NSRect) trimmedRectForImage:(CGImageRef)image
{
    int w = (int)CGImageGetWidth(image);
    int h = (int)CGImageGetHeight(image);
    
    int bytesPerRow = (int)CGImageGetBytesPerRow(image);
    int pixelsPerRow = bytesPerRow/4;
    
    CGImageGetDataProvider((CGImageRef)image);
    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(image));
    const UInt32 *pixels = (const UInt32*)CFDataGetBytePtr(imageData);
    
    // Search from left
    int x;
    for (x = 0; x < w; x++)
    {
        BOOL emptyRow = YES;
        for (int y = 0; y < h; y++)
        {
            if (pixels[y*pixelsPerRow+x] & 0xff000000)
            {
                emptyRow = NO;
            }
        }
        if (!emptyRow) break;
    }
    
    // Search from right
    int xRight;
    for (xRight = w-1; xRight >= 0; xRight--)
    {
        BOOL emptyRow = YES;
        for (int y = 0; y < h; y++)
        {
            if (pixels[y*pixelsPerRow+xRight] & 0xff000000)
            {
                emptyRow = NO;
            }
        }
        if (!emptyRow) break;
    }
    
    // Search from bottom
    int y;
    for (y = 0; y < h; y++)
    {
        BOOL emptyRow = YES;
        for (int x = 0; x < w; x++)
        {
            if (pixels[y*pixelsPerRow+x] & 0xff000000)
            {
                emptyRow = NO;
            }
        }
        if (!emptyRow) break;
    }
    
    // Search from top
    int yTop;
    for (yTop = h-1; yTop >=0; yTop--)
    {
        BOOL emptyRow = YES;
        for (int x = 0; x < w; x++)
        {
            if (pixels[yTop*pixelsPerRow+x] & 0xff000000)
            {
                emptyRow = NO;
            }
        }
        if (!emptyRow) break;
    }
    
    int wTrimmed = xRight-x+1;
    int hTrimmed = yTop-y+1;
    
    if(wTrimmed < 0)
        wTrimmed = 0;
    
    if(hTrimmed < 0)
        hTrimmed = 0;
    
    CFRelease(imageData);
    
    // HACK to fix jitter
    if (wTrimmed % 2 == 1) wTrimmed += 1;
    if (hTrimmed % 2 == 1) hTrimmed += 1;
    if (wTrimmed + x > w)
    {
        x = 0;
        wTrimmed = w;
    }
    if (hTrimmed + y > h)
    {
        y = 0;
        hTrimmed = h;
    }
    
    return NSMakeRect(x, y, wTrimmed, hTrimmed);
}

- (void)sha512HashFromCGImage:(CGImageRef)image
                      hash:(unsigned char*)hash
{
    CGDataProviderRef dataProvider = CGImageGetDataProvider(image);
    NSData *data = (NSData*)CFBridgingRelease(CGDataProviderCopyData(dataProvider));
    CC_SHA512([data bytes], [data length], hash);
}

- (BOOL)compareCGImages:(CGImageRef)image1
                  image:(CGImageRef)image2
{
    CGDataProviderRef dataProvider1 = CGImageGetDataProvider(image1);
    NSData *data1 = (NSData*)CFBridgingRelease(CGDataProviderCopyData(dataProvider1));
    CGDataProviderRef dataProvider2 = CGImageGetDataProvider(image2);
    NSData *data2 = (NSData*)CFBridgingRelease(CGDataProviderCopyData(dataProvider2));
    return [data1 isEqualToData:data2];
}

static int reduceHorizontalSize(const std::vector<TPRectSize> &inRects, int outW, int outH, int method, int numImages, std::vector<TPRect> &tempOutRects)
{
    int minOutW = outW/2;
    int maxOutW = outW;
    int curOutW = (minOutW + maxOutW) / 2;
    int lastOutW = outW;
    while (curOutW != lastOutW) {
        MaxRectsBinPack tempBin(curOutW, outH);
        tempOutRects.reserve(inRects.size());
        tempBin.Insert(inRects, tempOutRects, (MaxRectsBinPack::FreeRectChoiceHeuristic)method);
        lastOutW = curOutW;
        if(numImages == (int)tempOutRects.size())
        {
            maxOutW = curOutW;
            curOutW = (minOutW + maxOutW + 1) / 2;
        }
        else
        {
            minOutW = curOutW;
            curOutW = (minOutW + maxOutW + 1) / 2;
        }
    }
    //outRects = tempOutRects;
    return curOutW;
}

static int reduceVerticalSize(const std::vector<TPRectSize> &inRects, int outW, int outH, int method, int numImages, std::vector<TPRect> &tempOutRects)
{
    int minOutH = outH/2;
    int maxOutH = outH;
    int curOutH = (minOutH + maxOutH) / 2;
    int lastOutH = outH;
    while (curOutH != lastOutH) {
        MaxRectsBinPack tempBin(outW, curOutH);
        tempBin.Insert(inRects, tempOutRects, (MaxRectsBinPack::FreeRectChoiceHeuristic)method);
        lastOutH = curOutH;
        if(numImages == (int)tempOutRects.size())
        {
            maxOutH = curOutH;
            curOutH = (minOutH + maxOutH + 1) / 2;
        }
        else
        {
            minOutH = curOutH;
            curOutH = (minOutH + maxOutH + 1) / 2;
        }
    }
    //outRects = tempOutRects;
    return curOutH;
}

- (NSArray *)createTextureAtlas
{
    // Reset the error message
    if (errorMessage)
    {
        errorMessage = NULL;
    }
    
    NSMutableArray *result = [NSMutableArray array];
    
    if(self.filenames.count == 0)
        return result;
    
    // Create output directory if it doesn't exist
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* outputDir = [outputName_ stringByDeletingLastPathComponent];
    if (![fm fileExistsAtPath:outputDir])
    {
        [fm createDirectoryAtPath:outputDir withIntermediateDirectories:YES attributes:NULL error:NULL];
    }
    
    // Load images and retrieve information about them
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:self.filenames.count];
    NSMutableArray *imageInfos = [NSMutableArray arrayWithCapacity:self.filenames.count];
    
    CGColorSpaceRef colorSpace = NULL;
    BOOL createdColorSpace = NO;
    
    NSMutableDictionary *duplicates = [NSMutableDictionary dictionary];
    NSMutableDictionary *hashes = [NSMutableDictionary dictionary];
        
    for (NSString *filename in self.filenames)
    {
        if (cancelled_)
        {
            return nil;
        }

        // Load CGImage
        CGImageSourceRef image_source = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:[self.filenames objectForKey:filename]], NULL);
        CGImageRef srcImage = CGImageSourceCreateImageAtIndex(image_source, 0, NULL);
        
        unsigned char imageHash[CC_SHA512_DIGEST_LENGTH];
        
        [self sha512HashFromCGImage:srcImage hash:imageHash];
        
        NSData *imageHashData = [NSData dataWithBytes:imageHash length:CC_SHA512_DIGEST_LENGTH];
        
        BOOL duplicate = NO;
        for(id key in hashes)
        {
            if([imageHashData isEqualToData:[hashes objectForKey:key]])
            {
                duplicate = YES;
                NSMutableArray *files = [duplicates objectForKey:key];
                if(files)
                {
                    [files addObject:filename];
                }
                else
                {
                    NSMutableArray *files = [NSMutableArray array];
                    [files addObject:filename];
                    [duplicates setObject:files forKey:key];
                }
                break;
            }
        }
        if(duplicate)
            continue;
        else
            [hashes setObject:imageHashData forKey:filename];
        
        // Get info
        int w = (int)CGImageGetWidth(srcImage);
        int h = (int)CGImageGetHeight(srcImage);
        
        NSRect trimRect;
        if (_trim)
        {
            trimRect = [Tupac trimmedRectForImage:srcImage];
        }
        else
        {
            trimRect = CGRectMake(0, 0, w, h);
        }
        
        if (!colorSpace)
        {
            colorSpace = CGImageGetColorSpace(srcImage);
        
            if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelIndexed)
            {
                colorSpace = CGColorSpaceCreateDeviceRGB();
                createdColorSpace = YES;
            }
        }
        
        NSMutableDictionary* imageInfo = [NSMutableDictionary dictionary];
        [imageInfo setObject:filename forKey:@"filename"];
        [imageInfo setObject:[NSNumber numberWithInt:w] forKey:@"width"];
        [imageInfo setObject:[NSNumber numberWithInt:h] forKey:@"height"];
        [imageInfo setObject:[NSValue valueWithRect:trimRect] forKey:@"trimRect"];
        
        // Store info info
        [imageInfos addObject:imageInfo];
        [images addObject:[NSValue valueWithPointer:srcImage]];
        
        // Relase objects (images released later)
        CFRelease(image_source);
    }
    
    // Find the longest side
    int maxSideLen = 8;
    for (NSDictionary* imageInfo in imageInfos)
    {
        NSRect trimRect = [[imageInfo objectForKey:@"trimRect"] rectValue];
        
        int w = trimRect.size.width;
        if (w > maxSideLen) maxSideLen = w + (self.padding + self.extrude) * 2;
        
        int h = trimRect.size.height;
        if (h > maxSideLen) maxSideLen = h + (self.padding + self.extrude) * 2;
    }
    maxSideLen = upper_power_of_two(maxSideLen);
    
    std::vector<TPRect> bestOutRects;
    int bestOutW = INT_MAX;
    int bestOutH = INT_MAX;
    
    BOOL globalPackingError = YES;
    
    std::vector<TPRectSize> inRects;
    
    int numImages = 0;
    for (NSDictionary* imageInfo in imageInfos)
    {
        NSRect trimRect = [[imageInfo objectForKey:@"trimRect"] rectValue];
        
        inRects.push_back(TPRectSize());
        inRects[numImages].width = trimRect.size.width + (self.padding + self.extrude) * 2;
        inRects[numImages].height = trimRect.size.height + (self.padding + self.extrude) * 2;
        inRects[numImages].idx = numImages;
        
        numImages++;
    }
    
    int packMethods[] = {MaxRectsBinPack::RectBestShortSideFit, MaxRectsBinPack::RectBestLongSideFit, MaxRectsBinPack::RectBestAreaFit, MaxRectsBinPack::RectBottomLeftRule};
    
    for(int k=0; k<=sizeof(packMethods)/sizeof(*packMethods); ++k)
    {
        int i = packMethods[k];
        BOOL allFitted = NO;
        
        // Pack using max rects
        int outW = maxSideLen;
        int outH = 8;
        BOOL pot = _pot;
        BOOL makeSquare = NO;
        if (self.imageFormat == kFCImageFormatPVRTC_2BPP || self.imageFormat == kFCImageFormatPVRTC_4BPP)
        {
            makeSquare = YES;
            outH = outW;
            pot = YES;
        }
        
        BOOL packingError = NO;
        std::vector<TPRect> outRects;
        
        while (!packingError && !allFitted)
        {
            MaxRectsBinPack bin(outW, outH);
            
            bin.Insert(inRects, outRects, (MaxRectsBinPack::FreeRectChoiceHeuristic)i);
            
            if (numImages == (int)outRects.size())
            {
                allFitted = YES;
                if(!pot)
                {
                    std::vector<TPRect> tempOutRects;
                    tempOutRects.reserve(inRects.size());
                    
                    if(outH >= outW)
                    {
                        outH = reduceVerticalSize(inRects, outW, outH, i, numImages, tempOutRects);
                        outRects = tempOutRects;
                        outW = reduceHorizontalSize(inRects, outW, outH, i, numImages, tempOutRects);
                        outRects = tempOutRects;
                    }
                    else
                    {
                        outW = reduceHorizontalSize(inRects, outW, outH, i, numImages, tempOutRects);
                        outRects = tempOutRects;
                        outH = reduceVerticalSize(inRects, outW, outH, i, numImages, tempOutRects);
                        outRects = tempOutRects;
                    }
                
                }
            }
            else
            {
                if (makeSquare)
                {
                    outW *= 2;
                    outH *= 2;
                }
                else
                {
                    if (outW > outH)
                        outH *= 2;
                    else
                        outW *= 2;
                }
                
                if (outW > self.maxTextureSize || outH > self.maxTextureSize)
                    packingError = YES;
            }
        }
        if(outRects.size() >= bestOutRects.size())
        {
            if((long long)outW * outH < (long long)bestOutW * bestOutH)
            {
                printf("best method %d \n", i);
                if(allFitted)
                    globalPackingError = NO;
                bestOutRects = outRects;
                bestOutW = outW;
                bestOutH = outH;
            }
        }
    }
    
    if (globalPackingError)
    {
        [self setErrorMessage:@"Failed to fit all sprites in smart sprite sheet."];
        return result;
    }
    
    // Create the output graphics context
    CGContextRef dstContext = CGBitmapContextCreate(NULL, bestOutW, bestOutH, 8, bestOutW*32, colorSpace, kCGImageAlphaPremultipliedLast);
	NSAssert(dstContext != nil, @"CG bitmap context is nil");

    // Draw all the individual images
    int index = 0;
    while (index < bestOutRects.size())
    {
        if (cancelled_)
        {
            return nil;
        }
        
        bool rot = false;
        int  x, y, w, h;
        
        // Get the image and info
        CGImageRef srcImage = (CGImageRef)[[images objectAtIndex:bestOutRects[index].idx] pointerValue];
        NSDictionary* imageInfo = [imageInfos objectAtIndex:bestOutRects[index].idx];
        
        x = bestOutRects[index].x;
        y = bestOutRects[index].y;
       
        rot = bestOutRects[index].rotated;
        
        x += self.padding + self.extrude;
        y += self.padding + self.extrude;
        
        int dx = 0;
        int dy = 0;
        int trimWidth = 0;
        int trimHeight = 0;
        
        NSRect trimRect = [[imageInfo objectForKey:@"trimRect"] rectValue];
        if (rot)
        {
            h = [[imageInfo objectForKey:@"width"] intValue];
            w = [[imageInfo objectForKey:@"height"] intValue];
            
            dx = (w - trimRect.origin.y - trimRect.size.height);
            dy = trimRect.origin.x;
            trimWidth = trimRect.size.height;
            trimHeight = trimRect.size.width;
            x -= (w - trimRect.origin.y - trimRect.size.height);
            y -= trimRect.origin.x;
        }
        else
        {
            w = [[imageInfo objectForKey:@"width"] intValue];
            h = [[imageInfo objectForKey:@"height"] intValue];
            
            dx = trimRect.origin.x;
            dy = trimRect.origin.y;
            trimWidth = trimRect.size.width;
            trimHeight = trimRect.size.height;
            x -= trimRect.origin.x;
            y -= trimRect.origin.y;
        }
        
        if (rot)
        {
            // Rotate image 90 degrees
            CGContextRef rotContext = CGBitmapContextCreate(NULL, w, h, 8, 32*w, colorSpace, kCGImageAlphaPremultipliedLast);
            CGContextSaveGState(rotContext);
            CGContextRotateCTM(rotContext, -M_PI/2);
            CGContextTranslateCTM(rotContext, -h, 0);
            CGContextDrawImage(rotContext, CGRectMake(0, 0, h, w), srcImage);
            
            CGImageRelease(srcImage);
            srcImage = CGBitmapContextCreateImage(rotContext);
            CFRelease(rotContext);
        }
        
        // Draw the image
        CGContextDrawImage(dstContext, CGRectMake(x, bestOutH-y-h, w, h), srcImage);
        
        if(self.extrude>0)
        {
            CGImageRef left = CGImageCreateWithImageInRect(srcImage,CGRectMake(dx,dy,1,h-dy));
            if(left)
            {
                CGContextDrawImage(dstContext, CGRectMake(x-self.extrude+dx, bestOutH-y-h, self.extrude, h-dy), left);
                CFRelease(left);
            }
            CGImageRef right = CGImageCreateWithImageInRect(srcImage,CGRectMake(trimWidth + dx - 1,dy,1,h-dy));
            if(right)
            {
                CGContextDrawImage(dstContext, CGRectMake(x+dx+trimWidth, bestOutH-y-h, self.extrude, h-dy), right);
                CFRelease(right);
            }
            CGImageRef bottom = CGImageCreateWithImageInRect(srcImage,CGRectMake(dx,trimHeight + dy - 1,w-dx,1));
            if(bottom)
            {
                CGContextDrawImage(dstContext, CGRectMake(x+dx,bestOutH-y-trimHeight-self.extrude-dy, w-dx, self.extrude), bottom);
                CFRelease(bottom);
            }
            CGImageRef top = CGImageCreateWithImageInRect(srcImage,CGRectMake(dx,dy,w-dx,1));
            if(top)
            {
                CGContextDrawImage(dstContext, CGRectMake(x+dx,bestOutH-y-dy, w-dx, self.extrude), top);
                CFRelease(top);
            }
            
            CGImageRef leftTop = CGImageCreateWithImageInRect(srcImage,CGRectMake(dx,dy,1,1));
            if(leftTop)
            {
                CGContextDrawImage(dstContext, CGRectMake(x-self.extrude+dx, bestOutH-y-dy, self.extrude, self.extrude), leftTop);
                CFRelease(leftTop);
            }
            CGImageRef rightTop = CGImageCreateWithImageInRect(srcImage,CGRectMake(trimWidth + dx - 1,dy,1,1));
            if(rightTop)
            {
                CGContextDrawImage(dstContext, CGRectMake(x+dx+trimWidth, bestOutH-y-dy, self.extrude, self.extrude), rightTop);
                CFRelease(rightTop);
            }
            CGImageRef leftBottom = CGImageCreateWithImageInRect(srcImage,CGRectMake(dx,trimHeight + dy -1,1,1));
            if(leftBottom)
            {
                CGContextDrawImage(dstContext, CGRectMake(x-self.extrude+dx, bestOutH-y-trimHeight-self.extrude-dy, self.extrude, self.extrude), leftBottom);
                CFRelease(leftBottom);
            }
            CGImageRef rightBottom = CGImageCreateWithImageInRect(srcImage,CGRectMake(trimWidth + dx - 1,trimHeight + dy -1,1,1));
            if(rightBottom)
            {
                CGContextDrawImage(dstContext, CGRectMake(x+dx+trimWidth, bestOutH-y-trimHeight-self.extrude-dy, self.extrude, self.extrude), rightBottom);
                CFRelease(rightBottom);
            }
        }
        
        // Release the image
        CGImageRelease(srcImage);
        
        index++;
    }
    
    [NSGraphicsContext restoreGraphicsState];

    if (cancelled_)
    {
        return nil;
    }
    
    NSString* textureFileName = NULL;
    
    // Export PNG file
    
    NSString *pngFilename  = [self.outputName stringByAppendingPathExtension:@"png"];
    
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:pngFilename];
    CGImageRef imageDst = CGBitmapContextCreateImage(dstContext);
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, imageDst, nil);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", pngFilename);
    }
    
    CGImageRelease(imageDst);
    CGContextRelease(dstContext);
    
    textureFileName = pngFilename;
    
    if (createdColorSpace)
    {
        CFRelease(colorSpace);
    }
    
    [self generatePreviewImage:pngFilename];

    NSError * error = nil;

    self.formatConverter = [FCFormatConverter defaultConverter];
    if(![_formatConverter convertImageAtPath:pngFilename
                                      format:imageFormat_
                                     quality:imageQuality_
                                      dither:dither_
                                    compress:compress_
                               isSpriteSheet:YES
                                   isRelease:optimize_
                              outputFilename:&textureFileName
                                       error:&error])
    {
        [self setErrorMessage:error.localizedDescription];
    }
    self.formatConverter = nil;

    if (cancelled_)
    {
        return nil;
    }

    [result addObject:textureFileName];

    // Metadata File Export
    textureFileName = [textureFileName lastPathComponent];
    

    NSMutableDictionary *outDict    = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    NSMutableDictionary *frames     = [NSMutableDictionary dictionaryWithCapacity:self.filenames.count];
    NSMutableDictionary *metadata   = [NSMutableDictionary dictionaryWithCapacity:4];
    
    [outDict setObject:frames   forKey:@"frames"];
    [outDict setObject:metadata forKey:@"metadata"];
    
    index = 0;
    while(index < bestOutRects.size())
    {
        // Get info about the image
        NSDictionary* imageInfo = [imageInfos objectAtIndex:bestOutRects[index].idx];
        NSString* filename = [imageInfo objectForKey:@"filename"];
        NSString* exportFilename = filename;
        if (directoryPrefix_) exportFilename = [directoryPrefix_ stringByAppendingPathComponent:exportFilename];
        
        bool rot = false;
        int x, y, w, h, wSrc, hSrc, xOffset, yOffset;
        x = bestOutRects[index].x + (self.padding + self.extrude);
        y = bestOutRects[index].y + (self.padding + self.extrude);
        w = bestOutRects[index].width - (self.padding + self.extrude)*2;
        h = bestOutRects[index].height - (self.padding + self.extrude)*2;
        wSrc = [[imageInfo objectForKey:@"width"] intValue];
        hSrc = [[imageInfo objectForKey:@"height"] intValue];
        NSRect trimRect = [[imageInfo objectForKey:@"trimRect"] rectValue];
        
        rot = bestOutRects[index].rotated;
        
        if (rot)
        {
            int wRot = h;
            int hRot = w;
            w = wRot;
            h = hRot;
        }
        
        xOffset = trimRect.origin.x + trimRect.size.width/2 - wSrc/2;
        yOffset = -trimRect.origin.y - trimRect.size.height/2 + hSrc/2;
        
        index++;
        
        NSDictionary *frameDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   NSStringFromRect(NSMakeRect(x, y, w, h)),         @"frame",
                                   NSStringFromPoint(NSMakePoint(xOffset, yOffset)), @"offset",
                                   [NSNumber numberWithBool:rot],                    @"rotated",
                                   NSStringFromRect(trimRect),                       @"sourceColorRect",
                                   NSStringFromSize(NSMakeSize(wSrc, hSrc)),         @"sourceSize",
                                   nil];
        
        [frames setObject:frameDict forKey:exportFilename];
        NSArray *fileDuplicates = [duplicates objectForKey:filename];
        if(fileDuplicates)
        {
            for (NSString *duplicateFilename in fileDuplicates)
            {
                NSString* duplicateExportFilename = duplicateFilename;
                if (directoryPrefix_) duplicateExportFilename = [directoryPrefix_ stringByAppendingPathComponent:duplicateExportFilename];
                [frames setObject:frameDict forKey:duplicateExportFilename];
                //[frames setObject:frameDict forKey:[NSString stringWithFormat:@"%@ duplicate:%@", duplicateExportFilename, filename]];
            }
        }
    }
    
    [metadata setObject:textureFileName                                     forKey:@"textureFileName"];
    [metadata setObject:[NSNumber numberWithInt:2]                      forKey:@"format"];
    [metadata setObject:NSStringFromSize(NSMakeSize(bestOutW, bestOutH))        forKey:@"size"];
    
    NSString *plistFilename = [self.outputName stringByAppendingPathExtension:@"plist"];
    [outDict writeToFile:plistFilename atomically:YES];
    [result addObject:plistFilename];
    
    return result;
}

- (void)generatePreviewImage:(NSString *)pngFilename
{
    //use only phonehd image for preview, because it's 2x times smaller
    
    if (self.previewFile && [pngFilename containsString:@"resources-phonehd"])
    {
        NSError *error;
        if (![[NSFileManager defaultManager] removeItemAtPath:self.previewFile error:&error]
            && error.code != NSFileNoSuchFileError)
        {
            NSLog(@"[TEXTUREPACKER] Error removing preview image %@: %@", self.previewFile, error);
        }

        error = nil;
        if (![[NSFileManager defaultManager] copyItemAtPath:pngFilename toPath:self.previewFile error:&error])
        {
            NSLog(@"[TEXTUREPACKER] Error copying preview image from %@ to %@: %@", pngFilename, self.previewFile, error);
        }
        
        //resize preview 
        NSImageView* kView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
        [kView setImageScaling:NSImageScaleProportionallyUpOrDown];
        [kView setImage:[[NSImage alloc] initWithContentsOfFile:self.previewFile]];
        
        NSRect kRect = kView.frame;
        NSBitmapImageRep* kRep = [kView bitmapImageRepForCachingDisplayInRect:kRect];
        [kView cacheDisplayInRect:kRect toBitmapImageRep:kRep];
        
        NSData* kData = [kRep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
        [kData writeToFile:self.previewFile atomically:NO];
        
    }
}

- (NSArray *)recursivePathsForResourcesOfType:(NSArray *)types inDirectory:(NSString *)directoryPath{
    
    NSMutableArray *filePaths = [[NSMutableArray alloc] init];
    
    // Enumerators are recursive
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
    
    NSString *filePath;
    
    while ((filePath = [enumerator nextObject]) != nil){
        
        // If we have the right type of file, add it to the list
        // Make sure to prepend the directory path
        if([types containsObject:[[filePath pathExtension] lowercaseString]]){
            [filePaths addObject:filePath];
        }
    }
    
    return filePaths;
}

- (NSArray *) createTextureAtlasFromDirectoryPaths:(NSArray *)dirs
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    // Build a list of all file names from all directories
    NSMutableDictionary* allFiles = [NSMutableDictionary dictionary];
    
    for (NSString* dir in dirs)
    {
        NSArray* files = [fm contentsOfDirectoryAtPath:dir error:NULL];
        
        if (cancelled_)
        {
            return nil;
        }
        
        for (NSString* file in files)
        {
            NSString *lower = [[file pathExtension] lowercaseString];
            if ([lower isEqualToString:@"png"] || [lower isEqualToString:@"psd"])
            {
                if(![allFiles objectForKey:file])
                {
                    [allFiles setObject:[dir stringByAppendingPathComponent:file] forKey:file];
                }
            }
        }
    }
    
    // Generate the sprite sheet
    self.filenames = allFiles;
    return [self createTextureAtlas];
}

- (NSArray *)createTextureAtlasFromDirectoryPathsRecursive:(NSArray *)dirs ignoreDirs:(NSArray *)ignoreDirs
{
    // Build a list of all file names from all directories
    NSMutableDictionary* allFiles = [NSMutableDictionary dictionary];
    
    for (NSString* dir in dirs)
    {
        //NSArray* files = [fm contentsOfDirectoryAtPath:dir error:NULL];
        
        NSArray* files = [self recursivePathsForResourcesOfType:@[@"png", @"psd"] inDirectory:dir];
        
        if (cancelled_)
        {
            return nil;
        }
        for (NSString* file in files)
        {
            NSString *firstPathComponent = [file pathComponents][0];
            if(![ignoreDirs containsObject:firstPathComponent])
            {
                if(![allFiles objectForKey:file])
                {
                    [allFiles setObject:[dir stringByAppendingPathComponent:file] forKey:file];
                }
            }
        }
    }
    
    // Generate the sprite sheet
    self.filenames = allFiles;
    return [self createTextureAtlas];
}

- (void)cancel
{
    [_formatConverter cancel];
    cancelled_ = YES;
}

@end
