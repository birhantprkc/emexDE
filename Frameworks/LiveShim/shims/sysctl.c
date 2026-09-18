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

#include <LiveShim/shim.h>
#include <Broadpatch/Broadpatch.h>

#if LIVESHIM_SYSCTL_ENABLED

LIBKERN_PATCH(int, sysctl, (int *name,
                            u_int namelen,
                            void *__sized_by(*oldlenp) oldp,
                            size_t *oldlenp,
                            void *__sized_by(newlen) newp,
                            size_t newlen),
{
    int ret = (int)liveshim_syscall(SYS_sysctl, name, namelen, oldp, oldlenp, newp, newlen);
    return (ret == -1 && errno == ENOSYS) ? LIBKERN_ORIG(sysctl)(name, namelen, oldp, oldlenp, newp, newlen) : ret;
});

LIBKERN_PATCH(int, sysctlbyname, (const char *name,
                                  void *__sized_by(*oldlenp) oldp,
                                  size_t *oldlenp,
                                  void *__sized_by(newlen) newp,
                                  size_t newlen),
{
    int ret = (int)liveshim_syscall(SYS_sysctlbyname, name, oldp, oldlenp, newp, newlen);
    return (ret == -1 && errno == ENOSYS) ? LIBKERN_ORIG(sysctlbyname)(name, oldp, oldlenp, newp, newlen) : ret;
});

LIBKERN_PATCH(int, gethostname, (char *name,
                                 size_t len),
{
    int mib[2] = { CTL_KERN, KERN_HOSTNAME };
    int retval = (int)sysctl(mib, 2, name, &len, NULL, 0);
    name[len] = '\0';
    return retval;
});

LIBKERN_PATCH(int, sethostname, (char *name,
                                 size_t len),
{
    int mib[2] = { CTL_KERN, KERN_HOSTNAME };
    return (int)sysctl(mib, 2, NULL, NULL, name, len);
});

__attribute__((constructor))
static void InstallPatches(void)
{
    LIBKERN_INSTALL_PATCH(sysctl);
    LIBKERN_INSTALL_PATCH(sysctlbyname);
    LIBKERN_INSTALL_PATCH(gethostname);
    LIBKERN_INSTALL_PATCH(sethostname);
}

#endif /* LIVESHIM_SYSCTL_ENABLED */
