0000000140cd4920  55                       push     rbp
0000000140cd4921  4157                     push     r15
0000000140cd4923  4156                     push     r14
0000000140cd4925  4155                     push     r13
0000000140cd4927  4154                     push     r12
0000000140cd4929  56                       push     rsi
0000000140cd492a  57                       push     rdi
0000000140cd492b  53                       push     rbx
0000000140cd492c  4881ec88000000           sub      rsp, 0x88
0000000140cd4933  488dac2480000000         lea      rbp, [rsp + 0x80]
0000000140cd493b  0f297df0                 movaps   xmmword ptr [rbp - 0x10], xmm7
0000000140cd493f  0f2975e0                 movaps   xmmword ptr [rbp - 0x20], xmm6
0000000140cd4943  48c745d8feffffff         mov      qword ptr [rbp - 0x28], 0xfffffffffffffffe
0000000140cd494b  488b4210                 mov      rax, qword ptr [rdx + 0x10]
0000000140cd494f  4c8b7218                 mov      r14, qword ptr [rdx + 0x18]
0000000140cd4953  f048ff00                 lock inc qword ptr [rax]
0000000140cd4957  0f8e93010000             jle      0x140cd4af0
0000000140cd495d  f30f107240               movss    xmm6, dword ptr [rdx + 0x40]
0000000140cd4962  f30f107a44               movss    xmm7, dword ptr [rdx + 0x44]
0000000140cd4967  440fb65a78               movzx    r11d, byte ptr [rdx + 0x78]
0000000140cd496c  440fb64279               movzx    r8d, byte ptr [rdx + 0x79]
0000000140cd4971  448845d6                 mov      byte ptr [rbp - 0x2a], r8b
0000000140cd4975  448b4230                 mov      r8d, dword ptr [rdx + 0x30]
0000000140cd4979  448945c8                 mov      dword ptr [rbp - 0x38], r8d
0000000140cd497d  448b4234                 mov      r8d, dword ptr [rdx + 0x34]
0000000140cd4981  448945cc                 mov      dword ptr [rbp - 0x34], r8d
0000000140cd4985  448b6a38                 mov      r13d, dword ptr [rdx + 0x38]
0000000140cd4989  448b423c                 mov      r8d, dword ptr [rdx + 0x3c]
0000000140cd498d  448945d0                 mov      dword ptr [rbp - 0x30], r8d
0000000140cd4991  440fb75274               movzx    r10d, word ptr [rdx + 0x74]
0000000140cd4996  8b7264                   mov      esi, dword ptr [rdx + 0x64]
0000000140cd4999  8b7a68                   mov      edi, dword ptr [rdx + 0x68]
0000000140cd499c  0fb65a77                 movzx    ebx, byte ptr [rdx + 0x77]
0000000140cd49a0  440fb67a76               movzx    r15d, byte ptr [rdx + 0x76]
0000000140cd49a5  488945a0                 mov      qword ptr [rbp - 0x60], rax
0000000140cd49a9  4c8975a8                 mov      qword ptr [rbp - 0x58], r14
0000000140cd49ad  448b22                   mov      r12d, dword ptr [rdx]
0000000140cd49b0  4585e4                   test     r12d, r12d
0000000140cd49b3  488945c0                 mov      qword ptr [rbp - 0x40], rax
0000000140cd49b7  7406                     je       0x140cd49bf
0000000140cd49b9  4183fc01                 cmp      r12d, 1
0000000140cd49bd  750a                     jne      0x140cd49c9
0000000140cd49bf  448b4204                 mov      r8d, dword ptr [rdx + 4]
0000000140cd49c3  488b4208                 mov      rax, qword ptr [rdx + 8]
0000000140cd49c7  eb5a                     jmp      0x140cd4a23
0000000140cd49c9  44885dd7                 mov      byte ptr [rbp - 0x29], r11b
0000000140cd49cd  66448955d4               mov      word ptr [rbp - 0x2c], r10w
0000000140cd49d2  488955b8                 mov      qword ptr [rbp - 0x48], rdx
0000000140cd49d6  48894db0                 mov      qword ptr [rbp - 0x50], rcx
0000000140cd49da  e881a43aff               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
0000000140cd49df  b92c000000               mov      ecx, 0x2c
0000000140cd49e4  ba04000000               mov      edx, 4
0000000140cd49e9  e8c2709dff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
0000000140cd49ee  4885c0                   test     rax, rax
0000000140cd49f1  0f84e9000000             je       0x140cd4ae0
0000000140cd49f7  488b55b8                 mov      rdx, qword ptr [rbp - 0x48]
0000000140cd49fb  488b4a08                 mov      rcx, qword ptr [rdx + 8]
0000000140cd49ff  0f1001                   movups   xmm0, xmmword ptr [rcx]
0000000140cd4a02  0f104910                 movups   xmm1, xmmword ptr [rcx + 0x10]
0000000140cd4a06  0f10511c                 movups   xmm2, xmmword ptr [rcx + 0x1c]
0000000140cd4a0a  0f11501c                 movups   xmmword ptr [rax + 0x1c], xmm2
0000000140cd4a0e  0f114810                 movups   xmmword ptr [rax + 0x10], xmm1
0000000140cd4a12  0f1100                   movups   xmmword ptr [rax], xmm0
0000000140cd4a15  488b4db0                 mov      rcx, qword ptr [rbp - 0x50]
0000000140cd4a19  440fb755d4               movzx    r10d, word ptr [rbp - 0x2c]
0000000140cd4a1e  440fb65dd7               movzx    r11d, byte ptr [rbp - 0x29]
0000000140cd4a23  4488b9ac000000           mov      byte ptr [rcx + 0xac], r15b
0000000140cd4a2a  4c8b4dc0                 mov      r9, qword ptr [rbp - 0x40]
0000000140cd4a2e  4c894910                 mov      qword ptr [rcx + 0x10], r9
0000000140cd4a32  4c897118                 mov      qword ptr [rcx + 0x18], r14
0000000140cd4a36  44896120                 mov      dword ptr [rcx + 0x20], r12d
0000000140cd4a3a  44894124                 mov      dword ptr [rcx + 0x24], r8d
0000000140cd4a3e  48894128                 mov      qword ptr [rcx + 0x28], rax
0000000140cd4a42  c74130ff010000           mov      dword ptr [rcx + 0x30], 0x1ff
0000000140cd4a49  c7818400000000000000     mov      dword ptr [rcx + 0x84], 0
0000000140cd4a53  0f104248                 movups   xmm0, xmmword ptr [rdx + 0x48]
0000000140cd4a57  0f104a54                 movups   xmm1, xmmword ptr [rdx + 0x54]
0000000140cd4a5b  0f114134                 movups   xmmword ptr [rcx + 0x34], xmm0
0000000140cd4a5f  0f114940                 movups   xmmword ptr [rcx + 0x40], xmm1
0000000140cd4a63  f30f11715c               movss    dword ptr [rcx + 0x5c], xmm6
0000000140cd4a68  f30f117960               movss    dword ptr [rcx + 0x60], xmm7
0000000140cd4a6d  44885964                 mov      byte ptr [rcx + 0x64], r11b
0000000140cd4a71  0fb645d6                 movzx    eax, byte ptr [rbp - 0x2a]
0000000140cd4a75  884165                   mov      byte ptr [rcx + 0x65], al
0000000140cd4a78  8b45c8                   mov      eax, dword ptr [rbp - 0x38]
0000000140cd4a7b  894168                   mov      dword ptr [rcx + 0x68], eax
0000000140cd4a7e  8b45cc                   mov      eax, dword ptr [rbp - 0x34]
0000000140cd4a81  89416c                   mov      dword ptr [rcx + 0x6c], eax
0000000140cd4a84  44896970                 mov      dword ptr [rcx + 0x70], r13d
0000000140cd4a88  8b45d0                   mov      eax, dword ptr [rbp - 0x30]
0000000140cd4a8b  894174                   mov      dword ptr [rcx + 0x74], eax
0000000140cd4a8e  897178                   mov      dword ptr [rcx + 0x78], esi
0000000140cd4a91  89797c                   mov      dword ptr [rcx + 0x7c], edi
0000000140cd4a94  6644899180000000         mov      word ptr [rcx + 0x80], r10w
0000000140cd4a9c  00db                     add      bl, bl
0000000140cd4a9e  80f302                   xor      bl, 2
0000000140cd4aa1  889982000000             mov      byte ptr [rcx + 0x82], bl
0000000140cd4aa7  0f284220                 movaps   xmm0, xmmword ptr [rdx + 0x20]
0000000140cd4aab  488b426c                 mov      rax, qword ptr [rdx + 0x6c]
0000000140cd4aaf  48c1c020                 rol      rax, 0x20
0000000140cd4ab3  c74150ffffffff           mov      dword ptr [rcx + 0x50], 0xffffffff
0000000140cd4aba  48894154                 mov      qword ptr [rcx + 0x54], rax
0000000140cd4abe  0f2901                   movaps   xmmword ptr [rcx], xmm0
0000000140cd4ac1  4889c8                   mov      rax, rcx
0000000140cd4ac4  0f2875e0                 movaps   xmm6, xmmword ptr [rbp - 0x20]
0000000140cd4ac8  0f287df0                 movaps   xmm7, xmmword ptr [rbp - 0x10]
0000000140cd4acc  4881c488000000           add      rsp, 0x88
0000000140cd4ad3  5b                       pop      rbx
0000000140cd4ad4  5f                       pop      rdi
0000000140cd4ad5  5e                       pop      rsi
0000000140cd4ad6  415c                     pop      r12
0000000140cd4ad8  415d                     pop      r13
0000000140cd4ada  415e                     pop      r14
0000000140cd4adc  415f                     pop      r15
0000000140cd4ade  5d                       pop      rbp
0000000140cd4adf  c3                       ret      
0000000140cd4ae0  b904000000               mov      ecx, 4
0000000140cd4ae5  ba2c000000               mov      edx, 0x2c
0000000140cd4aea  e822330f02               call     0x142dc7e11 ; alloc::alloc::handle_alloc_error | _RNvNtCs1f2BdUxKfgg_5alloc5alloc18handle_alloc_error
0000000140cd4aef  90                       nop      
0000000140cd4af0  0f0b                     ud2      
0000000140cd4af2  66666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000140cd4b00  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000140cd4b05  55                       push     rbp
0000000140cd4b06  4157                     push     r15
0000000140cd4b08  4156                     push     r14
0000000140cd4b0a  4155                     push     r13
0000000140cd4b0c  4154                     push     r12
0000000140cd4b0e  56                       push     rsi
0000000140cd4b0f  57                       push     rdi
0000000140cd4b10  53                       push     rbx
0000000140cd4b11  4883ec48                 sub      rsp, 0x48
0000000140cd4b15  488daa80000000           lea      rbp, [rdx + 0x80]
0000000140cd4b1c  0f297c2420               movaps   xmmword ptr [rsp + 0x20], xmm7
0000000140cd4b21  0f29742430               movaps   xmmword ptr [rsp + 0x30], xmm6
0000000140cd4b26  488b45c0                 mov      rax, qword ptr [rbp - 0x40]
0000000140cd4b2a  f048ff08                 lock dec qword ptr [rax]
0000000140cd4b2e  7509                     jne      0x140cd4b39
0000000140cd4b30  488d4da0                 lea      rcx, [rbp - 0x60]
0000000140cd4b34  e8c7b2a1ff               call     0x1406efe00 ; _ZN5alloc4sync16Arc$LT$T$C$A$GT$9drop_slow17h022f42d9720ada22E | _ZN5alloc4sync16Arc$LT$T$C$A$GT$9drop_slow17h0505de1e4098bdf5E
0000000140cd4b39  0f28742430               movaps   xmm6, xmmword ptr [rsp + 0x30]
0000000140cd4b3e  0f287c2420               movaps   xmm7, xmmword ptr [rsp + 0x20]
0000000140cd4b43  4883c448                 add      rsp, 0x48
0000000140cd4b47  5b                       pop      rbx
0000000140cd4b48  5f                       pop      rdi
0000000140cd4b49  5e                       pop      rsi
0000000140cd4b4a  415c                     pop      r12
0000000140cd4b4c  415d                     pop      r13
0000000140cd4b4e  415e                     pop      r14
0000000140cd4b50  415f                     pop      r15
0000000140cd4b52  5d                       pop      rbp
0000000140cd4b53  c3                       ret      