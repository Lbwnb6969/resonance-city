0000000141488be0  4157                     push     r15
0000000141488be2  4156                     push     r14
0000000141488be4  4155                     push     r13
0000000141488be6  4154                     push     r12
0000000141488be8  56                       push     rsi
0000000141488be9  57                       push     rdi
0000000141488bea  55                       push     rbp
0000000141488beb  53                       push     rbx
0000000141488bec  4881ec58010000           sub      rsp, 0x158
0000000141488bf3  440f29bc2440010000       movaps   xmmword ptr [rsp + 0x140], xmm15
0000000141488bfc  440f29b42430010000       movaps   xmmword ptr [rsp + 0x130], xmm14
0000000141488c05  440f29ac2420010000       movaps   xmmword ptr [rsp + 0x120], xmm13
0000000141488c0e  440f29a42410010000       movaps   xmmword ptr [rsp + 0x110], xmm12
0000000141488c17  440f299c2400010000       movaps   xmmword ptr [rsp + 0x100], xmm11
0000000141488c20  440f299424f0000000       movaps   xmmword ptr [rsp + 0xf0], xmm10
0000000141488c29  440f298c24e0000000       movaps   xmmword ptr [rsp + 0xe0], xmm9
0000000141488c32  440f298424d0000000       movaps   xmmword ptr [rsp + 0xd0], xmm8
0000000141488c3b  0f29bc24c0000000         movaps   xmmword ptr [rsp + 0xc0], xmm7
0000000141488c43  0f29b424b0000000         movaps   xmmword ptr [rsp + 0xb0], xmm6
0000000141488c4b  4883791000               cmp      qword ptr [rcx + 0x10], 0
0000000141488c50  0f8427070000             je       0x14148937d
0000000141488c56  4889ce                   mov      rsi, rcx
0000000141488c59  31ff                     xor      edi, edi
0000000141488c5b  f30f103575259b01         movss    xmm6, dword ptr [rip + 0x19b2575]
0000000141488c63  f30f103dddeb9a01         movss    xmm7, dword ptr [rip + 0x19aebdd]
0000000141488c6b  4531e4                   xor      r12d, r12d
0000000141488c6e  eb0c                     jmp      0x141488c7c
0000000141488c70  48ffc7                   inc      rdi
0000000141488c73  4839df                   cmp      rdi, rbx
0000000141488c76  0f83ed060000             jae      0x141489369
0000000141488c7c  488b4608                 mov      rax, qword ptr [rsi + 8]
0000000141488c80  4c8d34bf                 lea      r14, [rdi + rdi*4]
0000000141488c84  4a8d0cf0                 lea      rcx, [rax + r14*8]
0000000141488c88  4883c110                 add      rcx, 0x10
0000000141488c8c  e8bf5f96ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
0000000141488c91  0f2ec6                   ucomiss  xmm0, xmm6
0000000141488c94  488b5e10                 mov      rbx, qword ptr [rsi + 0x10]
0000000141488c98  73d6                     jae      0x141488c70
0000000141488c9a  4839df                   cmp      rdi, rbx
0000000141488c9d  0f8373070000             jae      0x141489416
0000000141488ca3  4c8b4608                 mov      r8, qword ptr [rsi + 8]
0000000141488ca7  4f8b1cf0                 mov      r11, qword ptr [r8 + r14*8]
0000000141488cab  4b8b6cf008               mov      rbp, qword ptr [r8 + r14*8 + 8]
0000000141488cb0  f3470f105cf010           movss    xmm11, dword ptr [r8 + r14*8 + 0x10]
0000000141488cb7  f2470f104cf014           movsd    xmm9, qword ptr [r8 + r14*8 + 0x14]
0000000141488cbe  f3450f16d1               movshdup xmm10, xmm9
0000000141488cc3  f3470f1044f01c           movss    xmm8, dword ptr [r8 + r14*8 + 0x1c]
0000000141488cca  470fb66cf020             movzx    r13d, byte ptr [r8 + r14*8 + 0x20]
0000000141488cd0  470fb64cf021             movzx    r9d, byte ptr [r8 + r14*8 + 0x21]
0000000141488cd6  488d04dd00000000         lea      rax, [rbx*8]
0000000141488cde  488d0480                 lea      rax, [rax + rax*4]
0000000141488ce2  410f28c0                 movaps   xmm0, xmm8
0000000141488ce6  f30f58c7                 addss    xmm0, xmm7
0000000141488cea  410f28cb                 movaps   xmm1, xmm11
0000000141488cee  f3410fc2cb03             cmpunordss xmm1, xmm11
0000000141488cf4  498d4828                 lea      rcx, [r8 + 0x28]
0000000141488cf8  41f6c301                 test     r11b, 1
0000000141488cfc  0f849e000000             je       0x141488da0
0000000141488d02  410f28d2                 movaps   xmm2, xmm10
0000000141488d06  f3410fc2d203             cmpunordss xmm2, xmm10
0000000141488d0c  4889c2                   mov      rdx, rax
0000000141488d0f  4531f6                   xor      r14d, r14d
0000000141488d12  eb1d                     jmp      0x141488d31
0000000141488d14  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141488d20  49ffc6                   inc      r14
0000000141488d23  4883c128                 add      rcx, 0x28
0000000141488d27  4883c2d8                 add      rdx, -0x28
0000000141488d2b  0f843fffffff             je       0x141488c70
0000000141488d31  4c39f7                   cmp      rdi, r14
0000000141488d34  74ea                     je       0x141488d20
0000000141488d36  443869f8                 cmp      byte ptr [rcx - 8], r13b
0000000141488d3a  75e4                     jne      0x141488d20
0000000141488d3c  f641d801                 test     byte ptr [rcx - 0x28], 1
0000000141488d40  74de                     je       0x141488d20
0000000141488d42  483969e0                 cmp      qword ptr [rcx - 0x20], rbp
0000000141488d46  75d8                     jne      0x141488d20
0000000141488d48  f30f1059f4               movss    xmm3, dword ptr [rcx - 0xc]
0000000141488d4d  f30f58df                 addss    xmm3, xmm7
0000000141488d51  410f2ed9                 ucomiss  xmm3, xmm9
0000000141488d55  72c9                     jb       0x141488d20
0000000141488d57  0f2e41ec                 ucomiss  xmm0, dword ptr [rcx - 0x14]
0000000141488d5b  72c3                     jb       0x141488d20
0000000141488d5d  f30f1059e8               movss    xmm3, dword ptr [rcx - 0x18]
0000000141488d62  f30f1061f0               movss    xmm4, dword ptr [rcx - 0x10]
0000000141488d67  0f28e9                   movaps   xmm5, xmm1
0000000141488d6a  0f54eb                   andps    xmm5, xmm3
0000000141488d6d  f3410f5fdb               maxss    xmm3, xmm11
0000000141488d72  440f28e1                 movaps   xmm12, xmm1
0000000141488d76  440f55e3                 andnps   xmm12, xmm3
0000000141488d7a  440f56e5                 orps     xmm12, xmm5
0000000141488d7e  0f28da                   movaps   xmm3, xmm2
0000000141488d81  0f54dc                   andps    xmm3, xmm4
0000000141488d84  f3410f5de2               minss    xmm4, xmm10
0000000141488d89  440f28ea                 movaps   xmm13, xmm2
0000000141488d8d  440f55ec                 andnps   xmm13, xmm4
0000000141488d91  440f56eb                 orps     xmm13, xmm3
0000000141488d95  450f2ee5                 ucomiss  xmm12, xmm13
0000000141488d99  7385                     jae      0x141488d20
0000000141488d9b  e98c000000               jmp      0x141488e2c
0000000141488da0  4889c2                   mov      rdx, rax
0000000141488da3  4531f6                   xor      r14d, r14d
0000000141488da6  eb19                     jmp      0x141488dc1
0000000141488da8  0f1f840000000000         nop      dword ptr [rax + rax]
0000000141488db0  49ffc6                   inc      r14
0000000141488db3  4883c128                 add      rcx, 0x28
0000000141488db7  4883c2d8                 add      rdx, -0x28
0000000141488dbb  0f84affeffff             je       0x141488c70
0000000141488dc1  4c39f7                   cmp      rdi, r14
0000000141488dc4  74ea                     je       0x141488db0
0000000141488dc6  443869f8                 cmp      byte ptr [rcx - 8], r13b
0000000141488dca  75e4                     jne      0x141488db0
0000000141488dcc  f641d801                 test     byte ptr [rcx - 0x28], 1
0000000141488dd0  75de                     jne      0x141488db0
0000000141488dd2  f30f1051f4               movss    xmm2, dword ptr [rcx - 0xc]
0000000141488dd7  f30f58d7                 addss    xmm2, xmm7
0000000141488ddb  410f2ed1                 ucomiss  xmm2, xmm9
0000000141488ddf  72cf                     jb       0x141488db0
0000000141488de1  0f2e41ec                 ucomiss  xmm0, dword ptr [rcx - 0x14]
0000000141488de5  72c9                     jb       0x141488db0
0000000141488de7  f30f1051e8               movss    xmm2, dword ptr [rcx - 0x18]
0000000141488dec  f30f1059f0               movss    xmm3, dword ptr [rcx - 0x10]
0000000141488df1  0f28e1                   movaps   xmm4, xmm1
0000000141488df4  0f54e2                   andps    xmm4, xmm2
0000000141488df7  f3410f5fd3               maxss    xmm2, xmm11
0000000141488dfc  440f28e1                 movaps   xmm12, xmm1
0000000141488e00  440f55e2                 andnps   xmm12, xmm2
0000000141488e04  440f56e4                 orps     xmm12, xmm4
0000000141488e08  450f28ea                 movaps   xmm13, xmm10
0000000141488e0c  f3450fc2ea03             cmpunordss xmm13, xmm10
0000000141488e12  410f28d5                 movaps   xmm2, xmm13
0000000141488e16  0f54d3                   andps    xmm2, xmm3
0000000141488e19  f3410f5dda               minss    xmm3, xmm10
0000000141488e1e  440f55eb                 andnps   xmm13, xmm3
0000000141488e22  440f56ea                 orps     xmm13, xmm2
0000000141488e26  450f2ee5                 ucomiss  xmm12, xmm13
0000000141488e2a  7384                     jae      0x141488db0
0000000141488e2c  44884c2424               mov      byte ptr [rsp + 0x24], r9b
0000000141488e31  4c01c0                   add      rax, r8
0000000141488e34  4839c1                   cmp      rcx, rax
0000000141488e37  4c895c2428               mov      qword ptr [rsp + 0x28], r11
0000000141488e3c  0f840f010000             je       0x141488f51
0000000141488e42  410f28d5                 movaps   xmm2, xmm13
0000000141488e46  f3410f5cd4               subss    xmm2, xmm12
0000000141488e4b  66410f7ed1               movd     r9d, xmm2
0000000141488e50  4829c8                   sub      rax, rcx
0000000141488e53  48bacdcccccccccccccc     movabs   rdx, 0xcccccccccccccccd
0000000141488e5d  48f7e2                   mul      rdx
0000000141488e60  48c1ea05                 shr      rdx, 5
0000000141488e64  498d4601                 lea      rax, [r14 + 1]
0000000141488e68  4883c120                 add      rcx, 0x20
0000000141488e6c  eb22                     jmp      0x141488e90
0000000141488e6e  450f4eca                 cmovle   r9d, r10d
0000000141488e72  4c8b5c2428               mov      r11, qword ptr [rsp + 0x28]
0000000141488e77  660f1f840000000000       nop      word ptr [rax + rax]
0000000141488e80  48ffc0                   inc      rax
0000000141488e83  4883c128                 add      rcx, 0x28
0000000141488e87  48ffca                   dec      rdx
0000000141488e8a  0f84c1000000             je       0x141488f51
0000000141488e90  4839c7                   cmp      rdi, rax
0000000141488e93  74eb                     je       0x141488e80
0000000141488e95  443829                   cmp      byte ptr [rcx], r13b
0000000141488e98  75e6                     jne      0x141488e80
0000000141488e9a  f30f1059f0               movss    xmm3, dword ptr [rcx - 0x10]
0000000141488e9f  f30f1051f4               movss    xmm2, dword ptr [rcx - 0xc]
0000000141488ea4  f30f1061f8               movss    xmm4, dword ptr [rcx - 8]
0000000141488ea9  f30f1069fc               movss    xmm5, dword ptr [rcx - 4]
0000000141488eae  488379e001               cmp      qword ptr [rcx - 0x20], 1
0000000141488eb3  750f                     jne      0x141488ec4
0000000141488eb5  483969e8                 cmp      qword ptr [rcx - 0x18], rbp
0000000141488eb9  410f94c2                 sete     r10b
0000000141488ebd  4584d3                   test     r11b, r10b
0000000141488ec0  74be                     je       0x141488e80
0000000141488ec2  eb06                     jmp      0x141488eca
0000000141488ec4  41f6c301                 test     r11b, 1
0000000141488ec8  75b6                     jne      0x141488e80
0000000141488eca  f30f58ef                 addss    xmm5, xmm7
0000000141488ece  410f2ee9                 ucomiss  xmm5, xmm9
0000000141488ed2  72ac                     jb       0x141488e80
0000000141488ed4  0f2ec2                   ucomiss  xmm0, xmm2
0000000141488ed7  72a7                     jb       0x141488e80
0000000141488ed9  0f28e9                   movaps   xmm5, xmm1
0000000141488edc  0f54eb                   andps    xmm5, xmm3
0000000141488edf  f3410f5fdb               maxss    xmm3, xmm11
0000000141488ee4  0f28d1                   movaps   xmm2, xmm1
0000000141488ee7  0f55d3                   andnps   xmm2, xmm3
0000000141488eea  0f56d5                   orps     xmm2, xmm5
0000000141488eed  410f28da                 movaps   xmm3, xmm10
0000000141488ef1  f3410fc2da03             cmpunordss xmm3, xmm10
0000000141488ef7  0f28eb                   movaps   xmm5, xmm3
0000000141488efa  0f54ec                   andps    xmm5, xmm4
0000000141488efd  f3410f5de2               minss    xmm4, xmm10
0000000141488f02  0f55dc                   andnps   xmm3, xmm4
0000000141488f05  0f56dd                   orps     xmm3, xmm5
0000000141488f08  0f2ed3                   ucomiss  xmm2, xmm3
0000000141488f0b  0f836fffffff             jae      0x141488e80
0000000141488f11  0f28e3                   movaps   xmm4, xmm3
0000000141488f14  f30f5ce2                 subss    xmm4, xmm2
0000000141488f18  66410f7ee2               movd     r10d, xmm4
0000000141488f1d  4589cb                   mov      r11d, r9d
0000000141488f20  41c1fb1f                 sar      r11d, 0x1f
0000000141488f24  41d1eb                   shr      r11d, 1
0000000141488f27  4531cb                   xor      r11d, r9d
0000000141488f2a  4589d7                   mov      r15d, r10d
0000000141488f2d  41c1ff1f                 sar      r15d, 0x1f
0000000141488f31  41d1ef                   shr      r15d, 1
0000000141488f34  4531d7                   xor      r15d, r10d
0000000141488f37  4539fb                   cmp      r11d, r15d
0000000141488f3a  4c0f4ef0                 cmovle   r14, rax
0000000141488f3e  0f8f2affffff             jg       0x141488e6e
0000000141488f44  440f28e2                 movaps   xmm12, xmm2
0000000141488f48  440f28eb                 movaps   xmm13, xmm3
0000000141488f4c  e91dffffff               jmp      0x141488e6e
0000000141488f51  4c89642448               mov      qword ptr [rsp + 0x48], r12
0000000141488f56  4939de                   cmp      r14, rbx
0000000141488f59  0f83c9040000             jae      0x141489428
0000000141488f5f  4b8d04b6                 lea      rax, [r14 + r14*4]
0000000141488f63  f3410f1074c010           movss    xmm6, dword ptr [r8 + rax*8 + 0x10]
0000000141488f6a  f2450f107cc014           movsd    xmm15, qword ptr [r8 + rax*8 + 0x14]
0000000141488f71  f3450f1074c01c           movss    xmm14, dword ptr [r8 + rax*8 + 0x1c]
0000000141488f78  410fb64cc020             movzx    ecx, byte ptr [r8 + rax*8 + 0x20]
0000000141488f7e  884c2426                 mov      byte ptr [rsp + 0x26], cl
0000000141488f82  498b0cc0                 mov      rcx, qword ptr [r8 + rax*8]
0000000141488f86  48894c2438               mov      qword ptr [rsp + 0x38], rcx
0000000141488f8b  498b4cc008               mov      rcx, qword ptr [r8 + rax*8 + 8]
0000000141488f90  48894c2430               mov      qword ptr [rsp + 0x30], rcx
0000000141488f95  4939fe                   cmp      r14, rdi
0000000141488f98  4989fc                   mov      r12, rdi
0000000141488f9b  4d0f47e6                 cmova    r12, r14
0000000141488f9f  410fb644c021             movzx    eax, byte ptr [r8 + rax*8 + 0x21]
0000000141488fa5  88442425                 mov      byte ptr [rsp + 0x25], al
0000000141488fa9  4c0f43f7                 cmovae   r14, rdi
0000000141488fad  4b8d04a4                 lea      rax, [r12 + r12*4]
0000000141488fb1  498d0cc0                 lea      rcx, [r8 + rax*8]
0000000141488fb5  498b14c0                 mov      rdx, qword ptr [r8 + rax*8]
0000000141488fb9  4889542440               mov      qword ptr [rsp + 0x40], rdx
0000000141488fbe  498d14c0                 lea      rdx, [r8 + rax*8]
0000000141488fc2  4883c228                 add      rdx, 0x28
0000000141488fc6  4c89e0                   mov      rax, r12
0000000141488fc9  48f7d0                   not      rax
0000000141488fcc  4801d8                   add      rax, rbx
0000000141488fcf  48c1e003                 shl      rax, 3
0000000141488fd3  4c8d0480                 lea      r8, [rax + rax*4]
0000000141488fd7  e894979a01               call     0x142e32770 ; memmove
0000000141488fdc  4c8d7bff                 lea      r15, [rbx - 1]
0000000141488fe0  4c897e10                 mov      qword ptr [rsi + 0x10], r15
0000000141488fe4  48837c244002             cmp      qword ptr [rsp + 0x40], 2
0000000141488fea  0f845f040000             je       0x14148944f
0000000141488ff0  4d39fe                   cmp      r14, r15
0000000141488ff3  0f836b040000             jae      0x141489464
0000000141488ff9  488b4608                 mov      rax, qword ptr [rsi + 8]
0000000141488ffd  4b8d14b6                 lea      rdx, [r14 + r14*4]
0000000141489001  488d0cd0                 lea      rcx, [rax + rdx*8]
0000000141489005  4c8b24d0                 mov      r12, qword ptr [rax + rdx*8]
0000000141489009  488d14d0                 lea      rdx, [rax + rdx*8]
000000014148900d  4883c228                 add      rdx, 0x28
0000000141489011  4c89f0                   mov      rax, r14
0000000141489014  48f7d0                   not      rax
0000000141489017  4c01f8                   add      rax, r15
000000014148901a  48c1e003                 shl      rax, 3
000000014148901e  4c8d0480                 lea      r8, [rax + rax*4]
0000000141489022  e849979a01               call     0x142e32770 ; memmove
0000000141489027  4883c3fe                 add      rbx, -2
000000014148902b  48895e10                 mov      qword ptr [rsi + 0x10], rbx
000000014148902f  4983fc02                 cmp      r12, 2
0000000141489033  0f8428040000             je       0x141489461
0000000141489039  440f2ee6                 ucomiss  xmm12, xmm6
000000014148903d  4c8b642448               mov      r12, qword ptr [rsp + 0x48]
0000000141489042  440fb6442424             movzx    r8d, byte ptr [rsp + 0x24]
0000000141489048  766c                     jbe      0x1414890b6
000000014148904a  483b1e                   cmp      rbx, qword ptr [rsi]
000000014148904d  750e                     jne      0x14148905d
000000014148904f  4889f1                   mov      rcx, rsi
0000000141489052  e8895d8f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141489057  440fb6442424             movzx    r8d, byte ptr [rsp + 0x24]
000000014148905d  488b4608                 mov      rax, qword ptr [rsi + 8]
0000000141489061  488d0c9b                 lea      rcx, [rbx + rbx*4]
0000000141489065  488b542438               mov      rdx, qword ptr [rsp + 0x38]
000000014148906a  488914c8                 mov      qword ptr [rax + rcx*8], rdx
000000014148906e  488b542430               mov      rdx, qword ptr [rsp + 0x30]
0000000141489073  488954c808               mov      qword ptr [rax + rcx*8 + 8], rdx
0000000141489078  f30f1174c810             movss    dword ptr [rax + rcx*8 + 0x10], xmm6
000000014148907e  f3440f117cc814           movss    dword ptr [rax + rcx*8 + 0x14], xmm15
0000000141489085  f3440f1164c818           movss    dword ptr [rax + rcx*8 + 0x18], xmm12
000000014148908c  f3440f1174c81c           movss    dword ptr [rax + rcx*8 + 0x1c], xmm14
0000000141489093  0fb6542426               movzx    edx, byte ptr [rsp + 0x26]
0000000141489098  8854c820                 mov      byte ptr [rax + rcx*8 + 0x20], dl
000000014148909c  0fb6542425               movzx    edx, byte ptr [rsp + 0x25]
00000001414890a1  8854c821                 mov      byte ptr [rax + rcx*8 + 0x21], dl
00000001414890a5  4c897e10                 mov      qword ptr [rsi + 0x10], r15
00000001414890a9  f3410f16c7               movshdup xmm0, xmm15
00000001414890ae  410f2ec5                 ucomiss  xmm0, xmm13
00000001414890b2  7710                     ja       0x1414890c4
00000001414890b4  eb69                     jmp      0x14148911f
00000001414890b6  4989df                   mov      r15, rbx
00000001414890b9  f3410f16c7               movshdup xmm0, xmm15
00000001414890be  410f2ec5                 ucomiss  xmm0, xmm13
00000001414890c2  765b                     jbe      0x14148911f
00000001414890c4  4c3b3e                   cmp      r15, qword ptr [rsi]
00000001414890c7  750e                     jne      0x1414890d7
00000001414890c9  4889f1                   mov      rcx, rsi
00000001414890cc  e80f5d8f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
00000001414890d1  440fb6442424             movzx    r8d, byte ptr [rsp + 0x24]
00000001414890d7  488b4608                 mov      rax, qword ptr [rsi + 8]
00000001414890db  4b8d0cbf                 lea      rcx, [r15 + r15*4]
00000001414890df  488b542438               mov      rdx, qword ptr [rsp + 0x38]
00000001414890e4  488914c8                 mov      qword ptr [rax + rcx*8], rdx
00000001414890e8  488b542430               mov      rdx, qword ptr [rsp + 0x30]
00000001414890ed  488954c808               mov      qword ptr [rax + rcx*8 + 8], rdx
00000001414890f2  f3440f116cc810           movss    dword ptr [rax + rcx*8 + 0x10], xmm13
00000001414890f9  440f137cc814             movlps   qword ptr [rax + rcx*8 + 0x14], xmm15
00000001414890ff  f3440f1174c81c           movss    dword ptr [rax + rcx*8 + 0x1c], xmm14
0000000141489106  0fb6542426               movzx    edx, byte ptr [rsp + 0x26]
000000014148910b  8854c820                 mov      byte ptr [rax + rcx*8 + 0x20], dl
000000014148910f  0fb6542425               movzx    edx, byte ptr [rsp + 0x25]
0000000141489114  8854c821                 mov      byte ptr [rax + rcx*8 + 0x21], dl
0000000141489118  49ffc7                   inc      r15
000000014148911b  4c897e10                 mov      qword ptr [rsi + 0x10], r15
000000014148911f  450f2edc                 ucomiss  xmm11, xmm12
0000000141489123  0f82d4000000             jb       0x1414891fd
0000000141489129  450f2eea                 ucomiss  xmm13, xmm10
000000014148912d  0f822a010000             jb       0x14148925d
0000000141489133  4c3b3e                   cmp      r15, qword ptr [rsi]
0000000141489136  750e                     jne      0x141489146
0000000141489138  4889f1                   mov      rcx, rsi
000000014148913b  e8a05c8f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141489140  440fb6442424             movzx    r8d, byte ptr [rsp + 0x24]
0000000141489146  410f28c1                 movaps   xmm0, xmm9
000000014148914a  f3410fc2c103             cmpunordss xmm0, xmm9
0000000141489150  0f28c8                   movaps   xmm1, xmm0
0000000141489153  410f54cf                 andps    xmm1, xmm15
0000000141489157  f3450f5df9               minss    xmm15, xmm9
000000014148915c  410f55c7                 andnps   xmm0, xmm15
0000000141489160  0f56c1                   orps     xmm0, xmm1
0000000141489163  410f28c8                 movaps   xmm1, xmm8
0000000141489167  f3410fc2c803             cmpunordss xmm1, xmm8
000000014148916d  0f28d1                   movaps   xmm2, xmm1
0000000141489170  410f54d6                 andps    xmm2, xmm14
0000000141489174  f3450f5ff0               maxss    xmm14, xmm8
0000000141489179  410f55ce                 andnps   xmm1, xmm14
000000014148917d  0f56ca                   orps     xmm1, xmm2
0000000141489180  4180e501                 and      r13b, 1
0000000141489184  4180e001                 and      r8b, 1
0000000141489188  488b4608                 mov      rax, qword ptr [rsi + 8]
000000014148918c  4b8d0cbf                 lea      rcx, [r15 + r15*4]
0000000141489190  488b542428               mov      rdx, qword ptr [rsp + 0x28]
0000000141489195  488914c8                 mov      qword ptr [rax + rcx*8], rdx
0000000141489199  48896cc808               mov      qword ptr [rax + rcx*8 + 8], rbp
000000014148919e  f3440f1164c810           movss    dword ptr [rax + rcx*8 + 0x10], xmm12
00000001414891a5  f30f1144c814             movss    dword ptr [rax + rcx*8 + 0x14], xmm0
00000001414891ab  f3440f116cc818           movss    dword ptr [rax + rcx*8 + 0x18], xmm13
00000001414891b2  f30f114cc81c             movss    dword ptr [rax + rcx*8 + 0x1c], xmm1
00000001414891b8  44886cc820               mov      byte ptr [rax + rcx*8 + 0x20], r13b
00000001414891bd  448844c821               mov      byte ptr [rax + rcx*8 + 0x21], r8b
00000001414891c2  498d5f01                 lea      rbx, [r15 + 1]
00000001414891c6  48895e10                 mov      qword ptr [rsi + 0x10], rbx
00000001414891ca  4981fcff030000           cmp      r12, 0x3ff
00000001414891d1  0f84e2000000             je       0x1414892b9
00000001414891d7  49ffc4                   inc      r12
00000001414891da  4883ef02                 sub      rdi, 2
00000001414891de  b800000000               mov      eax, 0
00000001414891e3  480f42f8                 cmovb    rdi, rax
00000001414891e7  4c39ff                   cmp      rdi, r15
00000001414891ea  f30f1035e61f9b01         movss    xmm6, dword ptr [rip + 0x19b1fe6]
00000001414891f2  0f8684faffff             jbe      0x141488c7c
00000001414891f8  e96c010000               jmp      0x141489369
00000001414891fd  4c3b3e                   cmp      r15, qword ptr [rsi]
0000000141489200  750e                     jne      0x141489210
0000000141489202  4889f1                   mov      rcx, rsi
0000000141489205  e8d65b8f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
000000014148920a  440fb6442424             movzx    r8d, byte ptr [rsp + 0x24]
0000000141489210  488b4608                 mov      rax, qword ptr [rsi + 8]
0000000141489214  4b8d0cbf                 lea      rcx, [r15 + r15*4]
0000000141489218  488b542428               mov      rdx, qword ptr [rsp + 0x28]
000000014148921d  488914c8                 mov      qword ptr [rax + rcx*8], rdx
0000000141489221  48896cc808               mov      qword ptr [rax + rcx*8 + 8], rbp
0000000141489226  f3440f115cc810           movss    dword ptr [rax + rcx*8 + 0x10], xmm11
000000014148922d  f3440f114cc814           movss    dword ptr [rax + rcx*8 + 0x14], xmm9
0000000141489234  f3440f1164c818           movss    dword ptr [rax + rcx*8 + 0x18], xmm12
000000014148923b  f3440f1144c81c           movss    dword ptr [rax + rcx*8 + 0x1c], xmm8
0000000141489242  44886cc820               mov      byte ptr [rax + rcx*8 + 0x20], r13b
0000000141489247  448844c821               mov      byte ptr [rax + rcx*8 + 0x21], r8b
000000014148924c  49ffc7                   inc      r15
000000014148924f  4c897e10                 mov      qword ptr [rsi + 0x10], r15
0000000141489253  450f2eea                 ucomiss  xmm13, xmm10
0000000141489257  0f83d6feffff             jae      0x141489133
000000014148925d  4c3b3e                   cmp      r15, qword ptr [rsi]
0000000141489260  750e                     jne      0x141489270
0000000141489262  4889f1                   mov      rcx, rsi
0000000141489265  e8765b8f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
000000014148926a  440fb6442424             movzx    r8d, byte ptr [rsp + 0x24]
0000000141489270  488b4608                 mov      rax, qword ptr [rsi + 8]
0000000141489274  4b8d0cbf                 lea      rcx, [r15 + r15*4]
0000000141489278  488b542428               mov      rdx, qword ptr [rsp + 0x28]
000000014148927d  488914c8                 mov      qword ptr [rax + rcx*8], rdx
0000000141489281  48896cc808               mov      qword ptr [rax + rcx*8 + 8], rbp
0000000141489286  f3440f116cc810           movss    dword ptr [rax + rcx*8 + 0x10], xmm13
000000014148928d  440f134cc814             movlps   qword ptr [rax + rcx*8 + 0x14], xmm9
0000000141489293  f3440f1144c81c           movss    dword ptr [rax + rcx*8 + 0x1c], xmm8
000000014148929a  44886cc820               mov      byte ptr [rax + rcx*8 + 0x20], r13b
000000014148929f  448844c821               mov      byte ptr [rax + rcx*8 + 0x21], r8b
00000001414892a4  49ffc7                   inc      r15
00000001414892a7  4c897e10                 mov      qword ptr [rsi + 0x10], r15
00000001414892ab  4c3b3e                   cmp      r15, qword ptr [rsi]
00000001414892ae  0f8484feffff             je       0x141489138
00000001414892b4  e98dfeffff               jmp      0x141489146
00000001414892b9  488b05d0fb8102           mov      rax, qword ptr [rip + 0x281fbd0]
00000001414892c0  488b00                   mov      rax, qword ptr [rax]
00000001414892c3  4883f802                 cmp      rax, 2
00000001414892c7  0f829c000000             jb       0x141489369
00000001414892cd  48c744245000000000       mov      qword ptr [rsp + 0x50], 0
00000001414892d6  488d05ea3ee801           lea      rax, [rip + 0x1e83eea] ; 'system_wall_constructor::construct_wooden_walls::construct_wall_boards'
00000001414892dd  4889442458               mov      qword ptr [rsp + 0x58], rax
00000001414892e2  48c744246046000000       mov      qword ptr [rsp + 0x60], 0x46
00000001414892eb  48c744246800000000       mov      qword ptr [rsp + 0x68], 0
00000001414892f4  488d0dbd3de801           lea      rcx, [rip + 0x1e83dbd] ; 'crates/systems/wall-constructor/src/construct_wooden_walls/construct_wall_boards.rs'
00000001414892fb  48894c2470               mov      qword ptr [rsp + 0x70], rcx
0000000141489300  48c744247853000000       mov      qword ptr [rsp + 0x78], 0x53
0000000141489309  48c784248000000002000000 mov      qword ptr [rsp + 0x80], 2
0000000141489315  4889842488000000         mov      qword ptr [rsp + 0x88], rax
000000014148931d  48c784249000000046000000 mov      qword ptr [rsp + 0x90], 0x46
0000000141489329  48b80100000039090000     movabs   rax, 0x93900000001
0000000141489333  4889842498000000         mov      qword ptr [rsp + 0x98], rax
000000014148933b  488d05763fe801           lea      rax, [rip + 0x1e83f76] ; 'merge_narrow_planks_horizontal reached merge limit'
0000000141489342  48898424a0000000         mov      qword ptr [rsp + 0xa0], rax
000000014148934a  48c78424a800000065000000 mov      qword ptr [rsp + 0xa8], 0x65
0000000141489356  488d4c2427               lea      rcx, [rsp + 0x27]
000000014148935b  488d542450               lea      rdx, [rsp + 0x50]
0000000141489360  e88b9faaff               call     0x140f332f0 ; log::__private_api::impl$2::log | _ZN61_$LT$log..__private_api..GlobalLogger$u20$as$u20$log..Log$GT$3log17h18d828029531af6fE
0000000141489365  488b5e10                 mov      rbx, qword ptr [rsi + 0x10]
0000000141489369  488b7608                 mov      rsi, qword ptr [rsi + 8]
000000014148936d  488d442427               lea      rax, [rsp + 0x27]
0000000141489372  4889442450               mov      qword ptr [rsp + 0x50], rax
0000000141489377  4883fb02                 cmp      rbx, 2
000000014148937b  736c                     jae      0x1414893e9
000000014148937d  0f28b424b0000000         movaps   xmm6, xmmword ptr [rsp + 0xb0]
0000000141489385  0f28bc24c0000000         movaps   xmm7, xmmword ptr [rsp + 0xc0]
000000014148938d  440f288424d0000000       movaps   xmm8, xmmword ptr [rsp + 0xd0]
0000000141489396  440f288c24e0000000       movaps   xmm9, xmmword ptr [rsp + 0xe0]
000000014148939f  440f289424f0000000       movaps   xmm10, xmmword ptr [rsp + 0xf0]
00000001414893a8  440f289c2400010000       movaps   xmm11, xmmword ptr [rsp + 0x100]
00000001414893b1  440f28a42410010000       movaps   xmm12, xmmword ptr [rsp + 0x110]
00000001414893ba  440f28ac2420010000       movaps   xmm13, xmmword ptr [rsp + 0x120]
00000001414893c3  440f28b42430010000       movaps   xmm14, xmmword ptr [rsp + 0x130]
00000001414893cc  440f28bc2440010000       movaps   xmm15, xmmword ptr [rsp + 0x140]
00000001414893d5  4881c458010000           add      rsp, 0x158
00000001414893dc  5b                       pop      rbx
00000001414893dd  5d                       pop      rbp
00000001414893de  5f                       pop      rdi
00000001414893df  5e                       pop      rsi
00000001414893e0  415c                     pop      r12
00000001414893e2  415d                     pop      r13
00000001414893e4  415e                     pop      r14
00000001414893e6  415f                     pop      r15
00000001414893e8  c3                       ret      
00000001414893e9  4883fb15                 cmp      rbx, 0x15
00000001414893ed  734b                     jae      0x14148943a
00000001414893ef  48c1e303                 shl      rbx, 3
00000001414893f3  488d3c9b                 lea      rdi, [rbx + rbx*4]
00000001414893f7  bb28000000               mov      ebx, 0x28
00000001414893fc  488d141e                 lea      rdx, [rsi + rbx]
0000000141489400  4889f1                   mov      rcx, rsi
0000000141489403  e8d81cfdff               call     0x14145b0e0 ; _ZN4core5slice4sort6shared9smallsort11insert_tail17h5e16c08b2baa4f9bE.llvm.7236408601036147505 | _ZN4core5slice4sort6shared9smallsort11insert_tail17h7b700fd9418c4a76E.llvm.7236408601036147505
0000000141489408  4883c328                 add      rbx, 0x28
000000014148940c  4839df                   cmp      rdi, rbx
000000014148940f  75eb                     jne      0x1414893fc
0000000141489411  e967ffffff               jmp      0x14148937d
0000000141489416  4c8d056b3ee801           lea      r8, [rip + 0x1e83e6b]
000000014148941d  4889f9                   mov      rcx, rdi
0000000141489420  4889da                   mov      rdx, rbx
0000000141489423  e8caed9301               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
0000000141489428  4c8d05713ee801           lea      r8, [rip + 0x1e83e71]
000000014148942f  4c89f1                   mov      rcx, r14
0000000141489432  4889da                   mov      rdx, rbx
0000000141489435  e8b8ed9301               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
000000014148943a  4c8d442450               lea      r8, [rsp + 0x50]
000000014148943f  4889f1                   mov      rcx, rsi
0000000141489442  4889da                   mov      rdx, rbx
0000000141489445  e8b6bffdff               call     0x141465400 ; _ZN4core5slice4sort6stable14driftsort_main17h05dedffe9a33190eE | _ZN4core5slice4sort6stable14driftsort_main17h6919b7a8be3b8545E
000000014148944a  e92effffff               jmp      0x14148937d
000000014148944f  4c8d05ba3de801           lea      r8, [rip + 0x1e83dba]
0000000141489456  4c89e1                   mov      rcx, r12
0000000141489459  4c89fa                   mov      rdx, r15
000000014148945c  e897ea9301               call     0x142dc7ef8 ; alloc::vec::impl$1::remove::assert_failed | _RNvNvMs_NtCs1f2BdUxKfgg_5alloc3vecINtB6_3VecppE6remove13assert_failed
0000000141489461  4989df                   mov      r15, rbx
0000000141489464  4c8d05bd3de801           lea      r8, [rip + 0x1e83dbd]
000000014148946b  4c89f1                   mov      rcx, r14
000000014148946e  4c89fa                   mov      rdx, r15
0000000141489471  e882ea9301               call     0x142dc7ef8 ; alloc::vec::impl$1::remove::assert_failed | _RNvNvMs_NtCs1f2BdUxKfgg_5alloc3vecINtB6_3VecppE6remove13assert_failed
0000000141489476  cc                       int3     