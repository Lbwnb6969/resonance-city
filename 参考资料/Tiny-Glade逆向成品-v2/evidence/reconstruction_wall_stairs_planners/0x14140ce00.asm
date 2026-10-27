000000014140ce00  4157                     push     r15
000000014140ce02  4156                     push     r14
000000014140ce04  56                       push     rsi
000000014140ce05  57                       push     rdi
000000014140ce06  53                       push     rbx
000000014140ce07  4881eca0000000           sub      rsp, 0xa0
000000014140ce0e  440f299c2490000000       movaps   xmmword ptr [rsp + 0x90], xmm11
000000014140ce17  440f29942480000000       movaps   xmmword ptr [rsp + 0x80], xmm10
000000014140ce20  440f294c2470             movaps   xmmword ptr [rsp + 0x70], xmm9
000000014140ce26  440f29442460             movaps   xmmword ptr [rsp + 0x60], xmm8
000000014140ce2c  0f297c2450               movaps   xmmword ptr [rsp + 0x50], xmm7
000000014140ce31  0f29742440               movaps   xmmword ptr [rsp + 0x40], xmm6
000000014140ce36  488b4108                 mov      rax, qword ptr [rcx + 8]
000000014140ce3a  488b5110                 mov      rdx, qword ptr [rcx + 0x10]
000000014140ce3e  4801d2                   add      rdx, rdx
000000014140ce41  4889442428               mov      qword ptr [rsp + 0x28], rax
000000014140ce46  4889542430               mov      qword ptr [rsp + 0x30], rdx
000000014140ce4b  f20f104150               movsd    xmm0, qword ptr [rcx + 0x50]
000000014140ce50  f20f11442438             movsd    qword ptr [rsp + 0x38], xmm0
000000014140ce56  488b05db7c8902           mov      rax, qword ptr [rip + 0x2897cdb]
000000014140ce5d  0f14d1                   unpcklps xmm2, xmm1
000000014140ce60  0f5e159943a501           divps    xmm2, xmmword ptr [rip + 0x1a54399]
000000014140ce67  0f5815f2a0a201           addps    xmm2, xmmword ptr [rip + 0x1a2a0f2]
000000014140ce6e  803800                   cmp      byte ptr [rax], 0
000000014140ce71  7433                     je       0x14140cea6
000000014140ce73  0f5d15d6aaa201           minps    xmm2, xmmword ptr [rip + 0x1a2aad6]
000000014140ce7a  0f59159f43a501           mulps    xmm2, xmmword ptr [rip + 0x1a5439f]
000000014140ce81  0f5815a843a501           addps    xmm2, xmmword ptr [rip + 0x1a543a8]
000000014140ce88  0f57c0                   xorps    xmm0, xmm0
000000014140ce8b  0fc2c201                 cmpltps  xmm0, xmm2
000000014140ce8f  0f14c0                   unpcklps xmm0, xmm0
000000014140ce92  660f50c0                 movmskpd eax, xmm0
000000014140ce96  0f57c0                   xorps    xmm0, xmm0
000000014140ce99  a802                     test     al, 2
000000014140ce9b  7541                     jne      0x14140cede
000000014140ce9d  0f57f6                   xorps    xmm6, xmm6
000000014140cea0  a801                     test     al, 1
000000014140cea2  7442                     je       0x14140cee6
000000014140cea4  eb43                     jmp      0x14140cee9
000000014140cea6  0f57c0                   xorps    xmm0, xmm0
000000014140cea9  0f5fd0                   maxps    xmm2, xmm0
000000014140ceac  0f28c2                   movaps   xmm0, xmm2
000000014140ceaf  0fc20599aaa20101         cmpltps  xmm0, xmmword ptr [rip + 0x1a2aa99]
000000014140ceb7  0f14c0                   unpcklps xmm0, xmm0
000000014140ceba  660f50c0                 movmskpd eax, xmm0
000000014140cebe  f30f103d4a43a501         movss    xmm7, dword ptr [rip + 0x1a5434a]
000000014140cec6  a802                     test     al, 2
000000014140cec8  0f85f4000000             jne      0x14140cfc2
000000014140cece  0f28f7                   movaps   xmm6, xmm7
000000014140ced1  a801                     test     al, 1
000000014140ced3  0f85f5000000             jne      0x14140cfce
000000014140ced9  e9f4000000               jmp      0x14140cfd2
000000014140cede  f30f16f2                 movshdup xmm6, xmm2
000000014140cee2  a801                     test     al, 1
000000014140cee4  7503                     jne      0x14140cee9
000000014140cee6  0f57d2                   xorps    xmm2, xmm2
000000014140cee9  f34c0f2cfe               cvttss2si r15, xmm6
000000014140ceee  31c0                     xor      eax, eax
000000014140cef0  0f2ef0                   ucomiss  xmm6, xmm0
000000014140cef3  440f42f8                 cmovb    r15d, eax
000000014140cef7  f30f100d499ba301         movss    xmm1, dword ptr [rip + 0x1a39b49]
000000014140ceff  0f2ef1                   ucomiss  xmm6, xmm1
000000014140cf02  b9ffffffff               mov      ecx, 0xffffffff
000000014140cf07  440f47f9                 cmova    r15d, ecx
000000014140cf0b  f3480f2cf2               cvttss2si rsi, xmm2
000000014140cf10  0f2ed0                   ucomiss  xmm2, xmm0
000000014140cf13  0f42f0                   cmovb    esi, eax
000000014140cf16  0f2ed1                   ucomiss  xmm2, xmm1
000000014140cf19  0f47f1                   cmova    esi, ecx
000000014140cf1c  0f57c0                   xorps    xmm0, xmm0
000000014140cf1f  f3490f2ac7               cvtsi2ss xmm0, r15
000000014140cf24  0f57c9                   xorps    xmm1, xmm1
000000014140cf27  f3480f2ace               cvtsi2ss xmm1, rsi
000000014140cf2c  f30f5cf0                 subss    xmm6, xmm0
000000014140cf30  4181ffff010000           cmp      r15d, 0x1ff
000000014140cf37  b8ff010000               mov      eax, 0x1ff
000000014140cf3c  bfff010000               mov      edi, 0x1ff
000000014140cf41  410f42ff                 cmovb    edi, r15d
000000014140cf45  41ffc7                   inc      r15d
000000014140cf48  4181ffff010000           cmp      r15d, 0x1ff
000000014140cf4f  440f43f8                 cmovae   r15d, eax
000000014140cf53  81feff010000             cmp      esi, 0x1ff
000000014140cf59  bbff010000               mov      ebx, 0x1ff
000000014140cf5e  0f42de                   cmovb    ebx, esi
000000014140cf61  ffc6                     inc      esi
000000014140cf63  81feff010000             cmp      esi, 0x1ff
000000014140cf69  0f43f0                   cmovae   esi, eax
000000014140cf6c  f30f5cd1                 subss    xmm2, xmm1
000000014140cf70  c1e309                   shl      ebx, 9
000000014140cf73  4889da                   mov      rdx, rbx
000000014140cf76  4809fa                   or       rdx, rdi
000000014140cf79  4c8d742428               lea      r14, [rsp + 0x28]
000000014140cf7e  4c89f1                   mov      rcx, r14
000000014140cf81  0f28fa                   movaps   xmm7, xmm2
000000014140cf84  e837af51ff               call     0x140927ec0 ; country_core::resources::terrain_height::impl$7::load_index_unchecked | _ZN112_$LT$country_core..resources..terrain_height..TerrainHeightFloatGrid$u20$as$u20$utils..float_grid..FloatGrid$GT$20load_index_unchecked17h9e50be2e4fe4a679E
000000014140cf89  440f28c0                 movaps   xmm8, xmm0
000000014140cf8d  4c09fb                   or       rbx, r15
000000014140cf90  4c89f1                   mov      rcx, r14
000000014140cf93  4889da                   mov      rdx, rbx
000000014140cf96  e825af51ff               call     0x140927ec0 ; country_core::resources::terrain_height::impl$7::load_index_unchecked | _ZN112_$LT$country_core..resources..terrain_height..TerrainHeightFloatGrid$u20$as$u20$utils..float_grid..FloatGrid$GT$20load_index_unchecked17h9e50be2e4fe4a679E
000000014140cf9b  440f28c8                 movaps   xmm9, xmm0
000000014140cf9f  c1e609                   shl      esi, 9
000000014140cfa2  4809f7                   or       rdi, rsi
000000014140cfa5  4c89f1                   mov      rcx, r14
000000014140cfa8  4889fa                   mov      rdx, rdi
000000014140cfab  e810af51ff               call     0x140927ec0 ; country_core::resources::terrain_height::impl$7::load_index_unchecked | _ZN112_$LT$country_core..resources..terrain_height..TerrainHeightFloatGrid$u20$as$u20$utils..float_grid..FloatGrid$GT$20load_index_unchecked17h9e50be2e4fe4a679E
000000014140cfb0  440f28d0                 movaps   xmm10, xmm0
000000014140cfb4  4c09fe                   or       rsi, r15
000000014140cfb7  4c89f1                   mov      rcx, r14
000000014140cfba  4889f2                   mov      rdx, rsi
000000014140cfbd  e9c3000000               jmp      0x14140d085
000000014140cfc2  f30f16f2                 movshdup xmm6, xmm2
000000014140cfc6  f30f59f7                 mulss    xmm6, xmm7
000000014140cfca  a801                     test     al, 1
000000014140cfcc  7404                     je       0x14140cfd2
000000014140cfce  f30f59fa                 mulss    xmm7, xmm2
000000014140cfd2  f3480f2cfe               cvttss2si rdi, xmm6
000000014140cfd7  31c0                     xor      eax, eax
000000014140cfd9  0f57c0                   xorps    xmm0, xmm0
000000014140cfdc  0f2ef0                   ucomiss  xmm6, xmm0
000000014140cfdf  0f42f8                   cmovb    edi, eax
000000014140cfe2  f30f100d5e9aa301         movss    xmm1, dword ptr [rip + 0x1a39a5e]
000000014140cfea  0f2ef1                   ucomiss  xmm6, xmm1
000000014140cfed  b9ffffffff               mov      ecx, 0xffffffff
000000014140cff2  0f47f9                   cmova    edi, ecx
000000014140cff5  f3480f2cdf               cvttss2si rbx, xmm7
000000014140cffa  0f2ef8                   ucomiss  xmm7, xmm0
000000014140cffd  0f42d8                   cmovb    ebx, eax
000000014140d000  0f2ef9                   ucomiss  xmm7, xmm1
000000014140d003  0f47d9                   cmova    ebx, ecx
000000014140d006  81fffe010000             cmp      edi, 0x1fe
000000014140d00c  b8fe010000               mov      eax, 0x1fe
000000014140d011  0f43f8                   cmovae   edi, eax
000000014140d014  81fbfe010000             cmp      ebx, 0x1fe
000000014140d01a  0f43d8                   cmovae   ebx, eax
000000014140d01d  0f57c0                   xorps    xmm0, xmm0
000000014140d020  f30f2ac7                 cvtsi2ss xmm0, edi
000000014140d024  0f57c9                   xorps    xmm1, xmm1
000000014140d027  f30f2acb                 cvtsi2ss xmm1, ebx
000000014140d02b  f30f5cf0                 subss    xmm6, xmm0
000000014140d02f  f30f5cf9                 subss    xmm7, xmm1
000000014140d033  c1e309                   shl      ebx, 9
000000014140d036  4889da                   mov      rdx, rbx
000000014140d039  4809fa                   or       rdx, rdi
000000014140d03c  488d742428               lea      rsi, [rsp + 0x28]
000000014140d041  4889f1                   mov      rcx, rsi
000000014140d044  e877ae51ff               call     0x140927ec0 ; country_core::resources::terrain_height::impl$7::load_index_unchecked | _ZN112_$LT$country_core..resources..terrain_height..TerrainHeightFloatGrid$u20$as$u20$utils..float_grid..FloatGrid$GT$20load_index_unchecked17h9e50be2e4fe4a679E
000000014140d049  440f28c0                 movaps   xmm8, xmm0
000000014140d04d  488d143b                 lea      rdx, [rbx + rdi]
000000014140d051  48ffc2                   inc      rdx
000000014140d054  4889f1                   mov      rcx, rsi
000000014140d057  e864ae51ff               call     0x140927ec0 ; country_core::resources::terrain_height::impl$7::load_index_unchecked | _ZN112_$LT$country_core..resources..terrain_height..TerrainHeightFloatGrid$u20$as$u20$utils..float_grid..FloatGrid$GT$20load_index_unchecked17h9e50be2e4fe4a679E
000000014140d05c  440f28c8                 movaps   xmm9, xmm0
000000014140d060  488d143b                 lea      rdx, [rbx + rdi]
000000014140d064  4881c200020000           add      rdx, 0x200
000000014140d06b  4889f1                   mov      rcx, rsi
000000014140d06e  e84dae51ff               call     0x140927ec0 ; country_core::resources::terrain_height::impl$7::load_index_unchecked | _ZN112_$LT$country_core..resources..terrain_height..TerrainHeightFloatGrid$u20$as$u20$utils..float_grid..FloatGrid$GT$20load_index_unchecked17h9e50be2e4fe4a679E
000000014140d073  440f28d0                 movaps   xmm10, xmm0
000000014140d077  488d143b                 lea      rdx, [rbx + rdi]
000000014140d07b  4881c201020000           add      rdx, 0x201
000000014140d082  4889f1                   mov      rcx, rsi
000000014140d085  e836ae51ff               call     0x140927ec0 ; country_core::resources::terrain_height::impl$7::load_index_unchecked | _ZN112_$LT$country_core..resources..terrain_height..TerrainHeightFloatGrid$u20$as$u20$utils..float_grid..FloatGrid$GT$20load_index_unchecked17h9e50be2e4fe4a679E
000000014140d08a  440f28d8                 movaps   xmm11, xmm0
000000014140d08e  410f28c0                 movaps   xmm0, xmm8
000000014140d092  410f28ca                 movaps   xmm1, xmm10
000000014140d096  0f28d7                   movaps   xmm2, xmm7
000000014140d099  e832cf9dff               call     0x140de9fd0 ; utils::lerp | _ZN5utils4lerp17heb8fde786a8b1071E
000000014140d09e  440f28c0                 movaps   xmm8, xmm0
000000014140d0a2  410f28c1                 movaps   xmm0, xmm9
000000014140d0a6  410f28cb                 movaps   xmm1, xmm11
000000014140d0aa  0f28d7                   movaps   xmm2, xmm7
000000014140d0ad  e81ecf9dff               call     0x140de9fd0 ; utils::lerp | _ZN5utils4lerp17heb8fde786a8b1071E
000000014140d0b2  0f28c8                   movaps   xmm1, xmm0
000000014140d0b5  410f28c0                 movaps   xmm0, xmm8
000000014140d0b9  0f28d6                   movaps   xmm2, xmm6
000000014140d0bc  e80fcf9dff               call     0x140de9fd0 ; utils::lerp | _ZN5utils4lerp17heb8fde786a8b1071E
000000014140d0c1  0f28742440               movaps   xmm6, xmmword ptr [rsp + 0x40]
000000014140d0c6  0f287c2450               movaps   xmm7, xmmword ptr [rsp + 0x50]
000000014140d0cb  440f28442460             movaps   xmm8, xmmword ptr [rsp + 0x60]
000000014140d0d1  440f284c2470             movaps   xmm9, xmmword ptr [rsp + 0x70]
000000014140d0d7  440f28942480000000       movaps   xmm10, xmmword ptr [rsp + 0x80]
000000014140d0e0  440f289c2490000000       movaps   xmm11, xmmword ptr [rsp + 0x90]
000000014140d0e9  4881c4a0000000           add      rsp, 0xa0
000000014140d0f0  5b                       pop      rbx
000000014140d0f1  5f                       pop      rdi
000000014140d0f2  5e                       pop      rsi
000000014140d0f3  415e                     pop      r14
000000014140d0f5  415f                     pop      r15
000000014140d0f7  c3                       ret      