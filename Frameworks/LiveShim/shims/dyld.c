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
#include <LiveShim/dyld.h>
#include <LiveShim/cdhash.h>
#include <Frameworks/HWHook/HWHookThreadContext.h>
#include <mach-o/dyld_images.h>
#include <sys/mman.h>
#include <copyfile.h>
#include <sys/clonefile.h>
#include <copyfile.h>
#include <time.h>
#include <os/lock.h>
#include <LiveShim/patchcache.h>
#include <Broadpatch/Broadpatch.h>
#include <Nyxian/LindChain/Private/mach/mach_vm.h>
#include <Nyxian/LindChain/ProcEnvironment/LiveContainer/LCMachOUtils.h>

#if __has_include(<ksurface_config.h>)
#include <ksurface_config.h>
#else
#define KSURFACE_DYLD_HOOK_LOGGING_ENABLED 0
#define KSURFACE_DYLD_HARDENED_CDHASH_VERIFIER 1
#endif /* __has_include(<ksurface_config.h>) */

#if KSURFACE_DYLD_HOOK_LOGGING_ENABLED

static inline void _dyld_hook_log_timestamp(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    printf("[%6ld.%03ldms] ", ts.tv_sec % 1000, ts.tv_nsec / 1000000);
}

#define dyld_hook_log(fmt, ...) \
    do { \
        _dyld_hook_log_timestamp(); \
        printf(fmt, ##__VA_ARGS__); \
    } while (0)

#else
#define dyld_hook_log(fmt, ...) ((void)0)
#endif /* KSURFACE_DYLD_HOOK_LOGGING_ENABLED */

#define PE_MMAP_FD_CACHE_MAX 128

typedef struct {
    dev_t dev;
    ino_t ino;
    
    int shadow_fd;
    char shadow_path[PATH_MAX];
    
    off_t signed_slice;
    bool signature_registered;
} dyld_fd_cache_entry_t;

static const char *mmap_sandbox_map_exec_allowed_path = NULL;

static _Thread_local dyld_fd_cache_entry_t dyld_fd_cache[PE_MMAP_FD_CACHE_MAX];
static _Thread_local size_t dyld_fd_cache_count;

static _Thread_local bool cdhash_verified = false;
static _Thread_local bool cdhash_must_valid;
static _Thread_local bool open_hardlock;
static _Thread_local const char *cdhash_data_container_match;
static _Thread_local dlopen_cdhash_verifier_failed_callback_t cdhash_verifier_failed_callback;

LIBKERN_DEFINE_PATCHABLE(bool, dyld_should_shadow_file, (int fd,
                                                         char path[PATH_MAX]))
{
    if(fcntl(fd, F_GETPATH, path) == -1)
    {
        return false;
    }
    
    static const char prefix[] = "/private/var/mobile/Containers/Data";
    const size_t prefix_len = sizeof(prefix) - 1;
    if(strncmp(path, prefix, prefix_len) != 0)
    {
        return false;
    }
    
    return path[prefix_len] == '\0' || path[prefix_len] == '/';
}

LIBKERN_DEFINE_PATCHABLE(dyld_fd_cache_entry_t *, dyld_fd_cache_find, (dev_t dev,
                                                                       ino_t ino))
{
    for(size_t i = 0; i < dyld_fd_cache_count; ++i)
    {
        dyld_fd_cache_entry_t *entry = &dyld_fd_cache[i];
        if(entry->dev == dev && entry->ino == ino)
        {
            return entry;
        }
    }
    
    return NULL;
}

LIBKERN_DEFINE_PATCHABLE(dyld_fd_cache_entry_t *, dyld_fd_cache_insert, (dev_t dev,
                                                                         ino_t ino,
                                                                         int shadow_fd,
                                                                         const char *shadow_path))
{
    if(dyld_fd_cache_count >= PE_MMAP_FD_CACHE_MAX)
    {
        return NULL;
    }
    
    dyld_fd_cache_entry_t *entry = &dyld_fd_cache[dyld_fd_cache_count++];
    
    memset(entry, 0, sizeof(*entry));
    
    entry->dev = dev;
    entry->ino = ino;
    entry->shadow_fd = shadow_fd;
    entry->signed_slice = (off_t)-1;
    entry->signature_registered = false;
    
    strlcpy(entry->shadow_path, shadow_path, sizeof(entry->shadow_path));
    
    return entry;
}

LIBKERN_DEFINE_PATCHABLE(void, dyld_fd_cache_reset, (void))
{
    for(size_t i = 0; i < dyld_fd_cache_count; ++i)
    {
        dyld_fd_cache_entry_t *entry = &dyld_fd_cache[i];
        
        if(entry->shadow_fd >= 0)
        {
            close(entry->shadow_fd);
        }

        if(entry->shadow_path[0] != '\0')
        {
            unlink(entry->shadow_path);
        }
    }
    
    memset(dyld_fd_cache, 0, sizeof(dyld_fd_cache));
    dyld_fd_cache_count = 0;
}

LIBKERN_DEFINE_PATCHABLE(bool, dyld_verify_shadow_cdhash_if_needed, (int fd))
{
    if(!cdhash_must_valid || cdhash_verified)
    {
        return true;
    }
    
    cdhash_must_valid = false;
    cdhash_verified = false;
    
    uint8_t found_cdhash[USER_FSIGNATURES_CDHASH_LEN];
    
    lseek(fd, 0, SEEK_SET);
    bool success = CDHashOfFD(fd, found_cdhash);
    lseek(fd, 0, SEEK_SET);

    if(success && cdhash_data_container_match != NULL && memcmp(cdhash_data_container_match, found_cdhash, USER_FSIGNATURES_CDHASH_LEN) == 0)
    {
        dyld_hook_log("[dyld_verify_shadow_cdhash_if_needed] cdhash valid\n");
        cdhash_verified = true;
        return true;
    }
    
    dyld_hook_log("[dyld_verify_shadow_cdhash_if_needed] cdhash mismatch\n");
    
#if KSURFACE_DYLD_HARDENED_CDHASH_VERIFIER
    open_hardlock = true;
#else
    if(cdhash_verifier_failed_callback != NULL)
    {
        cdhash_verifier_failed_callback(
            fd,
            &open_hardlock
        );
    }
#endif
    
    if(open_hardlock)
    {
        dyld_hook_log("[dyld_verify_shadow_cdhash_if_needed] cdhash hardlock\n");
        errno = EACCES;
        return false;
    }
    
    return true;
}

LIBKERN_DEFINE_PATCHABLE(int, dyld_create_shadow_fd, (int original_fd,
                                                      ino_t ino,
                                                      char shadow_path[PATH_MAX]))
{
    if(mmap_sandbox_map_exec_allowed_path == NULL)
    {
        errno = EINVAL;
        return -1;
    }
    
    char tmp_dir[PATH_MAX];
    char pid_dir[PATH_MAX];
    if((snprintf(tmp_dir, sizeof(tmp_dir), "%s/tmp", mmap_sandbox_map_exec_allowed_path) >= sizeof(tmp_dir)) ||
       (mkdir(tmp_dir, 0777) != 0 && errno != EEXIST) ||
       (snprintf(pid_dir, sizeof(pid_dir), "%s/%d", tmp_dir, getpid()) >= sizeof(pid_dir)) ||
       (mkdir(pid_dir, 0777) != 0 && errno != EEXIST) ||
       (snprintf(shadow_path, PATH_MAX, "%s/0x%llx.dylib", pid_dir, (unsigned long long)ino) >= PATH_MAX))
    {
        return -1;
    }
    
    int shadow_fd = open(shadow_path, O_RDONLY);
    if(shadow_fd >= 0)
    {
        goto validate_shadow;
    }
    
    if(fclonefileat(original_fd, AT_FDCWD, shadow_path, 0) == 0)
    {
        shadow_fd = open(shadow_path, O_RDONLY);
        if(shadow_fd >= 0)
        {
            return shadow_fd;
        }
        unlink(shadow_path);
        return -1;
    }
    
    if(errno == EEXIST)
    {
        shadow_fd = open(shadow_path, O_RDONLY);
        if(shadow_fd >= 0)
        {
            return shadow_fd;
        }
    }
    
    int source_fd = dup(original_fd);
    if(source_fd < 0)
    {
        return -1;
    }
    
    if(lseek(source_fd, 0, SEEK_SET) == (off_t)-1)
    {
        int saved_errno = errno;
        close(source_fd);
        errno = saved_errno;
        return -1;
    }
    
    int out_fd = open(shadow_path, O_RDWR | O_CREAT | O_TRUNC, 0777);
    if(out_fd < 0)
    {
        int saved_errno = errno;
        close(source_fd);
        errno = saved_errno;
        return -1;
    }
    
    int copy_result = fcopyfile(source_fd, out_fd, NULL, COPYFILE_DATA);
    int saved_errno = errno;
    
    close(source_fd);
    close(out_fd);
    
    if(copy_result != 0)
    {
        unlink(shadow_path);
        errno = saved_errno;
        return -1;
    }
    
    shadow_fd = open(shadow_path, O_RDONLY);
    if(shadow_fd < 0)
    {
        saved_errno = errno;
        unlink(shadow_path);
        errno = saved_errno;
        return -1;
    }
    
validate_shadow:
    if(!dyld_verify_shadow_cdhash_if_needed(shadow_fd))
    {
        int saved_errno = errno ? errno : EACCES;
        close(shadow_fd);
        unlink(shadow_path);
        errno = saved_errno;
        return -1;
    }
    
    return shadow_fd;
}

LIBKERN_DEFINE_PATCHABLE(int, dyld_get_cached_fd, (int original_fd,
                                                   off_t mapping_offset,
                                                   bool require_signature))
{
    struct stat st;
    
    if(fstat(original_fd, &st) != 0)
    {
        return -1;
    }
    if(!S_ISREG(st.st_mode))
    {
        return original_fd;
    }
    
    char original_path[PATH_MAX];
    if(!dyld_should_shadow_file(original_fd, original_path))
    {
        return original_fd;
    }
    
    dyld_fd_cache_entry_t *entry = dyld_fd_cache_find(st.st_dev, st.st_ino);
    if(entry == NULL)
    {
        char shadow_path[PATH_MAX];
        int shadow_fd = dyld_create_shadow_fd(original_fd, st.st_ino, shadow_path);
        if(shadow_fd < 0)
        {
            return -1;
        }
        
        entry = dyld_fd_cache_insert(st.st_dev,st.st_ino, shadow_fd, shadow_path);
        if(entry == NULL)
        {
            int saved_errno = ENFILE;
            close(shadow_fd);
            unlink(shadow_path);
            errno = saved_errno;
            return -1;
        }
    }
    
    if(require_signature)
    {
        LCMachO *machO = LCMapMachOFromFDRO(dup(entry->shadow_fd));
        if(machO == NULL)
        {
            errno = ENOEXEC;
            return -1;
        }
        
        bool success = LCCheckCodeSignature(machO);
        LCUnmapMachO(machO);
        if(!success)
        {
            errno = ENOEXEC;
            return -1;
        }
    }
    
    return entry->shadow_fd;
}

void * hook_mmap(void *addr,
                 size_t len,
                 int prot,
                 int flags,
                 int fd,
                 off_t offset)
{
    dyld_hook_log("[hook_mmap] (addr=%p, len=0x%zx, prot=0x%x, flags=0x%x, fd=%d, offset=0x%llx)\n", addr, len, prot, flags, fd, (unsigned long long)offset);
    if(len == 0)
    {
        errno = EINVAL;
        return MAP_FAILED;
    }
    if(len > SIZE_MAX - (VM_PAGE_SIZE - 1))
    {
        errno = ENOMEM;
        return MAP_FAILED;
    }
    
    int map_fd = fd;
    if(fd >= 0 && !(flags & MAP_ANON))
    {
        bool require_signature = (prot & PROT_EXEC) != 0;
        map_fd = dyld_get_cached_fd(fd, offset, require_signature);
        if(map_fd < 0)
        {
            return MAP_FAILED;
        }
    }
    
    return mmap(addr, len, prot, flags, map_fd, offset);
}

HWHookThreadContextRef HWHookDlopenThreadContext(void)
{
    if(!ksurface_user_patchcache_load())
    {
        return NULL;
    }
    
    static HWHookThreadContextRef context = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(patchcache[kDyldPtrMmap] == 0x0)
        {
            return;
        }
        
        HWHookRef mmapHook = HWHookCreateWithPointerToSymbol(kCFAllocatorDefault, (void*)patchcache[kDyldPtrMmap], hook_mmap);
        if(mmapHook == NULL)
        {
            return;
        }
        
        context = HWHookThreadContextCreate(kCFAllocatorDefault);
        if(context == NULL)
        {
            goto release_hooks;
        }
        
        if(!HWHookThreadContextAppendHook(context, mmapHook))
        {
            CFRelease(context);
        release_hooks:
            CFRelease(mmapHook);
            return;
        }
    });
    return context;
}

