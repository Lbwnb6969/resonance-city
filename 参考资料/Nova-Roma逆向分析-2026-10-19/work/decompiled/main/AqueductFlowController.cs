using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System.Text;
using Roma.Aqueduct;
using UnityEngine;

public static class AqueductFlowController
{
	private struct GroupEdge
	{
		public int edgeId;

		public float target;

		public BathReservoir res;
	}

	private sealed class WaterFillState
	{
		public BathManager.BathGroup grp;

		public int node;

		public List<GroupEdge> edges;

		public float achievable;

		public float maintainPerRes;

		public int activeCount;

		public float frozenTotal;

		public float activeBoost;

		public readonly List<bool> frozen = new List<bool>(8);

		public readonly List<float> delivered = new List<float>(8);

		public float servedAtRead;
	}

	private const float EPSILON = 1E-06f;

	private static readonly float GROUP_EDGE_CAP = AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS * 8f;

	private static readonly AqueductFlowSolver core = new AqueductFlowSolver();

	private static bool topologyDirty = true;

	private static bool demandDirty = true;

	private static bool hasSolved = false;

	private static readonly Dictionary<AqueductBuilding, int> nodeOf = new Dictionary<AqueductBuilding, int>(64);

	private static readonly Dictionary<AqueductLine, int> edgeOf = new Dictionary<AqueductLine, int>(128);

	private static readonly List<AqueductBuilding> flushOrder = new List<AqueductBuilding>(64);

	private static readonly Dictionary<BathManager.BathGroup, int> groupNodeOf = new Dictionary<BathManager.BathGroup, int>(32);

	private static readonly Dictionary<BathManager.BathGroup, List<GroupEdge>> groupEdges = new Dictionary<BathManager.BathGroup, List<GroupEdge>>(32);

	private static readonly Stack<List<GroupEdge>> edgeListPool = new Stack<List<GroupEdge>>(16);

	private static readonly Dictionary<BathManager.BathGroup, float> groupAchievable = new Dictionary<BathManager.BathGroup, float>(32);

	private const int MAX_WATERFILL_ROUNDS = 16;

	private const float WATERFILL_EPSILON = 0.5f;

	private static readonly List<WaterFillState> waterFillPool = new List<WaterFillState>(8);

	private static int waterFillUsed = 0;

	private static readonly Dictionary<AqueductLine, float> prevLineFlow = new Dictionary<AqueductLine, float>(128);

	public static IReadOnlyList<AqueductBuilding> KnownBuildings => flushOrder;

	public static void MarkTopologyDirty([CallerMemberName] string caller = null)
	{
		topologyDirty = true;
		demandDirty = true;
		AqueductFlowDiagnostics.MarkedDirty("topology", caller);
	}

	public static void MarkDemandDirty([CallerMemberName] string caller = null)
	{
		demandDirty = true;
		AqueductFlowDiagnostics.MarkedDirty("demand", caller);
	}

	public static void Reset()
	{
		topologyDirty = true;
		demandDirty = true;
		hasSolved = false;
		nodeOf.Clear();
		edgeOf.Clear();
		flushOrder.Clear();
		groupNodeOf.Clear();
		groupAchievable.Clear();
		ClearGroupEdges();
		core.Clear();
	}

	public static void RefreshForLoad()
	{
		List<AqueductLine> allLines = AqueductLine.allLines;
		HashSet<AqueductBuilding> seeded = new HashSet<AqueductBuilding>();
		for (int i = 0; i < allLines.Count; i++)
		{
			AqueductLine aqueductLine = allLines[i];
			if (!(aqueductLine == null) && !aqueductLine.displayOnly && aqueductLine.fullyConstructed)
			{
				TrySeedSource(aqueductLine.GetStartBuilding(), seeded);
				TrySeedSource(aqueductLine.GetEndBuilding(), seeded);
			}
		}
		Rebuild();
		core.SolveWithConduitDetection();
		SnapshotGroupAchievable();
		hasSolved = true;
		DeriveRatios();
	}

	private static void SnapshotGroupAchievable()
	{
		groupAchievable.Clear();
		foreach (KeyValuePair<BathManager.BathGroup, int> item in groupNodeOf)
		{
			groupAchievable[item.Key] = core.GetServedAmount(item.Value);
		}
	}

