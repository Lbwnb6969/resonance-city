0000000140df4540  4889c8                   mov      rax, rcx
0000000140df4543  f30f1002                 movss    xmm0, dword ptr [rdx]
0000000140df4547  f30f104a04               movss    xmm1, dword ptr [rdx + 4]
0000000140df454c  f30f1101                 movss    dword ptr [rcx], xmm0
0000000140df4550  f30f115104               movss    dword ptr [rcx + 4], xmm2
0000000140df4555  f30f114908               movss    dword ptr [rcx + 8], xmm1
0000000140df455a  c3                       ret      