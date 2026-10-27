using Roma.Aqueduct;
using System.Text.Json;

// Controlled replay of the shipped pure managed solver. No Unity/game launch.
var results = new List<object>();
void Check(string name, float[] actual, float[] expected, object config)
{
    bool pass = actual.Zip(expected).All(p => Math.Abs(p.First - p.Second) < 0.0001f);
    results.Add(new { name, config, actual, expected, pass });
    if (!pass) throw new Exception(name + " failed");
}
AqueductFlowSolver Split(float supply, float da, float db, int pa, int pb, float minimumA = 0)
{
    var s = new AqueductFlowSolver();
    int src = s.AddNode(), a = s.AddNode(), b = s.AddNode();
    s.MarkSource(src, supply);
    s.MarkConsumer(a, da, pa, minimumA);
    s.MarkConsumer(b, db, pb);
    s.AddEdge(src, a, 100);
    s.AddEdge(src, b, 100);
    s.Solve();
    return s;
}
var eq = Split(10, 8, 8, 0, 0);
Check("same_priority_not_even_split", new[]{eq.GetServedAmount(1), eq.GetServedAmount(2)}, new[]{8f, 2f}, new {supply=10, demands=new[]{8,8}, priorities=new[]{0,0}});
var pri = Split(10, 8, 8, 0, 1);
Check("higher_priority_first", new[]{pri.GetServedAmount(1), pri.GetServedAmount(2)}, new[]{2f, 8f}, new {supply=10, demands=new[]{8,8}, priorities=new[]{0,1}});
var min = Split(5, 8, 5, 1, 0, 6);
Check("minimum_service_rolls_back", new[]{min.GetServedAmount(1), min.GetServedAmount(2), min.WasRolledBack(1)?1f:0f}, new[]{0f,5f,1f}, new {supply=5, demands=new[]{8,5}, minimumA=6, priorities=new[]{1,0}});
var edge = new AqueductFlowSolver();
edge.AddNode(); edge.AddNode(); edge.MarkSource(0, 10); edge.MarkConsumer(1, 10); edge.AddEdge(0,1,3); edge.Solve();
Check("edge_capacity_limits_delivery", new[]{edge.GetServedAmount(1),edge.GetSourceExtraction(0)},new[]{3f,3f},new {supply=10,demand=10,edgeCapacity=3});
Console.WriteLine(JsonSerializer.Serialize(new {kind="controlled-replay", target="Roma.Aqueduct.dll", targetSha256="09efb91699b31eb3d07737f6f176ac2302217a727e104fc98efac82f02e1e485",runtime=System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription, cases=results},new JsonSerializerOptions{WriteIndented=true}));
