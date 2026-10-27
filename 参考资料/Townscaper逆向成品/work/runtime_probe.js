// Frida 17: observes original IL2CPP code, redirects persistence to workspace.
let game = null, ready = false, storageRoot = null, initEntered = 0, initReturned = 0, world = ptr(0), lastState = -1, pending=null, completed=null, flowUpdates=0;
function invoke(obj,name,values) {
  const cls=api('il2cpp_object_get_class','pointer',['pointer'])(obj);
  const method=api('il2cpp_class_get_method_from_name','pointer',['pointer','pointer','int'])(cls,Memory.allocUtf8String(name),values.length);
  if(method.isNull())throw new Error('method not found: '+name);
  const parameters=Memory.alloc(Math.max(1,values.length)*Process.pointerSize);
  for(let i=0;i<values.length;i++)parameters.add(i*Process.pointerSize).writePointer(values[i]);
  const error=Memory.alloc(Process.pointerSize);error.writePointer(ptr(0));
  const ret=api('il2cpp_runtime_invoke','pointer',['pointer','pointer','pointer','pointer'])(method,obj,parameters,error);
  if(!error.readPointer().isNull())throw new Error('managed exception in '+name);
  return ret;
}
function number(value,size=4){const p=Memory.alloc(size);if(size===1)p.writeU8(value);else p.writeS32(value);return p;}
function perform(task) {
  if(task.kind==='flowstatus') {
    const domain=api('il2cpp_domain_get','pointer',[])();
    const assembly=api('il2cpp_domain_assembly_open','pointer',['pointer','pointer'])(domain,Memory.allocUtf8String('Assembly-CSharp'));
    const image=api('il2cpp_assembly_get_image','pointer',['pointer'])(assembly);
    const cls=api('il2cpp_class_from_name','pointer',['pointer','pointer','pointer'])(image,Memory.allocUtf8String('Placemaker.Graphs'),Memory.allocUtf8String('Flow'));
    if(cls.isNull())throw new Error('Flow class not found');
    const type=api('il2cpp_type_get_object','pointer',['pointer'])(api('il2cpp_class_get_type','pointer',['pointer'])(cls));
    const objects=new NativeFunction(game.base.add(6709936),'pointer',['pointer','pointer'])(type,ptr(0));
    return {allLoadedInstances:objects.isNull()?0:objects.add(0xc).readS32(),updateCalls:flowUpdates,scope:'Unity Resources.FindObjectsOfTypeAll(Type), including inactive loaded objects; instrumented Flow.Update since module load'};
  }
  if(task.kind.startsWith('grid'))return performGridTask(task);
  if(task.kind==='capture') {
    const filename=api('il2cpp_string_new','pointer',['pointer'])(Memory.allocUtf8String(task.path));
    new NativeFunction(game.base.add(0x11492c0),'void',['pointer','int','pointer'])(filename,1,ptr(0));
    return {api:'UnityEngine.ScreenCapture.CaptureScreenshot',path:task.path,state:world.add(0xbe).readU8()};
  }
  if(task.kind==='save')return utf(new NativeFunction(game.base.add(0x3f7a90),'pointer',['pointer','pointer'])(world,ptr(0)));
  if(task.kind==='snapshot') {
    const domain=api('il2cpp_domain_get','pointer',[])();
    const assembly=api('il2cpp_domain_assembly_open','pointer',['pointer','pointer'])(domain,Memory.allocUtf8String('Assembly-CSharp'));
    const image=api('il2cpp_assembly_get_image','pointer',['pointer'])(assembly);
    function type(name){const cls=api('il2cpp_class_from_name','pointer',['pointer','pointer','pointer'])(image,Memory.allocUtf8String('Placemaker.Graphs'),Memory.allocUtf8String(name));return api('il2cpp_type_get_object','pointer',['pointer'])(api('il2cpp_class_get_type','pointer',['pointer'])(cls));}
    const qubeType=type('Qube'),moduleType=type('ModuleContainer'),squareType=type('Square');
    const component=new NativeFunction(game.base.add(0xa3a9c0),'pointer',['pointer','pointer','pointer']);
    const childCount=new NativeFunction(game.base.add(0x66f450),'int',['pointer','pointer']);
    const child=new NativeFunction(game.base.add(0x66e3c0),'pointer',['pointer','int','pointer']);
    const squares=world.add(0x18).readPointer().add(0x1c).readPointer();
    const result=[];
    for(let s=0;s<childCount(squares,ptr(0));s++) {
      const st=child(squares,s,ptr(0)),sq=component(st,squareType,ptr(0));
      if(sq.isNull())continue;
      for(let q=0;q<childCount(st,ptr(0));q++){
        const qt=child(st,q,ptr(0)),obj=component(qt,qubeType,ptr(0));if(obj.isNull())continue;
        const modules=[];
        for(let m=0;m<childCount(qt,ptr(0));m++){const c=component(child(qt,m,ptr(0)),moduleType,ptr(0));if(!c.isNull())modules.push({index:c.add(0xc).readU16(),flags:c.add(0xe).readU8()});}
        const corners=[];
        for(let c=0;c<4;c++){const corner=sq.add(0x2c+c*4).readPointer();corners.push(corner.isNull()?null:[corner.add(0xc).readS32(),corner.add(0x10).readS32()]);}
        result.push({squareCorners:corners,childIndex:q,occupancyMask:obj.add(0xc).readU8(),possibleModuleListIndex:obj.add(0x14).readS32(),modules});
      }
    }
    result.sort((a,b)=>JSON.stringify(a.squareCorners).localeCompare(JSON.stringify(b.squareCorners))||a.childIndex-b.childIndex);
    return {state:world.add(0xbe).readU8(),qubes:result,anyChange:world.add(0xc4).readU8(),lastChangeTime:world.add(0xc8).readFloat()};
  }
  if(task.kind==='storage') {
    const system=world.add(0x88).readPointer();
    const container=new NativeFunction(game.base.add(0xa04020),'pointer',['pointer','pointer'])(system,ptr(0));
    const cls=api('il2cpp_object_get_class','pointer',['pointer'])(container);
    const name=api('il2cpp_class_get_name','pointer',['pointer'])(cls).readUtf8String();
    return {class:name,root:name==='StandalonePCStorageContainer'?utf(container.add(0x14).readPointer()):null};
  }
  const maker=world.add(0x14).readPointer(),graph=world.add(0x18).readPointer();
  function dirty(){return {anyChange:world.add(0xc4).readU8(),lastChangeTime:world.add(0xc8).readFloat(),lastStartChangeTime:world.add(0xcc).readFloat()};}
  function history(){const list=maker.add(0x10).readPointer(),size=list.add(0xc).readS32(),items=list.add(8).readPointer().add(0x10);return {size,actionIndex:maker.add(0x14).readS32(),actionCount:maker.add(0x18).readS32(),redoMax:maker.add(0x1c).readS32(),actionId:maker.add(0x20).readS32(),firstId:size?items.add(0xc).readS32():null,lastId:size?items.add((size-1)*16+0xc).readS32():null};}
  if(task.kind==='dirtyprobe') {
    invoke(maker,'EndAction',[]);const afterEnd=dirty();
    const result=invoke(world.add(0x88).readPointer(),'MaybeSaveCurrent',[]);
    const afterSave=dirty();const undo=invoke(maker,'Undo',[]).add(8).readU8()!==0;const afterUndo=dirty();
    const redo=invoke(maker,'Redo',[]).add(8).readU8()!==0;const afterRedo=dirty();
    return {afterEnd,saveReturned:result.add(8).readU8()!==0,afterSave,undo,afterUndo,redo,afterRedo};
  }
  if(task.kind==='historyprobe') {
    invoke(maker,'ClearUndoQueue',[]);const points=[];
    const pos=Memory.alloc(8);pos.writeS32(0);pos.add(4).writeS32(0);
    for(let group=1;group<=1000;group++){
      invoke(maker,'BeginNewAction',[]);
      for(let n=0;n<(group===1?2:1);n++)invoke(maker,'AddAction',[pos,number(1,1),number(18,1),number(0,1)]);
      if(group===1||group===998||group===999||group===1000)points.push({group,...history()});
    }
    invoke(maker,'TrimActionList',[]);points.push({phase:'explicitTrim',...history()});
    invoke(maker,'ClearUndoQueue',[]);
    return points;
  }
  if(task.kind==='worldload'){const str=api('il2cpp_string_new','pointer',['pointer'])(Memory.allocUtf8String(task.text));const ok=new NativeFunction(game.base.add(0x3f8420),'bool',['pointer','pointer','pointer'])(world,str,ptr(0));return {accepted:ok,state:world.add(0xbe).readU8()};}
  if(task.kind==='worldstatus')return {state:world.add(0xbe).readU8(),boundsHeight:graph.add(0x74).readS32(),maxHeight:graph.add(0xd8).readS32(),loadState:graph.add(0xec).readS32()};
  if(task.kind==='undo'||task.kind==='redo') {const ret=invoke(maker,task.kind==='undo'?'Undo':'Redo',[]);return ret.add(8).readU8()!==0;}
  if(task.kind==='action') {
    invoke(maker,'BeginNewAction',[]);
    const pos=Memory.alloc(8);pos.writeS32(task.x);pos.add(4).writeS32(task.y);
    invoke(maker,'AddAction',[pos,number(task.h,1),number(task.before,1),number(task.after,1)]);
    // AddAction actually has four arguments: position, height, old type, new type.
    const action=Memory.alloc(16);action.writeS32(task.x);action.add(4).writeS32(task.y);action.add(8).writeU8(task.h);action.add(9).writeU8(task.before);action.add(10).writeU8(task.after);action.add(12).writeS32(0);
    invoke(graph,'ApplyAction',[action,number(0,1)]);
    invoke(world,'SetDirty',[]);
    return true;
  }
  throw new Error('unsupported scenario task');
}
function api(name, ret, args) { return new NativeFunction(game.getExportByName(name), ret, args); }
function utf(s) { return s.isNull() ? null : s.add(12).readUtf16String(s.add(8).readS32()); }
const observer = Process.attachModuleObserver({
  onAdded(module) {
    if (module.name.toLowerCase() !== 'gameassembly.dll' || game) return;
    game = module;
    send({kind:'module',base:game.base.toString(),path:game.path});
    Interceptor.attach(game.getExportByName('il2cpp_init'), {onLeave(ret) {ready=true;send({kind:'il2cpp_initialized',domain:ret.toString()});}});
    Interceptor.attach(game.base.add(0xa35d20), {onLeave(ret) {
      if (!storageRoot) return;
      const str=api('il2cpp_string_new','pointer',['pointer']);
      const replaced=str(Memory.allocUtf8String(storageRoot));
      send({kind:'persistent_path_redirect',original:utf(ret),replacement:storageRoot});ret.replace(replaced);
    }});
    // Prevent automatic save writes; explicit codec calls never use SaveSystem.
    Interceptor.replace(game.base.add(0xa03390), new NativeCallback(function(){send({kind:'autosave_suppressed'});}, 'void', ['pointer','pointer','pointer']));
    Interceptor.attach(game.base.add(0x18e950), {onEnter(){initEntered++;},onLeave(){initReturned++;}});
    Interceptor.attach(game.base.add(0x83bef0), {onEnter(){flowUpdates++;}});
    Interceptor.attach(game.base.add(0x1142fb0), {onEnter(args){this.obj=args[0];},onLeave(){send({kind:'storage_container',rootPath:utf(this.obj.add(0x14).readPointer())});}});
    Interceptor.attach(game.base.add(0x3f7b30), {onEnter(args){world=args[0];const state=world.add(0xbe).readU8();if(state!==lastState){send({kind:'world_state',state});lastState=state;}},onLeave(){const state=world.add(0xbe).readU8();if(state!==lastState){send({kind:'world_state',state});lastState=state;}}});
    Interceptor.attach(game.base.add(0x3f8c30),{onEnter(args){world=args[0];if(pending){const task=pending;pending=null;try{completed={ok:true,result:perform(task)};}catch(e){completed={ok:false,error:String(e)};}}}});
  }
});
rpc.exports = {
  configure(path) {storageRoot=path;return true;},
  enqueue(task){if(pending)throw new Error('task already queued');completed=null;pending=task;return true;},
  scenarioresult(){return completed;},
  layouts(selections){
    if(!ready)throw new Error('IL2CPP not initialized');
    const domain=api('il2cpp_domain_get','pointer',[])();api('il2cpp_thread_attach','pointer',['pointer'])(domain);
    const results=[];
    for(const assemblyName of selections){
      const assembly=api('il2cpp_domain_assembly_open','pointer',['pointer','pointer'])(domain,Memory.allocUtf8String(assemblyName));
      if(assembly.isNull()){results.push({assembly:assemblyName,error:'not loaded'});continue;}
      const image=api('il2cpp_assembly_get_image','pointer',['pointer'])(assembly);
      const count=api('il2cpp_image_get_class_count','uint',['pointer'])(image);
      for(let index=0;index<count;index++){
        const cls=api('il2cpp_image_get_class','pointer',['pointer','uint'])(image,index);
        const name=api('il2cpp_class_get_name','pointer',['pointer'])(cls).readUtf8String(),namespace=api('il2cpp_class_get_namespace','pointer',['pointer'])(cls).readUtf8String();
        const fields=[],iterator=Memory.alloc(Process.pointerSize);iterator.writePointer(ptr(0));
        while(true){const field=api('il2cpp_class_get_fields','pointer',['pointer','pointer'])(cls,iterator);if(field.isNull())break;
          const t=api('il2cpp_field_get_type','pointer',['pointer'])(field),label=api('il2cpp_type_get_name','pointer',['pointer'])(t);
          fields.push({name:api('il2cpp_field_get_name','pointer',['pointer'])(field).readUtf8String(),offset:api('il2cpp_field_get_offset','uint',['pointer'])(field),flags:api('il2cpp_field_get_flags','uint',['pointer'])(field),type:label.readUtf8String()});api('il2cpp_free','void',['pointer'])(label);
        }
        results.push({assembly:assemblyName,index,name,namespace,instanceSize:api('il2cpp_class_instance_size','uint',['pointer'])(cls),isValueType:api('il2cpp_class_is_valuetype','bool',['pointer'])(cls),fields});
      }
    }
    return results;
  },
  status() {return {loaded:!!game,ready,pointerSize:Process.pointerSize,metadataInitializer:{entered:initEntered,returned:initReturned},worldState:world.isNull()?null:world.add(0xbe).readU8()};},
  codec(fixtures) {
    if(!ready) throw new Error('IL2CPP not initialized');
    const domain=api('il2cpp_domain_get','pointer',[])();
    api('il2cpp_thread_attach','pointer',['pointer'])(domain);
    const open=api('il2cpp_domain_assembly_open','pointer',['pointer','pointer']);
    const image=api('il2cpp_assembly_get_image','pointer',['pointer'])(open(domain,Memory.allocUtf8String('Assembly-CSharp')));
    const klass=api('il2cpp_class_from_name','pointer',['pointer','pointer','pointer'])(image,Memory.allocUtf8String('Placemaker'),Memory.allocUtf8String('SaveData'));
    const make=api('il2cpp_object_new','pointer',['pointer']);
    const str=api('il2cpp_string_new','pointer',['pointer']);
    const ctor=new NativeFunction(game.base.add(0x9fde20),'void',['pointer','pointer']);
    const load=new NativeFunction(game.base.add(0x301d60),'bool',['pointer','pointer','pointer','pointer']);
    const save=new NativeFunction(game.base.add(0x302ad0),'pointer',['pointer','pointer','pointer']);
    const results=[];
    for(const fixture of fixtures) {
      const obj=make(klass);ctor(obj,ptr(0));
      const corners=obj.add(0x20).readPointer(),voxels=obj.add(0x24).readPointer();
      const ok=load(str(Memory.allocUtf8String(fixture.text)),corners,voxels,ptr(0));
      const countC=corners.add(0xc).readS32(),countV=voxels.add(0xc).readS32();
      const arrC=corners.add(0x8).readPointer().add(0x10),arrV=voxels.add(0x8).readPointer().add(0x10);
      const cs=[],vs=[];
      for(let i=0;i<countC;i++){const p=arrC.add(i*12);cs.push({x:p.readS32(),y:p.add(4).readS32(),count:p.add(8).readS32()});}
      for(let i=0;i<countV;i++){const p=arrV.add(i*2);vs.push({t:p.readU8(),h:p.add(1).readU8()});}
      results.push({name:fixture.name,input:fixture.text,accepted:ok,reencoded:ok?utf(save(corners,voxels,ptr(0))):null,data:{corners:cs,voxels:vs}});
    }
    return {moduleBase:game.base.toString(),pointerSize:Process.pointerSize,results};
  }
};
