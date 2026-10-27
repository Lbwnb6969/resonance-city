0000000141d06040  55                       push     rbp
0000000141d06041  4157                     push     r15
0000000141d06043  4156                     push     r14
0000000141d06045  4155                     push     r13
0000000141d06047  4154                     push     r12
0000000141d06049  56                       push     rsi
0000000141d0604a  57                       push     rdi
0000000141d0604b  53                       push     rbx
0000000141d0604c  4881ec38020000           sub      rsp, 0x238
0000000141d06053  488dac2480000000         lea      rbp, [rsp + 0x80]
0000000141d0605b  440f2995a0010000         movaps   xmmword ptr [rbp + 0x1a0], xmm10
0000000141d06063  440f298d90010000         movaps   xmmword ptr [rbp + 0x190], xmm9
0000000141d0606b  440f298580010000         movaps   xmmword ptr [rbp + 0x180], xmm8
0000000141d06073  0f29bd70010000           movaps   xmmword ptr [rbp + 0x170], xmm7
0000000141d0607a  0f29b560010000           movaps   xmmword ptr [rbp + 0x160], xmm6
0000000141d06081  48c78558010000feffffff   mov      qword ptr [rbp + 0x158], 0xfffffffffffffffe
0000000141d0608c  4c8985e8000000           mov      qword ptr [rbp + 0xe8], r8
0000000141d06093  488b7a28                 mov      rdi, qword ptr [rdx + 0x28]
0000000141d06097  4885ff                   test     rdi, rdi
0000000141d0609a  0f8461080000             je       0x141d06901
0000000141d060a0  4589cf                   mov      r15d, r9d
0000000141d060a3  4989d6                   mov      r14, rdx
0000000141d060a6  48894d58                 mov      qword ptr [rbp + 0x58], rcx
0000000141d060aa  48c785d000000000000000   mov      qword ptr [rbp + 0xd0], 0
0000000141d060b5  48c785d800000004000000   mov      qword ptr [rbp + 0xd8], 4
0000000141d060c0  48c785e000000000000000   mov      qword ptr [rbp + 0xe0], 0
0000000141d060cb  488d8dd0000000           lea      rcx, [rbp + 0xd0]
0000000141d060d2  e8f9a60a01               call     0x142db07d0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h00df97f05d0f1c52E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h142b2e73de25e47dE
0000000141d060d7  90                       nop      
0000000141d060d8  f30f10bd20020000         movss    xmm7, dword ptr [rbp + 0x220]
0000000141d060e0  f30f1005500e1301         movss    xmm0, dword ptr [rip + 0x1130e50]
0000000141d060e8  f30f59c7                 mulss    xmm0, xmm7
0000000141d060ec  488b85d8000000           mov      rax, qword ptr [rbp + 0xd8]
0000000141d060f3  448938                   mov      dword ptr [rax], r15d
0000000141d060f6  f30f114004               movss    dword ptr [rax + 4], xmm0
0000000141d060fb  48c785e000000001000000   mov      qword ptr [rbp + 0xe0], 1
0000000141d06106  498b4620                 mov      rax, qword ptr [r14 + 0x20]
0000000141d0610a  488945b8                 mov      qword ptr [rbp - 0x48], rax
0000000141d0610e  498b4668                 mov      rax, qword ptr [r14 + 0x68]
0000000141d06112  48894550                 mov      qword ptr [rbp + 0x50], rax
0000000141d06116  498b4670                 mov      rax, qword ptr [r14 + 0x70]
0000000141d0611a  48894520                 mov      qword ptr [rbp + 0x20], rax
0000000141d0611e  488b85e8000000           mov      rax, qword ptr [rbp + 0xe8]
0000000141d06125  488d4870                 lea      rcx, [rax + 0x70]
0000000141d06129  48898db0000000           mov      qword ptr [rbp + 0xb0], rcx
0000000141d06130  488d4074                 lea      rax, [rax + 0x74]
0000000141d06134  488985b8000000           mov      qword ptr [rbp + 0xb8], rax
0000000141d0613b  440f2805dd161301         movaps   xmm8, xmmword ptr [rip + 0x11316dd]
0000000141d06143  450f57c9                 xorps    xmm9, xmm9
0000000141d06147  c785f400000000000000     mov      dword ptr [rbp + 0xf4], 0
0000000141d06151  6666666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
0000000141d06160  488d4dd4                 lea      rcx, [rbp - 0x2c]
0000000141d06164  488d95d0000000           lea      rdx, [rbp + 0xd0]
0000000141d0616b  e870320000               call     0x141d093e0 ; _ZN5alloc11collections11binary_heap23BinaryHeap$LT$T$C$A$GT$3pop17h3046b785d9789719E | _ZN5alloc11collections11binary_heap23BinaryHeap$LT$T$C$A$GT$3pop17hb5037e6e6fc3b7fdE
0000000141d06170  90                       nop      
0000000141d06171  837dd401                 cmp      dword ptr [rbp - 0x2c], 1
0000000141d06175  0f8528070000             jne      0x141d068a3
0000000141d0617b  f30f1045dc               movss    xmm0, dword ptr [rbp - 0x24]
0000000141d06180  410f57c0                 xorps    xmm0, xmm8
0000000141d06184  0f2ec7                   ucomiss  xmm0, xmm7
0000000141d06187  0f8316070000             jae      0x141d068a3
0000000141d0618d  8b4dd8                   mov      ecx, dword ptr [rbp - 0x28]
0000000141d06190  4839cf                   cmp      rdi, rcx
0000000141d06193  0f86a4080000             jbe      0x141d06a3d
0000000141d06199  48c1e107                 shl      rcx, 7
0000000141d0619d  488b45b8                 mov      rax, qword ptr [rbp - 0x48]
0000000141d061a1  4c8d2408                 lea      r12, [rax + rcx]
0000000141d061a5  440fb6740878             movzx    r14d, byte ptr [rax + rcx + 0x78]
0000000141d061ab  41f6c601                 test     r14b, 1
0000000141d061af  747e                     je       0x141d0622f
0000000141d061b1  418b442460               mov      eax, dword ptr [r12 + 0x60]
0000000141d061b6  4889c1                   mov      rcx, rax
0000000141d061b9  48c1e104                 shl      rcx, 4
0000000141d061bd  4c8b4520                 mov      r8, qword ptr [rbp + 0x20]
0000000141d061c1  4939c0                   cmp      r8, rax
0000000141d061c4  488b5550                 mov      rdx, qword ptr [rbp + 0x50]
0000000141d061c8  488d440a08               lea      rax, [rdx + rcx + 8]
0000000141d061cd  41b900000000             mov      r9d, 0
0000000141d061d3  490f46c1                 cmovbe   rax, r9
0000000141d061d7  48894530                 mov      qword ptr [rbp + 0x30], rax
0000000141d061db  418b442464               mov      eax, dword ptr [r12 + 0x64]
0000000141d061e0  4889c1                   mov      rcx, rax
0000000141d061e3  48c1e104                 shl      rcx, 4
0000000141d061e7  4939c0                   cmp      r8, rax
0000000141d061ea  488d440a08               lea      rax, [rdx + rcx + 8]
0000000141d061ef  490f46c1                 cmovbe   rax, r9
0000000141d061f3  48894538                 mov      qword ptr [rbp + 0x38], rax
0000000141d061f7  418b442468               mov      eax, dword ptr [r12 + 0x68]
0000000141d061fc  4889c1                   mov      rcx, rax
0000000141d061ff  48c1e104                 shl      rcx, 4
0000000141d06203  4939c0                   cmp      r8, rax
0000000141d06206  488d440a08               lea      rax, [rdx + rcx + 8]
0000000141d0620b  490f46c1                 cmovbe   rax, r9
0000000141d0620f  48894540                 mov      qword ptr [rbp + 0x40], rax
0000000141d06213  418b44246c               mov      eax, dword ptr [r12 + 0x6c]
0000000141d06218  4889c1                   mov      rcx, rax
0000000141d0621b  48c1e104                 shl      rcx, 4
0000000141d0621f  4939c0                   cmp      r8, rax
0000000141d06222  488d440a08               lea      rax, [rdx + rcx + 8]
0000000141d06227  490f46c1                 cmovbe   rax, r9
0000000141d0622b  48894548                 mov      qword ptr [rbp + 0x48], rax
0000000141d0622f  4c8b85e8000000           mov      r8, qword ptr [rbp + 0xe8]
0000000141d06236  f3410f104070             movss    xmm0, dword ptr [r8 + 0x70]
0000000141d0623c  f30f114560               movss    dword ptr [rbp + 0x60], xmm0
0000000141d06241  f30f114564               movss    dword ptr [rbp + 0x64], xmm0
0000000141d06246  f30f114568               movss    dword ptr [rbp + 0x68], xmm0
0000000141d0624b  f30f11456c               movss    dword ptr [rbp + 0x6c], xmm0
0000000141d06250  488d8d00010000           lea      rcx, [rbp + 0x100]
0000000141d06257  4c89e2                   mov      rdx, r12
0000000141d0625a  4c8d4d60                 lea      r9, [rbp + 0x60]
0000000141d0625e  e88df6fdfe               call     0x140ce58f0 ; parry3d::bounding_volume::simd_aabb::SimdAabb::cast_local_ray | _ZN7parry3d15bounding_volume9simd_aabb8SimdAabb14cast_local_ray17h4944e819a6b4a197E
0000000141d06263  90                       nop      
0000000141d06264  0f288500010000           movaps   xmm0, xmmword ptr [rbp + 0x100]
0000000141d0626b  0f2945a0                 movaps   xmmword ptr [rbp - 0x60], xmm0
0000000141d0626f  f30f109d10010000         movss    xmm3, dword ptr [rbp + 0x110]
0000000141d06277  f30f109514010000         movss    xmm2, dword ptr [rbp + 0x114]
0000000141d0627f  f30f108d18010000         movss    xmm1, dword ptr [rbp + 0x118]
0000000141d06287  f30f10851c010000         movss    xmm0, dword ptr [rbp + 0x11c]
0000000141d0628f  41f6c601                 test     r14b, 1
0000000141d06293  751b                     jne      0x141d062b0
0000000141d06295  448b7da0                 mov      r15d, dword ptr [rbp - 0x60]
0000000141d06299  31c9                     xor      ecx, ecx
0000000141d0629b  31c0                     xor      eax, eax
0000000141d0629d  31d2                     xor      edx, edx
0000000141d0629f  4531c0                   xor      r8d, r8d
0000000141d062a2  e906040000               jmp      0x141d066ad
0000000141d062a7  660f1f840000000000       nop      word ptr [rax + rax]
0000000141d062b0  0f2efb                   ucomiss  xmm7, xmm3
0000000141d062b3  0f9745c0                 seta     byte ptr [rbp - 0x40]
0000000141d062b7  440f298da0000000         movaps   xmmword ptr [rbp + 0xa0], xmm9
0000000141d062bf  c7855001000000000000     mov      dword ptr [rbp + 0x150], 0
0000000141d062c9  0f2efa                   ucomiss  xmm7, xmm2
0000000141d062cc  0f9745c1                 seta     byte ptr [rbp - 0x3f]
0000000141d062d0  c7456000000000           mov      dword ptr [rbp + 0x60], 0
0000000141d062d7  c7457000000000           mov      dword ptr [rbp + 0x70], 0
0000000141d062de  0f2ef9                   ucomiss  xmm7, xmm1
0000000141d062e1  0f9745c2                 seta     byte ptr [rbp - 0x3e]
0000000141d062e5  c7858000000000000000     mov      dword ptr [rbp + 0x80], 0
0000000141d062ef  c7859000000000000000     mov      dword ptr [rbp + 0x90], 0
0000000141d062f9  0f2ef8                   ucomiss  xmm7, xmm0
0000000141d062fc  0f9745c3                 seta     byte ptr [rbp - 0x3d]
0000000141d06300  488d8d00010000           lea      rcx, [rbp + 0x100]
0000000141d06307  488d55a0                 lea      rdx, [rbp - 0x60]
0000000141d0630b  4c8d45c0                 lea      r8, [rbp - 0x40]
0000000141d0630f  e87cbf0200               call     0x141d32290 ; simba::simd::auto_simd_impl::impl$1326::bitand | _ZN113_$LT$simba..simd..auto_simd_impl..AutoSimd$LT$$u5b$bool$u3b$$u20$4$u5d$$GT$$u20$as$u20$core..ops..bit..BitAnd$GT$6bitand17hff8c23c966c505abE
0000000141d06314  90                       nop      
0000000141d06315  0fb68501010000           movzx    eax, byte ptr [rbp + 0x101]
0000000141d0631c  0fb68d02010000           movzx    ecx, byte ptr [rbp + 0x102]
0000000141d06323  00c0                     add      al, al
0000000141d06325  0a8500010000             or       al, byte ptr [rbp + 0x100]
0000000141d0632b  c0e102                   shl      cl, 2
0000000141d0632e  08c1                     or       cl, al
0000000141d06330  0fb6b503010000           movzx    esi, byte ptr [rbp + 0x103]
0000000141d06337  8d04f500000000           lea      eax, [rsi*8]
0000000141d0633e  08c8                     or       al, cl
0000000141d06340  440fb6f8                 movzx    r15d, al
0000000141d06344  48c785f800000000000000   mov      qword ptr [rbp + 0xf8], 0
0000000141d0634f  41f6c701                 test     r15b, 1
0000000141d06353  0f84a4000000             je       0x141d063fd
0000000141d06359  48837d3000               cmp      qword ptr [rbp + 0x30], 0
0000000141d0635e  0f8499000000             je       0x141d063fd
0000000141d06364  488b4530                 mov      rax, qword ptr [rbp + 0x30]
0000000141d06368  8b10                     mov      edx, dword ptr [rax]
0000000141d0636a  448b4004                 mov      r8d, dword ptr [rax + 4]
0000000141d0636e  899548010000             mov      dword ptr [rbp + 0x148], edx
0000000141d06374  4489854c010000           mov      dword ptr [rbp + 0x14c], r8d
0000000141d0637b  488b85e8000000           mov      rax, qword ptr [rbp + 0xe8]
0000000141d06382  488b4860                 mov      rcx, qword ptr [rax + 0x60]
0000000141d06386  488b4068                 mov      rax, qword ptr [rax + 0x68]
0000000141d0638a  48898500010000           mov      qword ptr [rbp + 0x100], rax
0000000141d06391  488b85b0000000           mov      rax, qword ptr [rbp + 0xb0]
0000000141d06398  48898508010000           mov      qword ptr [rbp + 0x108], rax
0000000141d0639f  488b85b8000000           mov      rax, qword ptr [rbp + 0xb8]
0000000141d063a6  48898510010000           mov      qword ptr [rbp + 0x110], rax
0000000141d063ad  488d4560                 lea      rax, [rbp + 0x60]
0000000141d063b1  48898518010000           mov      qword ptr [rbp + 0x118], rax
0000000141d063b8  488d85f8000000           lea      rax, [rbp + 0xf8]
0000000141d063bf  48898520010000           mov      qword ptr [rbp + 0x120], rax
0000000141d063c6  488d8548010000           lea      rax, [rbp + 0x148]
0000000141d063cd  48898528010000           mov      qword ptr [rbp + 0x128], rax
0000000141d063d4  488d8550010000           lea      rax, [rbp + 0x150]
0000000141d063db  48898530010000           mov      qword ptr [rbp + 0x130], rax
0000000141d063e2  488d85a0000000           lea      rax, [rbp + 0xa0]
0000000141d063e9  48898538010000           mov      qword ptr [rbp + 0x138], rax
0000000141d063f0  4c8d8d00010000           lea      r9, [rbp + 0x100]
0000000141d063f7  e85414d0ff               call     0x141a07850 ; _ZN142_$LT$rapier3d..pipeline..query_pipeline..QueryPipelineAsCompositeShape$u20$as$u20$parry3d..shape..composite_shape..TypedSimdCompositeShape$GT$17map_typed_part_at17h991f4722cd874614E | rapier3d::pipeline::query_pipeline::impl$5::map_typed_part_at<parry3d::query::ray::ray_composite_shape::impl$4::visit::closure_env$0<rapier3d::pipeline::query_pipeline::QueryPipelineAsCompositeShape> >
0000000141d063fc  90                       nop      
0000000141d063fd  48c785f800000001000000   mov      qword ptr [rbp + 0xf8], 1
0000000141d06408  41f6c702                 test     r15b, 2
0000000141d0640c  0f84a4000000             je       0x141d064b6
0000000141d06412  48837d3800               cmp      qword ptr [rbp + 0x38], 0
0000000141d06417  0f8499000000             je       0x141d064b6
0000000141d0641d  488b4538                 mov      rax, qword ptr [rbp + 0x38]
0000000141d06421  8b10                     mov      edx, dword ptr [rax]
0000000141d06423  448b4004                 mov      r8d, dword ptr [rax + 4]
0000000141d06427  899548010000             mov      dword ptr [rbp + 0x148], edx
0000000141d0642d  4489854c010000           mov      dword ptr [rbp + 0x14c], r8d
0000000141d06434  488b85e8000000           mov      rax, qword ptr [rbp + 0xe8]
0000000141d0643b  488b4860                 mov      rcx, qword ptr [rax + 0x60]
0000000141d0643f  488b4068                 mov      rax, qword ptr [rax + 0x68]
0000000141d06443  48898500010000           mov      qword ptr [rbp + 0x100], rax
0000000141d0644a  488b85b0000000           mov      rax, qword ptr [rbp + 0xb0]
0000000141d06451  48898508010000           mov      qword ptr [rbp + 0x108], rax
0000000141d06458  488b85b8000000           mov      rax, qword ptr [rbp + 0xb8]
0000000141d0645f  48898510010000           mov      qword ptr [rbp + 0x110], rax
0000000141d06466  488d4560                 lea      rax, [rbp + 0x60]
0000000141d0646a  48898518010000           mov      qword ptr [rbp + 0x118], rax
0000000141d06471  488d85f8000000           lea      rax, [rbp + 0xf8]
0000000141d06478  48898520010000           mov      qword ptr [rbp + 0x120], rax
0000000141d0647f  488d8548010000           lea      rax, [rbp + 0x148]
0000000141d06486  48898528010000           mov      qword ptr [rbp + 0x128], rax
0000000141d0648d  488d8550010000           lea      rax, [rbp + 0x150]
0000000141d06494  48898530010000           mov      qword ptr [rbp + 0x130], rax
0000000141d0649b  488d85a0000000           lea      rax, [rbp + 0xa0]
0000000141d064a2  48898538010000           mov      qword ptr [rbp + 0x138], rax
0000000141d064a9  4c8d8d00010000           lea      r9, [rbp + 0x100]
0000000141d064b0  e89b13d0ff               call     0x141a07850 ; _ZN142_$LT$rapier3d..pipeline..query_pipeline..QueryPipelineAsCompositeShape$u20$as$u20$parry3d..shape..composite_shape..TypedSimdCompositeShape$GT$17map_typed_part_at17h991f4722cd874614E | rapier3d::pipeline::query_pipeline::impl$5::map_typed_part_at<parry3d::query::ray::ray_composite_shape::impl$4::visit::closure_env$0<rapier3d::pipeline::query_pipeline::QueryPipelineAsCompositeShape> >
0000000141d064b5  90                       nop      
0000000141d064b6  48c785f800000002000000   mov      qword ptr [rbp + 0xf8], 2
0000000141d064c1  41f6c704                 test     r15b, 4
0000000141d064c5  0f84a4000000             je       0x141d0656f
0000000141d064cb  48837d4000               cmp      qword ptr [rbp + 0x40], 0
0000000141d064d0  0f8499000000             je       0x141d0656f
0000000141d064d6  488b4540                 mov      rax, qword ptr [rbp + 0x40]
0000000141d064da  8b10                     mov      edx, dword ptr [rax]
0000000141d064dc  448b4004                 mov      r8d, dword ptr [rax + 4]
0000000141d064e0  899548010000             mov      dword ptr [rbp + 0x148], edx
0000000141d064e6  4489854c010000           mov      dword ptr [rbp + 0x14c], r8d
0000000141d064ed  488b85e8000000           mov      rax, qword ptr [rbp + 0xe8]
0000000141d064f4  488b4860                 mov      rcx, qword ptr [rax + 0x60]
0000000141d064f8  488b4068                 mov      rax, qword ptr [rax + 0x68]
0000000141d064fc  48898500010000           mov      qword ptr [rbp + 0x100], rax
0000000141d06503  488b85b0000000           mov      rax, qword ptr [rbp + 0xb0]
0000000141d0650a  48898508010000           mov      qword ptr [rbp + 0x108], rax
0000000141d06511  488b85b8000000           mov      rax, qword ptr [rbp + 0xb8]
0000000141d06518  48898510010000           mov      qword ptr [rbp + 0x110], rax
0000000141d0651f  488d4560                 lea      rax, [rbp + 0x60]
0000000141d06523  48898518010000           mov      qword ptr [rbp + 0x118], rax
0000000141d0652a  488d85f8000000           lea      rax, [rbp + 0xf8]
0000000141d06531  48898520010000           mov      qword ptr [rbp + 0x120], rax
0000000141d06538  488d8548010000           lea      rax, [rbp + 0x148]
0000000141d0653f  48898528010000           mov      qword ptr [rbp + 0x128], rax
0000000141d06546  488d8550010000           lea      rax, [rbp + 0x150]
0000000141d0654d  48898530010000           mov      qword ptr [rbp + 0x130], rax
0000000141d06554  488d85a0000000           lea      rax, [rbp + 0xa0]
0000000141d0655b  48898538010000           mov      qword ptr [rbp + 0x138], rax
0000000141d06562  4c8d8d00010000           lea      r9, [rbp + 0x100]
0000000141d06569  e8e212d0ff               call     0x141a07850 ; _ZN142_$LT$rapier3d..pipeline..query_pipeline..QueryPipelineAsCompositeShape$u20$as$u20$parry3d..shape..composite_shape..TypedSimdCompositeShape$GT$17map_typed_part_at17h991f4722cd874614E | rapier3d::pipeline::query_pipeline::impl$5::map_typed_part_at<parry3d::query::ray::ray_composite_shape::impl$4::visit::closure_env$0<rapier3d::pipeline::query_pipeline::QueryPipelineAsCompositeShape> >
0000000141d0656e  90                       nop      
0000000141d0656f  48c785f800000003000000   mov      qword ptr [rbp + 0xf8], 3
0000000141d0657a  4084f6                   test     sil, sil
0000000141d0657d  0f84a4000000             je       0x141d06627
0000000141d06583  48837d4800               cmp      qword ptr [rbp + 0x48], 0
0000000141d06588  0f8499000000             je       0x141d06627
0000000141d0658e  488b4548                 mov      rax, qword ptr [rbp + 0x48]
0000000141d06592  8b10                     mov      edx, dword ptr [rax]
0000000141d06594  448b4004                 mov      r8d, dword ptr [rax + 4]
0000000141d06598  899548010000             mov      dword ptr [rbp + 0x148], edx
0000000141d0659e  4489854c010000           mov      dword ptr [rbp + 0x14c], r8d
0000000141d065a5  488b85e8000000           mov      rax, qword ptr [rbp + 0xe8]
0000000141d065ac  488b4860                 mov      rcx, qword ptr [rax + 0x60]
0000000141d065b0  488b4068                 mov      rax, qword ptr [rax + 0x68]
0000000141d065b4  48898500010000           mov      qword ptr [rbp + 0x100], rax
0000000141d065bb  488b85b0000000           mov      rax, qword ptr [rbp + 0xb0]
0000000141d065c2  48898508010000           mov      qword ptr [rbp + 0x108], rax
0000000141d065c9  488b85b8000000           mov      rax, qword ptr [rbp + 0xb8]
0000000141d065d0  48898510010000           mov      qword ptr [rbp + 0x110], rax
0000000141d065d7  488d4560                 lea      rax, [rbp + 0x60]
0000000141d065db  48898518010000           mov      qword ptr [rbp + 0x118], rax
0000000141d065e2  488d85f8000000           lea      rax, [rbp + 0xf8]
0000000141d065e9  48898520010000           mov      qword ptr [rbp + 0x120], rax
0000000141d065f0  488d8548010000           lea      rax, [rbp + 0x148]
0000000141d065f7  48898528010000           mov      qword ptr [rbp + 0x128], rax
0000000141d065fe  488d8550010000           lea      rax, [rbp + 0x150]
0000000141d06605  48898530010000           mov      qword ptr [rbp + 0x130], rax
0000000141d0660c  488d85a0000000           lea      rax, [rbp + 0xa0]
0000000141d06613  48898538010000           mov      qword ptr [rbp + 0x138], rax
0000000141d0661a  4c8d8d00010000           lea      r9, [rbp + 0x100]
0000000141d06621  e82a12d0ff               call     0x141a07850 ; _ZN142_$LT$rapier3d..pipeline..query_pipeline..QueryPipelineAsCompositeShape$u20$as$u20$parry3d..shape..composite_shape..TypedSimdCompositeShape$GT$17map_typed_part_at17h991f4722cd874614E | rapier3d::pipeline::query_pipeline::impl$5::map_typed_part_at<parry3d::query::ray::ray_composite_shape::impl$4::visit::closure_env$0<rapier3d::pipeline::query_pipeline::QueryPipelineAsCompositeShape> >
0000000141d06626  90                       nop      
0000000141d06627  f30f109da0000000         movss    xmm3, dword ptr [rbp + 0xa0]
0000000141d0662f  f30f1095a4000000         movss    xmm2, dword ptr [rbp + 0xa4]
0000000141d06637  f30f108da8000000         movss    xmm1, dword ptr [rbp + 0xa8]
0000000141d0663f  f30f1085ac000000         movss    xmm0, dword ptr [rbp + 0xac]
0000000141d06647  448bbd50010000           mov      r15d, dword ptr [rbp + 0x150]
0000000141d0664e  8b4d60                   mov      ecx, dword ptr [rbp + 0x60]
0000000141d06651  8b4564                   mov      eax, dword ptr [rbp + 0x64]
0000000141d06654  8985c0000000             mov      dword ptr [rbp + 0xc0], eax
0000000141d0665a  488b4568                 mov      rax, qword ptr [rbp + 0x68]
0000000141d0665e  48894528                 mov      qword ptr [rbp + 0x28], rax
0000000141d06662  8b4570                   mov      eax, dword ptr [rbp + 0x70]
0000000141d06665  4c8d5574                 lea      r10, [rbp + 0x74]
0000000141d06669  418b5208                 mov      edx, dword ptr [r10 + 8]
0000000141d0666d  8955e8                   mov      dword ptr [rbp - 0x18], edx
0000000141d06670  498b12                   mov      rdx, qword ptr [r10]
0000000141d06673  488955e0                 mov      qword ptr [rbp - 0x20], rdx
0000000141d06677  8b9580000000             mov      edx, dword ptr [rbp + 0x80]
0000000141d0667d  458b4218                 mov      r8d, dword ptr [r10 + 0x18]
0000000141d06681  448945f8                 mov      dword ptr [rbp - 8], r8d
0000000141d06685  4d8b4210                 mov      r8, qword ptr [r10 + 0x10]
0000000141d06689  4c8945f0                 mov      qword ptr [rbp - 0x10], r8
0000000141d0668d  448b8590000000           mov      r8d, dword ptr [rbp + 0x90]
0000000141d06694  4d8b4a20                 mov      r9, qword ptr [r10 + 0x20]
0000000141d06698  4c894d00                 mov      qword ptr [rbp], r9
0000000141d0669c  458b4a28                 mov      r9d, dword ptr [r10 + 0x28]
0000000141d066a0  44894d08                 mov      dword ptr [rbp + 8], r9d
0000000141d066a4  83f902                   cmp      ecx, 2
0000000141d066a7  0f84c2020000             je       0x141d0696f
0000000141d066ad  f30f115d10               movss    dword ptr [rbp + 0x10], xmm3
0000000141d066b2  f30f115514               movss    dword ptr [rbp + 0x14], xmm2
0000000141d066b7  f30f114d18               movss    dword ptr [rbp + 0x18], xmm1
0000000141d066bc  f30f11451c               movss    dword ptr [rbp + 0x1c], xmm0
0000000141d066c1  898d00010000             mov      dword ptr [rbp + 0x100], ecx
0000000141d066c7  8b8dc0000000             mov      ecx, dword ptr [rbp + 0xc0]
0000000141d066cd  898d04010000             mov      dword ptr [rbp + 0x104], ecx
0000000141d066d3  488b4d28                 mov      rcx, qword ptr [rbp + 0x28]
0000000141d066d7  48898d08010000           mov      qword ptr [rbp + 0x108], rcx
0000000141d066de  898510010000             mov      dword ptr [rbp + 0x110], eax
0000000141d066e4  8b45e8                   mov      eax, dword ptr [rbp - 0x18]
0000000141d066e7  488d8d14010000           lea      rcx, [rbp + 0x114]
0000000141d066ee  894108                   mov      dword ptr [rcx + 8], eax
0000000141d066f1  488b45e0                 mov      rax, qword ptr [rbp - 0x20]
0000000141d066f5  488901                   mov      qword ptr [rcx], rax
0000000141d066f8  899520010000             mov      dword ptr [rbp + 0x120], edx
0000000141d066fe  8b45f8                   mov      eax, dword ptr [rbp - 8]
0000000141d06701  894118                   mov      dword ptr [rcx + 0x18], eax
0000000141d06704  488b45f0                 mov      rax, qword ptr [rbp - 0x10]
0000000141d06708  48894110                 mov      qword ptr [rcx + 0x10], rax
0000000141d0670c  44898530010000           mov      dword ptr [rbp + 0x130], r8d
0000000141d06713  8b4508                   mov      eax, dword ptr [rbp + 8]
0000000141d06716  894128                   mov      dword ptr [rcx + 0x28], eax
0000000141d06719  488b4500                 mov      rax, qword ptr [rbp]
0000000141d0671d  48894120                 mov      qword ptr [rcx + 0x20], rax
0000000141d06721  4489f8                   mov      eax, r15d
0000000141d06724  83e001                   and      eax, 1
0000000141d06727  4489f9                   mov      ecx, r15d
0000000141d0672a  c1e907                   shr      ecx, 7
0000000141d0672d  83e102                   and      ecx, 2
0000000141d06730  09c1                     or       ecx, eax
0000000141d06732  4489f8                   mov      eax, r15d
0000000141d06735  c1e80e                   shr      eax, 0xe
0000000141d06738  83e004                   and      eax, 4
0000000141d0673b  09c8                     or       eax, ecx
0000000141d0673d  41c1ef15                 shr      r15d, 0x15
0000000141d06741  4183e708                 and      r15d, 8
0000000141d06745  4109c7                   or       r15d, eax
0000000141d06748  31f6                     xor      esi, esi
0000000141d0674a  eb14                     jmp      0x141d06760
0000000141d0674c  31db                     xor      ebx, ebx
0000000141d0674e  890cd8                   mov      dword ptr [rax + rbx*8], ecx
0000000141d06751  f30f1144d804             movss    dword ptr [rax + rbx*8 + 4], xmm0
0000000141d06757  660f1f840000000000       nop      word ptr [rax + rax]
0000000141d06760  4883fe04                 cmp      rsi, 4
0000000141d06764  0f83f6f9ffff             jae      0x141d06160
0000000141d0676a  4889f1                   mov      rcx, rsi
0000000141d0676d  48ffc6                   inc      rsi
0000000141d06770  b801000000               mov      eax, 1
0000000141d06775  48d3e0                   shl      rax, cl
0000000141d06778  4485f8                   test     eax, r15d
0000000141d0677b  74e3                     je       0x141d06760
0000000141d0677d  41f6c601                 test     r14b, 1
0000000141d06781  0f8599000000             jne      0x141d06820
0000000141d06787  458b6c8c60               mov      r13d, dword ptr [r12 + rcx*4 + 0x60]
0000000141d0678c  4c39ef                   cmp      rdi, r13
0000000141d0678f  76cf                     jbe      0x141d06760
0000000141d06791  f3440f10548d10           movss    xmm10, dword ptr [rbp + rcx*4 + 0x10]
0000000141d06798  488b9de0000000           mov      rbx, qword ptr [rbp + 0xe0]
0000000141d0679f  483b9dd0000000           cmp      rbx, qword ptr [rbp + 0xd0]
0000000141d067a6  750d                     jne      0x141d067b5
0000000141d067a8  488d8dd0000000           lea      rcx, [rbp + 0xd0]
0000000141d067af  e81ca00a01               call     0x142db07d0 ; _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h00df97f05d0f1c52E | _ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$8grow_one17h142b2e73de25e47dE
0000000141d067b4  90                       nop      
0000000141d067b5  450f57d0                 xorps    xmm10, xmm8
0000000141d067b9  488b85d8000000           mov      rax, qword ptr [rbp + 0xd8]
0000000141d067c0  44892cd8                 mov      dword ptr [rax + rbx*8], r13d
0000000141d067c4  f3440f1154d804           movss    dword ptr [rax + rbx*8 + 4], xmm10
0000000141d067cb  488d4301                 lea      rax, [rbx + 1]
0000000141d067cf  488985e0000000           mov      qword ptr [rbp + 0xe0], rax
0000000141d067d6  488b85d8000000           mov      rax, qword ptr [rbp + 0xd8]
0000000141d067dd  8b0cd8                   mov      ecx, dword ptr [rax + rbx*8]
0000000141d067e0  f30f1044d804             movss    xmm0, dword ptr [rax + rbx*8 + 4]
0000000141d067e6  4885db                   test     rbx, rbx
0000000141d067e9  0f845dffffff             je       0x141d0674c
0000000141d067ef  90                       nop      
0000000141d067f0  488d53ff                 lea      rdx, [rbx - 1]
0000000141d067f4  48d1ea                   shr      rdx, 1
0000000141d067f7  0f2e44d004               ucomiss  xmm0, dword ptr [rax + rdx*8 + 4]
0000000141d067fc  0f864cffffff             jbe      0x141d0674e
0000000141d06802  4c8b04d0                 mov      r8, qword ptr [rax + rdx*8]
0000000141d06806  4c8904d8                 mov      qword ptr [rax + rbx*8], r8
0000000141d0680a  4889d3                   mov      rbx, rdx
0000000141d0680d  4885d2                   test     rdx, rdx
0000000141d06810  75de                     jne      0x141d067f0
0000000141d06812  e935ffffff               jmp      0x141d0674c
0000000141d06817  660f1f840000000000       nop      word ptr [rax + rax]
0000000141d06820  f30f10448d10             movss    xmm0, dword ptr [rbp + rcx*4 + 0x10]
0000000141d06826  0f2ef8                   ucomiss  xmm7, xmm0
0000000141d06829  0f8631ffffff             jbe      0x141d06760
0000000141d0682f  4889c8                   mov      rax, rcx
0000000141d06832  48c1e004                 shl      rax, 4
0000000141d06836  83bc050001000000         cmp      dword ptr [rbp + rax + 0x100], 0
0000000141d0683e  0f841cffffff             je       0x141d06760
0000000141d06844  418b4c8c60               mov      ecx, dword ptr [r12 + rcx*4 + 0x60]
0000000141d06849  48394d20                 cmp      qword ptr [rbp + 0x20], rcx
0000000141d0684d  0f860dffffff             jbe      0x141d06760
0000000141d06853  4801e8                   add      rax, rbp
0000000141d06856  480500010000             add      rax, 0x100
0000000141d0685c  48c1e104                 shl      rcx, 4
0000000141d06860  488b5550                 mov      rdx, qword ptr [rbp + 0x50]
0000000141d06864  448b040a                 mov      r8d, dword ptr [rdx + rcx]
0000000141d06868  448985cc000000           mov      dword ptr [rbp + 0xcc], r8d
0000000141d0686f  0fb64c0a04               movzx    ecx, byte ptr [rdx + rcx + 4]
0000000141d06874  888d57010000             mov      byte ptr [rbp + 0x157], cl
0000000141d0687a  8b4804                   mov      ecx, dword ptr [rax + 4]
0000000141d0687d  898dc4000000             mov      dword ptr [rbp + 0xc4], ecx
0000000141d06883  8b4808                   mov      ecx, dword ptr [rax + 8]
0000000141d06886  898dc8000000             mov      dword ptr [rbp + 0xc8], ecx
0000000141d0688c  f30f10700c               movss    xmm6, dword ptr [rax + 0xc]
0000000141d06891  c785f400000001000000     mov      dword ptr [rbp + 0xf4], 1
0000000141d0689b  0f28f8                   movaps   xmm7, xmm0
0000000141d0689e  e9bdfeffff               jmp      0x141d06760
0000000141d068a3  488b7558                 mov      rsi, qword ptr [rbp + 0x58]
0000000141d068a7  8b85f4000000             mov      eax, dword ptr [rbp + 0xf4]
0000000141d068ad  8906                     mov      dword ptr [rsi], eax
0000000141d068af  8b85cc000000             mov      eax, dword ptr [rbp + 0xcc]
0000000141d068b5  894604                   mov      dword ptr [rsi + 4], eax
0000000141d068b8  0fb68557010000           movzx    eax, byte ptr [rbp + 0x157]
0000000141d068bf  884608                   mov      byte ptr [rsi + 8], al
0000000141d068c2  8b85c4000000             mov      eax, dword ptr [rbp + 0xc4]
0000000141d068c8  89460c                   mov      dword ptr [rsi + 0xc], eax
0000000141d068cb  8b85c8000000             mov      eax, dword ptr [rbp + 0xc8]
0000000141d068d1  894610                   mov      dword ptr [rsi + 0x10], eax
0000000141d068d4  f30f117614               movss    dword ptr [rsi + 0x14], xmm6
0000000141d068d9  488b85d0000000           mov      rax, qword ptr [rbp + 0xd0]
0000000141d068e0  4885c0                   test     rax, rax
0000000141d068e3  7427                     je       0x141d0690c
0000000141d068e5  48c1e003                 shl      rax, 3
0000000141d068e9  488b8dd8000000           mov      rcx, qword ptr [rbp + 0xd8]
0000000141d068f0  48c7850001000004000000   mov      qword ptr [rbp + 0x100], 4
0000000141d068fb  488d5560                 lea      rdx, [rbp + 0x60]
0000000141d068ff  eb14                     jmp      0x141d06915
0000000141d06901  c70100000000             mov      dword ptr [rcx], 0
0000000141d06907  4889ce                   mov      rsi, rcx
0000000141d0690a  eb26                     jmp      0x141d06932
0000000141d0690c  31c0                     xor      eax, eax
0000000141d0690e  488d9500010000           lea      rdx, [rbp + 0x100]
0000000141d06915  488902                   mov      qword ptr [rdx], rax
0000000141d06918  4c8b8500010000           mov      r8, qword ptr [rbp + 0x100]
0000000141d0691f  4d85c0                   test     r8, r8
0000000141d06922  740e                     je       0x141d06932
0000000141d06924  488b5560                 mov      rdx, qword ptr [rbp + 0x60]
0000000141d06928  4885d2                   test     rdx, rdx
0000000141d0692b  7405                     je       0x141d06932
0000000141d0692d  e88e519afe               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
0000000141d06932  4889f0                   mov      rax, rsi
0000000141d06935  0f28b560010000           movaps   xmm6, xmmword ptr [rbp + 0x160]
0000000141d0693c  0f28bd70010000           movaps   xmm7, xmmword ptr [rbp + 0x170]
0000000141d06943  440f288580010000         movaps   xmm8, xmmword ptr [rbp + 0x180]
0000000141d0694b  440f288d90010000         movaps   xmm9, xmmword ptr [rbp + 0x190]
0000000141d06953  440f2895a0010000         movaps   xmm10, xmmword ptr [rbp + 0x1a0]
0000000141d0695b  4881c438020000           add      rsp, 0x238
0000000141d06962  5b                       pop      rbx
0000000141d06963  5f                       pop      rdi
0000000141d06964  5e                       pop      rsi
0000000141d06965  415c                     pop      r12
0000000141d06967  415d                     pop      r13
0000000141d06969  415e                     pop      r14
0000000141d0696b  415f                     pop      r15
0000000141d0696d  5d                       pop      rbp
0000000141d0696e  c3                       ret      
0000000141d0696f  31c9                     xor      ecx, ecx
0000000141d06971  f685c000000001           test     byte ptr [rbp + 0xc0], 1
0000000141d06978  7421                     je       0x141d0699b
0000000141d0697a  418b4c2470               mov      ecx, dword ptr [r12 + 0x70]
0000000141d0697f  410fb6542474             movzx    edx, byte ptr [r12 + 0x74]
0000000141d06985  894d64                   mov      dword ptr [rbp + 0x64], ecx
0000000141d06988  885568                   mov      byte ptr [rbp + 0x68], dl
0000000141d0698b  488b4d28                 mov      rcx, qword ptr [rbp + 0x28]
0000000141d0698f  48894d6c                 mov      qword ptr [rbp + 0x6c], rcx
0000000141d06993  894574                   mov      dword ptr [rbp + 0x74], eax
0000000141d06996  b901000000               mov      ecx, 1
0000000141d0699b  894d60                   mov      dword ptr [rbp + 0x60], ecx
0000000141d0699e  8b85f4000000             mov      eax, dword ptr [rbp + 0xf4]
0000000141d069a4  898500010000             mov      dword ptr [rbp + 0x100], eax
0000000141d069aa  8b85cc000000             mov      eax, dword ptr [rbp + 0xcc]
0000000141d069b0  898504010000             mov      dword ptr [rbp + 0x104], eax
0000000141d069b6  0fb68557010000           movzx    eax, byte ptr [rbp + 0x157]
0000000141d069bd  888508010000             mov      byte ptr [rbp + 0x108], al
0000000141d069c3  8b85c4000000             mov      eax, dword ptr [rbp + 0xc4]
0000000141d069c9  89850c010000             mov      dword ptr [rbp + 0x10c], eax
0000000141d069cf  8b85c8000000             mov      eax, dword ptr [rbp + 0xc8]
0000000141d069d5  898510010000             mov      dword ptr [rbp + 0x110], eax
0000000141d069db  f30f11b514010000         movss    dword ptr [rbp + 0x114], xmm6
0000000141d069e3  85c9                     test     ecx, ecx
0000000141d069e5  4c8d4560                 lea      r8, [rbp + 0x60]
0000000141d069e9  488d8500010000           lea      rax, [rbp + 0x100]
0000000141d069f0  4889c1                   mov      rcx, rax
0000000141d069f3  490f45c8                 cmovne   rcx, r8
0000000141d069f7  488b5110                 mov      rdx, qword ptr [rcx + 0x10]
0000000141d069fb  488b7558                 mov      rsi, qword ptr [rbp + 0x58]
0000000141d069ff  48895610                 mov      qword ptr [rsi + 0x10], rdx
0000000141d06a03  0f1001                   movups   xmm0, xmmword ptr [rcx]
0000000141d06a06  0f1106                   movups   xmmword ptr [rsi], xmm0
0000000141d06a09  488b95d0000000           mov      rdx, qword ptr [rbp + 0xd0]
0000000141d06a10  4885d2                   test     rdx, rdx
0000000141d06a13  741e                     je       0x141d06a33
0000000141d06a15  48c1e203                 shl      rdx, 3
0000000141d06a19  488b8dd8000000           mov      rcx, qword ptr [rbp + 0xd8]
0000000141d06a20  48c7850001000004000000   mov      qword ptr [rbp + 0x100], 4
0000000141d06a2b  498910                   mov      qword ptr [r8], rdx
0000000141d06a2e  e9e5feffff               jmp      0x141d06918
0000000141d06a33  31d2                     xor      edx, edx
0000000141d06a35  488910                   mov      qword ptr [rax], rdx
0000000141d06a38  e9dbfeffff               jmp      0x141d06918
0000000141d06a3d  4c8d05143b6c01           lea      r8, [rip + 0x16c3b14]
0000000141d06a44  4889fa                   mov      rdx, rdi
0000000141d06a47  e8a6170c01               call     0x142dc81f2 ; core::panicking::panic_bounds_check | _RNvNtCs8icZUrvfcq9_4core9panicking18panic_bounds_check
0000000141d06a4c  90                       nop      
0000000141d06a4d  0f0b                     ud2      
0000000141d06a4f  90                       nop      
0000000141d06a50  4889542410               mov      qword ptr [rsp + 0x10], rdx
0000000141d06a55  55                       push     rbp
0000000141d06a56  4157                     push     r15
0000000141d06a58  4156                     push     r14
0000000141d06a5a  4155                     push     r13
0000000141d06a5c  4154                     push     r12
0000000141d06a5e  56                       push     rsi
0000000141d06a5f  57                       push     rdi
0000000141d06a60  53                       push     rbx
0000000141d06a61  4883ec78                 sub      rsp, 0x78
0000000141d06a65  488daa80000000           lea      rbp, [rdx + 0x80]
0000000141d06a6c  440f29542420             movaps   xmmword ptr [rsp + 0x20], xmm10
0000000141d06a72  440f294c2430             movaps   xmmword ptr [rsp + 0x30], xmm9
0000000141d06a78  440f29442440             movaps   xmmword ptr [rsp + 0x40], xmm8
0000000141d06a7e  0f297c2450               movaps   xmmword ptr [rsp + 0x50], xmm7
0000000141d06a83  0f29742460               movaps   xmmword ptr [rsp + 0x60], xmm6
0000000141d06a88  488d8dd0000000           lea      rcx, [rbp + 0xd0]
0000000141d06a8f  e89cf3fcfe               call     0x140cd5e30 ; core::ptr::drop_in_place<regex_syntax::hir::ClassUnicode> | core::ptr::drop_in_place<regex_automata::nfa::thompson::range_trie::State>
0000000141d06a94  0f28742460               movaps   xmm6, xmmword ptr [rsp + 0x60]
0000000141d06a99  0f287c2450               movaps   xmm7, xmmword ptr [rsp + 0x50]
0000000141d06a9e  440f28442440             movaps   xmm8, xmmword ptr [rsp + 0x40]
0000000141d06aa4  440f284c2430             movaps   xmm9, xmmword ptr [rsp + 0x30]
0000000141d06aaa  440f28542420             movaps   xmm10, xmmword ptr [rsp + 0x20]
0000000141d06ab0  4883c478                 add      rsp, 0x78
0000000141d06ab4  5b                       pop      rbx
0000000141d06ab5  5f                       pop      rdi
0000000141d06ab6  5e                       pop      rsi
0000000141d06ab7  415c                     pop      r12
0000000141d06ab9  415d                     pop      r13
0000000141d06abb  415e                     pop      r14
0000000141d06abd  415f                     pop      r15
0000000141d06abf  5d                       pop      rbp
0000000141d06ac0  c3                       ret      