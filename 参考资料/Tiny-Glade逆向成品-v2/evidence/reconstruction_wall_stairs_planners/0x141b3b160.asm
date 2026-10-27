0000000141b3b160  4883ec58                 sub      rsp, 0x58
0000000141b3b164  440f29442440             movaps   xmmword ptr [rsp + 0x40], xmm8
0000000141b3b16a  0f297c2430               movaps   xmmword ptr [rsp + 0x30], xmm7
0000000141b3b16f  0f29742420               movaps   xmmword ptr [rsp + 0x20], xmm6
0000000141b3b174  0f28f2                   movaps   xmm6, xmm2
0000000141b3b177  0f28f9                   movaps   xmm7, xmm1
0000000141b3b17a  440f28c0                 movaps   xmm8, xmm0
0000000141b3b17e  e8dd3c54fe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
0000000141b3b183  b920000000               mov      ecx, 0x20
0000000141b3b188  ba08000000               mov      edx, 8
0000000141b3b18d  e81e09b7fe               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
0000000141b3b192  4885c0                   test     rax, rax
0000000141b3b195  743b                     je       0x141b3b1d2
0000000141b3b197  48c70001000000           mov      qword ptr [rax], 1
0000000141b3b19e  48c7400801000000         mov      qword ptr [rax + 8], 1
0000000141b3b1a6  f3440f114010             movss    dword ptr [rax + 0x10], xmm8
0000000141b3b1ac  f30f117814               movss    dword ptr [rax + 0x14], xmm7
0000000141b3b1b1  f30f117018               movss    dword ptr [rax + 0x18], xmm6
0000000141b3b1b6  488d157b958501           lea      rdx, [rip + 0x185957b]
0000000141b3b1bd  0f28742420               movaps   xmm6, xmmword ptr [rsp + 0x20]
0000000141b3b1c2  0f287c2430               movaps   xmm7, xmmword ptr [rsp + 0x30]
0000000141b3b1c7  440f28442440             movaps   xmm8, xmmword ptr [rsp + 0x40]
0000000141b3b1cd  4883c458                 add      rsp, 0x58
0000000141b3b1d1  c3                       ret      
0000000141b3b1d2  b908000000               mov      ecx, 8
0000000141b3b1d7  ba20000000               mov      edx, 0x20
0000000141b3b1dc  e830cc2801               call     0x142dc7e11 ; alloc::alloc::handle_alloc_error | _RNvNtCs1f2BdUxKfgg_5alloc5alloc18handle_alloc_error
0000000141b3b1e1  cc                       int3     