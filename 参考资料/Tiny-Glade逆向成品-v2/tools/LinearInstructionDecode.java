// @category TinyGlade
import ghidra.app.script.GhidraScript;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import java.nio.file.*;
import java.util.*;
public class LinearInstructionDecode extends GhidraScript {
 public void run() throws Exception {
  ArrayList<String> records=new ArrayList<>();int matches=0;
  for(String line:Files.readAllLines(Path.of(getScriptArgs()[0]))) {
   String[] a=line.split("\t",3);Address start=toAddr(a[0]);int size=Integer.parseInt(a[1]);Address end=start.add(size-1);
   byte[] bytes=new byte[size];currentProgram.getMemory().getBytes(start,bytes);
   if(!HexFormat.of().formatHex(bytes).equals(a[2]))throw new IllegalArgumentException("Image bytes differ at "+start);
   Instruction old=getInstructionAt(start);
   if(old!=null && old.getLength()==size){matches++;continue;}
   clearListing(start,end);DisassembleCommand cmd=new DisassembleCommand(start,new AddressSet(start,end),false);
   boolean ok=cmd.applyTo(currentProgram,monitor);Instruction ins=getInstructionAt(start);
   if(ok && ins!=null && ins.getLength()==size)matches++;
   else records.add(start+" expected="+size+" instruction="+ins+" status="+cmd.getStatusMsg());
  }
  records.add("MATCHED "+matches);Files.write(Path.of(getScriptArgs()[1]),records);println("LINEAR_INSTRUCTION_MATCHED "+matches);
 }
}
