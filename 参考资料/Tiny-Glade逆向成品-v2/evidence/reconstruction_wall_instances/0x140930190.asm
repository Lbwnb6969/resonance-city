0000000140930190  4883ec28                 sub      rsp, 0x28
0000000140930194  31c0                     xor      eax, eax
0000000140930196  80b99f02000001           cmp      byte ptr [rcx + 0x29f], 1
000000014093019d  7530                     jne      0x1409301cf
000000014093019f  83b95802000001           cmp      dword ptr [rcx + 0x258], 1
00000001409301a6  7727                     ja       0x1409301cf
00000001409301a8  f30f108194020000         movss    xmm0, dword ptr [rcx + 0x294]
00000001409301b0  0f57c9                   xorps    xmm1, xmm1
00000001409301b3  0f2ec1                   ucomiss  xmm0, xmm1
00000001409301b6  7612                     jbe      0x1409301ca
00000001409301b8  e873fdffff               call     0x14092ff30 ; country_core::resources::walls::public_wall_state::PublicWallState::stone_foundation_transition_y | _ZN12country_core9resources5walls17public_wall_state15PublicWallState29stone_foundation_transition_y17hdda4e85397708e77E
00000001409301bd  f30f5805d3c96e02         addss    xmm0, dword ptr [rip + 0x26ec9d3]
00000001409301c5  b801000000               mov      eax, 1
00000001409301ca  4883c428                 add      rsp, 0x28
00000001409301ce  c3                       ret      
00000001409301cf  4883c428                 add      rsp, 0x28
00000001409301d3  c3                       ret      