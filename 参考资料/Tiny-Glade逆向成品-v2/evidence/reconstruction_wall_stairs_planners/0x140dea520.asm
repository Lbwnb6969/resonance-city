0000000140dea520  56                       push     rsi
0000000140dea521  57                       push     rdi
0000000140dea522  4883ec28                 sub      rsp, 0x28
0000000140dea526  4889d6                   mov      rsi, rdx
0000000140dea529  4889cf                   mov      rdi, rcx
0000000140dea52c  f30f1009                 movss    xmm1, dword ptr [rcx]
0000000140dea530  f30f105108               movss    xmm2, dword ptr [rcx + 8]
0000000140dea535  4c8d0d34494102           lea      r9, [rip + 0x2414934]
0000000140dea53c  4889d1                   mov      rcx, rdx
0000000140dea53f  e86cea0401               call     0x141e38fb0 ; _ZN5utils5curve21Curve$LT$T$C$CSem$GT$21get_approx_u_from_pos17hfc6d69f2654477c0E | utils::curve::Curve::get_approx_u_from_pos<glam::f32::vec2::Vec2,utils::curve::CurveCoordSemantic2D>
0000000140dea544  0f57c9                   xorps    xmm1, xmm1
0000000140dea547  f30f5fc8                 maxss    xmm1, xmm0
0000000140dea54b  f30f1005d5c90402         movss    xmm0, dword ptr [rip + 0x204c9d5]
0000000140dea553  f30f5dc1                 minss    xmm0, xmm1
0000000140dea557  f30f594630               mulss    xmm0, dword ptr [rsi + 0x30]
0000000140dea55c  f30f104f04               movss    xmm1, dword ptr [rdi + 4]
0000000140dea561  4883c428                 add      rsp, 0x28
0000000140dea565  5f                       pop      rdi
0000000140dea566  5e                       pop      rsi
0000000140dea567  c3                       ret      