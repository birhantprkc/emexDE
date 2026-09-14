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
        return NO;
    }
    
    /* need new launch service instance */
    PELaunchService *service = [[PELaunchServiceManager shared] serviceForIdentifier:@"org.emexlabs.compilerd"];
    if(service == NULL)
    {
        return NO;
    }
    
    PELaunchServiceInstance *compilerInstance = [service newInstance];
    if(compilerInstance == NULL)
    {
        return NO;
    }
    
    /* now we got it now we need to get it's endpoint */
    NSXPCListenerEndpoint *endpoint = [compilerInstance xpcEndpoint];
    if(endpoint == NULL)
    {
        return NO;
    }
    
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithListenerEndpoint:endpoint];
    if(connection == NULL)
    {
        return NO;
    }
    
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(NXCompilationServiceProtocol)];
    /* TODO: add disconnect handlers obviously  */
    [connection resume];
    
    __block BOOL result = NO;
    __block NSArray<MDKDiagnostic*> *resultDiagnostic;
    __block NSString *resultMainSource;
    __block BOOL failed = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
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
        }];
    }
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    if(failed)
    {
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
    
    return result;
}

+ (BOOL)isAvailable
{
    return !NXApplicationState.extensionLessMode;
}

@end
