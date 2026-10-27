using System;
using UnityEngine;

public class ArcherTower : Tickable, IOutputInfo, IWorkerUIDisplay
{
	public GameObject flag;

	[Header("Range Display")]
	public Material rangeDisplayMaterial;

	public Transform rangeOrigin;

	public int rangeDisplayRadialSegments = 48;

	public float rangeDisplayRingStep = 1f;

	public float rangeOriginHeightOffset;

	[Tooltip("Arrow launch speed; higher = flatter and longer arc.")]
	public float arrowLaunchSpeed = -1f;

	private ArcherRangeDisplay rangeDisplay;

	private Building b;

	public float DPS = 2f;

	private float fullAttackTime;

	private WagePayer w;

	public float AttackRange = 5f;

	private bool firstUpdate = true;

	private const int frameSpread = 5;

	private int updateFrame = SRand.srand.Next(0, 5);

	private void Awake()
	{
		b = GetComponentInParent<Building>();
	}

	private void Start()
	{
		ArrowDamage component = GetComponent<ArrowDamage>();
		component.GetMaxRange = GetBallisticMaxRange;
		component.EffectiveDPS = EffectiveDPS;
		if (rangeOrigin == null && component.arrowHail != null)
		{
			rangeOrigin = component.arrowHail.transform;
		}
	}

	string IOutputInfo.GetError()
	{
		return null;
	}

	private float EffectiveDPS()
	{
		return DPS * (b.GetLandMassOwner().HasUpgrade(Player.UpgradeType.ArmorPiercingArrows) ? 1.33f : 1f) * (1f + 1f * b.GetAvgSkill()) * b.GetWorkerPercent();
	}

	public void PlacementValidation(ref PlacementValidationResult result)
	{
		if (result != PlacementValidationResult.ExistingStructure)
		{
			return;
		}
		Cell cellData = World.inst.GetCellData(b.GetPos());
		bool flag = true;
		for (int i = 0; i < cellData.OccupyingStructure.Count; i++)
		{
			Building building = cellData.OccupyingStructure[i];
			if (building.uniqueNameHash != World.woodcastleblockHash && building.uniqueNameHash != World.castleblockHash)
			{
				flag = false;
				break;
			}
		}
		if (flag)
		{
			result = PlacementValidationResult.Valid;
		}
	}

	private void OnInit()
	{
		b = GetComponentInParent<Building>();
		w = GetComponentInParent<WagePayer>();
		w.useHazardPay = true;
		b.visibilityChanged += B_visibilityChanged;
		b.PlacementValidaton = PlacementValidation;
		if (rangeDisplay == null)
		{
			rangeDisplay = new ArcherRangeDisplay(rangeDisplayRadialSegments, rangeDisplayMaterial, rangeDisplayRingStep);
		}
		UpdateRangeDisplayMesh();
	}

	private void OnShutdown()
	{
		b.visibilityChanged -= B_visibilityChanged;
		if (rangeDisplay != null)
		{
			rangeDisplay.Dispose();
			rangeDisplay = null;
		}
	}

	private void B_visibilityChanged(bool v)
	{
	}

	private void OnBuildingPlacement(bool undo)
	{
		Vector3 position = GetComponent<Building>().transform.position;
		int num = (int)position.x;
		int num2 = (int)position.z;
		World.inst.ForEachTile(num - 7, num2 - 7, num + 7, num2 + 7, (int x, int z, Cell cell) =>
		{
			cell.Danger += ((!undo) ? 1 : (-1));
		});
		BlockBuilding.MarkBlockStackDirty(b.GetCell());
	}

	public override void Tick(float dt, int currFrame)
	{
		if (currFrame % 5 == updateFrame || firstUpdate)
		{
			firstUpdate = false;
			bool flag = b.AreWorkersNear(b.jobs.Count);
			b.GetWorkerPercent();
			UpdateRangeDisplayVisibility();
		}
	}

	private void OnSelectionChanged()
	{
		UpdateRangeDisplayVisibility();
	}

	public bool CanHit(Vector3 targetPosition)
	{
		Vector3 origin = GetRangeOrigin(out var _);
		return rangeDisplay.CanHit(origin, targetPosition);
	}

	private void UpdateRangeDisplayVisibility()
	{
		bool flag = GameUI.inst.GetBuildingSelected() == b;
		bool flag2 = GameUI.inst.CurrPlacementMode.IsPlacing() && GameUI.inst.CurrPlacementMode.GetHoverBuilding() == b;
		bool flag3 = (flag | flag2) && b.Life > 0f;
		if (flag3 && GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			rangeDisplay.GameObject.transform.SetParent(transform, worldPositionStays: false);
		}
		if (rangeDisplay != null)
		{
			Vector3 origin = GetRangeOrigin(out var _);
			rangeDisplay.SetOrigin(origin);
			rangeDisplay.SetVisible(flag3);
		}
	}

	private void UpdateRangeDisplayMesh()
	{
		if (rangeDisplay != null && !(b == null))
		{
			Vector3 origin = GetRangeOrigin(out var launchHeight);
			rangeDisplay.SetOrigin(origin);
			float launchSpeed = GetLaunchSpeed(launchHeight);
			rangeDisplay.Rebuild(launchSpeed, launchHeight);
			if (rangeDisplay.GameObject.transform.parent != null && !IsPlacing())
			{
				rangeDisplay.GameObject.transform.SetParent(null, worldPositionStays: true);
			}
		}
	}

	private Vector3 GetRangeOrigin(out float launchHeight)
	{
		Vector3 result = b.Center();
		float y = result.y;
		float y2 = result.y;
		if (rangeOrigin != null)
		{
			y2 = rangeOrigin.position.y;
		}
		y2 += rangeOriginHeightOffset;
		launchHeight = Mathf.Max(0f, y2 - y);
		return result;
	}

	public float GetLaunchSpeed(float launchHeight = 0f)
	{
		if (arrowLaunchSpeed > 0f)
		{
			return arrowLaunchSpeed;
		}
		float num = AttackRange;
		if (num <= 0.01f)
		{
			num = 1f;
		}
		Mathf.Sin(MathF.PI / 4f);
		float num2 = Mathf.Cos(MathF.PI / 4f);
		float num3 = 2f * num2 * num2 * (launchHeight + num * Mathf.Tan(MathF.PI / 4f));
		if (num3 <= Mathf.Epsilon)
		{
			return 1f;
		}
		float num4 = Mathf.Sqrt(Mathf.Abs(Physics.gravity.y) * num * num / num3);
		return Mathf.Max(0.1f, num4);
	}

	public float GetBallisticMaxRange()
	{
		GetRangeOrigin(out var launchHeight);
		float launchSpeed = GetLaunchSpeed(launchHeight);
		float num = Mathf.Sin(MathF.PI / 4f);
		float num2 = Mathf.Cos(MathF.PI / 4f);
		float num3 = launchSpeed * num;
		float num4 = Mathf.Sqrt(num3 * num3 + 2f * Mathf.Abs(Physics.gravity.y) * launchHeight);
		float num5 = (num3 + num4) / Mathf.Abs(Physics.gravity.y);
		return launchSpeed * num2 * num5;
	}

	private bool IsPlacing()
	{
		if (GameUI.inst != null && GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			return GameUI.inst.CurrPlacementMode.GetHoverBuilding() == b;
		}
		return false;
	}

	private void OnDestroy()
	{
		if (rangeDisplay != null)
		{
			rangeDisplay.Dispose();
			rangeDisplay = null;
		}
	}

	public bool ShowOpenClose()
	{
		return true;
	}

	public bool ShowDemolish()
	{
		return true;
	}
}
