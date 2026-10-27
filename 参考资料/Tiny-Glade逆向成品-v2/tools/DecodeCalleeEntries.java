// @category TinyGlade
import ghidra.app.script.GhidraScript;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.program.model.address.*;
import java.nio.file.*;
public class DecodeCalleeEntries extends GhidraScript {
 public void run() throws Exception {
  int n=0;
  for(String a:Files.readAllLines(Path.of(getScriptArgs()[0]))) {
   Address entry=toAddr(a);
   if(getInstructionAt(entry)==null && currentProgram.getMemory().contains(entry)) {
    new DisassembleCommand(entry,new AddressSet(entry,entry.add(31)),true).applyTo(currentProgram,monitor);n++;
   }
  }
  println("CALLEE_ENTRIES_DECODED "+n);
 }
}
