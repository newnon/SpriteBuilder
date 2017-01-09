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

#import <Foundation/Foundation.h>
#import "CCBPublisherTypes.h"
#import "FCFormatConverter.h"

#define kCCBProjectSettingsVersion 1
#define kCCBDefaultExportPlugIn @"ccbi"


typedef enum {
    kCCBSceneScaleTypeDEFAULT  = -1,
    kCCBSceneScaleTypeNONE     = 0,
    kCCBSceneScaleTypeCUSTOM   = 1,
    kCCBSceneScaleTypeMINSIZE  = 2,
    kCCBSceneScaleTypeMAXSIZE  = 3,
    kCCBSceneScaleTypeMINSCALE = 4,
    kCCBSceneScaleTypeMAXSCALE = 5,
} CCBSceneScaleType;


typedef enum
{
    kCCBOrientationLandscape = 0,
    kCCBOrientationPortrait = 1,
} CCBOrientation;


@class RMResource;
@class CCBWarnings;
@class PlatformSettings;

@interface ProjectSettings : NSObject

// Full path to the project file, e.g. /foo/baa.spritebuilder/baa.ccbproj
@property (nonatomic, copy) NSString* projectPath;

// Full path to the project's root folder, according to -projectPath example: /foo/baa.spritebuilder/
@property (nonatomic, readonly) NSString* projectPathDir;

@property (nonatomic, strong, readonly) NSArray *allResourcesRelativePaths;

@property (nonatomic, readonly) NSString* projectPathHashed;
@property (nonatomic, strong) NSMutableArray* resourcePaths;

@property (nonatomic, assign) BOOL onlyPublishCCBs;
@property (nonatomic, readonly) NSArray* absoluteResourcePaths;
@property (nonatomic, copy) NSString* exporter;
@property (nonatomic, strong) NSMutableArray* availableExporters;
@property (nonatomic, readonly) NSString* displayCacheDirectory;
@property (nonatomic, readonly) NSString* tempSpriteSheetCacheDirectory;
@property (nonatomic, assign) BOOL deviceOrientationPortrait;
@property (nonatomic, assign) BOOL deviceOrientationUpsideDown;
@property (nonatomic, assign) BOOL deviceOrientationLandscapeLeft;
@property (nonatomic, assign) BOOL deviceOrientationLandscapeRight;
@property (nonatomic, assign) int resourceAutoScaleFactor;
@property (nonatomic, assign) CCBPublishEnvironment publishEnvironment;

@property (nonatomic, readonly) NSMutableArray* platformsSettings;


@property (nonatomic) BOOL excludedFromPackageMigration;

@property (nonatomic, copy) NSString* versionStr;
@property (nonatomic, assign) BOOL needRepublish;

@property (nonatomic, assign) int sceneScaleType;
@property (nonatomic, assign) int defaultOrientation;
@property (nonatomic, assign) int deviceScaling;
@property (nonatomic, assign) float tabletPositionScaleFactor;

@property (nonatomic,assign) int designSizeWidth;
@property (nonatomic,assign) int designSizeHeight;
@property (nonatomic,assign) float designResourceScale;

@property (nonatomic, strong) CCBWarnings* lastWarnings;

@property (nonatomic, assign) BOOL readOnly;


- (id) initWithSerialization:(id)dict;
- (BOOL) store;
- (id) serialize;


// *** Smart Sprite Sheets ***
- (void) makeSmartSpriteSheet:(RMResource*) res;
- (void) removeSmartSpriteSheet:(RMResource*) res;
- (NSArray*) smartSpriteSheetDirectories;

// *** Setting and reading file properties ***
// Will mark the resource as dirty if old value is not equal to new value
- (void)setProperty:(id)newValue forResource:(RMResource *)res andKey:(id <NSCopying>)key;
// Will mark the resource as dirty if old value is not equal to new value
- (void)setProperty:(id)newValue forRelPath:(NSString *)relPath andKey:(id <NSCopying>)key;
- (id)propertyForResource:(RMResource *)res andKey:(id <NSCopying>)key;
- (id)propertyForRelPath:(NSString *)relPath andKey:(id <NSCopying>)key;
// Will mark the resource as dirty
- (void)removePropertyForResource:(RMResource *)res andKey:(id <NSCopying>)key;
// Will mark the resource as dirty
- (void)removePropertyForRelPath:(NSString *)relPath andKey:(id <NSCopying>)key;

// *** Dirty markers ***
- (BOOL)isDirtyResource:(RMResource *)res;
- (BOOL)isDirtyRelPath:(NSString *)relPath;
- (void)markAsDirtyResource:(RMResource *)res;
- (void)markAsDirtyRelPath:(NSString *)relPath;
- (void)clearAllDirtyMarkers;
- (void)clearDirtyMarkerOfRelPath:(NSString *)relPath;
- (void)clearDirtyMarkerOfResource:(RMResource *)resource;
- (void)flagFilesDirtyWithWarnings:(CCBWarnings *)warnings;

// *** Handling moved and deleted resources ***
- (void) removedResourceAt:(NSString*) relPath;

- (void)movedResourceFrom:(NSString *)relPathOld to:(NSString *)relPathNew fromFullPath:(NSString *)fromFullPath toFullPath:(NSString *)toFullPath;

// *** Resource Paths ***
// Adds a full resourcePath to the project, provide full filePath
// Returns NO if resource path could not be added.
// Returns SBDuplicateResourcePathError if given resource path is already present,
- (BOOL)addResourcePath:(NSString *)path error:(NSError **)error;

// Tests if a given full resource path is already in the project, provide full filePath
- (BOOL)isResourcePathInProject:(NSString *)resourcePath;

// Removes a full resourcePath from the project, provide full filePath
// Returns NO if resource path could not be removed.
// Returns SBResourcePathNotInProjectError if given resource path does not exist,
- (BOOL)removeResourcePath:(NSString *)path error:(NSError **)error;

// Changes the path component of a resourcePath, provide full paths
// Returns NO if resource path could not be moved.
// Returns SBDuplicateResourcePathError if resource path toPath already exists
- (BOOL)moveResourcePathFrom:(NSString *)fromPath toPath:(NSString *)toPath error:(NSError **)error;

- (NSString *)fullPathForResourcePathDict:(NSMutableDictionary *)resourcePathDict;

// *** Misc ***
- (NSString* ) getVersion;
- (NSDictionary *)getVersionDictionary;

// Tries to find the relative path among all packages for a given absolute path
// Example: "/foo/Packages/baa.sbpack" as available packages and absolutePath given is
// "/foo/Packages/baa.sbpack/level1/sprites/fighter.png" will result in "level1/sprites/fighter.png"
// If no package include the given absolutePath nil is returned
- (NSString *)findRelativePathInPackagesForAbsolutePath:(NSString *)absolutePath;


@end
