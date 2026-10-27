00000001414851c0  56                       push     rsi
00000001414851c1  4881ec80000000           sub      rsp, 0x80
00000001414851c8  0f29742470               movaps   xmmword ptr [rsp + 0x70], xmm6
00000001414851cd  0f28f2                   movaps   xmm6, xmm2
00000001414851d0  4889ce                   mov      rsi, rcx
00000001414851d3  f30f114c242c             movss    dword ptr [rsp + 0x2c], xmm1
00000001414851d9  f30f11542430             movss    dword ptr [rsp + 0x30], xmm2
00000001414851df  f30f5cf1                 subss    xmm6, xmm1
00000001414851e3  0f57c0                   xorps    xmm0, xmm0
00000001414851e6  0f2ec6                   ucomiss  xmm0, xmm6
00000001414851e9  0f8394000000             jae      0x141485283
00000001414851ef  0f28c6                   movaps   xmm0, xmm6
00000001414851f2  4584c9                   test     r9b, r9b
00000001414851f5  0f84a4000000             je       0x14148529f
00000001414851fb  f30f5e054550e801         divss    xmm0, dword ptr [rip + 0x1e85045]
0000000141485203  f30f58051d1d9b01         addss    xmm0, dword ptr [rip + 0x19b1d1d]
000000014148520b  f30f59053d1d9b01         mulss    xmm0, dword ptr [rip + 0x19b1d3d]
0000000141485213  e8e8d89a01               call     0x142e32b00 ; roundf
0000000141485218  f30f5f0510269b01         maxss    xmm0, dword ptr [rip + 0x19b2610]
0000000141485220  f3480f2cc0               cvttss2si rax, xmm0
0000000141485225  4889c1                   mov      rcx, rax
0000000141485228  48c1f93f                 sar      rcx, 0x3f
000000014148522c  0f28c8                   movaps   xmm1, xmm0
000000014148522f  f30f5c0df51c9b01         subss    xmm1, dword ptr [rip + 0x19b1cf5]
0000000141485237  f3480f2cd1               cvttss2si rdx, xmm1
000000014148523c  4821ca                   and      rdx, rcx
000000014148523f  4809c2                   or       rdx, rax
0000000141485242  31c9                     xor      ecx, ecx
0000000141485244  0f57c9                   xorps    xmm1, xmm1
0000000141485247  0f2ec1                   ucomiss  xmm0, xmm1
000000014148524a  480f43ca                 cmovae   rcx, rdx
000000014148524e  0f2e05db1c9b01           ucomiss  xmm0, dword ptr [rip + 0x19b1cdb]
0000000141485255  48c7c0ffffffff           mov      rax, 0xffffffffffffffff
000000014148525c  480f46c1                 cmovbe   rax, rcx
0000000141485260  4889442468               mov      qword ptr [rsp + 0x68], rax
0000000141485265  488d0c45ffffffff         lea      rcx, [rax*2 - 1]
000000014148526d  4885c9                   test     rcx, rcx
0000000141485270  0f888d000000             js       0x141485303
0000000141485276  0f57c0                   xorps    xmm0, xmm0
0000000141485279  f3480f2ac1               cvtsi2ss xmm0, rcx
000000014148527e  e993000000               jmp      0x141485316
0000000141485283  48c70600000000           mov      qword ptr [rsi], 0
000000014148528a  48c7460804000000         mov      qword ptr [rsi + 8], 4
0000000141485292  48c7461000000000         mov      qword ptr [rsi + 0x10], 0
000000014148529a  e931010000               jmp      0x1414853d0
000000014148529f  f30f5e05b94fe801         divss    xmm0, dword ptr [rip + 0x1e84fb9]
00000001414852a7  e854d89a01               call     0x142e32b00 ; roundf
00000001414852ac  f30f5f05741c9b01         maxss    xmm0, dword ptr [rip + 0x19b1c74]
00000001414852b4  f3480f2cc0               cvttss2si rax, xmm0
00000001414852b9  4889c1                   mov      rcx, rax
00000001414852bc  48c1f93f                 sar      rcx, 0x3f
00000001414852c0  0f28c8                   movaps   xmm1, xmm0
00000001414852c3  f30f5c0d611c9b01         subss    xmm1, dword ptr [rip + 0x19b1c61]
00000001414852cb  f3480f2cd1               cvttss2si rdx, xmm1
00000001414852d0  4821ca                   and      rdx, rcx
00000001414852d3  4809c2                   or       rdx, rax
00000001414852d6  31c9                     xor      ecx, ecx
00000001414852d8  0f57c9                   xorps    xmm1, xmm1
00000001414852db  0f2ec1                   ucomiss  xmm0, xmm1
00000001414852de  480f43ca                 cmovae   rcx, rdx
00000001414852e2  0f2e05471c9b01           ucomiss  xmm0, dword ptr [rip + 0x19b1c47]
00000001414852e9  48c7c0ffffffff           mov      rax, 0xffffffffffffffff
00000001414852f0  480f46c1                 cmovbe   rax, rcx
00000001414852f4  4885c0                   test     rax, rax
00000001414852f7  786c                     js       0x141485365
00000001414852f9  0f57c0                   xorps    xmm0, xmm0
00000001414852fc  f3480f2ac0               cvtsi2ss xmm0, rax
0000000141485301  eb7c                     jmp      0x14148537f
0000000141485303  48d1e9                   shr      rcx, 1
0000000141485306  4883c901                 or       rcx, 1
000000014148530a  0f57c0                   xorps    xmm0, xmm0
000000014148530d  f3480f2ac1               cvtsi2ss xmm0, rcx
0000000141485312  f30f58c0                 addss    xmm0, xmm0
0000000141485316  f30f5ef0                 divss    xmm6, xmm0
000000014148531a  f30f11742428             movss    dword ptr [rsp + 0x28], xmm6
0000000141485320  488d4c242c               lea      rcx, [rsp + 0x2c]
0000000141485325  48894c2438               mov      qword ptr [rsp + 0x38], rcx
000000014148532a  488d4c2428               lea      rcx, [rsp + 0x28]
000000014148532f  48894c2440               mov      qword ptr [rsp + 0x40], rcx
0000000141485334  488d4c2468               lea      rcx, [rsp + 0x68]
0000000141485339  48894c2448               mov      qword ptr [rsp + 0x48], rcx
000000014148533e  488d4c2430               lea      rcx, [rsp + 0x30]
0000000141485343  48894c2450               mov      qword ptr [rsp + 0x50], rcx
0000000141485348  48c744245800000000       mov      qword ptr [rsp + 0x58], 0
0000000141485351  4889442460               mov      qword ptr [rsp + 0x60], rax
0000000141485356  488d542438               lea      rdx, [rsp + 0x38]
000000014148535b  4889f1                   mov      rcx, rsi
000000014148535e  e81d97f6ff               call     0x1413eea80 ; _ZN98_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$alloc..vec..spec_from_iter..SpecFromIter$LT$T$C$I$GT$$GT$9from_iter17hd1f0830f25b9bee0E | alloc::vec::spec_from_iter::impl$0::from_iter<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceXRange,core::iter::adapters::filter_map::FilterMap<core::ops::range::Range<usize>,system_wall_constructor::construct_wooden_walls::construct_wall_boards::top_rim_merlon_ranges::closure_env$1> >
0000000141485363  eb6b                     jmp      0x1414853d0
0000000141485365  4889c1                   mov      rcx, rax
0000000141485368  48d1e9                   shr      rcx, 1
000000014148536b  89c2                     mov      edx, eax
000000014148536d  83e201                   and      edx, 1
0000000141485370  4809ca                   or       rdx, rcx
0000000141485373  0f57c0                   xorps    xmm0, xmm0
0000000141485376  f3480f2ac2               cvtsi2ss xmm0, rdx
000000014148537b  f30f58c0                 addss    xmm0, xmm0
000000014148537f  f30f5ef0                 divss    xmm6, xmm0
0000000141485383  f30f11742434             movss    dword ptr [rsp + 0x34], xmm6
0000000141485389  f30f5935bf1b9b01         mulss    xmm6, dword ptr [rip + 0x19b1bbf]
0000000141485391  f30f11742428             movss    dword ptr [rsp + 0x28], xmm6
0000000141485397  488d4c242c               lea      rcx, [rsp + 0x2c]
000000014148539c  48894c2438               mov      qword ptr [rsp + 0x38], rcx
00000001414853a1  488d4c2434               lea      rcx, [rsp + 0x34]
00000001414853a6  48894c2440               mov      qword ptr [rsp + 0x40], rcx
00000001414853ab  488d4c2428               lea      rcx, [rsp + 0x28]
00000001414853b0  48894c2448               mov      qword ptr [rsp + 0x48], rcx
00000001414853b5  48c744245000000000       mov      qword ptr [rsp + 0x50], 0
00000001414853be  4889442458               mov      qword ptr [rsp + 0x58], rax
00000001414853c3  488d542438               lea      rdx, [rsp + 0x38]
00000001414853c8  4889f1                   mov      rcx, rsi
00000001414853cb  e88083f6ff               call     0x1413ed750 ; _ZN98_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$alloc..vec..spec_from_iter..SpecFromIter$LT$T$C$I$GT$$GT$9from_iter17hb9350b850abea67aE | alloc::vec::spec_from_iter::impl$0::from_iter<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceXRange,core::iter::adapters::filter_map::FilterMap<core::ops::range::Range<usize>,system_wall_constructor::construct_wooden_walls::construct_wall_boards::top_rim_merlon_ranges::closure_env$0> >
00000001414853d0  4889f0                   mov      rax, rsi
00000001414853d3  0f28742470               movaps   xmm6, xmmword ptr [rsp + 0x70]
00000001414853d8  4881c480000000           add      rsp, 0x80
00000001414853df  5e                       pop      rsi
00000001414853e0  c3                       ret      