0000000141420320  55                       push     rbp
0000000141420321  4157                     push     r15
0000000141420323  4156                     push     r14
0000000141420325  4155                     push     r13
0000000141420327  4154                     push     r12
0000000141420329  56                       push     rsi
000000014142032a  57                       push     rdi
000000014142032b  53                       push     rbx
000000014142032c  4881ece8000000           sub      rsp, 0xe8
0000000141420333  488dac2480000000         lea      rbp, [rsp + 0x80]
000000014142033b  440f295550               movaps   xmmword ptr [rbp + 0x50], xmm10
0000000141420340  440f294d40               movaps   xmmword ptr [rbp + 0x40], xmm9
0000000141420345  440f294530               movaps   xmmword ptr [rbp + 0x30], xmm8
000000014142034a  0f297d20                 movaps   xmmword ptr [rbp + 0x20], xmm7
000000014142034e  0f297510                 movaps   xmmword ptr [rbp + 0x10], xmm6
0000000141420352  48c74508feffffff         mov      qword ptr [rbp + 8], 0xfffffffffffffffe
000000014142035a  4c8b7920                 mov      r15, qword ptr [rcx + 0x20]
000000014142035e  4c8b6128                 mov      r12, qword ptr [rcx + 0x28]
0000000141420362  488b02                   mov      rax, qword ptr [rdx]
0000000141420365  488945e8                 mov      qword ptr [rbp - 0x18], rax
0000000141420369  4c8b4208                 mov      r8, qword ptr [rdx + 8]
000000014142036d  4d29fc                   sub      r12, r15
0000000141420370  7532                     jne      0x1414203a4
0000000141420372  488b45e8                 mov      rax, qword ptr [rbp - 0x18]
0000000141420376  4c8900                   mov      qword ptr [rax], r8
0000000141420379  0f287510                 movaps   xmm6, xmmword ptr [rbp + 0x10]
000000014142037d  0f287d20                 movaps   xmm7, xmmword ptr [rbp + 0x20]
0000000141420381  440f284530               movaps   xmm8, xmmword ptr [rbp + 0x30]
0000000141420386  440f284d40               movaps   xmm9, xmmword ptr [rbp + 0x40]
000000014142038b  440f285550               movaps   xmm10, xmmword ptr [rbp + 0x50]
0000000141420390  4881c4e8000000           add      rsp, 0xe8
0000000141420397  5b                       pop      rbx
0000000141420398  5f                       pop      rdi
0000000141420399  5e                       pop      rsi
000000014142039a  415c                     pop      r12
000000014142039c  415d                     pop      r13
000000014142039e  415e                     pop      r14
00000001414203a0  415f                     pop      r15
00000001414203a2  5d                       pop      rbp
00000001414203a3  c3                       ret      
00000001414203a4  4c8b29                   mov      r13, qword ptr [rcx]
00000001414203a7  488b4110                 mov      rax, qword ptr [rcx + 0x10]
00000001414203ab  488945d8                 mov      qword ptr [rbp - 0x28], rax
00000001414203af  488b7130                 mov      rsi, qword ptr [rcx + 0x30]
00000001414203b3  488b7938                 mov      rdi, qword ptr [rcx + 0x38]
00000001414203b7  488b5a10                 mov      rbx, qword ptr [rdx + 0x10]
00000001414203bb  4531f6                   xor      r14d, r14d
00000001414203be  0f57ff                   xorps    xmm7, xmm7
00000001414203c1  f3440f10055e6ba101       movss    xmm8, dword ptr [rip + 0x1a16b5e]
00000001414203ca  eb44                     jmp      0x141420410
00000001414203cc  0f1f4000                 nop      dword ptr [rax]
00000001414203d0  f30f1045f8               movss    xmm0, dword ptr [rbp - 8]
00000001414203d5  f30f104d00               movss    xmm1, dword ptr [rbp]
00000001414203da  49ffc6                   inc      r14
00000001414203dd  4c8b45e0                 mov      r8, qword ptr [rbp - 0x20]
00000001414203e1  4b8d0480                 lea      rax, [r8 + r8*4]
00000001414203e5  f30f110483               movss    dword ptr [rbx + rax*4], xmm0
00000001414203ea  f30f114c8304             movss    dword ptr [rbx + rax*4 + 4], xmm1
00000001414203f0  f30f11748308             movss    dword ptr [rbx + rax*4 + 8], xmm6
00000001414203f6  f3440f1154830c           movss    dword ptr [rbx + rax*4 + 0xc], xmm10
00000001414203fd  f3440f114c8310           movss    dword ptr [rbx + rax*4 + 0x10], xmm9
0000000141420404  49ffc0                   inc      r8
0000000141420407  4d39e6                   cmp      r14, r12
000000014142040a  0f8462ffffff             je       0x141420372
0000000141420410  4c8945e0                 mov      qword ptr [rbp - 0x20], r8
0000000141420414  4b8d043e                 lea      rax, [r14 + r15]
0000000141420418  488d0c40                 lea      rcx, [rax + rax*2]
000000014142041c  488b55d8                 mov      rdx, qword ptr [rbp - 0x28]
0000000141420420  f3440f100c82             movss    xmm9, dword ptr [rdx + rax*4]
0000000141420426  418b448d08               mov      eax, dword ptr [r13 + rcx*4 + 8]
000000014142042b  894500                   mov      dword ptr [rbp], eax
000000014142042e  498b448d00               mov      rax, qword ptr [r13 + rcx*4]
0000000141420433  488945f8                 mov      qword ptr [rbp - 8], rax
0000000141420437  418b448d08               mov      eax, dword ptr [r13 + rcx*4 + 8]
000000014142043c  8945b8                   mov      dword ptr [rbp - 0x48], eax
000000014142043f  498b448d00               mov      rax, qword ptr [r13 + rcx*4]
0000000141420444  488945b0                 mov      qword ptr [rbp - 0x50], rax
0000000141420448  488d4db0                 lea      rcx, [rbp - 0x50]
000000014142044c  4889f2                   mov      rdx, rsi
000000014142044f  e8cca09cff               call     0x140dea520 ; utils::wall_space::WallSpaceCoord::from_world_space | _ZN5utils10wall_space14WallSpaceCoord16from_world_space17hd8792f152ea4f085E
0000000141420454  90                       nop      
0000000141420455  4889f9                   mov      rcx, rdi
0000000141420458  0f28c8                   movaps   xmm1, xmm0
000000014142045b  e8303a0600               call     0x141483e90 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::BoardWallSpace::remap_x | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards14BoardWallSpace7remap_x17hac10aa8678e4b041E
0000000141420460  90                       nop      
0000000141420461  0f28f0                   movaps   xmm6, xmm0
0000000141420464  f3440f1055fc             movss    xmm10, dword ptr [rbp - 4]
000000014142046a  488d471c                 lea      rax, [rdi + 0x1c]
000000014142046e  833802                   cmp      dword ptr [rax], 2
0000000141420471  0f8459ffffff             je       0x1414203d0
0000000141420477  0f1000                   movups   xmm0, xmmword ptr [rax]
000000014142047a  0f10480c                 movups   xmm1, xmmword ptr [rax + 0xc]
000000014142047e  0f114dbc                 movups   xmmword ptr [rbp - 0x44], xmm1
0000000141420482  0f2945b0                 movaps   xmmword ptr [rbp - 0x50], xmm0
0000000141420486  488d4df8                 lea      rcx, [rbp - 8]
000000014142048a  4889f2                   mov      rdx, rsi
000000014142048d  e88ea09cff               call     0x140dea520 ; utils::wall_space::WallSpaceCoord::from_world_space | _ZN5utils10wall_space14WallSpaceCoord16from_world_space17hd8792f152ea4f085E
0000000141420492  90                       nop      
0000000141420493  4889f9                   mov      rcx, rdi
0000000141420496  0f28c8                   movaps   xmm1, xmm0
0000000141420499  e8f2390600               call     0x141483e90 ; system_wall_constructor::construct_wooden_walls::construct_wall_boards::BoardWallSpace::remap_x | _ZN23system_wall_constructor22construct_wooden_walls21construct_wall_boards14BoardWallSpace7remap_x17hac10aa8678e4b041E
000000014142049e  90                       nop      
000000014142049f  f30f5e473c               divss    xmm0, dword ptr [rdi + 0x3c]
00000001414204a4  f30f1145f4               movss    dword ptr [rbp - 0xc], xmm0
00000001414204a9  0f2ec7                   ucomiss  xmm0, xmm7
00000001414204ac  7218                     jb       0x1414204c6
00000001414204ae  440f2ec0                 ucomiss  xmm8, xmm0
00000001414204b2  7212                     jb       0x1414204c6
00000001414204b4  488d4db0                 lea      rcx, [rbp - 0x50]
00000001414204b8  0f28c8                   movaps   xmm1, xmm0
00000001414204bb  e8004966ff               call     0x140a84dc0 ; country_core::systems::wall::valid_enclosure::ShapeParameters::get_pos_at_u | _ZN12country_core7systems4wall15valid_enclosure15ShapeParameters12get_pos_at_u17h02aeaf0ab4264c8aE
00000001414204c0  90                       nop      
00000001414204c1  e914ffffff               jmp      0x1414203da
00000001414204c6  488d45f4                 lea      rax, [rbp - 0xc]
00000001414204ca  488945a0                 mov      qword ptr [rbp - 0x60], rax
00000001414204ce  488d05eb0ab5ff           lea      rax, [rip - 0x4af515]
00000001414204d5  488945a8                 mov      qword ptr [rbp - 0x58], rax
00000001414204d9  488d0dd075ee01           lea      rcx, [rip + 0x1ee75d0]
00000001414204e0  4c8d0559ccee01           lea      r8, [rip + 0x1eecc59]
00000001414204e7  488d55a0                 lea      rdx, [rbp - 0x60]
00000001414204eb  e8e07e9a01               call     0x142dc83d0 ; core::panicking::panic_fmt | _RNvNtCs8icZUrvfcq9_4core9panicking9panic_fmt
00000001414204f0  90                       nop      
00000001414204f1  0f0b                     ud2      
00000001414204f3  666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141420500  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141420505  55                       push     rbp
0000000141420506  4157                     push     r15
0000000141420508  4156                     push     r14
000000014142050a  4155                     push     r13
000000014142050c  4154                     push     r12
000000014142050e  56                       push     rsi
000000014142050f  57                       push     rdi
0000000141420510  53                       push     rbx
0000000141420511  4883ec78                 sub      rsp, 0x78
0000000141420515  488daa80000000           lea      rbp, [rdx + 0x80]
000000014142051c  440f29542420             movaps   xmmword ptr [rsp + 0x20], xmm10
0000000141420522  440f294c2430             movaps   xmmword ptr [rsp + 0x30], xmm9
0000000141420528  440f29442440             movaps   xmmword ptr [rsp + 0x40], xmm8
000000014142052e  0f297c2450               movaps   xmmword ptr [rsp + 0x50], xmm7
0000000141420533  0f29742460               movaps   xmmword ptr [rsp + 0x60], xmm6
0000000141420538  488b45e8                 mov      rax, qword ptr [rbp - 0x18]
000000014142053c  488b4de0                 mov      rcx, qword ptr [rbp - 0x20]
0000000141420540  488908                   mov      qword ptr [rax], rcx
0000000141420543  0f28742460               movaps   xmm6, xmmword ptr [rsp + 0x60]
0000000141420548  0f287c2450               movaps   xmm7, xmmword ptr [rsp + 0x50]
000000014142054d  440f28442440             movaps   xmm8, xmmword ptr [rsp + 0x40]
0000000141420553  440f284c2430             movaps   xmm9, xmmword ptr [rsp + 0x30]
0000000141420559  440f28542420             movaps   xmm10, xmmword ptr [rsp + 0x20]
000000014142055f  4883c478                 add      rsp, 0x78
0000000141420563  5b                       pop      rbx
0000000141420564  5f                       pop      rdi
0000000141420565  5e                       pop      rsi
0000000141420566  415c                     pop      r12
0000000141420568  415d                     pop      r13
000000014142056a  415e                     pop      r14
000000014142056c  415f                     pop      r15
000000014142056e  5d                       pop      rbp
000000014142056f  c3                       ret      