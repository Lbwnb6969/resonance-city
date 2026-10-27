using System;
using System.Collections.Generic;
using UnityEngine;

public class WaterFlowLabelSystem : MonoBehaviour
{
	[Serializable]
	public struct StateVisual
	{
		public WaterFlowState state;

		public Sprite background;

		public Color color;
	}

	public static WaterFlowLabelSystem inst;

	[Tooltip("Prefab root with a WaterFlowLabel (TextMeshPro + background sprite).")]
	public WaterFlowLabel labelPrefab;

	[Tooltip("How far along each connected line, in world units, to place that line's label — measured from the building end of the line. Clamped to half the line's length so a short line's two end labels can't land on top of each other.")]
	public float lineLabelDistance = 1f;

	[Tooltip("Vertical offset above the point on the line. The line already sits at pipe height, so this only needs to clear the channel itself.")]
	public float lineLabelHeightOffset = 0.35f;

	[Tooltip("On-screen size vs. distance to camera (matches ThoughtBubbleSystem's feel).")]
	public AnimationCurve scaleToCamDist = AnimationCurve.Linear(0f, 0.5f, 100f, 5f);

	[Header("State backgrounds")]
	[Tooltip("Background sprite + tint the artist authors per flow state, applied to every label this system drives. A state absent from this list leaves the label's prefab background untouched.")]
	public StateVisual[] stateVisuals = new StateVisual[3]
	{
		new StateVisual
		{
			state = WaterFlowState.Normal
		},
		new StateVisual
		{
			state = WaterFlowState.Source
		},
		new StateVisual
		{
			state = WaterFlowState.SupplyIssue
		}
	};

	private readonly List<WaterFlowLabel> pool = new List<WaterFlowLabel>(64);

	private void Awake()
	{
		inst = this;
	}

	private void LateUpdate()
	{
		if (labelPrefab == null || Cam.inst == null || !AqueductLine.IsWaterBuildingSelected())
		{
			HideAll();
			return;
		}
		IReadOnlyList<AqueductBuilding> knownBuildings = AqueductFlowController.KnownBuildings;
		Camera cam = Cam.inst.cam;
		Vector3 position = cam.transform.position;
		int num = 0;
		for (int i = 0; i < knownBuildings.Count; i++)
		{
			AqueductBuilding aqueductBuilding = knownBuildings[i];
			if (aqueductBuilding == null || aqueductBuilding.aqueductLines == null || (!(aqueductBuilding == GameUI.inst.GetBuildingSelected()?.GetComponent<AqueductBuilding>()) && !(aqueductBuilding == (GameUI.inst.GetHighlightedBuilding() as Building)?.GetComponent<AqueductBuilding>())))
			{
				continue;
			}
			WaterFlowState state = StateOf(aqueductBuilding);
			WaterPriority priority = PriorityOf(aqueductBuilding);
			for (int j = 0; j < aqueductBuilding.aqueductLines.Count; j++)
			{
				AqueductLine aqueductLine = aqueductBuilding.aqueductLines[j];
				if (!(aqueductLine == null))
				{
					bool flag = aqueductLine.GetStartBuilding() == aqueductBuilding;
					if ((flag || !(aqueductLine.GetEndBuilding() != aqueductBuilding)) && TryPointAlongLine(aqueductLine.waypoints, flag, lineLabelDistance, out var point, out var direction))
					{
						Vector3 vector = point + Vector3.up * lineLabelHeightOffset;
						float scale = scaleToCamDist.Evaluate(Vector3.Distance(vector, position));
						float num2 = (flag ? aqueductLine.GetInflowAmount() : aqueductLine.currentOutputFlow);
						Vector3 alongDirection = (flag ? direction : (-direction));
						WaterFlowLabel pooled = GetPooled(num++);
						pooled.SetText($"{num2:F0}");
						ApplyState(pooled, state);
						pooled.SetPriority(priority);
						pooled.Place(vector, cam, scale, alongDirection);
					}
				}
			}
		}
		for (int k = num; k < pool.Count; k++)
		{
			SetActive(pool[k], active: false);
		}
	}

