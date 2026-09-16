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

#ifndef LIBKERN_PATCH_H
#define LIBKERN_PATCH_H

#define LIBKERN_DEFINE_PATCHABLE(ret, name, params)             \
    static ret name##__impl params;                             \
                                                                \
    ret name params;                                            \
                                                                \
    __attribute__((used, section("__DATA,__lkswz")))            \
    void *name##__ptr = (void *)&name##__impl;                  \
                                                                \
    __asm__(                                                    \
        ".section __TEXT,__text,regular,pure_instructions\n"    \
        ".globl _" #name "\n"                                   \
        ".p2align 2\n"                                          \
        "_" #name ":\n"                                         \
        "    adrp x16, _" #name "__ptr@PAGE\n"                  \
        "    ldr  x16, [x16, _" #name "__ptr@PAGEOFF]\n"        \
        "    br   x16\n"                                        \
    );                                                          \
                                                                \
    static __attribute__((noinline, optnone, used))             \
    ret name##__impl params

#define LIBKERN__DECLARE_PATCHABLE(ret, name, params)           \
    ret name params;                                            \
    extern void *name##__ptr

#define LIBKERN_PATCH(ret, name, params, ...)                   \
    extern void *name##__ptr;                                   \
    static ret (*name##__orig) params;                          \
    static ret name##__swz params __VA_ARGS__                   \
    static void name##__install(void) {                         \
        name##__orig = (ret (*) params)name##__ptr;             \
        name##__ptr  = (void *)name##__swz;                     \
    }                                                           \
    static void name##__uninstall(void) {                       \
        name##__ptr  = (void *)name##__orig;                    \
    }                                                           \
    extern int name##__need_semi

#define LIBKERN_INSTALL_PATCH(name)                             \
    name##__install()

#define LIBKERN_UNINSTALL_PATCH(name)                           \
    name##__uninstall()

#endif /* LIBKERN_PATCH_H */
