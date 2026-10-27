00000001408279f0  56                       push     rsi
00000001408279f1  57                       push     rdi
00000001408279f2  53                       push     rbx
00000001408279f3  4881ec30010000           sub      rsp, 0x130
00000001408279fa  440f29bc2420010000       movaps   xmmword ptr [rsp + 0x120], xmm15
0000000140827a03  440f29b42410010000       movaps   xmmword ptr [rsp + 0x110], xmm14
0000000140827a0c  440f29ac2400010000       movaps   xmmword ptr [rsp + 0x100], xmm13
0000000140827a15  440f29a424f0000000       movaps   xmmword ptr [rsp + 0xf0], xmm12
0000000140827a1e  440f299c24e0000000       movaps   xmmword ptr [rsp + 0xe0], xmm11
0000000140827a27  440f299424d0000000       movaps   xmmword ptr [rsp + 0xd0], xmm10
0000000140827a30  440f298c24c0000000       movaps   xmmword ptr [rsp + 0xc0], xmm9
0000000140827a39  440f298424b0000000       movaps   xmmword ptr [rsp + 0xb0], xmm8
0000000140827a42  0f29bc24a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm7
0000000140827a4a  0f29b42490000000         movaps   xmmword ptr [rsp + 0x90], xmm6
0000000140827a52  0f28fb                   movaps   xmm7, xmm3
0000000140827a55  0f28f2                   movaps   xmm6, xmm2
0000000140827a58  4889ce                   mov      rsi, rcx
0000000140827a5b  f3440f10842470010000     movss    xmm8, dword ptr [rsp + 0x170]
0000000140827a65  f30f119c2480000000       movss    dword ptr [rsp + 0x80], xmm3
0000000140827a6e  f3440f11842484000000     movss    dword ptr [rsp + 0x84], xmm8
0000000140827a78  f30f1002                 movss    xmm0, dword ptr [rdx]
0000000140827a7c  f30f104a08               movss    xmm1, dword ptr [rdx + 8]
0000000140827a81  f30f11442428             movss    dword ptr [rsp + 0x28], xmm0
0000000140827a87  f30f114c242c             movss    dword ptr [rsp + 0x2c], xmm1
0000000140827a8d  f30f105204               movss    xmm2, dword ptr [rdx + 4]
0000000140827a92  f30f581596227e02         addss    xmm2, dword ptr [rip + 0x27e2296]
0000000140827a9a  488d4c2450               lea      rcx, [rsp + 0x50]
0000000140827a9f  488d542428               lea      rdx, [rsp + 0x28]
0000000140827aa4  e897ca5c00               call     0x140df4540 ; utils::swizzlers::impl$1::xvy | _ZN71_$LT$glam..f32..vec2..Vec2$u20$as$u20$utils..swizzlers..SwizzlerXVY$GT$3xvy17hcb9aa753d52e64e7E
0000000140827aa9  440f57056ffd6002         xorps    xmm8, xmmword ptr [rip + 0x260fd6f]
0000000140827ab1  f3440f11842488000000     movss    dword ptr [rsp + 0x88], xmm8
0000000140827abb  f30f11bc248c000000       movss    dword ptr [rsp + 0x8c], xmm7
0000000140827ac4  f30f103d84f46002         movss    xmm7, dword ptr [rip + 0x260f484]
0000000140827acc  f30f59fe                 mulss    xmm7, xmm6
0000000140827ad0  f30f583d38227e02         addss    xmm7, dword ptr [rip + 0x27e2238]
0000000140827ad8  0f57c0                   xorps    xmm0, xmm0
0000000140827adb  f30f5ff8                 maxss    xmm7, xmm0
0000000140827adf  488d4c2428               lea      rcx, [rsp + 0x28]
0000000140827ae4  488d942488000000         lea      rdx, [rsp + 0x88]
0000000140827aec  e82fca5c00               call     0x140df4520 ; utils::swizzlers::impl$0::x0y | _ZN71_$LT$glam..f32..vec2..Vec2$u20$as$u20$utils..swizzlers..SwizzlerX0Y$GT$3x0y17hce4d29c2d291b17dE
0000000140827af1  f30f12c7                 movsldup xmm0, xmm7
0000000140827af5  f30f597c2430             mulss    xmm7, dword ptr [rsp + 0x30]
0000000140827afb  f2440f10442428           movsd    xmm8, qword ptr [rsp + 0x28]
0000000140827b02  440f59c0                 mulps    xmm8, xmm0
0000000140827b06  f2440f10642450           movsd    xmm12, qword ptr [rsp + 0x50]
0000000140827b0d  f3440f105c2458           movss    xmm11, dword ptr [rsp + 0x58]
0000000140827b14  450f28cc                 movaps   xmm9, xmm12
0000000140827b18  450f5cc8                 subps    xmm9, xmm8
0000000140827b1c  450f28d3                 movaps   xmm10, xmm11
0000000140827b20  f3440f5cd7               subss    xmm10, xmm7
0000000140827b25  450f58c4                 addps    xmm8, xmm12
0000000140827b29  f3410f58fb               addss    xmm7, xmm11
0000000140827b2e  f684247801000001         test     byte ptr [rsp + 0x178], 1
0000000140827b36  7417                     je       0x140827b4f
0000000140827b38  f3440f10b42480010000     movss    xmm14, dword ptr [rsp + 0x180]
0000000140827b42  450f28ee                 movaps   xmm13, xmm14
0000000140827b46  410f28c6                 movaps   xmm0, xmm14
0000000140827b4a  e9bc010000               jmp      0x140827d0b
0000000140827b4f  488b9c2490010000         mov      rbx, qword ptr [rsp + 0x190]
0000000140827b57  f3440f103d90fc6002       movss    xmm15, dword ptr [rip + 0x260fc90]
0000000140827b60  410f28c7                 movaps   xmm0, xmm15
0000000140827b64  410f16c2                 movlhps  xmm0, xmm10
0000000140827b68  410f28c9                 movaps   xmm1, xmm9
0000000140827b6c  0fc6c824                 shufps   xmm1, xmm0, 0x24
0000000140827b70  0f580da9217e02           addps    xmm1, xmmword ptr [rip + 0x27e21a9]
0000000140827b77  488bbc2488010000         mov      rdi, qword ptr [rsp + 0x188]
0000000140827b7f  0f294c2460               movaps   xmmword ptr [rsp + 0x60], xmm1
0000000140827b84  f2440f1035a3e07702       movsd    xmm14, qword ptr [rip + 0x277e0a3]
0000000140827b8d  f2440f11742470           movsd    qword ptr [rsp + 0x70], xmm14
0000000140827b94  c744242002020000         mov      dword ptr [rsp + 0x20], 0x202
0000000140827b9c  488d4c2428               lea      rcx, [rsp + 0x28]
0000000140827ba1  4c8d442460               lea      r8, [rsp + 0x60]
0000000140827ba6  f30f101d8ef36002         movss    xmm3, dword ptr [rip + 0x260f38e]
0000000140827bae  4889da                   mov      rdx, rbx
0000000140827bb1  e86a611c00               call     0x1409edd20 ; country_core::systems::collision::world::RaycastWorld::raycast_simple | _ZN12country_core7systems9collision5world12RaycastWorld14raycast_simple17h0e5fb3e3ac060f8bE
0000000140827bb6  0fb6442428               movzx    eax, byte ptr [rsp + 0x28]
0000000140827bbb  83f811                   cmp      eax, 0x11
0000000140827bbe  7427                     je       0x140827be7
0000000140827bc0  f3440f106c2444           movss    xmm13, dword ptr [rsp + 0x44]
0000000140827bc7  83f801                   cmp      eax, 1
0000000140827bca  0f84e9010000             je       0x140827db9
0000000140827bd0  83f802                   cmp      eax, 2
0000000140827bd3  7512                     jne      0x140827be7
0000000140827bd5  f644242901               test     byte ptr [rsp + 0x29], 1
0000000140827bda  751f                     jne      0x140827bfb
0000000140827bdc  f3440f582d4ff36002       addss    xmm13, dword ptr [rip + 0x260f34f]
0000000140827be5  eb14                     jmp      0x140827bfb
0000000140827be7  4889f9                   mov      rcx, rdi
0000000140827bea  410f28c9                 movaps   xmm1, xmm9
0000000140827bee  410f28d2                 movaps   xmm2, xmm10
0000000140827bf2  e80952be00               call     0x14140ce00 ; _ZN12country_core9resources14terrain_height28TerrainHeightsData$LT$Ty$GT$18sample_at_world_xz17h2445e50d219a5ab4E | _ZN12country_core9resources14terrain_height28TerrainHeightsData$LT$Ty$GT$18sample_at_world_xz17h2eea1dee9cdbfe25E
0000000140827bf7  440f28e8                 movaps   xmm13, xmm0
0000000140827bfb  410f28c7                 movaps   xmm0, xmm15
0000000140827bff  0f16c7                   movlhps  xmm0, xmm7
0000000140827c02  410f28c8                 movaps   xmm1, xmm8
0000000140827c06  0fc6c824                 shufps   xmm1, xmm0, 0x24
0000000140827c0a  0f580d0f217e02           addps    xmm1, xmmword ptr [rip + 0x27e210f]
0000000140827c11  0f294c2460               movaps   xmmword ptr [rsp + 0x60], xmm1
0000000140827c16  f2440f11742470           movsd    qword ptr [rsp + 0x70], xmm14
0000000140827c1d  c744242002020000         mov      dword ptr [rsp + 0x20], 0x202
0000000140827c25  488d4c2428               lea      rcx, [rsp + 0x28]
0000000140827c2a  4c8d442460               lea      r8, [rsp + 0x60]
0000000140827c2f  f30f101d05f36002         movss    xmm3, dword ptr [rip + 0x260f305]
0000000140827c37  4889da                   mov      rdx, rbx
0000000140827c3a  e8e1601c00               call     0x1409edd20 ; country_core::systems::collision::world::RaycastWorld::raycast_simple | _ZN12country_core7systems9collision5world12RaycastWorld14raycast_simple17h0e5fb3e3ac060f8bE
0000000140827c3f  0fb6442428               movzx    eax, byte ptr [rsp + 0x28]
0000000140827c44  83f811                   cmp      eax, 0x11
0000000140827c47  7427                     je       0x140827c70
0000000140827c49  f3440f10742444           movss    xmm14, dword ptr [rsp + 0x44]
0000000140827c50  83f801                   cmp      eax, 1
0000000140827c53  0f846e010000             je       0x140827dc7
0000000140827c59  83f802                   cmp      eax, 2
0000000140827c5c  7512                     jne      0x140827c70
0000000140827c5e  f644242901               test     byte ptr [rsp + 0x29], 1
0000000140827c63  751e                     jne      0x140827c83
0000000140827c65  f3440f5835c6f26002       addss    xmm14, dword ptr [rip + 0x260f2c6]
0000000140827c6e  eb13                     jmp      0x140827c83
0000000140827c70  4889f9                   mov      rcx, rdi
0000000140827c73  410f28c8                 movaps   xmm1, xmm8
0000000140827c77  0f28d7                   movaps   xmm2, xmm7
0000000140827c7a  e88151be00               call     0x14140ce00 ; _ZN12country_core9resources14terrain_height28TerrainHeightsData$LT$Ty$GT$18sample_at_world_xz17h2445e50d219a5ab4E | _ZN12country_core9resources14terrain_height28TerrainHeightsData$LT$Ty$GT$18sample_at_world_xz17h2eea1dee9cdbfe25E
0000000140827c7f  440f28f0                 movaps   xmm14, xmm0
0000000140827c83  450f16fb                 movlhps  xmm15, xmm11
0000000140827c87  410f28c4                 movaps   xmm0, xmm12
0000000140827c8b  410fc6c724               shufps   xmm0, xmm15, 0x24
0000000140827c90  0f580589207e02           addps    xmm0, xmmword ptr [rip + 0x27e2089]
0000000140827c97  0f29442460               movaps   xmmword ptr [rsp + 0x60], xmm0
0000000140827c9c  f20f10058cdf7702         movsd    xmm0, qword ptr [rip + 0x277df8c]
0000000140827ca4  f20f11442470             movsd    qword ptr [rsp + 0x70], xmm0
0000000140827caa  c744242002020000         mov      dword ptr [rsp + 0x20], 0x202
0000000140827cb2  488d4c2428               lea      rcx, [rsp + 0x28]
0000000140827cb7  4c8d442460               lea      r8, [rsp + 0x60]
0000000140827cbc  f30f101d78f26002         movss    xmm3, dword ptr [rip + 0x260f278]
0000000140827cc4  4889da                   mov      rdx, rbx
0000000140827cc7  e854601c00               call     0x1409edd20 ; country_core::systems::collision::world::RaycastWorld::raycast_simple | _ZN12country_core7systems9collision5world12RaycastWorld14raycast_simple17h0e5fb3e3ac060f8bE
0000000140827ccc  0fb6442428               movzx    eax, byte ptr [rsp + 0x28]
0000000140827cd1  83f811                   cmp      eax, 0x11
0000000140827cd4  7425                     je       0x140827cfb
0000000140827cd6  f30f10442444             movss    xmm0, dword ptr [rsp + 0x44]
0000000140827cdc  83f801                   cmp      eax, 1
0000000140827cdf  0f84f0000000             je       0x140827dd5
0000000140827ce5  83f802                   cmp      eax, 2
0000000140827ce8  7511                     jne      0x140827cfb
0000000140827cea  f644242901               test     byte ptr [rsp + 0x29], 1
0000000140827cef  751a                     jne      0x140827d0b
0000000140827cf1  f30f58053bf26002         addss    xmm0, dword ptr [rip + 0x260f23b]
0000000140827cf9  eb10                     jmp      0x140827d0b
0000000140827cfb  4889f9                   mov      rcx, rdi
0000000140827cfe  410f28cc                 movaps   xmm1, xmm12
0000000140827d02  410f28d3                 movaps   xmm2, xmm11
0000000140827d06  e8f550be00               call     0x14140ce00 ; _ZN12country_core9resources14terrain_height28TerrainHeightsData$LT$Ty$GT$18sample_at_world_xz17h2445e50d219a5ab4E | _ZN12country_core9resources14terrain_height28TerrainHeightsData$LT$Ty$GT$18sample_at_world_xz17h2eea1dee9cdbfe25E
0000000140827d0b  f3440f116e24             movss    dword ptr [rsi + 0x24], xmm13
0000000140827d11  f3440f117628             movss    dword ptr [rsi + 0x28], xmm14
0000000140827d17  f30f11462c               movss    dword ptr [rsi + 0x2c], xmm0
0000000140827d1c  488d4e30                 lea      rcx, [rsi + 0x30]
0000000140827d20  488d942480000000         lea      rdx, [rsp + 0x80]
0000000140827d28  e8f3c75c00               call     0x140df4520 ; utils::swizzlers::impl$0::x0y | _ZN71_$LT$glam..f32..vec2..Vec2$u20$as$u20$utils..swizzlers..SwizzlerX0Y$GT$3x0y17hce4d29c2d291b17dE
0000000140827d2d  440f130e                 movlps   qword ptr [rsi], xmm9
0000000140827d31  f3440f115608             movss    dword ptr [rsi + 8], xmm10
0000000140827d37  440f13460c               movlps   qword ptr [rsi + 0xc], xmm8
0000000140827d3c  f30f117e14               movss    dword ptr [rsi + 0x14], xmm7
0000000140827d41  488b442450               mov      rax, qword ptr [rsp + 0x50]
0000000140827d46  48894618                 mov      qword ptr [rsi + 0x18], rax
0000000140827d4a  8b442458                 mov      eax, dword ptr [rsp + 0x58]
0000000140827d4e  894620                   mov      dword ptr [rsi + 0x20], eax
0000000140827d51  f30f11763c               movss    dword ptr [rsi + 0x3c], xmm6
0000000140827d56  0f28b42490000000         movaps   xmm6, xmmword ptr [rsp + 0x90]
0000000140827d5e  0f28bc24a0000000         movaps   xmm7, xmmword ptr [rsp + 0xa0]
0000000140827d66  440f288424b0000000       movaps   xmm8, xmmword ptr [rsp + 0xb0]
0000000140827d6f  440f288c24c0000000       movaps   xmm9, xmmword ptr [rsp + 0xc0]
0000000140827d78  440f289424d0000000       movaps   xmm10, xmmword ptr [rsp + 0xd0]
0000000140827d81  440f289c24e0000000       movaps   xmm11, xmmword ptr [rsp + 0xe0]
0000000140827d8a  440f28a424f0000000       movaps   xmm12, xmmword ptr [rsp + 0xf0]
0000000140827d93  440f28ac2400010000       movaps   xmm13, xmmword ptr [rsp + 0x100]
0000000140827d9c  440f28b42410010000       movaps   xmm14, xmmword ptr [rsp + 0x110]
0000000140827da5  440f28bc2420010000       movaps   xmm15, xmmword ptr [rsp + 0x120]
0000000140827dae  4881c430010000           add      rsp, 0x130
0000000140827db5  5b                       pop      rbx
0000000140827db6  5f                       pop      rdi
0000000140827db7  5e                       pop      rsi
0000000140827db8  c3                       ret      
0000000140827db9  f3440f582dc6fb6002       addss    xmm13, dword ptr [rip + 0x260fbc6]
0000000140827dc2  e934feffff               jmp      0x140827bfb
0000000140827dc7  f3440f5835b8fb6002       addss    xmm14, dword ptr [rip + 0x260fbb8]
0000000140827dd0  e9aefeffff               jmp      0x140827c83
0000000140827dd5  f30f5805abfb6002         addss    xmm0, dword ptr [rip + 0x260fbab]
0000000140827ddd  e929ffffff               jmp      0x140827d0b