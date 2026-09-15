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

#include <LindChain/ProcEnvironment/Surface/kxld/vtable.h>

kxld_vtab_t *kxld_vtable = &(kxld_vtab_t){
    .LCMapMachOFromFDRO = LCMapMachOFromFDRO,
    .LCUnmapMachO = LCUnmapMachO,
    .mmap = mmap,
    .mprotect = mprotect,
    .munmap = munmap,
    .KXRegisterKextExports = KXRegisterKextExports,
    .KXApplyFixups = KXApplyFixups,
    .KXRunInitializers = KXRunInitializers,
    .KXLocateKmod = KXLocateKmod,
    .KXMapMachOExecutable = KXMapMachOExecutable,
    .KXRegisterObjCImage = KXRegisterObjCImage,
    .KXResealDataConst = KXResealDataConst,
    .KXRegisterKext = KXRegisterKext,
    .KXUnregisterKext = KXUnregisterKext,
    .KXGetRegisteredKextForIdentifier = KXGetRegisteredKextForIdentifier,
    .KXValidateCodeSignature = KXValidateCodeSignature,
};
