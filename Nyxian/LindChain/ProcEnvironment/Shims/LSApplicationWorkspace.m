/*
 SPDX-License-Identifier: AGPL-3.0-or-later

 Copyright (C) 2025 - 2026 emexlab

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import <Foundation/Foundation.h>
#import <LindChain/Utils/Swizzle.h>
#import <LindChain/Private/UIKitPrivate.h>
#import <LindChain/Services/bootstrapd/LDEApplicationWorkspace.h>
#import <LindChain/Services/bootstrapd/ISIcon.h>
#import <LindChain/Utils/IconUtils.h>

/* WIP TO A HUGE EXTEND! */

@interface _LSDiskUsage : NSObject
@property (readonly, nullable, nonatomic) NSNumber *staticUsage;
@property (readonly, nullable, nonatomic) NSNumber *dynamicUsage;
@property (readonly, nullable, nonatomic) NSNumber *onDemandResourcesUsage;
@property (readonly, nullable, nonatomic) NSNumber *sharedUsage;
@end

@interface LDEApplicationProxy : NSObject

@property (nonatomic, readonly) LDEApplicationObject *applicationObject;

@end

@implementation LDEApplicationProxy

/* inits */
+ (id)applicationProxyForLDEObject:(LDEApplicationObject*)object
{
    LDEApplicationProxy *applicationProxy = [[LDEApplicationProxy alloc] init];
    if(self)
    {
        applicationProxy->_applicationObject = object;
    }
    return applicationProxy;
}

- (id)ODRDiskUsage
{
    return nil;
}

- (bool)UPPValidated
{
    return YES;
}

- (id)_localizedNameWithPreferredLocalizations:(id)arg1
                              useShortNameOnly:(bool)arg2
{
    return _applicationObject.localizedName;
}

- (id)_managedPersonas
{
    return nil;
}

- (id)_stringLocalizerForTable:(id)arg1
{
    return nil;
}

- (NSString*)localizedName
{
    return _applicationObject.localizedName;
}

- (NSArray<NSURL*>*)groupContainerURLs
{
    /* this is a test, remove if not needed */
    return @[];
}

- (id)dataContainerURL
{
    return [NSURL fileURLWithPath:_applicationObject.containerPath];
}

- (bool)isInstalled
{
    return YES;
}

- (bool)_usesSystemPersona
{
    return NO;
}

- (id)activityTypes
{
    return nil;
}

- (id)alternateIconName
{
    return nil;
}

- (id)appIDPrefix
{
    return nil;
}

- (id)appState
{
    return nil;
}

- (id)applicationDSID
{
    return nil;
}


- (id)applicationIdentifier
{
    return _applicationObject.bundleIdentifier;
}

- (id)applicationType
{
    return @"User";
}

- (id)applicationVariant
{
    return nil;
}

- (id)betaExternalVersionIdentifier
{
    return nil;
}

- (int)bundleModTime
{
    return 0;
}

- (id)bundleType
{
    return nil;
}

- (id)claimedDocumentContentTypes
{
    return nil;
}

- (id)claimedURLSchemes
{
    return [NSSet set];
}

- (void)clearAdvertisingIdentifier
{
    return;
}

- (id)companionApplicationIdentifier
{
    return nil;
}

- (id)complicationPrincipalClass
{
    return nil;
}

- (id)correspondingApplicationRecord
{
    return nil;
}

- (id)description
{
    return nil;
}

- (void)detach
{
    return;
}

- (id)deviceFamily
{
    return nil;
}

- (long long)deviceManagementPolicy
{
    return 0;
}

- (id)downloaderDSID
{
    return nil;
}

- (id)dynamicDiskUsage
{
    return nil;
}

- (id)environmentVariables
{
    return @{};
}

- (id)externalVersionIdentifier
{
    return nil;
}

- (id)familyID
{
    return nil;
}

- (bool)fileSharingEnabled
{
    return false;
}

- (bool)freeProfileValidated
{
    return false;
}

