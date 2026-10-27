// @category TinyGlade
import ghidra.app.script.GhidraScript;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import java.nio.file.*;
public class PrepareCalleeBodies extends GhidraScript {
 public void run() throws Exception {
  int count=0;
  for(String line:Files.readAllLines(Path.of(getScriptArgs()[0]))) {
   String[] row=line.split("\t",3);Address entry=toAddr(row[0]);AddressSet body=new AddressSet(entry,entry.add(Long.parseLong(row[1])-1));
   Function f=getFunctionAt(entry);if(f==null)continue;
   java.util.List<Address> remove=new java.util.ArrayList<>();FunctionIterator it=currentProgram.getFunctionManager().getFunctions(body,true);
   while(it.hasNext()){Function other=it.next();if(other!=f)remove.add(other.getEntryPoint());}
   for(Address a:remove)currentProgram.getFunctionManager().removeFunction(a);
   new DisassembleCommand(entry,body,true).applyTo(currentProgram,monitor);f.setBody(body);count++;
  }
  for(FunctionIterator it=currentProgram.getFunctionManager().getFunctions(true);it.hasNext();) {
   Function f=it.next();String c=f.getComment();
   if(c!=null && (c.contains("core::panicking::panic") || c.contains("core::option::unwrap_failed") || c.contains("core::result::unwrap_failed") || c.contains("alloc::alloc::handle_alloc_error")))f.setNoReturn(true);
  }
  println("CALLEE_BODIES_PREPARED "+count);
 }
}