	private static void TrySeedSource(AqueductBuilding b, HashSet<AqueductBuilding> seeded)
	{
		if (!(b == null) && seeded.Add(b) && b is RiverTap riverTap)
		{
			riverTap.SeedCapacityFromWorld();
		}
	}

	public static void SolveIfDirtyAndFlush()
	{
		if (LoadSave.Loading || (!topologyDirty && !demandDirty))
		{
			return;
		}
		bool enabled = AqueductFlowDiagnostics.Enabled;
		if (enabled)
		{
			SnapshotLineFlows();
		}
		Rebuild();
		core.SolveWithConduitDetection();
		SnapshotGroupAchievable();
		WaterFillBathGroups();
		hasSolved = true;
		topologyDirty = false;
		demandDirty = false;
		if (enabled)
		{
			try
			{
				AqueductFlowDiagnostics.SolveBlock(BuildDiagnosticsBlock());
			}
			catch (Exception ex)
			{
				Debug.LogWarning("Aqueduct diagnostics failed: " + ex.Message);
			}
		}
		DeriveRatios();
		Flush();
	}

	private static void DeriveRatios()
	{
		foreach (KeyValuePair<AqueductBuilding, int> item in nodeOf)
		{
			AqueductBuilding key = item.Key;
			if (key == null || key.aqueductLines == null)
			{
				continue;
			}
			List<AqueductLine> aqueductLines = key.aqueductLines;
			float num = 0f;
			for (int i = 0; i < aqueductLines.Count; i++)
			{
				AqueductLine aqueductLine = aqueductLines[i];
				if (!(aqueductLine == null) && aqueductLine.IsSendingWaterTo(key) && edgeOf.TryGetValue(aqueductLine, out var value))
				{
					num += core.GetEdgeFlow(value);
				}
			}
			if (num <= 1E-06f)
			{
				continue;
			}
			for (int j = 0; j < aqueductLines.Count; j++)
			{
				AqueductLine aqueductLine2 = aqueductLines[j];
				if (!(aqueductLine2 == null) && aqueductLine2.IsSendingWaterTo(key) && edgeOf.TryGetValue(aqueductLine2, out var value2))
				{
					aqueductLine2.valveRatio = core.GetEdgeFlow(value2) / num;
				}
			}
		}
	}

