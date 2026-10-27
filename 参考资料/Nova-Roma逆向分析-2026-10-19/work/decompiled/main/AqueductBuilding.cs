using System;
using System.Collections.Generic;
using I2.Loc;
using UnityEngine;

public class AqueductBuilding : Tickable, IRubbleSettings
{
	public enum WaterError
	{
		None,
		NoLinesConnected,
		NoInputLines,
		NoWaterFlowing,
		DemandUnmet,
		OutputsBlocked
	}

	[Serializable]
	public class PortBox
	{
		public Transform corner1;

		public Transform corner2;
	}

	[Serializable]
	public class AqueductBuildingSaveData : SaveClass<AqueductBuilding, AqueductBuildingSaveData>
	{
		public int solverPriority;

		public override AqueductBuildingSaveData Pack(AqueductBuilding obj)
		{
			solverPriority = obj.solverPriority;
			return this;
		}

		public override AqueductBuilding Unpack(AqueductBuilding obj)
		{
			obj.solverPriority = solverPriority;
			return obj;
		}
	}

	public const float WATER_ARRIVED_FRACTION = 0.98f;

	public static readonly float MAX_WATER_FLOW_HUMAN_UNITS = 250f;

	public static readonly float MAX_WATER_FLOW = 0.07f;

	public List<AqueductLine> aqueductLines;

	public Building b;

	internal bool hasPotentialConnection;

	public float inputFromEnvironment;

	public float waterFlow;

	public float waterFlowAfterConsumption;

	public float waterConsumption;

	public float solverDemand;

	public int solverPriority;

	public float solverMinServe;

	public const float DEMAND_HYSTERESIS_EPSILON = 0.5f;

	public const float ATOMIC_RELIGHT_MARGIN = 3f;

	protected const float FLOW_DIRTY_EPSILON = 1f;

	public int maxPorts = 6;

	public PortBox[] portBoxes;

	[NonSerialized]
	public bool onlyOutgoing;

	[NonSerialized]
	public bool onlyIncoming;

	[NonSerialized]
	public bool bothOutgoingAndIncoming;

	public WaterPriority WaterPriorityLevel
	{
		get
		{
			return (WaterPriority)solverPriority;
		}
		set
		{
			SetWaterPriority(value);
		}
	}

	public ThoughtBubbleSystem.Thought GetThoughtBubbleFor(WaterError waterError)
	{
		switch (waterError)
		{
		case WaterError.NoLinesConnected:
		case WaterError.NoInputLines:
			return ThoughtBubbleSystem.Thought.Aqueduct;
		case WaterError.NoWaterFlowing:
		case WaterError.DemandUnmet:
		case WaterError.OutputsBlocked:
			return ThoughtBubbleSystem.Thought.WaterCritical;
		default:
			return ThoughtBubbleSystem.Thought.Satisfied;
		}
	}

	protected void ApplyWaterErrorThought(WaterError error)
	{
		if (!(b == null) && b.thought != null)
		{
			if (error != WaterError.None)
			{
				b.thought.thought = GetThoughtBubbleFor(error);
				b.thought.visible = true;
			}
			else
			{
				b.thought.visible = false;
			}
		}
	}

	public WaterError UpdateWaterErrorState()
	{
		WaterError result = WaterError.None;
		if (aqueductLines.Count == 0)
		{
			result = WaterError.NoLinesConnected;
		}
		else
		{
			int num = 0;
			foreach (AqueductLine aqueductLine in aqueductLines)
			{
				if (aqueductLine.IsProvidingWaterTo(this))
				{
					num++;
				}
			}
			if (num == 0)
			{
				result = WaterError.NoInputLines;
			}
			else if (AqueductFlowController.WasRolledBack(this))
			{
				result = WaterError.DemandUnmet;
			}
			else if (AqueductFlowController.IsUnderserved(this))
			{
				result = WaterError.NoWaterFlowing;
			}
		}
		return result;
	}

	public static bool WaterHasArrived(float received, float demand)
	{
		if (!(received >= demand * 0.98f))
		{
			return received >= demand - 0.5f;
		}
		return true;
	}

	public virtual bool IsWaterEnRoute()
	{
		if (solverDemand >= 1f && !WaterHasArrived(waterFlow, solverDemand))
		{
			return UpdateWaterErrorState() == WaterError.None;
		}
		return false;
	}

	public static string GetErrorString(WaterError error)
	{
		return error switch
		{
			WaterError.NoLinesConnected => LocalizationManager.GetTranslation("watertower_error_nolinesconnected"), 
			WaterError.NoInputLines => LocalizationManager.GetTranslation("watertower_error_noinputlines"), 
			WaterError.NoWaterFlowing => LocalizationManager.GetTranslation("workerui_watertower_error_supplyshortfall"), 
			WaterError.DemandUnmet => LocalizationManager.GetTranslation("workerui_watertower_error_supplysuspended"), 
			WaterError.OutputsBlocked => LocalizationManager.GetTranslation("workerui_wateroutlet_error_blocked"), 
			_ => null, 
		};
	}

