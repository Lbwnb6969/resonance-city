using System.Collections.Generic;
using Assets.Code;
using Assets.Code.Interface;
using I2.Loc;
using UnityEngine;

public class Mason : Tickable, IOutputInfo, IWorkerUIDisplay, IOverlayUser
{
	public struct BuildingMasonSet
	{
		public Mason mason;

		public Building building;
	}

	public Transform hammerPrefab;

	private Transform hammer;

	public float hammerAngle = 45f;

	public float hammerAnimSpeed = 1f;

	public static Dictionary<Building, Mason> activeRepairList = new Dictionary<Building, Mason>(64);

	private List<PromisedBuildResource> PromisedBuildResources = new List<PromisedBuildResource>();

	private ResourceAmount ConsumedForRepair = new ResourceAmount();

	private ResourceAmount TotalPromisedRepairResources = new ResourceAmount();

	private ResourceAmount RepairCost = new ResourceAmount();

	private Building b;

	internal Building damagedBuilding;

	private const int frameSpread = 10;

	private int updateFrame = SRand.srand.Next(0, 10);

	private float time;

	public float Radius = 12f;

	private float timeWithoutResources;

	private RenderInstance[] scaffolds;

	private int missingResourceID;

	public Color overlayColor;

	bool IOverlayUser.OverlayWhenPlacing => true;

	bool IOverlayUser.OverlayWhenSelected => true;

	public int LandMass()
	{
		return b.LandMass();
	}

	private void Awake()
	{
		b = GetComponent<Building>();
		hammer = Object.Instantiate(hammerPrefab);
		hammer.gameObject.SetActive(value: false);
	}

	public override void Tick(float dt, int currFrame)
	{
		time += Time.unscaledDeltaTime * hammerAnimSpeed;
		float num = Mathf.Sin(time);
		float t = num * num;
		if (currFrame % 10 == updateFrame && b.IsBuilt() && b.WorkersAllocated > 0)
		{
			if (damagedBuilding == null)
			{
				List<Building> list = Player.inst.DamagedList[b.LandMass()];
				float num2 = float.MaxValue;
				Building building = null;
				Vector3 pos = b.GetPos();
				float num3 = (Radius + 1f) * (Radius + 1f);
				for (int i = 0; i < list.Count; i++)
				{
					Building building2 = list[i];
					if (!(building2 == null) && building2.IsDamaged() && !building2.IsBeingDamaged() && !IsAlreadySelected(building2))
					{
						float num4 = Mathff.DistSqrdXZ(building2.GetPos(), pos);
						if (building2.Life / building2.ModifiedMaxLife < num2 && num4 < num3)
						{
							building = building2;
							num2 = building2.Life / building2.ModifiedMaxLife;
						}
					}
				}
				if (building != null)
				{
					activeRepairList.Add(building, this);
					UpdateRepairCost(building);
					PromisedBuildResources.Clear();
					ConsumedForRepair.Clear();
					TotalPromisedRepairResources.Clear();
					damagedBuilding = building;
					Vector3 position = building.Center();
					position.y = building.size.y * 1.5f;
					hammer.transform.position = position;
					hammer.gameObject.SetActive(value: true);
				}
			}
			missingResourceID = -1;
			for (int j = 0; j < b.jobs.Count; j++)
			{
				if (b.jobs[j].HasEmployee() && b.jobs[j] is MasonJob { status: MasonJob.Status.SearchingForResource, resourceProvider: null } masonJob)
				{
					missingResourceID = masonJob.seekingType;
					break;
				}
			}
			if (missingResourceID != -1)
			{
				timeWithoutResources += dt * 10f;
			}
			else
			{
				timeWithoutResources = 0f;
			}
			if (timeWithoutResources > 0f)
			{
				b.thought.thought = ThoughtBubbleSystem.Thought.GeneralError;
				b.thought.visible = true;
			}
			else if (b.thought.thought != ThoughtBubbleSystem.Thought.Tired)
			{
				b.thought.visible = false;
			}
		}
		if (damagedBuilding != null)
		{
			if (!b.IsBuilt() && b.WorkersAllocated <= 0)
			{
				ClearDamagedBuilding();
				return;
			}
			if (damagedBuilding.IsBeingDamaged())
			{
				ResetMasonTarget();
				return;
			}
			float z = Mathff.Lerp(0f - hammerAngle, hammerAngle, t);
			hammer.localRotation = Quaternion.Euler(new Vector3(0f, 0f, z));
			if (scaffolds == null)
			{
				scaffolds = new RenderInstance[128];
				for (int k = 0; k < scaffolds.Length; k++)
				{
					scaffolds[k] = new RenderInstance(World.inst.scaffoldMesh, World.inst.romeUnimaterial);
				}
			}
			int l = 0;
			for (int m = 0; (float)m < damagedBuilding.size.y; m++)
			{
				damagedBuilding.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
				for (int n = minZ; n <= maxZ; n++)
				{
					for (int num5 = minX; num5 <= maxX; num5++)
					{
						if ((num5 == minX || n == minZ || num5 == maxX || n == maxZ) && l < scaffolds.Length)
						{
							Vector3 pos2 = new Vector3((float)num5 + 0.5f, damagedBuilding.xform.position.y + (float)m * 0.35f, (float)n + 0.5f);
							scaffolds[l].UpdateTRS(pos2, Quaternion.identity, new Vector3(1f, 1f, 1f));
							scaffolds[l].Visible = true;
							l++;
						}
					}
				}
			}
			for (; l < scaffolds.Length; l++)
			{
				scaffolds[l].Visible = false;
			}
		}
		else if (scaffolds != null && scaffolds[0].Visible)
		{
			for (int num6 = 0; num6 < scaffolds.Length; num6++)
			{
				scaffolds[num6].Visible = false;
			}
		}
	}

