00000001409f9030  4157                     push     r15
00000001409f9032  4156                     push     r14
00000001409f9034  4155                     push     r13
00000001409f9036  4154                     push     r12
00000001409f9038  56                       push     rsi
00000001409f9039  57                       push     rdi
00000001409f903a  55                       push     rbp
00000001409f903b  53                       push     rbx
00000001409f903c  4881ec38010000           sub      rsp, 0x138
00000001409f9043  440f29942420010000       movaps   xmmword ptr [rsp + 0x120], xmm10
00000001409f904c  440f298c2410010000       movaps   xmmword ptr [rsp + 0x110], xmm9
00000001409f9055  440f29842400010000       movaps   xmmword ptr [rsp + 0x100], xmm8
00000001409f905e  0f29bc24f0000000         movaps   xmmword ptr [rsp + 0xf0], xmm7
00000001409f9066  0f29b424e0000000         movaps   xmmword ptr [rsp + 0xe0], xmm6
00000001409f906e  4889d7                   mov      rdi, rdx
00000001409f9071  4889ce                   mov      rsi, rcx
00000001409f9074  8b9c24b0010000           mov      ebx, dword ptr [rsp + 0x1b0]
00000001409f907b  f30f10b424a8010000       movss    xmm6, dword ptr [rsp + 0x1a8]
00000001409f9084  488b8424a0010000         mov      rax, qword ptr [rsp + 0x1a0]
00000001409f908c  4c894c2468               mov      qword ptr [rsp + 0x68], r9
00000001409f9091  4889442470               mov      qword ptr [rsp + 0x70], rax
00000001409f9096  4c8da2803d0000           lea      r12, [rdx + 0x3d80]
00000001409f909d  f3410f107808             movss    xmm7, dword ptr [r8 + 8]
00000001409f90a3  f2450f1000               movsd    xmm8, qword ptr [r8]
00000001409f90a8  f2450f10500c             movsd    xmm10, qword ptr [r8 + 0xc]
00000001409f90ae  f3450f104814             movss    xmm9, dword ptr [r8 + 0x14]
00000001409f90b4  41bf20000000             mov      r15d, 0x20
00000001409f90ba  31ed                     xor      ebp, ebp
00000001409f90bc  488d542468               lea      rdx, [rsp + 0x68]
00000001409f90c1  4c8d442478               lea      r8, [rsp + 0x78]
00000001409f90c6  4c8d15cbae6302           lea      r10, [rip + 0x263aecb]
00000001409f90cd  4c8d9c24a8000000         lea      r11, [rsp + 0xa8]
00000001409f90d5  4c8db42490000000         lea      r14, [rsp + 0x90]
00000001409f90dd  31c9                     xor      ecx, ecx
00000001409f90df  4889e8                   mov      rax, rbp
00000001409f90e2  66666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001409f90f0  4981ffb03c0000           cmp      r15, 0x3cb0
00000001409f90f7  0f8411010000             je       0x1409f920e
00000001409f90fd  4981c790030000           add      r15, 0x390
00000001409f9104  488d6801                 lea      rbp, [rax + 1]
00000001409f9108  0fa3c3                   bt       ebx, eax
00000001409f910b  4889e8                   mov      rax, rbp
00000001409f910e  73e0                     jae      0x1409f90f0
00000001409f9110  4889742460               mov      qword ptr [rsp + 0x60], rsi
00000001409f9115  4e8d0c3f                 lea      r9, [rdi + r15]
00000001409f9119  4981c170fcffff           add      r9, -0x390
00000001409f9120  48897c2478               mov      qword ptr [rsp + 0x78], rdi
00000001409f9125  4c898c2480000000         mov      qword ptr [rsp + 0x80], r9
00000001409f912d  4889942488000000         mov      qword ptr [rsp + 0x88], rdx
00000001409f9135  4889ce                   mov      rsi, rcx
00000001409f9138  4a8d943fa0fcffff         lea      rdx, [rdi + r15 - 0x360]
00000001409f9140  440f13842490000000       movlps   qword ptr [rsp + 0x90], xmm8
00000001409f9149  f30f11bc2498000000       movss    dword ptr [rsp + 0x98], xmm7
00000001409f9152  440f1394249c000000       movlps   qword ptr [rsp + 0x9c], xmm10
00000001409f915b  f3440f118c24a4000000     movss    dword ptr [rsp + 0xa4], xmm9
00000001409f9165  4c898424a8000000         mov      qword ptr [rsp + 0xa8], r8
00000001409f916d  4c899424b0000000         mov      qword ptr [rsp + 0xb0], r10
00000001409f9175  48c78424b800000000000000 mov      qword ptr [rsp + 0xb8], 0
00000001409f9181  c78424c800000000000000   mov      dword ptr [rsp + 0xc8], 0
00000001409f918c  c78424d400000000000000   mov      dword ptr [rsp + 0xd4], 0
00000001409f9197  4c895c2438               mov      qword ptr [rsp + 0x38], r11
00000001409f919c  f30f11742428             movss    dword ptr [rsp + 0x28], xmm6
00000001409f91a2  4d89f5                   mov      r13, r14
00000001409f91a5  4c89742420               mov      qword ptr [rsp + 0x20], r14
00000001409f91aa  c644243001               mov      byte ptr [rsp + 0x30], 1
00000001409f91af  488d4c2450               lea      rcx, [rsp + 0x50]
00000001409f91b4  4d89e6                   mov      r14, r12
00000001409f91b7  4d89e0                   mov      r8, r12
00000001409f91ba  4d89cc                   mov      r12, r9
00000001409f91bd  e86ef70001               call     0x141a08930 ; rapier3d::pipeline::query_pipeline::QueryPipeline::cast_ray | _ZN8rapier3d8pipeline14query_pipeline13QueryPipeline8cast_ray17h0a8fb7830201b62dE
00000001409f91c2  4889f1                   mov      rcx, rsi
00000001409f91c5  837c245001               cmp      dword ptr [rsp + 0x50], 1
00000001409f91ca  7519                     jne      0x1409f91e5
00000001409f91cc  8b442454                 mov      eax, dword ptr [rsp + 0x54]
00000001409f91d0  8944244c                 mov      dword ptr [rsp + 0x4c], eax
00000001409f91d4  8b442458                 mov      eax, dword ptr [rsp + 0x58]
00000001409f91d8  89442448                 mov      dword ptr [rsp + 0x48], eax
00000001409f91dc  f30f1074245c             movss    xmm6, dword ptr [rsp + 0x5c]
00000001409f91e2  4c89e1                   mov      rcx, r12
00000001409f91e5  4d89f4                   mov      r12, r14
00000001409f91e8  488d542468               lea      rdx, [rsp + 0x68]
00000001409f91ed  488b742460               mov      rsi, qword ptr [rsp + 0x60]
00000001409f91f2  4c8d442478               lea      r8, [rsp + 0x78]
00000001409f91f7  4c8d159aad6302           lea      r10, [rip + 0x263ad9a]
00000001409f91fe  4c8d9c24a8000000         lea      r11, [rsp + 0xa8]
00000001409f9206  4d89ee                   mov      r14, r13
00000001409f9209  e9d1feffff               jmp      0x1409f90df
00000001409f920e  4885c9                   test     rcx, rcx
00000001409f9211  0f8481000000             je       0x1409f9298
00000001409f9217  8b54244c                 mov      edx, dword ptr [rsp + 0x4c]
00000001409f921b  448b442448               mov      r8d, dword ptr [rsp + 0x48]
00000001409f9220  e8abb92d00               call     0x140cd4bd0 ; rapier3d::geometry::collider_set::ColliderSet::get_mut_internal | _ZN8rapier3d8geometry12collider_set11ColliderSet3get17h9bb726f4a42d0d6cE
00000001409f9225  4885c0                   test     rax, rax
00000001409f9228  0f84ac000000             je       0x1409f92da
00000001409f922e  488b00                   mov      rax, qword ptr [rax]
00000001409f9231  89c1                     mov      ecx, eax
00000001409f9233  48394f10                 cmp      qword ptr [rdi + 0x10], rcx
00000001409f9237  0f86a9000000             jbe      0x1409f92e6
00000001409f923d  488b5708                 mov      rdx, qword ptr [rdi + 8]
00000001409f9241  4885d2                   test     rdx, rdx
00000001409f9244  0f849c000000             je       0x1409f92e6
00000001409f924a  48c1e820                 shr      rax, 0x20
00000001409f924e  83c801                   or       eax, 1
00000001409f9251  488d0c89                 lea      rcx, [rcx + rcx*4]
00000001409f9255  3944ca20                 cmp      dword ptr [rdx + rcx*8 + 0x20], eax
00000001409f9259  0f8587000000             jne      0x1409f92e6
00000001409f925f  488d04ca                 lea      rax, [rdx + rcx*8]
00000001409f9263  f30f12c6                 movsldup xmm0, xmm6
00000001409f9267  410f59c2                 mulps    xmm0, xmm10
00000001409f926b  f3440f59ce               mulss    xmm9, xmm6
00000001409f9270  f3410f58f9               addss    xmm7, xmm9
00000001409f9275  488b4810                 mov      rcx, qword ptr [rax + 0x10]
00000001409f9279  48894e10                 mov      qword ptr [rsi + 0x10], rcx
00000001409f927d  0f1008                   movups   xmm1, xmmword ptr [rax]
00000001409f9280  0f110e                   movups   xmmword ptr [rsi], xmm1
00000001409f9283  440f58c0                 addps    xmm8, xmm0
00000001409f9287  440f134618               movlps   qword ptr [rsi + 0x18], xmm8
00000001409f928c  f30f117e20               movss    dword ptr [rsi + 0x20], xmm7
00000001409f9291  f30f117624               movss    dword ptr [rsi + 0x24], xmm6
00000001409f9296  eb03                     jmp      0x1409f929b
00000001409f9298  c60611                   mov      byte ptr [rsi], 0x11
00000001409f929b  0f28b424e0000000         movaps   xmm6, xmmword ptr [rsp + 0xe0]
00000001409f92a3  0f28bc24f0000000         movaps   xmm7, xmmword ptr [rsp + 0xf0]
00000001409f92ab  440f28842400010000       movaps   xmm8, xmmword ptr [rsp + 0x100]
00000001409f92b4  440f288c2410010000       movaps   xmm9, xmmword ptr [rsp + 0x110]
00000001409f92bd  440f28942420010000       movaps   xmm10, xmmword ptr [rsp + 0x120]
00000001409f92c6  4881c438010000           add      rsp, 0x138
00000001409f92cd  5b                       pop      rbx
00000001409f92ce  5d                       pop      rbp
00000001409f92cf  5f                       pop      rdi
00000001409f92d0  5e                       pop      rsi
00000001409f92d1  415c                     pop      r12
00000001409f92d3  415d                     pop      r13
00000001409f92d5  415e                     pop      r14
00000001409f92d7  415f                     pop      r15
00000001409f92d9  c3                       ret      
00000001409f92da  488d0dffa86302           lea      rcx, [rip + 0x263a8ff]
00000001409f92e1  e86aee3c02               call     0x142dc8150 ; core::option::unwrap_failed | _RNvNtCs8icZUrvfcq9_4core6option13unwrap_failed
00000001409f92e6  488d0d3bdb6702           lea      rcx, [rip + 0x267db3b] ; 'invalid SlotMap key used/home/h3/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/bevy_app-0'
00000001409f92ed  4c8d0504a96302           lea      r8, [rip + 0x263a904]
00000001409f92f4  ba18000000               mov      edx, 0x18
00000001409f92f9  e851d33c02               call     0x142dc664f ; std::panicking::begin_panic<ref$<str$> > | _RINvNtCs1aoCESei0z2_3std9panicking11begin_panicReEB4_
00000001409f92fe  cc                       int3     