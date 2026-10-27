0000000141483630  55                       push     rbp
0000000141483631  4157                     push     r15
0000000141483633  4156                     push     r14
0000000141483635  4155                     push     r13
0000000141483637  4154                     push     r12
0000000141483639  56                       push     rsi
000000014148363a  57                       push     rdi
000000014148363b  53                       push     rbx
000000014148363c  4881ec18010000           sub      rsp, 0x118
0000000141483643  488dac2480000000         lea      rbp, [rsp + 0x80]
000000014148364b  440f298d80000000         movaps   xmmword ptr [rbp + 0x80], xmm9
0000000141483653  440f294570               movaps   xmmword ptr [rbp + 0x70], xmm8
0000000141483658  0f297d60                 movaps   xmmword ptr [rbp + 0x60], xmm7
000000014148365c  0f297550                 movaps   xmmword ptr [rbp + 0x50], xmm6
0000000141483660  48c74548feffffff         mov      qword ptr [rbp + 0x48], 0xfffffffffffffffe
0000000141483668  4d89c4                   mov      r12, r8
000000014148366b  4889d3                   mov      rbx, rdx
000000014148366e  4989ce                   mov      r14, rcx
0000000141483671  488b8290000000           mov      rax, qword ptr [rdx + 0x90]
0000000141483678  488b8a98000000           mov      rcx, qword ptr [rdx + 0x98]
000000014148367f  488d1449                 lea      rdx, [rcx + rcx*2]
0000000141483683  488d1490                 lea      rdx, [rax + rdx*4]
0000000141483687  4c8b83e0000000           mov      r8, qword ptr [rbx + 0xe0]
000000014148368e  4c8b8be8000000           mov      r9, qword ptr [rbx + 0xe8]
0000000141483695  4f8d1488                 lea      r10, [r8 + r9*4]
0000000141483699  4939c9                   cmp      r9, rcx
000000014148369c  490f42c9                 cmovb    rcx, r9
00000001414836a0  488945d0                 mov      qword ptr [rbp - 0x30], rax
00000001414836a4  488955d8                 mov      qword ptr [rbp - 0x28], rdx
00000001414836a8  4c8945e0                 mov      qword ptr [rbp - 0x20], r8
00000001414836ac  4c8955e8                 mov      qword ptr [rbp - 0x18], r10
00000001414836b0  48c745f000000000         mov      qword ptr [rbp - 0x10], 0
00000001414836b8  48894df8                 mov      qword ptr [rbp - 8], rcx
00000001414836bc  48895d00                 mov      qword ptr [rbp], rbx
00000001414836c0  4c896508                 mov      qword ptr [rbp + 8], r12
00000001414836c4  488d4da8                 lea      rcx, [rbp - 0x58]
00000001414836c8  488d55d0                 lea      rdx, [rbp - 0x30]
00000001414836cc  e8efaff6ff               call     0x1413ee6c0 ; _ZN98_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$alloc..vec..spec_from_iter..SpecFromIter$LT$T$C$I$GT$$GT$9from_iter17hc29b488141464911E | alloc::vec::spec_from_iter::impl$0::from_iter<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSample,core::iter::adapters::map::Map<core::iter::adapters::zip::Zip<core::slice::iter::Iter<glam::f32::vec3::Vec3>,core::slice::iter::Iter<f32> >,system_wall_constructor::construct_wooden_walls::construct_wall_boards::impl$2::new::closure_env$0> >
00000001414836d1  488b7db0                 mov      rdi, qword ptr [rbp - 0x50]
00000001414836d5  4c8b7db8                 mov      r15, qword ptr [rbp - 0x48]
00000001414836d9  488d4545                 lea      rax, [rbp + 0x45]
00000001414836dd  488945d0                 mov      qword ptr [rbp - 0x30], rax
00000001414836e1  4983ff02                 cmp      r15, 2
00000001414836e5  0f8388020000             jae      0x141483973
00000001414836eb  4d85ff                   test     r15, r15
00000001414836ee  0f8406020000             je       0x1414838fa
00000001414836f4  4c8965c8                 mov      qword ptr [rbp - 0x38], r12
00000001414836f8  4c8975c0                 mov      qword ptr [rbp - 0x40], r14
00000001414836fc  4a8d04bd00000000         lea      rax, [r15*4]
0000000141483704  4c8d3480                 lea      r14, [rax + rax*4]
0000000141483708  e853b7bffe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
000000014148370d  ba04000000               mov      edx, 4
0000000141483712  4c89f1                   mov      rcx, r14
0000000141483715  e8968322ff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
000000014148371a  4885c0                   test     rax, rax
000000014148371d  48897d38                 mov      qword ptr [rbp + 0x38], rdi
0000000141483721  0f8479020000             je       0x1414839a0
0000000141483727  4c897d20                 mov      qword ptr [rbp + 0x20], r15
000000014148372b  48894528                 mov      qword ptr [rbp + 0x28], rax
000000014148372f  48c7453000000000         mov      qword ptr [rbp + 0x30], 0
0000000141483737  488b45a8                 mov      rax, qword ptr [rbp - 0x58]
000000014148373b  48894518                 mov      qword ptr [rbp + 0x18], rax
000000014148373f  4901fe                   add      r14, rdi
0000000141483742  4c8d7d20                 lea      r15, [rbp + 0x20]
0000000141483746  0f283593409b01           movaps   xmm6, xmmword ptr [rip + 0x19b4093]
000000014148374d  f30f103d1b419b01         movss    xmm7, dword ptr [rip + 0x19b411b]
0000000141483755  4989fc                   mov      r12, rdi
0000000141483758  eb2b                     jmp      0x141483785
000000014148375a  660f1f440000             nop      word ptr [rax + rax]
0000000141483760  48893cb1                 mov      qword ptr [rcx + rsi*4], rdi
0000000141483764  440f134cb108             movlps   qword ptr [rcx + rsi*4 + 8], xmm9
000000014148376a  f3440f1144b110           movss    dword ptr [rcx + rsi*4 + 0x10], xmm8
0000000141483771  49ffc5                   inc      r13
0000000141483774  4c896d30                 mov      qword ptr [rbp + 0x30], r13
0000000141483778  4983c414                 add      r12, 0x14
000000014148377c  4d39f4                   cmp      r12, r14
000000014148377f  0f84c4000000             je       0x141483849
0000000141483785  498b3c24                 mov      rdi, qword ptr [r12]
0000000141483789  f2450f104c2408           movsd    xmm9, qword ptr [r12 + 8]
0000000141483790  f3450f10442410           movss    xmm8, dword ptr [r12 + 0x10]
0000000141483797  488b4d28                 mov      rcx, qword ptr [rbp + 0x28]
000000014148379b  4c8b6d30                 mov      r13, qword ptr [rbp + 0x30]
000000014148379f  4a8d34ad00000000         lea      rsi, [r13*4]
00000001414837a7  4c01ee                   add      rsi, r13
00000001414837aa  4d85ed                   test     r13, r13
00000001414837ad  7423                     je       0x1414837d2
00000001414837af  488d04b1                 lea      rax, [rcx + rsi*4]
00000001414837b3  4883c0ec                 add      rax, -0x14
00000001414837b7  4885c0                   test     rax, rax
00000001414837ba  7416                     je       0x1414837d2
00000001414837bc  488d04b1                 lea      rax, [rcx + rsi*4]
00000001414837c0  f30f1040f4               movss    xmm0, dword ptr [rax - 0xc]
00000001414837c5  f3410f5cc1               subss    xmm0, xmm9
00000001414837ca  0f54c6                   andps    xmm0, xmm6
00000001414837cd  0f2ef8                   ucomiss  xmm7, xmm0
00000001414837d0  731e                     jae      0x1414837f0
00000001414837d2  4c3b6d20                 cmp      r13, qword ptr [rbp + 0x20]
00000001414837d6  7588                     jne      0x141483760
00000001414837d8  4c89f9                   mov      rcx, r15
00000001414837db  e8e09d9001               call     0x142d8d5c0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h1a1a54980fb1fcc7E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h5261048e76b835d3E
00000001414837e0  90                       nop      
00000001414837e1  488b4d28                 mov      rcx, qword ptr [rbp + 0x28]
00000001414837e5  e976ffffff               jmp      0x141483760
00000001414837ea  660f1f440000             nop      word ptr [rax + rax]
00000001414837f0  f3410f16c1               movshdup xmm0, xmm9
00000001414837f5  f30f1048f8               movss    xmm1, dword ptr [rax - 8]
00000001414837fa  f30f1050fc               movss    xmm2, dword ptr [rax - 4]
00000001414837ff  0f28d9                   movaps   xmm3, xmm1
0000000141483802  f30fc2d903               cmpunordss xmm3, xmm1
0000000141483807  0f28e3                   movaps   xmm4, xmm3
000000014148380a  0f54e0                   andps    xmm4, xmm0
000000014148380d  f30f5dc1                 minss    xmm0, xmm1
0000000141483811  0f55d8                   andnps   xmm3, xmm0
0000000141483814  0f56dc                   orps     xmm3, xmm4
0000000141483817  f30f1158f8               movss    dword ptr [rax - 8], xmm3
000000014148381c  0f28c2                   movaps   xmm0, xmm2
000000014148381f  f30fc2c203               cmpunordss xmm0, xmm2
0000000141483824  0f28c8                   movaps   xmm1, xmm0
0000000141483827  410f54c8                 andps    xmm1, xmm8
000000014148382b  f3440f5fc2               maxss    xmm8, xmm2
0000000141483830  410f55c0                 andnps   xmm0, xmm8
0000000141483834  0f56c1                   orps     xmm0, xmm1
0000000141483837  f30f1140fc               movss    dword ptr [rax - 4], xmm0
000000014148383c  4983c414                 add      r12, 0x14
0000000141483840  4d39f4                   cmp      r12, r14
0000000141483843  0f853cffffff             jne      0x141483785
0000000141483849  488b7d38                 mov      rdi, qword ptr [rbp + 0x38]
000000014148384d  4c8b75c0                 mov      r14, qword ptr [rbp - 0x40]
0000000141483851  4c8b65c8                 mov      r12, qword ptr [rbp - 0x38]
0000000141483855  488b4518                 mov      rax, qword ptr [rbp + 0x18]
0000000141483859  4885c0                   test     rax, rax
000000014148385c  7416                     je       0x141483874
000000014148385e  48c1e002                 shl      rax, 2
0000000141483862  488d1480                 lea      rdx, [rax + rax*4]
0000000141483866  41b804000000             mov      r8d, 4
000000014148386c  4889f9                   mov      rcx, rdi
000000014148386f  e84c8222ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141483874  488b4530                 mov      rax, qword ptr [rbp + 0x30]
0000000141483878  488945e0                 mov      qword ptr [rbp - 0x20], rax
000000014148387c  0f104520                 movups   xmm0, xmmword ptr [rbp + 0x20]
0000000141483880  0f2945d0                 movaps   xmmword ptr [rbp - 0x30], xmm0
0000000141483884  83bb5802000002           cmp      dword ptr [rbx + 0x258], 2
000000014148388b  7507                     jne      0x141483894
000000014148388d  31c0                     xor      eax, eax
000000014148388f  e992000000               jmp      0x141483926
0000000141483894  488b75e0                 mov      rsi, qword ptr [rbp - 0x20]
0000000141483898  4885f6                   test     rsi, rsi
000000014148389b  0f8483000000             je       0x141483924
00000001414838a1  488b45d8                 mov      rax, qword ptr [rbp - 0x28]
00000001414838a5  f20f1030                 movsd    xmm6, qword ptr [rax]
00000001414838a9  f3440f104008             movss    xmm8, dword ptr [rax + 8]
00000001414838af  f20f10780c               movsd    xmm7, qword ptr [rax + 0xc]
00000001414838b4  f3450f5844243c           addss    xmm8, dword ptr [r12 + 0x3c]
00000001414838bb  483b75d0                 cmp      rsi, qword ptr [rbp - 0x30]
00000001414838bf  7512                     jne      0x1414838d3
00000001414838c1  48897d38                 mov      qword ptr [rbp + 0x38], rdi
00000001414838c5  488d4dd0                 lea      rcx, [rbp - 0x30]
00000001414838c9  e8f29c9001               call     0x142d8d5c0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h1a1a54980fb1fcc7E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h5261048e76b835d3E
00000001414838ce  90                       nop      
00000001414838cf  488b45d8                 mov      rax, qword ptr [rbp - 0x28]
00000001414838d3  488d0cb6                 lea      rcx, [rsi + rsi*4]
00000001414838d7  0f133488                 movlps   qword ptr [rax + rcx*4], xmm6
00000001414838db  f3440f11448808           movss    dword ptr [rax + rcx*4 + 8], xmm8
00000001414838e2  0f137c880c               movlps   qword ptr [rax + rcx*4 + 0xc], xmm7
00000001414838e7  48ffc6                   inc      rsi
00000001414838ea  488975e0                 mov      qword ptr [rbp - 0x20], rsi
00000001414838ee  83bb5802000002           cmp      dword ptr [rbx + 0x258], 2
00000001414838f5  0f95c0                   setne    al
00000001414838f8  eb2c                     jmp      0x141483926
00000001414838fa  48c7452000000000         mov      qword ptr [rbp + 0x20], 0
0000000141483902  48c7452804000000         mov      qword ptr [rbp + 0x28], 4
000000014148390a  48c7453000000000         mov      qword ptr [rbp + 0x30], 0
0000000141483912  488b45a8                 mov      rax, qword ptr [rbp - 0x58]
0000000141483916  4885c0                   test     rax, rax
0000000141483919  0f853fffffff             jne      0x14148385e
000000014148391f  e950ffffff               jmp      0x141483874
0000000141483924  b001                     mov      al, 1
0000000141483926  488b4de0                 mov      rcx, qword ptr [rbp - 0x20]
000000014148392a  49894e10                 mov      qword ptr [r14 + 0x10], rcx
000000014148392e  0f2845d0                 movaps   xmm0, xmmword ptr [rbp - 0x30]
0000000141483932  410f1106                 movups   xmmword ptr [r14], xmm0
0000000141483936  f3410f1044243c           movss    xmm0, dword ptr [r12 + 0x3c]
000000014148393d  f3410f114618             movss    dword ptr [r14 + 0x18], xmm0
0000000141483943  4188461c                 mov      byte ptr [r14 + 0x1c], al
0000000141483947  4c89f0                   mov      rax, r14
000000014148394a  0f287550                 movaps   xmm6, xmmword ptr [rbp + 0x50]
000000014148394e  0f287d60                 movaps   xmm7, xmmword ptr [rbp + 0x60]
0000000141483952  440f284570               movaps   xmm8, xmmword ptr [rbp + 0x70]
0000000141483957  440f288d80000000         movaps   xmm9, xmmword ptr [rbp + 0x80]
000000014148395f  4881c418010000           add      rsp, 0x118
0000000141483966  5b                       pop      rbx
0000000141483967  5f                       pop      rdi
0000000141483968  5e                       pop      rsi
0000000141483969  415c                     pop      r12
000000014148396b  415d                     pop      r13
000000014148396d  415e                     pop      r14
000000014148396f  415f                     pop      r15
0000000141483971  5d                       pop      rbp
0000000141483972  c3                       ret      
0000000141483973  4983ff15                 cmp      r15, 0x15
0000000141483977  48897d38                 mov      qword ptr [rbp + 0x38], rdi
000000014148397b  7337                     jae      0x1414839b4
000000014148397d  c6454701                 mov      byte ptr [rbp + 0x47], 1
0000000141483981  4c8d4dd0                 lea      r9, [rbp - 0x30]
0000000141483985  41b801000000             mov      r8d, 1
000000014148398b  4889f9                   mov      rcx, rdi
000000014148398e  4c89fa                   mov      rdx, r15
0000000141483991  e8eac7fdff               call     0x141460180 ; _ZN4core5slice4sort6shared9smallsort25insertion_sort_shift_left17h42d301a014fd5f24E | core::slice::sort::shared::smallsort::insertion_sort_shift_left<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSample,alloc::slice::impl$0::sort_by::closure_env$0<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSample,system_wall_constructor::construct_wooden_walls::construct_wall_boards::impl$2::new::closure_env$1> >
0000000141483996  90                       nop      
0000000141483997  488b7d38                 mov      rdi, qword ptr [rbp + 0x38]
000000014148399b  e954fdffff               jmp      0x1414836f4
00000001414839a0  c6454701                 mov      byte ptr [rbp + 0x47], 1
00000001414839a4  b904000000               mov      ecx, 4
00000001414839a9  4c89f2                   mov      rdx, r14
00000001414839ac  e879449401               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
00000001414839b1  90                       nop      
00000001414839b2  0f0b                     ud2      
00000001414839b4  c6454701                 mov      byte ptr [rbp + 0x47], 1
00000001414839b8  4c8d45d0                 lea      r8, [rbp - 0x30]
00000001414839bc  4889f9                   mov      rcx, rdi
00000001414839bf  4c89fa                   mov      rdx, r15
00000001414839c2  e8b920feff               call     0x141465a80 ; _ZN4core5slice4sort6stable14driftsort_main17h5a11cc6a623b4a0dE | core::slice::sort::stable::driftsort_main<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSample,alloc::slice::impl$0::sort_by::closure_env$0<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSample,system_wall_constructor::construct_wooden_walls::construct_wall_boards::impl$2::new::closure_env$1>,alloc::vec::Vec<system_wall_constructor::construct_wooden_walls::construct_wall_boards::WallSample,alloc::alloc::Global> >
00000001414839c7  90                       nop      
00000001414839c8  ebcd                     jmp      0x141483997
00000001414839ca  660f1f440000             nop      word ptr [rax + rax]
00000001414839d0  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001414839d5  55                       push     rbp
00000001414839d6  4157                     push     r15
00000001414839d8  4156                     push     r14
00000001414839da  4155                     push     r13
00000001414839dc  4154                     push     r12
00000001414839de  56                       push     rsi
00000001414839df  57                       push     rdi
00000001414839e0  53                       push     rbx
00000001414839e1  4883ec68                 sub      rsp, 0x68
00000001414839e5  488daa80000000           lea      rbp, [rdx + 0x80]
00000001414839ec  440f294c2420             movaps   xmmword ptr [rsp + 0x20], xmm9
00000001414839f2  440f29442430             movaps   xmmword ptr [rsp + 0x30], xmm8
00000001414839f8  0f297c2440               movaps   xmmword ptr [rsp + 0x40], xmm7
00000001414839fd  0f29742450               movaps   xmmword ptr [rsp + 0x50], xmm6
0000000141483a02  48837d1800               cmp      qword ptr [rbp + 0x18], 0
0000000141483a07  741b                     je       0x141483a24
0000000141483a09  488b4518                 mov      rax, qword ptr [rbp + 0x18]
0000000141483a0d  48c1e002                 shl      rax, 2
0000000141483a11  488d1480                 lea      rdx, [rax + rax*4]
0000000141483a15  41b804000000             mov      r8d, 4
0000000141483a1b  488b4d38                 mov      rcx, qword ptr [rbp + 0x38]
0000000141483a1f  e89c8022ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141483a24  c6454601                 mov      byte ptr [rbp + 0x46], 1
0000000141483a28  0f28742450               movaps   xmm6, xmmword ptr [rsp + 0x50]
0000000141483a2d  0f287c2440               movaps   xmm7, xmmword ptr [rsp + 0x40]
0000000141483a32  440f28442430             movaps   xmm8, xmmword ptr [rsp + 0x30]
0000000141483a38  440f284c2420             movaps   xmm9, xmmword ptr [rsp + 0x20]
0000000141483a3e  4883c468                 add      rsp, 0x68
0000000141483a42  5b                       pop      rbx
0000000141483a43  5f                       pop      rdi
0000000141483a44  5e                       pop      rsi
0000000141483a45  415c                     pop      r12
0000000141483a47  415d                     pop      r13
0000000141483a49  415e                     pop      r14
0000000141483a4b  415f                     pop      r15
0000000141483a4d  5d                       pop      rbp
0000000141483a4e  c3                       ret      
0000000141483a4f  90                       nop      
0000000141483a50  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141483a55  55                       push     rbp
0000000141483a56  4157                     push     r15
0000000141483a58  4156                     push     r14
0000000141483a5a  4155                     push     r13
0000000141483a5c  4154                     push     r12
0000000141483a5e  56                       push     rsi
0000000141483a5f  57                       push     rdi
0000000141483a60  53                       push     rbx
0000000141483a61  4883ec68                 sub      rsp, 0x68
0000000141483a65  488daa80000000           lea      rbp, [rdx + 0x80]
0000000141483a6c  440f294c2420             movaps   xmmword ptr [rsp + 0x20], xmm9
0000000141483a72  440f29442430             movaps   xmmword ptr [rsp + 0x30], xmm8
0000000141483a78  0f297c2440               movaps   xmmword ptr [rsp + 0x40], xmm7
0000000141483a7d  0f29742450               movaps   xmmword ptr [rsp + 0x50], xmm6
0000000141483a82  488b45d0                 mov      rax, qword ptr [rbp - 0x30]
0000000141483a86  4885c0                   test     rax, rax
0000000141483a89  7417                     je       0x141483aa2
0000000141483a8b  488b4dd8                 mov      rcx, qword ptr [rbp - 0x28]
0000000141483a8f  48c1e002                 shl      rax, 2
0000000141483a93  488d1480                 lea      rdx, [rax + rax*4]
0000000141483a97  41b804000000             mov      r8d, 4
0000000141483a9d  e81e8022ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141483aa2  c6454600                 mov      byte ptr [rbp + 0x46], 0
0000000141483aa6  0f28742450               movaps   xmm6, xmmword ptr [rsp + 0x50]
0000000141483aab  0f287c2440               movaps   xmm7, xmmword ptr [rsp + 0x40]
0000000141483ab0  440f28442430             movaps   xmm8, xmmword ptr [rsp + 0x30]
0000000141483ab6  440f284c2420             movaps   xmm9, xmmword ptr [rsp + 0x20]
0000000141483abc  4883c468                 add      rsp, 0x68
0000000141483ac0  5b                       pop      rbx
0000000141483ac1  5f                       pop      rdi
0000000141483ac2  5e                       pop      rsi
0000000141483ac3  415c                     pop      r12
0000000141483ac5  415d                     pop      r13
0000000141483ac7  415e                     pop      r14
0000000141483ac9  415f                     pop      r15
0000000141483acb  5d                       pop      rbp
0000000141483acc  c3                       ret      
0000000141483acd  0f1f00                   nop      dword ptr [rax]
0000000141483ad0  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141483ad5  55                       push     rbp
0000000141483ad6  4157                     push     r15
0000000141483ad8  4156                     push     r14
0000000141483ada  4155                     push     r13
0000000141483adc  4154                     push     r12
0000000141483ade  56                       push     rsi
0000000141483adf  57                       push     rdi
0000000141483ae0  53                       push     rbx
0000000141483ae1  4883ec68                 sub      rsp, 0x68
0000000141483ae5  488daa80000000           lea      rbp, [rdx + 0x80]
0000000141483aec  440f294c2420             movaps   xmmword ptr [rsp + 0x20], xmm9
0000000141483af2  440f29442430             movaps   xmmword ptr [rsp + 0x30], xmm8
0000000141483af8  0f297c2440               movaps   xmmword ptr [rsp + 0x40], xmm7
0000000141483afd  0f29742450               movaps   xmmword ptr [rsp + 0x50], xmm6
0000000141483b02  807d4600                 cmp      byte ptr [rbp + 0x46], 0
0000000141483b06  744b                     je       0x141483b53
0000000141483b08  488b4520                 mov      rax, qword ptr [rbp + 0x20]
0000000141483b0c  4885c0                   test     rax, rax
0000000141483b0f  7417                     je       0x141483b28
0000000141483b11  488b4d28                 mov      rcx, qword ptr [rbp + 0x28]
0000000141483b15  48c1e002                 shl      rax, 2
0000000141483b19  488d1480                 lea      rdx, [rax + rax*4]
0000000141483b1d  41b804000000             mov      r8d, 4
0000000141483b23  e8987f22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141483b28  c6454700                 mov      byte ptr [rbp + 0x47], 0
0000000141483b2c  0f28742450               movaps   xmm6, xmmword ptr [rsp + 0x50]
0000000141483b31  0f287c2440               movaps   xmm7, xmmword ptr [rsp + 0x40]
0000000141483b36  440f28442430             movaps   xmm8, xmmword ptr [rsp + 0x30]
0000000141483b3c  440f284c2420             movaps   xmm9, xmmword ptr [rsp + 0x20]
0000000141483b42  4883c468                 add      rsp, 0x68
0000000141483b46  5b                       pop      rbx
0000000141483b47  5f                       pop      rdi
0000000141483b48  5e                       pop      rsi
0000000141483b49  415c                     pop      r12
0000000141483b4b  415d                     pop      r13
0000000141483b4d  415e                     pop      r14
0000000141483b4f  415f                     pop      r15
0000000141483b51  5d                       pop      rbp
0000000141483b52  c3                       ret      
0000000141483b53  c6454700                 mov      byte ptr [rbp + 0x47], 0
0000000141483b57  0f28742450               movaps   xmm6, xmmword ptr [rsp + 0x50]
0000000141483b5c  0f287c2440               movaps   xmm7, xmmword ptr [rsp + 0x40]
0000000141483b61  440f28442430             movaps   xmm8, xmmword ptr [rsp + 0x30]
0000000141483b67  440f284c2420             movaps   xmm9, xmmword ptr [rsp + 0x20]
0000000141483b6d  4883c468                 add      rsp, 0x68
0000000141483b71  5b                       pop      rbx
0000000141483b72  5f                       pop      rdi
0000000141483b73  5e                       pop      rsi
0000000141483b74  415c                     pop      r12
0000000141483b76  415d                     pop      r13
0000000141483b78  415e                     pop      r14
0000000141483b7a  415f                     pop      r15
0000000141483b7c  5d                       pop      rbp
0000000141483b7d  c3                       ret      
0000000141483b7e  6690                     nop      
0000000141483b80  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141483b85  55                       push     rbp
0000000141483b86  4157                     push     r15
0000000141483b88  4156                     push     r14
0000000141483b8a  4155                     push     r13
0000000141483b8c  4154                     push     r12
0000000141483b8e  56                       push     rsi
0000000141483b8f  57                       push     rdi
0000000141483b90  53                       push     rbx
0000000141483b91  4883ec68                 sub      rsp, 0x68
0000000141483b95  488daa80000000           lea      rbp, [rdx + 0x80]
0000000141483b9c  440f294c2420             movaps   xmmword ptr [rsp + 0x20], xmm9
0000000141483ba2  440f29442430             movaps   xmmword ptr [rsp + 0x30], xmm8
0000000141483ba8  0f297c2440               movaps   xmmword ptr [rsp + 0x40], xmm7
0000000141483bad  0f29742450               movaps   xmmword ptr [rsp + 0x50], xmm6
0000000141483bb2  807d4700                 cmp      byte ptr [rbp + 0x47], 0
0000000141483bb6  7420                     je       0x141483bd8
0000000141483bb8  488b45a8                 mov      rax, qword ptr [rbp - 0x58]
0000000141483bbc  4885c0                   test     rax, rax
0000000141483bbf  7417                     je       0x141483bd8
0000000141483bc1  48c1e002                 shl      rax, 2
0000000141483bc5  488d1480                 lea      rdx, [rax + rax*4]
0000000141483bc9  41b804000000             mov      r8d, 4
0000000141483bcf  488b4d38                 mov      rcx, qword ptr [rbp + 0x38]
0000000141483bd3  e8e87e22ff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141483bd8  0f28742450               movaps   xmm6, xmmword ptr [rsp + 0x50]
0000000141483bdd  0f287c2440               movaps   xmm7, xmmword ptr [rsp + 0x40]
0000000141483be2  440f28442430             movaps   xmm8, xmmword ptr [rsp + 0x30]
0000000141483be8  440f284c2420             movaps   xmm9, xmmword ptr [rsp + 0x20]
0000000141483bee  4883c468                 add      rsp, 0x68
0000000141483bf2  5b                       pop      rbx
0000000141483bf3  5f                       pop      rdi
0000000141483bf4  5e                       pop      rsi
0000000141483bf5  415c                     pop      r12
0000000141483bf7  415d                     pop      r13
0000000141483bf9  415e                     pop      r14
0000000141483bfb  415f                     pop      r15
0000000141483bfd  5d                       pop      rbp
0000000141483bfe  c3                       ret      