- (bool)gameCenterEverEnabled
{
    return false;
}

- (id)genre
{
    return nil;
}

- (id)genreID
{
    return nil;
}

- (id)getBundleMetadata
{
    return nil;
}

- (void)getDeviceManagementPolicyWithCompletionHandler:(id)arg1
{
    
}

- (bool)getGenericTranslocationTargetURL:(id*)arg1 error:(id*)arg2
{
    return false;
}

- (bool)isBetaApp
{
    return false;
}

- (bool)isDeletable
{
    return true;
}

- (bool)isRestricted
{
    return false;
}

- (bool)isContainerized
{
    return true;
}

- (bool)isAdHocCodeSigned
{
    return false;
}

- (bool)isAppStoreVendable
{
    return false;
}

- (bool)isLaunchProhibited
{
    return !_applicationObject.isLaunchAllowed;
}

- (NSString*)teamID
{
    return @"";
}

- (NSString*)sdkVersion
{
    return _applicationObject.sdkVersion;
}

- (NSDictionary<NSString*,id<NSCoding>>*)entitlements
{
    return _applicationObject.entitlements;
}

- (NSURL*)bundleContainerURL
{
    return [NSURL fileURLWithPath:_applicationObject.bundlePath];
}

- (_LSDiskUsage*)diskUsage
{
    NSLog(@"wants diskUsage!\n");
    return nil;
}

- (NSDate*)registeredDate
{
    return [NSDate now];
}

- (NSString*)vendorName
{
    return @"";
}

- (NSString*)minimumSystemVersion
{
    return _applicationObject.minimumSystemVersion;
}

- (NSURL*)bundleURL
{
    return [NSURL fileURLWithPath:_applicationObject.bundlePath];
}

- (NSURL*)containerURL
{
    return [NSURL fileURLWithPath:_applicationObject.containerPath];
}

- (NSData *)iconDataForVariant:(int)variant
{
    UIImage *icon = _applicationObject.icon;
    return UIImagePNGRepresentation(icon);
}

- (NSData *)iconDataForVariant:(int)variant
                   withOptions:(int)options
{
    return [self iconDataForVariant:variant];
}

- (NSString*)bundleVersion
{
    return _applicationObject.bundleVersion;
}

- (NSString*)shortVersionString
{
    return _applicationObject.shortVersionString;
}

- (NSDictionary*)iconsDictionary
{
    return _applicationObject.iconDictionary;
}

- (id)handlerRankOfClaimForContentType:(id)arg1
{
    return nil;
}

- (bool)hasMIDBasedSINF
{
    return false;
}

- (bool)iconIsPrerendered
{
    return _applicationObject.icon == nil;
}

- (bool)iconUsesAssetCatalog
{
    return false;   /* FIXME: properly check for it in LDEApplicationObject */
}

- (id)installFailureReason
{
    return nil; /* no reason */
}

- (id)installProgress
{
    return nil; /* no progress */
}

- (id)installProgressSync
{
    return nil;
}

- (unsigned long long)installType
{
    return 0;
}

- (bool)isAppUpdate
{
    return false;
}

- (bool)isDeletableIgnoringRestrictions
{
    return false;
}

