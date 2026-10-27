0000000140aaab70  4889c8                   mov      rax, rcx
0000000140aaab73  44894248                 mov      dword ptr [rdx + 0x48], r8d
0000000140aaab77  0f1002                   movups   xmm0, xmmword ptr [rdx]
0000000140aaab7a  0f104a10                 movups   xmm1, xmmword ptr [rdx + 0x10]
0000000140aaab7e  0f105220                 movups   xmm2, xmmword ptr [rdx + 0x20]
0000000140aaab82  0f105a30                 movups   xmm3, xmmword ptr [rdx + 0x30]
0000000140aaab86  0f115930                 movups   xmmword ptr [rcx + 0x30], xmm3
0000000140aaab8a  0f115120                 movups   xmmword ptr [rcx + 0x20], xmm2
0000000140aaab8e  0f114910                 movups   xmmword ptr [rcx + 0x10], xmm1
0000000140aaab92  0f1101                   movups   xmmword ptr [rcx], xmm0
0000000140aaab95  488b4a40                 mov      rcx, qword ptr [rdx + 0x40]
0000000140aaab99  48894840                 mov      qword ptr [rax + 0x40], rcx
0000000140aaab9d  8b4a48                   mov      ecx, dword ptr [rdx + 0x48]
0000000140aaaba0  894848                   mov      dword ptr [rax + 0x48], ecx
0000000140aaaba3  8b4a4c                   mov      ecx, dword ptr [rdx + 0x4c]
0000000140aaaba6  89484c                   mov      dword ptr [rax + 0x4c], ecx
0000000140aaaba9  c3                       ret      