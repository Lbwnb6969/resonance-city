import ghidra.program.model.data.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;

public class TownscaperTypes extends ghidra.app.script.GhidraScript {
  private String q(String s){return "\""+s.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n").replace("\r","\\r").replace("\t","\\t")+"\"";}
  @Override public void run() throws Exception {
    Set<String> selected=new HashSet<>(Arrays.asList("Graph","Corner","Voxel","Square","Qube","WorldMaster","GridGenerator","WaveFunctionCollapse","Maker","ModuleLibrary","Module","OrientedModule","ModuleContainer","ModuleBuilder","PossibleModule","PropPlacer","PropNode","PropCollider","BigMeshMaster","BigMeshPart","SaveData","SaveSystem","UiMaster","MasterClicker","FlyCamera","AoBaker","ShadowBaker","Palette","TextSaveSystem"));
    List<String> records=new ArrayList<>();
    Iterator<DataType> types=currentProgram.getDataTypeManager().getAllDataTypes();
    while(types.hasNext()) {
      DataType dt=types.next();
      String name=dt.getName();
      if(!(dt instanceof Structure) || !selected.contains(name.split("_t")[0]))continue;
      Structure s=(Structure)dt;
      List<String> fields=new ArrayList<>();
      for(DataTypeComponent c:s.getDefinedComponents())fields.add("{\"name\":"+q(c.getFieldName()==null?"":c.getFieldName())+",\"offset\":"+c.getOffset()+",\"length\":"+c.getLength()+",\"type\":"+q(c.getDataType().getName())+"}");
      records.add("{\"name\":"+q(name)+",\"path\":"+q(dt.getPathName())+",\"size\":"+s.getLength()+",\"fields\":["+String.join(",",fields)+"]}");
    }
    Collections.sort(records);
    Files.writeString(Paths.get(getScriptArgs()[0]),"{\"source\":\"Ghidra imported shipped PDB structure layouts; not runtime inspection or REA Evidence\",\"types\":["+String.join(",",records)+"]}\n",StandardCharsets.UTF_8);
    println("TYPE_EXPORT count="+records.size());
  }
}
