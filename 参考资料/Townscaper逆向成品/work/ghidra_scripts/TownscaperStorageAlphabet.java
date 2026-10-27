import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.util.task.ConsoleTaskMonitor;
import ghidra.util.task.TaskMonitor;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Set;

public class TownscaperStorageAlphabet extends ghidra.app.script.GhidraScript {
    private static final long[][] TARGETS = new long[][] {
        {0x3015a0L, 0}, {0x110bab0L, 1}, {0x1142570L, 2},
        {0x1142fb0L, 3}, {0x1142c00L, 4}
    };
    private static final String[] NAMES = new String[] {
        "TextSaveAlphabet_cctor", "BasePlatformSDK_Storage",
        "StandalonePCPlatformSDK_CreateContainer", "StandalonePCStorageContainer_ctor",
        "StandalonePCStorageContainer_GetFilePath"
    };

    @Override
    public void run() throws Exception {
        String outPath = getScriptArgs().length > 0 ? getScriptArgs()[0] : "townscaper_ghidra_decompile.md";
        DecompInterface decomp = new DecompInterface();
        decomp.setSimplificationStyle("decompile");
        decomp.openProgram(currentProgram);
        TaskMonitor monitor = new ConsoleTaskMonitor();
        try (BufferedWriter out = new BufferedWriter(new FileWriter(new File(outPath)))) {
            out.write("# Townscaper Ghidra decompilation\n\n");
            out.write("- Program: " + currentProgram.getDomainFile().getPathname() + "\n");
            out.write("- Image base: " + currentProgram.getImageBase() + "\n\n");
            for (int i = 0; i < TARGETS.length; i++) {
                long rva = TARGETS[i][0];
                Address address = currentProgram.getImageBase().add(rva);
                Function function = getFunctionAt(address);
                if (function == null) {
                    function = getFunctionContaining(address);
                }
                out.write("## " + NAMES[i] + " (RVA 0x" + Long.toHexString(rva) + ")\n\n");
                out.write("- Address: `" + address + "`\n");
                if (function == null) {
                    out.write("- Function: unresolved by Ghidra at this address.\n\n");
                    continue;
                }
                out.write("- Function: `" + function.getName() + "`\n");
                out.write("- Body: `" + function.getBody() + "`\n");
                out.write("- Called functions:\n");
                try {
                    Set<Function> called = function.getCalledFunctions(monitor);
                    for (Function callee : called) out.write("  - `" + callee.getName() + "` at `" + callee.getEntryPoint() + "`\n");
                } catch (Exception e) {
                    out.write("  - unavailable: " + e.getMessage() + "\n");
                }
                DecompileResults result = decomp.decompileFunction(function, 45, monitor);
                if (result != null && result.decompileCompleted() && result.getDecompiledFunction() != null) {
                    out.write("\n```c\n");
                    out.write(result.getDecompiledFunction().getC());
                    out.write("\n```\n\n");
                } else {
                    out.write("\nDecompiler status: `" + (result == null ? "null" : result.getErrorMessage()) + "`\n\n");
                }
            }
        } finally {
            decomp.dispose();
        }
    }
}
