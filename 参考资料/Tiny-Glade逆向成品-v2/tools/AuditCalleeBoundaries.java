// @category TinyGlade
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import java.nio.file.*;
import java.util.*;
public class AuditCalleeBoundaries extends GhidraScript {
 public void run() throws Exception {
  ArrayList<String> rows=new ArrayList<>();
  rows.add("language="+currentProgram.getLanguageID()+" compiler="+currentProgram.getCompilerSpec().getCompilerSpecID());
  int calls=0,missing=0;
  for(String line:Files.readAllLines(Path.of(getScriptArgs()[0]))) {
   String[] a=line.split("\t",3);Address start=toAddr(a[0]);AddressSet body=new AddressSet(start,start.add(Long.parseLong(a[1])-1));
   InstructionIterator it=currentProgram.getListing().getInstructions(body,true);
   while(it.hasNext()) {
    Instruction ins=it.next();if(!ins.getFlowType().isCall())continue;
    for(Address target:ins.getFlows()) {
     calls++;Function f=getFunctionAt(target);Instruction ci=getInstructionAt(target);Function containing=getFunctionContaining(target);
     if(f==null) {missing++;rows.add(ins.getAddress()+" CALL "+target+" NO_FUNCTION containing="+(containing==null?"none":containing.getEntryPoint()));}
     else if(ci==null)rows.add(ins.getAddress()+" CALL "+target+" NO_INSTRUCTION function="+f.getName()+" body="+f.getBody());
    }
   }
  }
  for(String s:new String[]{"0x14192d290","0x14192c990","0x14192d30f","0x14192d310"}) {
   Address a=toAddr(s);Function f=getFunctionAt(a),c=getFunctionContaining(a);Instruction i=getInstructionAt(a);
   rows.add(s+" function="+(f==null?"none":f.getName()+" "+f.getBody())+" containing="+(c==null?"none":c.getName()+" "+c.getBody())+" ins="+i);
  }
  rows.add("calls="+calls+" missing="+missing);Files.write(Path.of(getScriptArgs()[1]),rows);
  for(String r:rows)println(r);
 }
}