	private static bool TryPointAlongLine(Vector3[] waypoints, bool fromStart, float distance, out Vector3 point, out Vector3 direction)
	{
		point = Vector3.zero;
		direction = Vector3.zero;
		if (waypoints == null || waypoints.Length < 2)
		{
			return false;
		}
		float num = 0f;
		for (int i = 1; i < waypoints.Length; i++)
		{
			num += Vector3.Distance(waypoints[i - 1], waypoints[i]);
		}
		if (num <= 0.0001f)
		{
			point = waypoints[0];
			return true;
		}
		float num2 = Mathf.Min(distance, num * 0.5f);
		float num3 = 0f;
		if (fromStart)
		{
			for (int j = 1; j < waypoints.Length; j++)
			{
				float num4 = Vector3.Distance(waypoints[j - 1], waypoints[j]);
				if (num3 + num4 >= num2)
				{
					point = Vector3.Lerp(waypoints[j - 1], waypoints[j], (num4 > 0.0001f) ? ((num2 - num3) / num4) : 0f);
					direction = (waypoints[j] - waypoints[j - 1]).normalized;
					return true;
				}
				num3 += num4;
			}
			point = waypoints[^1];
			direction = (waypoints[^1] - waypoints[^2]).normalized;
			return true;
		}
		for (int num5 = waypoints.Length - 1; num5 > 0; num5--)
		{
			float num6 = Vector3.Distance(waypoints[num5], waypoints[num5 - 1]);
			if (num3 + num6 >= num2)
			{
				point = Vector3.Lerp(waypoints[num5], waypoints[num5 - 1], (num6 > 0.0001f) ? ((num2 - num3) / num6) : 0f);
				direction = (waypoints[num5 - 1] - waypoints[num5]).normalized;
				return true;
			}
			num3 += num6;
		}
		point = waypoints[0];
		direction = (waypoints[0] - waypoints[1]).normalized;
		return true;
	}

	private void ApplyState(WaterFlowLabel label, WaterFlowState state)
	{
		if (label.background == null)
		{
			return;
		}
		for (int i = 0; i < stateVisuals.Length; i++)
		{
			if (stateVisuals[i].state == state)
			{
				label.background.sprite = stateVisuals[i].background;
				label.background.color = stateVisuals[i].color;
				break;
			}
		}
	}

	private static WaterFlowState StateOf(AqueductBuilding b)
	{
		if (b is RiverTap)
		{
			return WaterFlowState.Source;
		}
		if (HasSupplyIssue(b))
		{
			return WaterFlowState.SupplyIssue;
		}
		return WaterFlowState.Normal;
	}

	private static bool HasSupplyIssue(AqueductBuilding b)
	{
		if (b is BathReservoir bathReservoir)
		{
			if (bathReservoir.Group != null)
			{
				if (bathReservoir.Group.waterViable)
				{
					return AqueductFlowController.GetGroupRolledBack(bathReservoir.Group);
				}
				return true;
			}
			return false;
		}
		if (!AqueductFlowController.IsUnderserved(b))
		{
			return AqueductFlowController.WasRolledBack(b);
		}
		return true;
	}

	private static WaterPriority PriorityOf(AqueductBuilding b)
	{
		if (b is BathReservoir bathReservoir)
		{
			if (bathReservoir.Group == null)
			{
				return WaterPriority.Normal;
			}
			return (WaterPriority)bathReservoir.Group.solverPriority;
		}
		if (b is WaterTower)
		{
			return b.WaterPriorityLevel;
		}
		return WaterPriority.Normal;
	}

	private WaterFlowLabel GetPooled(int index)
	{
		while (pool.Count <= index)
		{
			pool.Add(UnityEngine.Object.Instantiate(labelPrefab, transform));
		}
		WaterFlowLabel waterFlowLabel = pool[index];
		SetActive(waterFlowLabel, active: true);
		return waterFlowLabel;
	}

	private void HideAll()
	{
		for (int i = 0; i < pool.Count; i++)
		{
			SetActive(pool[i], active: false);
		}
	}

	private static void SetActive(WaterFlowLabel label, bool active)
	{
		if (label != null && label.gameObject.activeSelf != active)
		{
			label.gameObject.SetActive(active);
		}
	}
}
