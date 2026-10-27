0000000141489480  4157                     push     r15
0000000141489482  4156                     push     r14
0000000141489484  56                       push     rsi
0000000141489485  57                       push     rdi
0000000141489486  53                       push     rbx
0000000141489487  4881ec70010000           sub      rsp, 0x170
000000014148948e  440f29b42460010000       movaps   xmmword ptr [rsp + 0x160], xmm14
0000000141489497  440f29ac2450010000       movaps   xmmword ptr [rsp + 0x150], xmm13
00000001414894a0  440f29a42440010000       movaps   xmmword ptr [rsp + 0x140], xmm12
00000001414894a9  440f299c2430010000       movaps   xmmword ptr [rsp + 0x130], xmm11
00000001414894b2  440f29942420010000       movaps   xmmword ptr [rsp + 0x120], xmm10
00000001414894bb  440f298c2410010000       movaps   xmmword ptr [rsp + 0x110], xmm9
00000001414894c4  440f29842400010000       movaps   xmmword ptr [rsp + 0x100], xmm8
00000001414894cd  0f29bc24f0000000         movaps   xmmword ptr [rsp + 0xf0], xmm7
00000001414894d5  0f29b424e0000000         movaps   xmmword ptr [rsp + 0xe0], xmm6
00000001414894dd  4d89c6                   mov      r14, r8
00000001414894e0  4889d7                   mov      rdi, rdx
00000001414894e3  4889ce                   mov      rsi, rcx
00000001414894e6  0fb69c24d0010000         movzx    ebx, byte ptr [rsp + 0x1d0]
00000001414894ee  488b8424c8010000         mov      rax, qword ptr [rsp + 0x1c8]
00000001414894f6  0fb68c24c0010000         movzx    ecx, byte ptr [rsp + 0x1c0]
00000001414894fe  f30f115c2428             movss    dword ptr [rsp + 0x28], xmm3
0000000141489504  884c2427                 mov      byte ptr [rsp + 0x27], cl
0000000141489508  660f76c0                 pcmpeqd  xmm0, xmm0
000000014148950c  660f7f442440             movdqa   xmmword ptr [rsp + 0x40], xmm0
0000000141489512  803800                   cmp      byte ptr [rax], 0
0000000141489515  488d4008                 lea      rax, [rax + 8]
0000000141489519  488d4c2440               lea      rcx, [rsp + 0x40]
000000014148951e  480f45c8                 cmovne   rcx, rax
0000000141489522  0f1001                   movups   xmm0, xmmword ptr [rcx]
0000000141489525  0f29442430               movaps   xmmword ptr [rsp + 0x30], xmm0
000000014148952a  41f6401c01               test     byte ptr [r8 + 0x1c], 1
000000014148952f  0f8457010000             je       0x14148968c
0000000141489535  498b4630                 mov      rax, qword ptr [r14 + 0x30]
0000000141489539  4889442450               mov      qword ptr [rsp + 0x50], rax
000000014148953e  410f104620               movups   xmm0, xmmword ptr [r14 + 0x20]
0000000141489543  0f29442440               movaps   xmmword ptr [rsp + 0x40], xmm0
0000000141489548  4c8d7c2440               lea      r15, [rsp + 0x40]
000000014148954d  4c89f9                   mov      rcx, r15
0000000141489550  31d2                     xor      edx, edx
0000000141489552  e8a97196ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
0000000141489557  0f28f0                   movaps   xmm6, xmm0
000000014148955a  f3450f10763c             movss    xmm14, dword ptr [r14 + 0x3c]
0000000141489560  ba01000000               mov      edx, 1
0000000141489565  4c89f9                   mov      rcx, r15
0000000141489568  e8937196ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
000000014148956d  0f28f8                   movaps   xmm7, xmm0
0000000141489570  ba01000000               mov      edx, 1
0000000141489575  4c89f9                   mov      rcx, r15
0000000141489578  e8837196ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
000000014148957d  440f28c0                 movaps   xmm8, xmm0
0000000141489581  ba02000000               mov      edx, 2
0000000141489586  4c89f9                   mov      rcx, r15
0000000141489589  e8727196ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
000000014148958e  440f28d0                 movaps   xmm10, xmm0
0000000141489592  ba02000000               mov      edx, 2
0000000141489597  4c89f9                   mov      rcx, r15
000000014148959a  e8617196ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
000000014148959f  440f28c8                 movaps   xmm9, xmm0
00000001414895a3  ba03000000               mov      edx, 3
00000001414895a8  4c89f9                   mov      rcx, r15
00000001414895ab  e8507196ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
00000001414895b0  440f28d8                 movaps   xmm11, xmm0
00000001414895b4  ba03000000               mov      edx, 3
00000001414895b9  4c89f9                   mov      rcx, r15
00000001414895bc  e83f7196ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
00000001414895c1  440f28e0                 movaps   xmm12, xmm0
00000001414895c5  ba04000000               mov      edx, 4
00000001414895ca  4c89f9                   mov      rcx, r15
00000001414895cd  e82e7196ff               call     0x140df0700 ; utils::geometry::rectangle::Rectangle2d::get_point_u | _ZN5utils8geometry9rectangle11Rectangle2d11get_point_u17h1b3b998b370a5667E
00000001414895d2  440f28e8                 movaps   xmm13, xmm0
00000001414895d6  4889f9                   mov      rcx, rdi
00000001414895d9  89da                     mov      edx, ebx
00000001414895db  e8b06b4aff               call     0x140930190 ; country_core::resources::walls::public_wall_state::PublicWallState::wooden_stone_foundation_surface_top_y | _ZN12country_core9resources5walls17public_wall_state15PublicWallState37wooden_stone_foundation_surface_top_y17h6256acfd832f12b4E
00000001414895e0  a801                     test     al, 1
00000001414895e2  7508                     jne      0x1414895ec
00000001414895e4  f30f108778020000         movss    xmm0, dword ptr [rdi + 0x278]
00000001414895ec  f30f1144242c             movss    dword ptr [rsp + 0x2c], xmm0
00000001414895f2  488d442430               lea      rax, [rsp + 0x30]
00000001414895f7  4889442440               mov      qword ptr [rsp + 0x40], rax
00000001414895fc  488d442427               lea      rax, [rsp + 0x27]
0000000141489601  4889442448               mov      qword ptr [rsp + 0x48], rax
0000000141489606  488d442428               lea      rax, [rsp + 0x28]
000000014148960b  4889442450               mov      qword ptr [rsp + 0x50], rax
0000000141489610  48897c2458               mov      qword ptr [rsp + 0x58], rdi
0000000141489615  488d44242c               lea      rax, [rsp + 0x2c]
000000014148961a  4889442460               mov      qword ptr [rsp + 0x60], rax
000000014148961f  48c744246800000000       mov      qword ptr [rsp + 0x68], 0
0000000141489628  48c744247004000000       mov      qword ptr [rsp + 0x70], 4
0000000141489631  0f14f7                   unpcklps xmm6, xmm7
0000000141489634  450f14c2                 unpcklps xmm8, xmm10
0000000141489638  410f16f0                 movlhps  xmm6, xmm8
000000014148963c  450fc6f600               shufps   xmm14, xmm14, 0
0000000141489641  410f59f6                 mulps    xmm6, xmm14
0000000141489645  0f11742478               movups   xmmword ptr [rsp + 0x78], xmm6
000000014148964a  450f14cb                 unpcklps xmm9, xmm11
000000014148964e  450f14e5                 unpcklps xmm12, xmm13
0000000141489652  450f16cc                 movlhps  xmm9, xmm12
0000000141489656  450f59ce                 mulps    xmm9, xmm14
000000014148965a  440f118c2488000000       movups   xmmword ptr [rsp + 0x88], xmm9
0000000141489663  48c78424c000000000000000 mov      qword ptr [rsp + 0xc0], 0
000000014148966f  0f57c0                   xorps    xmm0, xmm0
0000000141489672  0f11842498000000         movups   xmmword ptr [rsp + 0x98], xmm0
000000014148967a  488d542440               lea      rdx, [rsp + 0x40]
000000014148967f  4889f1                   mov      rcx, rsi
0000000141489682  e8995ff6ff               call     0x1413ef620 ; _ZN98_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$alloc..vec..spec_from_iter..SpecFromIter$LT$T$C$I$GT$$GT$9from_iter17he6adc64b5a383e96E | alloc::vec::spec_from_iter::impl$0::from_iter<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceRegion,core::iter::adapters::flatten::FlatMap<core::iter::adapters::enumerate::Enumerate<core::array::iter::IntoIter<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceXRange,4> >,alloc::vec::Vec<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallspaceRegion,alloc::alloc::Global>,system_wall_constructor::construct_wooden_walls::construct_wall_boards::plan_rectangle_wallspace_regions::closure_env$0> >
0000000141489687  e98a000000               jmp      0x141489716
000000014148968c  0f28f3                   movaps   xmm6, xmm3
000000014148968f  4889f9                   mov      rcx, rdi
0000000141489692  89da                     mov      edx, ebx
0000000141489694  e8f76a4aff               call     0x140930190 ; country_core::resources::walls::public_wall_state::PublicWallState::wooden_stone_foundation_surface_top_y | _ZN12country_core9resources5walls17public_wall_state15PublicWallState37wooden_stone_foundation_surface_top_y17h6256acfd832f12b4E
0000000141489699  0f28f8                   movaps   xmm7, xmm0
000000014148969c  a801                     test     al, 1
000000014148969e  7508                     jne      0x1414896a8
00000001414896a0  f30f10bf78020000         movss    xmm7, dword ptr [rdi + 0x278]
00000001414896a8  f30f100524e49a01         movss    xmm0, dword ptr [rip + 0x19ae424]
00000001414896b0  f30f58c7                 addss    xmm0, xmm7
00000001414896b4  0f2ec6                   ucomiss  xmm0, xmm6
00000001414896b7  734b                     jae      0x141489704
00000001414896b9  e8a257bffe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
00000001414896be  b928000000               mov      ecx, 0x28
00000001414896c3  ba08000000               mov      edx, 8
00000001414896c8  e8e32322ff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
00000001414896cd  4885c0                   test     rax, rax
00000001414896d0  0f84a1000000             je       0x141489777
00000001414896d6  f3410f10463c             movss    xmm0, dword ptr [r14 + 0x3c]
00000001414896dc  48c70000000000           mov      qword ptr [rax], 0
00000001414896e3  c7401000000000           mov      dword ptr [rax + 0x10], 0
00000001414896ea  f30f117814               movss    dword ptr [rax + 0x14], xmm7
00000001414896ef  f30f114018               movss    dword ptr [rax + 0x18], xmm0
00000001414896f4  f30f11701c               movss    dword ptr [rax + 0x1c], xmm6
00000001414896f9  c6402000                 mov      byte ptr [rax + 0x20], 0
00000001414896fd  b901000000               mov      ecx, 1
0000000141489702  eb07                     jmp      0x14148970b
0000000141489704  b808000000               mov      eax, 8
0000000141489709  31c9                     xor      ecx, ecx
000000014148970b  48890e                   mov      qword ptr [rsi], rcx
000000014148970e  48894608                 mov      qword ptr [rsi + 8], rax
0000000141489712  48894e10                 mov      qword ptr [rsi + 0x10], rcx
0000000141489716  4889f0                   mov      rax, rsi
0000000141489719  0f28b424e0000000         movaps   xmm6, xmmword ptr [rsp + 0xe0]
0000000141489721  0f28bc24f0000000         movaps   xmm7, xmmword ptr [rsp + 0xf0]
0000000141489729  440f28842400010000       movaps   xmm8, xmmword ptr [rsp + 0x100]
0000000141489732  440f288c2410010000       movaps   xmm9, xmmword ptr [rsp + 0x110]
000000014148973b  440f28942420010000       movaps   xmm10, xmmword ptr [rsp + 0x120]
0000000141489744  440f289c2430010000       movaps   xmm11, xmmword ptr [rsp + 0x130]
000000014148974d  440f28a42440010000       movaps   xmm12, xmmword ptr [rsp + 0x140]
0000000141489756  440f28ac2450010000       movaps   xmm13, xmmword ptr [rsp + 0x150]
000000014148975f  440f28b42460010000       movaps   xmm14, xmmword ptr [rsp + 0x160]
0000000141489768  4881c470010000           add      rsp, 0x170
000000014148976f  5b                       pop      rbx
0000000141489770  5f                       pop      rdi
0000000141489771  5e                       pop      rsi
0000000141489772  415e                     pop      r14
0000000141489774  415f                     pop      r15
0000000141489776  c3                       ret      
0000000141489777  b908000000               mov      ecx, 8
000000014148977c  ba28000000               mov      edx, 0x28
0000000141489781  e88be69301               call     0x142dc7e11 ; alloc::alloc::handle_alloc_error | _RNvNtCs1f2BdUxKfgg_5alloc5alloc18handle_alloc_error
0000000141489786  cc                       int3     