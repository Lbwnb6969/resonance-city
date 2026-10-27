using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class AqueductJunction : AqueductBuilding
{
	[Serializable]
	public class AqueductJunctionSaveData : SaveClass<AqueductJunction, AqueductJunctionSaveData>
	{
		public Guid guid;

		public SerializableVector3 position;

		public override AqueductJunctionSaveData Pack(AqueductJunction w)
		{
			guid = w.guid;
			position = w.transform.position;
			return this;
		}

		public override AqueductJunction Unpack(AqueductJunction w)
		{
			if (w == null)
			{
				w = Create(position);
			}
			w.guid = guid;
			w.FinalizePlacement();
			w.transform.position = position;
			w.RegisterWithInstanceManager();
			return w;
		}
	}

	private sealed class CollapseSuppressionScope : IDisposable
	{
		private bool disposed;

		public CollapseSuppressionScope()
		{
			collapseSuppressionDepth++;
		}

		public void Dispose()
		{
			if (!disposed)
			{
				collapseSuppressionDepth = Math.Max(0, collapseSuppressionDepth - 1);
				disposed = true;
			}
		}
	}

	private readonly struct JunctionConnection(AqueductLine line, AqueductBuilding other)
	{
		public readonly AqueductLine line = line;

		public readonly AqueductBuilding other = other;
	}

	private static readonly Dictionary<Guid, AqueductJunction> junctionLookup = new Dictionary<Guid, AqueductJunction>();

	private static int collapseSuppressionDepth;

	[SerializeField]
	private Guid guid;

	private float tunnelColliderRadius = 0.15f;

	private float tunnelColliderHeight = 0.52f;

	[SerializeField]
	private Mesh elbowMeshTop;

	[SerializeField]
	private Mesh elbowMesh;

	[SerializeField]
	private Material material;

	private bool previewOnly;

	private CapsuleCollider tunnelCollider;

	private List<RenderInstance> _renderInstances;

	private Vector3 scale = new Vector3(1.4f, 1f, 1.4f);

	private Quaternion rot = Quaternion.LookRotation(Vector3.forward, Vector3.up);

	public Guid Guid => guid;

	private static bool CollapseSuppressed => collapseSuppressionDepth > 0;

	public static void ClearAll()
	{
		if (junctionLookup.Count > 0)
		{
			AqueductJunction[] array = junctionLookup.Values.ToArray();
			foreach (AqueductJunction aqueductJunction in array)
			{
				if (aqueductJunction != null)
				{
					UnityEngine.Object.Destroy(aqueductJunction.gameObject);
				}
			}
			junctionLookup.Clear();
		}
		collapseSuppressionDepth = 0;
	}

	public static AqueductJunction[] SnapshotAll()
	{
		return junctionLookup.Values.ToArray();
	}

	private void Awake()
	{
		maxPorts = 6;
		bothOutgoingAndIncoming = true;
		onlyIncoming = false;
		onlyOutgoing = false;
		if (portBoxes == null || portBoxes.Length == 0)
		{
			portBoxes = new PortBox[1];
			portBoxes[0] = new PortBox
			{
				corner1 = new GameObject("PortCorner1").transform,
				corner2 = new GameObject("PortCorner2").transform
			};
			portBoxes[0].corner1.SetParent(transform, worldPositionStays: false);
			portBoxes[0].corner2.SetParent(transform, worldPositionStays: false);
		}
		UpdatePortBounds();
		SetupTunnelCollider();
		material = World.inst.uniMaterialNoFog;
		elbowMeshTop = Resources.Load<Mesh>("aqueduct_nodecover_top");
		elbowMesh = Resources.Load<Mesh>("aqueduct_nodecover");
	}

	public void RefreshRenderInstances()
	{
		RegisterWithInstanceManager();
	}

	private void RegisterWithInstanceManager()
	{
		UnregisterFromInstanceManager();
		Vector3 position = transform.position;
		_renderInstances = new List<RenderInstance>();
		if (Physics.Raycast(new Ray(position, Vector3.down), out var hitInfo, 100f, LayerMask.GetMask("Terrain")))
		{
			Vector3 vector = new Vector3(0f, 0.1f, 0f);
			Vector3 vector2 = position + vector;
			Matrix4x4 mat = default;
			Mathff.SetTRS(ref mat, vector2, rot, scale);
			RenderInstance renderInstance = new RenderInstance(elbowMeshTop, material);
			renderInstance.UpdateMatrix(mat);
			renderInstance.Visible = true;
			_renderInstances.Add(renderInstance);
			float y = elbowMesh.bounds.size.y;
			float num = (float)Mathf.RoundToInt((vector2.y - (y - 0f)) / y) * y;
			float num2 = vector2.y - num;
			vector2.y -= num2;
			int num3 = Mathf.CeilToInt((vector2.y - hitInfo.point.y) / y);
			for (int i = 0; i < num3; i++)
			{
				Vector3 pos = vector2 + Vector3.down * (y * (float)i);
				Mathff.SetTRS(ref mat, pos, rot, scale);
				RenderInstance renderInstance2 = new RenderInstance(elbowMesh, material);
				renderInstance2.UpdateMatrix(mat);
				renderInstance2.Visible = true;
				_renderInstances.Add(renderInstance2);
			}
		}
	}

	private void UnregisterFromInstanceManager()
	{
		if (_renderInstances != null)
		{
			for (int i = 0; i < _renderInstances.Count; i++)
			{
				_renderInstances[i].Visible = false;
			}
			_renderInstances.Clear();
			_renderInstances = null;
		}
	}

	private void UpdatePortBounds()
	{
		if (portBoxes != null && portBoxes.Length != 0)
		{
			Vector3 localPosition = new Vector3(0f, 0f, 0f);
			portBoxes[0].corner1.localPosition = localPosition;
			portBoxes[0].corner2.localPosition = localPosition;
		}
	}

	private void SetupTunnelCollider()
	{
		if (portBoxes != null && portBoxes.Length != 0)
		{
			if (tunnelCollider == null)
			{
				GameObject gameObject = new GameObject("TunnelCollider");
				gameObject.transform.SetParent(transform, worldPositionStays: false);
				gameObject.layer = base.gameObject.layer;
				tunnelCollider = gameObject.AddComponent<CapsuleCollider>();
				tunnelCollider.direction = 1;
				tunnelCollider.isTrigger = false;
			}
			Vector3 localPosition = portBoxes[0].corner1.localPosition;
			Vector3 localPosition2 = portBoxes[0].corner2.localPosition;
			Vector3 center = new Vector3((localPosition.x + localPosition2.x) * 0.5f, Mathf.Max(localPosition.y, localPosition2.y), (localPosition.z + localPosition2.z) * 0.5f);
			tunnelCollider.center = center;
			tunnelCollider.radius = Mathf.Max(0.01f, tunnelColliderRadius);
			tunnelCollider.height = Mathf.Max(tunnelColliderHeight, tunnelCollider.radius * 2f);
		}
	}

	private void EnsureTunnelColliderRegistered()
	{
		SetupTunnelCollider();
		Physics.SyncTransforms();
		SimulationMode simulationMode = Physics.simulationMode;
		if (simulationMode != SimulationMode.Script)
		{
			Physics.simulationMode = SimulationMode.Script;
		}
		try
		{
			Physics.Simulate(0f);
		}
		finally
		{
			if (simulationMode != SimulationMode.Script)
			{
				Physics.simulationMode = simulationMode;
			}
		}
	}

	private void RebuildConnectedLineTunnels()
	{
		if (aqueductLines == null)
		{
			return;
		}
		for (int i = 0; i < aqueductLines.Count; i++)
		{
			AqueductLine aqueductLine = aqueductLines[i];
			if (!(aqueductLine == null))
			{
				aqueductLine.FullBuild();
			}
		}
	}

	public void Initialize(Vector3 position, bool isPreview)
	{
		transform.position = position;
		previewOnly = isPreview;
		if (!previewOnly)
		{
			RegisterGuid();
		}
		RegisterWithInstanceManager();
	}

	public static AqueductJunction Create(Vector3 position, bool preview = false)
	{
		AqueductJunction aqueductJunction = new GameObject("AqueductJunction").AddComponent<AqueductJunction>();
		aqueductJunction.Initialize(position, preview);
		return aqueductJunction;
	}

	public void FinalizePlacement()
	{
		if (previewOnly)
		{
			previewOnly = false;
			RegisterGuid();
		}
	}

	private void RegisterGuid()
	{
		if (guid == Guid.Empty)
		{
			guid = Guid.NewGuid();
		}
		junctionLookup[guid] = this;
	}

	public override int GetLandMass()
	{
		return World.inst.GetCellDataClamped(transform.position).landMassIdx;
	}

	public override Vector3 Center()
	{
		return transform.position;
	}

	public override void ConnectLine(AqueductLine line)
	{
		base.ConnectLine(line);
		if (!previewOnly && isActiveAndEnabled)
		{
			EnsureTunnelColliderRegistered();
			RebuildConnectedLineTunnels();
		}
	}

	public override void OnDestroy()
	{
		base.OnDestroy();
		UnregisterFromInstanceManager();
		if (guid != Guid.Empty && junctionLookup.TryGetValue(guid, out var value) && value == this)
		{
			junctionLookup.Remove(guid);
		}
	}

	public static bool TryGet(Guid id, out AqueductJunction junction)
	{
		return junctionLookup.TryGetValue(id, out junction);
	}

	public static AqueductJunction EnsureFromSave(AqueductJunctionSaveData data)
	{
		if (data == null)
		{
			return null;
		}
		if (junctionLookup.TryGetValue(data.guid, out var value))
		{
			return value;
		}
		AqueductJunction aqueductJunction = Create(data.position);
		if (aqueductJunction.guid != Guid.Empty && junctionLookup.TryGetValue(aqueductJunction.guid, out var value2) && value2 == aqueductJunction)
		{
			junctionLookup.Remove(aqueductJunction.guid);
		}
		aqueductJunction.guid = data.guid;
		aqueductJunction.RegisterGuid();
		return aqueductJunction;
	}

	internal static IDisposable SuppressCollapseScope()
	{
		return new CollapseSuppressionScope();
	}

	public void TryCollapseLines()
	{
		if (CollapseSuppressed || LoadSave.Loading || aqueductLines == null)
		{
			return;
		}
		for (int num = aqueductLines.Count - 1; num >= 0; num--)
		{
			if (aqueductLines[num] == null)
			{
				aqueductLines.RemoveAt(num);
			}
		}
		if (aqueductLines.Count == 0)
		{
			UnityEngine.Object.Destroy(gameObject);
		}
		else
		{
			if (aqueductLines.Count != 2)
			{
				return;
			}
			AqueductLine aqueductLine = aqueductLines[0];
			AqueductLine aqueductLine2 = aqueductLines[1];
			if (aqueductLine == null || aqueductLine2 == null || !aqueductLine.fullyConstructed || !aqueductLine2.fullyConstructed)
			{
				return;
			}
			bool flag = aqueductLine.IsProvidingWaterTo(this);
			bool flag2 = aqueductLine2.IsProvidingWaterTo(this);
			if (flag == flag2)
			{
				return;
			}
			AqueductBuilding otherEnd = aqueductLine.GetOtherEnd(this);
			AqueductBuilding otherEnd2 = aqueductLine2.GetOtherEnd(this);
			if ((otherEnd == null && !FarSideOpen(aqueductLine)) || (otherEnd2 == null && !FarSideOpen(aqueductLine2)) || (otherEnd != null && otherEnd == otherEnd2))
			{
				return;
			}
			JunctionConnection junctionConnection = new JunctionConnection(aqueductLine, otherEnd);
			JunctionConnection junctionConnection2 = new JunctionConnection(aqueductLine2, otherEnd2);
			JunctionConnection junctionConnection3 = junctionConnection;
			JunctionConnection junctionConnection4 = junctionConnection2;
			if (junctionConnection2.line.IsProvidingWaterTo(this) && !junctionConnection.line.IsProvidingWaterTo(this))
			{
				junctionConnection3 = junctionConnection2;
				junctionConnection4 = junctionConnection;
			}
			else if (!junctionConnection.line.IsProvidingWaterTo(this) && !junctionConnection2.line.IsProvidingWaterTo(this))
			{
				float portHeight = GetPortHeight(junctionConnection.other);
				if (GetPortHeight(junctionConnection2.other) > portHeight)
				{
					JunctionConnection junctionConnection5 = junctionConnection2;
					JunctionConnection junctionConnection6 = junctionConnection;
					junctionConnection3 = junctionConnection5;
					junctionConnection4 = junctionConnection6;
				}
			}
			List<Vector3> list = BuildCombinedWaypoints(junctionConnection3.line, junctionConnection3.other, junctionConnection4.line);
			if (list == null)
			{
				return;
			}
			if (tunnelCollider != null)
			{
				tunnelCollider.enabled = false;
			}
			aqueductLine.DisableSegmentColliders();
			aqueductLine2.DisableSegmentColliders();
			using (SuppressCollapseScope())
			{
				bool flag3 = junctionConnection3.other == null;
				bool flag4 = junctionConnection4.other == null;
				Vector3[] middleWaypoints = ExtractMiddle(list);
				AqueductLine aqueductLine3;
				if (!flag3 && !flag4)
				{
					aqueductLine3 = AqueductLine.CreateInstantLine(junctionConnection3.other, middleWaypoints, junctionConnection4.other);
				}
				else if (flag3 & flag4)
				{
					aqueductLine3 = AqueductLine.CreateInstantLineBothOpen(list.ToArray());
				}
				else
				{
					aqueductLine3 = ((!flag3) ? AqueductLine.CreateInstantLineOneOpen(junctionConnection3.other, middleWaypoints, list[list.Count - 1], openIsStart: false) : AqueductLine.CreateInstantLineOneOpen(junctionConnection4.other, middleWaypoints, list[0], openIsStart: true));
				}
				List<AqueductLine.WaterFlowStateTransitionNodes> list2 = MergeTransitionNodes(junctionConnection3.line, junctionConnection3.other, junctionConnection4.line, this);
				if (aqueductLine3 == null)
				{
					return;
				}
				aqueductLine3.waterFlowStateTransitionNodes = list2;
				aqueductLine3.currentInputFlow = GetStartFlow(junctionConnection3.line, junctionConnection3.other);
				aqueductLine3.currentOutputFlow = GetEndFlow(junctionConnection4.line, junctionConnection4.other);
				aqueductLine3.hasWater = aqueductLine3.currentInputFlow > 0f || aqueductLine3.currentOutputFlow > 0f || list2.Any((AqueductLine.WaterFlowStateTransitionNodes n) => n.waterAmount > 0f);
				aqueductLine3.FullBuild();
				aqueductLine.DestroySelf(triggerCollapse: false);
				aqueductLine2.DestroySelf(triggerCollapse: false);
			}
			AqueductFlowController.MarkTopologyDirty("TryCollapseLines");
			UnityEngine.Object.Destroy(gameObject);
		}
	}

	public void RemoveIfDangling()
	{
		if (previewOnly || CollapseSuppressed || LoadSave.Loading || aqueductLines == null)
		{
			return;
		}
		for (int num = aqueductLines.Count - 1; num >= 0; num--)
		{
			if (aqueductLines[num] == null)
			{
				aqueductLines.RemoveAt(num);
			}
		}
		if (aqueductLines.Count == 1)
		{
			AqueductLine aqueductLine = aqueductLines[0];
			if (aqueductLine != null && aqueductLine.fullyConstructed && !aqueductLine.displayOnly)
			{
				AqueductLine.CutLine(aqueductLine, transform.position, transform.position, 0.5f);
			}
			OrphanLines();
			UnityEngine.Object.Destroy(gameObject);
		}
	}

	public void ClearAndRemove(float minRemnantLength)
	{
		if (aqueductLines == null)
		{
			return;
		}
		List<AqueductLine> list = new List<AqueductLine>(aqueductLines);
		Vector3 position = transform.position;
		float radius = ((minRemnantLength > 0f) ? minRemnantLength : 0.5f);
		using (SuppressCollapseScope())
		{
			for (int i = 0; i < list.Count; i++)
			{
				AqueductLine aqueductLine = list[i];
				if (!(aqueductLine == null) && !aqueductLine.displayOnly && aqueductLine.fullyConstructed)
				{
					AqueductLine.CutLine(aqueductLine, position, position, radius, minRemnantLength);
				}
			}
		}
		if (!(this == null))
		{
			RemoveIfDangling();
			if (this != null)
			{
				TryCollapseLines();
			}
		}
	}

	private static float GetStartFlow(AqueductLine line, AqueductBuilding startBuilding)
	{
		if (!(line.GetStartBuilding() == startBuilding))
		{
			return line.currentOutputFlow;
		}
		return line.currentInputFlow;
	}

	private static float GetEndFlow(AqueductLine line, AqueductBuilding endBuilding)
	{
		if (!(line.GetEndBuilding() == endBuilding))
		{
			return line.currentInputFlow;
		}
		return line.currentOutputFlow;
	}

	private static List<Vector3> GetOrderedWaypoints(AqueductLine line, AqueductBuilding desiredStart)
	{
		if (line == null)
		{
			return null;
		}
		List<Vector3> list = new List<Vector3>(line.waypoints);
		if (line.GetStartBuilding() == desiredStart)
		{
			return list;
		}
		if (line.GetEndBuilding() == desiredStart)
		{
			list.Reverse();
			return list;
		}
		return null;
	}

	private static bool IsColinear(Vector3 a, Vector3 b, Vector3 c)
	{
		Vector3 normalized = (b - a).xz().normalized;
		Vector3 normalized2 = (c - b).xz().normalized;
		if (normalized.sqrMagnitude < 0.0001f || normalized2.sqrMagnitude < 0.0001f)
		{
			return true;
		}
		return Vector2.Distance(normalized, normalized2) < 0.001f;
	}

	private List<Vector3> BuildCombinedWaypoints(AqueductLine lineA, AqueductBuilding otherA, AqueductLine lineB)
	{
		List<Vector3> orderedWaypoints = GetOrderedWaypoints(lineA, otherA);
		List<Vector3> orderedWaypoints2 = GetOrderedWaypoints(lineB, this);
		if (orderedWaypoints == null || orderedWaypoints2 == null)
		{
			return null;
		}
		if (orderedWaypoints.Count == 0 || orderedWaypoints2.Count == 0)
		{
			return null;
		}
		List<Vector3> list = new List<Vector3>(orderedWaypoints.Count + orderedWaypoints2.Count);
		list.AddRange(orderedWaypoints);
		for (int i = 1; i < orderedWaypoints2.Count; i++)
		{
			list.Add(orderedWaypoints2[i]);
		}
		for (int num = list.Count - 1; num > 0; num--)
		{
			if ((list[num] - list[num - 1]).sqrMagnitude < 0.0001f)
			{
				list.RemoveAt(num);
			}
		}
		Vector3 junctionPoint = orderedWaypoints[orderedWaypoints.Count - 1];
		int num2 = list.FindIndex((Vector3 p) => (p - junctionPoint).sqrMagnitude < 0.0001f);
		if (num2 > 0 && num2 < list.Count - 1 && IsColinear(list[num2 - 1], list[num2], list[num2 + 1]))
		{
			list.RemoveAt(num2);
		}
		if (list.Count < 2)
		{
			return null;
		}
		return list;
	}

	private static Vector3[] ExtractMiddle(List<Vector3> full)
	{
		if (full.Count <= 2)
		{
			return Array.Empty<Vector3>();
		}
		Vector3[] array = new Vector3[full.Count - 2];
		for (int i = 1; i < full.Count - 1; i++)
		{
			array[i - 1] = full[i];
		}
		return array;
	}

	private bool FarSideOpen(AqueductLine line)
	{
		if (line.GetStartBuilding() == this)
		{
			return line.IsEndOpen;
		}
		if (line.GetEndBuilding() == this)
		{
			return line.IsStartOpen;
		}
		return false;
	}

	private static float GetPathLength(List<Vector3> path)
	{
		float num = 0f;
		for (int i = 0; i < path.Count - 1; i++)
		{
			num += Vector3.Distance(path[i], path[i + 1]);
		}
		return num;
	}

	private static List<AqueductLine.WaterFlowStateTransitionNodes> MergeTransitionNodes(AqueductLine lineA, AqueductBuilding otherA, AqueductLine lineB, AqueductBuilding junction)
	{
		List<AqueductLine.WaterFlowStateTransitionNodes> list = new List<AqueductLine.WaterFlowStateTransitionNodes>();
		List<Vector3> orderedWaypoints = GetOrderedWaypoints(lineA, otherA);
		List<Vector3> orderedWaypoints2 = GetOrderedWaypoints(lineB, junction);
		if (orderedWaypoints == null || orderedWaypoints2 == null)
		{
			return list;
		}
		float pathLength = GetPathLength(orderedWaypoints);
		float pathLength2 = GetPathLength(orderedWaypoints2);
		float num = Mathf.Max(pathLength + pathLength2, 0.0001f);
		AppendTransitionNodes(lineA, otherA, 0f, pathLength / num, list);
		AppendTransitionNodes(lineB, junction, pathLength / num, pathLength2 / num, list);
		return list;
	}

	private static void AppendTransitionNodes(AqueductLine sourceLine, AqueductBuilding referenceStart, float offset, float span, List<AqueductLine.WaterFlowStateTransitionNodes> destination)
	{
		if (sourceLine.waterFlowStateTransitionNodes == null || destination == null)
		{
			return;
		}
		bool flag = sourceLine.GetStartBuilding() == referenceStart;
		bool flag2 = sourceLine.GetEndBuilding() == referenceStart;
		for (int i = 0; i < sourceLine.waterFlowStateTransitionNodes.Count; i++)
		{
			AqueductLine.WaterFlowStateTransitionNodes waterFlowStateTransitionNodes = sourceLine.waterFlowStateTransitionNodes[i];
			if (waterFlowStateTransitionNodes != null)
			{
				float num;
				if (flag)
				{
					num = waterFlowStateTransitionNodes.T;
				}
				else
				{
					num = (flag2 ? (1f - waterFlowStateTransitionNodes.T) : waterFlowStateTransitionNodes.T);
				}
				float t = Mathf.Clamp01(offset + num * span);
				destination.Add(new AqueductLine.WaterFlowStateTransitionNodes
				{
					T = t,
					waterAmount = waterFlowStateTransitionNodes.waterAmount
				});
			}
		}
	}

	private float GetPortHeight(AqueductBuilding building)
	{
		if (building == null)
		{
			return transform.position.y;
		}
		return building.GetPortPosition(transform.position).y;
	}
}
