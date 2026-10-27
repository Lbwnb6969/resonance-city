0000000141e38fb0  4883ec78                 sub      rsp, 0x78
0000000141e38fb4  440f29542460             movaps   xmmword ptr [rsp + 0x60], xmm10
0000000141e38fba  440f294c2450             movaps   xmmword ptr [rsp + 0x50], xmm9
0000000141e38fc0  440f29442440             movaps   xmmword ptr [rsp + 0x40], xmm8
0000000141e38fc6  0f297c2430               movaps   xmmword ptr [rsp + 0x30], xmm7
0000000141e38fcb  0f29742420               movaps   xmmword ptr [rsp + 0x20], xmm6
0000000141e38fd0  488b5110                 mov      rdx, qword ptr [rcx + 0x10]
0000000141e38fd4  4883fa01                 cmp      rdx, 1
0000000141e38fd8  0f8623020000             jbe      0x141e39201
0000000141e38fde  4c8b4108                 mov      r8, qword ptr [rcx + 8]
0000000141e38fe2  f2410f1020               movsd    xmm4, qword ptr [r8]
0000000141e38fe7  f2410f104008             movsd    xmm0, qword ptr [r8 + 8]
0000000141e38fed  0f14ca                   unpcklps xmm1, xmm2
0000000141e38ff0  0f28d1                   movaps   xmm2, xmm1
0000000141e38ff3  0f5cd4                   subps    xmm2, xmm4
0000000141e38ff6  0f28d8                   movaps   xmm3, xmm0
0000000141e38ff9  0f5cdc                   subps    xmm3, xmm4
0000000141e38ffc  0f59d3                   mulps    xmm2, xmm3
0000000141e38fff  f30f16ea                 movshdup xmm5, xmm2
0000000141e39003  0f59db                   mulps    xmm3, xmm3
0000000141e39006  f30f16f3                 movshdup xmm6, xmm3
0000000141e3900a  f30f58f3                 addss    xmm6, xmm3
0000000141e3900e  f30f5f350edfff00         maxss    xmm6, dword ptr [rip + 0xffdf0e]
0000000141e39016  f30f58ea                 addss    xmm5, xmm2
0000000141e3901a  f30f5eee                 divss    xmm5, xmm6
0000000141e3901e  0f57db                   xorps    xmm3, xmm3
0000000141e39021  0f57f6                   xorps    xmm6, xmm6
0000000141e39024  f30f5ff5                 maxss    xmm6, xmm5
0000000141e39028  f30f1015f8deff00         movss    xmm2, dword ptr [rip + 0xffdef8]
0000000141e39030  0f28ea                   movaps   xmm5, xmm2
0000000141e39033  f30f5dee                 minss    xmm5, xmm6
0000000141e39037  0f28f2                   movaps   xmm6, xmm2
0000000141e3903a  f30f5cf5                 subss    xmm6, xmm5
0000000141e3903e  f30f12f6                 movsldup xmm6, xmm6
0000000141e39042  0f59f4                   mulps    xmm6, xmm4
0000000141e39045  f30f12e5                 movsldup xmm4, xmm5
0000000141e39049  0f59e0                   mulps    xmm4, xmm0
0000000141e3904c  0f58e6                   addps    xmm4, xmm6
0000000141e3904f  0f28f1                   movaps   xmm6, xmm1
0000000141e39052  0f5cf4                   subps    xmm6, xmm4
0000000141e39055  0f59f6                   mulps    xmm6, xmm6
0000000141e39058  f30f16e6                 movshdup xmm4, xmm6
0000000141e3905c  f30f58e6                 addss    xmm4, xmm6
0000000141e39060  0f57f6                   xorps    xmm6, xmm6
0000000141e39063  f30f51f4                 sqrtss   xmm6, xmm4
0000000141e39067  f30f1025cddeff00         movss    xmm4, dword ptr [rip + 0xffdecd]
0000000141e3906f  0f2ee6                   ucomiss  xmm4, xmm6
0000000141e39072  7618                     jbe      0x141e3908c
0000000141e39074  0f2eeb                   ucomiss  xmm5, xmm3
0000000141e39077  0f82ff000000             jb       0x141e3917c
0000000141e3907d  0f2ed5                   ucomiss  xmm2, xmm5
0000000141e39080  0f28e6                   movaps   xmm4, xmm6
0000000141e39083  0f28dd                   movaps   xmm3, xmm5
0000000141e39086  0f82f0000000             jb       0x141e3917c
0000000141e3908c  31c0                     xor      eax, eax
0000000141e3908e  4883fa02                 cmp      rdx, 2
0000000141e39092  0f84fe000000             je       0x141e39196
0000000141e39098  48c1e203                 shl      rdx, 3
0000000141e3909c  41ba01000000             mov      r10d, 1
0000000141e390a2  41bb10000000             mov      r11d, 0x10
0000000141e390a8  f30f102d74deff00         movss    xmm5, dword ptr [rip + 0xffde74]
0000000141e390b0  0f57f6                   xorps    xmm6, xmm6
0000000141e390b3  eb1b                     jmp      0x141e390d0
0000000141e390b5  66662e0f1f840000000000   nop      word ptr cs:[rax + rax]
0000000141e390c0  4983c308                 add      r11, 8
0000000141e390c4  41ffc2                   inc      r10d
0000000141e390c7  4c39da                   cmp      rdx, r11
0000000141e390ca  0f84c4000000             je       0x141e39194
0000000141e390d0  0f28f8                   movaps   xmm7, xmm0
0000000141e390d3  440f28c1                 movaps   xmm8, xmm1
0000000141e390d7  440f5cc0                 subps    xmm8, xmm0
0000000141e390db  f2430f100418             movsd    xmm0, qword ptr [r8 + r11]
0000000141e390e1  440f28c8                 movaps   xmm9, xmm0
0000000141e390e5  440f5ccf                 subps    xmm9, xmm7
0000000141e390e9  450f59c1                 mulps    xmm8, xmm9
0000000141e390ed  f3450f16d0               movshdup xmm10, xmm8
0000000141e390f2  f3450f58d0               addss    xmm10, xmm8
0000000141e390f7  450f59c9                 mulps    xmm9, xmm9
0000000141e390fb  f3450f16c1               movshdup xmm8, xmm9
0000000141e39100  f3450f58c1               addss    xmm8, xmm9
0000000141e39105  f3440f5fc5               maxss    xmm8, xmm5
0000000141e3910a  f3450f5ed0               divss    xmm10, xmm8
0000000141e3910f  450f57c9                 xorps    xmm9, xmm9
0000000141e39113  f3450f5fca               maxss    xmm9, xmm10
0000000141e39118  440f28c2                 movaps   xmm8, xmm2
0000000141e3911c  f3450f5dc1               minss    xmm8, xmm9
0000000141e39121  440f28ca                 movaps   xmm9, xmm2
0000000141e39125  f3450f5cc8               subss    xmm9, xmm8
0000000141e3912a  f3450f12c9               movsldup xmm9, xmm9
0000000141e3912f  440f59cf                 mulps    xmm9, xmm7
0000000141e39133  f3410f12f8               movsldup xmm7, xmm8
0000000141e39138  0f59f8                   mulps    xmm7, xmm0
0000000141e3913b  410f58f9                 addps    xmm7, xmm9
0000000141e3913f  440f28c9                 movaps   xmm9, xmm1
0000000141e39143  440f5ccf                 subps    xmm9, xmm7
0000000141e39147  450f59c9                 mulps    xmm9, xmm9
0000000141e3914b  f3410f16f9               movshdup xmm7, xmm9
0000000141e39150  f3410f58f9               addss    xmm7, xmm9
0000000141e39155  f30f51ff                 sqrtss   xmm7, xmm7
0000000141e39159  0f2ee7                   ucomiss  xmm4, xmm7
0000000141e3915c  0f865effffff             jbe      0x141e390c0
0000000141e39162  440f2ec6                 ucomiss  xmm8, xmm6
0000000141e39166  7214                     jb       0x141e3917c
0000000141e39168  410f2ed0                 ucomiss  xmm2, xmm8
0000000141e3916c  0f28e7                   movaps   xmm4, xmm7
0000000141e3916f  410f28d8                 movaps   xmm3, xmm8
0000000141e39173  4489d0                   mov      eax, r10d
0000000141e39176  0f8344ffffff             jae      0x141e390c0
0000000141e3917c  488d0d453b5b01           lea      rcx, [rip + 0x15b3b45] ; 'assertion failed: (0.0..=1.0).contains(&t)'
0000000141e39183  4c8d056e3b5b01           lea      r8, [rip + 0x15b3b6e]
0000000141e3918a  ba2a000000               mov      edx, 0x2a
0000000141e3918f  e81cf2f800               call     0x142dc83b0 ; core::panicking::panic | _RNvNtCs8icZUrvfcq9_4core9panicking5panic
0000000141e39194  89c0                     mov      eax, eax
0000000141e39196  488b5128                 mov      rdx, qword ptr [rcx + 0x28]
0000000141e3919a  4839c2                   cmp      rdx, rax
0000000141e3919d  0f869a000000             jbe      0x141e3923d
0000000141e391a3  4c8d4001                 lea      r8, [rax + 1]
0000000141e391a7  4939d0                   cmp      r8, rdx
0000000141e391aa  0f8398000000             jae      0x141e39248
0000000141e391b0  488b4920                 mov      rcx, qword ptr [rcx + 0x20]
0000000141e391b4  f30f5cd3                 subss    xmm2, xmm3
0000000141e391b8  f20f100481               movsd    xmm0, qword ptr [rcx + rax*4]
0000000141e391bd  0f14d3                   unpcklps xmm2, xmm3
0000000141e391c0  0f59d0                   mulps    xmm2, xmm0
0000000141e391c3  f30f16c2                 movshdup xmm0, xmm2
0000000141e391c7  f30f58c2                 addss    xmm0, xmm2
0000000141e391cb  0f2ec0                   ucomiss  xmm0, xmm0
0000000141e391ce  7a45                     jp       0x141e39215
0000000141e391d0  660f7ec0                 movd     eax, xmm0
0000000141e391d4  25ffffff7f               and      eax, 0x7fffffff
0000000141e391d9  3d0000807f               cmp      eax, 0x7f800000
0000000141e391de  7449                     je       0x141e39229
0000000141e391e0  0f28742420               movaps   xmm6, xmmword ptr [rsp + 0x20]
0000000141e391e5  0f287c2430               movaps   xmm7, xmmword ptr [rsp + 0x30]
0000000141e391ea  440f28442440             movaps   xmm8, xmmword ptr [rsp + 0x40]
0000000141e391f0  440f284c2450             movaps   xmm9, xmmword ptr [rsp + 0x50]
0000000141e391f6  440f28542460             movaps   xmm10, xmmword ptr [rsp + 0x60]
0000000141e391fc  4883c478                 add      rsp, 0x78
0000000141e39200  c3                       ret      
0000000141e39201  488d0d783a5b01           lea      rcx, [rip + 0x15b3a78] ; 'assertion failed: self.point_count() >= 2'
0000000141e39208  ba29000000               mov      edx, 0x29
0000000141e3920d  4d89c8                   mov      r8, r9
0000000141e39210  e89bf1f800               call     0x142dc83b0 ; core::panicking::panic | _RNvNtCs8icZUrvfcq9_4core9panicking5panic
0000000141e39215  488d0dd73b5b01           lea      rcx, [rip + 0x15b3bd7] ; 'assertion failed: !u.is_nan()assertion failed: (0.0..=1.0).contains(&t)crates/utils/src/curve/cu'
0000000141e3921c  ba1d000000               mov      edx, 0x1d
0000000141e39221  4d89c8                   mov      r8, r9
0000000141e39224  e887f1f800               call     0x142dc83b0 ; core::panicking::panic | _RNvNtCs8icZUrvfcq9_4core9panicking5panic
0000000141e39229  488d0d483c5b01           lea      rcx, [rip + 0x15b3c48] ; 'assertion failed: !u.is_infinite()'
0000000141e39230  ba22000000               mov      edx, 0x22
0000000141e39235  4d89c8                   mov      r8, r9
0000000141e39238  e873f1f800               call     0x142dc83b0 ; core::panicking::panic | _RNvNtCs8icZUrvfcq9_4core9panicking5panic
0000000141e3923d  4889c1                   mov      rcx, rax
0000000141e39240  4d89c8                   mov      r8, r9
0000000141e39243  e8aaeff800               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
0000000141e39248  4c89c1                   mov      rcx, r8
0000000141e3924b  4d89c8                   mov      r8, r9
0000000141e3924e  e89feff800               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
0000000141e39253  cc                       int3     