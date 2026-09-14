#include <cstddef>
#include <cstdint>

namespace nn
{
    using Result = uint32_t;

    // we'll just put this here so we don't need to bother with other headers
    // if this is ever properly decompiled, we can just replace it
    namespace diag { namespace detail {
        [[noreturn]] void AbortImpl(const char* msg, const char* object, const char* file, int line);
    } }

    #define NN_ABORT_UNLESS(RESULT)                             \
        do {                                                    \
            if ((RESULT) != 0)                                  \
                ::nn::diag::detail::AbortImpl("", "", "", 0);   \
        } while (0)

    namespace os
    {
        const size_t MemoryBlockUnitSize = 0x200000;

        struct MemoryInfo
        {
            uint64_t totalAvailableMemorySize;
            size_t totalUsedMemorySize;
            size_t totalMemoryHeapSize;
            size_t allocatedMemoryHeapSize;
            size_t programSize;
            size_t totalThreadStackSize;
            int threadCount;
        };

        void QueryMemoryInfo(MemoryInfo* info);

        Result SetMemoryHeapSize(size_t size);

        Result AllocateMemoryBlock(uintptr_t* address, size_t size);

        void SetMemoryAllocatorForThreadLocal(void* (*allocator)(size_t, size_t), void (*deallocator)(void*, size_t));
    }

    namespace init
    {
        namespace detail
        {
            void StartupDefaultForHorizon();

            void DefaultDeallocatorForThreadLocal(void* ptr, size_t size);

            void* DefaultAllocatorForThreadLocal(size_t size, size_t align);
        }

        void InitializeAllocator(void* address, size_t size, bool isCacheEnabled);
    }

    namespace util
    {
        template <typename T>
        T align_down(T x, T align)
        {
            return x / align * align;
        }
    }
}

extern "C"
{
    __attribute__((visibility("default"))) void nninitStartup();
    __attribute__((visibility("default"))) void nninitStartup()
    {
        nn::init::detail::StartupDefaultForHorizon();

        nn::os::MemoryInfo memInfo;
        nn::os::QueryMemoryInfo(&memInfo);

        size_t size = nn::util::align_down(memInfo.totalAvailableMemorySize - memInfo.totalUsedMemorySize, nn::os::MemoryBlockUnitSize);
        if (auto result = nn::os::SetMemoryHeapSize(size)) {
            size = nn::os::MemoryBlockUnitSize;
            NN_ABORT_UNLESS(nn::os::SetMemoryHeapSize(size));
        }

        uintptr_t p;
        NN_ABORT_UNLESS(nn::os::AllocateMemoryBlock(&p, size));

        nn::init::InitializeAllocator(reinterpret_cast<void*>(p), size, true);
        nn::os::SetMemoryAllocatorForThreadLocal(nn::init::detail::DefaultAllocatorForThreadLocal, nn::init::detail::DefaultDeallocatorForThreadLocal);
    }
}