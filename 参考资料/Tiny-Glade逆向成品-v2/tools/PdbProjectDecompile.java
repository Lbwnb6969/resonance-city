// Bounded export of all procedures with retained private-project source lines.
// Requires existing matched-PDB callee boundaries in the private project.
// -postScript PdbProjectDecompile.java project_targets.tsv NEW_OUT [timeout]
// @category TinyGlade
import ghidra.app.script.GhidraScript;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.SourceType;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.io.*;
public class PdbProjectDecompile extends GhidraScript {
 public void run() throws Exception {
  String[] args=getScriptArgs();Path root=Path.of(args[1]);Files.createDirectory(root);
  int timeout=args.length>2?Integer.parseInt(args[2]):30;
  ArrayList<String[]> records=new ArrayList<>();
  for(String line:Files.readAllLines(Path.of(args[0]),StandardCharsets.UTF_8))records.add(line.split("\t",5));
  int prepared=0;
  for(String[] row:records) {
   Address entry=toAddr(row[0]);Address end=entry.add(Long.parseLong(row[1])-1);AddressSet body=new AddressSet(entry,end);
   ArrayList<Address> interiors=new ArrayList<>();FunctionIterator it=currentProgram.getFunctionManager().getFunctions(body,true);
   while(it.hasNext()){Function f=it.next();if(!f.getEntryPoint().equals(entry))interiors.add(f.getEntryPoint());}
   for(Address a:interiors)currentProgram.getFunctionManager().removeFunction(a);
   clearListing(entry,end);new DisassembleCommand(entry,body,true).applyTo(currentProgram,monitor);
   Function f=getFunctionAt(entry);
   if(f==null)f=currentProgram.getFunctionManager().createFunction("pdb_"+row[0].substring(2),entry,body,SourceType.USER_DEFINED);
   else f.setBody(body);
   f.setComment("Matched PDB project procedure: "+row[2]+"\nSource attribution: "+row[4]+"\nExtent: "+row[1]);
   prepared++;if(prepared%250==0)println("PROJECT_PREPARED "+prepared+"/"+records.size());
  }
  DecompInterface decompiler=new DecompInterface();decompiler.toggleSyntaxTree(false);decompiler.openProgram(currentProgram);
  int done=0,flowClean=0,limited=0,failed=0;
  try(BufferedWriter status=Files.newBufferedWriter(root.resolve("status.tsv"),StandardCharsets.UTF_8,StandardOpenOption.CREATE_NEW)) {
   status.write("va\tcrate\tstatus\tfile\tdiagnostic\n");
   for(String[] row:records) {
    Function f=getFunctionAt(toAddr(row[0]));DecompileResults r=decompiler.decompileFunction(f,timeout,monitor);
    String diag=r.getErrorMessage().replace('\n',' ').replace('\t',' ');String filename="",quality="failed";
    if(r.decompileCompleted() && r.getDecompiledFunction()!=null) {
     String c=r.getDecompiledFunction().getC();
     boolean invalid=c.contains("Control flow encountered bad") || c.contains("overlaps instruction") || c.contains("Could not recover jumptable") || c.contains("UNRECOVERED_JUMPTABLE") || c.contains("halt_baddata") || c.contains("Unable to resolve constructor");
     quality=invalid?"limited-flow":"no-explicit-flow-error";
     if(invalid)limited++;else flowClean++;
     filename=quality+"/"+row[3].replaceAll("[^a-zA-Z0-9_/-]","_")+"/"+row[0]+".c";
     Path output=root.resolve(filename);Files.createDirectories(output.getParent());
     String header="// VA "+row[0]+", PDB extent "+row[1]+" bytes\n// "+row[2]+"\n// PDB source attribution: "+row[4]+"\n// Ghidra pseudocode; missing Rust signatures/types. Not standalone source or behavior verification.\n";
     Files.writeString(output,header+c,StandardCharsets.UTF_8,StandardOpenOption.CREATE_NEW);
    } else failed++;
    status.write(row[0]+"\t"+row[3]+"\t"+quality+"\t"+filename+"\t"+diag+"\n");status.flush();done++;
    if(done%50==0){println("PROJECT_DECOMPILED "+done+"/"+records.size()+" clean-flow="+flowClean+" limited="+limited+" failed="+failed);decompiler.flushCache();}
   }
  } finally {decompiler.dispose();}
  Files.writeString(root.resolve("completion.txt"),"procedures="+done+"\nno-explicit-flow-error="+flowClean+"\nlimited-flow="+limited+"\nfailed="+failed+"\n",StandardOpenOption.CREATE_NEW);
  println("PROJECT_EXPORT_COMPLETE "+done);
 }
}