/*
- (bool)isGameCenterEnabled;
- (bool)isNewsstandApp;
- (bool)isPlaceholder;
- (bool)isPurchasedReDownload;
- (bool)isRemoveableSystemApp;
- (bool)isRemovedSystemApp;
- (bool)isRestricted;
- (bool)isStandaloneWatchApp;
- (bool)isWatchKitApp;
- (bool)isWhitelisted;
- (id)itemID;
- (id)itemName;
- (id)localizedNameForContext:(id)arg1;
- (id)localizedNameForContext:(id)arg1 preferredLocalizations:(id)arg2;
- (id)localizedNameForContext:(id)arg1 preferredLocalizations:(id)arg2 useShortNameOnly:(bool)arg3;
- (id)managedPersonas;
- (id)methodSignatureForSelector:(SEL)arg1;
- (bool)missingRequiredSINF;
- (unsigned long long)originalInstallType;
- (id)platform;
- (id)plugInKitPlugins;
- (id)preferredArchitecture;
- (id)primaryIconDataForVariant:(int)arg1;
- (bool)profileValidated;
- (id)purchaserDSID;
- (id)ratingLabel;
- (id)ratingRank;
- (id)registeredDate;
- (id)requiredDeviceCapabilities;
- (bool)respondsToSelector:(SEL)arg1;
- (void)setAlternateIconName:(id)arg1 withResult:(id)arg2;
- (void)setUserInitiatedUninstall:(bool)arg1;
- (id)signerIdentity;
- (id)signerOrganization;
- (id)siriActionDefinitionURLs;
- (id)sourceAppIdentifier;
- (id)staticDiskUsage;
- (id)storeCohortMetadata;
- (id)storeFront;
- (id)subgenres;
- (bool)supportsODR;
- (bool)userInitiatedUninstall;
- (id)valueForUndefinedKey:(id)arg1;
- (id)vendorName;
 */

- (BOOL)isKindOfClass:(Class)cls
{
   if(cls == PrivClass(LSApplicationProxy))
   {
       return YES;
   }
   return [super isKindOfClass:cls];
}

- (Class)class
{
    return PrivClass(LSApplicationProxy);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    NSMethodSignature *sig = [super methodSignatureForSelector:sel];
    if(sig)
    {
        return sig;
    }
    return [PrivClass(LSApplicationProxy) instanceMethodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)inv
{
    SEL sel = inv.selector;
    static NSMutableSet *seen;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ seen = [NSMutableSet set]; });
    NSString *name = NSStringFromSelector(sel);
    @synchronized(seen)
    {
        if(![seen containsObject:name])
        {
            [seen addObject:name];
        }
    }

    NSUInteger len = inv.methodSignature.methodReturnLength;
    if(len)
    {
        void *buf = calloc(1, len);
        [inv setReturnValue:buf];
        free(buf);
    }
}

- (BOOL)respondsToSelector:(SEL)sel
{
    if([super respondsToSelector:sel])
    {
        return YES;
    }
    return [PrivClass(LSApplicationProxy) instancesRespondToSelector:sel];
}

@end

@interface LSApplicationWorkspaceHooks: NSObject
@end

@implementation LSApplicationWorkspaceHooks {
    
}

+ (void)load
{
    [super load];
    
    SwizzleObjCMethod(@selector(defaultWorkspace), PrivClass(LSApplicationWorkspace), @selector(hook_defaultWorkspace), [LSApplicationWorkspaceHooks class], kSwizzleMethodTypeClass);
}

+ (instancetype)hook_defaultWorkspace
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SwizzleObjCMethod(@selector(allApplications), PrivClass(LSApplicationWorkspace), @selector(hook_allApplications), [LSApplicationWorkspaceHooks class], kSwizzleMethodTypeInstance);
        SwizzleObjCMethod(@selector(allInstalledApplications), PrivClass(LSApplicationWorkspace), @selector(hook_allInstalledApplications), [LSApplicationWorkspaceHooks class], kSwizzleMethodTypeInstance);
        SwizzleObjCMethod(@selector(uninstallApplication:withOptions:error:usingBlock:), PrivClass(LSApplicationWorkspace), @selector(hook_uninstallApplication:withOptions:error:usingBlock:), [LSApplicationWorkspaceHooks class], kSwizzleMethodTypeInstance);
        SwizzleObjCMethod(@selector(openApplicationWithBundleID:), PrivClass(LSApplicationWorkspace), @selector(hook_openApplicationWithBundleID:), [LSApplicationWorkspaceHooks class], kSwizzleMethodTypeInstance);
        SwizzleObjCMethod(@selector(_applicationIconImageForBundleIdentifier:format:scale:), [UIImage class], @selector(hook_iconForBundleID:format:scale:), [UIImage class], kSwizzleMethodTypeClass);
    });
    return [self hook_defaultWorkspace];
}

