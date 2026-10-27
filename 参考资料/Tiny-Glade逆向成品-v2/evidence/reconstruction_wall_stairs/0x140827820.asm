0000000140827820  4157                     push     r15
0000000140827822  4156                     push     r14
0000000140827824  56                       push     rsi
0000000140827825  57                       push     rdi
0000000140827826  53                       push     rbx
0000000140827827  4883ec60                 sub      rsp, 0x60
000000014082782b  4c89cb                   mov      rbx, r9
000000014082782e  4d89c7                   mov      r15, r8
0000000140827831  4889d7                   mov      rdi, rdx
0000000140827834  4889ce                   mov      rsi, rcx
0000000140827837  4c8bb424b0000000         mov      r14, qword ptr [rsp + 0xb0]
000000014082783f  f30f1002                 movss    xmm0, dword ptr [rdx]
0000000140827843  f30f104a08               movss    xmm1, dword ptr [rdx + 8]
0000000140827848  f30f1144244c             movss    dword ptr [rsp + 0x4c], xmm0
000000014082784e  f30f114c2450             movss    dword ptr [rsp + 0x50], xmm1
0000000140827854  f30f105204               movss    xmm2, dword ptr [rdx + 4]
0000000140827859  f30f5815cf247e02         addss    xmm2, dword ptr [rip + 0x27e24cf]
0000000140827861  488d4c2454               lea      rcx, [rsp + 0x54]
0000000140827866  488d54244c               lea      rdx, [rsp + 0x4c]
000000014082786b  e8d0cc5c00               call     0x140df4540 ; utils::swizzlers::impl$1::xvy | _ZN71_$LT$glam..f32..vec2..Vec2$u20$as$u20$utils..swizzlers..SwizzlerXVY$GT$3xvy17hcb9aa753d52e64e7E
0000000140827870  f30f104c2454             movss    xmm1, dword ptr [rsp + 0x54]
0000000140827876  f30f1054245c             movss    xmm2, dword ptr [rsp + 0x5c]
000000014082787c  4c89f9                   mov      rcx, r15
000000014082787f  e88c29bd00               call     0x1413fa210 ; _ZN5utils5curve21Curve$LT$T$C$CSem$GT$25get_approx_coord_from_pos17h2785d520b6be01b5E | _ZN5utils5curve21Curve$LT$T$C$CSem$GT$25get_approx_coord_from_pos17he32081444c961eeeE
0000000140827884  89c1                     mov      ecx, eax
0000000140827886  4939ce                   cmp      r14, rcx
0000000140827889  0f861f010000             jbe      0x1408279ae
000000014082788f  488d4101                 lea      rax, [rcx + 1]
0000000140827893  4c39f0                   cmp      rax, r14
0000000140827896  0f8321010000             jae      0x1408279bd
000000014082789c  488b9424c0000000         mov      rdx, qword ptr [rsp + 0xc0]
00000001408278a4  4839ca                   cmp      rdx, rcx
00000001408278a7  0f8622010000             jbe      0x1408279cf
00000001408278ad  4839d0                   cmp      rax, rdx
00000001408278b0  0f8325010000             jae      0x1408279db
00000001408278b6  4c8b8424e0000000         mov      r8, qword ptr [rsp + 0xe0]
00000001408278be  488b9424d8000000         mov      rdx, qword ptr [rsp + 0xd8]
00000001408278c6  f30f108c24d0000000       movss    xmm1, dword ptr [rsp + 0xd0]
00000001408278cf  8b8424c8000000           mov      eax, dword ptr [rsp + 0xc8]
00000001408278d6  4c8b8c24b8000000         mov      r9, qword ptr [rsp + 0xb8]
00000001408278de  f30f101c8b               movss    xmm3, dword ptr [rbx + rcx*4]
00000001408278e3  f30f10548b04             movss    xmm2, dword ptr [rbx + rcx*4 + 4]
00000001408278e9  f30f5cd3                 subss    xmm2, xmm3
00000001408278ed  f30f59d0                 mulss    xmm2, xmm0
00000001408278f1  f30f58d3                 addss    xmm2, xmm3
00000001408278f5  f2410f1024c9             movsd    xmm4, qword ptr [r9 + rcx*8]
00000001408278fb  f2410f106cc908           movsd    xmm5, qword ptr [r9 + rcx*8 + 8]
0000000140827902  0f5cec                   subps    xmm5, xmm4
0000000140827905  f30f12d8                 movsldup xmm3, xmm0
0000000140827909  0f59dd                   mulps    xmm3, xmm5
000000014082790c  0f58dc                   addps    xmm3, xmm4
000000014082790f  0f28c3                   movaps   xmm0, xmm3
0000000140827912  0f59c3                   mulps    xmm0, xmm3
0000000140827915  f30f16e0                 movshdup xmm4, xmm0
0000000140827919  f30f58e0                 addss    xmm4, xmm0
000000014082791d  f30f51e4                 sqrtss   xmm4, xmm4
0000000140827921  f30f1005fff56002         movss    xmm0, dword ptr [rip + 0x260f5ff]
0000000140827929  f30f5ec4                 divss    xmm0, xmm4
000000014082792d  660f7ec1                 movd     ecx, xmm0
0000000140827931  85c9                     test     ecx, ecx
0000000140827933  410f99c1                 setns    r9b
0000000140827937  4189ca                   mov      r10d, ecx
000000014082793a  4181e2ffffff7f           and      r10d, 0x7fffffff
0000000140827941  4181c2000080ff           add      r10d, 0xff800000
0000000140827948  4181fa0000007f           cmp      r10d, 0x7f000000
000000014082794f  410f92c2                 setb     r10b
0000000140827953  4520ca                   and      r10b, r9b
0000000140827956  ffc9                     dec      ecx
0000000140827958  81f9ffff7f00             cmp      ecx, 0x7fffff
000000014082795e  0f92c1                   setb     cl
0000000140827961  4408d1                   or       cl, r10b
0000000140827964  7508                     jne      0x14082796e
0000000140827966  0f57e4                   xorps    xmm4, xmm4
0000000140827969  0f57db                   xorps    xmm3, xmm3
000000014082796c  eb0c                     jmp      0x14082797a
000000014082796e  f30f16e3                 movshdup xmm4, xmm3
0000000140827972  f30f59d8                 mulss    xmm3, xmm0
0000000140827976  f30f59e0                 mulss    xmm4, xmm0
000000014082797a  4c89442440               mov      qword ptr [rsp + 0x40], r8
000000014082797f  4889542438               mov      qword ptr [rsp + 0x38], rdx
0000000140827984  f30f114c2430             movss    dword ptr [rsp + 0x30], xmm1
000000014082798a  89442428                 mov      dword ptr [rsp + 0x28], eax
000000014082798e  f30f11642420             movss    dword ptr [rsp + 0x20], xmm4
0000000140827994  4889f1                   mov      rcx, rsi
0000000140827997  4889fa                   mov      rdx, rdi
000000014082799a  e851000000               call     0x1408279f0 ; system_wall_constructor::construct_playermade_stairs::wooden_supports::support_station_from_sample | _ZN23system_wall_constructor27construct_playermade_stairs15wooden_supports27support_station_from_sample17h71c5c7a7f654dee7E.llvm.15792818820247213999
000000014082799f  4889f0                   mov      rax, rsi
00000001408279a2  4883c460                 add      rsp, 0x60
00000001408279a6  5b                       pop      rbx
00000001408279a7  5f                       pop      rdi
00000001408279a8  5e                       pop      rsi
00000001408279a9  415e                     pop      r14
00000001408279ab  415f                     pop      r15
00000001408279ad  c3                       ret      
00000001408279ae  4c8d0543257e02           lea      r8, [rip + 0x27e2543]
00000001408279b5  4c89f2                   mov      rdx, r14
00000001408279b8  e835085a02               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
00000001408279bd  4c8d0534257e02           lea      r8, [rip + 0x27e2534]
00000001408279c4  4889c1                   mov      rcx, rax
00000001408279c7  4c89f2                   mov      rdx, r14
00000001408279ca  e823085a02               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
00000001408279cf  4c8d053a257e02           lea      r8, [rip + 0x27e253a]
00000001408279d6  e817085a02               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
00000001408279db  4c8d052e257e02           lea      r8, [rip + 0x27e252e]
00000001408279e2  4889c1                   mov      rcx, rax
00000001408279e5  e808085a02               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
00000001408279ea  cc                       int3     