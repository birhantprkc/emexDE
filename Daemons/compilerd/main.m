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
#import <MobileDevelopmentKit/MobileDevelopmentKit.h>
#import <LiveShim/Service.h>
#import <LiveShim/ServiceProtocol.h>

static NSString *ubid = nil;

@protocol NXCompilationServiceProtocol <NSObject>

- (void)executeJob:(MDKJob*)job withReply:(void (^)(BOOL success, NSArray<MDKDiagnostic*> *diagnostics, NSString *mainSource))reply;

@end

@interface NXCompilationService : NSObject <NXCompilationServiceProtocol,PEServiceProtocol>
@end

@implementation NXCompilationService

- (void)executeJob:(MDKJob*)job
         withReply:(void (^)(BOOL success, NSArray<MDKDiagnostic*> *diagnostics, NSString *mainSource))reply
{
    NSArray<MDKDiagnostic*> *diagnostic = nil;
    NSString *mainSource = nil;
    BOOL success = [job executeJobWithOutDiagnostics:&diagnostic withOutMainSource:&mainSource];
    reply(success, diagnostic, mainSource);
}

- (void)clientDidConnectWithConnection:(NSXPCConnection *)client
{
    return;
}

+ (Protocol *)observerProtocol
{
    return nil;
}

+ (NSString *)servcieIdentifier
{
    return ubid;
}

+ (Protocol *)serviceProtocol
{
    return @protocol(NXCompilationServiceProtocol);
}

@end

int main(int argc, char **argv)
{
    /* checking permissions */
    if(getuid() != 0 ||
       getgid() != 0)
    {
        if(setreuid(0, 0) != 0)
        {
            return 1;
        }
        if(setregid(0, 0) != 0)
        {
            return 1;
        }
    }
    
    /* getting nxroot */
    const char *virtualRootPathCStr = getenv("NXROOT");
    if(virtualRootPathCStr == NULL)
    {
        return 1;
    }
    
    NSString *virtualRootPath = [NSString stringWithCString:virtualRootPathCStr encoding:NSUTF8StringEncoding];
    if(virtualRootPath == NULL)
    {
        return 1;
    }
    
    NSString *nyxianRootPath = virtualRootPath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    if(nyxianRootPath == NULL)
    {
        return 1;
    }
    
    NSString *nyxianTmpDir = [nyxianRootPath stringByAppendingPathComponent:@"tmp"];
    if(nyxianTmpDir == NULL)
    {
        return 1;
    }
    
    /* setting env up */
    if(setenv("HOME", nyxianRootPath.UTF8String, 1) != 0 ||
       setenv("CFFIXED_USER_HOME", nyxianRootPath.UTF8String, 1) != 0 ||
       setenv("TMPDIR", nyxianTmpDir.UTF8String, 1) != 0)
    {
        return 1;
    }
    
    /* making sure we do not free */
    setenv("CCForceDisableFree", "1", 1);
    
    /* getting unique bootstrap identifier for port */
    const char *uniqueBootstrapRegistryIdentifier = getenv("PEUBID");
    if(uniqueBootstrapRegistryIdentifier == NULL)
    {
        return 1;
    }
    
    ubid = [NSString stringWithCString:uniqueBootstrapRegistryIdentifier encoding:NSUTF8StringEncoding];
    if(ubid == NULL)
    {
        return 1;
    }
    
    /* ready for compilation service =3 */
    return PEServiceMain(argc, argv, [NXCompilationService class]);
}
