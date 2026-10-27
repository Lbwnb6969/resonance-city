0000000141484710  55                       push     rbp
0000000141484711  4157                     push     r15
0000000141484713  4156                     push     r14
0000000141484715  4155                     push     r13
0000000141484717  4154                     push     r12
0000000141484719  56                       push     rsi
000000014148471a  57                       push     rdi
000000014148471b  53                       push     rbx
000000014148471c  4881ecc8010000           sub      rsp, 0x1c8
0000000141484723  488dac2480000000         lea      rbp, [rsp + 0x80]
000000014148472b  440f29bd30010000         movaps   xmmword ptr [rbp + 0x130], xmm15
0000000141484733  440f29b520010000         movaps   xmmword ptr [rbp + 0x120], xmm14
000000014148473b  440f29ad10010000         movaps   xmmword ptr [rbp + 0x110], xmm13
0000000141484743  440f29a500010000         movaps   xmmword ptr [rbp + 0x100], xmm12
000000014148474b  440f299df0000000         movaps   xmmword ptr [rbp + 0xf0], xmm11
0000000141484753  440f2995e0000000         movaps   xmmword ptr [rbp + 0xe0], xmm10
000000014148475b  440f298dd0000000         movaps   xmmword ptr [rbp + 0xd0], xmm9
0000000141484763  440f2985c0000000         movaps   xmmword ptr [rbp + 0xc0], xmm8
000000014148476b  0f29bdb0000000           movaps   xmmword ptr [rbp + 0xb0], xmm7
0000000141484772  0f29b5a0000000           movaps   xmmword ptr [rbp + 0xa0], xmm6
0000000141484779  48c78598000000feffffff   mov      qword ptr [rbp + 0x98], 0xfffffffffffffffe
0000000141484784  4885d2                   test     rdx, rdx
0000000141484787  0f84bf080000             je       0x14148504c
000000014148478d  4c89c6                   mov      rsi, r8
0000000141484790  48c1e204                 shl      rdx, 4
0000000141484794  4801ca                   add      rdx, rcx
0000000141484797  4c8d6dd8                 lea      r13, [rbp - 0x28]
000000014148479b  4c8d7de0                 lea      r15, [rbp - 0x20]
000000014148479f  48b83033333333333303     movabs   rax, 0x333333333333330
00000001414847a9  4c8d6520                 lea      r12, [rbp + 0x20]
00000001414847ad  0f57f6                   xorps    xmm6, xmm6
00000001414847b0  4531c0                   xor      r8d, r8d
00000001414847b3  4983f810                 cmp      r8, 0x10
00000001414847b7  0f848f080000             je       0x14148504c
00000001414847bd  44888d96000000           mov      byte ptr [rbp + 0x96], r9b
00000001414847c4  0f1001                   movups   xmm0, xmmword ptr [rcx]
00000001414847c7  0f294520                 movaps   xmmword ptr [rbp + 0x20], xmm0
00000001414847cb  488b7e10                 mov      rdi, qword ptr [rsi + 0x10]
00000001414847cf  4839c7                   cmp      rdi, rax
00000001414847d2  0f87d6080000             ja       0x1414850ae
00000001414847d8  49ffc0                   inc      r8
00000001414847db  4531c9                   xor      r9d, r9d
00000001414847de  48894d08                 mov      qword ptr [rbp + 8], rcx
00000001414847e2  488955f8                 mov      qword ptr [rbp - 8], rdx
00000001414847e6  4c894500                 mov      qword ptr [rbp], r8
00000001414847ea  48894d10                 mov      qword ptr [rbp + 0x10], rcx
00000001414847ee  44894d30                 mov      dword ptr [rbp + 0x30], r9d
00000001414847f2  488d04fd18000000         lea      rax, [rdi*8 + 0x18]
00000001414847fa  488d1c80                 lea      rbx, [rax + rax*4]
00000001414847fe  e85da6bffe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
0000000141484803  41be08000000             mov      r14d, 8
0000000141484809  ba08000000               mov      edx, 8
000000014148480e  4889d9                   mov      rcx, rbx
0000000141484811  e89a7222ff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
0000000141484816  4885c0                   test     rax, rax
0000000141484819  0f8496080000             je       0x1414850b5
000000014148481f  4883451010               add      qword ptr [rbp + 0x10], 0x10
0000000141484824  4883c703                 add      rdi, 3
0000000141484828  48897d48                 mov      qword ptr [rbp + 0x48], rdi
000000014148482c  48894518                 mov      qword ptr [rbp + 0x18], rax
0000000141484830  48894550                 mov      qword ptr [rbp + 0x50], rax
0000000141484834  48c7455800000000         mov      qword ptr [rbp + 0x58], 0
000000014148483c  488b5608                 mov      rdx, qword ptr [rsi + 8]
0000000141484840  488b4610                 mov      rax, qword ptr [rsi + 0x10]
0000000141484844  48c7461000000000         mov      qword ptr [rsi + 0x10], 0
000000014148484c  488d0c80                 lea      rcx, [rax + rax*4]
0000000141484850  488d1cca                 lea      rbx, [rdx + rcx*8]
0000000141484854  488955a8                 mov      qword ptr [rbp - 0x58], rdx
0000000141484858  48895db0                 mov      qword ptr [rbp - 0x50], rbx
000000014148485c  488975b8                 mov      qword ptr [rbp - 0x48], rsi
0000000141484860  488945c0                 mov      qword ptr [rbp - 0x40], rax
0000000141484864  48c745c800000000         mov      qword ptr [rbp - 0x38], 0
000000014148486c  c7453400000000           mov      dword ptr [rbp + 0x34], 0
0000000141484873  4889d0                   mov      rax, rdx
0000000141484876  eb35                     jmp      0x1414848ad
0000000141484878  0f1f840000000000         nop      dword ptr [rax + rax]
0000000141484880  488b4550                 mov      rax, qword ptr [rbp + 0x50]
0000000141484884  488d0cbf                 lea      rcx, [rdi + rdi*4]
0000000141484888  0f1045d0                 movups   xmm0, xmmword ptr [rbp - 0x30]
000000014148488c  0f104de0                 movups   xmm1, xmmword ptr [rbp - 0x20]
0000000141484890  488b55f0                 mov      rdx, qword ptr [rbp - 0x10]
0000000141484894  488954c820               mov      qword ptr [rax + rcx*8 + 0x20], rdx
0000000141484899  0f114cc810               movups   xmmword ptr [rax + rcx*8 + 0x10], xmm1
000000014148489e  0f1104c8                 movups   xmmword ptr [rax + rcx*8], xmm0
00000001414848a2  48ffc7                   inc      rdi
00000001414848a5  48897d58                 mov      qword ptr [rbp + 0x58], rdi
00000001414848a9  488b4538                 mov      rax, qword ptr [rbp + 0x38]
00000001414848ad  4839d8                   cmp      rax, rbx
00000001414848b0  0f840a070000             je       0x141484fc0
00000001414848b6  4c8b30                   mov      r14, qword ptr [rax]
00000001414848b9  4983fe02                 cmp      r14, 2
00000001414848bd  0f84fd060000             je       0x141484fc0
00000001414848c3  488d4828                 lea      rcx, [rax + 0x28]
00000001414848c7  48894d38                 mov      qword ptr [rbp + 0x38], rcx
00000001414848cb  4c8975d0                 mov      qword ptr [rbp - 0x30], r14
00000001414848cf  0f104008                 movups   xmm0, xmmword ptr [rax + 8]
00000001414848d3  0f104818                 movups   xmm1, xmmword ptr [rax + 0x18]
00000001414848d7  410f114d10               movups   xmmword ptr [r13 + 0x10], xmm1
00000001414848dc  410f114500               movups   xmmword ptr [r13], xmm0
00000001414848e1  4c89f9                   mov      rcx, r15
00000001414848e4  4c89e2                   mov      rdx, r12
00000001414848e7  e8a4a296ff               call     0x140deeb90 ; utils::geometry::aabb::Aabb2::intersects_non_inclusive | _ZN5utils8geometry4aabb5Aabb224intersects_non_inclusive17h2284a53ff0aa838dE
00000001414848ec  90                       nop      
00000001414848ed  84c0                     test     al, al
00000001414848ef  751f                     jne      0x141484910
00000001414848f1  488b7d58                 mov      rdi, qword ptr [rbp + 0x58]
00000001414848f5  483b7d48                 cmp      rdi, qword ptr [rbp + 0x48]
00000001414848f9  7585                     jne      0x141484880
00000001414848fb  488d4d48                 lea      rcx, [rbp + 0x48]
00000001414848ff  e8dca48f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141484904  90                       nop      
0000000141484905  e976ffffff               jmp      0x141484880
000000014148490a  660f1f440000             nop      word ptr [rax + rax]
0000000141484910  488b45d8                 mov      rax, qword ptr [rbp - 0x28]
0000000141484914  48894540                 mov      qword ptr [rbp + 0x40], rax
0000000141484918  f20f107de0               movsd    xmm7, qword ptr [rbp - 0x20]
000000014148491d  f3440f16e7               movshdup xmm12, xmm7
0000000141484922  f2440f104de8             movsd    xmm9, qword ptr [rbp - 0x18]
0000000141484928  f3450f16c1               movshdup xmm8, xmm9
000000014148492d  0fb645f0                 movzx    eax, byte ptr [rbp - 0x10]
0000000141484931  888597000000             mov      byte ptr [rbp + 0x97], al
0000000141484937  f3440f107520             movss    xmm14, dword ptr [rbp + 0x20]
000000014148493d  f3440f107d24             movss    xmm15, dword ptr [rbp + 0x24]
0000000141484943  f3440f105d28             movss    xmm11, dword ptr [rbp + 0x28]
0000000141484949  f3440f10552c             movss    xmm10, dword ptr [rbp + 0x2c]
000000014148494f  80bd9600000000           cmp      byte ptr [rbp + 0x96], 0
0000000141484956  0f842b030000             je       0x141484c87
000000014148495c  450f2efc                 ucomiss  xmm15, xmm12
0000000141484960  0f86a6000000             jbe      0x141484a0c
0000000141484966  410f28c7                 movaps   xmm0, xmm15
000000014148496a  f3410fc2c703             cmpunordss xmm0, xmm15
0000000141484970  0f28c8                   movaps   xmm1, xmm0
0000000141484973  410f54c8                 andps    xmm1, xmm8
0000000141484977  410f28d0                 movaps   xmm2, xmm8
000000014148497b  f3410f5dd7               minss    xmm2, xmm15
0000000141484980  0f55c2                   andnps   xmm0, xmm2
0000000141484983  0f56c1                   orps     xmm0, xmm1
0000000141484986  0f137d70                 movlps   qword ptr [rbp + 0x70], xmm7
000000014148498a  f3440f114d78             movss    dword ptr [rbp + 0x78], xmm9
0000000141484990  f30f11457c               movss    dword ptr [rbp + 0x7c], xmm0
0000000141484995  4c897560                 mov      qword ptr [rbp + 0x60], r14
0000000141484999  488b4540                 mov      rax, qword ptr [rbp + 0x40]
000000014148499d  48894568                 mov      qword ptr [rbp + 0x68], rax
00000001414849a1  0fb68597000000           movzx    eax, byte ptr [rbp + 0x97]
00000001414849a8  888580000000             mov      byte ptr [rbp + 0x80], al
00000001414849ae  488d4d70                 lea      rcx, [rbp + 0x70]
00000001414849b2  e859a296ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
00000001414849b7  90                       nop      
00000001414849b8  0f2ec6                   ucomiss  xmm0, xmm6
00000001414849bb  764f                     jbe      0x141484a0c
00000001414849bd  488d4d70                 lea      rcx, [rbp + 0x70]
00000001414849c1  e88aa296ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
00000001414849c6  90                       nop      
00000001414849c7  0f2ec6                   ucomiss  xmm0, xmm6
00000001414849ca  7640                     jbe      0x141484a0c
00000001414849cc  488b7d58                 mov      rdi, qword ptr [rbp + 0x58]
00000001414849d0  483b7d48                 cmp      rdi, qword ptr [rbp + 0x48]
00000001414849d4  750a                     jne      0x1414849e0
00000001414849d6  488d4d48                 lea      rcx, [rbp + 0x48]
00000001414849da  e801a48f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
00000001414849df  90                       nop      
00000001414849e0  488b4550                 mov      rax, qword ptr [rbp + 0x50]
00000001414849e4  488d0cbf                 lea      rcx, [rdi + rdi*4]
00000001414849e8  0f104560                 movups   xmm0, xmmword ptr [rbp + 0x60]
00000001414849ec  0f104d70                 movups   xmm1, xmmword ptr [rbp + 0x70]
00000001414849f0  488b9580000000           mov      rdx, qword ptr [rbp + 0x80]
00000001414849f7  488954c820               mov      qword ptr [rax + rcx*8 + 0x20], rdx
00000001414849fc  0f114cc810               movups   xmmword ptr [rax + rcx*8 + 0x10], xmm1
0000000141484a01  0f1104c8                 movups   xmmword ptr [rax + rcx*8], xmm0
0000000141484a05  48ffc7                   inc      rdi
0000000141484a08  48897d58                 mov      qword ptr [rbp + 0x58], rdi
0000000141484a0c  450f2ec2                 ucomiss  xmm8, xmm10
0000000141484a10  0f86a6000000             jbe      0x141484abc
0000000141484a16  410f28c2                 movaps   xmm0, xmm10
0000000141484a1a  f3410fc2c203             cmpunordss xmm0, xmm10
0000000141484a20  0f28c8                   movaps   xmm1, xmm0
0000000141484a23  410f54cc                 andps    xmm1, xmm12
0000000141484a27  410f28d4                 movaps   xmm2, xmm12
0000000141484a2b  f3410f5fd2               maxss    xmm2, xmm10
0000000141484a30  0f55c2                   andnps   xmm0, xmm2
0000000141484a33  0f56c1                   orps     xmm0, xmm1
0000000141484a36  f30f117d70               movss    dword ptr [rbp + 0x70], xmm7
0000000141484a3b  f30f114574               movss    dword ptr [rbp + 0x74], xmm0
0000000141484a40  440f134d78               movlps   qword ptr [rbp + 0x78], xmm9
0000000141484a45  4c897560                 mov      qword ptr [rbp + 0x60], r14
0000000141484a49  488b4540                 mov      rax, qword ptr [rbp + 0x40]
0000000141484a4d  48894568                 mov      qword ptr [rbp + 0x68], rax
0000000141484a51  0fb68597000000           movzx    eax, byte ptr [rbp + 0x97]
0000000141484a58  888580000000             mov      byte ptr [rbp + 0x80], al
0000000141484a5e  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484a62  e8a9a196ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
0000000141484a67  90                       nop      
0000000141484a68  0f2ec6                   ucomiss  xmm0, xmm6
0000000141484a6b  764f                     jbe      0x141484abc
0000000141484a6d  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484a71  e8daa196ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
0000000141484a76  90                       nop      
0000000141484a77  0f2ec6                   ucomiss  xmm0, xmm6
0000000141484a7a  7640                     jbe      0x141484abc
0000000141484a7c  488b7d58                 mov      rdi, qword ptr [rbp + 0x58]
0000000141484a80  483b7d48                 cmp      rdi, qword ptr [rbp + 0x48]
0000000141484a84  750a                     jne      0x141484a90
0000000141484a86  488d4d48                 lea      rcx, [rbp + 0x48]
0000000141484a8a  e851a38f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141484a8f  90                       nop      
0000000141484a90  488b4550                 mov      rax, qword ptr [rbp + 0x50]
0000000141484a94  488d0cbf                 lea      rcx, [rdi + rdi*4]
0000000141484a98  0f104560                 movups   xmm0, xmmword ptr [rbp + 0x60]
0000000141484a9c  0f104d70                 movups   xmm1, xmmword ptr [rbp + 0x70]
0000000141484aa0  488b9580000000           mov      rdx, qword ptr [rbp + 0x80]
0000000141484aa7  488954c820               mov      qword ptr [rax + rcx*8 + 0x20], rdx
0000000141484aac  0f114cc810               movups   xmmword ptr [rax + rcx*8 + 0x10], xmm1
0000000141484ab1  0f1104c8                 movups   xmmword ptr [rax + rcx*8], xmm0
0000000141484ab5  48ffc7                   inc      rdi
0000000141484ab8  48897d58                 mov      qword ptr [rbp + 0x58], rdi
0000000141484abc  450f28ec                 movaps   xmm13, xmm12
0000000141484ac0  f3450fc2ec03             cmpunordss xmm13, xmm12
0000000141484ac6  410f28c5                 movaps   xmm0, xmm13
0000000141484aca  410f54c7                 andps    xmm0, xmm15
0000000141484ace  f3450f5ffc               maxss    xmm15, xmm12
0000000141484ad3  450f55ef                 andnps   xmm13, xmm15
0000000141484ad7  440f56e8                 orps     xmm13, xmm0
0000000141484adb  450f28e0                 movaps   xmm12, xmm8
0000000141484adf  f3450fc2e003             cmpunordss xmm12, xmm8
0000000141484ae5  410f28c4                 movaps   xmm0, xmm12
0000000141484ae9  410f54c2                 andps    xmm0, xmm10
0000000141484aed  f3450f5dd0               minss    xmm10, xmm8
0000000141484af2  450f55e2                 andnps   xmm12, xmm10
0000000141484af6  440f56e0                 orps     xmm12, xmm0
0000000141484afa  b001                     mov      al, 1
0000000141484afc  894534                   mov      dword ptr [rbp + 0x34], eax
0000000141484aff  450f2eec                 ucomiss  xmm13, xmm12
0000000141484b03  488b5538                 mov      rdx, qword ptr [rbp + 0x38]
0000000141484b07  0f8366fdffff             jae      0x141484873
0000000141484b0d  440f2ef7                 ucomiss  xmm14, xmm7
0000000141484b11  0f86b1000000             jbe      0x141484bc8
0000000141484b17  410f28c1                 movaps   xmm0, xmm9
0000000141484b1b  f3410f5dc6               minss    xmm0, xmm14
0000000141484b20  f3450fc2f603             cmpunordss xmm14, xmm14
0000000141484b26  410f28ce                 movaps   xmm1, xmm14
0000000141484b2a  410f54c9                 andps    xmm1, xmm9
0000000141484b2e  440f55f0                 andnps   xmm14, xmm0
0000000141484b32  440f56f1                 orps     xmm14, xmm1
0000000141484b36  f30f117d70               movss    dword ptr [rbp + 0x70], xmm7
0000000141484b3b  f3440f116d74             movss    dword ptr [rbp + 0x74], xmm13
0000000141484b41  f3440f117578             movss    dword ptr [rbp + 0x78], xmm14
0000000141484b47  f3440f11657c             movss    dword ptr [rbp + 0x7c], xmm12
0000000141484b4d  4c897560                 mov      qword ptr [rbp + 0x60], r14
0000000141484b51  488b4540                 mov      rax, qword ptr [rbp + 0x40]
0000000141484b55  48894568                 mov      qword ptr [rbp + 0x68], rax
0000000141484b59  0fb68597000000           movzx    eax, byte ptr [rbp + 0x97]
0000000141484b60  888580000000             mov      byte ptr [rbp + 0x80], al
0000000141484b66  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484b6a  e8a1a096ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
0000000141484b6f  90                       nop      
0000000141484b70  0f2ec6                   ucomiss  xmm0, xmm6
0000000141484b73  764f                     jbe      0x141484bc4
0000000141484b75  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484b79  e8d2a096ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
0000000141484b7e  90                       nop      
0000000141484b7f  0f2ec6                   ucomiss  xmm0, xmm6
0000000141484b82  7640                     jbe      0x141484bc4
0000000141484b84  488b7d58                 mov      rdi, qword ptr [rbp + 0x58]
0000000141484b88  483b7d48                 cmp      rdi, qword ptr [rbp + 0x48]
0000000141484b8c  750a                     jne      0x141484b98
0000000141484b8e  488d4d48                 lea      rcx, [rbp + 0x48]
0000000141484b92  e849a28f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141484b97  90                       nop      
0000000141484b98  488b4550                 mov      rax, qword ptr [rbp + 0x50]
0000000141484b9c  488d0cbf                 lea      rcx, [rdi + rdi*4]
0000000141484ba0  0f104560                 movups   xmm0, xmmword ptr [rbp + 0x60]
0000000141484ba4  0f104d70                 movups   xmm1, xmmword ptr [rbp + 0x70]
0000000141484ba8  488b9580000000           mov      rdx, qword ptr [rbp + 0x80]
0000000141484baf  488954c820               mov      qword ptr [rax + rcx*8 + 0x20], rdx
0000000141484bb4  0f114cc810               movups   xmmword ptr [rax + rcx*8 + 0x10], xmm1
0000000141484bb9  0f1104c8                 movups   xmmword ptr [rax + rcx*8], xmm0
0000000141484bbd  48ffc7                   inc      rdi
0000000141484bc0  48897d58                 mov      qword ptr [rbp + 0x58], rdi
0000000141484bc4  488b5538                 mov      rdx, qword ptr [rbp + 0x38]
0000000141484bc8  450f2ecb                 ucomiss  xmm9, xmm11
0000000141484bcc  0f86a1fcffff             jbe      0x141484873
0000000141484bd2  0f28c7                   movaps   xmm0, xmm7
0000000141484bd5  f3410f5fc3               maxss    xmm0, xmm11
0000000141484bda  f3450fc2db03             cmpunordss xmm11, xmm11
0000000141484be0  410f28cb                 movaps   xmm1, xmm11
0000000141484be4  0f54cf                   andps    xmm1, xmm7
0000000141484be7  440f55d8                 andnps   xmm11, xmm0
0000000141484beb  440f56d9                 orps     xmm11, xmm1
0000000141484bef  f3440f115d70             movss    dword ptr [rbp + 0x70], xmm11
0000000141484bf5  f3440f116d74             movss    dword ptr [rbp + 0x74], xmm13
0000000141484bfb  f3440f114d78             movss    dword ptr [rbp + 0x78], xmm9
0000000141484c01  f3440f11657c             movss    dword ptr [rbp + 0x7c], xmm12
0000000141484c07  4c897560                 mov      qword ptr [rbp + 0x60], r14
0000000141484c0b  488b4540                 mov      rax, qword ptr [rbp + 0x40]
0000000141484c0f  48894568                 mov      qword ptr [rbp + 0x68], rax
0000000141484c13  0fb68597000000           movzx    eax, byte ptr [rbp + 0x97]
0000000141484c1a  888580000000             mov      byte ptr [rbp + 0x80], al
0000000141484c20  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484c24  e8e79f96ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
0000000141484c29  90                       nop      
0000000141484c2a  0f2ec6                   ucomiss  xmm0, xmm6
0000000141484c2d  764f                     jbe      0x141484c7e
0000000141484c2f  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484c33  e818a096ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
0000000141484c38  90                       nop      
0000000141484c39  0f2ec6                   ucomiss  xmm0, xmm6
0000000141484c3c  7640                     jbe      0x141484c7e
0000000141484c3e  488b7d58                 mov      rdi, qword ptr [rbp + 0x58]
0000000141484c42  483b7d48                 cmp      rdi, qword ptr [rbp + 0x48]
0000000141484c46  750a                     jne      0x141484c52
0000000141484c48  488d4d48                 lea      rcx, [rbp + 0x48]
0000000141484c4c  e88fa18f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141484c51  90                       nop      
0000000141484c52  488b4550                 mov      rax, qword ptr [rbp + 0x50]
0000000141484c56  488d0cbf                 lea      rcx, [rdi + rdi*4]
0000000141484c5a  0f104560                 movups   xmm0, xmmword ptr [rbp + 0x60]
0000000141484c5e  0f104d70                 movups   xmm1, xmmword ptr [rbp + 0x70]
0000000141484c62  488b9580000000           mov      rdx, qword ptr [rbp + 0x80]
0000000141484c69  488954c820               mov      qword ptr [rax + rcx*8 + 0x20], rdx
0000000141484c6e  0f114cc810               movups   xmmword ptr [rax + rcx*8 + 0x10], xmm1
0000000141484c73  0f1104c8                 movups   xmmword ptr [rax + rcx*8], xmm0
0000000141484c77  48ffc7                   inc      rdi
0000000141484c7a  48897d58                 mov      qword ptr [rbp + 0x58], rdi
0000000141484c7e  488b5538                 mov      rdx, qword ptr [rbp + 0x38]
0000000141484c82  e9ecfbffff               jmp      0x141484873
0000000141484c87  440f2ef7                 ucomiss  xmm14, xmm7
0000000141484c8b  0f86aa000000             jbe      0x141484d3b
0000000141484c91  410f28c6                 movaps   xmm0, xmm14
0000000141484c95  f3410fc2c603             cmpunordss xmm0, xmm14
0000000141484c9b  0f28c8                   movaps   xmm1, xmm0
0000000141484c9e  410f54c9                 andps    xmm1, xmm9
0000000141484ca2  410f28d1                 movaps   xmm2, xmm9
0000000141484ca6  f3410f5dd6               minss    xmm2, xmm14
0000000141484cab  0f55c2                   andnps   xmm0, xmm2
0000000141484cae  0f56c1                   orps     xmm0, xmm1
0000000141484cb1  0f137d70                 movlps   qword ptr [rbp + 0x70], xmm7
0000000141484cb5  f30f114578               movss    dword ptr [rbp + 0x78], xmm0
0000000141484cba  f3440f11457c             movss    dword ptr [rbp + 0x7c], xmm8
0000000141484cc0  4c897560                 mov      qword ptr [rbp + 0x60], r14
0000000141484cc4  488b4540                 mov      rax, qword ptr [rbp + 0x40]
0000000141484cc8  48894568                 mov      qword ptr [rbp + 0x68], rax
0000000141484ccc  0fb68597000000           movzx    eax, byte ptr [rbp + 0x97]
0000000141484cd3  888580000000             mov      byte ptr [rbp + 0x80], al
0000000141484cd9  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484cdd  e82e9f96ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
0000000141484ce2  90                       nop      
0000000141484ce3  0f2ec6                   ucomiss  xmm0, xmm6
0000000141484ce6  7653                     jbe      0x141484d3b
0000000141484ce8  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484cec  e85f9f96ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
0000000141484cf1  90                       nop      
0000000141484cf2  0f2e05db2d9b01           ucomiss  xmm0, dword ptr [rip + 0x19b2ddb]
0000000141484cf9  7240                     jb       0x141484d3b
0000000141484cfb  488b7d58                 mov      rdi, qword ptr [rbp + 0x58]
0000000141484cff  483b7d48                 cmp      rdi, qword ptr [rbp + 0x48]
0000000141484d03  750a                     jne      0x141484d0f
0000000141484d05  488d4d48                 lea      rcx, [rbp + 0x48]
0000000141484d09  e8d2a08f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141484d0e  90                       nop      
0000000141484d0f  488b4550                 mov      rax, qword ptr [rbp + 0x50]
0000000141484d13  488d0cbf                 lea      rcx, [rdi + rdi*4]
0000000141484d17  0f104560                 movups   xmm0, xmmword ptr [rbp + 0x60]
0000000141484d1b  0f104d70                 movups   xmm1, xmmword ptr [rbp + 0x70]
0000000141484d1f  488b9580000000           mov      rdx, qword ptr [rbp + 0x80]
0000000141484d26  488954c820               mov      qword ptr [rax + rcx*8 + 0x20], rdx
0000000141484d2b  0f114cc810               movups   xmmword ptr [rax + rcx*8 + 0x10], xmm1
0000000141484d30  0f1104c8                 movups   xmmword ptr [rax + rcx*8], xmm0
0000000141484d34  48ffc7                   inc      rdi
0000000141484d37  48897d58                 mov      qword ptr [rbp + 0x58], rdi
0000000141484d3b  450f2ecb                 ucomiss  xmm9, xmm11
0000000141484d3f  0f86a9000000             jbe      0x141484dee
0000000141484d45  410f28c3                 movaps   xmm0, xmm11
0000000141484d49  f3410fc2c303             cmpunordss xmm0, xmm11
0000000141484d4f  0f28c8                   movaps   xmm1, xmm0
0000000141484d52  0f54cf                   andps    xmm1, xmm7
0000000141484d55  0f28d7                   movaps   xmm2, xmm7
0000000141484d58  f3410f5fd3               maxss    xmm2, xmm11
0000000141484d5d  0f55c2                   andnps   xmm0, xmm2
0000000141484d60  0f56c1                   orps     xmm0, xmm1
0000000141484d63  f30f114570               movss    dword ptr [rbp + 0x70], xmm0
0000000141484d68  f3440f116574             movss    dword ptr [rbp + 0x74], xmm12
0000000141484d6e  440f134d78               movlps   qword ptr [rbp + 0x78], xmm9
0000000141484d73  4c897560                 mov      qword ptr [rbp + 0x60], r14
0000000141484d77  488b4540                 mov      rax, qword ptr [rbp + 0x40]
0000000141484d7b  48894568                 mov      qword ptr [rbp + 0x68], rax
0000000141484d7f  0fb68597000000           movzx    eax, byte ptr [rbp + 0x97]
0000000141484d86  888580000000             mov      byte ptr [rbp + 0x80], al
0000000141484d8c  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484d90  e87b9e96ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
0000000141484d95  90                       nop      
0000000141484d96  0f2ec6                   ucomiss  xmm0, xmm6
0000000141484d99  7653                     jbe      0x141484dee
0000000141484d9b  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484d9f  e8ac9e96ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
0000000141484da4  90                       nop      
0000000141484da5  0f2e05282d9b01           ucomiss  xmm0, dword ptr [rip + 0x19b2d28]
0000000141484dac  7240                     jb       0x141484dee
0000000141484dae  488b7d58                 mov      rdi, qword ptr [rbp + 0x58]
0000000141484db2  483b7d48                 cmp      rdi, qword ptr [rbp + 0x48]
0000000141484db6  750a                     jne      0x141484dc2
0000000141484db8  488d4d48                 lea      rcx, [rbp + 0x48]
0000000141484dbc  e81fa08f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141484dc1  90                       nop      
0000000141484dc2  488b4550                 mov      rax, qword ptr [rbp + 0x50]
0000000141484dc6  488d0cbf                 lea      rcx, [rdi + rdi*4]
0000000141484dca  0f104560                 movups   xmm0, xmmword ptr [rbp + 0x60]
0000000141484dce  0f104d70                 movups   xmm1, xmmword ptr [rbp + 0x70]
0000000141484dd2  488b9580000000           mov      rdx, qword ptr [rbp + 0x80]
0000000141484dd9  488954c820               mov      qword ptr [rax + rcx*8 + 0x20], rdx
0000000141484dde  0f114cc810               movups   xmmword ptr [rax + rcx*8 + 0x10], xmm1
0000000141484de3  0f1104c8                 movups   xmmword ptr [rax + rcx*8], xmm0
0000000141484de7  48ffc7                   inc      rdi
0000000141484dea  48897d58                 mov      qword ptr [rbp + 0x58], rdi
0000000141484dee  440f28ef                 movaps   xmm13, xmm7
0000000141484df2  f3440fc2ef03             cmpunordss xmm13, xmm7
0000000141484df8  410f28c5                 movaps   xmm0, xmm13
0000000141484dfc  410f54c6                 andps    xmm0, xmm14
0000000141484e00  f3440f5ff7               maxss    xmm14, xmm7
0000000141484e05  450f55ee                 andnps   xmm13, xmm14
0000000141484e09  440f56e8                 orps     xmm13, xmm0
0000000141484e0d  410f28f9                 movaps   xmm7, xmm9
0000000141484e11  f3410fc2f903             cmpunordss xmm7, xmm9
0000000141484e17  0f28c7                   movaps   xmm0, xmm7
0000000141484e1a  410f54c3                 andps    xmm0, xmm11
0000000141484e1e  f3450f5dd9               minss    xmm11, xmm9
0000000141484e23  410f55fb                 andnps   xmm7, xmm11
0000000141484e27  0f56f8                   orps     xmm7, xmm0
0000000141484e2a  b001                     mov      al, 1
0000000141484e2c  894534                   mov      dword ptr [rbp + 0x34], eax
0000000141484e2f  440f2eef                 ucomiss  xmm13, xmm7
0000000141484e33  488b5538                 mov      rdx, qword ptr [rbp + 0x38]
0000000141484e37  0f8336faffff             jae      0x141484873
0000000141484e3d  450f2efc                 ucomiss  xmm15, xmm12
0000000141484e41  0f86b5000000             jbe      0x141484efc
0000000141484e47  410f28c0                 movaps   xmm0, xmm8
0000000141484e4b  f3410f5dc7               minss    xmm0, xmm15
0000000141484e50  f3450fc2ff03             cmpunordss xmm15, xmm15
0000000141484e56  410f28cf                 movaps   xmm1, xmm15
0000000141484e5a  410f54c8                 andps    xmm1, xmm8
0000000141484e5e  440f55f8                 andnps   xmm15, xmm0
0000000141484e62  440f56f9                 orps     xmm15, xmm1
0000000141484e66  f3440f116d70             movss    dword ptr [rbp + 0x70], xmm13
0000000141484e6c  f3440f116574             movss    dword ptr [rbp + 0x74], xmm12
0000000141484e72  f30f117d78               movss    dword ptr [rbp + 0x78], xmm7
0000000141484e77  f3440f117d7c             movss    dword ptr [rbp + 0x7c], xmm15
0000000141484e7d  4c897560                 mov      qword ptr [rbp + 0x60], r14
0000000141484e81  488b4540                 mov      rax, qword ptr [rbp + 0x40]
0000000141484e85  48894568                 mov      qword ptr [rbp + 0x68], rax
0000000141484e89  0fb68597000000           movzx    eax, byte ptr [rbp + 0x97]
0000000141484e90  888580000000             mov      byte ptr [rbp + 0x80], al
0000000141484e96  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484e9a  e8719d96ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
0000000141484e9f  90                       nop      
0000000141484ea0  0f2ec6                   ucomiss  xmm0, xmm6
0000000141484ea3  7653                     jbe      0x141484ef8
0000000141484ea5  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484ea9  e8a29d96ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
0000000141484eae  90                       nop      
0000000141484eaf  0f2e051e2c9b01           ucomiss  xmm0, dword ptr [rip + 0x19b2c1e]
0000000141484eb6  7240                     jb       0x141484ef8
0000000141484eb8  488b7d58                 mov      rdi, qword ptr [rbp + 0x58]
0000000141484ebc  483b7d48                 cmp      rdi, qword ptr [rbp + 0x48]
0000000141484ec0  750a                     jne      0x141484ecc
0000000141484ec2  488d4d48                 lea      rcx, [rbp + 0x48]
0000000141484ec6  e8159f8f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141484ecb  90                       nop      
0000000141484ecc  488b4550                 mov      rax, qword ptr [rbp + 0x50]
0000000141484ed0  488d0cbf                 lea      rcx, [rdi + rdi*4]
0000000141484ed4  0f104560                 movups   xmm0, xmmword ptr [rbp + 0x60]
0000000141484ed8  0f104d70                 movups   xmm1, xmmword ptr [rbp + 0x70]
0000000141484edc  488b9580000000           mov      rdx, qword ptr [rbp + 0x80]
0000000141484ee3  488954c820               mov      qword ptr [rax + rcx*8 + 0x20], rdx
0000000141484ee8  0f114cc810               movups   xmmword ptr [rax + rcx*8 + 0x10], xmm1
0000000141484eed  0f1104c8                 movups   xmmword ptr [rax + rcx*8], xmm0
0000000141484ef1  48ffc7                   inc      rdi
0000000141484ef4  48897d58                 mov      qword ptr [rbp + 0x58], rdi
0000000141484ef8  488b5538                 mov      rdx, qword ptr [rbp + 0x38]
0000000141484efc  450f2ec2                 ucomiss  xmm8, xmm10
0000000141484f00  0f866df9ffff             jbe      0x141484873
0000000141484f06  410f28c4                 movaps   xmm0, xmm12
0000000141484f0a  f3410f5fc2               maxss    xmm0, xmm10
0000000141484f0f  f3450fc2d203             cmpunordss xmm10, xmm10
0000000141484f15  410f28ca                 movaps   xmm1, xmm10
0000000141484f19  410f54cc                 andps    xmm1, xmm12
0000000141484f1d  440f55d0                 andnps   xmm10, xmm0
0000000141484f21  440f56d1                 orps     xmm10, xmm1
0000000141484f25  f3440f116d70             movss    dword ptr [rbp + 0x70], xmm13
0000000141484f2b  f3440f115574             movss    dword ptr [rbp + 0x74], xmm10
0000000141484f31  f30f117d78               movss    dword ptr [rbp + 0x78], xmm7
0000000141484f36  f3440f11457c             movss    dword ptr [rbp + 0x7c], xmm8
0000000141484f3c  4c897560                 mov      qword ptr [rbp + 0x60], r14
0000000141484f40  488b4540                 mov      rax, qword ptr [rbp + 0x40]
0000000141484f44  48894568                 mov      qword ptr [rbp + 0x68], rax
0000000141484f48  0fb68597000000           movzx    eax, byte ptr [rbp + 0x97]
0000000141484f4f  888580000000             mov      byte ptr [rbp + 0x80], al
0000000141484f55  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484f59  e8b29c96ff               call     0x140deec10 ; utils::geometry::aabb::Aabb2::width | _ZN5utils8geometry4aabb5Aabb25width17he30e90b5e741e6fbE
0000000141484f5e  90                       nop      
0000000141484f5f  0f2ec6                   ucomiss  xmm0, xmm6
0000000141484f62  7653                     jbe      0x141484fb7
0000000141484f64  488d4d70                 lea      rcx, [rbp + 0x70]
0000000141484f68  e8e39c96ff               call     0x140deec50 ; utils::geometry::aabb::Aabb2::height | _ZN5utils8geometry4aabb5Aabb26height17h160a2c40e4ab2359E
0000000141484f6d  90                       nop      
0000000141484f6e  0f2e055f2b9b01           ucomiss  xmm0, dword ptr [rip + 0x19b2b5f]
0000000141484f75  7240                     jb       0x141484fb7
0000000141484f77  488b7d58                 mov      rdi, qword ptr [rbp + 0x58]
0000000141484f7b  483b7d48                 cmp      rdi, qword ptr [rbp + 0x48]
0000000141484f7f  750a                     jne      0x141484f8b
0000000141484f81  488d4d48                 lea      rcx, [rbp + 0x48]
0000000141484f85  e8569e8f01               call     0x142d7ede0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h01e56cf28dccb067E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h02f6c3bd9325fc3fE
0000000141484f8a  90                       nop      
0000000141484f8b  488b4550                 mov      rax, qword ptr [rbp + 0x50]
0000000141484f8f  488d0cbf                 lea      rcx, [rdi + rdi*4]
0000000141484f93  0f104560                 movups   xmm0, xmmword ptr [rbp + 0x60]
0000000141484f97  0f104d70                 movups   xmm1, xmmword ptr [rbp + 0x70]
0000000141484f9b  488b9580000000           mov      rdx, qword ptr [rbp + 0x80]
0000000141484fa2  488954c820               mov      qword ptr [rax + rcx*8 + 0x20], rdx
0000000141484fa7  0f114cc810               movups   xmmword ptr [rax + rcx*8 + 0x10], xmm1
0000000141484fac  0f1104c8                 movups   xmmword ptr [rax + rcx*8], xmm0
0000000141484fb0  48ffc7                   inc      rdi
0000000141484fb3  48897d58                 mov      qword ptr [rbp + 0x58], rdi
0000000141484fb7  488b5538                 mov      rdx, qword ptr [rbp + 0x38]
0000000141484fbb  e9b3f8ffff               jmp      0x141484873
0000000141484fc0  488b4558                 mov      rax, qword ptr [rbp + 0x58]
0000000141484fc4  48894570                 mov      qword ptr [rbp + 0x70], rax
0000000141484fc8  0f104548                 movups   xmm0, xmmword ptr [rbp + 0x48]
0000000141484fcc  0f294560                 movaps   xmmword ptr [rbp + 0x60], xmm0
0000000141484fd0  488b06                   mov      rax, qword ptr [rsi]
0000000141484fd3  4885c0                   test     rax, rax
0000000141484fd6  7417                     je       0x141484fef
0000000141484fd8  488b4e08                 mov      rcx, qword ptr [rsi + 8]
0000000141484fdc  48c1e003                 shl      rax, 3
0000000141484fe0  488d1480                 lea      rdx, [rax + rax*4]
0000000141484fe4  41b808000000             mov      r8d, 8
0000000141484fea  e8d16a22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141484fef  488b4570                 mov      rax, qword ptr [rbp + 0x70]
0000000141484ff3  48894610                 mov      qword ptr [rsi + 0x10], rax
0000000141484ff7  0f284560                 movaps   xmm0, xmmword ptr [rbp + 0x60]
0000000141484ffb  0f1106                   movups   xmmword ptr [rsi], xmm0
0000000141484ffe  448b4d30                 mov      r9d, dword ptr [rbp + 0x30]
0000000141485002  440a4d34                 or       r9b, byte ptr [rbp + 0x34]
0000000141485006  488b55f8                 mov      rdx, qword ptr [rbp - 8]
000000014148500a  488b4d10                 mov      rcx, qword ptr [rbp + 0x10]
000000014148500e  4839d1                   cmp      rcx, rdx
0000000141485011  48b83033333333333303     movabs   rax, 0x333333333333330
000000014148501b  4c8b4500                 mov      r8, qword ptr [rbp]
000000014148501f  7415                     je       0x141485036
0000000141485021  0f1001                   movups   xmm0, xmmword ptr [rcx]
0000000141485024  0f294520                 movaps   xmmword ptr [rbp + 0x20], xmm0
0000000141485028  488b7e10                 mov      rdi, qword ptr [rsi + 0x10]
000000014148502c  4839c7                   cmp      rdi, rax
000000014148502f  777d                     ja       0x1414850ae
0000000141485031  e9b4f7ffff               jmp      0x1414847ea
0000000141485036  41f6c101                 test     r9b, 1
000000014148503a  440fb68d96000000         movzx    r9d, byte ptr [rbp + 0x96]
0000000141485042  488b4d08                 mov      rcx, qword ptr [rbp + 8]
0000000141485046  0f8567f7ffff             jne      0x1414847b3
000000014148504c  0f28b5a0000000           movaps   xmm6, xmmword ptr [rbp + 0xa0]
0000000141485053  0f28bdb0000000           movaps   xmm7, xmmword ptr [rbp + 0xb0]
000000014148505a  440f2885c0000000         movaps   xmm8, xmmword ptr [rbp + 0xc0]
0000000141485062  440f288dd0000000         movaps   xmm9, xmmword ptr [rbp + 0xd0]
000000014148506a  440f2895e0000000         movaps   xmm10, xmmword ptr [rbp + 0xe0]
0000000141485072  440f289df0000000         movaps   xmm11, xmmword ptr [rbp + 0xf0]
000000014148507a  440f28a500010000         movaps   xmm12, xmmword ptr [rbp + 0x100]
0000000141485082  440f28ad10010000         movaps   xmm13, xmmword ptr [rbp + 0x110]
000000014148508a  440f28b520010000         movaps   xmm14, xmmword ptr [rbp + 0x120]
0000000141485092  440f28bd30010000         movaps   xmm15, xmmword ptr [rbp + 0x130]
000000014148509a  4881c4c8010000           add      rsp, 0x1c8
00000001414850a1  5b                       pop      rbx
00000001414850a2  5f                       pop      rdi
00000001414850a3  5e                       pop      rsi
00000001414850a4  415c                     pop      r12
00000001414850a6  415d                     pop      r13
00000001414850a8  415e                     pop      r14
00000001414850aa  415f                     pop      r15
00000001414850ac  5d                       pop      rbp
00000001414850ad  c3                       ret      
00000001414850ae  4531f6                   xor      r14d, r14d
00000001414850b1  488b5d18                 mov      rbx, qword ptr [rbp + 0x18]
00000001414850b5  4c89f1                   mov      rcx, r14
00000001414850b8  4889da                   mov      rdx, rbx
00000001414850bb  e86a2d9401               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
00000001414850c0  cc                       int3     
00000001414850c1  6666666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001414850d0  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001414850d5  55                       push     rbp
00000001414850d6  4157                     push     r15
00000001414850d8  4156                     push     r14
00000001414850da  4155                     push     r13
00000001414850dc  4154                     push     r12
00000001414850de  56                       push     rsi
00000001414850df  57                       push     rdi
00000001414850e0  53                       push     rbx
00000001414850e1  4881ecc8000000           sub      rsp, 0xc8
00000001414850e8  488daa80000000           lea      rbp, [rdx + 0x80]
00000001414850ef  440f297c2420             movaps   xmmword ptr [rsp + 0x20], xmm15
00000001414850f5  440f29742430             movaps   xmmword ptr [rsp + 0x30], xmm14
00000001414850fb  440f296c2440             movaps   xmmword ptr [rsp + 0x40], xmm13
0000000141485101  440f29642450             movaps   xmmword ptr [rsp + 0x50], xmm12
0000000141485107  440f295c2460             movaps   xmmword ptr [rsp + 0x60], xmm11
000000014148510d  440f29542470             movaps   xmmword ptr [rsp + 0x70], xmm10
0000000141485113  440f298c2480000000       movaps   xmmword ptr [rsp + 0x80], xmm9
000000014148511c  440f29842490000000       movaps   xmmword ptr [rsp + 0x90], xmm8
0000000141485125  0f29bc24a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm7
000000014148512d  0f29b424b0000000         movaps   xmmword ptr [rsp + 0xb0], xmm6
0000000141485135  488b4538                 mov      rax, qword ptr [rbp + 0x38]
0000000141485139  488945a8                 mov      qword ptr [rbp - 0x58], rax
000000014148513d  488d4da8                 lea      rcx, [rbp - 0x58]
0000000141485141  e8ba974fff               call     0x14097e900 ; alloc::vec::drain::impl$7::drop<rhapsody::raw::swapchain::SwapchainSyncSlot,alloc::alloc::Global> | _ZN79_$LT$alloc..vec..drain..Drain$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17h1daa861ef070338eE
0000000141485146  488b4548                 mov      rax, qword ptr [rbp + 0x48]
000000014148514a  4885c0                   test     rax, rax
000000014148514d  7417                     je       0x141485166
000000014148514f  488b4d50                 mov      rcx, qword ptr [rbp + 0x50]
0000000141485153  48c1e003                 shl      rax, 3
0000000141485157  488d1480                 lea      rdx, [rax + rax*4]
000000014148515b  41b808000000             mov      r8d, 8
0000000141485161  e85a6922ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141485166  0f28b424b0000000         movaps   xmm6, xmmword ptr [rsp + 0xb0]
000000014148516e  0f28bc24a0000000         movaps   xmm7, xmmword ptr [rsp + 0xa0]
0000000141485176  440f28842490000000       movaps   xmm8, xmmword ptr [rsp + 0x90]
000000014148517f  440f288c2480000000       movaps   xmm9, xmmword ptr [rsp + 0x80]
0000000141485188  440f28542470             movaps   xmm10, xmmword ptr [rsp + 0x70]
000000014148518e  440f285c2460             movaps   xmm11, xmmword ptr [rsp + 0x60]
0000000141485194  440f28642450             movaps   xmm12, xmmword ptr [rsp + 0x50]
000000014148519a  440f286c2440             movaps   xmm13, xmmword ptr [rsp + 0x40]
00000001414851a0  440f28742430             movaps   xmm14, xmmword ptr [rsp + 0x30]
00000001414851a6  440f287c2420             movaps   xmm15, xmmword ptr [rsp + 0x20]
00000001414851ac  4881c4c8000000           add      rsp, 0xc8
00000001414851b3  5b                       pop      rbx
00000001414851b4  5f                       pop      rdi
00000001414851b5  5e                       pop      rsi
00000001414851b6  415c                     pop      r12
00000001414851b8  415d                     pop      r13
00000001414851ba  415e                     pop      r14
00000001414851bc  415f                     pop      r15
00000001414851be  5d                       pop      rbp
00000001414851bf  c3                       ret      