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
#include <Nyxian/LindChain/ProcEnvironment/Surface/libkern/bsd/proc_info.h>
#include <Broadpatch/Broadpatch.h>

#if LIVESHIM_PROC_ENABLED

extern int __proc_info(int32_t callnum, int32_t pid, uint32_t flavor, uint64_t arg, user_addr_t buffer, int32_t buffersize);

LIBKERN_PATCH(int, __proc_info, (int32_t callnum,
                                 int32_t pid,
                                 uint32_t flavor,
                                 uint64_t arg,
                                 user_addr_t buffer,
                                 int32_t buffersize),
{
    errno = 0;
    int ret = (int)liveshim_syscall(SYS_proc_info, callnum, pid, flavor, arg, buffer, buffersize);
    if(errno == ENOSYS)
    {
        errno = 0;  /* must be reset so it is no errno */
        ret = LIBKERN_ORIG(__proc_info)(callnum, pid, flavor, arg, buffer, buffersize);
    }
    return ret;
});

LIBKERN_PATCH(int, proc_pidinfo, (pid_t pid,
                                  int flavor,
                                  uint64_t arg,
                                  void * buffer,
                                  int buffersize),{
    return __proc_info(PROC_INFO_CALL_PIDINFO, pid, flavor, 0, (user_addr_t)buffer, buffersize);
});

LIBKERN_PATCH(int, proc_name, (pid_t pid,
                               void *buffer,
                               uint32_t buffersize),
{
    struct proc_bsdinfo pbsd;
    if(buffersize < sizeof(pbsd.pbi_name))
    {
        errno = ENOMEM;
        return 0;
    }
    
    int retval = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &pbsd, sizeof(pbsd));
    if(retval != 0)
    {
        if(pbsd.pbi_name[0])
        {
            bcopy(&pbsd.pbi_name, buffer, sizeof(pbsd.pbi_name));
        }
        else
        {
            bcopy(&pbsd.pbi_comm, buffer, sizeof(pbsd.pbi_comm));
        }
        return (int)strlen(buffer);
    }
    return 0;
});

LIBKERN_PATCH(int, proc_pidpath, (pid_t pid,
                                  void *buffer,
                                  uint32_t buffersize),
{
    /* sanity check */
    if(buffersize == 0 || buffer == NULL)
    {
        return 0;
    }
    
    /* syscall with SYS_PROCPATH */
    int retval = proc_pidinfo(pid, PROC_PIDPATHINFO, 0, buffer, buffersize);
    if(retval != 0)
    {
        return 0;
    }
    
    /* final return of lenght */
    return (int)strlen((char*)buffer);
});

LIBKERN_PATCH(int, proc_listallpids, (void *buffer,
                                      int buffersize),
{
    if(buffersize < 0)
    {
        errno = EINVAL;
        return -1;
    }
    
    if(buffersize < 0)
    {
        errno = EINVAL;
        return -1;
    }
    
    struct kinfo_proc kp[500];
    size_t len = sizeof(kp);
    
    int mib[3] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL };
    sysctl(mib, 3, &kp, &len, NULL, 0); /* goes through broadpatch */
    
    size_t count = (uint32_t)(len / sizeof(struct kinfo_proc));
    
    size_t n = 0;
    size_t needed_bytes = 0;
    
    needed_bytes = (size_t)count * sizeof(pid_t);
    
    if(buffer != NULL && buffersize > 0)
    {
        size_t capacity = (size_t)buffersize / sizeof(pid_t);
        n = count < capacity ? count : capacity;
        
        pid_t *pids = (pid_t *)buffer;
        
        for(size_t i = 0; i < n; i++)
        {
            pids[i] = kp[i].kp_proc.p_pid;
        }
    }
    
    if(buffer == NULL || buffersize == 0)
    {
        return (int)needed_bytes;
    }
    
    return (int)(n * sizeof(pid_t));
});

LIBKERN_PATCH(int, proc_pid_rusage, (int pid,
                                     int flavor,
                                     rusage_info_t *buffer),
{
    return __proc_info(PROC_INFO_CALL_PIDRUSAGE, pid, (uint32_t)flavor, (uint64_t)0, (user_addr_t)buffer, 0);
});

LIBKERN_PATCH(int, proc_kmsgbuf, (void *buffer,
                                  uint32_t buffersize),{
    return __proc_info(PROC_INFO_CALL_KERNMSGBUF, 0, 0, (uint64_t)0, (user_addr_t)buffer, buffersize);
});

LIBKERN_PATCH(int, kill, (pid_t pid,
                          int sig),
{
    return (int)liveshim_syscall(SYS_kill, pid, sig);
});

LIBKERN_PATCH(int, raise, (int sig),{
    return kill(getpid(), sig);
});

__attribute__((constructor))
static void InstallPatches(void)
{
    LIBKERN_INSTALL_PATCH(__proc_info);
    LIBKERN_INSTALL_PATCH(proc_pidinfo);
    LIBKERN_INSTALL_PATCH(proc_name);
    LIBKERN_INSTALL_PATCH(proc_pidpath);
    LIBKERN_INSTALL_PATCH(proc_listallpids);
    LIBKERN_INSTALL_PATCH(proc_pid_rusage);
    LIBKERN_INSTALL_PATCH(proc_kmsgbuf);
    LIBKERN_INSTALL_PATCH(kill);
    LIBKERN_INSTALL_PATCH(raise);
}

#endif /* LIVESHIM_PROC_ENABLED */
