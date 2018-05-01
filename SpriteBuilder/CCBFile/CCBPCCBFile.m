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

#import "CCBPCCBFile.h"
#import "ResourceManager.h"
#import "CCBReaderInternal.h"
#import "CCBGlobals.h"
#import "CCBDocument.h"
#import "AppDelegate.h"
#import "CCNode+NodeInfo.h"
#import "PlugInNode.h"

#import "SequencerHandler.h"
#import "SequencerSequence.h"
#import "SequencerNodeProperty.h"

@implementation CCBPCCBFile

@synthesize ccbFile;

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    return self;
}

- (void) setCcbFile:(CCNode *)cf
{
    ccbFile = cf;
    
    [self removeAllChildrenWithCleanup:YES];
    if (cf)
    {
        [self addChild:cf];
        self.contentSizeType = ccbFile.contentSizeType;
        self.contentSize = ccbFile.contentSize;
        self.anchorPoint = ccbFile.anchorPoint;
        cf.anchorPoint = ccp(0,0);
    }
    else
    {
        self.contentSize = CGSizeZero;
        self.anchorPoint = ccp(0,0);
    }
}

- (CGSize) contentSize
{
    if(ccbFile)
        return ccbFile.contentSize;
    else
        return super.contentSize;
}

- (CCSizeType) contentSizeType
{
    if(ccbFile)
        return ccbFile.contentSizeType;
    else
        return super.contentSizeType;
}

+ (NSArray*) paramsProperties:(CCNode*)node
{
    NSMutableArray *ret = [NSMutableArray array];
    for (CCNode* child in node.children)
    {  
            
        id memberVarAssignmentParam = [child extraPropForKey:@"param_customClass"];
        if(memberVarAssignmentParam && [memberVarAssignmentParam boolValue])
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setObject:[NSString stringWithFormat:@"%d@%@", (int)child.UUID, @"memberVarAssignment"] forKey:@"name"];
            [dict setObject:@"MemberVarAssignment" forKey:@"type"];
            [dict setObject:@"Member variable" forKey:@"displayName"];
            [dict setObject:[@(child.UUID) stringValue] forKey:@"group"];
            [dict setObject:child.displayName forKey:@"groupName"];
            [dict setObject:@YES forKey:@"codeConnection"];
            [ret addObject:dict];
        }
    
        NSArray *propInfos = child.plugIn.nodeProperties;
        for (int i = 0; i < [propInfos count]; i++)
        {
            NSDictionary *propInfo = propInfos[(NSUInteger) i];
            NSString *propertyName = propInfo[@"name"];
            id param = [child extraPropForKey:[NSString stringWithFormat:@"param_%@", propertyName]];
            if(param && [param boolValue])
            {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                
                NSValue *codeConnection = propInfo[@"codeConnection"];
                NSValue *extra = propInfo[@"extra"];
                
                [dict setObject:[NSString stringWithFormat:@"%d@%@", (int)child.UUID, propertyName] forKey:@"name"];
                [dict setObject:propInfo[@"type"] forKey:@"type"];
                [dict setObject:propInfo[@"displayName"] forKey:@"displayName"];
                [dict setObject:[@(child.UUID) stringValue] forKey:@"group"];
                [dict setObject:child.displayName forKey:@"groupName"];
                if(codeConnection)
                    [dict setObject:codeConnection forKey:@"codeConnection"];
                if(extra)
                    [dict setObject:extra forKey:@"extra"];
                [ret addObject:dict];
            }
        }
        
        if([child class] == [self class])
            continue;
        NSArray *childProperies = [CCBPCCBFile paramsProperties:child];
        [ret addObjectsFromArray:childProperies];
    }
    return ret;
}

- (NSArray*) additionalProperties
{
    return [CCBPCCBFile paramsProperties:self];
}

