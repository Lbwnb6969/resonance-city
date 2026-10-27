00000001409edd20  56                       push     rsi
00000001409edd21  4883ec40                 sub      rsp, 0x40
00000001409edd25  4889ce                   mov      rsi, rcx
00000001409edd28  8b442470                 mov      eax, dword ptr [rsp + 0x70]
00000001409edd2c  89442430                 mov      dword ptr [rsp + 0x30], eax
00000001409edd30  f30f115c2428             movss    dword ptr [rsp + 0x28], xmm3
00000001409edd36  4531c9                   xor      r9d, r9d
00000001409edd39  e8f2b20000               call     0x1409f9030 ; country_core::systems::collision::world::Rapier::raycast_simple | _ZN12country_core7systems9collision5world6Rapier14raycast_simple17h6074b2086f1d89e9E.llvm.5062323474712436301
00000001409edd3e  4889f0                   mov      rax, rsi
00000001409edd41  4883c440                 add      rsp, 0x40
00000001409edd45  5e                       pop      rsi
00000001409edd46  c3                       ret      