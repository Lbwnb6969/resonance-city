0000000140e02880  48ba2f64bd78641d76a0     movabs   rdx, 0xa0761d6478bd642f
0000000140e0288a  480311                   add      rdx, qword ptr [rcx]
0000000140e0288d  488911                   mov      qword ptr [rcx], rdx
0000000140e02890  48b8db28b4a0d17e03e7     movabs   rax, 0xe7037ed1a0b428db
0000000140e0289a  4831d0                   xor      rax, rdx
0000000140e0289d  48f7e2                   mul      rdx
0000000140e028a0  31c2                     xor      edx, eax
0000000140e028a2  c1ea09                   shr      edx, 9
0000000140e028a5  81ca0000803f             or       edx, 0x3f800000
0000000140e028ab  660f6ec2                 movd     xmm0, edx
0000000140e028af  f30f58057d460302         addss    xmm0, dword ptr [rip + 0x203467d]
0000000140e028b7  c3                       ret      