- (id) extraPropForKey:(NSString *)key
{
    if ([key isEqualToString:@"customClass"] && ccbFile)
    {
        return [ccbFile extraPropForKey:@"customClass"];
    }
    else if ([key isEqualToString:@"animation*sequences"] && ccbFile)
    {
        return [ccbFile extraPropForKey:@"*sequences"];
    }
    else if  ([key isEqualToString:@"**startSequence"] && ccbFile)
    {
        return [ccbFile extraPropForKey:@"*startSequence"];
    }
    else
    {
        if ([key containsString:@"@"])
        {
            NSArray *ar = [key componentsSeparatedByString:@"@"];
            
            CCNode *ret = [ccbFile findNodeWithUUID:[ar[0] integerValue]];
            if(ret)
            {
                NSString *name = ar[1];
                BOOL sheet = NO;
                BOOL X = NO;
                BOOL Y = NO;
                
                id baseValue = [ret baseValueForProperty:name];
                if(!baseValue)
                {
                    if ([name hasSuffix:@"Sheet"])
                    {
                        NSString *newName = [name substringToIndex:[name length] - 5];
                        baseValue = [ret baseValueForProperty:newName];
                        if(baseValue)
                        {
                            sheet = YES;
                            name = newName;
                        }
                    }
                }
                if(!baseValue)
                {
                    unichar lastChar = [name characterAtIndex:[name length] - 1];
                    switch (lastChar) {
                        case 'X':
                        {
                            name = [name substringToIndex:[name length] - 1];
                            baseValue = [ret baseValueForProperty:name];
                            X = YES;
                        }
                            break;
                        case 'Y':
                        {
                            name = [name substringToIndex:[name length] - 1];
                            baseValue = [ret baseValueForProperty:name];
                            Y = YES;
                        }
                            break;
                        default:
                            break;
                    }
                }
                if(baseValue)
                {
                    NSDictionary* propInfo = [ret.plugIn.nodePropertiesDict objectForKey:name];
                    NSString *type = propInfo[@"type"];
                    if([type isEqualToString:@"SpriteFrame"])
                    {
                        if(sheet)
                            return baseValue[1];
                        else
                            return baseValue[0];
                    }
                    else if([type isEqualToString:@"ScaleLock"])
                    {
                        if(X)
                            return baseValue[0];
                        if(Y)
                            return baseValue[1];
                        return baseValue;
                    }
                    return baseValue;
                }
                return [ret extraPropForKey:name];
            }
            return nil;
        }
        return [super extraPropForKey:key];
    }
}

- (void) setExtraProp:(id)prop forKey:(NSString *)key
{
    if ([key containsString:@"@"])
    {
        NSArray *ar = [key componentsSeparatedByString:@"@"];
        
        CCNode *ret = [ccbFile findNodeWithUUID:[ar[0] integerValue]];
        if(ret)
        {
            NSString *name = ar[1];
            BOOL sheet = NO;
            BOOL X = NO;
            BOOL Y = NO;
            
            id baseValue = [ret baseValueForProperty:name];
            if(!baseValue)
            {
                if ([name hasSuffix:@"Sheet"])
                {
                    NSString *newName = [name substringToIndex:[name length] - 5];
                    baseValue = [ret baseValueForProperty:newName];
                    if(baseValue)
                    {
                        sheet = YES;
                        name = newName;
                    }
                }
            }
            if(!baseValue)
            {
                unichar lastChar = [name characterAtIndex:[name length] - 1];
                switch (lastChar) {
                    case 'X':
                    {
                        name = [name substringToIndex:[name length] - 1];
                        baseValue = [ret baseValueForProperty:name];
                        X = YES;
                    }
                        break;
                    case 'Y':
                    {
                        name = [name substringToIndex:[name length] - 1];
                        baseValue = [ret baseValueForProperty:name];
                        Y = YES;
                    }
                        break;
                    default:
                        break;
                }
            }
            if(baseValue)
            {
                NSDictionary* propInfo = [ret.plugIn.nodePropertiesDict objectForKey:name];
                NSString *type = propInfo[@"type"];
                if([type isEqualToString:@"SpriteFrame"])
                {
                    [ret setBaseValue:@[!sheet?prop:baseValue[0], sheet?prop:baseValue[1]] forProperty:name];
                }
                else if([type isEqualToString:@"ScaleLock"])
                {
                    [ret setBaseValue:@[X?prop:baseValue[0], Y?prop:baseValue[1]] forProperty:name];
                }
                return;
            }
            [ret setExtraProp:prop forKey:ar[1]];
        }
        return;
    }
    [super setExtraProp:prop forKey:key];
}

