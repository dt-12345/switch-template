#include <cstddef>
#include <cstdint>
#include <memory>
#include <new>
#if __cplusplus < 202302
#include <type_traits>
#endif

namespace nn
{
    namespace util
    {
        template <typename T, size_t Size = sizeof(T), size_t Alignment = alignof(T)>
        struct TypedStorage
        {
#if __cplusplus < 202302
            std::aligned_storage_t<Size, Alignment> storage;
#else
            alignas(Alignment) std::byte storage[Size];
#endif
        };

        template <typename T>
        [[gnu::always_inline]] T& Get(TypedStorage<T>& storage)
        {
            return *std::launder(reinterpret_cast<T*>(std::addressof(storage)));
        }

        template <typename T>
        [[gnu::always_inline]] T* GetPointer(TypedStorage<T>& storage)
        {
            return std::launder(reinterpret_cast<T*>(std::addressof(storage)));
        }

        template <typename T, typename... Ts>
        [[gnu::always_inline]] void ConstructAt(TypedStorage<T>& storage, Ts&&... args)
        {
            std::construct_at<T>(GetPointer(storage), std::forward<Ts>(args)...);
        }
    }

    namespace os
    {
        struct TlsSlot
        {
            uint32_t _innerValue;
        };
    }

    namespace nlibsdk { namespace heap {
        class CentralHeap;
    } }

    namespace mem
    {
        namespace detail
        {
            using InternalCentralHeapStorage = util::TypedStorage<nlibsdk::heap::CentralHeap, 0x30, 0x8>;
        }

        class StandardAllocator
        {
        public:
            StandardAllocator();

            void Initialize(void* addr, size_t size, bool isCacheEnable);
            
            void* Allocate(size_t size, size_t align);
            void* Allocate(size_t size);
            
            void Free(void* ptr);

            void* Reallocate(void* ptr, size_t newSize);

            size_t GetSizeOf(const void* ptr) const;

        private:
            bool m_Initialized;
            bool m_EnableThreadCache;
            uintptr_t m_CentralAllocatorAddr;
            os::TlsSlot m_TlsSlot;
            detail::InternalCentralHeapStorage m_CentralHeap;
        };
    }
}

namespace
{
    nn::util::TypedStorage<nn::mem::StandardAllocator> g_MallocAllocator;
    void* g_MallocRegionAddress;
    size_t g_MallocRegionSize;
}

namespace nn
{
    namespace init
    {
        void InitializeAllocator(void* address, size_t size, bool isCacheEnabled)
        {
            util::ConstructAt(g_MallocAllocator);
            util::Get(g_MallocAllocator).Initialize(address, size, isCacheEnabled);
            g_MallocRegionAddress = address;
            g_MallocRegionSize = size;
        }
        
        namespace detail
        {
            void* DefaultAllocatorForThreadLocal(size_t size, size_t align)
            {
                if (g_MallocRegionSize == 0)
                    return nullptr;

                return util::Get(g_MallocAllocator).Allocate(size, align);
            }

            void DefaultDeallocatorForThreadLocal(void* ptr, size_t /* size */)
            {
                util::Get(g_MallocAllocator).Free(ptr);
            }
        }
    }
}

extern "C"
{
    __attribute__((visibility("default"))) void* malloc(size_t size);
    __attribute__((visibility("default"))) void* malloc(size_t size)
    {
        if (g_MallocRegionSize == 0)
            return nullptr;

        void* p = nn::util::Get(g_MallocAllocator).Allocate(size);
        if (p != nullptr) {
            return p;
        }

        *__errno_location() = ENOMEM;
        return nullptr;
    }

    __attribute__((visibility("default"))) void free(void* ptr);
    __attribute__((visibility("default"))) void free(void* ptr)
    {
        if (ptr != nullptr)
            nn::util::Get(g_MallocAllocator).Free(ptr);
    }

    __attribute__((visibility("default"))) void* calloc(size_t num, size_t size);
    __attribute__((visibility("default"))) void* calloc(size_t num, size_t size)
    {
        if (g_MallocRegionSize != 0)
        {
            size_t sum = size * num;
            void* p = nn::util::Get(g_MallocAllocator).Allocate(sum);
            if (p != nullptr) {
                memset(p, 0, sum);
                return p;
            }

            *__errno_location() = ENOMEM;
            // we do this twice?
        }

        *__errno_location() = ENOMEM;
        return nullptr;
    }

    __attribute__((visibility("default"))) void* realloc(void* ptr, size_t size);
    __attribute__((visibility("default"))) void* realloc(void* p, size_t newSize)
    {
        if (g_MallocRegionSize == 0)
            return nullptr;

        void* r = nn::util::Get(g_MallocAllocator).Reallocate(p, newSize);
        if (r != nullptr) {
            return r;
        }

        *__errno_location() = ENOMEM;
        return nullptr;
    }

    __attribute__((visibility("default"))) void* aligned_alloc(size_t alignment, size_t size);
    __attribute__((visibility("default"))) void* aligned_alloc(size_t alignment, size_t size)
    {
        if (g_MallocRegionSize == 0)
            return nullptr;

        void* p = nn::util::Get(g_MallocAllocator).Allocate(alignment, size);
        if (p != nullptr) {
            return p;
        }

        *__errno_location() = ENOMEM;
        return nullptr;
    }

    __attribute__((visibility("default"))) size_t malloc_usable_size(void* p);
    __attribute__((visibility("default"))) size_t malloc_usable_size(void* p)
    {
        if (p == nullptr)
            return 0;
        return nn::util::Get(g_MallocAllocator).GetSizeOf(p);
    }
}