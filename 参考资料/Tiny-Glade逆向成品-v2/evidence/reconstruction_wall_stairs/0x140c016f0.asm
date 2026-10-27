0000000140c016f0  4883ec28                 sub      rsp, 0x28
0000000140c016f4  0fb601                   movzx    eax, byte ptr [rcx]
0000000140c016f7  85c0                     test     eax, eax
0000000140c016f9  741e                     je       0x140c01719
0000000140c016fb  83f801                   cmp      eax, 1
0000000140c016fe  7532                     jne      0x140c01732
0000000140c01700  b810000000               mov      eax, 0x10
0000000140c01705  ba0c000000               mov      edx, 0xc
0000000140c0170a  f30f100411               movss    xmm0, dword ptr [rcx + rdx]
0000000140c0170f  f30f100c01               movss    xmm1, dword ptr [rcx + rax]
0000000140c01714  4883c428                 add      rsp, 0x28
0000000140c01718  c3                       ret      
0000000140c01719  b808000000               mov      eax, 8
0000000140c0171e  ba04000000               mov      edx, 4
0000000140c01723  f30f100411               movss    xmm0, dword ptr [rcx + rdx]
0000000140c01728  f30f100c01               movss    xmm1, dword ptr [rcx + rax]
0000000140c0172d  4883c428                 add      rsp, 0x28
0000000140c01731  c3                       ret      
0000000140c01732  488d0da9684602           lea      rcx, [rip + 0x24668a9] ; 'AlignKind::None has no defined outgoing_dircrates/country-core/src/resources/stairs/stairs_assem'
0000000140c01739  4c8d0510694602           lea      r8, [rip + 0x2466910]
0000000140c01740  ba57000000               mov      edx, 0x57
0000000140c01745  e8866c1c02               call     0x142dc83d0 ; core::panicking::panic_fmt | _RNvNtCs8icZUrvfcq9_4core9panicking9panic_fmt
0000000140c0174a  cc                       int3     