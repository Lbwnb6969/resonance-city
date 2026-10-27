0000000141483d90  4156                     push     r14
0000000141483d92  56                       push     rsi
0000000141483d93  57                       push     rdi
0000000141483d94  53                       push     rbx
0000000141483d95  4881ec98000000           sub      rsp, 0x98
0000000141483d9c  0f29b42480000000         movaps   xmmword ptr [rsp + 0x80], xmm6
0000000141483da4  4889d7                   mov      rdi, rdx
0000000141483da7  4889ce                   mov      rsi, rcx
0000000141483daa  4889d1                   mov      rcx, rdx
0000000141483dad  e85ebc4aff               call     0x14092fa10 ; country_core::resources::walls::public_wall_state::PublicWallState::try_get_wall_shape | _ZN12country_core9resources5walls17public_wall_state15PublicWallState18try_get_wall_shape17hec23b3b3b2c0939eE
0000000141483db2  4885c0                   test     rax, rax
0000000141483db5  0f8494000000             je       0x141483e4f
0000000141483dbb  4889c3                   mov      rbx, rax
0000000141483dbe  4c8d742464               lea      r14, [rsp + 0x64]
0000000141483dc3  f30f10158513b901         movss    xmm2, dword ptr [rip + 0x1b91385]
0000000141483dcb  4c89f1                   mov      rcx, r14
0000000141483dce  4889c2                   mov      rdx, rax
0000000141483dd1  e84a1360ff               call     0x140a85120 ; country_core::systems::wall::valid_enclosure::ShapeParameters::expand | _ZN12country_core7systems4wall15valid_enclosure15ShapeParameters6expand17hd0321616b4323821E
0000000141483dd6  488d4c2428               lea      rcx, [rsp + 0x28]
0000000141483ddb  4c89f2                   mov      rdx, r14
0000000141483dde  e8ad1360ff               call     0x140a85190 ; country_core::systems::wall::valid_enclosure::ShapeParameters::as_curve2 | _ZN12country_core7systems4wall15valid_enclosure15ShapeParameters9as_curve217hb7bd6d6bbc45bce6E
0000000141483de3  f30f10742458             movss    xmm6, dword ptr [rsp + 0x58]
0000000141483de9  488b542428               mov      rdx, qword ptr [rsp + 0x28]
0000000141483dee  4885d2                   test     rdx, rdx
0000000141483df1  7414                     je       0x141483e07
0000000141483df3  488b4c2430               mov      rcx, qword ptr [rsp + 0x30]
0000000141483df8  48c1e203                 shl      rdx, 3
0000000141483dfc  41b804000000             mov      r8d, 4
0000000141483e02  e8b97c22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141483e07  488b542440               mov      rdx, qword ptr [rsp + 0x40]
0000000141483e0c  4885d2                   test     rdx, rdx
0000000141483e0f  7414                     je       0x141483e25
0000000141483e11  488b4c2448               mov      rcx, qword ptr [rsp + 0x48]
0000000141483e16  48c1e202                 shl      rdx, 2
0000000141483e1a  41b804000000             mov      r8d, 4
0000000141483e20  e89b7c22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141483e25  0f1003                   movups   xmm0, xmmword ptr [rbx]
0000000141483e28  0f104b0c                 movups   xmm1, xmmword ptr [rbx + 0xc]
0000000141483e2c  0f114e0c                 movups   xmmword ptr [rsi + 0xc], xmm1
0000000141483e30  0f1106                   movups   xmmword ptr [rsi], xmm0
0000000141483e33  0f10442464               movups   xmm0, xmmword ptr [rsp + 0x64]
0000000141483e38  0f104c2470               movups   xmm1, xmmword ptr [rsp + 0x70]
0000000141483e3d  0f114e28                 movups   xmmword ptr [rsi + 0x28], xmm1
0000000141483e41  0f11461c                 movups   xmmword ptr [rsi + 0x1c], xmm0
0000000141483e45  f30f108790020000         movss    xmm0, dword ptr [rdi + 0x290]
0000000141483e4d  eb18                     jmp      0x141483e67
0000000141483e4f  f30f108790020000         movss    xmm0, dword ptr [rdi + 0x290]
0000000141483e57  c70602000000             mov      dword ptr [rsi], 2
0000000141483e5d  c7461c02000000           mov      dword ptr [rsi + 0x1c], 2
0000000141483e64  0f28f0                   movaps   xmm6, xmm0
0000000141483e67  f30f114638               movss    dword ptr [rsi + 0x38], xmm0
0000000141483e6c  f30f11763c               movss    dword ptr [rsi + 0x3c], xmm6
0000000141483e71  c746400000003e           mov      dword ptr [rsi + 0x40], 0x3e000000
0000000141483e78  4889f0                   mov      rax, rsi
0000000141483e7b  0f28b42480000000         movaps   xmm6, xmmword ptr [rsp + 0x80]
0000000141483e83  4881c498000000           add      rsp, 0x98
0000000141483e8a  5b                       pop      rbx
0000000141483e8b  5f                       pop      rdi
0000000141483e8c  5e                       pop      rsi
0000000141483e8d  415e                     pop      r14
0000000141483e8f  c3                       ret      