	public bool IsAlreadySelected(Building building)
	{
		if (building.categoryHash == World.castleblockHash)
		{
			List<Building> occupyingStructure = building.GetCell().OccupyingStructure;
			for (int i = 0; i < occupyingStructure.Count; i++)
			{
				if (activeRepairList.ContainsKey(occupyingStructure[i]))
				{
					return true;
				}
			}
		}
		if (activeRepairList.ContainsKey(building))
		{
			return true;
		}
		return false;
	}

	public void PromiseResources(int _resourceID, int num, Villager villager)
	{
		PromisedBuildResources.Add(new PromisedBuildResource
		{
			resourceID = _resourceID,
			amount = num,
			promiser = villager
		});
		TotalPromisedRepairResources.Add(_resourceID, num);
	}

	public bool HasEnoughToRepair()
	{
		for (int i = 0; i < RepairCost.resources.Count; i++)
		{
			Resource resource = RepairCost.resources[i];
			if (TotalPromisedRepairResources.Get(resource.resourceID) + ConsumedForRepair.Get(resource.resourceID) < resource.Amount)
			{
				return false;
			}
		}
		return true;
	}

	public void FinishRepair()
	{
		if (!(damagedBuilding != null))
		{
			return;
		}
		ResourceStatistics.AddConsumption(b.LandMass(), b.UniqueName, ConsumedForRepair);
		PromisedBuildResources.Clear();
		ConsumedForRepair.Clear();
		TotalPromisedRepairResources.Clear();
		float decayProtection = damagedBuilding.decayProtection;
		float num = damagedBuilding.ModifiedMaxLife - damagedBuilding.Life;
		decayProtection = Mathff.Max(0.2f, 1f - num);
		float amount = Mathf.CeilToInt(damagedBuilding.ModifiedMaxLife * 0.09f);
		damagedBuilding.Repair(amount);
		if (damagedBuilding.Life == damagedBuilding.ModifiedMaxLife)
		{
			SfxSystem.inst.PlayFromBankIfVisible("MasonRepairComplete", damagedBuilding.Center());
			damagedBuilding.decayProtection = decayProtection;
			Home component = damagedBuilding.GetComponent<Home>();
			if (component != null)
			{
				component.RefreshBonuses();
			}
			ClearDamagedBuilding();
			RepairCost.Clear();
		}
	}

	public void AddRepairResource(int type, int amount)
	{
		ConsumedForRepair.Add(type, amount);
	}

