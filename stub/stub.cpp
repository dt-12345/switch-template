extern "C"
{
    __attribute__((visibility("default")))
    int __nnmusl_init_dso(unsigned char *EX_start, unsigned char *EX_end,
        unsigned char *tdata_start, unsigned char *tdata_end,
        unsigned char *tdata_align_abs, unsigned char *tdata_align_rel,
        unsigned char *tbss_start, unsigned char *tbss_end,
        unsigned char *tbss_align_abs, unsigned char *tbss_align_rel,
        unsigned char *got_plt_start, unsigned char *got_plt_end,
        unsigned char *rela_dyn_start, unsigned char *rela_dyn_end,
        unsigned char *rel_dyn_start, unsigned char *rel_dyn_end,
        unsigned char *rela_plt_start, unsigned char *rela_plt_end,
        unsigned char *rel_plt_start, unsigned char *rel_plt_end,
        unsigned char *DYNAMIC);
    
    __attribute__((visibility("default"), weak))
    int __nnmusl_init_dso(unsigned char */* EX_start */, unsigned char */* EX_end */,
        unsigned char */* tdata_start */, unsigned char */* tdata_end */,
        unsigned char */* tdata_align_abs */, unsigned char */* tdata_align_rel */,
        unsigned char */* tbss_start */, unsigned char */* tbss_end */,
        unsigned char */* tbss_align_abs */, unsigned char */* tbss_align_rel */,
        unsigned char */* got_plt_start */, unsigned char */* got_plt_end */,
        unsigned char */* rela_dyn_start */, unsigned char */* rela_dyn_end */,
        unsigned char */* rel_dyn_start */, unsigned char */* rel_dyn_end */,
        unsigned char */* rela_plt_start */, unsigned char */* rela_plt_end */,
        unsigned char */* rel_plt_start */, unsigned char */* rel_plt_end */,
        unsigned char */* DYNAMIC */)
    {
        return 2;
    }

    __attribute__((visibility("default")))
    void __nnmusl_fini_dso(unsigned char *EX_start, unsigned char *EX_end,
                            unsigned char *tdata_start, unsigned char *tdata_end,
                            unsigned char *tbss_start, unsigned char *tbss_end);
    
    __attribute__((visibility("default"), weak))
    void __nnmusl_fini_dso(unsigned char *EX_start, unsigned char *EX_end,
                            unsigned char *tdata_start, unsigned char *tdata_end,
                            unsigned char *tbss_start, unsigned char *tbss_end) {}
}

namespace nn { namespace ro {
    __attribute__((visibility("default")))
    void ProtectRelro(const void* relro, const void* relroEnd, const void* fullRelroEnd, const void* pModule, const void* pVersion) noexcept;

    __attribute__((visibility("default"), weak))
    void ProtectRelro(const void* /* relro */, const void* /* relroEnd */, const void* /* fullRelroEnd */, const void* /* pModule */, const void* /* pVersion */) noexcept {}
}}