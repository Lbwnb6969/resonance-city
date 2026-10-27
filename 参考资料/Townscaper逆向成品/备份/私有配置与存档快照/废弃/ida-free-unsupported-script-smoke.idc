#include <idc.idc>
static main() {
    auto_wait();
    msg("TOWNSCAPER_IDA_FREE_SMOKE_OK version=%s input=%s\n", get_kernel_version(), get_input_file_path());
    qexit(0);
}
