000000014092ff30  4883ec48                 sub      rsp, 0x48
000000014092ff34  660f7f7c2430             movdqa   xmmword ptr [rsp + 0x30], xmm7
000000014092ff3a  660f7f742420             movdqa   xmmword ptr [rsp + 0x20], xmm6
000000014092ff40  f30f108994020000         movss    xmm1, dword ptr [rcx + 0x294]
000000014092ff48  84d2                     test     dl, dl
000000014092ff4a  7454                     je       0x14092ffa0
000000014092ff4c  80b90801000000           cmp      byte ptr [rcx + 0x108], 0
000000014092ff53  0f849d010000             je       0x1409300f6
000000014092ff59  f30f10810c010000         movss    xmm0, dword ptr [rcx + 0x10c]
000000014092ff61  f30f58059bc65002         addss    xmm0, dword ptr [rip + 0x250c69b]
000000014092ff69  f30f5805ef1a6f02         addss    xmm0, dword ptr [rip + 0x26f1aef]
000000014092ff71  488b9198000000           mov      rdx, qword ptr [rcx + 0x98]
000000014092ff78  4885d2                   test     rdx, rdx
000000014092ff7b  7444                     je       0x14092ffc1
000000014092ff7d  488b8190000000           mov      rax, qword ptr [rcx + 0x90]
000000014092ff84  660f6e5004               movd     xmm2, dword ptr [rax + 4]
000000014092ff89  4883fa01                 cmp      rdx, 1
000000014092ff8d  7547                     jne      0x14092ffd6
000000014092ff8f  660f6e9984020000         movd     xmm3, dword ptr [rcx + 0x284]
000000014092ff97  660f6fea                 movdqa   xmm5, xmm2
000000014092ff9b  e917010000               jmp      0x1409300b7
000000014092ffa0  80b91001000000           cmp      byte ptr [rcx + 0x110], 0
000000014092ffa7  0f844e010000             je       0x1409300fb
000000014092ffad  f30f108114010000         movss    xmm0, dword ptr [rcx + 0x114]
000000014092ffb5  488b9198000000           mov      rdx, qword ptr [rcx + 0x98]
000000014092ffbc  4885d2                   test     rdx, rdx
000000014092ffbf  75bc                     jne      0x14092ff7d
000000014092ffc1  660f6e9184020000         movd     xmm2, dword ptr [rcx + 0x284]
000000014092ffc9  660f6fea                 movdqa   xmm5, xmm2
000000014092ffcd  660f6fda                 movdqa   xmm3, xmm2
000000014092ffd1  e9e1000000               jmp      0x1409300b7
000000014092ffd6  488d1452                 lea      rdx, [rdx + rdx*2]
000000014092ffda  4c8d0495f4ffffff         lea      r8, [rdx*4 - 0xc]
000000014092ffe2  49c1e802                 shr      r8, 2
000000014092ffe6  48baabaaaaaaaaaaaaaa     movabs   rdx, 0xaaaaaaaaaaaaaaab
000000014092fff0  490fafd0                 imul     rdx, r8
000000014092fff4  4c8d4010                 lea      r8, [rax + 0x10]
000000014092fff8  4989d1                   mov      r9, rdx
000000014092fffb  660f6fda                 movdqa   xmm3, xmm2
000000014092ffff  eb1c                     jmp      0x14093001d
0000000140930001  6666666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000140930010  4983c00c                 add      r8, 0xc
0000000140930014  660f6fdc                 movdqa   xmm3, xmm4
0000000140930018  49ffc9                   dec      r9
000000014093001b  7439                     je       0x140930056
000000014093001d  66410f6e20               movd     xmm4, dword ptr [r8]
0000000140930022  660f6feb                 movdqa   xmm5, xmm3
0000000140930026  660f62ec                 punpckldq xmm5, xmm4
000000014093002a  660f6ff5                 movdqa   xmm6, xmm5
000000014093002e  660f72e61f               psrad    xmm6, 0x1f
0000000140930033  660f72d601               psrld    xmm6, 1
0000000140930038  660feff5                 pxor     xmm6, xmm5
000000014093003c  660f70ee55               pshufd   xmm5, xmm6, 0x55
0000000140930041  660f66f5                 pcmpgtd  xmm6, xmm5
0000000140930045  66410f7ef2               movd     r10d, xmm6
000000014093004a  41f6c201                 test     r10b, 1
000000014093004e  75c0                     jne      0x140930010
0000000140930050  660f6fe3                 movdqa   xmm4, xmm3
0000000140930054  ebba                     jmp      0x140930010
0000000140930056  660f6e9984020000         movd     xmm3, dword ptr [rcx + 0x284]
000000014093005e  4883c010                 add      rax, 0x10
0000000140930062  eb19                     jmp      0x14093007d
0000000140930064  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000140930070  4883c00c                 add      rax, 0xc
0000000140930074  660f6fd5                 movdqa   xmm2, xmm5
0000000140930078  48ffca                   dec      rdx
000000014093007b  7436                     je       0x1409300b3
000000014093007d  660f6e28                 movd     xmm5, dword ptr [rax]
0000000140930081  660f6ff2                 movdqa   xmm6, xmm2
0000000140930085  660f62f5                 punpckldq xmm6, xmm5
0000000140930089  660f6ffe                 movdqa   xmm7, xmm6
000000014093008d  660f72e71f               psrad    xmm7, 0x1f
0000000140930092  660f72d701               psrld    xmm7, 1
0000000140930097  660feffe                 pxor     xmm7, xmm6
000000014093009b  660f70f755               pshufd   xmm6, xmm7, 0x55
00000001409300a0  660f66fe                 pcmpgtd  xmm7, xmm6
00000001409300a4  660f7ef9                 movd     ecx, xmm7
00000001409300a8  f6c101                   test     cl, 1
00000001409300ab  75c3                     jne      0x140930070
00000001409300ad  660f6fea                 movdqa   xmm5, xmm2
00000001409300b1  ebbd                     jmp      0x140930070
00000001409300b3  660f6fd4                 movdqa   xmm2, xmm4
00000001409300b7  f30f5cc2                 subss    xmm0, xmm2
00000001409300bb  0f57d2                   xorps    xmm2, xmm2
00000001409300be  f30f5fc2                 maxss    xmm0, xmm2
00000001409300c2  f30f5fd1                 maxss    xmm2, xmm1
00000001409300c6  f30f5dc2                 minss    xmm0, xmm2
00000001409300ca  f30f58c5                 addss    xmm0, xmm5
00000001409300ce  660f6fcb                 movdqa   xmm1, xmm3
00000001409300d2  f30f5fc8                 maxss    xmm1, xmm0
00000001409300d6  f30fc2c003               cmpunordss xmm0, xmm0
00000001409300db  0f28d0                   movaps   xmm2, xmm0
00000001409300de  0f55d1                   andnps   xmm2, xmm1
00000001409300e1  0f54c3                   andps    xmm0, xmm3
00000001409300e4  0f56c2                   orps     xmm0, xmm2
00000001409300e7  0f28742420               movaps   xmm6, xmmword ptr [rsp + 0x20]
00000001409300ec  0f287c2430               movaps   xmm7, xmmword ptr [rsp + 0x30]
00000001409300f1  4883c448                 add      rsp, 0x48
00000001409300f5  c3                       ret      
00000001409300f6  e845df4502               call     0x142d8e040 ; country_core::resources::walls::public_wall_state::impl$0::max_y::closure$0 | _ZN12country_core9resources5walls17public_wall_state15PublicWallState5max_y28_$u7b$$u7b$closure$u7d$$u7d$17h631be69922351c74E.llvm.9594058148382606787
00000001409300fb  e800df4502               call     0x142d8e000 ; country_core::resources::walls::public_wall_state::impl$0::max_y_gable::closure$0 | _ZN12country_core9resources5walls17public_wall_state15PublicWallState11max_y_gable28_$u7b$$u7b$closure$u7d$$u7d$17hdbfc85e4a059832dE.llvm.9594058148382606787
0000000140930100  cc                       int3     