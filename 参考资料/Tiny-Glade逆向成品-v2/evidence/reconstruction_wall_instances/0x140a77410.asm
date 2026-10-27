0000000140a77410  4889c8                   mov      rax, rcx
0000000140a77413  0f1005a6a95c02           movups   xmm0, xmmword ptr [rip + 0x25ca9a6]
0000000140a7741a  0f114120                 movups   xmmword ptr [rcx + 0x20], xmm0
0000000140a7741e  0f10058ba95c02           movups   xmm0, xmmword ptr [rip + 0x25ca98b]
0000000140a77425  0f114110                 movups   xmmword ptr [rcx + 0x10], xmm0
0000000140a77429  0f100570a95c02           movups   xmm0, xmmword ptr [rip + 0x25ca970]
0000000140a77430  0f1101                   movups   xmmword ptr [rcx], xmm0
0000000140a77433  0f2805d67e5c02           movaps   xmm0, xmmword ptr [rip + 0x25c7ed6]
0000000140a7743a  0f114130                 movups   xmmword ptr [rcx + 0x30], xmm0
0000000140a7743e  0f57c0                   xorps    xmm0, xmm0
0000000140a77441  0f114140                 movups   xmmword ptr [rcx + 0x40], xmm0
0000000140a77445  c3                       ret      