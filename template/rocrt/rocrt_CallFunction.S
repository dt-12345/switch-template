#ifndef __clang__
    .global __init_array_start
    .hidden __init_array_start
    .global __init_array_end
    .hidden __init_array_end
    .global __fini_array_start
    .hidden __fini_array_start
    .global __fini_array_end
    .hidden __fini_array_end

    .global __CallInit
    .hidden __CallInit
    .global __CallFini
    .hidden __CallFini

__CallInit:
    .cfi_startproc
    ldr  x16, [x0]
    adrp x8, __init_array_start
    add  x8, x8, :lo12:__init_array_start
    cmp  x0, x8
    b.lo 1f
    adrp x8, __init_array_end
    add  x8, x8, :lo12:__init_array_end
    cmp  x0, x8
    b.hs 1f
    tst  x0, #0x7
    b.ne 1f
    br   x16
    1:  udf #0x8003
    .cfi_endproc

__CallFini:
    .cfi_startproc
    ldr  x16, [x0]
    adrp x8, __init_array_start
    add  x8, x8, :lo12:__init_array_start
    cmp  x0, x8
    b.lo 1f
    adrp x8, __init_array_end
    add  x8, x8, :lo12:__init_array_end
    cmp  x0, x8
    b.hs 1f
    tst  x0, #0x7
    b.ne 1f
    br   x16
    1:  udf #0x8003
    .cfi_endproc
#endif