- (id) baseValueForProperty:(NSString*)name
{
    if ([name containsString:@"@"])
    {
        NSArray *ar = [name componentsSeparatedByString:@"@"];
        
        CCNode *ret = [ccbFile findNodeWithUUID:[ar[0] integerValue]];
        if(ret)
            return [ret baseValueForProperty:ar[1]];
        return nil;
    }
    return [super baseValueForProperty:name];
}

- (void) setBaseValue:(id)value forProperty:(NSString*)name
{
    if ([name containsString:@"@"])
    {
        NSArray *ar = [name componentsSeparatedByString:@"@"];
        
        CCNode *ret = [ccbFile findNodeWithUUID:[ar[0] integerValue]];
        if(ret)
            [ret setBaseValue:value forProperty:ar[1]];
        return;
    }
    return [super setBaseValue:value forProperty:name];
}

- (id) valueForProperty:(NSString*)name atTime:(float)time sequenceId:(int)seqId
{
    if ([name containsString:@"@"])
    {
        NSArray *ar = [name componentsSeparatedByString:@"@"];
        
        CCNode *ret = [ccbFile findNodeWithUUID:[ar[0] integerValue]];
        if(ret)
            return [ret valueForProperty:ar[1] atTime:0 sequenceId:-1];
        return nil;
    }
    return [super valueForProperty:name atTime:time sequenceId:seqId];
}

+ (BOOL)isDisabledProperty:(NSString *)name node:(CCNode*)node
{
    SequencerSequence *sequence = [SequencerHandler sharedHandler].currentSequence;
    SequencerNodeProperty *sequencerNodeProperty = [node sequenceNodeProperty:name sequenceId:sequence.sequenceId];
    
    // Do not disable if animation hasn't been enabled
    if (!sequencerNodeProperty)
    {
        return NO;
    }
    
    // Do not disable if we are currently at a keyframe or beore
    if(![sequencerNodeProperty activeKeyframeAtTime:sequence.timelinePosition])
    {
        return NO;
    }
    else
    {
        if ([sequencerNodeProperty keyframeAtTime:sequence.timelinePosition] && ![name isEqualToString:@"visible"])
            return NO;
    }
    
    // Between keyframes - disable
    return YES;
}

- (void) updateAnimateablePropertyValue:(id)value forProperty:(NSString*)name;
{
    if ([name containsString:@"@"])
    {
        /*
        NSArray *ar = [name componentsSeparatedByString:@"@"];
        
        CCNode *ret = [ccbFile findNodeWithUUID:[ar[0] integerValue]];
        if(ret)
        {
            id baseValue = [ret baseValueForProperty:ar[1]];
            if (baseValue)
            {
                [ret setBaseValue:value forProperty:ar[1]];
            }
        }*/
        return;
    }
    return [super updateAnimateablePropertyValue:value forProperty:name];
}

- (void) setValue:(id)value forKey:(NSString *)key
{
    if ([key containsString:@"@"])
    {
        NSArray *ar = [key componentsSeparatedByString:@"@"];
        
        CCNode *ret = [ccbFile findNodeWithUUID:[ar[0] integerValue]];
        if(ret)
        {
            NSString *name = ar[1];
            BOOL X = NO;
            BOOL Y = NO;
            
            id baseValue = [ret baseValueForProperty:name];
            if(!baseValue)
            {
                unichar lastChar = [name characterAtIndex:[name length] - 1];
                switch (lastChar) {
                    case 'X':
                        {
                            name = [name substringToIndex:[name length] - 1];
                            baseValue = [ret baseValueForProperty:name];
                            X = YES;
                        }
                        break;
                    case 'Y':
                        {
                            name = [name substringToIndex:[name length] - 1];
                            baseValue = [ret baseValueForProperty:name];
                            Y = YES;
                        }
                        break;
                    default:
                        break;
                }
            }
            if (baseValue)
            {
                NSDictionary* propInfo = [ret.plugIn.nodePropertiesDict objectForKey:name];
                NSString *type = propInfo[@"type"];
                if([type isEqualToString:@"Position"])
                {
                    NSArray* encodedVal = [NSArray arrayWithObjects:
                                          @([value pointValue].x),
                                          @([value pointValue].y),
                                          NULL];
                    [ret setBaseValue:encodedVal forProperty:name];
                }
                else if([type isEqualToString:@"ScaleLock"])
                {
                    //[ret setBaseValue:@[X?value:baseValue[0], Y?value:baseValue[1]] forProperty:name];
                }
                else if([type isEqualToString:@"FloatXY"])
                {
                    [ret setBaseValue:@[X?value:baseValue[0], Y?value:baseValue[1]] forProperty:name];
                }
                else if([type isEqualToString:@"SpriteFrame"])
                {
                    //id sf = [ret extraPropForKey:name];
                    //id ssf = [ret extraPropForKey:[NSString stringWithFormat:@"%@Sheet", name]];
                    //[ret setBaseValue:@[sf, ssf] forProperty:name];
                }
                else if([type isEqualToString:@"Color3"] || [type isEqualToString:@"Color4"])
                {
                    CCColor* colorValue = value;
                    NSArray* encodedVal = @[@(colorValue.red),
                                            @(colorValue.green),
                                            @(colorValue.blue),
                                            @(colorValue.alpha)];
                    [ret setBaseValue:encodedVal forProperty:name];
                }
                else
                {
                    [ret setBaseValue:value forProperty:name];
                }
            }
            if(![CCBPCCBFile isDisabledProperty:name node:ret])
            {
                if(ret == ccbFile && [ar[1] isEqualToString:@"anchorPoint"])
                    [self setAnchorPoint:[value pointValue]];
                else
                    [ret setValue:value forKey:ar[1]];
            }
        }
        return;
    }
    [super setValue:value forKey:key];
}

