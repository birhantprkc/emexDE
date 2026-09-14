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

int main(void)
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
    
    /* getting unique bootstrap identifier for port */
    const char *uniqueBootstrapRegistryIdentifier = getenv("PEUBID");
    if(uniqueBootstrapRegistryIdentifier == NULL)
    {
        return 1;
    }
    
    NSString *ubid = [NSString stringWithCString:uniqueBootstrapRegistryIdentifier encoding:NSUTF8StringEncoding];
    if(ubid == NULL)
    {
        return 1;
    }
    
    /* ready for compilation service =3 */
    /* like I said for better memory management */
    
    CFRunLoopRun();
    return 0;
}
