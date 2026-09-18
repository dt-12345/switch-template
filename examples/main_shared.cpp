#include <cstdio>

extern "C" __attribute__((visibility("default"))) void Greet()
{
    printf("Hello, World!\n");
}