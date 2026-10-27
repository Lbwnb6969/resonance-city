0000000140aaac40  4889c8                   mov      rax, rcx
0000000140aaac43  44894234                 mov      dword ptr [rdx + 0x34], r8d
0000000140aaac47  0f1002                   movups   xmm0, xmmword ptr [rdx]
0000000140aaac4a  0f104a10                 movups   xmm1, xmmword ptr [rdx + 0x10]
0000000140aaac4e  0f105220                 movups   xmm2, xmmword ptr [rdx + 0x20]
0000000140aaac52  0f105a40                 movups   xmm3, xmmword ptr [rdx + 0x40]
0000000140aaac56  0f115940                 movups   xmmword ptr [rcx + 0x40], xmm3
0000000140aaac5a  0f115120                 movups   xmmword ptr [rcx + 0x20], xmm2
0000000140aaac5e  0f114910                 movups   xmmword ptr [rcx + 0x10], xmm1
0000000140aaac62  0f1101                   movups   xmmword ptr [rcx], xmm0
0000000140aaac65  8b4a30                   mov      ecx, dword ptr [rdx + 0x30]
0000000140aaac68  894830                   mov      dword ptr [rax + 0x30], ecx
0000000140aaac6b  8b4a34                   mov      ecx, dword ptr [rdx + 0x34]
0000000140aaac6e  894834                   mov      dword ptr [rax + 0x34], ecx
0000000140aaac71  488b4a38                 mov      rcx, qword ptr [rdx + 0x38]
0000000140aaac75  48894838                 mov      qword ptr [rax + 0x38], rcx
0000000140aaac79  c3                       ret      