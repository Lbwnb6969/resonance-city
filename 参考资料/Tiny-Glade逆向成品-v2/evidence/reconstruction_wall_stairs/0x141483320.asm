0000000141483320  56                       push     rsi
0000000141483321  57                       push     rdi
0000000141483322  53                       push     rbx
0000000141483323  4881eca0000000           sub      rsp, 0xa0
000000014148332a  440f298c2490000000       movaps   xmmword ptr [rsp + 0x90], xmm9
0000000141483333  440f29842480000000       movaps   xmmword ptr [rsp + 0x80], xmm8
000000014148333c  0f297c2470               movaps   xmmword ptr [rsp + 0x70], xmm7
0000000141483341  0f29742460               movaps   xmmword ptr [rsp + 0x60], xmm6
0000000141483346  0f28fb                   movaps   xmm7, xmm3
0000000141483349  4889d7                   mov      rdi, rdx
000000014148334c  4889ce                   mov      rsi, rcx
000000014148334f  0fb65a1c                 movzx    ebx, byte ptr [rdx + 0x1c]
0000000141483353  f30f107218               movss    xmm6, dword ptr [rdx + 0x18]
0000000141483358  84db                     test     bl, bl
000000014148335a  744c                     je       0x1414833a8
000000014148335c  0f28c2                   movaps   xmm0, xmm2
000000014148335f  0f28ce                   movaps   xmm1, xmm6
0000000141483362  e809f79a01               call     0x142e32a70 ; fmodf
0000000141483367  440f28c0                 movaps   xmm8, xmm0
000000014148336b  0f28c7                   movaps   xmm0, xmm7
000000014148336e  0f28ce                   movaps   xmm1, xmm6
0000000141483371  e8faf69a01               call     0x142e32a70 ; fmodf
0000000141483376  410f14c0                 unpcklps xmm0, xmm8
000000014148337a  0f57d2                   xorps    xmm2, xmm2
000000014148337d  0f28c8                   movaps   xmm1, xmm0
0000000141483380  0fc2ca01                 cmpltps  xmm1, xmm2
0000000141483384  f30f12d6                 movsldup xmm2, xmm6
0000000141483388  0f541551449b01           andps    xmm2, xmmword ptr [rip + 0x19b4451]
000000014148338f  0f58d0                   addps    xmm2, xmm0
0000000141483392  0f54d1                   andps    xmm2, xmm1
0000000141483395  0f55c8                   andnps   xmm1, xmm0
0000000141483398  0f56ca                   orps     xmm1, xmm2
000000014148339b  f30f16f9                 movshdup xmm7, xmm1
000000014148339f  84db                     test     bl, bl
00000001414833a1  7529                     jne      0x1414833cc
00000001414833a3  0f28c1                   movaps   xmm0, xmm1
00000001414833a6  eb2b                     jmp      0x1414833d3
00000001414833a8  0f57c0                   xorps    xmm0, xmm0
00000001414833ab  0f2ef0                   ucomiss  xmm6, xmm0
00000001414833ae  0f822c020000             jb       0x1414835e0
00000001414833b4  0f14fa                   unpcklps xmm7, xmm2
00000001414833b7  0f57c0                   xorps    xmm0, xmm0
00000001414833ba  0f5fc7                   maxps    xmm0, xmm7
00000001414833bd  f30f12ce                 movsldup xmm1, xmm6
00000001414833c1  0f5dc8                   minps    xmm1, xmm0
00000001414833c4  f30f16f9                 movshdup xmm7, xmm1
00000001414833c8  84db                     test     bl, bl
00000001414833ca  74d7                     je       0x1414833a3
00000001414833cc  0f28c6                   movaps   xmm0, xmm6
00000001414833cf  f30f58c1                 addss    xmm0, xmm1
00000001414833d3  440f28c1                 movaps   xmm8, xmm1
00000001414833d7  f3440fc2c701             cmpltss  xmm8, xmm7
00000001414833dd  410f54c0                 andps    xmm0, xmm8
00000001414833e1  440f55c1                 andnps   xmm8, xmm1
00000001414833e5  440f56c0                 orps     xmm8, xmm0
00000001414833e9  488d4c2428               lea      rcx, [rsp + 0x28]
00000001414833ee  4889fa                   mov      rdx, rdi
00000001414833f1  0f28d7                   movaps   xmm2, xmm7
00000001414833f4  e897fcffff               call     0x141483090 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSampler::sample_pair_at | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards11WallSampler14sample_pair_at17h3845de2e9feb8b12E.llvm.1951817906911489466
00000001414833f9  837c242801               cmp      dword ptr [rsp + 0x28], 1
00000001414833fe  7534                     jne      0x141483434
0000000141483400  f30f10442454             movss    xmm0, dword ptr [rsp + 0x54]
0000000141483406  f30f100d1a3b9b01         movss    xmm1, dword ptr [rip + 0x19b3b1a]
000000014148340e  f30f5cc8                 subss    xmm1, xmm0
0000000141483412  f20f1054242c             movsd    xmm2, qword ptr [rsp + 0x2c]
0000000141483418  f20f105c2440             movsd    xmm3, qword ptr [rsp + 0x40]
000000014148341e  f30f12c9                 movsldup xmm1, xmm1
0000000141483422  0f59ca                   mulps    xmm1, xmm2
0000000141483425  f3440f12c8               movsldup xmm9, xmm0
000000014148342a  440f59cb                 mulps    xmm9, xmm3
000000014148342e  440f58c9                 addps    xmm9, xmm1
0000000141483432  eb04                     jmp      0x141483438
0000000141483434  450f57c9                 xorps    xmm9, xmm9
0000000141483438  488d4c2428               lea      rcx, [rsp + 0x28]
000000014148343d  4889fa                   mov      rdx, rdi
0000000141483440  410f28d0                 movaps   xmm2, xmm8
0000000141483444  e847fcffff               call     0x141483090 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSampler::sample_pair_at | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards11WallSampler14sample_pair_at17h3845de2e9feb8b12E.llvm.1951817906911489466
0000000141483449  837c242801               cmp      dword ptr [rsp + 0x28], 1
000000014148344e  7531                     jne      0x141483481
0000000141483450  f30f10442454             movss    xmm0, dword ptr [rsp + 0x54]
0000000141483456  f30f100dca3a9b01         movss    xmm1, dword ptr [rip + 0x19b3aca]
000000014148345e  f30f5cc8                 subss    xmm1, xmm0
0000000141483462  f20f1054242c             movsd    xmm2, qword ptr [rsp + 0x2c]
0000000141483468  f20f105c2440             movsd    xmm3, qword ptr [rsp + 0x40]
000000014148346e  f30f12c9                 movsldup xmm1, xmm1
0000000141483472  0f59ca                   mulps    xmm1, xmm2
0000000141483475  f30f12c0                 movsldup xmm0, xmm0
0000000141483479  0f59c3                   mulps    xmm0, xmm3
000000014148347c  0f58c1                   addps    xmm0, xmm1
000000014148347f  eb03                     jmp      0x141483484
0000000141483481  0f57c0                   xorps    xmm0, xmm0
0000000141483484  410f5cc1                 subps    xmm0, xmm9
0000000141483488  0f28d0                   movaps   xmm2, xmm0
000000014148348b  0f59d0                   mulps    xmm2, xmm0
000000014148348e  f30f16ca                 movshdup xmm1, xmm2
0000000141483492  f30f58ca                 addss    xmm1, xmm2
0000000141483496  0f2e0dc768b801           ucomiss  xmm1, dword ptr [rip + 0x1b868c7]
000000014148349d  0f87da000000             ja       0x14148357d
00000001414834a3  f3410f58f8               addss    xmm7, xmm8
00000001414834a8  f30f593da03a9b01         mulss    xmm7, dword ptr [rip + 0x19b3aa0]
00000001414834b0  f30f5935b8439b01         mulss    xmm6, dword ptr [rip + 0x19b43b8]
00000001414834b8  f30f5f3588439b01         maxss    xmm6, dword ptr [rip + 0x19b4388]
00000001414834c0  0f28d7                   movaps   xmm2, xmm7
00000001414834c3  f30f5cd6                 subss    xmm2, xmm6
00000001414834c7  488d4c2428               lea      rcx, [rsp + 0x28]
00000001414834cc  4889fa                   mov      rdx, rdi
00000001414834cf  e8bcfbffff               call     0x141483090 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSampler::sample_pair_at | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards11WallSampler14sample_pair_at17h3845de2e9feb8b12E.llvm.1951817906911489466
00000001414834d4  837c242801               cmp      dword ptr [rsp + 0x28], 1
00000001414834d9  7534                     jne      0x14148350f
00000001414834db  f30f10442454             movss    xmm0, dword ptr [rsp + 0x54]
00000001414834e1  f30f100d3f3a9b01         movss    xmm1, dword ptr [rip + 0x19b3a3f]
00000001414834e9  f30f5cc8                 subss    xmm1, xmm0
00000001414834ed  f20f1054242c             movsd    xmm2, qword ptr [rsp + 0x2c]
00000001414834f3  f20f105c2440             movsd    xmm3, qword ptr [rsp + 0x40]
00000001414834f9  f30f12c9                 movsldup xmm1, xmm1
00000001414834fd  0f59ca                   mulps    xmm1, xmm2
0000000141483500  f3440f12c0               movsldup xmm8, xmm0
0000000141483505  440f59c3                 mulps    xmm8, xmm3
0000000141483509  440f58c1                 addps    xmm8, xmm1
000000014148350d  eb04                     jmp      0x141483513
000000014148350f  450f57c0                 xorps    xmm8, xmm8
0000000141483513  f30f58f7                 addss    xmm6, xmm7
0000000141483517  488d4c2428               lea      rcx, [rsp + 0x28]
000000014148351c  4889fa                   mov      rdx, rdi
000000014148351f  0f28d6                   movaps   xmm2, xmm6
0000000141483522  e869fbffff               call     0x141483090 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSampler::sample_pair_at | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards11WallSampler14sample_pair_at17h3845de2e9feb8b12E.llvm.1951817906911489466
0000000141483527  837c242801               cmp      dword ptr [rsp + 0x28], 1
000000014148352c  7531                     jne      0x14148355f
000000014148352e  f30f10442454             movss    xmm0, dword ptr [rsp + 0x54]
0000000141483534  f30f100dec399b01         movss    xmm1, dword ptr [rip + 0x19b39ec]
000000014148353c  f30f5cc8                 subss    xmm1, xmm0
0000000141483540  f20f1054242c             movsd    xmm2, qword ptr [rsp + 0x2c]
0000000141483546  f20f105c2440             movsd    xmm3, qword ptr [rsp + 0x40]
000000014148354c  f30f12c9                 movsldup xmm1, xmm1
0000000141483550  0f59ca                   mulps    xmm1, xmm2
0000000141483553  f30f12c0                 movsldup xmm0, xmm0
0000000141483557  0f59c3                   mulps    xmm0, xmm3
000000014148355a  0f58c1                   addps    xmm0, xmm1
000000014148355d  eb03                     jmp      0x141483562
000000014148355f  0f57c0                   xorps    xmm0, xmm0
0000000141483562  410f5cc0                 subps    xmm0, xmm8
0000000141483566  0f28d0                   movaps   xmm2, xmm0
0000000141483569  0f59d0                   mulps    xmm2, xmm0
000000014148356c  f30f16ca                 movshdup xmm1, xmm2
0000000141483570  f30f58ca                 addss    xmm1, xmm2
0000000141483574  0f2e0de967b801           ucomiss  xmm1, dword ptr [rip + 0x1b867e9]
000000014148357b  762b                     jbe      0x1414835a8
000000014148357d  f30f51c9                 sqrtss   xmm1, xmm1
0000000141483581  f30f10159f399b01         movss    xmm2, dword ptr [rip + 0x19b399f]
0000000141483589  f30f5ed1                 divss    xmm2, xmm1
000000014148358d  f30f12ca                 movsldup xmm1, xmm2
0000000141483591  0f59c1                   mulps    xmm0, xmm1
0000000141483594  0f13442428               movlps   qword ptr [rsp + 0x28], xmm0
0000000141483599  488d542428               lea      rdx, [rsp + 0x28]
000000014148359e  4889f1                   mov      rcx, rsi
00000001414835a1  e87a0f97ff               call     0x140df4520 ; utils::swizzlers::impl$0::x0y | _ZN71_$LT$glam..f32..vec2..Vec2$u20$as$u20$utils..swizzlers..SwizzlerX0Y$GT$3x0y17hce4d29c2d291b17dE
00000001414835a6  eb0e                     jmp      0x1414835b6
00000001414835a8  c7460800000000           mov      dword ptr [rsi + 8], 0
00000001414835af  48c7060000803f           mov      qword ptr [rsi], 0x3f800000
00000001414835b6  4889f0                   mov      rax, rsi
00000001414835b9  0f28742460               movaps   xmm6, xmmword ptr [rsp + 0x60]
00000001414835be  0f287c2470               movaps   xmm7, xmmword ptr [rsp + 0x70]
00000001414835c3  440f28842480000000       movaps   xmm8, xmmword ptr [rsp + 0x80]
00000001414835cc  440f288c2490000000       movaps   xmm9, xmmword ptr [rsp + 0x90]
00000001414835d5  4881c4a0000000           add      rsp, 0xa0
00000001414835dc  5b                       pop      rbx
00000001414835dd  5f                       pop      rdi
00000001414835de  5e                       pop      rsi
00000001414835df  c3                       ret      
00000001414835e0  c744245800000000         mov      dword ptr [rsp + 0x58], 0
00000001414835e8  f30f1174245c             movss    dword ptr [rsp + 0x5c], xmm6
00000001414835ee  488d442458               lea      rax, [rsp + 0x58]
00000001414835f3  4889442428               mov      qword ptr [rsp + 0x28], rax
00000001414835f8  488d05d1cfaeff           lea      rax, [rip - 0x51302f]
00000001414835ff  4889442430               mov      qword ptr [rsp + 0x30], rax
0000000141483604  488d4c245c               lea      rcx, [rsp + 0x5c]
0000000141483609  48894c2438               mov      qword ptr [rsp + 0x38], rcx
000000014148360e  4889442440               mov      qword ptr [rsp + 0x40], rax
0000000141483613  488d0de699e801           lea      rcx, [rip + 0x1e899e6]
000000014148361a  4c8d057f9ae801           lea      r8, [rip + 0x1e89a7f]
0000000141483621  488d542428               lea      rdx, [rsp + 0x28]
0000000141483626  e8a54d9401               call     0x142dc83d0 ; core::panicking::panic_fmt | _RNvNtCs8icZUrvfcq9_4core9panicking9panic_fmt
000000014148362b  cc                       int3     