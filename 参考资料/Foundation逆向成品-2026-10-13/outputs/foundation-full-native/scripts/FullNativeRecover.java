// @category REA.Foundation.Full
import ghidra.app.script.GhidraScript;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import ghidra.util.task.TaskMonitor;
import java.nio.file.*;
import java.io.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;
import java.util.zip.GZIPOutputStream;
import com.google.gson.*;

public class FullNativeRecover extends GhidraScript {
 static final Gson GSON=new GsonBuilder().disableHtmlEscaping().create();
 Path work,out;TreeMap<Long,Long> ranges=new TreeMap<>();Map<Long,String> classification=new HashMap<>();
 AtomicInteger done=new AtomicInteger(),ok=new AtomicInteger(),failed=new AtomicInteger();long started;
 void progress(String stage,int total,Map<String,Object> extra)throws Exception {
  Map<String,Object> p=new LinkedHashMap<>();p.put("stage",stage);p.put("processed",done.get());p.put("total",total);p.put("success",ok.get());p.put("failed",failed.get());p.put("elapsed_seconds",(System.currentTimeMillis()-started)/1000);p.put("updated_utc",java.time.Instant.now().toString());p.putAll(extra);
  Path tmp=out.resolve("progress.json.tmp");Files.writeString(tmp,GSON.toJson(p));try{Files.move(tmp,out.resolve("progress.json"),StandardCopyOption.REPLACE_EXISTING);}catch(java.nio.file.FileSystemException sharing){println("Progress read lock; continuing analysis: "+sharing.getReason());}
 }
 BufferedWriter gz(String name)throws Exception{return new BufferedWriter(new OutputStreamWriter(new GZIPOutputStream(Files.newOutputStream(out.resolve(name)),65536),java.nio.charset.StandardCharsets.UTF_8),65536);}
 long parse(String s){return Long.parseUnsignedLong(s.replace("0x",""),16);}
 String hx(long a){return "0x"+Long.toHexString(a);}
 long displacement(byte[] b,int off){return (b[off]&255)|((b[off+1]&255)<<8)|((b[off+2]&255)<<16)|(b[off+3]<<24);}
 boolean inText(long a){return a>=0x140001000L && a<0x142c64360L;}
 boolean covered(long a){Map.Entry<Long,Long> e=ranges.floorEntry(a);return e!=null && a<e.getValue();}
 public void run()throws Exception{
  String[] args=getScriptArgs();work=Paths.get(args[0]);out=Paths.get(args[1]);Files.createDirectories(out);started=System.currentTimeMillis();String stage=args.length>2?args[2]:"decode";
  for(String line:Files.readAllLines(work.resolve("all-ranges.tsv"))){String[] s=line.split("\t");long a=parse(s[0]);ranges.put(a,parse(s[1]));classification.put(a,s[2]);}
  if(stage.equals("decode"))decode();else if(stage.equals("supplement"))supplement();else if(stage.equals("decompile"))decompile(Integer.parseInt(args[3]),Integer.parseInt(args[4]),args.length>5?Integer.parseInt(args[5]):0);else if(stage.equals("retry"))retry(Integer.parseInt(args[4]));else throw new IllegalArgumentException(stage);
 }
 void decode()throws Exception{
  int total=ranges.size();Set<Long> outsideCalls=new TreeSet<>(),stringTargets=new HashSet<>();List<String> createErrors=new ArrayList<>();int instructions=0;long decodedBytes=0,calls=0;BufferedWriter assembly=null;int shard=-1;
  BufferedWriter callout=gz("all-call-references.jsonl.gz"),dataout=gz("all-rip-data-references.jsonl.gz"),index=Files.newBufferedWriter(out.resolve("assembly-address-index.csv"));index.write("entry,shard,line,classification,pdata_end_exclusive,instructions,decoded_bytes\n");
  progress("decode",total,Map.of("source_ranges",total));
  for(Map.Entry<Long,Long> r:ranges.entrySet()){
   monitor.checkCancelled();long a=r.getKey(),end=r.getValue();Address ad=toAddr(a);AddressSet bound=new AddressSet(ad,toAddr(end-1));
   try{
    DisassembleCommand cmd=new DisassembleCommand(ad,bound,true);cmd.enableCodeAnalysis(false);cmd.applyTo(currentProgram,monitor);
    Function f=getFunctionAt(ad);if(f==null)f=currentProgram.getFunctionManager().createFunction("FUN_"+Long.toHexString(a),ad,bound,SourceType.ANALYSIS);else f.setBody(bound);
    List<Object> inslist=new ArrayList<>();long byteCount=0;
    for(Instruction ins:currentProgram.getListing().getInstructions(bound,true)){
     long at=ins.getAddress().getOffset();byte[] b=ins.getBytes();byteCount+=b.length;String hex=java.util.HexFormat.of().formatHex(b);Map<String,Object> item=new LinkedHashMap<>();item.put("va",hx(at));item.put("bytes",hex);item.put("asm",ins.toString());item.put("flow",ins.getFlowType().toString());
     if(b.length==5 && ((b[0]&255)==0xe8 || (b[0]&255)==0xe9)){
      long target=at+5+displacement(b,1);boolean iscall=(b[0]&255)==0xe8;Map<String,Object> edge=Map.of("from",hx(at),"owner",hx(a),"target",hx(target),"kind",iscall?"direct_call":"direct_jump");callout.write(GSON.toJson(edge)+"\n");if(iscall){calls++;currentProgram.getReferenceManager().addMemoryReference(ins.getAddress(),toAddr(target),RefType.UNCONDITIONAL_CALL,SourceType.ANALYSIS,0);if(inText(target)&&!covered(target))outsideCalls.add(target);}item.put("target",hx(target));
     }else if(ins.getFlowType().isCall()){
      callout.write(GSON.toJson(Map.of("from",hx(at),"owner",hx(a),"kind","indirect_call","asm",ins.toString()))+"\n");calls++;
     }
     if(b.length>=7 && (b[0]&255)>=0x48 && (b[0]&255)<=0x4f && ((b[1]&255)==0x8d || (b[1]&255)==0x8b) && (b[2]&0xc7)==5){long target=at+7+displacement(b,3);dataout.write(GSON.toJson(Map.of("from",hx(at),"owner",hx(a),"target",hx(target),"opcode",(b[1]&255)==0x8d?"LEA":"MOV"))+"\n");stringTargets.add(target);}
     inslist.add(item);
    }
    int wanted=done.get()/2000;if(wanted!=shard){if(assembly!=null)assembly.close();shard=wanted;assembly=gz(String.format("assembly-%04d.jsonl.gz",shard));}
    Map<String,Object> rec=new LinkedHashMap<>();rec.put("entry",hx(a));rec.put("end_exclusive",hx(end));rec.put("classification",classification.get(a));rec.put("instruction_count",inslist.size());rec.put("decoded_bytes",byteCount);rec.put("instructions",inslist);assembly.write(GSON.toJson(rec)+"\n");index.write(hx(a)+","+String.format("assembly-%04d.jsonl.gz",shard)+","+(done.get()%2000)+","+classification.get(a)+","+hx(end)+","+inslist.size()+","+byteCount+"\n");
    decodedBytes+=byteCount;instructions+=inslist.size();ok.incrementAndGet();
   }catch(Exception exc){failed.incrementAndGet();createErrors.add(hx(a)+" "+exc);}
   done.incrementAndGet();if(done.get()%500==0){progress("decode",total,Map.of("instructions",instructions,"decoded_bytes",decodedBytes,"calls",calls,"leaf_candidates",outsideCalls.size()));println("FULL_DECODE "+done+"/"+total);}
  }
  if(assembly!=null)assembly.close();index.close();callout.close();dataout.close();Files.write(out.resolve("decode-errors.txt"),createErrors);
  // Leaf functions without unwind records: use control-flow disassembly, bounded by the next existing function.
  List<Map<String,Object>> leaves=new ArrayList<>();int leafok=0;
  for(long a:outsideCalls){
   if(getFunctionContaining(toAddr(a))!=null)continue;Map<String,Object> row=new LinkedHashMap<>();row.put("entry",hx(a));
   try{Long next=ranges.ceilingKey(a);long end=Math.min(next==null?0x142c64360L:next,a+32768);AddressSet limit=new AddressSet(toAddr(a),toAddr(end-1));DisassembleCommand cmd=new DisassembleCommand(toAddr(a),limit,true);cmd.enableCodeAnalysis(false);cmd.applyTo(currentProgram,monitor);AddressSetView body=cmd.getDisassembledAddressSet();
    if(body!=null&&body.contains(toAddr(a))&&!body.isEmpty()){Function f=currentProgram.getFunctionManager().createFunction("LEAF_"+Long.toHexString(a),toAddr(a),body,SourceType.ANALYSIS);row.put("recovered",true);row.put("body",body.toString());row.put("bytes",body.getNumAddresses());leafok++;}else row.put("recovered",false);
   }catch(Exception exc){row.put("recovered",false);row.put("error",exc.toString());}leaves.add(row);
  }
  Files.writeString(out.resolve("leaf-function-recovery.json"),GSON.toJson(leaves));
  int labeled=0;for(long target:stringTargets){try{byte[] data=new byte[2001];int n=currentProgram.getMemory().getBytes(toAddr(target),data);int k=0;while(k<n && data[k]>=32 && data[k]<127)k++;if(k>=5 && k<n && data[k]==0 && getDataAt(toAddr(target))==null){createAsciiString(toAddr(target));labeled++;}}catch(Exception ignored){}}
  progress("decode_complete",total,Map.of("instructions",instructions,"decoded_bytes",decodedBytes,"calls",calls,"leaf_candidates",outsideCalls.size(),"leaf_functions",leafok,"ascii_labels",labeled,"ghidra_functions",currentProgram.getFunctionManager().getFunctionCount()));println("FULL_DECODE_DONE "+done+" functions="+currentProgram.getFunctionManager().getFunctionCount());
 }
 void decompile(int workers,int timeout,int startShard)throws Exception{
  List<Function> functions=new ArrayList<>();for(Function f:currentProgram.getFunctionManager().getFunctions(true))if(!f.isExternal())functions.add(f);functions.sort(Comparator.comparingLong(f->f.getEntryPoint().getOffset()));int total=functions.size();
  ExecutorService pool=Executors.newFixedThreadPool(workers);List<DecompInterface> interfaces=Collections.synchronizedList(new ArrayList<>());ThreadLocal<DecompInterface> local=ThreadLocal.withInitial(()->{DecompInterface d=new DecompInterface();DecompileOptions opts=new DecompileOptions();opts.grabFromProgram(currentProgram);opts.setDefaultTimeout(timeout);d.setOptions(opts);d.toggleSyntaxTree(false);d.toggleCCode(true);d.openProgram(currentProgram);interfaces.add(d);return d;});
  BufferedWriter idx=Files.newBufferedWriter(out.resolve(startShard==0?"pseudocode-address-index.csv":"pseudocode-resume-index.csv"));idx.write("entry,shard,line,status,body_bytes\n");done.set(startShard*2000);progress("decompile",total,Map.of("workers",workers,"timeout_seconds",timeout));
  try{
   for(int begin=startShard*2000;begin<total;begin+=2000){monitor.checkCancelled();int end=Math.min(begin+2000,total);int shard=begin/2000;String name=String.format("pseudocode-%04d.jsonl.gz",shard);CompletionService<Map<String,Object>> completion=new ExecutorCompletionService<>(pool);
    for(int i=begin;i<end;i++){final Function f=functions.get(i);completion.submit(()->{
     Map<String,Object> rec=new LinkedHashMap<>();long address=f.getEntryPoint().getOffset();rec.put("entry",hx(address));rec.put("name",f.getName());rec.put("classification",classification.getOrDefault(address,"leaf_or_loader_function"));rec.put("body_ranges",f.getBody().toString());rec.put("body_bytes",f.getBody().getNumAddresses());
     long beginTime=System.nanoTime();try{DecompileResults r=local.get().decompileFunction(f,timeout,TaskMonitor.DUMMY);rec.put("status",r.decompileCompleted()?"complete":"failed");rec.put("error",r.getErrorMessage());if(r.getDecompiledFunction()!=null)rec.put("pseudocode",r.getDecompiledFunction().getC());}catch(Exception exc){rec.put("status","exception");rec.put("error",exc.toString());}rec.put("elapsed_ms",(System.nanoTime()-beginTime)/1000000);return rec;
    });}
    try(BufferedWriter writer=gz(name)){for(int line=0;line<end-begin;line++){Map<String,Object> rec=completion.take().get();writer.write(GSON.toJson(rec)+"\n");idx.write(rec.get("entry")+","+name+","+line+","+rec.get("status")+","+rec.get("body_bytes")+"\n");done.incrementAndGet();if("complete".equals(rec.get("status")))ok.incrementAndGet();else failed.incrementAndGet();if(done.get()%200==0)progress("decompile",total,Map.of("workers",workers,"timeout_seconds",timeout,"shard",shard));}}
    idx.flush();progress("decompile",total,Map.of("workers",workers,"timeout_seconds",timeout,"completed_shard",shard));println("FULL_DECOMPILE "+done+"/"+total+" ok="+ok+" failed="+failed);
   }
  }finally{pool.shutdownNow();for(DecompInterface d:interfaces)d.dispose();idx.close();}
  progress("decompile_complete",total,Map.of("workers",workers,"timeout_seconds",timeout));println("FULL_DECOMPILE_DONE "+done+" ok="+ok+" failed="+failed);
 }
 void supplement()throws Exception{
  TreeSet<Long> targets=new TreeSet<>();for(String s:Files.readAllLines(work.resolve("vtable-leaf-targets.tsv")))targets.add(parse(s));
  for(Instruction ins:currentProgram.getListing().getInstructions(new AddressSet(toAddr(0x140001000L),toAddr(0x142c6435fL)),true)){
   byte[] b=ins.getBytes();if(b.length==5 && ((b[0]&255)==0xe9 || (b[0]&255)==0xe8)){long a=ins.getAddress().getOffset()+5+displacement(b,1);if(inText(a)&&!covered(a))targets.add(a);}
  }
  BufferedWriter leafout=gz("additional-function-recovery.jsonl.gz");int created=0;
  for(long a:targets){monitor.checkCancelled();Map<String,Object> row=new LinkedHashMap<>();row.put("entry",hx(a));Function existing=getFunctionContaining(toAddr(a));
   if(existing!=null){row.put("status","covered_by_existing");row.put("owner",existing.getEntryPoint().toString());}else{
    try{Long next=ranges.ceilingKey(a);long end=Math.min(next==null?0x142c64360L:next,a+32768);AddressSet limit=new AddressSet(toAddr(a),toAddr(end-1));DisassembleCommand cmd=new DisassembleCommand(toAddr(a),limit,true);cmd.enableCodeAnalysis(false);cmd.applyTo(currentProgram,monitor);AddressSetView body=cmd.getDisassembledAddressSet();
     if(body==null||body.isEmpty()){Instruction start=getInstructionAt(toAddr(a));if(start!=null){AddressSet known=new AddressSet();Address cur=toAddr(a);while(cur.getOffset()<end){Instruction ins=getInstructionAt(cur);if(ins==null)break;known.add(ins.getMinAddress(),ins.getMaxAddress());if(ins.getFlowType().isTerminal()||ins.getFlowType().isJump())break;cur=ins.getMaxAddress().next();}body=known;}}
     if(body!=null&&body.contains(toAddr(a))&&!body.isEmpty()){currentProgram.getFunctionManager().createFunction("LEAF_"+Long.toHexString(a),toAddr(a),body,SourceType.ANALYSIS);row.put("status","recovered");row.put("body",body.toString());row.put("bytes",body.getNumAddresses());created++;}else row.put("status","no_instructions");
    }catch(Exception exc){row.put("status","error");row.put("error",exc.toString());}
   }
   leafout.write(GSON.toJson(row)+"\n");done.incrementAndGet();if(done.get()%500==0)progress("supplement",targets.size(),Map.of("created",created,"ghidra_functions",currentProgram.getFunctionManager().getFunctionCount()));
  }leafout.close();
  // Full listing export includes unwind ranges, discovered leaves, thunks and other loader-defined instructions.
  BufferedWriter all=gz("all-text-instructions.jsonl.gz"),refs=gz("complete-call-references.jsonl.gz"),gaps=gz("unassigned-text-byte-ranges.jsonl.gz");long cursor=0x140001000L;long count=0,bytes=0,gapBytes=0,padding=0;
  for(Instruction ins:currentProgram.getListing().getInstructions(new AddressSet(toAddr(cursor),toAddr(0x142c6435fL)),true)){
   long a=ins.getAddress().getOffset();if(a>cursor){long[] stats=writeGap(gaps,cursor,a);gapBytes+=stats[0];padding+=stats[1];}byte[] raw=ins.getBytes();Function f=getFunctionContaining(ins.getAddress());Map<String,Object> row=new LinkedHashMap<>();row.put("va",hx(a));row.put("bytes",java.util.HexFormat.of().formatHex(raw));row.put("asm",ins.toString());row.put("flow",ins.getFlowType().toString());if(f!=null)row.put("owner",f.getEntryPoint().toString());
   if(raw.length==5 && ((raw[0]&255)==0xe8 || (raw[0]&255)==0xe9)){long to=a+5+displacement(raw,1);row.put("target",hx(to));refs.write(GSON.toJson(Map.of("from",hx(a),"owner",f==null?"unassigned":f.getEntryPoint().toString(),"target",hx(to),"kind",(raw[0]&255)==0xe8?"direct_call":"direct_jump"))+"\n");}
   else if(ins.getFlowType().isCall()||ins.getFlowType().isJump()){refs.write(GSON.toJson(Map.of("from",hx(a),"owner",f==null?"unassigned":f.getEntryPoint().toString(),"kind","indirect_or_relative_control_flow","asm",ins.toString()))+"\n");}
   all.write(GSON.toJson(row)+"\n");count++;bytes+=raw.length;cursor=a+raw.length;
  }if(cursor<0x142c64360L){long[] stats=writeGap(gaps,cursor,0x142c64360L);gapBytes+=stats[0];padding+=stats[1];}all.close();refs.close();gaps.close();
  Map<String,Object> coverage=new LinkedHashMap<>();coverage.put("text_start",hx(0x140001000L));coverage.put("text_end_exclusive",hx(0x142c64360L));coverage.put("text_bytes",46543712);coverage.put("decoded_instructions",count);coverage.put("decoded_instruction_bytes",bytes);coverage.put("unassigned_bytes",gapBytes);coverage.put("unassigned_0x00_or_0xcc_bytes",padding);coverage.put("byte_partition_closed",bytes+gapBytes==46543712);coverage.put("recovered_function_entries",currentProgram.getFunctionManager().getFunctionCount());coverage.put("additional_created",created);coverage.put("limits","Unassigned bytes are preserved verbatim and classified only bytewise; no inference that every gap is padding or executable code. Short branches/indirect calls are assembly observations, unresolved targets retained.");Files.writeString(out.resolve("decode-coverage.json"),GSON.toJson(coverage));
  progress("supplement_complete",targets.size(),coverage);println("FULL_SUPPLEMENT_DONE functions="+currentProgram.getFunctionManager().getFunctionCount());
 }
 long[] writeGap(BufferedWriter writer,long start,long end)throws Exception{
  byte[] b=new byte[(int)(end-start)];currentProgram.getMemory().getBytes(toAddr(start),b);long padding=0;for(byte a:b)if(a==0||(a&255)==0xcc)padding++;writer.write(GSON.toJson(Map.of("start",hx(start),"end_exclusive",hx(end),"bytes",java.util.HexFormat.of().formatHex(b),"length",b.length,"zero_or_int3_bytes",padding))+"\n");return new long[]{b.length,padding};
 }
 void retry(int timeout)throws Exception{
  List<String> addresses=Files.readAllLines(work.resolve("retry-addresses.tsv"));DecompInterface dec=new DecompInterface();DecompileOptions opts=new DecompileOptions();opts.grabFromProgram(currentProgram);dec.setOptions(opts);dec.toggleSyntaxTree(false);dec.openProgram(currentProgram);BufferedWriter output=gz("pseudocode-retry.jsonl.gz"),index=Files.newBufferedWriter(out.resolve("pseudocode-retry-address-index.csv"));index.write("entry,shard,line,status,body_bytes\n");int line=0;
  for(String s:addresses){long a=parse(s);Function f=getFunctionAt(toAddr(a));Map<String,Object> rec=new LinkedHashMap<>();rec.put("entry",hx(a));rec.put("timeout_seconds",timeout);rec.put("classification",classification.getOrDefault(a,"leaf_or_loader_function"));
   if(f==null){rec.put("status","function_missing");rec.put("body_bytes",0);}else{rec.put("body_ranges",f.getBody().toString());rec.put("body_bytes",f.getBody().getNumAddresses());DecompileResults r=dec.decompileFunction(f,timeout,monitor);rec.put("status",r.decompileCompleted()?"complete":"failed");rec.put("error",r.getErrorMessage());if(r.getDecompiledFunction()!=null)rec.put("pseudocode",r.getDecompiledFunction().getC());}
   output.write(GSON.toJson(rec)+"\n");index.write(hx(a)+",pseudocode-retry.jsonl.gz,"+line+","+rec.get("status")+","+rec.get("body_bytes")+"\n");line++;done.incrementAndGet();if("complete".equals(rec.get("status")))ok.incrementAndGet();else failed.incrementAndGet();progress("retry",addresses.size(),Map.of("timeout_seconds",timeout));
  }output.close();index.close();dec.dispose();progress("retry_complete",addresses.size(),Map.of("timeout_seconds",timeout));
 }
}
