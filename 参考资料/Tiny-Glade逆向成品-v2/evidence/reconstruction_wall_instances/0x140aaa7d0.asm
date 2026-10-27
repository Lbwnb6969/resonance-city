0000000140aaa7d0  44094238                 or       dword ptr [rdx + 0x38], r8d
0000000140aaa7d4  4889c8                   mov      rax, rcx
0000000140aaa7d7  0f1002                   movups   xmm0, xmmword ptr [rdx]
0000000140aaa7da  0f104a10                 movups   xmm1, xmmword ptr [rdx + 0x10]
0000000140aaa7de  0f105220                 movups   xmm2, xmmword ptr [rdx + 0x20]
0000000140aaa7e2  0f105a40                 movups   xmm3, xmmword ptr [rdx + 0x40]
0000000140aaa7e6  0f115940                 movups   xmmword ptr [rcx + 0x40], xmm3
0000000140aaa7ea  0f115120                 movups   xmmword ptr [rcx + 0x20], xmm2
0000000140aaa7ee  0f114910                 movups   xmmword ptr [rcx + 0x10], xmm1
0000000140aaa7f2  0f1101                   movups   xmmword ptr [rcx], xmm0
0000000140aaa7f5  0f104230                 movups   xmm0, xmmword ptr [rdx + 0x30]
0000000140aaa7f9  0f114130                 movups   xmmword ptr [rcx + 0x30], xmm0
0000000140aaa7fd  c3                       ret      