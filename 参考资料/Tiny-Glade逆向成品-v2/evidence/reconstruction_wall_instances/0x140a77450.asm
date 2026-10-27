0000000140a77450  4889c8                   mov      rax, rcx
0000000140a77453  0f100566a95c02           movups   xmm0, xmmword ptr [rip + 0x25ca966]
0000000140a7745a  0f114120                 movups   xmmword ptr [rcx + 0x20], xmm0
0000000140a7745e  0f10054ba95c02           movups   xmm0, xmmword ptr [rip + 0x25ca94b]
0000000140a77465  0f114110                 movups   xmmword ptr [rcx + 0x10], xmm0
0000000140a77469  0f100530a95c02           movups   xmm0, xmmword ptr [rip + 0x25ca930]
0000000140a77470  0f1101                   movups   xmmword ptr [rcx], xmm0
0000000140a77473  0f2805068b3d02           movaps   xmm0, xmmword ptr [rip + 0x23d8b06]
0000000140a7747a  0f114130                 movups   xmmword ptr [rcx + 0x30], xmm0
0000000140a7747e  0f28057b0b5202           movaps   xmm0, xmmword ptr [rip + 0x2520b7b]
0000000140a77485  0f114140                 movups   xmmword ptr [rcx + 0x40], xmm0
0000000140a77489  0f57c0                   xorps    xmm0, xmm0
0000000140a7748c  0f114150                 movups   xmmword ptr [rcx + 0x50], xmm0
0000000140a77490  c3                       ret      