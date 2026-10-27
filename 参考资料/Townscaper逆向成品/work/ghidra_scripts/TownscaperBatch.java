import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.listing.Function;
import ghidra.program.model.address.Address;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;

// Read-only export: manifest columns are hexadecimal RVA, descriptive alias.
// Every exact entry has a status; cached outputs are retained on resumed runs.
public class TownscaperBatch extends ghidra.app.script.GhidraScript {
    private String clean(String s) { return s.replace('\t', ' ').replace('\n', ' ').replace('\r', ' '); }
    @Override public void run() throws Exception {
        String[] args = getScriptArgs();
        Path manifest = Paths.get(args[0]), root = Paths.get(args[1]);
        Files.createDirectories(root);
        DecompInterface d = new DecompInterface();
        d.openProgram(currentProgram);
        int done = 0, failed = 0, cached = 0;
        try (BufferedWriter index = Files.newBufferedWriter(root.resolve("index.tsv"), StandardCharsets.UTF_8)) {
            index.write("rva\talias\tstatus\tentry\tpdb_name\tbody_bytes\tnoreturn\terror\n");
            for (String line : Files.readAllLines(manifest, StandardCharsets.UTF_8)) {
                if (line.isEmpty() || line.startsWith("#")) continue;
                String[] col = line.split("\t", 2);
                long rva = Long.parseLong(col[0].replace("0x", ""), 16);
                String hex = Long.toHexString(rva), alias = col.length > 1 ? col[1] : "";
                Address addr = currentProgram.getImageBase().add(rva);
                Function f = getFunctionAt(addr);
                if (f == null) {
                    index.write(hex + "\t" + clean(alias) + "\tno_exact_function\t" + addr + "\t\t\t\t\n");
                    failed++; continue;
                }
                Path out = root.resolve(hex + ".c");
                String prefix = hex + "\t" + clean(alias) + "\t";
                String suffix = "\t" + f.getEntryPoint() + "\t" + clean(f.getName()) + "\t" + f.getBody().getNumAddresses() + "\t" + f.hasNoReturn();
                if (Files.exists(out)) { cached++; index.write(prefix + "cached" + suffix + "\t\n"); continue; }
                DecompileResults result = d.decompileFunction(f, 45, monitor);
                if (result != null && result.decompileCompleted() && result.getDecompiledFunction() != null) {
                    StringBuilder content = new StringBuilder("// RVA 0x" + hex + " | " + clean(alias) + "\n// PDB: " + clean(f.getName()) + "\n// Body: " + f.getBody() + "\n// Direct callees:\n");
                    List<Function> callees = new ArrayList<>(f.getCalledFunctions(monitor));
                    callees.sort(Comparator.comparing(Function::getEntryPoint));
                    for (Function c : callees) content.append("// ").append(c.getEntryPoint()).append(" ").append(clean(c.getName())).append("\n");
                    content.append(result.getDecompiledFunction().getC());
                    Files.writeString(out, content.toString().replaceAll("(?m)[ \\t]+$", ""), StandardCharsets.UTF_8);
                    index.write(prefix + "decompiled" + suffix + "\t\n"); done++;
                } else {
                    String error = result == null ? "null result" : result.getErrorMessage();
                    index.write(prefix + "failed" + suffix + "\t" + clean(error) + "\n"); failed++;
                }
                index.flush();
                if ((done + failed + cached) % 100 == 0) println("EXPORT " + (done + failed + cached) + " done=" + done + " failed=" + failed + " cached=" + cached);
            }
        } finally { d.dispose(); }
        println("COMPLETE done=" + done + " failed=" + failed + " cached=" + cached);
    }
}
