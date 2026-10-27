000000014092fa10  31c0                     xor      eax, eax
000000014092fa12  83b95802000002           cmp      dword ptr [rcx + 0x258], 2
000000014092fa19  488d8958020000           lea      rcx, [rcx + 0x258]
000000014092fa20  480f42c1                 cmovb    rax, rcx
000000014092fa24  c3                       ret      