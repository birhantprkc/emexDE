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

#import <LiveShim/LiveShimSyscall.h>
#import <LiveShim/shim.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#include <Broadpatch/Broadpatch.h>

NSMutableDictionary *SecItemPrepare(CFDictionaryRef query)
{
    NSMutableDictionary *queryCopy = ((__bridge NSDictionary *)query).mutableCopy;
    NSString *accessGroup = queryCopy[(__bridge id)kSecAttrAccessGroup];
    NSString *account = queryCopy[(__bridge id)kSecAttrAccount];
    
    if(!accessGroup)
    {
        accessGroup = [[NSBundle mainBundle] bundleIdentifier];
    }
    if(account)
    {
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccount];
        queryCopy[(__bridge id)kSecAttrAccount] = [NSString stringWithFormat:@"%@@%@", accessGroup, account];
    }
    else
    {
        [queryCopy removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    }
    
    return queryCopy;
}

/* will later be ksurface syscalls (safe finally) */
LIBKERN_PATCH(OSStatus, SecItemAdd, (CFDictionaryRef query,
                                     CFTypeRef *result),
{
    return LIBKERN_ORIG(SecItemAdd)((__bridge CFDictionaryRef)SecItemPrepare(query), result);
});

LIBKERN_PATCH(OSStatus, SecItemCopyMatching, (CFDictionaryRef query,
                                              CFTypeRef *result),
{
    return LIBKERN_ORIG(SecItemCopyMatching)((__bridge CFDictionaryRef)SecItemPrepare(query), result);
});

LIBKERN_PATCH(OSStatus, SecItemUpdate, (CFDictionaryRef query,
                                        CFTypeRef *result),
{
    return LIBKERN_ORIG(SecItemUpdate)((__bridge CFDictionaryRef)SecItemPrepare(query), result);
});

LIBKERN_PATCH(OSStatus, SecItemDelete, (CFDictionaryRef query),
{
    return LIBKERN_ORIG(SecItemDelete)((__bridge CFDictionaryRef)SecItemPrepare(query));
});

__attribute__((constructor))
static void InstallPatches(void)
{
    LIBKERN_INSTALL_PATCH(SecItemAdd);
    LIBKERN_INSTALL_PATCH(SecItemCopyMatching);
    LIBKERN_INSTALL_PATCH(SecItemUpdate);
    LIBKERN_INSTALL_PATCH(SecItemDelete);
}