	protected void SetSolverDemand(float demand, float minServe)
	{
		if (Mathff.Abs(solverDemand - demand) > 0.5f || Mathff.Abs(solverMinServe - minServe) > 0.5f)
		{
			solverDemand = demand;
			solverMinServe = minServe;
			AqueductFlowController.MarkDemandDirty("SetSolverDemand");
		}
	}

	public void SetWaterPriority(WaterPriority priority)
	{
		if (solverPriority != (int)priority)
		{
			solverPriority = (int)priority;
			AqueductFlowController.MarkDemandDirty("SetWaterPriority");
		}
	}

	public virtual void SetConsumption(float consumptionHumanUnits)
	{
		waterConsumption = consumptionHumanUnits;
		solverDemand = waterConsumption;
		AqueductFlowController.MarkDemandDirty("SetConsumption");
		if (aqueductLines.Count == 0)
		{
			UpdateWaterFlow();
		}
	}

	public virtual float GetCurrentWaterConsumption()
	{
		return Mathff.Min(waterFlow, waterConsumption);
	}

	protected virtual float NetworkDraw()
	{
		return waterConsumption;
	}

	public virtual float GetWaterDemandTotal()
	{
		return waterConsumption;
	}

	public virtual float SourceCapacity()
	{
		return 0f;
	}

	public bool HasNetworkedLine()
	{
		if (aqueductLines == null)
		{
			return false;
		}
		for (int i = 0; i < aqueductLines.Count; i++)
		{
			AqueductLine aqueductLine = aqueductLines[i];
			if (aqueductLine != null && aqueductLine.fullyConstructed && !aqueductLine.displayOnly && !aqueductLine.IsOpenEnded)
			{
				return true;
			}
		}
		return false;
	}

	public static float SystemToHuman(float system)
	{
		return system * (MAX_WATER_FLOW_HUMAN_UNITS / MAX_WATER_FLOW);
	}

	public static float HumanToSystem(float human)
	{
		return human * (MAX_WATER_FLOW / MAX_WATER_FLOW_HUMAN_UNITS);
	}

	protected bool FlowChanged(float newInput, bool immediate)
	{
		if (!immediate && newInput != 0f && inputFromEnvironment != 0f)
		{
			return Mathff.Abs(newInput - inputFromEnvironment) > 1f;
		}
		return true;
	}

	public virtual void CalculateWaterFlow()
	{
		waterFlow = inputFromEnvironment;
		for (int i = 0; i < aqueductLines.Count; i++)
		{
			if (aqueductLines[i].fullyConstructed && aqueductLines[i].IsProvidingWaterTo(this))
			{
				waterFlow += aqueductLines[i].currentOutputFlow;
			}
		}
	}

	public virtual void UpdateWaterFlow()
	{
		CalculateWaterFlow();
		if (GameState.IsQuitting || LoadSave.Loading)
		{
			return;
		}
		waterFlowAfterConsumption = Mathff.Clamp(waterFlow - NetworkDraw(), 0f, waterFlow);
		int num = Mathf.FloorToInt(waterFlowAfterConsumption);
		int num2 = (int)MAX_WATER_FLOW_HUMAN_UNITS;
		List<AqueductLine> list = null;
		List<int> list2 = null;
		List<float> list3 = null;
		List<AqueductLine> list4 = null;
		int num3 = 0;
		for (int i = 0; i < aqueductLines.Count; i++)
		{
			AqueductLine aqueductLine = aqueductLines[i];
			if (aqueductLine == null || !aqueductLine.fullyConstructed || !aqueductLine.IsSendingWaterTo(this))
			{
				continue;
			}
			if (aqueductLine.IsOpenEnded)
			{
				(list4 ?? (list4 = new List<AqueductLine>(aqueductLines.Count))).Add(aqueductLine);
				continue;
			}
			if (list == null)
			{
				list = new List<AqueductLine>(aqueductLines.Count);
				list2 = new List<int>(aqueductLines.Count);
				list3 = new List<float>(aqueductLines.Count);
			}
			float num4 = (float)num * aqueductLine.valveRatio;
			int num5 = Mathf.Min(Mathf.FloorToInt(num4), num2);
			list.Add(aqueductLine);
			list2.Add(num5);
			list3.Add(num4 - (float)num5);
			num3 += num5;
		}
		int num6 = num;
		if (list != null)
		{
			for (num6 = num - num3; num6 > 0; num6--)
			{
				int num7 = -1;
				float num8 = -1f;
				for (int j = 0; j < list.Count; j++)
				{
					if (list2[j] < num2 && list3[j] > num8)
					{
						num8 = list3[j];
						num7 = j;
					}
				}
				if (num7 < 0)
				{
					break;
				}
				list2[num7]++;
				list3[num7] = -1f;
			}
			for (int k = 0; k < list.Count; k++)
			{
				list[k].SetWaterFlow(list2[k]);
			}
		}
		if (list4 != null)
		{
			int num9 = num6 / list4.Count;
			int num10 = num6 % list4.Count;
			for (int l = 0; l < list4.Count; l++)
			{
				int num11 = Mathf.Min(num9 + ((l < num10) ? 1 : 0), num2);
				list4[l].SetWaterFlow(num11);
			}
		}
	}

