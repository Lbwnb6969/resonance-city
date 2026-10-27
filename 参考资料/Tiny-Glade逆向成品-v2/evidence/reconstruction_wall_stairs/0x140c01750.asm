0000000140c01750  0fb601                   movzx    eax, byte ptr [rcx]
0000000140c01753  0f57c0                   xorps    xmm0, xmm0
0000000140c01756  85c0                     test     eax, eax
0000000140c01758  742c                     je       0x140c01786
0000000140c0175a  83f801                   cmp      eax, 1
0000000140c0175d  7533                     jne      0x140c01792
0000000140c0175f  f20f105104               movsd    xmm2, qword ptr [rcx + 4]
0000000140c01764  80790100                 cmp      byte ptr [rcx + 1], 0
0000000140c01768  7408                     je       0x140c01772
0000000140c0176a  f20f10410c               movsd    xmm0, qword ptr [rcx + 0xc]
0000000140c0176f  0f58d0                   addps    xmm2, xmm0
0000000140c01772  f30f590dd6572302         mulss    xmm1, dword ptr [rip + 0x22357d6]
0000000140c0177a  f30f12c1                 movsldup xmm0, xmm1
0000000140c0177e  0f59c2                   mulps    xmm0, xmm2
0000000140c01781  f30f16c8                 movshdup xmm1, xmm0
0000000140c01785  c3                       ret      
0000000140c01786  80790100                 cmp      byte ptr [rcx + 1], 0
0000000140c0178a  750b                     jne      0x140c01797
0000000140c0178c  80790200                 cmp      byte ptr [rcx + 2], 0
0000000140c01790  7505                     jne      0x140c01797
0000000140c01792  f30f16c8                 movshdup xmm1, xmm0
0000000140c01796  c3                       ret      
0000000140c01797  f20f105104               movsd    xmm2, qword ptr [rcx + 4]
0000000140c0179c  f30f12c1                 movsldup xmm0, xmm1
0000000140c017a0  0f59c2                   mulps    xmm0, xmm2
0000000140c017a3  f30f16c8                 movshdup xmm1, xmm0
0000000140c017a7  c3                       ret      