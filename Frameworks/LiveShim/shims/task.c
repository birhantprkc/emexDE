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

#if LIVESHIM_TASK_ENABLED

static inline kern_return_t __task_for_pid(mach_port_name_t tp_in,
                                           pid_t pid,
                                           mach_port_name_t *tp_out,
                                           bool name_port)
{
    if(tp_out == NULL)
    {
        return KERN_FAILURE;
    }
    
    *tp_out = MACH_PORT_NULL;   /* SYS_gettask may not zero it out on failure */
    int64_t ret = liveshim_syscall(SYS_task_for_pid, pid, name_port, tp_out);
    if(ret == -1 || *tp_out == MACH_PORT_NULL)
    {
        return KERN_FAILURE;
    }
    
    return KERN_SUCCESS;
}

LIBKERN_PATCH(kern_return_t, task_for_pid, (mach_port_name_t tp_in,
                                            pid_t pid,
                                            mach_port_name_t *tp_out),
{
    return __task_for_pid(tp_in, pid, tp_out, false);
});

LIBKERN_PATCH(kern_return_t, task_name_for_pid, (mach_port_name_t tp_in,
                                                 pid_t pid,
                                                 mach_port_name_t *tp_out),
{
    return __task_for_pid(tp_in, pid, tp_out, true);
});

/* NEED PATCHES FOR READ AND INSPECT */

__attribute__((constructor))
static void InstallPatches(void)
{
    LIBKERN_INSTALL_PATCH(task_for_pid);
    LIBKERN_INSTALL_PATCH(task_name_for_pid);
}

#endif /* LIVESHIM_TASK_ENABLED */