	public bool HasWater()
	{
		return waterFlow >= 1f;
	}

	public virtual int GetLandMass()
	{
		return b.LandMass();
	}

	public virtual Vector3 Center()
	{
		return b.Center();
	}

	private void OnDrawGizmos()
	{
		Gizmos.color = Color.red;
		Vector3 size = default;
		for (int i = 0; i < portBoxes.Length; i++)
		{
			Transform corner = portBoxes[i].corner1;
			Transform corner2 = portBoxes[i].corner2;
			Gizmos.DrawLine(corner.position, corner.position);
			size.x = Mathff.Abs(corner.position.x - corner2.position.x);
			size.y = Mathff.Abs(corner.position.y - corner2.position.y);
			size.z = Mathff.Abs(corner.position.z - corner2.position.z);
			Gizmos.DrawCube((corner.position + corner2.position) / 2f, size);
		}
	}

	public void GetPortBox(out Vector3 min, out Vector3 max, int idx)
	{
		min = portBoxes[idx].corner1.position;
		max = portBoxes[idx].corner1.position;
		if (min.x > portBoxes[idx].corner2.position.x)
		{
			min.x = portBoxes[idx].corner2.position.x;
		}
		if (min.y > portBoxes[idx].corner2.position.y)
		{
			min.y = portBoxes[idx].corner2.position.y;
		}
		if (min.z > portBoxes[idx].corner2.position.z)
		{
			min.z = portBoxes[idx].corner2.position.z;
		}
		if (max.x < portBoxes[idx].corner2.position.x)
		{
			max.x = portBoxes[idx].corner2.position.x;
		}
		if (max.y < portBoxes[idx].corner2.position.y)
		{
			max.y = portBoxes[idx].corner2.position.y;
		}
		if (max.z < portBoxes[idx].corner2.position.z)
		{
			max.z = portBoxes[idx].corner2.position.z;
		}
	}

	public Vector3 GetPortPosition(Vector3 pos)
	{
		float num = float.MaxValue;
		Vector3 result = Vector3.zero;
		for (int i = 0; i < portBoxes.Length; i++)
		{
			GetPortBox(out var min, out var max, i);
			Vector3 vector = Mathff.ClosestPointOnBoxXZ(min, max, pos);
			vector.y = max.y;
			float num2 = Mathff.DistSqrd(vector, pos);
			if (num2 < num)
			{
				num = num2;
				result = vector;
			}
		}
		return result;
	}

	public bool HasAvailablePorts()
	{
		return aqueductLines.Count < maxPorts;
	}

	public virtual void ConnectLine(AqueductLine line)
	{
		if (!aqueductLines.Contains(line))
		{
			aqueductLines.Add(line);
		}
	}

	public virtual void OnDestroy()
	{
		OrphanLines();
	}

	public void OnBuildingPlacement(bool undo)
	{
		if (undo)
		{
			OrphanLines();
		}
		else
		{
			AqueductLine.ReconnectOpenEndsTo(this);
		}
	}

	public void OrphanLines()
	{
		if (LoadSave.Loading || aqueductLines == null)
		{
			return;
		}
		List<AqueductLine> list = new List<AqueductLine>(aqueductLines);
		for (int i = 0; i < list.Count; i++)
		{
			if (list[i] != null)
			{
				list[i].DetachFrom(this);
			}
		}
		aqueductLines.Clear();
	}

	public void RemoveAqueductLine(AqueductLine aqueductLine)
	{
		aqueductLines.Remove(aqueductLine);
		AqueductFlowController.MarkTopologyDirty("RemoveAqueductLine");
		if (aqueductLines.Count == 0)
		{
			UpdateWaterFlow();
		}
		if (this is AqueductJunction aqueductJunction)
		{
			aqueductJunction.RemoveIfDangling();
			if (aqueductJunction != null)
			{
				aqueductJunction.TryCollapseLines();
			}
		}
	}

	public override void OnEnableInternal()
	{
		aqueductLines = new List<AqueductLine>(maxPorts);
		base.OnEnableInternal();
	}

	public void Start()
	{
		bothOutgoingAndIncoming = true;
	}
}
