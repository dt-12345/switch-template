#include <cstddef>
#include <cstring>

namespace nn { namespace diag { namespace detail {
    void PrintDebugString(const char* s, size_t size);
} } }

static void Print(const char* s)
{
    const size_t len = std::strlen(s);
    nn::diag::detail::PrintDebugString(s, len);
}

__attribute__((visibility("default"))) extern "C" void Greet()
{
    Print("Hello, World!\n");
}