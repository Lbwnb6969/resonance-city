000000014148a930  4157                     push     r15
000000014148a932  4156                     push     r14
000000014148a934  4154                     push     r12
000000014148a936  56                       push     rsi
000000014148a937  57                       push     rdi
000000014148a938  55                       push     rbp
000000014148a939  53                       push     rbx
000000014148a93a  4881ec00010000           sub      rsp, 0x100
000000014148a941  440f29ac24f0000000       movaps   xmmword ptr [rsp + 0xf0], xmm13
000000014148a94a  440f29a424e0000000       movaps   xmmword ptr [rsp + 0xe0], xmm12
000000014148a953  440f299c24d0000000       movaps   xmmword ptr [rsp + 0xd0], xmm11
000000014148a95c  440f299424c0000000       movaps   xmmword ptr [rsp + 0xc0], xmm10
000000014148a965  440f298c24b0000000       movaps   xmmword ptr [rsp + 0xb0], xmm9
000000014148a96e  440f298424a0000000       movaps   xmmword ptr [rsp + 0xa0], xmm8
000000014148a977  0f29bc2490000000         movaps   xmmword ptr [rsp + 0x90], xmm7
000000014148a97f  0f29b42480000000         movaps   xmmword ptr [rsp + 0x80], xmm6
000000014148a987  4c8ba42478010000         mov      r12, qword ptr [rsp + 0x178]
000000014148a98f  80bc247001000000         cmp      byte ptr [rsp + 0x170], 0
000000014148a997  0f848c000000             je       0x14148aa29
000000014148a99d  4889d7                   mov      rdi, rdx
000000014148a9a0  488b842460010000         mov      rax, qword ptr [rsp + 0x160]
000000014148a9a8  4885d2                   test     rdx, rdx
000000014148a9ab  0f95c2                   setne    dl
000000014148a9ae  bd02000000               mov      ebp, 2
000000014148a9b3  41be10000000             mov      r14d, 0x10
000000014148a9b9  84c2                     test     dl, al
000000014148a9bb  0f8455020000             je       0x14148ac16
000000014148a9c1  4c89c6                   mov      rsi, r8
000000014148a9c4  f3410f103424             movss    xmm6, dword ptr [r12]
000000014148a9ca  f3410f107c2408           movss    xmm7, dword ptr [r12 + 8]
000000014148a9d1  0f28c6                   movaps   xmm0, xmm6
000000014148a9d4  f30f58c7                 addss    xmm0, xmm7
000000014148a9d8  f30f590570c59a01         mulss    xmm0, dword ptr [rip + 0x19ac570]
000000014148a9e0  f3410f105118             movss    xmm2, dword ptr [r9 + 0x18]
000000014148a9e6  4180791c00               cmp      byte ptr [r9 + 0x1c], 0
000000014148a9eb  7451                     je       0x14148aa3e
000000014148a9ed  4989cf                   mov      r15, rcx
000000014148a9f0  0f28ca                   movaps   xmm1, xmm2
000000014148a9f3  4c89cb                   mov      rbx, r9
000000014148a9f6  440f28c2                 movaps   xmm8, xmm2
000000014148a9fa  e871809a01               call     0x142e32a70 ; fmodf
000000014148a9ff  4989d9                   mov      r9, rbx
000000014148aa02  440f5405d6cd9a01         andps    xmm8, xmmword ptr [rip + 0x19acdd6]
000000014148aa0a  f3440f58c0               addss    xmm8, xmm0
000000014148aa0f  0f57c9                   xorps    xmm1, xmm1
000000014148aa12  0f28d0                   movaps   xmm2, xmm0
000000014148aa15  f30fc2d101               cmpltss  xmm2, xmm1
000000014148aa1a  0f28ca                   movaps   xmm1, xmm2
000000014148aa1d  0f55c8                   andnps   xmm1, xmm0
000000014148aa20  410f54d0                 andps    xmm2, xmm8
000000014148aa24  0f56d1                   orps     xmm2, xmm1
000000014148aa27  eb2c                     jmp      0x14148aa55
000000014148aa29  410f100424               movups   xmm0, xmmword ptr [r12]
000000014148aa2e  0f1101                   movups   xmmword ptr [rcx], xmm0
000000014148aa31  31ed                     xor      ebp, ebp
000000014148aa33  41be10000000             mov      r14d, 0x10
000000014148aa39  e9d8010000               jmp      0x14148ac16
000000014148aa3e  0f57c9                   xorps    xmm1, xmm1
000000014148aa41  0f2ed1                   ucomiss  xmm2, xmm1
000000014148aa44  0f822b020000             jb       0x14148ac75
000000014148aa4a  4989cf                   mov      r15, rcx
000000014148aa4d  f30f5fc8                 maxss    xmm1, xmm0
000000014148aa51  f30f5dd1                 minss    xmm2, xmm1
000000014148aa55  488b9c2468010000         mov      rbx, qword ptr [rsp + 0x168]
000000014148aa5d  488d4c2440               lea      rcx, [rsp + 0x40]
000000014148aa62  4c89ca                   mov      rdx, r9
000000014148aa65  e82686ffff               call     0x141483090 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSampler::sample_pair_at | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards11WallSampler14sample_pair_at17h3845de2e9feb8b12E.llvm.1951817906911489466
000000014148aa6a  837c244001               cmp      dword ptr [rsp + 0x40], 1
000000014148aa6f  7534                     jne      0x14148aaa5
000000014148aa71  f30f1044246c             movss    xmm0, dword ptr [rsp + 0x6c]
000000014148aa77  f30f100da9c49a01         movss    xmm1, dword ptr [rip + 0x19ac4a9]
000000014148aa7f  f30f5cc8                 subss    xmm1, xmm0
000000014148aa83  f20f10542444             movsd    xmm2, qword ptr [rsp + 0x44]
000000014148aa89  f20f105c2458             movsd    xmm3, qword ptr [rsp + 0x58]
000000014148aa8f  f30f12c9                 movsldup xmm1, xmm1
000000014148aa93  0f59ca                   mulps    xmm1, xmm2
000000014148aa96  f3440f12d8               movsldup xmm11, xmm0
000000014148aa9b  440f59db                 mulps    xmm11, xmm3
000000014148aa9f  440f58d9                 addps    xmm11, xmm1
000000014148aaa3  eb04                     jmp      0x14148aaa9
000000014148aaa5  450f57db                 xorps    xmm11, xmm11
000000014148aaa9  f3450f104c2404           movss    xmm9, dword ptr [r12 + 4]
000000014148aab0  f3450f16eb               movshdup xmm13, xmm11
000000014148aab5  f3440f114c2430           movss    dword ptr [rsp + 0x30], xmm9
000000014148aabc  f3440f116c2428           movss    dword ptr [rsp + 0x28], xmm13
000000014148aac3  f3440f115c2420           movss    dword ptr [rsp + 0x20], xmm11
000000014148aaca  488d4c2440               lea      rcx, [rsp + 0x40]
000000014148aacf  4889fa                   mov      rdx, rdi
000000014148aad2  4989f0                   mov      r8, rsi
000000014148aad5  4989d9                   mov      r9, rbx
000000014148aad8  e813caffff               call     0x1414874f0 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::gable_roof_side_x_span_at_y
000000014148aadd  807c244000               cmp      byte ptr [rsp + 0x40], 0
000000014148aae2  0f842b010000             je       0x14148ac13
000000014148aae8  f2440f10442444           movsd    xmm8, qword ptr [rsp + 0x44]
000000014148aaef  f3440f10642448           movss    xmm12, dword ptr [rsp + 0x48]
000000014148aaf6  f3450f1054240c           movss    xmm10, dword ptr [r12 + 0xc]
000000014148aafd  f3440f11542430           movss    dword ptr [rsp + 0x30], xmm10
000000014148ab04  f3440f116c2428           movss    dword ptr [rsp + 0x28], xmm13
000000014148ab0b  f3440f115c2420           movss    dword ptr [rsp + 0x20], xmm11
000000014148ab12  488d4c2440               lea      rcx, [rsp + 0x40]
000000014148ab17  4889fa                   mov      rdx, rdi
000000014148ab1a  4989f0                   mov      r8, rsi
000000014148ab1d  4989d9                   mov      r9, rbx
000000014148ab20  e8cbc9ffff               call     0x1414874f0 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::gable_roof_side_x_span_at_y
000000014148ab25  807c244000               cmp      byte ptr [rsp + 0x40], 0
000000014148ab2a  0f84e3000000             je       0x14148ac13
000000014148ab30  f2440f105c2444           movsd    xmm11, qword ptr [rsp + 0x44]
000000014148ab37  f30f10442448             movss    xmm0, dword ptr [rsp + 0x48]
000000014148ab3d  410f28d4                 movaps   xmm2, xmm12
000000014148ab41  f3410f5cd0               subss    xmm2, xmm8
000000014148ab46  0f28c8                   movaps   xmm1, xmm0
000000014148ab49  f3410f5ccb               subss    xmm1, xmm11
000000014148ab4e  0f2ed1                   ucomiss  xmm2, xmm1
000000014148ab51  f30fc2ca06               cmpnless xmm1, xmm2
000000014148ab56  0f28d1                   movaps   xmm2, xmm1
000000014148ab59  410f54d3                 andps    xmm2, xmm11
000000014148ab5d  410f55c8                 andnps   xmm1, xmm8
000000014148ab61  0f56ca                   orps     xmm1, xmm2
000000014148ab64  7204                     jb       0x14148ab6a
000000014148ab66  410f28c4                 movaps   xmm0, xmm12
000000014148ab6a  0f28d1                   movaps   xmm2, xmm1
000000014148ab6d  f30f5fd6                 maxss    xmm2, xmm6
000000014148ab71  f30fc2f603               cmpunordss xmm6, xmm6
000000014148ab76  0f28de                   movaps   xmm3, xmm6
000000014148ab79  0f54d9                   andps    xmm3, xmm1
000000014148ab7c  0f55f2                   andnps   xmm6, xmm2
000000014148ab7f  0f56f3                   orps     xmm6, xmm3
000000014148ab82  0f28cf                   movaps   xmm1, xmm7
000000014148ab85  f30fc2cf03               cmpunordss xmm1, xmm7
000000014148ab8a  0f28d1                   movaps   xmm2, xmm1
000000014148ab8d  0f54d0                   andps    xmm2, xmm0
000000014148ab90  f30f5dc7                 minss    xmm0, xmm7
000000014148ab94  0f55c8                   andnps   xmm1, xmm0
000000014148ab97  0f56ca                   orps     xmm1, xmm2
000000014148ab9a  0f2ef1                   ucomiss  xmm6, xmm1
000000014148ab9d  7374                     jae      0x14148ac13
000000014148ab9f  f30f11742470             movss    dword ptr [rsp + 0x70], xmm6
000000014148aba5  f3440f114c2474           movss    dword ptr [rsp + 0x74], xmm9
000000014148abac  f30f114c2478             movss    dword ptr [rsp + 0x78], xmm1
000000014148abb2  f3440f1154247c           movss    dword ptr [rsp + 0x7c], xmm10
000000014148abb9  488d4c2470               lea      rcx, [rsp + 0x70]
000000014148abbe  e84d4096ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
000000014148abc3  0f57c9                   xorps    xmm1, xmm1
000000014148abc6  0f2ec8                   ucomiss  xmm1, xmm0
000000014148abc9  4c89f9                   mov      rcx, r15
000000014148abcc  7348                     jae      0x14148ac16
000000014148abce  450f14c3                 unpcklps xmm8, xmm11
000000014148abd2  0fc6f600                 shufps   xmm6, xmm6, 0
000000014148abd6  440f5cc6                 subps    xmm8, xmm6
000000014148abda  0f104c2470               movups   xmm1, xmmword ptr [rsp + 0x70]
000000014148abdf  0f1109                   movups   xmmword ptr [rcx], xmm1
000000014148abe2  c7411001000000           mov      dword ptr [rcx + 0x10], 1
000000014148abe9  0fc6c000                 shufps   xmm0, xmm0, 0
000000014148abed  440f5ec0                 divps    xmm8, xmm0
000000014148abf1  0f57c0                   xorps    xmm0, xmm0
000000014148abf4  410f5fc0                 maxps    xmm0, xmm8
000000014148abf8  0f280d411a9b01           movaps   xmm1, xmmword ptr [rip + 0x19b1a41]
000000014148abff  0f5dc8                   minps    xmm1, xmm0
000000014148ac02  0f114914                 movups   xmmword ptr [rcx + 0x14], xmm1
000000014148ac06  bd06000000               mov      ebp, 6
000000014148ac0b  41be24000000             mov      r14d, 0x24
000000014148ac11  eb03                     jmp      0x14148ac16
000000014148ac13  4c89f9                   mov      rcx, r15
000000014148ac16  42892c31                 mov      dword ptr [rcx + r14], ebp
000000014148ac1a  4889c8                   mov      rax, rcx
000000014148ac1d  0f28b42480000000         movaps   xmm6, xmmword ptr [rsp + 0x80]
000000014148ac25  0f28bc2490000000         movaps   xmm7, xmmword ptr [rsp + 0x90]
000000014148ac2d  440f288424a0000000       movaps   xmm8, xmmword ptr [rsp + 0xa0]
000000014148ac36  440f288c24b0000000       movaps   xmm9, xmmword ptr [rsp + 0xb0]
000000014148ac3f  440f289424c0000000       movaps   xmm10, xmmword ptr [rsp + 0xc0]
000000014148ac48  440f289c24d0000000       movaps   xmm11, xmmword ptr [rsp + 0xd0]
000000014148ac51  440f28a424e0000000       movaps   xmm12, xmmword ptr [rsp + 0xe0]
000000014148ac5a  440f28ac24f0000000       movaps   xmm13, xmmword ptr [rsp + 0xf0]
000000014148ac63  4881c400010000           add      rsp, 0x100
000000014148ac6a  5b                       pop      rbx
000000014148ac6b  5d                       pop      rbp
000000014148ac6c  5f                       pop      rdi
000000014148ac6d  5e                       pop      rsi
000000014148ac6e  415c                     pop      r12
000000014148ac70  415e                     pop      r14
000000014148ac72  415f                     pop      r15
000000014148ac74  c3                       ret      
000000014148ac75  c744243800000000         mov      dword ptr [rsp + 0x38], 0
000000014148ac7d  f30f1154243c             movss    dword ptr [rsp + 0x3c], xmm2
000000014148ac83  488d442438               lea      rax, [rsp + 0x38]
000000014148ac88  4889442440               mov      qword ptr [rsp + 0x40], rax
000000014148ac8d  488d053c59aeff           lea      rax, [rip - 0x51a6c4]
000000014148ac94  4889442448               mov      qword ptr [rsp + 0x48], rax
000000014148ac99  488d4c243c               lea      rcx, [rsp + 0x3c]
000000014148ac9e  48894c2450               mov      qword ptr [rsp + 0x50], rcx
000000014148aca3  4889442458               mov      qword ptr [rsp + 0x58], rax
000000014148aca8  488d0d5123e801           lea      rcx, [rip + 0x1e82351]
000000014148acaf  4c8d05ea23e801           lea      r8, [rip + 0x1e823ea]
000000014148acb6  488d542440               lea      rdx, [rsp + 0x40]
000000014148acbb  e810d79301               call     0x142dc83d0 ; core::panicking::panic_fmt | _RNvNtCs8icZUrvfcq9_4core9panicking9panic_fmt
000000014148acc0  cc                       int3     