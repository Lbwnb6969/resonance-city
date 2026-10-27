// Concatenate before runtime_probe.js, then dispatch from perform(task):
// if(task.kind.startsWith('grid')) return performGridTask(task);
// Uses runtime_layouts.json verified x86 layouts; run only on queued Unity main thread.
function performGridTask(task) {
  if(Process.pointerSize!==4)throw new Error('Townscaper grid layouts require x86');
  const grid=world.add(0x10).readPointer(),graph=world.add(0x18).readPointer();
  function list(p,stride,reader){if(p.isNull())return [];const n=p.add(0xc).readS32(),a=p.add(8).readPointer().add(0x10),out=[];for(let i=0;i<n;i++)out.push(reader(a.add(i*stride),i));return out;}
  function hex(p){return [p.readS32(),p.add(4).readS32()];}
  function floats(p,n){const a=[];for(let i=0;i<n;i++)a.push(p.add(i*4).readFloat());return a;}
  function unbox(p){if(p.isNull())throw new Error('null boxed result');return api('il2cpp_object_unbox','pointer',['pointer'])(p);}
  const domain=api('il2cpp_domain_get','pointer',[])();
  const assembly=api('il2cpp_domain_assembly_open','pointer',['pointer','pointer'])(domain,Memory.allocUtf8String('Assembly-CSharp'));
  const image=api('il2cpp_assembly_get_image','pointer',['pointer'])(assembly);
  function type(ns,name){const cls=api('il2cpp_class_from_name','pointer',['pointer','pointer','pointer'])(image,Memory.allocUtf8String(ns),Memory.allocUtf8String(name));return api('il2cpp_type_get_object','pointer',['pointer'])(api('il2cpp_class_get_type','pointer',['pointer'])(cls));}
  if(task.kind==='gridmath') {
    // class_get_method_from_name cannot distinguish four one-argument overloads.
    const cls=api('il2cpp_object_get_class','pointer',['pointer'])(grid),it=Memory.alloc(4);it.writePointer(ptr(0));let selected=null;
    while(true){const m=api('il2cpp_class_get_methods','pointer',['pointer','pointer'])(cls,it);if(m.isNull())break;
      if(api('il2cpp_method_get_name','pointer',['pointer'])(m).readUtf8String()!=='HexToPlane'||api('il2cpp_method_get_param_count','uint',['pointer'])(m)!==1)continue;
      const t=api('il2cpp_method_get_param','pointer',['pointer','uint'])(m,0),s=api('il2cpp_type_get_name','pointer',['pointer'])(t),name=s.readUtf8String();api('il2cpp_free','void',['pointer'])(s);
      if(name==='Unity.Mathematics.int2'){selected=m;break;}
    }
    if(!selected)throw new Error('HexToPlane(int2) overload not found');
    const result=[];
    for(const h of (task.points||[[0,0],[9,0],[0,9],[72,-36]])){
      const value=Memory.alloc(8);value.writeS32(h[0]);value.add(4).writeS32(h[1]);const args=Memory.alloc(4);args.writePointer(value);const ex=Memory.alloc(4);ex.writePointer(ptr(0));
      const box=api('il2cpp_runtime_invoke','pointer',['pointer','pointer','pointer','pointer'])(selected,ptr(0),args,ex);if(!ex.readPointer().isNull())throw new Error('HexToPlane managed exception');
      const p=unbox(box);result.push({hex:h,plane:floats(p,2),floatBits:[p.readU32().toString(16),p.add(4).readU32().toString(16)]});
    }
    const mathCls=api('il2cpp_class_from_name','pointer',['pointer','pointer','pointer'])(image,Memory.allocUtf8String('Placemaker'),Memory.allocUtf8String('ModuleMath'));
    const field=api('il2cpp_class_get_field_from_name','pointer',['pointer','pointer'])(mathCls,Memory.allocUtf8String('baryVectors')),value=Memory.alloc(4);
    api('il2cpp_field_static_get_value','void',['pointer','pointer'])(field,value);const a=value.readPointer();
    const baryVectors=[];for(let i=0;i<6;i++)baryVectors.push(floats(a.add(0x10+i*8),2));
    return {rva:'0xe13c00',overload:'Unity.Mathematics.int2',result,baryVectors};
  }
  if(task.kind==='gridbits'){
    const records=list(grid.add(0x18).readPointer(),4,p=>{const b=p.readPointer();return {pointer:b.toString(),hex:hex(b.add(0xc)),motivations:b.add(0x14).readU8(),relaxationSteps:b.add(0x15).readU8(),clusterCount:b.add(0x16).readU8(),patchDone:b.add(0x17).readU8(),state:b.add(0x18).readU8(),verts:list(b.add(0x1c).readPointer(),8,p=>floats(p,2))};});
    const clusters=list(grid.add(0x28).readPointer(),4,p=>{const c=p.readPointer();return {pointer:c.toString(),hex:hex(c.add(8)),relaxationSteps:c.add(0x11).readU8(),done:c.add(0x13).readU8(),patchVertOffsets:[c.add(0x14).readS32(),c.add(0x18).readS32(),c.add(0x1c).readS32()],vertIndexes:list(c.add(0x20).readPointer(),2,p=>p.readS16()),relaxedVerts:list(c.add(0x24).readPointer(),8,p=>floats(p,2))};}).filter(c=>[[72,-72],[0,-72],[-72,0],[-72,72],[0,72],[72,0]].some(h=>h[0]===c.hex[0]&&h[1]===c.hex[1]));
    return {state:world.add(0xbe).readU8(),grid:grid.toString(),centralBit:records.find(b=>b.hex[0]===0&&b.hex[1]===0)||null,centralClusters:clusters,bits:records.map(({verts,...b})=>({...b,vertexCount:verts.length})),patches:list(grid.add(0x20).readPointer(),4,p=>{const a=p.readPointer();return {hex:hex(a.add(8)),state:a.add(0x1d).readU8(),subdivisions:a.add(0x1e).readU8(),cutoff:a.add(0x10).readU16(),verts:list(a.add(0x18).readPointer(),8,hex),indexes:list(a.add(0x14).readPointer(),1,p=>p.readU8())};})};
  }
  if(task.kind==='gridgraph'){
    const squareType=type('Placemaker.Graphs','Square'),qubeType=type('Placemaker.Graphs','Qube'),cornerType=type('Placemaker.Graphs','Corner'),voxelType=type('Placemaker','Voxel');
    const component=new NativeFunction(game.base.add(0xa3a9c0),'pointer',['pointer','pointer','pointer']),childCount=new NativeFunction(game.base.add(0x66f450),'int',['pointer','pointer']),child=new NativeFunction(game.base.add(0x66e3c0),'pointer',['pointer','int','pointer']);
    function position(t){return floats(unbox(invoke(t,'get_localPosition',[])),3);}
    function corner(c){return {pointer:c.toString(),hex:hex(c.add(0xc)),coverage:c.add(0x2c).readU8(),angle:c.add(0x28).readFloat(),colliderMesh:c.add(0x18).readPointer().toString(),squarePointers:list(c.add(0x14).readPointer(),4,p=>p.readPointer().toString())};}
    const squares=graph.add(0x1c).readPointer(),out=[];
    for(let i=0;i<childCount(squares,ptr(0));i++){
      const st=child(squares,i,ptr(0)),sq=component(st,squareType,ptr(0));if(sq.isNull())continue;
      const cs=[];for(let c=0;c<4;c++){const a=sq.add(0x2c+4*c).readPointer();cs.push(a.isNull()?null:corner(a));}
      if(task.hex&&!cs.some(c=>c&&c.hex[0]===task.hex[0]&&c.hex[1]===task.hex[1]))continue;
      const relations=[];for(let e=0;e<4;e++){const p=sq.add(0xc+8*e),other=p.readPointer(),j=p.add(4).readS8();relations.push({edge:e,square:other.toString(),indexInOther:j,reciprocal:other.isNull()?null:(j>=0&&j<4&&other.add(0xc+8*j).readPointer().equals(sq)&&other.add(0x10+8*j).readS8()===e)});}
      const qubes=[];for(let q=0;q<childCount(st,ptr(0));q++){const t=child(st,q,ptr(0)),a=component(t,qubeType,ptr(0));if(a.isNull())continue;const cv=[];for(let j=0;j<8;j++)cv.push(a.add(0x24+j).readU8());qubes.push({pointer:a.toString(),localPosition:position(t),occupancyMask:a.add(0xc).readU8(),cornerValues:cv,awaitingGraphUpdate:a.add(0x2e).readU8()});}
      const bid=unbox(invoke(sq,'get_bitQuadId',[]));
      out.push({pointer:sq.toString(),localPosition:position(st),bitQuadId:[bid.readS32(),bid.add(4).readS32(),bid.add(8).readS32()],quadIndex:sq.add(0x13d).readU8(),corners:cs,relations,qubes});
    }
    const corners=graph.add(0x14).readPointer(),voxels=[];
    for(let i=0;i<childCount(corners,ptr(0));i++){const ct=child(corners,i,ptr(0)),c=component(ct,cornerType,ptr(0));if(c.isNull())continue;const h=hex(c.add(0xc));if(task.hex&&(h[0]!==task.hex[0]||h[1]!==task.hex[1]))continue;
      for(let v=0;v<childCount(ct,ptr(0));v++){const t=child(ct,v,ptr(0)),a=component(t,voxelType,ptr(0));if(!a.isNull())voxels.push({pointer:a.toString(),hex:h,type:a.add(0xc).readU8(),height:a.add(0xd).readU8(),localPosition:position(t)});}
    }
    return {state:world.add(0xbe).readU8(),selectedHex:task.hex||null,squares:out,voxels};
  }
  throw new Error('unsupported grid task: '+task.kind);
}
