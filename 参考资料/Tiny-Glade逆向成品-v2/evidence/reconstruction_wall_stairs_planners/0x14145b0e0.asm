000000014145b0e0  56                       push     rsi
000000014145b0e1  57                       push     rdi
000000014145b0e2  53                       push     rbx
000000014145b0e3  4883ec20                 sub      rsp, 0x20
000000014145b0e7  8b4210                   mov      eax, dword ptr [rdx + 0x10]
000000014145b0ea  448b4214                 mov      r8d, dword ptr [rdx + 0x14]
000000014145b0ee  448b52e8                 mov      r10d, dword ptr [rdx - 0x18]
000000014145b0f2  448b5aec                 mov      r11d, dword ptr [rdx - 0x14]
000000014145b0f6  4189c1                   mov      r9d, eax
000000014145b0f9  41c1f91f                 sar      r9d, 0x1f
000000014145b0fd  41d1e9                   shr      r9d, 1
000000014145b100  4131c1                   xor      r9d, eax
000000014145b103  4489d6                   mov      esi, r10d
000000014145b106  c1fe1f                   sar      esi, 0x1f
000000014145b109  d1ee                     shr      esi, 1
000000014145b10b  4431d6                   xor      esi, r10d
000000014145b10e  4589c2                   mov      r10d, r8d
000000014145b111  41c1fa1f                 sar      r10d, 0x1f
000000014145b115  41d1ea                   shr      r10d, 1
000000014145b118  4531c2                   xor      r10d, r8d
000000014145b11b  4489df                   mov      edi, r11d
000000014145b11e  c1ff1f                   sar      edi, 0x1f
000000014145b121  d1ef                     shr      edi, 1
000000014145b123  4431df                   xor      edi, r11d
000000014145b126  4531db                   xor      r11d, r11d
000000014145b129  4139fa                   cmp      r10d, edi
000000014145b12c  410f9cc3                 setl     r11b
000000014145b130  31ff                     xor      edi, edi
000000014145b132  4139f1                   cmp      r9d, esi
000000014145b135  400f9cc7                 setl     dil
000000014145b139  410f44fb                 cmove    edi, r11d
000000014145b13d  4080ff01                 cmp      dil, 1
000000014145b141  0f858f000000             jne      0x14145b1d6
000000014145b147  0f1002                   movups   xmm0, xmmword ptr [rdx]
000000014145b14a  0f29442410               movaps   xmmword ptr [rsp + 0x10], xmm0
000000014145b14f  0f104218                 movups   xmm0, xmmword ptr [rdx + 0x18]
000000014145b153  0f290424                 movaps   xmmword ptr [rsp], xmm0
000000014145b157  660f1f840000000000       nop      word ptr [rax + rax]
000000014145b160  4989d3                   mov      r11, rdx
000000014145b163  4883c2d8                 add      rdx, -0x28
000000014145b167  498b73f8                 mov      rsi, qword ptr [r11 - 8]
000000014145b16b  49897320                 mov      qword ptr [r11 + 0x20], rsi
000000014145b16f  410f1043d8               movups   xmm0, xmmword ptr [r11 - 0x28]
000000014145b174  410f104be8               movups   xmm1, xmmword ptr [r11 - 0x18]
000000014145b179  410f114b10               movups   xmmword ptr [r11 + 0x10], xmm1
000000014145b17e  410f1103                 movups   xmmword ptr [r11], xmm0
000000014145b182  4839ca                   cmp      rdx, rcx
000000014145b185  7434                     je       0x14145b1bb
000000014145b187  418b73c0                 mov      esi, dword ptr [r11 - 0x40]
000000014145b18b  418b7bc4                 mov      edi, dword ptr [r11 - 0x3c]
000000014145b18f  89f3                     mov      ebx, esi
000000014145b191  c1fb1f                   sar      ebx, 0x1f
000000014145b194  d1eb                     shr      ebx, 1
000000014145b196  31f3                     xor      ebx, esi
000000014145b198  89fe                     mov      esi, edi
000000014145b19a  c1fe1f                   sar      esi, 0x1f
000000014145b19d  d1ee                     shr      esi, 1
000000014145b19f  31fe                     xor      esi, edi
000000014145b1a1  31ff                     xor      edi, edi
000000014145b1a3  4139f2                   cmp      r10d, esi
000000014145b1a6  400f9cc7                 setl     dil
000000014145b1aa  31f6                     xor      esi, esi
000000014145b1ac  4139d9                   cmp      r9d, ebx
000000014145b1af  400f9cc6                 setl     sil
000000014145b1b3  0f44f7                   cmove    esi, edi
000000014145b1b6  4084f6                   test     sil, sil
000000014145b1b9  75a5                     jne      0x14145b160
000000014145b1bb  0f28442410               movaps   xmm0, xmmword ptr [rsp + 0x10]
000000014145b1c0  410f1143d8               movups   xmmword ptr [r11 - 0x28], xmm0
000000014145b1c5  418943e8                 mov      dword ptr [r11 - 0x18], eax
000000014145b1c9  458943ec                 mov      dword ptr [r11 - 0x14], r8d
000000014145b1cd  0f280424                 movaps   xmm0, xmmword ptr [rsp]
000000014145b1d1  410f1143f0               movups   xmmword ptr [r11 - 0x10], xmm0
000000014145b1d6  4883c420                 add      rsp, 0x20
000000014145b1da  5b                       pop      rbx
000000014145b1db  5f                       pop      rdi
000000014145b1dc  5e                       pop      rsi
000000014145b1dd  c3                       ret      