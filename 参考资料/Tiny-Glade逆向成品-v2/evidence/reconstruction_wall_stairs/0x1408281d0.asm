00000001408281d0  55                       push     rbp
00000001408281d1  56                       push     rsi
00000001408281d2  4881ec88000000           sub      rsp, 0x88
00000001408281d9  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001408281e1  48c74500feffffff         mov      qword ptr [rbp], 0xfffffffffffffffe
00000001408281e9  4889ce                   mov      rsi, rcx
00000001408281ec  4983f801                 cmp      r8, 1
00000001408281f0  770f                     ja       0x140828201
00000001408281f2  48b80000000000000080     movabs   rax, 0x8000000000000000
00000001408281fc  488906                   mov      qword ptr [rsi], rax
00000001408281ff  eb79                     jmp      0x14082827a
0000000140828201  488955c0                 mov      qword ptr [rbp - 0x40], rdx
0000000140828205  4c8945c8                 mov      qword ptr [rbp - 0x38], r8
0000000140828209  48c745d000000000         mov      qword ptr [rbp - 0x30], 0
0000000140828211  4c8945d8                 mov      qword ptr [rbp - 0x28], r8
0000000140828215  488d4de0                 lea      rcx, [rbp - 0x20]
0000000140828219  488d55c0                 lea      rdx, [rbp - 0x40]
000000014082821d  e88e78bc00               call     0x1413efab0 ; _ZN98_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$alloc..vec..spec_from_iter..SpecFromIter$LT$T$C$I$GT$$GT$9from_iter17heb552e03d289c664E | alloc::vec::spec_from_iter::impl$0::from_iter<system_wall_constructor::construct_arches::wooden_arch_frame::WoodenArchFrameDensePoint,core::iter::adapters::map::Map<core::ops::range::Range<usize>,system_wall_constructor::construct_arches::wooden_arch_frame::add_frame_normals::closure_env$0> >
0000000140828222  488b55e8                 mov      rdx, qword ptr [rbp - 0x18]
0000000140828226  4c8b45f0                 mov      r8, qword ptr [rbp - 0x10]
000000014082822a  c644243800               mov      byte ptr [rsp + 0x38], 0
000000014082822f  c74424305839343d         mov      dword ptr [rsp + 0x30], 0x3d343958
0000000140828237  c7442428f853e33d         mov      dword ptr [rsp + 0x28], 0x3de353f8
000000014082823f  c7442420c3f5283e         mov      dword ptr [rsp + 0x20], 0x3e28f5c3
0000000140828247  4889f1                   mov      rcx, rsi
000000014082824a  488955f8                 mov      qword ptr [rbp - 8], rdx
000000014082824e  41b913000000             mov      r9d, 0x13
0000000140828254  e8873afdff               call     0x1407fbce0 ; system_wall_constructor::construct_arches::wooden_arch_frame::wooden_arch_frame_params_from_points | _ZN23system_wall_constructor16construct_arches17wooden_arch_frame36wooden_arch_frame_params_from_points17h12cda3dc8dc59499E
0000000140828259  90                       nop      
000000014082825a  488b45e0                 mov      rax, qword ptr [rbp - 0x20]
000000014082825e  4885c0                   test     rax, rax
0000000140828261  7417                     je       0x14082827a
0000000140828263  48c1e003                 shl      rax, 3
0000000140828267  488d1440                 lea      rdx, [rax + rax*2]
000000014082826b  41b804000000             mov      r8d, 4
0000000140828271  488b4df8                 mov      rcx, qword ptr [rbp - 8]
0000000140828275  e84638e8ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
000000014082827a  4889f0                   mov      rax, rsi
000000014082827d  4881c488000000           add      rsp, 0x88
0000000140828284  5e                       pop      rsi
0000000140828285  5d                       pop      rbp
0000000140828286  c3                       ret      
0000000140828287  660f1f840000000000       nop      word ptr [rax + rax]
0000000140828290  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000140828295  55                       push     rbp
0000000140828296  56                       push     rsi
0000000140828297  4883ec48                 sub      rsp, 0x48
000000014082829b  488daa80000000           lea      rbp, [rdx + 0x80]
00000001408282a2  488b45e0                 mov      rax, qword ptr [rbp - 0x20]
00000001408282a6  4885c0                   test     rax, rax
00000001408282a9  7418                     je       0x1408282c3
00000001408282ab  48c1e003                 shl      rax, 3
00000001408282af  488d1440                 lea      rdx, [rax + rax*2]
00000001408282b3  41b804000000             mov      r8d, 4
00000001408282b9  488b4df8                 mov      rcx, qword ptr [rbp - 8]
00000001408282bd  e8fe37e8ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001408282c2  90                       nop      
00000001408282c3  4883c448                 add      rsp, 0x48
00000001408282c7  5e                       pop      rsi
00000001408282c8  5d                       pop      rbp
00000001408282c9  c3                       ret      