	private static void Rebuild()
	{
		nodeOf.Clear();
		edgeOf.Clear();
		flushOrder.Clear();
		groupNodeOf.Clear();
		ClearGroupEdges();
		core.Clear();
		List<AqueductLine> allLines = AqueductLine.allLines;
		for (int i = 0; i < allLines.Count; i++)
		{
			AqueductLine aqueductLine = allLines[i];
			if (!(aqueductLine == null) && !aqueductLine.displayOnly && aqueductLine.fullyConstructed)
			{
				AqueductBuilding startBuilding = aqueductLine.GetStartBuilding();
				AqueductBuilding endBuilding = aqueductLine.GetEndBuilding();
				if (!(startBuilding == null) && !(endBuilding == null))
				{
					EnsureNode(startBuilding);
					EnsureNode(endBuilding);
				}
			}
		}
		for (int j = 0; j < allLines.Count; j++)
		{
			AqueductLine aqueductLine2 = allLines[j];
			if (!(aqueductLine2 == null) && !aqueductLine2.displayOnly && aqueductLine2.fullyConstructed)
			{
				AqueductBuilding startBuilding2 = aqueductLine2.GetStartBuilding();
				AqueductBuilding endBuilding2 = aqueductLine2.GetEndBuilding();
				if (!(startBuilding2 == null) && !(endBuilding2 == null) && nodeOf.TryGetValue(startBuilding2, out var value) && nodeOf.TryGetValue(endBuilding2, out var value2))
				{
					edgeOf[aqueductLine2] = core.AddEdge(value, value2, AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
				}
			}
		}
		foreach (KeyValuePair<AqueductBuilding, int> item in nodeOf)
		{
			AqueductBuilding key = item.Key;
			int value3 = item.Value;
			if (key is RiverTap)
			{
				core.MarkSource(value3, Mathf.Max(0f, key.SourceCapacity()));
			}
			if (key.solverDemand > 0f)
			{
				core.MarkConsumer(value3, key.solverDemand, key.solverPriority, key.solverMinServe);
			}
			flushOrder.Add(key);
		}
		BuildBathGroupConsumers();
	}

	private static void EnsureNode(AqueductBuilding b)
	{
		if (!nodeOf.ContainsKey(b))
		{
			nodeOf[b] = core.AddNode();
		}
	}

	private static void BuildBathGroupConsumers()
	{
		foreach (KeyValuePair<AqueductBuilding, int> item in nodeOf)
		{
			if (!(item.Key is BathReservoir bathReservoir) || !bathReservoir.ParticipatesInComplexWater())
			{
				continue;
			}
			BathManager.BathGroup bathGroup = bathReservoir.Group;
			if (bathGroup != null && !(bathGroup.solverDemand <= 1E-06f))
			{
				if (!groupNodeOf.TryGetValue(bathGroup, out var value))
				{
					value = core.AddNode();
					core.MarkConsumer(value, bathGroup.solverDemand, bathGroup.solverPriority, bathGroup.solverMinServe);
					groupNodeOf[bathGroup] = value;
					groupEdges[bathGroup] = RentEdgeList();
				}
				float capacity = ((bathGroup.wConsumption <= 0f) ? bathReservoir.bandTarget : GROUP_EDGE_CAP);
				int edgeId = core.AddEdge(item.Value, value, capacity);
				groupEdges[bathGroup].Add(new GroupEdge
				{
					edgeId = edgeId,
					target = bathReservoir.bandTarget,
					res = bathReservoir
				});
			}
		}
	}

	private static void ClearGroupEdges()
	{
		foreach (List<GroupEdge> value in groupEdges.Values)
		{
			value.Clear();
			edgeListPool.Push(value);
		}
		groupEdges.Clear();
	}

	private static List<GroupEdge> RentEdgeList()
	{
		if (edgeListPool.Count <= 0)
		{
			return new List<GroupEdge>(4);
		}
		return edgeListPool.Pop();
	}

	private static void WaterFillBathGroups()
	{
		waterFillUsed = 0;
		foreach (KeyValuePair<BathManager.BathGroup, List<GroupEdge>> groupEdge in groupEdges)
		{
			List<GroupEdge> value = groupEdge.Value;
			if (value.Count < 2 || !groupNodeOf.TryGetValue(groupEdge.Key, out var value2) || groupEdge.Key.solverMinServe > 1E-06f)
			{
				continue;
			}
			BathManager.BathGroup key = groupEdge.Key;
			WaterFillState waterFillState = RentWaterFillState();
			waterFillState.grp = key;
			waterFillState.node = value2;
			waterFillState.edges = value;
			if (AqueductFlowDiagnostics.Enabled)
			{
				StringBuilder stringBuilder = new StringBuilder(128);
				stringBuilder.Append("wf group#").Append(key.id).Append(" edges:");
				for (int i = 0; i < value.Count; i++)
				{
					stringBuilder.Append(" [").Append(i).Append(" id=")
						.Append(value[i].edgeId)
						.Append(' ')
						.Append((value[i].res != null) ? BName(value[i].res) : "?")
						.Append(" t=")
						.Append(value[i].target.ToString("F0"))
						.Append(']');
				}
				AqueductFlowDiagnostics.Note(stringBuilder.ToString());
			}
			waterFillState.achievable = core.GetServedAmount(value2);
			waterFillState.maintainPerRes = ((key.contributingReservoirs > 0) ? (key.wConsumption / (float)key.contributingReservoirs) : 0f);
			waterFillState.activeCount = value.Count;
			waterFillState.frozenTotal = 0f;
			waterFillState.activeBoost = 0f;
			waterFillState.frozen.Clear();
			for (int j = 0; j < value.Count; j++)
			{
				waterFillState.frozen.Add(item: false);
				waterFillState.activeBoost += Mathf.Max(0f, value[j].target - waterFillState.maintainPerRes);
			}
		}
		if (waterFillUsed == 0)
		{
			return;
		}
		int num = 0;
		bool flag = true;
		while (flag && num < 16)
		{
			flag = false;
			num++;
			for (int k = 0; k < waterFillUsed; k++)
			{
				WaterFillState waterFillState2 = waterFillPool[k];
				if (waterFillState2.activeCount <= 0)
				{
					continue;
				}
				StringBuilder stringBuilder2 = (AqueductFlowDiagnostics.Enabled ? new StringBuilder(96) : null);
				for (int l = 0; l < waterFillState2.edges.Count; l++)
				{
					if (!waterFillState2.frozen[l])
					{
						float capacity = TieredCap(waterFillState2, waterFillState2.edges[l].target);
						core.SetEdgeCapacity(waterFillState2.edges[l].edgeId, capacity);
						stringBuilder2?.Append(" e").Append(l).Append("=")
							.Append(capacity.ToString("F1"));
					}
				}
				if (stringBuilder2 != null)
				{
					AqueductFlowDiagnostics.Note($"wf group#{((waterFillState2.grp != null) ? waterFillState2.grp.id : (-1))} r{num} set-caps{stringBuilder2}");
				}
			}
			core.Solve();
			for (int m = 0; m < waterFillUsed; m++)
			{
				WaterFillState waterFillState3 = waterFillPool[m];
				waterFillState3.delivered.Clear();
				for (int n = 0; n < waterFillState3.edges.Count; n++)
				{
					waterFillState3.delivered.Add(waterFillState3.frozen[n] ? 0f : core.GetEdgeFlow(waterFillState3.edges[n].edgeId));
				}
				waterFillState3.servedAtRead = core.GetServedAmount(waterFillState3.node);
			}
			for (int num2 = 0; num2 < waterFillUsed; num2++)
			{
				WaterFillState waterFillState4 = waterFillPool[num2];
				if (waterFillState4.activeCount <= 0)
				{
					continue;
				}
				StringBuilder stringBuilder3 = (AqueductFlowDiagnostics.Enabled ? new StringBuilder(128) : null);
				for (int num3 = 0; num3 < waterFillState4.edges.Count; num3++)
				{
					if (waterFillState4.frozen[num3])
					{
						stringBuilder3?.Append(" [").Append(num3).Append(" frozen]");
						continue;
					}
					float num4 = TieredCap(waterFillState4, waterFillState4.edges[num3].target);
					float num5 = waterFillState4.delivered[num3];
					bool flag2 = num5 < num4 - 0.5f;
					stringBuilder3?.Append(" [").Append(num3).Append(" t=")
						.Append(waterFillState4.edges[num3].target.ToString("F0"))
						.Append(" cap=")
						.Append(num4.ToString("F0"))
						.Append(" coreCap=")
						.Append(core.GetEdgeCapacityInput(waterFillState4.edges[num3].edgeId).ToString("F1"))
						.Append(" got=")
						.Append(num5.ToString("F0"))
						.Append(flag2 ? " FREEZE]" : "]");
					if (flag2)
					{
						waterFillState4.frozen[num3] = true;
						waterFillState4.frozenTotal += num5;
						waterFillState4.activeCount--;
						waterFillState4.activeBoost -= Mathf.Max(0f, waterFillState4.edges[num3].target - waterFillState4.maintainPerRes);
						core.SetEdgeCapacity(waterFillState4.edges[num3].edgeId, num5);
						flag = true;
					}
				}
				if (stringBuilder3 != null)
				{
					AqueductFlowDiagnostics.Note($"wf group#{((waterFillState4.grp != null) ? waterFillState4.grp.id : (-1))} r{num} achv={waterFillState4.achievable:F0} maint={waterFillState4.maintainPerRes:F0} frozenTot={waterFillState4.frozenTotal:F0} groupServed={waterFillState4.servedAtRead:F1}{stringBuilder3}");
				}
			}
		}
	}

	private static float TieredCap(WaterFillState s, float target)
	{
		float num = s.achievable - s.frozenTotal;
		float num2 = s.maintainPerRes * (float)s.activeCount;
		float num3 = Mathf.Max(0f, target - s.maintainPerRes);
		if (num >= num2)
		{
			float num4 = num - num2;
			float num5 = ((s.activeBoost > 0f) ? Mathf.Min(1f, num4 / s.activeBoost) : 0f);
			float num6 = Mathf.Max(0f, num4 - s.activeBoost);
			float num7 = ((s.grp.wConsumption > 0f && s.activeCount > 0) ? (num6 / (float)s.activeCount) : 0f);
			return s.maintainPerRes + num3 * num5 + num7;
		}
		float num8 = ((num2 > 0f) ? (num / num2) : 0f);
		return s.maintainPerRes * num8;
	}

	private static WaterFillState RentWaterFillState()
	{
		WaterFillState waterFillState;
		if (waterFillUsed < waterFillPool.Count)
		{
			waterFillState = waterFillPool[waterFillUsed];
		}
		else
		{
			waterFillState = new WaterFillState();
			waterFillPool.Add(waterFillState);
		}
		waterFillUsed++;
		return waterFillState;
	}

	private static void Flush()
	{
		flushOrder.Sort(CompareByDepth);
		for (int i = 0; i < flushOrder.Count; i++)
		{
			AqueductBuilding aqueductBuilding = flushOrder[i];
			if (!(aqueductBuilding == null))
			{
				aqueductBuilding.UpdateWaterFlow();
			}
		}
	}

	private static int CompareByDepth(AqueductBuilding a, AqueductBuilding b)
	{
		return core.GetBfsDepth(nodeOf[a]).CompareTo(core.GetBfsDepth(nodeOf[b]));
	}

	private static void SnapshotLineFlows()
	{
		prevLineFlow.Clear();
		foreach (KeyValuePair<AqueductLine, int> item in edgeOf)
		{
			if (item.Key != null)
			{
				prevLineFlow[item.Key] = core.GetEdgeFlow(item.Value);
			}
		}
	}

	private static string BName(AqueductBuilding b)
	{
		try
		{
			Vector3 vector = b.Center();
			return $"{b.GetType().Name}({(int)vector.x},{(int)vector.z})";
		}
		catch
		{
			return (b != null) ? b.GetType().Name : "null";
		}
	}

	private static string BuildDiagnosticsBlock()
	{
		StringBuilder stringBuilder = new StringBuilder(1024);
		foreach (KeyValuePair<AqueductBuilding, int> item in nodeOf)
		{
			AqueductBuilding key = item.Key;
			if (key is RiverTap)
			{
				stringBuilder.Append("  src   ").Append(BName(key)).Append(" cap=")
					.Append(key.SourceCapacity().ToString("F1"))
					.Append(" extract=")
					.Append(core.GetSourceExtraction(item.Value).ToString("F1"))
					.Append('\n');
			}
		}
		foreach (KeyValuePair<AqueductBuilding, int> item2 in nodeOf)
		{
			AqueductBuilding key2 = item2.Key;
			int value = item2.Value;
			if (!(key2.solverDemand <= 0f))
			{
				stringBuilder.Append("  con   ").Append(BName(key2)).Append(" demand=")
					.Append(key2.solverDemand.ToString("F1"));
				if (key2.solverMinServe > 0f)
				{
					stringBuilder.Append(" floor=").Append(key2.solverMinServe.ToString("F1"));
				}
				stringBuilder.Append(" prio=").Append(key2.solverPriority).Append(" served=")
					.Append(core.GetServedAmount(value).ToString("F1"));
				if (core.WasRolledBack(value))
				{
					stringBuilder.Append(" ROLLED-BACK");
				}
				if (core.IsPassthrough(value))
				{
					stringBuilder.Append(" conduit");
				}
				float networkOutflow = core.GetNetworkOutflow(value);
				if (networkOutflow > 0.5f)
				{
					stringBuilder.Append(" thru=").Append(networkOutflow.ToString("F1"));
				}
				stringBuilder.Append('\n');
			}
		}
		foreach (KeyValuePair<BathManager.BathGroup, int> item3 in groupNodeOf)
		{
			BathManager.BathGroup key3 = item3.Key;
			int value2 = item3.Value;
			stringBuilder.Append("  bath  group#").Append(key3.id).Append(" res=")
				.Append(key3.reservoirs.Count)
				.Append(" need=")
				.Append(key3.wConsumption.ToString("F1"))
				.Append(" demand=")
				.Append(key3.solverDemand.ToString("F1"));
			if (key3.solverMinServe > 0f)
			{
				stringBuilder.Append(" floor=").Append(key3.solverMinServe.ToString("F1"));
			}
			stringBuilder.Append(" prio=").Append(key3.solverPriority).Append(" served=")
				.Append(core.GetServedAmount(value2).ToString("F1"));
			if (groupAchievable.TryGetValue(key3, out var value3))
			{
				stringBuilder.Append(" achv=").Append(value3.ToString("F1"));
			}
			stringBuilder.Append(" viable=").Append(key3.waterViable).Append(" storage=")
				.Append(key3.storage.ToString("F0"));
			if (core.WasRolledBack(value2))
			{
				stringBuilder.Append(" ROLLED-BACK");
			}
			stringBuilder.Append('\n');
		}
		int num = 0;
		float num2 = 0f;
		AqueductLine aqueductLine = null;
		float num3 = 0f;
		float num4 = 0f;
		foreach (KeyValuePair<AqueductLine, int> item4 in edgeOf)
		{
			float edgeFlow = core.GetEdgeFlow(item4.Value);
			prevLineFlow.TryGetValue(item4.Key, out var value4);
			float num5 = Mathf.Abs(edgeFlow - value4);
			if (num5 > 0.5f)
			{
				num++;
				num2 += num5;
				if (aqueductLine == null || num5 > Mathf.Abs(num4 - num3))
				{
					aqueductLine = item4.Key;
					num3 = value4;
					num4 = edgeFlow;
				}
			}
		}
		stringBuilder.Append("  route lines-changed=").Append(num).Append(" sum|d|=")
			.Append(num2.ToString("F0"));
		if (aqueductLine != null)
		{
			AqueductBuilding startBuilding = aqueductLine.GetStartBuilding();
			AqueductBuilding endBuilding = aqueductLine.GetEndBuilding();
			stringBuilder.Append("  worst=").Append((startBuilding != null) ? BName(startBuilding) : "?").Append("->")
				.Append((endBuilding != null) ? BName(endBuilding) : "?")
				.Append(' ')
				.Append(num3.ToString("F0"))
				.Append("->")
				.Append(num4.ToString("F0"));
		}
		stringBuilder.Append('\n');
		return stringBuilder.ToString();
	}

	public static float GetLineFlow(AqueductLine line)
	{
		if (line != null && edgeOf.TryGetValue(line, out var value))
		{
			return core.GetEdgeFlow(value);
		}
		return 0f;
	}

	public static float GetSolvedSupply(AqueductBuilding b)
	{
		if (b != null && nodeOf.TryGetValue(b, out var value))
		{
			return core.GetNodeInflow(value);
		}
		return 0f;
	}

	public static bool IsUnderserved(AqueductBuilding b)
	{
		if (b != null && nodeOf.TryGetValue(b, out var value))
		{
			return core.IsUnderserved(value);
		}
		return false;
	}

	public static bool WasRolledBack(AqueductBuilding b)
	{
		if (b != null && nodeOf.TryGetValue(b, out var value))
		{
			return core.WasRolledBack(value);
		}
		return false;
	}

	public static float GetSourceExtraction(AqueductBuilding b)
	{
		if (!hasSolved || b == null || !nodeOf.TryGetValue(b, out var value))
		{
			return float.MaxValue;
		}
		return core.GetSourceExtraction(value);
	}

	public static float GetGroupCommittedPull(BathManager.BathGroup grp)
	{
		if (hasSolved && grp != null && groupNodeOf.TryGetValue(grp, out var value))
		{
			return core.GetServedAmount(value);
		}
		return 0f;
	}

	public static float GetGroupAchievablePull(BathManager.BathGroup grp)
	{
		if (hasSolved && grp != null && groupAchievable.TryGetValue(grp, out var value))
		{
			return value;
		}
		return 0f;
	}

	public static float GetReservoirCommittedIntake(BathReservoir res)
	{
		if (!hasSolved || res == null || res.Group == null)
		{
			return 0f;
		}
		if (!groupEdges.TryGetValue(res.Group, out var value))
		{
			return 0f;
		}
		for (int i = 0; i < value.Count; i++)
		{
			if (value[i].res == res)
			{
				return core.GetEdgeFlow(value[i].edgeId);
			}
		}
		return 0f;
	}

	public static bool GetGroupRolledBack(BathManager.BathGroup grp)
	{
		if (grp != null && groupNodeOf.TryGetValue(grp, out var value))
		{
			return core.WasRolledBack(value);
		}
		return false;
	}
}
