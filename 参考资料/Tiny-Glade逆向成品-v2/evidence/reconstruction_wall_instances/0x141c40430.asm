0000000141c40430  4883ec38                 sub      rsp, 0x38
0000000141c40434  0f29742420               movaps   xmmword ptr [rsp + 0x20], xmm6
0000000141c40439  f30f1001                 movss    xmm0, dword ptr [rcx]
0000000141c4043d  f30f103587773101         movss    xmm6, dword ptr [rip + 0x1317787]
0000000141c40445  0f28ce                   movaps   xmm1, xmm6
0000000141c40448  e823261f01               call     0x142e32a70 ; fmodf
0000000141c4044d  f30f58f0                 addss    xmm6, xmm0
0000000141c40451  0f57d2                   xorps    xmm2, xmm2
0000000141c40454  0f28c8                   movaps   xmm1, xmm0
0000000141c40457  f30fc2ca01               cmpltss  xmm1, xmm2
0000000141c4045c  0f54f1                   andps    xmm6, xmm1
0000000141c4045f  0f55c8                   andnps   xmm1, xmm0
0000000141c40462  0f56ce                   orps     xmm1, xmm6
0000000141c40465  0f28c1                   movaps   xmm0, xmm1
0000000141c40468  0f28742420               movaps   xmm6, xmmword ptr [rsp + 0x20]
0000000141c4046d  4883c438                 add      rsp, 0x38
0000000141c40471  c3                       ret      