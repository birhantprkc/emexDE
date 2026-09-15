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

#ifndef KXLD_VTABLE_H
#define KXLD_VTABLE_H

#include <LindChain/ProcEnvironment/Surface/kxld/export.h>
#include <LindChain/ProcEnvironment/Surface/kxld/fixup.h>
#include <LindChain/ProcEnvironment/Surface/kxld/image.h>
#include <LindChain/ProcEnvironment/Surface/kxld/init.h>
#include <LindChain/ProcEnvironment/Surface/kxld/kmod.h>
#include <LindChain/ProcEnvironment/Surface/kxld/kxopen.h>
#include <LindChain/ProcEnvironment/Surface/kxld/mapper.h>
#include <LindChain/ProcEnvironment/Surface/kxld/objc.h>
#include <LindChain/ProcEnvironment/Surface/kxld/pseudo.h>
#include <LindChain/ProcEnvironment/Surface/kxld/reseal.h>
#include <LindChain/ProcEnvironment/Surface/kxld/resolve.h>
#include <LindChain/ProcEnvironment/Surface/kxld/validation.h>
#include <sys/mman.h>

typedef struct kxld_vtab {
    /* LCMachOUtils */
    LCMachO *(*LCMapMachOFromFDRO)(int fd);
    void (*LCUnmapMachO)(LCMachO *machO);
    
    /* mmap */
    void *(*mmap)(void *addr, size_t len, int prot, int flags, int fd, off_t offset);
    int (*mprotect)(void *addr, size_t len, int prot);
    int (*munmap)(void *addr, size_t len);
    
    /* KXLD it self */
    bool (*KXRegisterKextExports)(kxld_image_info_t *image_info);
    bool (*KXApplyFixups)(kxld_image_info_t *image_info);
    bool (*KXRunInitializers)(kxld_image_info_t *image_info);
    bool (*KXLocateKmod)(kxld_image_info_t *image_info);
    bool (*KXMapMachOExecutable)(LCMachO *machO, int mode, kxld_image_info_t *image_info);
    bool (*KXRegisterObjCImage)(kxld_image_info_t *image_info);
    bool (*KXResealDataConst)(kxld_image_info_t *image_info);
    kern_return_t (*KXRegisterKext)(kxld_image_info_t *image_info);
    kern_return_t (*KXUnregisterKext)(kxld_image_info_t *image_info);
    kern_return_t (*KXGetRegisteredKextForIdentifier)(const char *identifier, kxld_image_info_t **image_info);
    bool (*KXValidateCodeSignature)(LCMachO *machO);
} kxld_vtab_t;

extern kxld_vtab_t *kxld_vtable;

#endif /* KXLD_VTABLE_H */
