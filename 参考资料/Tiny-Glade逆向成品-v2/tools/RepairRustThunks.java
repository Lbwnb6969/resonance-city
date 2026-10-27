// Repair missing public-only Rust allocator thunks in a private Ghidra project.
// @category TinyGlade
import ghidra.app.script.GhidraScript;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.SourceType;
import ghidra.program.model.data.*;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class RepairRustThunks extends GhidraScript {
    private void allocator(String address, int count, boolean pointerResult) throws Exception {
        Function f = getFunctionAt(toAddr(address));
        if (f == null) return;
        Function target = f.isThunk() ? f.getThunkedFunction(true) : f;
        DataType pointer = new PointerDataType(ByteDataType.dataType);
        Parameter[] params = new Parameter[count];
        for (int i = 0; i < count; i++) {
            DataType type = (!pointerResult && i == 0) || count == 4 && i == 0 ? pointer : UnsignedLongLongDataType.dataType;
            params[i] = new ParameterImpl("arg" + i, type, currentProgram);
        }
        target.setCallingConvention("__cdecl");
        target.setReturnType(pointerResult ? pointer : VoidDataType.dataType, SourceType.USER_DEFINED);
        target.replaceParameters(Function.FunctionUpdateType.DYNAMIC_STORAGE_ALL_PARAMS, true, SourceType.USER_DEFINED, params);
        target.setNoReturn(false);
        f.setNoReturn(false);
    }
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length != 3) throw new IllegalArgumentException("public-seeds.tsv targets.tsv new-output-directory");
        Path out = Path.of(args[2]); Files.createDirectories(out);
        int added = 0, thunks = 0;
        List<Address> entries = new ArrayList<>();
        for (String line : Files.readAllLines(Path.of(args[0]), StandardCharsets.UTF_8)) {
            String[] row = line.split("\t", 2);
            Address address = toAddr(row[0]);
            Function f = getFunctionAt(address);
            if (f == null) {
                new DisassembleCommand(address, new AddressSet(address, address.add(15)), true).applyTo(currentProgram, monitor);
                Instruction ins = getInstructionAt(address);
                Address end = ins == null ? address : address.add(ins.getLength() - 1);
                f = currentProgram.getFunctionManager().createFunction("pub_" + row[0].replace("0x", ""),
                    address, new AddressSet(address, end), SourceType.USER_DEFINED);
                f.setComment("PDB public code flag: " + row[1] + ". Instruction-only extent, not a recovered full body.");
                added++;
            }
            entries.add(address);
        }
        for (Address address : entries) {
            Instruction ins = getInstructionAt(address);
            Function f = getFunctionAt(address);
            if (ins != null && ins.getMnemonicString().equalsIgnoreCase("JMP") && ins.getFlows().length == 1) {
                Function target = getFunctionAt(ins.getFlows()[0]);
                if (target != null && target != f) { f.setThunkedFunction(target); thunks++; }
            }
        }
        allocator("0x1406abab0", 2, true);
        allocator("0x1406abac0", 3, false);
        allocator("0x1406abad0", 4, true);
        allocator("0x1406abae0", 2, true);
        List<String> diagnostics = new ArrayList<>();
        diagnostics.add("public-only functions added=" + added + "; thunks=" + thunks);
        DecompInterface dc = new DecompInterface(); dc.openProgram(currentProgram);
        for (String line : Files.readAllLines(Path.of(args[1]), StandardCharsets.UTF_8)) {
            if (line.isBlank()) continue;
            String[] row = line.split("\t", 3); Address address = toAddr(row[0]);
            Function f = getFunctionAt(address);
            diagnostics.add(row[0] + " body=" + f.getBody());
            DecompileResults r = dc.decompileFunction(f, 180, monitor);
            if (r.decompileCompleted() && r.getDecompiledFunction() != null) {
                Files.writeString(out.resolve(row[0] + ".c"), "// PDB " + row[2] + "\n" + r.getDecompiledFunction().getC(),
                    StandardCharsets.UTF_8, StandardOpenOption.CREATE_NEW);
            }
            diagnostics.add(row[0] + " completed=" + r.decompileCompleted() + " " + r.getErrorMessage());
            println("REPAIRED_DECOMPILE " + row[0] + " " + r.decompileCompleted());
        }
        dc.dispose();
        Files.write(out.resolve("diagnostics.txt"), diagnostics, StandardCharsets.UTF_8, StandardOpenOption.CREATE_NEW);
    }
}
