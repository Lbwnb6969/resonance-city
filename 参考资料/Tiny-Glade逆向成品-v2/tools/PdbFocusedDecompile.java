// Focused native decompilation with independently matched PDB procedure extents.
// Run analyzeHeadless PROJECT_DIR NAME -import EXE -noanalysis -scriptPath TOOLS
//     -postScript PdbFocusedDecompile.java targets.tsv NEW_OUTPUT_DIRECTORY [all-entry-seeds.tsv]
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

public class PdbFocusedDecompile extends GhidraScript {
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 2 || args.length > 3) throw new IllegalArgumentException("targets.tsv output-directory [all-entry-seeds.tsv]");
        Path output = Path.of(args[1]);
        Files.createDirectories(output);
        List<String[]> records = new ArrayList<>();
        for (String line : Files.readAllLines(Path.of(args[0]), StandardCharsets.UTF_8)) {
            if (line.isBlank() || line.startsWith("#")) continue;
            records.add(line.split("\t", 3));
        }
        if (args.length == 3) {
            // Reset only this private project's function metadata. Single-address
            // callee boundaries prevent the decompiler from absorbing tailcalls.
            List<Address> priorEntries = new ArrayList<>();
            FunctionIterator prior = currentProgram.getFunctionManager().getFunctions(true);
            while (prior.hasNext()) priorEntries.add(prior.next().getEntryPoint());
            for (Address entry : priorEntries) currentProgram.getFunctionManager().removeFunction(entry);
            int seeded = 0;
            for (String line : Files.readAllLines(Path.of(args[2]), StandardCharsets.UTF_8)) {
                if (line.isBlank() || line.startsWith("#")) continue;
                String[] row = line.split("\t", 2);
                Address entry = toAddr(row[0]);
                Function seed = currentProgram.getFunctionManager().createFunction(
                    "pdb_" + row[0].replace("0x", ""), entry, new AddressSet(entry), SourceType.USER_DEFINED);
                seed.setComment("Matched PDB callee boundary: " + row[1] + ". Body not analyzed.");
                seeded++;
            }
            println("PDB_SEEDED " + seeded);
        }
        // Install every selected function before decompiling callers.
        for (String[] row : records) {
            Address start = toAddr(row[0]);
            long size = Long.parseLong(row[1]);
            AddressSet body = new AddressSet(start, start.add(size - 1));
            // PE unwind metadata can introduce interior one-address functions.
            // Matched PDB extents are nonoverlapping; replace only interior
            // analysis annotations in this private project, never file bytes.
            List<Address> interior = new ArrayList<>();
            FunctionIterator existing = currentProgram.getFunctionManager().getFunctions(body, true);
            while (existing.hasNext()) {
                Function prior = existing.next();
                if (!prior.getEntryPoint().equals(start)) interior.add(prior.getEntryPoint());
            }
            for (Address entry : interior) currentProgram.getFunctionManager().removeFunction(entry);
            new DisassembleCommand(start, body, true).applyTo(currentProgram, monitor);
            Function f = getFunctionAt(start);
            String name = "pdb_" + row[0].replace("0x", "");
            if (f == null) f = createFunction(start, name);
            if (f != null) {
                f.setBody(body);
                f.setName(name, SourceType.USER_DEFINED);
                f.setComment("Matched PDB: " + row[2] + "\nExtent: " + size + " bytes. No whole-program auto-analysis.");
            }
        }
        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);
        List<String> statuses = new ArrayList<>();
        for (String[] row : records) {
            Address address = toAddr(row[0]);
            Function f = getFunctionAt(address);
            if (f == null) {
                statuses.add(row[0] + "\tunavailable\tfunction creation failed");
                continue;
            }
            DecompileResults result = decompiler.decompileFunction(f, 90, monitor);
            if (result.decompileCompleted() && result.getDecompiledFunction() != null) {
                String text = "// Matched PDB: " + row[2] + "\n// VA " + row[0] + ", PDB extent " + row[1] + " bytes\n"
                    + "// Ghidra pseudocode; types and unresolved calls are not original source.\n"
                    + result.getDecompiledFunction().getC();
                Files.writeString(output.resolve(row[0] + ".c"), text, StandardCharsets.UTF_8,
                    StandardOpenOption.CREATE_NEW);
                statuses.add(row[0] + "\tdecompiled\t" + result.getErrorMessage().replace('\n', ' '));
            } else statuses.add(row[0] + "\tfailed\t" + result.getErrorMessage().replace('\n', ' '));
            println("PDB_FOCUSED " + row[0] + " " + result.decompileCompleted());
        }
        decompiler.dispose();
        Files.write(output.resolve("status.tsv"), statuses, StandardCharsets.UTF_8, StandardOpenOption.CREATE_NEW);
    }
}
