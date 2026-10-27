0000000141483e90  4157                     push     r15
0000000141483e92  4156                     push     r14
0000000141483e94  56                       push     rsi
0000000141483e95  57                       push     rdi
0000000141483e96  53                       push     rbx
0000000141483e97  4881ec50010000           sub      rsp, 0x150
0000000141483e9e  440f29bc2440010000       movaps   xmmword ptr [rsp + 0x140], xmm15
0000000141483ea7  440f29b42430010000       movaps   xmmword ptr [rsp + 0x130], xmm14
0000000141483eb0  440f29ac2420010000       movaps   xmmword ptr [rsp + 0x120], xmm13
0000000141483eb9  440f29a42410010000       movaps   xmmword ptr [rsp + 0x110], xmm12
0000000141483ec2  440f299c2400010000       movaps   xmmword ptr [rsp + 0x100], xmm11
0000000141483ecb  440f299424f0000000       movaps   xmmword ptr [rsp + 0xf0], xmm10
0000000141483ed4  440f298c24e0000000       movaps   xmmword ptr [rsp + 0xe0], xmm9
0000000141483edd  440f298424d0000000       movaps   xmmword ptr [rsp + 0xd0], xmm8
0000000141483ee6  0f29bc24c0000000         movaps   xmmword ptr [rsp + 0xc0], xmm7
0000000141483eee  0f29b424b0000000         movaps   xmmword ptr [rsp + 0xb0], xmm6
0000000141483ef6  f30f107938               movss    xmm7, dword ptr [rcx + 0x38]
0000000141483efb  0f57c0                   xorps    xmm0, xmm0
0000000141483efe  0f2ef8                   ucomiss  xmm7, xmm0
0000000141483f01  0f8288030000             jb       0x14148428f
0000000141483f07  f30f5fc1                 maxss    xmm0, xmm1
0000000141483f0b  440f28c7                 movaps   xmm8, xmm7
0000000141483f0f  f3440f5dc0               minss    xmm8, xmm0
0000000141483f14  410f28c0                 movaps   xmm0, xmm8
0000000141483f18  f30f5ec7                 divss    xmm0, xmm7
0000000141483f1c  f6411c01                 test     byte ptr [rcx + 0x1c], 1
0000000141483f20  0f8448010000             je       0x14148406e
0000000141483f26  488b4130                 mov      rax, qword ptr [rcx + 0x30]
0000000141483f2a  4889842480000000         mov      qword ptr [rsp + 0x80], rax
0000000141483f32  0f104920                 movups   xmm1, xmmword ptr [rcx + 0x20]
0000000141483f36  0f294c2470               movaps   xmmword ptr [rsp + 0x70], xmm1
0000000141483f3b  f60101                   test     byte ptr [rcx], 1
0000000141483f3e  0f842a010000             je       0x14148406e
0000000141483f44  488b4114                 mov      rax, qword ptr [rcx + 0x14]
0000000141483f48  4889442440               mov      qword ptr [rsp + 0x40], rax
0000000141483f4d  4989ce                   mov      r14, rcx
0000000141483f50  0f104104                 movups   xmm0, xmmword ptr [rcx + 4]
0000000141483f54  0f29442430               movaps   xmmword ptr [rsp + 0x30], xmm0
0000000141483f59  31f6                     xor      esi, esi
0000000141483f5b  488d5c2430               lea      rbx, [rsp + 0x30]
0000000141483f60  4889d9                   mov      rcx, rbx
0000000141483f63  31d2                     xor      edx, edx
0000000141483f65  e896c796ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483f6a  0f28f0                   movaps   xmm6, xmm0
0000000141483f6d  bf01000000               mov      edi, 1
0000000141483f72  ba01000000               mov      edx, 1
0000000141483f77  4889d9                   mov      rcx, rbx
0000000141483f7a  e881c796ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483f7f  f30f59c7                 mulss    xmm0, xmm7
0000000141483f83  f30f100dd95db801         movss    xmm1, dword ptr [rip + 0x1b85dd9]
0000000141483f8b  f30f58c8                 addss    xmm1, xmm0
0000000141483f8f  410f2ec8                 ucomiss  xmm1, xmm8
0000000141483f93  0f83df000000             jae      0x141484078
0000000141483f99  488d5c2430               lea      rbx, [rsp + 0x30]
0000000141483f9e  be01000000               mov      esi, 1
0000000141483fa3  ba01000000               mov      edx, 1
0000000141483fa8  4889d9                   mov      rcx, rbx
0000000141483fab  e850c796ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483fb0  0f28f0                   movaps   xmm6, xmm0
0000000141483fb3  bf02000000               mov      edi, 2
0000000141483fb8  ba02000000               mov      edx, 2
0000000141483fbd  4889d9                   mov      rcx, rbx
0000000141483fc0  e83bc796ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483fc5  f30f59c7                 mulss    xmm0, xmm7
0000000141483fc9  f30f100d935db801         movss    xmm1, dword ptr [rip + 0x1b85d93]
0000000141483fd1  f30f58c8                 addss    xmm1, xmm0
0000000141483fd5  410f2ec8                 ucomiss  xmm1, xmm8
0000000141483fd9  0f8399000000             jae      0x141484078
0000000141483fdf  488d5c2430               lea      rbx, [rsp + 0x30]
0000000141483fe4  be02000000               mov      esi, 2
0000000141483fe9  ba02000000               mov      edx, 2
0000000141483fee  4889d9                   mov      rcx, rbx
0000000141483ff1  e80ac796ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141483ff6  0f28f0                   movaps   xmm6, xmm0
0000000141483ff9  bf03000000               mov      edi, 3
0000000141483ffe  ba03000000               mov      edx, 3
0000000141484003  4889d9                   mov      rcx, rbx
0000000141484006  e8f5c696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
000000014148400b  f30f59c7                 mulss    xmm0, xmm7
000000014148400f  f30f100d4d5db801         movss    xmm1, dword ptr [rip + 0x1b85d4d]
0000000141484017  f30f58c8                 addss    xmm1, xmm0
000000014148401b  410f2ec8                 ucomiss  xmm1, xmm8
000000014148401f  7357                     jae      0x141484078
0000000141484021  488d5c2430               lea      rbx, [rsp + 0x30]
0000000141484026  be03000000               mov      esi, 3
000000014148402b  ba03000000               mov      edx, 3
0000000141484030  4889d9                   mov      rcx, rbx
0000000141484033  e8c8c696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141484038  0f28f0                   movaps   xmm6, xmm0
000000014148403b  bf04000000               mov      edi, 4
0000000141484040  ba04000000               mov      edx, 4
0000000141484045  4889d9                   mov      rcx, rbx
0000000141484048  e8b3c696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
000000014148404d  f30f59c7                 mulss    xmm0, xmm7
0000000141484051  f30f100d0b5db801         movss    xmm1, dword ptr [rip + 0x1b85d0b]
0000000141484059  f30f58c8                 addss    xmm1, xmm0
000000014148405d  410f2ec8                 ucomiss  xmm1, xmm8
0000000141484061  7315                     jae      0x141484078
0000000141484063  f3410f10463c             movss    xmm0, dword ptr [r14 + 0x3c]
0000000141484069  e9ba010000               jmp      0x141484228
000000014148406e  f30f59413c               mulss    xmm0, dword ptr [rcx + 0x3c]
0000000141484073  e9b0010000               jmp      0x141484228
0000000141484078  f30f59fe                 mulss    xmm7, xmm6
000000014148407c  f30f5cc7                 subss    xmm0, xmm7
0000000141484080  450f57ff                 xorps    xmm15, xmm15
0000000141484084  410f2ec7                 ucomiss  xmm0, xmm15
0000000141484088  0f824c020000             jb       0x1414842da
000000014148408e  f3440f5cc7               subss    xmm8, xmm7
0000000141484093  0f57c9                   xorps    xmm1, xmm1
0000000141484096  f3410f5fc8               maxss    xmm1, xmm8
000000014148409b  f30f5dc1                 minss    xmm0, xmm1
000000014148409f  0f298424a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm0
00000001414840a7  488d5c2470               lea      rbx, [rsp + 0x70]
00000001414840ac  4889d9                   mov      rcx, rbx
00000001414840af  4889f2                   mov      rdx, rsi
00000001414840b2  e849c696ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
00000001414840b7  0f28f0                   movaps   xmm6, xmm0
00000001414840ba  4d89f7                   mov      r15, r14
00000001414840bd  f3410f59763c             mulss    xmm6, dword ptr [r14 + 0x3c]
00000001414840c3  4c8d742430               lea      r14, [rsp + 0x30]
00000001414840c8  4c89f1                   mov      rcx, r14
00000001414840cb  4889f2                   mov      rdx, rsi
00000001414840ce  e83dfd96ff               call     0x140df3e10 ; utils::geometry::rectangle::Rectangle2d::get_point | _ZN5utils8geometry9rectangle11Rectangle2d9get_point17h50924ac2709043c3E
00000001414840d3  440f28c0                 movaps   xmm8, xmm0
00000001414840d7  440f28e9                 movaps   xmm13, xmm1
00000001414840db  4c89f1                   mov      rcx, r14
00000001414840de  4889fa                   mov      rdx, rdi
00000001414840e1  e82afd96ff               call     0x140df3e10 ; utils::geometry::rectangle::Rectangle2d::get_point | _ZN5utils8geometry9rectangle11Rectangle2d9get_point17h50924ac2709043c3E
00000001414840e6  440f28e0                 movaps   xmm12, xmm0
00000001414840ea  440f28f1                 movaps   xmm14, xmm1
00000001414840ee  4c89f1                   mov      rcx, r14
00000001414840f1  4889f2                   mov      rdx, rsi
00000001414840f4  e867d696ff               call     0x140df1760 ; utils::geometry::rectangle::Rectangle2d::get_edge_normal | _ZN5utils8geometry9rectangle11Rectangle2d15get_edge_normal17h19163fb135e59d6bE
00000001414840f9  440f28c8                 movaps   xmm9, xmm0
00000001414840fd  440f28d1                 movaps   xmm10, xmm1
0000000141484101  f3410f104740             movss    xmm0, dword ptr [r15 + 0x40]
0000000141484107  0f29842490000000         movaps   xmmword ptr [rsp + 0x90], xmm0
000000014148410f  4889d9                   mov      rcx, rbx
0000000141484112  4889f2                   mov      rdx, rsi
0000000141484115  e8f6fc96ff               call     0x140df3e10 ; utils::geometry::rectangle::Rectangle2d::get_point | _ZN5utils8geometry9rectangle11Rectangle2d9get_point17h50924ac2709043c3E
000000014148411a  0f28f8                   movaps   xmm7, xmm0
000000014148411d  440f28d9                 movaps   xmm11, xmm1
0000000141484121  4889d9                   mov      rcx, rbx
0000000141484124  4889fa                   mov      rdx, rdi
0000000141484127  e8e4fc96ff               call     0x140df3e10 ; utils::geometry::rectangle::Rectangle2d::get_point | _ZN5utils8geometry9rectangle11Rectangle2d9get_point17h50924ac2709043c3E
000000014148412c  450f14e6                 unpcklps xmm12, xmm14
0000000141484130  450f14c5                 unpcklps xmm8, xmm13
0000000141484134  450f5ce0                 subps    xmm12, xmm8
0000000141484138  410f28d4                 movaps   xmm2, xmm12
000000014148413c  410f59d4                 mulps    xmm2, xmm12
0000000141484140  f30f16da                 movshdup xmm3, xmm2
0000000141484144  f30f58da                 addss    xmm3, xmm2
0000000141484148  f30f51db                 sqrtss   xmm3, xmm3
000000014148414c  f30f1015d42d9b01         movss    xmm2, dword ptr [rip + 0x19b2dd4]
0000000141484154  0f28e2                   movaps   xmm4, xmm2
0000000141484157  f30f5ee3                 divss    xmm4, xmm3
000000014148415b  660f7ee0                 movd     eax, xmm4
000000014148415f  85c0                     test     eax, eax
0000000141484161  0f99c1                   setns    cl
0000000141484164  89c2                     mov      edx, eax
0000000141484166  81e2ffffff7f             and      edx, 0x7fffffff
000000014148416c  81c2000080ff             add      edx, 0xff800000
0000000141484172  81fa0000007f             cmp      edx, 0x7f000000
0000000141484178  0f92c2                   setb     dl
000000014148417b  20ca                     and      dl, cl
000000014148417d  ffc8                     dec      eax
000000014148417f  3dffff7f00               cmp      eax, 0x7fffff
0000000141484184  0f92c0                   setb     al
0000000141484187  08d0                     or       al, dl
0000000141484189  0f57db                   xorps    xmm3, xmm3
000000014148418c  0fc6e340                 shufps   xmm4, xmm3, 0x40
0000000141484190  410f59e4                 mulps    xmm4, xmm12
0000000141484194  0fb6c0                   movzx    eax, al
0000000141484197  660f6ed8                 movd     xmm3, eax
000000014148419b  660f70db00               pshufd   xmm3, xmm3, 0
00000001414841a0  660f72f31f               pslld    xmm3, 0x1f
00000001414841a5  660f72e31f               psrad    xmm3, 0x1f
00000001414841aa  660fdbdc                 pand     xmm3, xmm4
00000001414841ae  f30f12a424a0000000       movsldup xmm4, xmmword ptr [rsp + 0xa0]
00000001414841b7  0f59e3                   mulps    xmm4, xmm3
00000001414841ba  410f58e0                 addps    xmm4, xmm8
00000001414841be  450f14ca                 unpcklps xmm9, xmm10
00000001414841c2  f30f129c2490000000       movsldup xmm3, xmmword ptr [rsp + 0x90]
00000001414841cb  410f59d9                 mulps    xmm3, xmm9
00000001414841cf  0f58dc                   addps    xmm3, xmm4
00000001414841d2  410f14fb                 unpcklps xmm7, xmm11
00000001414841d6  0f5cdf                   subps    xmm3, xmm7
00000001414841d9  0f14c1                   unpcklps xmm0, xmm1
00000001414841dc  0f28c8                   movaps   xmm1, xmm0
00000001414841df  0f5ccf                   subps    xmm1, xmm7
00000001414841e2  0f59d9                   mulps    xmm3, xmm1
00000001414841e5  f30f16e3                 movshdup xmm4, xmm3
00000001414841e9  f30f58e3                 addss    xmm4, xmm3
00000001414841ed  0f59c9                   mulps    xmm1, xmm1
00000001414841f0  f30f16d9                 movshdup xmm3, xmm1
00000001414841f4  f30f58d9                 addss    xmm3, xmm1
00000001414841f8  f30f5f1dc02bb801         maxss    xmm3, dword ptr [rip + 0x1b82bc0]
0000000141484200  f30f5ee3                 divss    xmm4, xmm3
0000000141484204  f3440f5ffc               maxss    xmm15, xmm4
0000000141484209  f3410f5dd7               minss    xmm2, xmm15
000000014148420e  0f5cf8                   subps    xmm7, xmm0
0000000141484211  0f59ff                   mulps    xmm7, xmm7
0000000141484214  f30f16c7                 movshdup xmm0, xmm7
0000000141484218  f30f58c7                 addss    xmm0, xmm7
000000014148421c  f30f51c0                 sqrtss   xmm0, xmm0
0000000141484220  f30f59c2                 mulss    xmm0, xmm2
0000000141484224  f30f58c6                 addss    xmm0, xmm6
0000000141484228  0f28b424b0000000         movaps   xmm6, xmmword ptr [rsp + 0xb0]
0000000141484230  0f28bc24c0000000         movaps   xmm7, xmmword ptr [rsp + 0xc0]
0000000141484238  440f288424d0000000       movaps   xmm8, xmmword ptr [rsp + 0xd0]
0000000141484241  440f288c24e0000000       movaps   xmm9, xmmword ptr [rsp + 0xe0]
000000014148424a  440f289424f0000000       movaps   xmm10, xmmword ptr [rsp + 0xf0]
0000000141484253  440f289c2400010000       movaps   xmm11, xmmword ptr [rsp + 0x100]
000000014148425c  440f28a42410010000       movaps   xmm12, xmmword ptr [rsp + 0x110]
0000000141484265  440f28ac2420010000       movaps   xmm13, xmmword ptr [rsp + 0x120]
000000014148426e  440f28b42430010000       movaps   xmm14, xmmword ptr [rsp + 0x130]
0000000141484277  440f28bc2440010000       movaps   xmm15, xmmword ptr [rsp + 0x140]
0000000141484280  4881c450010000           add      rsp, 0x150
0000000141484287  5b                       pop      rbx
0000000141484288  5f                       pop      rdi
0000000141484289  5e                       pop      rsi
000000014148428a  415e                     pop      r14
000000014148428c  415f                     pop      r15
000000014148428e  c3                       ret      
000000014148428f  c744247000000000         mov      dword ptr [rsp + 0x70], 0
0000000141484297  f30f117c2430             movss    dword ptr [rsp + 0x30], xmm7
000000014148429d  488d442470               lea      rax, [rsp + 0x70]
00000001414842a2  4889442450               mov      qword ptr [rsp + 0x50], rax
00000001414842a7  488d0522c3aeff           lea      rax, [rip - 0x513cde]
00000001414842ae  4889442458               mov      qword ptr [rsp + 0x58], rax
00000001414842b3  488d4c2430               lea      rcx, [rsp + 0x30]
00000001414842b8  48894c2460               mov      qword ptr [rsp + 0x60], rcx
00000001414842bd  4889442468               mov      qword ptr [rsp + 0x68], rax
00000001414842c2  488d0d378de801           lea      rcx, [rip + 0x1e88d37]
00000001414842c9  4c8d05d08de801           lea      r8, [rip + 0x1e88dd0]
00000001414842d0  488d542450               lea      rdx, [rsp + 0x50]
00000001414842d5  e8f6409401               call     0x142dc83d0 ; core::panicking::panic_fmt | _RNvNtCs8icZUrvfcq9_4core9panicking9panic_fmt
00000001414842da  c744242800000000         mov      dword ptr [rsp + 0x28], 0
00000001414842e2  f30f1144242c             movss    dword ptr [rsp + 0x2c], xmm0
00000001414842e8  488d442428               lea      rax, [rsp + 0x28]
00000001414842ed  4889442450               mov      qword ptr [rsp + 0x50], rax
00000001414842f2  488d05d7c2aeff           lea      rax, [rip - 0x513d29]
00000001414842f9  4889442458               mov      qword ptr [rsp + 0x58], rax
00000001414842fe  488d4c242c               lea      rcx, [rsp + 0x2c]
0000000141484303  ebb3                     jmp      0x1414842b8