// @category TinyGlade
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.pcode.PcodeOp;
import java.util.*;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
public class AuditNativeDecode extends GhidraScript {
 public void run() throws Exception {
  List<String> lines=new ArrayList<>();
  for(String a: new String[]{"0x141921268","0x1406abac0","0x140f3c360","0x141920a00","0x141924120","0x141922052"}) {
   Address address=toAddr(a); Function f=getFunctionAt(address); Function containing=getFunctionContaining(address);
   lines.add(a+" function="+(f==null?"null":f.getName()+" "+f.getBody()+" noreturn="+f.hasNoReturn()+" thunk="+f.isThunk())+" containing="+(containing==null?"null":containing.getName()));
   Instruction i=getInstructionAt(address); if(i!=null){lines.add("instruction="+i+" flows="+Arrays.toString(i.getFlows())+" fall="+i.getFallThrough());for(PcodeOp op:i.getPcode())lines.add("pcode="+op);}
   byte[] b=new byte[24];currentProgram.getMemory().getBytes(address,b);lines.add("bytes="+HexFormat.of().formatHex(b));
  }
  Files.write(Path.of(getScriptArgs()[0]),lines,StandardCharsets.UTF_8,StandardOpenOption.CREATE_NEW);
  for(String line:lines)println(line);
 }
}