LIBKERN_PATCH(void*, dlopen, (const char *path, int mode),
{
    char newTmpPath[PATH_MAX];
    snprintf(newTmpPath, sizeof(newTmpPath), "%s/tmp", mmap_sandbox_map_exec_allowed_path);
    mkdir(newTmpPath, 0777);
    snprintf(newTmpPath, sizeof(newTmpPath), "%s/%d", newTmpPath, getpid());
    mkdir(newTmpPath, 0777);
    
    dyld_hook_log("[hook_dlopen] %s\n", path);
    
    open_hardlock = false;
    HWHookThreadContextRef context = HWHookDlopenThreadContext();
    HWHookThreadContextEnter(context);
    void *ret = dlopen__orig(path, mode);
    HWHookThreadContextExit(context);
    
    dyld_fd_cache_reset();
    rmdir(newTmpPath);
    return ret;
});

void *dlopen_cdhash_verified(const char *path,
                             int flags,
                             const char *cdhash,
                             dlopen_cdhash_verifier_failed_callback_t callback)
{
    cdhash_verified = false;
    cdhash_must_valid = true;
    cdhash_data_container_match = cdhash;
    cdhash_verifier_failed_callback = callback;
    void *ret = dlopen(path, flags);
    cdhash_verifier_failed_callback = NULL;
    cdhash_data_container_match = NULL;
    cdhash_must_valid = false;
    return ret;
}

__attribute__((constructor))
void LiveShimDlopenHookInit(void)
{
    LIBKERN_INSTALL_PATCH(dlopen);
    
    const char *home = getenv("HOME");
    if(home == NULL)
    {
        return;
    }
    
    char *home_copy = strndup(home, MAXPATHLEN);
    if(home_copy == NULL)
    {
        return;
    }
    
    mmap_sandbox_map_exec_allowed_path = home_copy;
}

const char *dyld_get_mmap_sandbox_map_exec_allowed_path(void)
{
    return mmap_sandbox_map_exec_allowed_path;
}