+ (NSArray<LDEApplicationProxy*>*)giveAllApps
{
    LDEApplicationWorkspace *workspace = [LDEApplicationWorkspace shared];
    [workspace ping];
    
    NSArray<LDEApplicationObject*> *allApplicationObjects = [workspace allApplicationObjects];
    NSMutableArray<LDEApplicationProxy*> *apps = [NSMutableArray array];
    for(LDEApplicationObject *object in allApplicationObjects)
    {
        LDEApplicationProxy *proxy = [LDEApplicationProxy applicationProxyForLDEObject:object];
        [apps addObject:proxy];
    }
    
    return apps;
}

- (NSArray<LDEApplicationProxy*>*)hook_allApplications
{
    return [LSApplicationWorkspaceHooks giveAllApps];
}

- (NSArray<LDEApplicationProxy*>*)hook_allInstalledApplications
{
    return [LSApplicationWorkspaceHooks giveAllApps];
}

- (BOOL)hook_uninstallApplication:(NSString *)bundleID
                      withOptions:(NSDictionary<NSString *, id> *_Nullable)arg1
                            error:(NSError **)arg2
                       usingBlock:(_Nullable id)arg3 __attribute__((swift_error(nonnull_error)))
{
    return [[LDEApplicationWorkspace shared] deleteApplicationWithBundleID:bundleID];
}

- (BOOL)hook_openApplicationWithBundleID:(NSString*)bundleIdentifier
{
    return [[LDEApplicationWorkspace shared] openApplicationWithBundleID:bundleIdentifier];
}

@end

@implementation UIImage (PrivateHook)

+ (UIImage *)hook_iconForBundleID:(NSString *)bundleIdentifier
                           format:(int)format
                            scale:(CGFloat)scale
{
    LDEApplicationObject *obj = [[LDEApplicationWorkspace shared] applicationObjectForBundleID:bundleIdentifier];
    if(obj && obj.icon)
    {
        CGSize targetSize;
        {
            static NSMutableDictionary<NSString *, NSValue *> *sizeCache;
            static dispatch_once_t once;
            dispatch_once(&once, ^{
                sizeCache = [NSMutableDictionary new];
            });
            
            NSString *key = [NSString stringWithFormat:@"%d@%.1f", format, scale];
            @synchronized(sizeCache)
            {
                NSValue *found = sizeCache[key];
                if(found)
                {
                    targetSize = found.CGSizeValue;
                    goto got_size;
                }
            }
            
            /* dw apple tells us what their size and scale is dw ^^ */
            UIImage *probe = [self hook_iconForBundleID:@"com.apple.Preferences" format:format scale:scale];
            targetSize = probe ? probe.size : CGSizeMake(60, 60);
            
            @synchronized(sizeCache)
            {
                sizeCache[key] = [NSValue valueWithCGSize:targetSize];
            }
        }
    got_size:
        {
            if(@available(iOS 26.0, *))
            {
                /* the asking apple way */
                UIImage *image = Gib26Icon(obj.icon, obj.darkIcon, targetSize, scale);
                if(image == nil)
                {
                    goto manual_way;
                }
                return image;
            }
            
        manual_way:
            {
                /* the doing it my self way */
                CGRect r = (CGRect){ .origin = CGPointZero, .size = targetSize };
                UIBezierPath *mask = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:targetSize.width * 0.2237];
                UIGraphicsImageRendererFormat *fmt = [UIGraphicsImageRendererFormat defaultFormat];
                fmt.scale = scale;
                UIGraphicsImageRenderer *rr = [[UIGraphicsImageRenderer alloc] initWithSize:targetSize format:fmt];
                UIImage *curvedImage = [rr imageWithActions:^(UIGraphicsImageRendererContext *ctx){
                    [mask addClip];
                    [obj.icon drawInRect:r];
                }];
                return curvedImage;
            }
        }
    }
    return [self hook_iconForBundleID:bundleIdentifier format:format scale:scale];
}

@end
