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

#if LIVESHIM_UCRED_ENABLED

LIBKERN_PATCH(uid_t, getuid, (void),
{
    return (uid_t)liveshim_syscall(SYS_getuid);
});

LIBKERN_PATCH(gid_t, getgid, (void),
{
    return (gid_t)liveshim_syscall(SYS_getgid);
});

LIBKERN_PATCH(uid_t, geteuid, (void),
{
    return (uid_t)liveshim_syscall(SYS_geteuid);
});

LIBKERN_PATCH(gid_t, getegid, (void),
{
    return (gid_t)liveshim_syscall(SYS_getegid);
});

LIBKERN_PATCH(pid_t, getppid, (void),
{
    return (pid_t)liveshim_syscall(SYS_getppid);
});

LIBKERN_PATCH(int, setuid, (uid_t uid),
{
    return (int)liveshim_syscall(SYS_setuid, uid);
});

LIBKERN_PATCH(int, seteuid, (uid_t euid),
{
    return (int)liveshim_syscall(SYS_seteuid, euid);
});

LIBKERN_PATCH(int, setruid, (uid_t uid),
{
    return (int)liveshim_syscall(SYS_setreuid, uid, -1);
});

LIBKERN_PATCH(int, setreuid, (uid_t ruid,
                              uid_t euid),
{
    return (int)liveshim_syscall(SYS_setreuid, ruid, euid);
});

LIBKERN_PATCH(int, setgid, (gid_t gid),
{
    return (int)liveshim_syscall(SYS_setgid, gid);
});

LIBKERN_PATCH(int, setegid, (gid_t gid),
{
    return (int)liveshim_syscall(SYS_setegid, gid);
});

LIBKERN_PATCH(int, setrgid, (gid_t gid),
{
    return (int)liveshim_syscall(SYS_setregid, gid, -1);
});

LIBKERN_PATCH(int, setregid, (gid_t egid,
                              gid_t rgid),
{
    return (int)liveshim_syscall(SYS_setregid, egid, rgid);
});

LIBKERN_PATCH(pid_t, getsid, (pid_t sid),
{
    return (pid_t)liveshim_syscall(SYS_getsid, sid);
});

LIBKERN_PATCH(int, setsid, (void),
{
    return (int)liveshim_syscall(SYS_setsid);
});

__attribute__((constructor))
static void InstallPatches(void)
{
    LIBKERN_INSTALL_PATCH(getuid);
    LIBKERN_INSTALL_PATCH(getgid);
    LIBKERN_INSTALL_PATCH(geteuid);
    LIBKERN_INSTALL_PATCH(getegid);
    LIBKERN_INSTALL_PATCH(getppid);
    LIBKERN_INSTALL_PATCH(setuid);
    LIBKERN_INSTALL_PATCH(seteuid);
    LIBKERN_INSTALL_PATCH(setruid);
    LIBKERN_INSTALL_PATCH(setreuid);
    LIBKERN_INSTALL_PATCH(setgid);
    LIBKERN_INSTALL_PATCH(setegid);
    LIBKERN_INSTALL_PATCH(setrgid);
    LIBKERN_INSTALL_PATCH(setregid);
    LIBKERN_INSTALL_PATCH(getsid);
    LIBKERN_INSTALL_PATCH(setsid);
}

#endif /* LIVESHIM_UCRED_ENABLED */
