00000001413ed750  55                       push     rbp
00000001413ed751  4157                     push     r15
00000001413ed753  4156                     push     r14
00000001413ed755  4155                     push     r13
00000001413ed757  4154                     push     r12
00000001413ed759  56                       push     rsi
00000001413ed75a  57                       push     rdi
00000001413ed75b  53                       push     rbx
00000001413ed75c  4881ec98020000           sub      rsp, 0x298
00000001413ed763  488dac2480000000         lea      rbp, [rsp + 0x80]
00000001413ed76b  440f29bd00020000         movaps   xmmword ptr [rbp + 0x200], xmm15
00000001413ed773  66440f7fb5f0010000       movdqa   xmmword ptr [rbp + 0x1f0], xmm14
00000001413ed77c  66440f7fade0010000       movdqa   xmmword ptr [rbp + 0x1e0], xmm13
00000001413ed785  66440f7fa5d0010000       movdqa   xmmword ptr [rbp + 0x1d0], xmm12
00000001413ed78e  66440f7f9dc0010000       movdqa   xmmword ptr [rbp + 0x1c0], xmm11
00000001413ed797  66440f7f95b0010000       movdqa   xmmword ptr [rbp + 0x1b0], xmm10
00000001413ed7a0  66440f7f8da0010000       movdqa   xmmword ptr [rbp + 0x1a0], xmm9
00000001413ed7a9  440f298590010000         movaps   xmmword ptr [rbp + 0x190], xmm8
00000001413ed7b1  0f29bd80010000           movaps   xmmword ptr [rbp + 0x180], xmm7
00000001413ed7b8  0f29b570010000           movaps   xmmword ptr [rbp + 0x170], xmm6
00000001413ed7bf  48c78568010000feffffff   mov      qword ptr [rbp + 0x168], 0xfffffffffffffffe
00000001413ed7ca  4889ce                   mov      rsi, rcx
00000001413ed7cd  488b5a18                 mov      rbx, qword ptr [rdx + 0x18]
00000001413ed7d1  4c8b7220                 mov      r14, qword ptr [rdx + 0x20]
00000001413ed7d5  4c39f3                   cmp      rbx, r14
00000001413ed7d8  7374                     jae      0x1413ed84e
00000001413ed7da  4c8b3a                   mov      r15, qword ptr [rdx]
00000001413ed7dd  4c8b6208                 mov      r12, qword ptr [rdx + 8]
00000001413ed7e1  f3410f1007               movss    xmm0, dword ptr [r15]
00000001413ed7e6  f3410f100c24             movss    xmm1, dword ptr [r12]
00000001413ed7ec  4c8b6a10                 mov      r13, qword ptr [rdx + 0x10]
00000001413ed7f0  f3410f105500             movss    xmm2, dword ptr [r13]
00000001413ed7f6  f3440f1005d5a2a401       movss    xmm8, dword ptr [rip + 0x1a4a2d5]
00000001413ed7ff  90                       nop      
00000001413ed800  4885db                   test     rbx, rbx
00000001413ed803  780b                     js       0x1413ed810
00000001413ed805  0f57f6                   xorps    xmm6, xmm6
00000001413ed808  f3480f2af3               cvtsi2ss xmm6, rbx
00000001413ed80d  eb1b                     jmp      0x1413ed82a
00000001413ed80f  90                       nop      
00000001413ed810  4889d8                   mov      rax, rbx
00000001413ed813  48d1e8                   shr      rax, 1
00000001413ed816  89d9                     mov      ecx, ebx
00000001413ed818  83e101                   and      ecx, 1
00000001413ed81b  4809c1                   or       rcx, rax
00000001413ed81e  0f57f6                   xorps    xmm6, xmm6
00000001413ed821  f3480f2af1               cvtsi2ss xmm6, rcx
00000001413ed826  f30f58f6                 addss    xmm6, xmm6
00000001413ed82a  f30f59f1                 mulss    xmm6, xmm1
00000001413ed82e  f30f58f0                 addss    xmm6, xmm0
00000001413ed832  0f28fe                   movaps   xmm7, xmm6
00000001413ed835  f30f58fa                 addss    xmm7, xmm2
00000001413ed839  0f28df                   movaps   xmm3, xmm7
00000001413ed83c  f30f5cde                 subss    xmm3, xmm6
00000001413ed840  410f2ed8                 ucomiss  xmm3, xmm8
00000001413ed844  7324                     jae      0x1413ed86a
00000001413ed846  48ffc3                   inc      rbx
00000001413ed849  4939de                   cmp      r14, rbx
00000001413ed84c  75b2                     jne      0x1413ed800
00000001413ed84e  48c70600000000           mov      qword ptr [rsi], 0
00000001413ed855  48c7460804000000         mov      qword ptr [rsi + 8], 4
00000001413ed85d  48c7461000000000         mov      qword ptr [rsi + 0x10], 0
00000001413ed865  e995090000               jmp      0x1413ee1ff
00000001413ed86a  e8f115c9fe               call     0x14007ee60 ; log::impl$17::log | log::impl$17::flush
00000001413ed86f  b920000000               mov      ecx, 0x20
00000001413ed874  ba04000000               mov      edx, 4
00000001413ed879  e832e22bff               call     0x1406abab0 ; _RNvCsfLfy6EI15iL_7___rustc12___rust_alloc
00000001413ed87e  4885c0                   test     rax, rax
00000001413ed881  0f84dd090000             je       0x1413ee264
00000001413ed887  48ffc3                   inc      rbx
00000001413ed88a  f30f1130                 movss    dword ptr [rax], xmm6
00000001413ed88e  f30f117804               movss    dword ptr [rax + 4], xmm7
00000001413ed893  48c7852801000004000000   mov      qword ptr [rbp + 0x128], 4
00000001413ed89e  48898530010000           mov      qword ptr [rbp + 0x130], rax
00000001413ed8a5  48c7853801000001000000   mov      qword ptr [rbp + 0x138], 1
00000001413ed8b0  4c39f3                   cmp      rbx, r14
00000001413ed8b3  0f8326090000             jae      0x1413ee1df
00000001413ed8b9  bf01000000               mov      edi, 1
00000001413ed8be  eb25                     jmp      0x1413ed8e5
00000001413ed8c0  488b8530010000           mov      rax, qword ptr [rbp + 0x130]
00000001413ed8c7  f30f1134f8               movss    dword ptr [rax + rdi*8], xmm6
00000001413ed8cc  f30f117cf804             movss    dword ptr [rax + rdi*8 + 4], xmm7
00000001413ed8d2  48ffc7                   inc      rdi
00000001413ed8d5  4889bd38010000           mov      qword ptr [rbp + 0x138], rdi
00000001413ed8dc  4c39f3                   cmp      rbx, r14
00000001413ed8df  0f83fa080000             jae      0x1413ee1df
00000001413ed8e5  f3410f100f               movss    xmm1, dword ptr [r15]
00000001413ed8ea  f3410f101424             movss    xmm2, dword ptr [r12]
00000001413ed8f0  f3410f105d00             movss    xmm3, dword ptr [r13]
00000001413ed8f6  4d89f0                   mov      r8, r14
00000001413ed8f9  4929d8                   sub      r8, rbx
00000001413ed8fc  4983f830                 cmp      r8, 0x30
00000001413ed900  7308                     jae      0x1413ed90a
00000001413ed902  4889da                   mov      rdx, rbx
00000001413ed905  e946080000               jmp      0x1413ee150
00000001413ed90a  4d89c1                   mov      r9, r8
00000001413ed90d  4983e1f0                 and      r9, 0xfffffffffffffff0
00000001413ed911  4a8d140b                 lea      rdx, [rbx + r9]
00000001413ed915  0f298da0000000           movaps   xmmword ptr [rbp + 0xa0], xmm1
00000001413ed91c  0fc6c900                 shufps   xmm1, xmm1, 0
00000001413ed920  0f294d70                 movaps   xmmword ptr [rbp + 0x70], xmm1
00000001413ed924  0f2995b0000000           movaps   xmmword ptr [rbp + 0xb0], xmm2
00000001413ed92b  0fc6d200                 shufps   xmm2, xmm2, 0
00000001413ed92f  0f299580000000           movaps   xmmword ptr [rbp + 0x80], xmm2
00000001413ed936  0f299dc0000000           movaps   xmmword ptr [rbp + 0xc0], xmm3
00000001413ed93d  0fc6db00                 shufps   xmm3, xmm3, 0
00000001413ed941  0f299d90000000           movaps   xmmword ptr [rbp + 0x90], xmm3
00000001413ed948  66480f6ec3               movq     xmm0, rbx
00000001413ed94d  66440f70e844             pshufd   xmm13, xmm0, 0x44
00000001413ed953  66450f6ff5               movdqa   xmm14, xmm13
00000001413ed958  66440fd4351f9ec101       paddq    xmm14, xmmword ptr [rip + 0x1c19e1f]
00000001413ed961  66410f6ff5               movdqa   xmm6, xmm13
00000001413ed966  660fd435229ec101         paddq    xmm6, xmmword ptr [rip + 0x1c19e22]
00000001413ed96e  66450f6fdd               movdqa   xmm11, xmm13
00000001413ed973  66440fd41d249ec101       paddq    xmm11, xmmword ptr [rip + 0x1c19e24]
00000001413ed97c  66410f6fc5               movdqa   xmm0, xmm13
00000001413ed981  660fd405279ec101         paddq    xmm0, xmmword ptr [rip + 0x1c19e27]
00000001413ed989  660f7f8540010000         movdqa   xmmword ptr [rbp + 0x140], xmm0
00000001413ed991  66450f6fcd               movdqa   xmm9, xmm13
00000001413ed996  66440fd40d219ec101       paddq    xmm9, xmmword ptr [rip + 0x1c19e21]
00000001413ed99f  66410f6fcd               movdqa   xmm1, xmm13
00000001413ed9a4  660fd40d249ec101         paddq    xmm1, xmmword ptr [rip + 0x1c19e24]
00000001413ed9ac  660f7f8d00010000         movdqa   xmmword ptr [rbp + 0x100], xmm1
00000001413ed9b4  66450f6fe5               movdqa   xmm12, xmm13
00000001413ed9b9  66440fd4251e9ec101       paddq    xmm12, xmmword ptr [rip + 0x1c19e1e]
00000001413ed9c2  66440fd42db525a601       paddq    xmm13, xmmword ptr [rip + 0x1a625b5]
00000001413ed9cb  b90f000000               mov      ecx, 0xf
00000001413ed9d0  4829d9                   sub      rcx, rbx
00000001413ed9d3  4d8d51f0                 lea      r10, [r9 - 0x10]
00000001413ed9d7  660f1f840000000000       nop      word ptr [rax + rax]
00000001413ed9e0  664d0f7eeb               movq     r11, xmm13
00000001413ed9e5  4d85db                   test     r11, r11
00000001413ed9e8  7816                     js       0x1413eda00
00000001413ed9ea  0f57db                   xorps    xmm3, xmm3
00000001413ed9ed  f3490f2adb               cvtsi2ss xmm3, r11
00000001413ed9f2  eb25                     jmp      0x1413eda19
00000001413ed9f4  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001413eda00  4c89db                   mov      rbx, r11
00000001413eda03  48d1eb                   shr      rbx, 1
00000001413eda06  4183e301                 and      r11d, 1
00000001413eda0a  4909db                   or       r11, rbx
00000001413eda0d  0f57db                   xorps    xmm3, xmm3
00000001413eda10  f3490f2adb               cvtsi2ss xmm3, r11
00000001413eda15  f30f58db                 addss    xmm3, xmm3
00000001413eda19  66410f6fc1               movdqa   xmm0, xmm9
00000001413eda1e  66440f6fce               movdqa   xmm9, xmm6
00000001413eda23  66410f70cdee             pshufd   xmm1, xmm13, 0xee
00000001413eda29  66490f7ecb               movq     r11, xmm1
00000001413eda2e  4d85db                   test     r11, r11
00000001413eda31  783d                     js       0x1413eda70
00000001413eda33  0f57c9                   xorps    xmm1, xmm1
00000001413eda36  f3490f2acb               cvtsi2ss xmm1, r11
00000001413eda3b  0f298d10010000           movaps   xmmword ptr [rbp + 0x110], xmm1
00000001413eda42  664d0f7ee3               movq     r11, xmm12
00000001413eda47  4d85db                   test     r11, r11
00000001413eda4a  794e                     jns      0x1413eda9a
00000001413eda4c  4c89db                   mov      rbx, r11
00000001413eda4f  48d1eb                   shr      rbx, 1
00000001413eda52  4183e301                 and      r11d, 1
00000001413eda56  4909db                   or       r11, rbx
00000001413eda59  0f57c9                   xorps    xmm1, xmm1
00000001413eda5c  f3490f2acb               cvtsi2ss xmm1, r11
00000001413eda61  f30f58c9                 addss    xmm1, xmm1
00000001413eda65  eb3b                     jmp      0x1413edaa2
00000001413eda67  660f1f840000000000       nop      word ptr [rax + rax]
00000001413eda70  4c89db                   mov      rbx, r11
00000001413eda73  48d1eb                   shr      rbx, 1
00000001413eda76  4183e301                 and      r11d, 1
00000001413eda7a  4909db                   or       r11, rbx
00000001413eda7d  0f57c9                   xorps    xmm1, xmm1
00000001413eda80  f3490f2acb               cvtsi2ss xmm1, r11
00000001413eda85  f30f58c9                 addss    xmm1, xmm1
00000001413eda89  0f298d10010000           movaps   xmmword ptr [rbp + 0x110], xmm1
00000001413eda90  664d0f7ee3               movq     r11, xmm12
00000001413eda95  4d85db                   test     r11, r11
00000001413eda98  78b2                     js       0x1413eda4c
00000001413eda9a  0f57c9                   xorps    xmm1, xmm1
00000001413eda9d  f3490f2acb               cvtsi2ss xmm1, r11
00000001413edaa2  0f298dd0000000           movaps   xmmword ptr [rbp + 0xd0], xmm1
00000001413edaa9  66410f70ccee             pshufd   xmm1, xmm12, 0xee
00000001413edaaf  66490f7ecb               movq     r11, xmm1
00000001413edab4  4d85db                   test     r11, r11
00000001413edab7  7817                     js       0x1413edad0
00000001413edab9  0f57c9                   xorps    xmm1, xmm1
00000001413edabc  f3490f2acb               cvtsi2ss xmm1, r11
00000001413edac1  eb26                     jmp      0x1413edae9
00000001413edac3  666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001413edad0  4c89db                   mov      rbx, r11
00000001413edad3  48d1eb                   shr      rbx, 1
00000001413edad6  4183e301                 and      r11d, 1
00000001413edada  4909db                   or       r11, rbx
00000001413edadd  0f57c9                   xorps    xmm1, xmm1
00000001413edae0  f3490f2acb               cvtsi2ss xmm1, r11
00000001413edae5  f30f58c9                 addss    xmm1, xmm1
00000001413edae9  0f298de0000000           movaps   xmmword ptr [rbp + 0xe0], xmm1
00000001413edaf0  660f6f8d00010000         movdqa   xmm1, xmmword ptr [rbp + 0x100]
00000001413edaf8  66490f7ecb               movq     r11, xmm1
00000001413edafd  4d85db                   test     r11, r11
00000001413edb00  785e                     js       0x1413edb60
00000001413edb02  0f57c9                   xorps    xmm1, xmm1
00000001413edb05  f3490f2acb               cvtsi2ss xmm1, r11
00000001413edb0a  660f709500010000ee       pshufd   xmm2, xmmword ptr [rbp + 0x100], 0xee
00000001413edb13  66490f7ed3               movq     r11, xmm2
00000001413edb18  4d85db                   test     r11, r11
00000001413edb1b  796f                     jns      0x1413edb8c
00000001413edb1d  4c89db                   mov      rbx, r11
00000001413edb20  48d1eb                   shr      rbx, 1
00000001413edb23  4183e301                 and      r11d, 1
00000001413edb27  4909db                   or       r11, rbx
00000001413edb2a  0f57d2                   xorps    xmm2, xmm2
00000001413edb2d  f3490f2ad3               cvtsi2ss xmm2, r11
00000001413edb32  f30f58d2                 addss    xmm2, xmm2
00000001413edb36  0f2995f0000000           movaps   xmmword ptr [rbp + 0xf0], xmm2
00000001413edb3d  66490f7ec3               movq     r11, xmm0
00000001413edb42  4d85db                   test     r11, r11
00000001413edb45  795e                     jns      0x1413edba5
00000001413edb47  4c89db                   mov      rbx, r11
00000001413edb4a  48d1eb                   shr      rbx, 1
00000001413edb4d  4183e301                 and      r11d, 1
00000001413edb51  4909db                   or       r11, rbx
00000001413edb54  f34d0f2afb               cvtsi2ss xmm15, r11
00000001413edb59  f3450f58ff               addss    xmm15, xmm15
00000001413edb5e  eb4a                     jmp      0x1413edbaa
00000001413edb60  4c89db                   mov      rbx, r11
00000001413edb63  48d1eb                   shr      rbx, 1
00000001413edb66  4183e301                 and      r11d, 1
00000001413edb6a  4909db                   or       r11, rbx
00000001413edb6d  0f57c9                   xorps    xmm1, xmm1
00000001413edb70  f3490f2acb               cvtsi2ss xmm1, r11
00000001413edb75  f30f58c9                 addss    xmm1, xmm1
00000001413edb79  660f709500010000ee       pshufd   xmm2, xmmword ptr [rbp + 0x100], 0xee
00000001413edb82  66490f7ed3               movq     r11, xmm2
00000001413edb87  4d85db                   test     r11, r11
00000001413edb8a  7891                     js       0x1413edb1d
00000001413edb8c  0f57d2                   xorps    xmm2, xmm2
00000001413edb8f  f3490f2ad3               cvtsi2ss xmm2, r11
00000001413edb94  0f2995f0000000           movaps   xmmword ptr [rbp + 0xf0], xmm2
00000001413edb9b  66490f7ec3               movq     r11, xmm0
00000001413edba0  4d85db                   test     r11, r11
00000001413edba3  78a2                     js       0x1413edb47
00000001413edba5  f34d0f2afb               cvtsi2ss xmm15, r11
00000001413edbaa  66410f6ff5               movdqa   xmm6, xmm13
00000001413edbaf  660f70d0ee               pshufd   xmm2, xmm0, 0xee
00000001413edbb4  66490f7ed3               movq     r11, xmm2
00000001413edbb9  4d85db                   test     r11, r11
00000001413edbbc  0f881e010000             js       0x1413edce0
00000001413edbc2  450f57ed                 xorps    xmm13, xmm13
00000001413edbc6  f34d0f2aeb               cvtsi2ss xmm13, r11
00000001413edbcb  660f6f9540010000         movdqa   xmm2, xmmword ptr [rbp + 0x140]
00000001413edbd3  66490f7ed3               movq     r11, xmm2
00000001413edbd8  4d85db                   test     r11, r11
00000001413edbdb  0f8930010000             jns      0x1413edd11
00000001413edbe1  4c89db                   mov      rbx, r11
00000001413edbe4  48d1eb                   shr      rbx, 1
00000001413edbe7  4183e301                 and      r11d, 1
00000001413edbeb  4909db                   or       r11, rbx
00000001413edbee  f34d0f2ac3               cvtsi2ss xmm8, r11
00000001413edbf3  f3450f58c0               addss    xmm8, xmm8
00000001413edbf8  660f709540010000ee       pshufd   xmm2, xmmword ptr [rbp + 0x140], 0xee
00000001413edc01  66490f7ed3               movq     r11, xmm2
00000001413edc06  4d85db                   test     r11, r11
00000001413edc09  0f891e010000             jns      0x1413edd2d
00000001413edc0f  4c89db                   mov      rbx, r11
00000001413edc12  48d1eb                   shr      rbx, 1
00000001413edc15  4183e301                 and      r11d, 1
00000001413edc19  4909db                   or       r11, rbx
00000001413edc1c  0f57d2                   xorps    xmm2, xmm2
00000001413edc1f  f3490f2ad3               cvtsi2ss xmm2, r11
00000001413edc24  f30f58d2                 addss    xmm2, xmm2
00000001413edc28  664d0f7edb               movq     r11, xmm11
00000001413edc2d  4d85db                   test     r11, r11
00000001413edc30  0f890d010000             jns      0x1413edd43
00000001413edc36  4c89db                   mov      rbx, r11
00000001413edc39  48d1eb                   shr      rbx, 1
00000001413edc3c  4183e301                 and      r11d, 1
00000001413edc40  4909db                   or       r11, rbx
00000001413edc43  f3490f2aeb               cvtsi2ss xmm5, r11
00000001413edc48  f30f58ed                 addss    xmm5, xmm5
00000001413edc4c  66410f70e3ee             pshufd   xmm4, xmm11, 0xee
00000001413edc52  66490f7ee3               movq     r11, xmm4
00000001413edc57  4d85db                   test     r11, r11
00000001413edc5a  0f89fc000000             jns      0x1413edd5c
00000001413edc60  4c89db                   mov      rbx, r11
00000001413edc63  48d1eb                   shr      rbx, 1
00000001413edc66  4183e301                 and      r11d, 1
00000001413edc6a  4909db                   or       r11, rbx
00000001413edc6d  f3490f2afb               cvtsi2ss xmm7, r11
00000001413edc72  f30f58ff                 addss    xmm7, xmm7
00000001413edc76  664d0f7ecb               movq     r11, xmm9
00000001413edc7b  4d85db                   test     r11, r11
00000001413edc7e  0f89eb000000             jns      0x1413edd6f
00000001413edc84  4c89db                   mov      rbx, r11
00000001413edc87  48d1eb                   shr      rbx, 1
00000001413edc8a  4183e301                 and      r11d, 1
00000001413edc8e  4909db                   or       r11, rbx
00000001413edc91  0f57e4                   xorps    xmm4, xmm4
00000001413edc94  f3490f2ae3               cvtsi2ss xmm4, r11
00000001413edc99  f30f58e4                 addss    xmm4, xmm4
00000001413edc9d  66450f70d1ee             pshufd   xmm10, xmm9, 0xee
00000001413edca3  664d0f7ed3               movq     r11, xmm10
00000001413edca8  4d85db                   test     r11, r11
00000001413edcab  0f89da000000             jns      0x1413edd8b
00000001413edcb1  4c89db                   mov      rbx, r11
00000001413edcb4  48d1eb                   shr      rbx, 1
00000001413edcb7  4183e301                 and      r11d, 1
00000001413edcbb  4909db                   or       r11, rbx
00000001413edcbe  450f57d2                 xorps    xmm10, xmm10
00000001413edcc2  f34d0f2ad3               cvtsi2ss xmm10, r11
00000001413edcc7  f3450f58d2               addss    xmm10, xmm10
00000001413edccc  e9c3000000               jmp      0x1413edd94
00000001413edcd1  6666666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001413edce0  4c89db                   mov      rbx, r11
00000001413edce3  48d1eb                   shr      rbx, 1
00000001413edce6  4183e301                 and      r11d, 1
00000001413edcea  4909db                   or       r11, rbx
00000001413edced  450f57ed                 xorps    xmm13, xmm13
00000001413edcf1  f34d0f2aeb               cvtsi2ss xmm13, r11
00000001413edcf6  f3450f58ed               addss    xmm13, xmm13
00000001413edcfb  660f6f9540010000         movdqa   xmm2, xmmword ptr [rbp + 0x140]
00000001413edd03  66490f7ed3               movq     r11, xmm2
00000001413edd08  4d85db                   test     r11, r11
00000001413edd0b  0f88d0feffff             js       0x1413edbe1
00000001413edd11  f34d0f2ac3               cvtsi2ss xmm8, r11
00000001413edd16  660f709540010000ee       pshufd   xmm2, xmmword ptr [rbp + 0x140], 0xee
00000001413edd1f  66490f7ed3               movq     r11, xmm2
00000001413edd24  4d85db                   test     r11, r11
00000001413edd27  0f88e2feffff             js       0x1413edc0f
00000001413edd2d  0f57d2                   xorps    xmm2, xmm2
00000001413edd30  f3490f2ad3               cvtsi2ss xmm2, r11
00000001413edd35  664d0f7edb               movq     r11, xmm11
00000001413edd3a  4d85db                   test     r11, r11
00000001413edd3d  0f88f3feffff             js       0x1413edc36
00000001413edd43  f3490f2aeb               cvtsi2ss xmm5, r11
00000001413edd48  66410f70e3ee             pshufd   xmm4, xmm11, 0xee
00000001413edd4e  66490f7ee3               movq     r11, xmm4
00000001413edd53  4d85db                   test     r11, r11
00000001413edd56  0f8804ffffff             js       0x1413edc60
00000001413edd5c  f3490f2afb               cvtsi2ss xmm7, r11
00000001413edd61  664d0f7ecb               movq     r11, xmm9
00000001413edd66  4d85db                   test     r11, r11
00000001413edd69  0f8815ffffff             js       0x1413edc84
00000001413edd6f  0f57e4                   xorps    xmm4, xmm4
00000001413edd72  f3490f2ae3               cvtsi2ss xmm4, r11
00000001413edd77  66450f70d1ee             pshufd   xmm10, xmm9, 0xee
00000001413edd7d  664d0f7ed3               movq     r11, xmm10
00000001413edd82  4d85db                   test     r11, r11
00000001413edd85  0f8826ffffff             js       0x1413edcb1
00000001413edd8b  450f57d2                 xorps    xmm10, xmm10
00000001413edd8f  f34d0f2ad3               cvtsi2ss xmm10, r11
00000001413edd94  66440f7f5d40             movdqa   xmmword ptr [rbp + 0x40], xmm11
00000001413edd9a  664d0f7ef3               movq     r11, xmm14
00000001413edd9f  4d85db                   test     r11, r11
00000001413edda2  66440f7f4d30             movdqa   xmmword ptr [rbp + 0x30], xmm9
00000001413edda8  660f7f7550               movdqa   xmmword ptr [rbp + 0x50], xmm6
00000001413eddad  66440f7f6560             movdqa   xmmword ptr [rbp + 0x60], xmm12
00000001413eddb3  780b                     js       0x1413eddc0
00000001413eddb5  f34d0f2adb               cvtsi2ss xmm11, r11
00000001413eddba  eb1b                     jmp      0x1413eddd7
00000001413eddbc  0f1f4000                 nop      dword ptr [rax]
00000001413eddc0  4c89db                   mov      rbx, r11
00000001413eddc3  48d1eb                   shr      rbx, 1
00000001413eddc6  4183e301                 and      r11d, 1
00000001413eddca  4909db                   or       r11, rbx
00000001413eddcd  f34d0f2adb               cvtsi2ss xmm11, r11
00000001413eddd2  f3450f58db               addss    xmm11, xmm11
00000001413eddd7  66440f6fc8               movdqa   xmm9, xmm0
00000001413edddc  66410f6ff6               movdqa   xmm6, xmm14
00000001413edde1  66450f70e6ee             pshufd   xmm12, xmm14, 0xee
00000001413edde7  664d0f7ee3               movq     r11, xmm12
00000001413eddec  4d85db                   test     r11, r11
00000001413eddef  781f                     js       0x1413ede10
00000001413eddf1  0f288540010000           movaps   xmm0, xmmword ptr [rbp + 0x140]
00000001413eddf8  450f57e4                 xorps    xmm12, xmm12
00000001413eddfc  f34d0f2ae3               cvtsi2ss xmm12, r11
00000001413ede01  eb2f                     jmp      0x1413ede32
00000001413ede03  666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001413ede10  0f288540010000           movaps   xmm0, xmmword ptr [rbp + 0x140]
00000001413ede17  4c89db                   mov      rbx, r11
00000001413ede1a  48d1eb                   shr      rbx, 1
00000001413ede1d  4183e301                 and      r11d, 1
00000001413ede21  4909db                   or       r11, rbx
00000001413ede24  450f57e4                 xorps    xmm12, xmm12
00000001413ede28  f34d0f2ae3               cvtsi2ss xmm12, r11
00000001413ede2d  f3450f58e4               addss    xmm12, xmm12
00000001413ede32  0f298540010000           movaps   xmmword ptr [rbp + 0x140], xmm0
00000001413ede39  450f14dc                 unpcklps xmm11, xmm12
00000001413ede3d  0f149d10010000           unpcklps xmm3, xmmword ptr [rbp + 0x110]
00000001413ede44  0f2885d0000000           movaps   xmm0, xmmword ptr [rbp + 0xd0]
00000001413ede4b  0f1485e0000000           unpcklps xmm0, xmmword ptr [rbp + 0xe0]
00000001413ede52  0f16d8                   movlhps  xmm3, xmm0
00000001413ede55  0f148df0000000           unpcklps xmm1, xmmword ptr [rbp + 0xf0]
00000001413ede5c  450f14fd                 unpcklps xmm15, xmm13
00000001413ede60  410f16cf                 movlhps  xmm1, xmm15
00000001413ede64  440f14c2                 unpcklps xmm8, xmm2
00000001413ede68  0f14ef                   unpcklps xmm5, xmm7
00000001413ede6b  440f16c5                 movlhps  xmm8, xmm5
00000001413ede6f  410f14e2                 unpcklps xmm4, xmm10
00000001413ede73  410f16e3                 movlhps  xmm4, xmm11
00000001413ede77  0f289580000000           movaps   xmm2, xmmword ptr [rbp + 0x80]
00000001413ede7e  0f59e2                   mulps    xmm4, xmm2
00000001413ede81  440f59c2                 mulps    xmm8, xmm2
00000001413ede85  0f59ca                   mulps    xmm1, xmm2
00000001413ede88  0f59da                   mulps    xmm3, xmm2
00000001413ede8b  0f285570                 movaps   xmm2, xmmword ptr [rbp + 0x70]
00000001413ede8f  0f58da                   addps    xmm3, xmm2
00000001413ede92  0f58ca                   addps    xmm1, xmm2
00000001413ede95  440f58c2                 addps    xmm8, xmm2
00000001413ede99  0f58e2                   addps    xmm4, xmm2
00000001413ede9c  440f28bd90000000         movaps   xmm15, xmmword ptr [rbp + 0x90]
00000001413edea4  410f28d7                 movaps   xmm2, xmm15
00000001413edea8  0f58d4                   addps    xmm2, xmm4
00000001413edeab  0f28c3                   movaps   xmm0, xmm3
00000001413edeae  410f28df                 movaps   xmm3, xmm15
00000001413edeb2  410f58d8                 addps    xmm3, xmm8
00000001413edeb6  410f28ff                 movaps   xmm7, xmm15
00000001413edeba  0f58f9                   addps    xmm7, xmm1
00000001413edebd  440f58f8                 addps    xmm15, xmm0
00000001413edec1  450f28df                 movaps   xmm11, xmm15
00000001413edec5  0f298510010000           movaps   xmmword ptr [rbp + 0x110], xmm0
00000001413edecc  440f5cd8                 subps    xmm11, xmm0
00000001413eded0  440f28e7                 movaps   xmm12, xmm7
00000001413eded4  440f5ce1                 subps    xmm12, xmm1
00000001413eded8  0f28eb                   movaps   xmm5, xmm3
00000001413ededb  410f5ce8                 subps    xmm5, xmm8
00000001413ededf  440f2835895ac501         movaps   xmm14, xmmword ptr [rip + 0x1c55a89]
00000001413edee7  450f28d6                 movaps   xmm10, xmm14
00000001413edeeb  450fc2d302               cmpleps  xmm10, xmm11
00000001413edef0  450f28de                 movaps   xmm11, xmm14
00000001413edef4  450fc2dc02               cmpleps  xmm11, xmm12
00000001413edef9  440f28e2                 movaps   xmm12, xmm2
00000001413edefd  440f5ce4                 subps    xmm12, xmm4
00000001413edf01  66450f6bd3               packssdw xmm10, xmm11
00000001413edf06  450f28de                 movaps   xmm11, xmm14
00000001413edf0a  440fc2dd02               cmpleps  xmm11, xmm5
00000001413edf0f  450fc2f402               cmpleps  xmm14, xmm12
00000001413edf14  66450f6bde               packssdw xmm11, xmm14
00000001413edf19  66450f63d3               packsswb xmm10, xmm11
00000001413edf1e  66450fd7da               pmovmskb r11d, xmm10
00000001413edf23  4883c1f0                 add      rcx, -0x10
00000001413edf27  4585db                   test     r11d, r11d
00000001413edf2a  660f6fc6                 movdqa   xmm0, xmm6
00000001413edf2e  660f6f7530               movdqa   xmm6, xmmword ptr [rbp + 0x30]
00000001413edf33  66440f6f5d40             movdqa   xmm11, xmmword ptr [rbp + 0x40]
00000001413edf39  66440f6f6d50             movdqa   xmm13, xmmword ptr [rbp + 0x50]
00000001413edf3f  66440f6f6560             movdqa   xmm12, xmmword ptr [rbp + 0x60]
00000001413edf45  756f                     jne      0x1413edfb6
00000001413edf47  660f6f2da198c101         movdqa   xmm5, xmmword ptr [rip + 0x1c198a1]
00000001413edf4f  66440fd4ed               paddq    xmm13, xmm5
00000001413edf54  66440fd4e5               paddq    xmm12, xmm5
00000001413edf59  66450f6ff4               movdqa   xmm14, xmm12
00000001413edf5e  66440f6fa500010000       movdqa   xmm12, xmmword ptr [rbp + 0x100]
00000001413edf67  66440fd4e5               paddq    xmm12, xmm5
00000001413edf6c  66440f7fa500010000       movdqa   xmmword ptr [rbp + 0x100], xmm12
00000001413edf75  66450f6fe6               movdqa   xmm12, xmm14
00000001413edf7a  66440fd4cd               paddq    xmm9, xmm5
00000001413edf7f  66440f6fb540010000       movdqa   xmm14, xmmword ptr [rbp + 0x140]
00000001413edf88  66440fd4f5               paddq    xmm14, xmm5
00000001413edf8d  66440f7fb540010000       movdqa   xmmword ptr [rbp + 0x140], xmm14
00000001413edf96  66440f6ff0               movdqa   xmm14, xmm0
00000001413edf9b  66440fd4dd               paddq    xmm11, xmm5
00000001413edfa0  660fd4f5                 paddq    xmm6, xmm5
00000001413edfa4  66440fd4f5               paddq    xmm14, xmm5
00000001413edfa9  4d85d2                   test     r10, r10
00000001413edfac  4d8d52f0                 lea      r10, [r10 - 0x10]
00000001413edfb0  0f852afaffff             jne      0x1413ed9e0
00000001413edfb6  664585db                 test     r11w, r11w
00000001413edfba  0f845b010000             je       0x1413ee11b
00000001413edfc0  66440fdb15b79eba01       pand     xmm10, xmmword ptr [rip + 0x1ba9eb7]
00000001413edfc9  66440f7f9550010000       movdqa   xmmword ptr [rbp + 0x150], xmm10
00000001413edfd2  0fb69551010000           movzx    edx, byte ptr [rbp + 0x151]
00000001413edfd9  448b8550010000           mov      r8d, dword ptr [rbp + 0x150]
00000001413edfe0  4138d0                   cmp      r8b, dl
00000001413edfe3  410f47d0                 cmova    edx, r8d
00000001413edfe7  448b8554010000           mov      r8d, dword ptr [rbp + 0x154]
00000001413edfee  440fb68d52010000         movzx    r9d, byte ptr [rbp + 0x152]
00000001413edff6  4438ca                   cmp      dl, r9b
00000001413edff9  410f46d1                 cmovbe   edx, r9d
00000001413edffd  440fb68d53010000         movzx    r9d, byte ptr [rbp + 0x153]
00000001413ee005  4438ca                   cmp      dl, r9b
00000001413ee008  410f46d1                 cmovbe   edx, r9d
00000001413ee00c  4438c2                   cmp      dl, r8b
00000001413ee00f  410f46d0                 cmovbe   edx, r8d
00000001413ee013  440fb68555010000         movzx    r8d, byte ptr [rbp + 0x155]
00000001413ee01b  4438c2                   cmp      dl, r8b
00000001413ee01e  410f46d0                 cmovbe   edx, r8d
00000001413ee022  440fb68556010000         movzx    r8d, byte ptr [rbp + 0x156]
00000001413ee02a  4438c2                   cmp      dl, r8b
00000001413ee02d  410f46d0                 cmovbe   edx, r8d
00000001413ee031  440fb68557010000         movzx    r8d, byte ptr [rbp + 0x157]
00000001413ee039  4438c2                   cmp      dl, r8b
00000001413ee03c  410f46d0                 cmovbe   edx, r8d
00000001413ee040  448b8558010000           mov      r8d, dword ptr [rbp + 0x158]
00000001413ee047  4438c2                   cmp      dl, r8b
00000001413ee04a  410f46d0                 cmovbe   edx, r8d
00000001413ee04e  440fb68559010000         movzx    r8d, byte ptr [rbp + 0x159]
00000001413ee056  4438c2                   cmp      dl, r8b
00000001413ee059  410f46d0                 cmovbe   edx, r8d
00000001413ee05d  440fb6855a010000         movzx    r8d, byte ptr [rbp + 0x15a]
00000001413ee065  4438c2                   cmp      dl, r8b
00000001413ee068  410f46d0                 cmovbe   edx, r8d
00000001413ee06c  440fb6855b010000         movzx    r8d, byte ptr [rbp + 0x15b]
00000001413ee074  4438c2                   cmp      dl, r8b
00000001413ee077  410f46d0                 cmovbe   edx, r8d
00000001413ee07b  448b855c010000           mov      r8d, dword ptr [rbp + 0x15c]
00000001413ee082  4438c2                   cmp      dl, r8b
00000001413ee085  410f46d0                 cmovbe   edx, r8d
00000001413ee089  440fb6855d010000         movzx    r8d, byte ptr [rbp + 0x15d]
00000001413ee091  4438c2                   cmp      dl, r8b
00000001413ee094  410f46d0                 cmovbe   edx, r8d
00000001413ee098  440fb6855e010000         movzx    r8d, byte ptr [rbp + 0x15e]
00000001413ee0a0  4438c2                   cmp      dl, r8b
00000001413ee0a3  410f46d0                 cmovbe   edx, r8d
00000001413ee0a7  440fb6855f010000         movzx    r8d, byte ptr [rbp + 0x15f]
00000001413ee0af  4438c2                   cmp      dl, r8b
00000001413ee0b2  410f46d0                 cmovbe   edx, r8d
00000001413ee0b6  41b010                   mov      r8b, 0x10
00000001413ee0b9  4128d0                   sub      r8b, dl
00000001413ee0bc  410fb6d8                 movzx    ebx, r8b
00000001413ee0c0  89da                     mov      edx, ebx
00000001413ee0c2  83e20f                   and      edx, 0xf
00000001413ee0c5  c1e202                   shl      edx, 2
00000001413ee0c8  0f288510010000           movaps   xmm0, xmmword ptr [rbp + 0x110]
00000001413ee0cf  0f2945b0                 movaps   xmmword ptr [rbp - 0x50], xmm0
00000001413ee0d3  0f294dc0                 movaps   xmmword ptr [rbp - 0x40], xmm1
00000001413ee0d7  440f2945d0               movaps   xmmword ptr [rbp - 0x30], xmm8
00000001413ee0dc  0f2965e0                 movaps   xmmword ptr [rbp - 0x20], xmm4
00000001413ee0e0  f30f107415b0             movss    xmm6, dword ptr [rbp + rdx - 0x50]
00000001413ee0e6  440f297df0               movaps   xmmword ptr [rbp - 0x10], xmm15
00000001413ee0eb  0f297d00                 movaps   xmmword ptr [rbp], xmm7
00000001413ee0ef  0f295d10                 movaps   xmmword ptr [rbp + 0x10], xmm3
00000001413ee0f3  0f295520                 movaps   xmmword ptr [rbp + 0x20], xmm2
00000001413ee0f7  f30f107c15f0             movss    xmm7, dword ptr [rbp + rdx - 0x10]
00000001413ee0fd  4829cb                   sub      rbx, rcx
00000001413ee100  f3440f1005cb99a401       movss    xmm8, dword ptr [rip + 0x1a499cb]
00000001413ee109  483bbd28010000           cmp      rdi, qword ptr [rbp + 0x128]
00000001413ee110  0f85b1f7ffff             jne      0x1413ed8c7
00000001413ee116  e99a000000               jmp      0x1413ee1b5
00000001413ee11b  4d39c8                   cmp      r8, r9
00000001413ee11e  f3440f1005ad99a401       movss    xmm8, dword ptr [rip + 0x1a499ad]
00000001413ee127  0f288da0000000           movaps   xmm1, xmmword ptr [rbp + 0xa0]
00000001413ee12e  0f2895b0000000           movaps   xmm2, xmmword ptr [rbp + 0xb0]
00000001413ee135  0f289dc0000000           movaps   xmm3, xmmword ptr [rbp + 0xc0]
00000001413ee13c  0f849d000000             je       0x1413ee1df
00000001413ee142  66666666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001413ee150  4885d2                   test     rdx, rdx
00000001413ee153  780b                     js       0x1413ee160
00000001413ee155  0f57f6                   xorps    xmm6, xmm6
00000001413ee158  f3480f2af2               cvtsi2ss xmm6, rdx
00000001413ee15d  eb1d                     jmp      0x1413ee17c
00000001413ee15f  90                       nop      
00000001413ee160  4889d1                   mov      rcx, rdx
00000001413ee163  48d1e9                   shr      rcx, 1
00000001413ee166  4189d0                   mov      r8d, edx
00000001413ee169  4183e001                 and      r8d, 1
00000001413ee16d  4909c8                   or       r8, rcx
00000001413ee170  0f57f6                   xorps    xmm6, xmm6
00000001413ee173  f3490f2af0               cvtsi2ss xmm6, r8
00000001413ee178  f30f58f6                 addss    xmm6, xmm6
00000001413ee17c  f30f59f2                 mulss    xmm6, xmm2
00000001413ee180  f30f58f1                 addss    xmm6, xmm1
00000001413ee184  0f28fb                   movaps   xmm7, xmm3
00000001413ee187  f30f58fe                 addss    xmm7, xmm6
00000001413ee18b  0f28c7                   movaps   xmm0, xmm7
00000001413ee18e  f30f5cc6                 subss    xmm0, xmm6
00000001413ee192  410f2ec0                 ucomiss  xmm0, xmm8
00000001413ee196  730a                     jae      0x1413ee1a2
00000001413ee198  48ffc2                   inc      rdx
00000001413ee19b  4939d6                   cmp      r14, rdx
00000001413ee19e  75b0                     jne      0x1413ee150
00000001413ee1a0  eb3d                     jmp      0x1413ee1df
00000001413ee1a2  48ffc2                   inc      rdx
00000001413ee1a5  4889d3                   mov      rbx, rdx
00000001413ee1a8  483bbd28010000           cmp      rdi, qword ptr [rbp + 0x128]
00000001413ee1af  0f8512f7ffff             jne      0x1413ed8c7
00000001413ee1b5  48c744242008000000       mov      qword ptr [rsp + 0x20], 8
00000001413ee1be  41b801000000             mov      r8d, 1
00000001413ee1c4  41b904000000             mov      r9d, 4
00000001413ee1ca  488d8d28010000           lea      rcx, [rbp + 0x128]
00000001413ee1d1  4889fa                   mov      rdx, rdi
00000001413ee1d4  e8d70f9901               call     0x142d7f1b0 ; alloc::raw_vec::impl$4::reserve::do_reserve_and_handle<alloc::alloc::Global> | _ZN5alloc7raw_vec20RawVecInner$LT$A$GT$7reserve21do_reserve_and_handle17h0559268ff9d2f5acE
00000001413ee1d9  90                       nop      
00000001413ee1da  e9e1f6ffff               jmp      0x1413ed8c0
00000001413ee1df  488b8538010000           mov      rax, qword ptr [rbp + 0x138]
00000001413ee1e6  48894610                 mov      qword ptr [rsi + 0x10], rax
00000001413ee1ea  488b8528010000           mov      rax, qword ptr [rbp + 0x128]
00000001413ee1f1  488906                   mov      qword ptr [rsi], rax
00000001413ee1f4  488b8530010000           mov      rax, qword ptr [rbp + 0x130]
00000001413ee1fb  48894608                 mov      qword ptr [rsi + 8], rax
00000001413ee1ff  4889f0                   mov      rax, rsi
00000001413ee202  0f28b570010000           movaps   xmm6, xmmword ptr [rbp + 0x170]
00000001413ee209  0f28bd80010000           movaps   xmm7, xmmword ptr [rbp + 0x180]
00000001413ee210  440f288590010000         movaps   xmm8, xmmword ptr [rbp + 0x190]
00000001413ee218  440f288da0010000         movaps   xmm9, xmmword ptr [rbp + 0x1a0]
00000001413ee220  440f2895b0010000         movaps   xmm10, xmmword ptr [rbp + 0x1b0]
00000001413ee228  440f289dc0010000         movaps   xmm11, xmmword ptr [rbp + 0x1c0]
00000001413ee230  440f28a5d0010000         movaps   xmm12, xmmword ptr [rbp + 0x1d0]
00000001413ee238  440f28ade0010000         movaps   xmm13, xmmword ptr [rbp + 0x1e0]
00000001413ee240  440f28b5f0010000         movaps   xmm14, xmmword ptr [rbp + 0x1f0]
00000001413ee248  440f28bd00020000         movaps   xmm15, xmmword ptr [rbp + 0x200]
00000001413ee250  4881c498020000           add      rsp, 0x298
00000001413ee257  5b                       pop      rbx
00000001413ee258  5f                       pop      rdi
00000001413ee259  5e                       pop      rsi
00000001413ee25a  415c                     pop      r12
00000001413ee25c  415d                     pop      r13
00000001413ee25e  415e                     pop      r14
00000001413ee260  415f                     pop      r15
00000001413ee262  5d                       pop      rbp
00000001413ee263  c3                       ret      
00000001413ee264  b904000000               mov      ecx, 4
00000001413ee269  ba20000000               mov      edx, 0x20
00000001413ee26e  e8b79b9d01               call     0x142dc7e2a ; alloc::raw_vec::handle_error | _RNvNtCs1f2BdUxKfgg_5alloc7raw_vec12handle_error
00000001413ee273  cc                       int3     
00000001413ee274  6666662e0f1f840000000000 nop      word ptr cs:[rax + rax]
00000001413ee280  4889542410               mov      qword ptr [rsp + 0x10], rdx
00000001413ee285  55                       push     rbp
00000001413ee286  4157                     push     r15
00000001413ee288  4156                     push     r14
00000001413ee28a  4155                     push     r13
00000001413ee28c  4154                     push     r12
00000001413ee28e  56                       push     rsi
00000001413ee28f  57                       push     rdi
00000001413ee290  53                       push     rbx
00000001413ee291  4881ecc8000000           sub      rsp, 0xc8
00000001413ee298  488daa80000000           lea      rbp, [rdx + 0x80]
00000001413ee29f  440f297c2420             movaps   xmmword ptr [rsp + 0x20], xmm15
00000001413ee2a5  66440f7f742430           movdqa   xmmword ptr [rsp + 0x30], xmm14
00000001413ee2ac  66440f7f6c2440           movdqa   xmmword ptr [rsp + 0x40], xmm13
00000001413ee2b3  66440f7f642450           movdqa   xmmword ptr [rsp + 0x50], xmm12
00000001413ee2ba  66440f7f5c2460           movdqa   xmmword ptr [rsp + 0x60], xmm11
00000001413ee2c1  66440f7f542470           movdqa   xmmword ptr [rsp + 0x70], xmm10
00000001413ee2c8  66440f7f8c2480000000     movdqa   xmmword ptr [rsp + 0x80], xmm9
00000001413ee2d2  440f29842490000000       movaps   xmmword ptr [rsp + 0x90], xmm8
00000001413ee2db  0f29bc24a0000000         movaps   xmmword ptr [rsp + 0xa0], xmm7
00000001413ee2e3  0f29b424b0000000         movaps   xmmword ptr [rsp + 0xb0], xmm6
00000001413ee2eb  488b9528010000           mov      rdx, qword ptr [rbp + 0x128]
00000001413ee2f2  4885d2                   test     rdx, rdx
00000001413ee2f5  7416                     je       0x1413ee30d
00000001413ee2f7  488b8d30010000           mov      rcx, qword ptr [rbp + 0x130]
00000001413ee2fe  48c1e203                 shl      rdx, 3
00000001413ee302  41b804000000             mov      r8d, 4
00000001413ee308  e8b3d72bff               call     0x1406abac0 ; _RNvCsfLfy6EI15iL_7___rustc14___rust_dealloc
00000001413ee30d  0f28b424b0000000         movaps   xmm6, xmmword ptr [rsp + 0xb0]
00000001413ee315  0f28bc24a0000000         movaps   xmm7, xmmword ptr [rsp + 0xa0]
00000001413ee31d  440f28842490000000       movaps   xmm8, xmmword ptr [rsp + 0x90]
00000001413ee326  440f288c2480000000       movaps   xmm9, xmmword ptr [rsp + 0x80]
00000001413ee32f  440f28542470             movaps   xmm10, xmmword ptr [rsp + 0x70]
00000001413ee335  440f285c2460             movaps   xmm11, xmmword ptr [rsp + 0x60]
00000001413ee33b  440f28642450             movaps   xmm12, xmmword ptr [rsp + 0x50]
00000001413ee341  440f286c2440             movaps   xmm13, xmmword ptr [rsp + 0x40]
00000001413ee347  440f28742430             movaps   xmm14, xmmword ptr [rsp + 0x30]
00000001413ee34d  440f287c2420             movaps   xmm15, xmmword ptr [rsp + 0x20]
00000001413ee353  4881c4c8000000           add      rsp, 0xc8
00000001413ee35a  5b                       pop      rbx
00000001413ee35b  5f                       pop      rdi
00000001413ee35c  5e                       pop      rsi
00000001413ee35d  415c                     pop      r12
00000001413ee35f  415d                     pop      r13
00000001413ee361  415e                     pop      r14
00000001413ee363  415f                     pop      r15
00000001413ee365  5d                       pop      rbp
00000001413ee366  c3                       ret      