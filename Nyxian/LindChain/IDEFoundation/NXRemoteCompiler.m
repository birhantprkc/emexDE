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

#import <LindChain/IDEFoundation/NXRemoteCompiler.h>
#import <LindChain/ProcEnvironment/PELaunchServiceManager.h>
#import <Nyxian-Swift.h>

@implementation NXRemoteCompiler

+ (BOOL)executeJob:(MDKJob*)job
   withDiagnostics:(NSArray<MDKDiagnostic*>**)diagnostics
    withMainSource:(NSString**)mainSource
{
    if(![self isAvailable])
    {
        if(mainSource)
        {
            *mainSource = job.inputFileURLs[0].path;
        }
        if(diagnostics)
        {
            *diagnostics = @[[MDKDiagnostic diagnosticWithType:kCCDiagnosticTypeInternal level:kCCDiagnosticLevelFatal mainSource:job.inputFileURLs[0].path fileSourceLocation:nil message:@"Remote compilation service is not available."]];
        }
        return NO;
    }
    
    /* need new launch service instance */
    PELaunchService *service = [[PELaunchServiceManager shared] serviceForIdentifier:@"org.emexlabs.compilerd"];
    if(service == NULL)
    {
        if(mainSource)
        {
            *mainSource = job.inputFileURLs[0].path;
        }
        if(diagnostics)
        {
            *diagnostics = @[[MDKDiagnostic diagnosticWithType:kCCDiagnosticTypeInternal level:kCCDiagnosticLevelFatal mainSource:job.inputFileURLs[0].path fileSourceLocation:nil message:@"Remote compilation service is not available."]];
        }
        return NO;
    }
    
    PELaunchServiceInstance *compilerInstance = [service newInstance];
    if(compilerInstance == NULL)
    {
        if(mainSource)
        {
            *mainSource = job.inputFileURLs[0].path;
        }
        if(diagnostics)
        {
            *diagnostics = @[[MDKDiagnostic diagnosticWithType:kCCDiagnosticTypeInternal level:kCCDiagnosticLevelFatal mainSource:job.inputFileURLs[0].path fileSourceLocation:nil message:@"Couldn't create remote compilation service instance."]];
        }
        return NO;
    }
    
    /* now we got it now we need to get it's endpoint */
    NSXPCListenerEndpoint *endpoint = [compilerInstance xpcEndpoint];
    if(endpoint == NULL)
    {
        if(mainSource)
        {
            *mainSource = job.inputFileURLs[0].path;
        }
        if(diagnostics)
        {
            *diagnostics = @[[MDKDiagnostic diagnosticWithType:kCCDiagnosticTypeInternal level:kCCDiagnosticLevelFatal mainSource:job.inputFileURLs[0].path fileSourceLocation:nil message:@"Couldn't get remote compilation service's NSXPC endpoint."]];
        }
        [compilerInstance terminate];
        return NO;
    }
    
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];
    if(connection == NULL)
    {
        if(mainSource)
        {
            *mainSource = job.inputFileURLs[0].path;
        }
        if(diagnostics)
        {
            *diagnostics = @[[MDKDiagnostic diagnosticWithType:kCCDiagnosticTypeInternal level:kCCDiagnosticLevelFatal mainSource:nil fileSourceLocation:nil message:@"Couldn't establish connection with remote compilation service instance."]];
        }
        [compilerInstance terminate];
        return NO;
    }
    
    __block BOOL failed = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    /* creating brand new connection */
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(NXCompilationServiceProtocol)];
    connection.invalidationHandler = ^{
        failed = YES;
        dispatch_semaphore_signal(sema); };
    connection.interruptionHandler = ^{
        failed = YES;
        dispatch_semaphore_signal(sema);
    };
    NSXPCInterface *iface = [NSXPCInterface interfaceWithProtocol:@protocol(NXCompilationServiceProtocol)];
    NSSet *classes = [NSSet setWithObjects: [NSArray class], [MDKJob class], [MDKDiagnostic class], [MDKFileSourceLocation class], [NSString class], [NSURL class], nil];
    [iface setClasses:classes forSelector:@selector(executeJob:withReply:) argumentIndex:1 ofReply:YES];
    connection.remoteObjectInterface = iface;
    [connection resume];
    
    __block BOOL result = NO;
    __block NSArray<MDKDiagnostic*> *resultDiagnostic;
    __block NSString *resultMainSource;
    
    id proxy = [connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
        /* semaphores remember the signal, it doesnt have to catch them in time */
        failed = YES;
        dispatch_semaphore_signal(sema);
    }];
    
    if(proxy == NULL)
    {
        /* semaphores remember the signal, it doesnt have to catch them in time */
        failed = YES;
        dispatch_semaphore_signal(sema);
    }
    else
    {
        [proxy executeJob:job withReply:^(BOOL successRet, NSArray<MDKDiagnostic*> *diagnosticsRet, NSString *mainSourceRet){
            result = successRet;
            resultDiagnostic = diagnosticsRet;
            resultMainSource = mainSourceRet;
            dispatch_semaphore_signal(sema);
        }];
    }
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    if(failed)
    {
        if(mainSource)
        {
            *mainSource = job.inputFileURLs[0].path;
        }
        if(diagnostics)
        {
            *diagnostics = @[[MDKDiagnostic diagnosticWithType:kCCDiagnosticTypeInternal level:kCCDiagnosticLevelFatal mainSource:job.inputFileURLs[0].path fileSourceLocation:nil message:@"Couldn't keep connection with remote compilation service instance."]];
        }
        [compilerInstance terminate];
        return NO;
    }
    
    if(diagnostics)
    {
        *diagnostics = resultDiagnostic;
    }
    if(mainSource)
    {
        *mainSource = resultMainSource;
    }
    
    [compilerInstance terminate];
    return result;
}

+ (BOOL)isAvailable
{
    return !NXApplicationState.extensionLessMode;
}

@end
