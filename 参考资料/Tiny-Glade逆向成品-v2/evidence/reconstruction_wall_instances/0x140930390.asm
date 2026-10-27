0000000140930390  4883ec28                 sub      rsp, 0x28
0000000140930394  80b90801000000           cmp      byte ptr [rcx + 0x108], 0
000000014093039b  740d                     je       0x1409303aa
000000014093039d  f30f10810c010000         movss    xmm0, dword ptr [rcx + 0x10c]
00000001409303a5  4883c428                 add      rsp, 0x28
00000001409303a9  c3                       ret      
00000001409303aa  e891dc4502               call     0x142d8e040 ; country_core::resources::walls::public_wall_state::impl$0::max_y::closure$0 | _ZN12country_core9resources5walls17public_wall_state15PublicWallState5max_y28_$u7b$$u7b$closure$u7d$$u7d$17h631be69922351c74E.llvm.9594058148382606787
00000001409303af  cc                       int3     