- (id) valueForKey:(NSString *)key
{
    if ([key containsString:@"@"])
    {
        NSArray *ar = [key componentsSeparatedByString:@"@"];
        
        CCNode *ret = [ccbFile findNodeWithUUID:[ar[0] integerValue]];
        if(ret)
        {
            NSString *name = ar[1];
            BOOL X = NO;
            BOOL Y = NO;
            
            id baseValue = [ret baseValueForProperty:name];
            if(!baseValue)
            {
                unichar lastChar = [name characterAtIndex:[name length] - 1];
                switch (lastChar) {
                    case 'X':
                    {
                        name = [name substringToIndex:[name length] - 1];
                        baseValue = [ret baseValueForProperty:name];
                        X = YES;
                    }
                        break;
                    case 'Y':
                    {
                        name = [name substringToIndex:[name length] - 1];
                        baseValue = [ret baseValueForProperty:name];
                        Y = YES;
                    }
                        break;
                    default:
                        break;
                }
            }
            if (baseValue)
            {
                NSDictionary* propInfo = [ret.plugIn.nodePropertiesDict objectForKey:name];
                NSString *type = propInfo[@"type"];
                if([type isEqualToString:@"Position"])
                {
                    NSPoint pt;
                    pt.x = [baseValue[0] floatValue];
                    pt.y = [baseValue[1] floatValue];
                    return [NSValue valueWithPoint:pt];
                }
                else if([type isEqualToString:@"Color3"])
                {
                    return [CCColor colorWithRed:[baseValue[0] floatValue] green:[baseValue[1] floatValue] blue:[baseValue[2] floatValue] alpha:1.0];
                }
                else if([type isEqualToString:@"Color4"])
                {
                    return [CCColor colorWithRed:[baseValue[0] floatValue] green:[baseValue[1] floatValue] blue:[baseValue[2] floatValue] alpha:[baseValue[3] floatValue]];
                }
                else if([type isEqualToString:@"FloatXY"])
                {
                    if(X)
                        return baseValue[0];
                    if(Y)
                        return baseValue[1];
                    return baseValue;
                }
                else if([type isEqualToString:@"SpriteFrame"])
                {
                    return baseValue;
                }
                else if([type isEqualToString:@"ScaleLock"])
                {
                    if(X)
                        return baseValue[0];
                    if(Y)
                        return baseValue[1];
                    return baseValue;
                }
                else
                {
                    return baseValue;
                }
            }
            
            if(ret == ccbFile && [ar[1] isEqualToString:@"anchorPoint"])
                return [NSValue valueWithPoint:self.anchorPoint];
            else
                return [ret valueForKey:ar[1]];
        }
        
        return nil;
    }
    return [super valueForKey:key];
}

- (NSMutableArray*) customProperties
{
    if (!ccbFile) return [NSMutableArray array];
    
    return [ccbFile customProperties];
}

@end
