0000000141420f40  55                       push     rbp
0000000141420f41  4157                     push     r15
0000000141420f43  4156                     push     r14
0000000141420f45  56                       push     rsi
0000000141420f46  57                       push     rdi
0000000141420f47  53                       push     rbx
0000000141420f48  4883ec58                 sub      rsp, 0x58
0000000141420f4c  488d6c2450               lea      rbp, [rsp + 0x50]
0000000141420f51  48c74500feffffff         mov      qword ptr [rbp], 0xfffffffffffffffe
0000000141420f59  4c8b5928                 mov      r11, qword ptr [rcx + 0x28]
0000000141420f5d  488b7950                 mov      rdi, qword ptr [rcx + 0x50]
0000000141420f61  488b7158                 mov      rsi, qword ptr [rcx + 0x58]
0000000141420f65  488b4160                 mov      rax, qword ptr [rcx + 0x60]
0000000141420f69  4c8b5168                 mov      r10, qword ptr [rcx + 0x68]
0000000141420f6d  4c8b3a                   mov      r15, qword ptr [rdx]
0000000141420f70  4c8b4208                 mov      r8, qword ptr [rdx + 8]
0000000141420f74  488b5210                 mov      rdx, qword ptr [rdx + 0x10]
0000000141420f78  48833901                 cmp      qword ptr [rcx], 1
0000000141420f7c  7548                     jne      0x141420fc6
0000000141420f7e  0f104108                 movups   xmm0, xmmword ptr [rcx + 8]
0000000141420f82  0f104918                 movups   xmm1, xmmword ptr [rcx + 0x18]
0000000141420f86  0f2945d0                 movaps   xmmword ptr [rbp - 0x30], xmm0
0000000141420f8a  0f294de0                 movaps   xmmword ptr [rbp - 0x20], xmm1
0000000141420f8e  488b5dd0                 mov      rbx, qword ptr [rbp - 0x30]
0000000141420f92  4c8b75d8                 mov      r14, qword ptr [rbp - 0x28]
0000000141420f96  4c39f3                   cmp      rbx, r14
0000000141420f99  742b                     je       0x141420fc6
0000000141420f9b  0f1f440000               nop      dword ptr [rax + rax]
0000000141420fa0  4c8b4cdde0               mov      r9, qword ptr [rbp + rbx*8 - 0x20]
0000000141420fa5  4983f904                 cmp      r9, 4
0000000141420fa9  0f83b3000000             jae      0x141421062
0000000141420faf  48ffc3                   inc      rbx
0000000141420fb2  f2430f1004ca             movsd    xmm0, qword ptr [r10 + r9*8]
0000000141420fb8  f2420f1104c2             movsd    qword ptr [rdx + r8*8], xmm0
0000000141420fbe  49ffc0                   inc      r8
0000000141420fc1  4939de                   cmp      r14, rbx
0000000141420fc4  75da                     jne      0x141420fa0
0000000141420fc6  48f7c7fdffffff           test     rdi, -3
0000000141420fcd  7508                     jne      0x141420fd7
0000000141420fcf  4983fb01                 cmp      r11, 1
0000000141420fd3  7439                     je       0x14142100e
0000000141420fd5  eb7b                     jmp      0x141421052
0000000141420fd7  4883fe03                 cmp      rsi, 3
0000000141420fdb  0f87bc000000             ja       0x14142109d
0000000141420fe1  f2410f1004f2             movsd    xmm0, qword ptr [r10 + rsi*8]
0000000141420fe7  f2420f1104c2             movsd    qword ptr [rdx + r8*8], xmm0
0000000141420fed  4883f803                 cmp      rax, 3
0000000141420ff1  0f87af000000             ja       0x1414210a6
0000000141420ff7  f2410f1004c2             movsd    xmm0, qword ptr [r10 + rax*8]
0000000141420ffd  f2420f1144c208           movsd    qword ptr [rdx + r8*8 + 8], xmm0
0000000141421004  4983c002                 add      r8, 2
0000000141421008  4983fb01                 cmp      r11, 1
000000014142100c  7544                     jne      0x141421052
000000014142100e  4883c130                 add      rcx, 0x30
0000000141421012  0f1001                   movups   xmm0, xmmword ptr [rcx]
0000000141421015  0f104910                 movups   xmm1, xmmword ptr [rcx + 0x10]
0000000141421019  0f2945d0                 movaps   xmmword ptr [rbp - 0x30], xmm0
000000014142101d  0f294de0                 movaps   xmmword ptr [rbp - 0x20], xmm1
0000000141421021  488b45d0                 mov      rax, qword ptr [rbp - 0x30]
0000000141421025  4c8b4dd8                 mov      r9, qword ptr [rbp - 0x28]
0000000141421029  4c39c8                   cmp      rax, r9
000000014142102c  7424                     je       0x141421052
000000014142102e  6690                     nop      
0000000141421030  488b4cc5e0               mov      rcx, qword ptr [rbp + rax*8 - 0x20]
0000000141421035  4883f904                 cmp      rcx, 4
0000000141421039  7346                     jae      0x141421081
000000014142103b  48ffc0                   inc      rax
000000014142103e  f2410f1004ca             movsd    xmm0, qword ptr [r10 + rcx*8]
0000000141421044  f2420f1104c2             movsd    qword ptr [rdx + r8*8], xmm0
000000014142104a  49ffc0                   inc      r8
000000014142104d  4939c1                   cmp      r9, rax
0000000141421050  75de                     jne      0x141421030
0000000141421052  4d8907                   mov      qword ptr [r15], r8
0000000141421055  4883c458                 add      rsp, 0x58
0000000141421059  5b                       pop      rbx
000000014142105a  5f                       pop      rdi
000000014142105b  5e                       pop      rsi
000000014142105c  415e                     pop      r14
000000014142105e  415f                     pop      r15
0000000141421060  5d                       pop      rbp
0000000141421061  c3                       ret      
0000000141421062  4c897df8                 mov      qword ptr [rbp - 8], r15
0000000141421066  4c8945f0                 mov      qword ptr [rbp - 0x10], r8
000000014142106a  4c8d057f79ee01           lea      r8, [rip + 0x1ee797f]
0000000141421071  ba04000000               mov      edx, 4
0000000141421076  4c89c9                   mov      rcx, r9
0000000141421079  e874719a01               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
000000014142107e  90                       nop      
000000014142107f  eb45                     jmp      0x1414210c6
0000000141421081  4c897df8                 mov      qword ptr [rbp - 8], r15
0000000141421085  4c8945f0                 mov      qword ptr [rbp - 0x10], r8
0000000141421089  4c8d056079ee01           lea      r8, [rip + 0x1ee7960]
0000000141421090  ba04000000               mov      edx, 4
0000000141421095  e858719a01               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
000000014142109a  90                       nop      
000000014142109b  eb29                     jmp      0x1414210c6
000000014142109d  4c897df8                 mov      qword ptr [rbp - 8], r15
00000001414210a1  4889f0                   mov      rax, rsi
00000001414210a4  eb07                     jmp      0x1414210ad
00000001414210a6  4c897df8                 mov      qword ptr [rbp - 8], r15
00000001414210aa  49ffc0                   inc      r8
00000001414210ad  4c8945f0                 mov      qword ptr [rbp - 0x10], r8
00000001414210b1  4c8d053879ee01           lea      r8, [rip + 0x1ee7938]
00000001414210b8  ba04000000               mov      edx, 4
00000001414210bd  4889c1                   mov      rcx, rax
00000001414210c0  e82d719a01               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
00000001414210c5  90                       nop      
00000001414210c6  0f0b                     ud2      
00000001414210c8  0f1f840000000000         nop      dword ptr [rax + rax]
00000001414210d0  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001414210d5  55                       push     rbp
00000001414210d6  4157                     push     r15
00000001414210d8  4156                     push     r14
00000001414210da  56                       push     rsi
00000001414210db  57                       push     rdi
00000001414210dc  53                       push     rbx
00000001414210dd  4883ec28                 sub      rsp, 0x28
00000001414210e1  488d6a50                 lea      rbp, [rdx + 0x50]
00000001414210e5  488b45f0                 mov      rax, qword ptr [rbp - 0x10]
00000001414210e9  488b4df8                 mov      rcx, qword ptr [rbp - 8]
00000001414210ed  488901                   mov      qword ptr [rcx], rax
00000001414210f0  4883c428                 add      rsp, 0x28
00000001414210f4  5b                       pop      rbx
00000001414210f5  5f                       pop      rdi
00000001414210f6  5e                       pop      rsi
00000001414210f7  415e                     pop      r14
00000001414210f9  415f                     pop      r15
00000001414210fb  5d                       pop      rbp
00000001414210fc  c3                       ret      