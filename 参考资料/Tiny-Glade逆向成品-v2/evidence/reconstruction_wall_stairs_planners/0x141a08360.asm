0000000141a08360  56                       push     rsi
0000000141a08361  53                       push     rbx
0000000141a08362  488b442438               mov      rax, qword ptr [rsp + 0x38]
0000000141a08367  83792001                 cmp      dword ptr [rcx + 0x20], 1
0000000141a0836b  7510                     jne      0x141a0837d
0000000141a0836d  44394124                 cmp      dword ptr [rcx + 0x24], r8d
0000000141a08371  750a                     jne      0x141a0837d
0000000141a08373  44394928                 cmp      dword ptr [rcx + 0x28], r9d
0000000141a08377  0f8487000000             je       0x141a08404
0000000141a0837d  83792c00                 cmp      dword ptr [rcx + 0x2c], 0
0000000141a08381  7423                     je       0x141a083a6
0000000141a08383  f6808400000001           test     byte ptr [rax + 0x84], 1
0000000141a0838a  741a                     je       0x141a083a6
0000000141a0838c  448b9088000000           mov      r10d, dword ptr [rax + 0x88]
0000000141a08393  44395130                 cmp      dword ptr [rcx + 0x30], r10d
0000000141a08397  750d                     jne      0x141a083a6
0000000141a08399  448b908c000000           mov      r10d, dword ptr [rax + 0x8c]
0000000141a083a0  44395134                 cmp      dword ptr [rcx + 0x34], r10d
0000000141a083a4  745e                     je       0x141a08404
0000000141a083a6  f6411401                 test     byte ptr [rcx + 0x14], 1
0000000141a083aa  7414                     je       0x141a083c0
0000000141a083ac  448b5068                 mov      r10d, dword ptr [rax + 0x68]
0000000141a083b0  4485511c                 test     dword ptr [rcx + 0x1c], r10d
0000000141a083b4  744e                     je       0x141a08404
0000000141a083b6  448b5118                 mov      r10d, dword ptr [rcx + 0x18]
0000000141a083ba  4485506c                 test     dword ptr [rax + 0x6c], r10d
0000000141a083be  7444                     je       0x141a08404
0000000141a083c0  448b5110                 mov      r10d, dword ptr [rcx + 0x10]
0000000141a083c4  4585d2                   test     r10d, r10d
0000000141a083c7  0f849b000000             je       0x141a08468
0000000141a083cd  4489d6                   mov      esi, r10d
0000000141a083d0  83e608                   and      esi, 8
0000000141a083d3  c1ee03                   shr      esi, 3
0000000141a083d6  440fb698ac000000         movzx    r11d, byte ptr [rax + 0xac]
0000000141a083de  4484de                   test     sil, r11b
0000000141a083e1  7521                     jne      0x141a08404
0000000141a083e3  41f6c210                 test     r10b, 0x10
0000000141a083e7  0f94c3                   sete     bl
0000000141a083ea  4408db                   or       bl, r11b
0000000141a083ed  f6c301                   test     bl, 1
0000000141a083f0  7412                     je       0x141a08404
0000000141a083f2  448b9884000000           mov      r11d, dword ptr [rax + 0x84]
0000000141a083f9  4585db                   test     r11d, r11d
0000000141a083fc  0f94c3                   sete     bl
0000000141a083ff  4184da                   test     r10b, bl
0000000141a08402  7405                     je       0x141a08409
0000000141a08404  31c0                     xor      eax, eax
0000000141a08406  5b                       pop      rbx
0000000141a08407  5e                       pop      rsi
0000000141a08408  c3                       ret      
0000000141a08409  41f6c301                 test     r11b, 1
0000000141a0840d  7459                     je       0x141a08468
0000000141a0840f  448b9888000000           mov      r11d, dword ptr [rax + 0x88]
0000000141a08416  4c395a10                 cmp      qword ptr [rdx + 0x10], r11
0000000141a0841a  764c                     jbe      0x141a08468
0000000141a0841c  488b5208                 mov      rdx, qword ptr [rdx + 8]
0000000141a08420  4d69dba0010000           imul     r11, r11, 0x1a0
0000000141a08427  31f6                     xor      esi, esi
0000000141a08429  4a3b741a40               cmp      rsi, qword ptr [rdx + r11 + 0x40]
0000000141a0842e  7038                     jo       0x141a08468
0000000141a08430  8bb08c000000             mov      esi, dword ptr [rax + 0x8c]
0000000141a08436  4c01da                   add      rdx, r11
0000000141a08439  39b290010000             cmp      dword ptr [rdx + 0x190], esi
0000000141a0843f  7527                     jne      0x141a08468
0000000141a08441  0fb69285010000           movzx    edx, byte ptr [rdx + 0x185]
0000000141a08448  41f6c201                 test     r10b, 1
0000000141a0844c  7405                     je       0x141a08453
0000000141a0844e  80fa01                   cmp      dl, 1
0000000141a08451  74b1                     je       0x141a08404
0000000141a08453  41f6c202                 test     r10b, 2
0000000141a08457  7405                     je       0x141a0845e
0000000141a08459  80fa01                   cmp      dl, 1
0000000141a0845c  77a6                     ja       0x141a08404
0000000141a0845e  41f6c204                 test     r10b, 4
0000000141a08462  7404                     je       0x141a08468
0000000141a08464  84d2                     test     dl, dl
0000000141a08466  749c                     je       0x141a08404
0000000141a08468  488b11                   mov      rdx, qword ptr [rcx]
0000000141a0846b  4885d2                   test     rdx, rdx
0000000141a0846e  7419                     je       0x141a08489
0000000141a08470  488b4908                 mov      rcx, qword ptr [rcx + 8]
0000000141a08474  4c8b5128                 mov      r10, qword ptr [rcx + 0x28]
0000000141a08478  4889d1                   mov      rcx, rdx
0000000141a0847b  4489c2                   mov      edx, r8d
0000000141a0847e  4589c8                   mov      r8d, r9d
0000000141a08481  4989c1                   mov      r9, rax
0000000141a08484  5b                       pop      rbx
0000000141a08485  5e                       pop      rsi
0000000141a08486  49ffe2                   jmp      r10
0000000141a08489  b001                     mov      al, 1
0000000141a0848b  e976ffffff               jmp      0x141a08406