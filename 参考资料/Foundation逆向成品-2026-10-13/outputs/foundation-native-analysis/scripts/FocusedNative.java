// @category REA.Foundation
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.nio.file.*;
import java.util.*;
import com.google.gson.GsonBuilder;

public class FocusedNative extends GhidraScript {
 private TreeMap<Long,Long> ranges=new TreeMap<>();
 private LinkedHashMap<Long,String> seeds=new LinkedHashMap<>();
 private LinkedHashSet<Long> selected=new LinkedHashSet<>();
 private long addr(String a) { return Long.parseUnsignedLong(a.replace("0x",""),16); }
 private Function make(long a) throws Exception {
  Address ad=toAddr(a); Function f=getFunctionAt(ad);
  Long end=ranges.get(a); if(end==null || end-a>50000)return null;
  AddressSet set=new AddressSet(ad,toAddr(end-1));
  DisassembleCommand cmd=new DisassembleCommand(ad,set,true);cmd.enableCodeAnalysis(false);cmd.applyTo(currentProgram,monitor);
  if(f==null)f=createFunction(ad,null);
  if(f!=null)f.setBody(set);
  return f;
 }
 private void explicitRefs(Function f) throws Exception {
  if(f==null)return;
  for(Instruction ins:currentProgram.getListing().getInstructions(f.getBody(),true)){
   byte[] b=ins.getBytes(); long a=ins.getAddress().getOffset();
   if(b.length==5 && (b[0]&255)==0xe8){
    int disp=(b[1]&255)|((b[2]&255)<<8)|((b[3]&255)<<16)|(b[4]<<24);long dst=a+5+disp;
    currentProgram.getReferenceManager().addMemoryReference(ins.getAddress(),toAddr(dst),RefType.UNCONDITIONAL_CALL,SourceType.ANALYSIS,0);
   }
   if(b.length==7 && (b[0]&255)>=0x48 && (b[0]&255)<=0x4f && ((b[1]&255)==0x8d || (b[1]&255)==0x8b) && (b[2]&0xc7)==5){
    int disp=(b[3]&255)|((b[4]&255)<<8)|((b[5]&255)<<16)|(b[6]<<24);Address dst=toAddr(a+7+disp);
    try{byte[] buf=new byte[500];int len=currentProgram.getMemory().getBytes(dst,buf);int k=0;while(k<len && buf[k]>=32 && buf[k]<127)k++;if(k>=5 && k<len && buf[k]==0){
     currentProgram.getReferenceManager().addMemoryReference(ins.getAddress(),dst,RefType.DATA,SourceType.ANALYSIS,1);
     if(getDataAt(dst)==null || getDataAt(dst).getDataType().getName().startsWith("undefined"))try{createAsciiString(dst);}catch(Exception ignored){}
    }}catch(Exception ignored){}
   }
  }
 }
 public void run() throws Exception {
  String[] args=getScriptArgs(); Path work=Paths.get(args[0]), out=Paths.get(args[1]);
  for(String line:Files.readAllLines(work.resolve("ranges.tsv"))){String[] s=line.split("\t");ranges.put(addr(s[0]),addr(s[1]));}
  boolean broad=args.length>2 && !args[2].equals("seeds.tsv");
  for(String line:Files.readAllLines(work.resolve(args.length>2?args[2]:"seeds.tsv"))){String[] s=line.split("\t",3);long a=addr(s[0]); if((broad || a<0x140300000L) && !s[2].contains("FbxImport")){seeds.put(a,s[2]);selected.add(a);}}
  println("FOCUSED_STAGE create seeds "+seeds.size());
  for(long a:new ArrayList<>(selected)) {monitor.checkCancelled(); explicitRefs(make(a));}
  // One direct-call expansion only; .pdata must identify the exact callee entry.
  for(long a:new ArrayList<>(selected)){
   Function f=getFunctionAt(toAddr(a)); if(f==null)continue;
   for(Instruction ins: currentProgram.getListing().getInstructions(f.getBody(),true)) {
    if(ins.getFlowType().isCall()) for(Address dest:ins.getFlows()) if(ranges.containsKey(dest.getOffset()))selected.add(dest.getOffset());
   }
  }
  println("FOCUSED_STAGE create expanded "+selected.size());
  for(long a:selected){monitor.checkCancelled();explicitRefs(make(a));}
  DecompInterface dec=new DecompInterface();dec.openProgram(currentProgram);
  List<Object> records=new ArrayList<>(); int n=0;
  for(long a:selected){
   monitor.checkCancelled(); Function f=getFunctionAt(toAddr(a));if(f==null)continue;
   Map<String,Object> rec=new LinkedHashMap<>();rec.put("entry","0x"+Long.toHexString(a));rec.put("name",f.getName());rec.put("seed",seeds.get(a));rec.put("pdata_end_exclusive","0x"+Long.toHexString(ranges.get(a)));
   List<Object> refs=new ArrayList<>(), calls=new ArrayList<>();StringBuilder asm=new StringBuilder();
   for(Instruction ins:currentProgram.getListing().getInstructions(f.getBody(),true)){
    asm.append(ins.getAddress()).append(" ").append(ins).append("\n");
    for(Reference r:ins.getReferencesFrom()){
     Map<String,Object> x=new LinkedHashMap<>();x.put("from",ins.getAddress().toString());x.put("to",r.getToAddress().toString());x.put("type",r.getReferenceType().toString());
     if(r.getReferenceType().isCall()){calls.add(x);}
     else if(r.getToAddress().isMemoryAddress()){
      try{byte[] bytes=new byte[500];int len=currentProgram.getMemory().getBytes(r.getToAddress(),bytes);int k=0;while(k<len && bytes[k]>=32 && bytes[k]<127)k++;if(k>=5 && k<len && bytes[k]==0){x.put("ascii",new String(bytes,0,k,"US-ASCII"));refs.add(x);}}catch(Exception e){}
     }
    }
   }
   rec.put("calls",calls);rec.put("referenced_strings",refs);
   if(seeds.containsKey(a) || a==0x1401812b0L || a==0x1401805c0L){
    println("FOCUSED_DECOMPILE "+(++n)+" "+f.getEntryPoint());
    DecompileResults result=dec.decompileFunction(f,45,monitor);rec.put("decompile_completed",result.decompileCompleted());rec.put("decompile_error",result.getErrorMessage());
    if(result.getDecompiledFunction()!=null)Files.writeString(out.resolve("pseudocode").resolve(Long.toHexString(a)+".c"),result.getDecompiledFunction().getC());
    Files.writeString(out.resolve("pseudocode").resolve(Long.toHexString(a)+".asm.txt"),asm.toString());
   }
   records.add(rec);
  }
  dec.dispose();
  Map<String,Object> result=new LinkedHashMap<>();result.put("profile","Ghidra 12.1.4 PE import -noanalysis; exact .pdata-bounded seed disassembly; decoded E8 rel32 direct calls and RIP-relative LEA/MOV ASCII references explicitly marked; one direct-call expansion; no auto-analysis, demangler, PDB, RTTI or whole-program call graph; decompiler timeout 45s per seed");result.put("program",currentProgram.getExecutablePath());result.put("sha256",currentProgram.getExecutableSHA256());result.put("seed_count",seeds.size());result.put("selected_count",selected.size());result.put("functions",records);
  Files.writeString(out.resolve(args.length>3?args[3]:"focused-functions.json"),new GsonBuilder().setPrettyPrinting().create().toJson(result));
  println("FOCUSED_DONE functions "+records.size());
 }
}
