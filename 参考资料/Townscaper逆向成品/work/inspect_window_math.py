"""Restore Window UV modulo operands directly from original x86 bytes."""
from pathlib import Path
import hashlib,json,math,struct,sys
BASE=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(BASE/'work/pydeps'))
import pefile
from capstone import Cs,CS_ARCH_X86,CS_MODE_32
target=Path(r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll')
data=target.read_bytes();pe=pefile.PE(data=data);base=pe.OPTIONAL_HEADER.ImageBase
md=Cs(CS_ARCH_X86,CS_MODE_32)
def decode(start,end):
    return list(md.disasm(data[pe.get_offset_from_rva(start):pe.get_offset_from_rva(end)],base+start))
def record(i):return {'va':hex(i.address),'bytes':i.bytes.hex(),'text':i.mnemonic+' '+i.op_str}
ins=decode(0x3f6be0,0x3f6fc8);sites=[]
for n,i in enumerate(ins):
    if i.mnemonic=='call' and i.op_str=='0x10195ff0':
        assert ins[n-1].mnemonic=='fld1'
        assert ins[n-2].mnemonic=='fld' and 'qword ptr' in ins[n-2].op_str
        sites.append({'call_va':hex(i.address),'coordinate':'x' if not sites else'y','x87_stack_before_call':['ST0=1 (divisor)','ST1=float64(abs(current UV coordinate)) (dividend)'],'instructions':[record(k)for k in ins[n-10:n+15]]})
assert [s['call_va']for s in sites]==['0x103f6db5','0x103f6e15']
mask=data[pe.get_offset_from_rva(0x11d2720):pe.get_offset_from_rva(0x11d2720)+16]
assert mask==struct.pack('<4I',*[0x7fffffff]*4)
zero=data[pe.get_offset_from_rva(0x11d26e4):pe.get_offset_from_rva(0x11d26e4)+4];assert zero==b'\0'*4
fallback=decode(0x196000,0x19600e);assert fallback[0].mnemonic=='fxch' and fallback[1].mnemonic=='fprem'
off=pe.get_offset_from_rva(0x13cf4d0);table=data[off:off+24];assert struct.unpack_from('<I',table,16)[0]==base+0x196000
sign=decode(0xa44440,0xa44464)
assert any(i.mnemonic=='jae' and i.op_str=='0x10a4445f' for i in sign)
def f32(v):return struct.unpack('<f',struct.pack('<f',v))[0]
def update(v,offset):
    # Original first converts abs(float32) to double for fmod, returns to float32,
    # then adds float32 offset and multiplies by x87 +/-1 with float32 store.
    r=f32(math.fmod(abs(v),1.0));summed=f32(r+f32(offset))
    return f32((1.0 if v>=0.0 else-1.0)*summed)
def trace(x,y):
    uv=(f32(x),f32(y));out=[{'color':0,'variant':0,'uv':list(uv),'source_mesh':True}]
    for color in range(15):
        for variant in range(1 if color==0 else 0,4):
            uv=(update(uv[0],color),update(uv[1],variant))
            out.append({'color':color,'variant':variant,'uv':list(uv),'uv_bits':[hex(struct.unpack('<I',struct.pack('<f',v))[0])for v in uv]})
    assert len(out)==60
    return out
ordinary=trace(-2.25,3.625);integers=trace(-2.0,-3.0)
assert ordinary[1]['uv']==[-0.25,1.625] and ordinary[4]['uv']==[-1.25,0.625]
assert integers[1]['uv_bits']==['0x80000000','0xbf800000']
assert integers[2]['uv_bits'][0]=='0x0' and integers[4]['uv_bits'][1]=='0x80000000'
result={'source':str(target),'sha256':hashlib.sha256(data).hexdigest(),'image_base':hex(base),'provenance':'Independent raw-byte / Capstone verification; not new REA Evidence','function_rva':'0x3f6be0','modulo_calls':sites,'abs_sign_mask':{'va':'0x111d2720','bytes':mask.hex()},'sign_comparison_zero':{'va':'0x111d26e4','bytes':zero.hex()},'fmod_dispatch':{'va':'0x113cf4d0','bytes':table.hex(),'fallback_va':'0x10196000','instructions':[record(i)for i in fallback]},'mathf_sign':{'va':'0x10a44440','instructions':[record(i)for i in sign],'finite_semantics':'Sign(v)=+1 if v>=0, else -1; +0 and -0 both yield +1. Unordered/NaN falls through the -1 branch.'},'uv_formula':{'x':'UVx_next = float32(Sign(UVx_current) * float32(float32(fmod(float64(abs(UVx_current)), 1.0)) + float32(color)))','y':'UVy_next = float32(Sign(UVy_current) * float32(float32(fmod(float64(abs(UVy_current)), 1.0)) + float32(variant)))','divisor_x':1.0,'divisor_y':1.0,'offsets':'color=0..14; variant=0..3; first transformed pair is color0/variant1, then 0/2,0/3,1/0,...,14/3. The list is mutated in place and each next pair reads the previous rewritten UV.','ordinary_closed_form':'For fractions that survive float32 addition unchanged and signs that do not encounter zero: UVx=Sign(originalX)*(frac(abs(originalX))+color), UVy=Sign(originalY)*(frac(abs(originalY))+variant). Use the recurrence for exact reconstruction.','signed_zero_exception':'Negative integer originalX produces -0 at color0/variant1; Mathf.Sign(-0)=+1 changes the next X to +0, and later color offsets become positive. Negative integer Y reaches -0 at color1/variant0; later variants become positive. Float32 offset addition can also round small/near-one fractions to integers; the next in-place modulo then uses that rounded value.'},'cache':{'meshes_per_source':60,'original_source_retained_at_color0_variant0':True,'new_clones_per_source':59,'index':'(sourceListIndex / 60 * 15 + voxelType) * 4 + CSharpSignedRemainder(seed,4)','instructions':[record(i)for i in ins if 0x103f6f14<=i.address<=0x103f6fa0]},'numeric_examples':{'ordinary_negative_fraction':{'input':[-2.25,3.625],'first_pairs':ordinary[:9]},'negative_integer_signed_zero':{'input':[-2.0,-3.0],'first_pairs':integers[:9]}},'limits':['Static original-code formula recovery and deterministic reference traces, not a runtime window mesh observation. Preserve in-place mutation, original color0/variant0 source mesh, float32 storage and signed remainder.']}
(BASE/'outputs/townscaper_window_math.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(json.dumps({'modulo_sites':len(sites),'divisors':[1,1],'meshes_per_source':60,'new_clones':59,'reference_traces':2,'source_sha256':result['sha256']}))
