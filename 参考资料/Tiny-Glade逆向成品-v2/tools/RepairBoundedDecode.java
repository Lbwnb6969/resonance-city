// @category TinyGlade
import ghidra.app.script.GhidraScript;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import java.nio.file.*;
import java.util.*;
public class RepairBoundedDecode extends GhidraScript {
 public void run() throws Exception {
  ArrayList<String> rows=new ArrayList<>();
  for(String line:Files.readAllLines(Path.of(getScriptArgs()[0]))) {
   String[] a=line.split("\t",3);Address start=toAddr(a[0]);Address end=start.add(Long.parseLong(a[1])-1);
   CodeUnit unit=currentProgram.getListing().getCodeUnitAt(start);AddressSet body=new AddressSet(start,end);
   rows.add(start+" before="+unit+" containing="+currentProgram.getListing().getCodeUnitContaining(start));
   clearListing(start,end);DisassembleCommand cmd=new DisassembleCommand(start,body,true);
   boolean ok=cmd.applyTo(currentProgram,monitor);int bytes=0,n=0;
   InstructionIterator it=currentProgram.getListing().getInstructions(body,true);
   while(it.hasNext()){Instruction ins=it.next();bytes+=ins.getLength();n++;}
   rows.add(start+" ok="+ok+" bytes="+bytes+" extent="+a[1]+" instructions="+n+" status="+cmd.getStatusMsg());
  }
  Files.write(Path.of(getScriptArgs()[1]),rows);println("REPAIRED_BOUNDED_DECODE "+rows.size()/2);
 }
}