	public void EndPromise(Villager villager)
	{
		ResourceAmount resourceAmount = new ResourceAmount();
		for (int i = 0; i < PromisedBuildResources.Count; i++)
		{
			if (PromisedBuildResources[i].promiser == villager)
			{
				resourceAmount.Add(PromisedBuildResources[i].resourceID, PromisedBuildResources[i].amount);
				PromisedBuildResources.RemoveAt(i);
				i--;
			}
		}
		TotalPromisedRepairResources.TrySubtract(resourceAmount);
	}

	public int ResourcesNeededToFinishRepair(int rID)
	{
		if (rID == 4)
		{
			return 0;
		}
		return RepairCost.Get(rID) - (TotalPromisedRepairResources.Get(rID) + ConsumedForRepair.Get(rID));
	}

	public void ClearDamagedBuilding()
	{
		if (scaffolds != null)
		{
			for (int i = 0; i < scaffolds.Length; i++)
			{
				scaffolds[i].Visible = false;
			}
		}
		if ((bool)damagedBuilding)
		{
			activeRepairList.Remove(damagedBuilding);
		}
		damagedBuilding = null;
		hammer.gameObject.SetActive(value: false);
	}

	public void ResetMasonTarget()
	{
		ClearDamagedBuilding();
		TotalPromisedRepairResources.Clear();
		ConsumedForRepair.Clear();
		RepairCost.Clear();
		PromisedBuildResources.Clear();
	}

	public void UpdateMasonsTarget()
	{
		for (int i = 0; i < b.jobs.Count; i++)
		{
			if (b.jobs[i] is MasonJob masonJob && masonJob.HasEmployee())
			{
				masonJob.damagedBuilding = damagedBuilding;
				if ((bool)damagedBuilding)
				{
					masonJob.SetStatus(MasonJob.Status.SearchingForResource);
				}
				else
				{
					masonJob.SetStatus(MasonJob.Status.Idle);
				}
			}
		}
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(MasonJob)))
			{
				b.SetAndAddJob(i, new MasonJob(b, this));
			}
		}
	}

	private void UpdateRepairCost(Building b)
	{
		ResourceAmount cost = b.GetCost(b.LandMass());
		for (int i = 0; i < cost.resources.Count; i++)
		{
			Resource resource = cost.resources[i];
			if (resource.resourceID != 4)
			{
				RepairCost.Set(resource.resourceID, Mathf.CeilToInt((float)resource.Amount * 0.075f));
			}
		}
	}

	private void OnShutdown()
	{
		ClearDamagedBuilding();
		if ((bool)hammer)
		{
			Object.Destroy(hammer.gameObject);
		}
	}

	public string GetError()
	{
		if (b.thought.thought == ThoughtBubbleSystem.Thought.GeneralError && b.thought.visible)
		{
			return string.Format(ScriptLocalization.workerui_error_noresourceavailable, ResourceAmount.ResourceIcon(missingResourceID));
		}
		return "";
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}

	private static void DrawIndividual(Mason m)
	{
		Building building = m.b;
		Vector3 pos = building.Center().xz();
		World.inst.ForEachTileTouchingRadius(pos, m.Radius, (int x, int z, Cell cell) =>
		{
			if (Mathff.DistSqrdXZ(pos, cell.Center2D) <= m.Radius * m.Radius)
			{
				TerrainGen.inst.SetOverlayTileColorNoBuilding(x, z, m.overlayColor);
				for (int i = 0; i < cell.OccupyingStructure.Count; i++)
				{
					if (cell.OccupyingStructure[i].uniqueNameHash != World.masonHash)
					{
						cell.OccupyingStructure[i].SetInfoColor(m.overlayColor);
						TerrainGen.inst.AddBuildingToOverlay(cell.OccupyingStructure[i]);
					}
				}
			}
		});
	}

	void IOverlayUser.DrawOverlay(Vector3 origin)
	{
		TerrainGen.inst.ClearOverlay(updateToo: false);
		int focusedLandMass = Player.inst.FocusedLandMass;
		ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(focusedLandMass, World.masonHash);
		for (int i = 0; i < buildingListForLandMass.Count; i++)
		{
			DrawIndividual(buildingListForLandMass.data[i].GetComponent<Mason>());
		}
		if (!b.IsPlaced())
		{
			DrawIndividual(this);
		}
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}
}
