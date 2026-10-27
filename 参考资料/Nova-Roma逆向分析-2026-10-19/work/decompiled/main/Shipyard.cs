using System;
using System.Collections.Generic;
using Assets.Code;
using Assets.Code.Jobs;
using Assets.Interface;
using UnityEngine;

public class Shipyard : MonoBehaviour, IResourceStorageBase, IWorkerUIDisplay
{
	[Serializable]
	public class ShipBuildItem
	{
		public string titleTerm;

		public ResourceAmount constructCost;

		public GameObject spawnPrefab;

		public MeshRenderer shipInProgress;

		public string unlockKey;
	}

	[Serializable]
	public class ShipyardSaveData : SaveClass<Shipyard, ShipyardSaveData>
	{
		private ResourceAmount resources;

		private bool constructing;

		private int currItem;

		private float constructionProgress;

		public override ShipyardSaveData Pack(Shipyard obj)
		{
			constructing = obj.constructing;
			currItem = obj.currBuildItemIdx;
			resources = obj.currStorage;
			constructionProgress = obj.constructionProgress;
			return this;
		}

		public override Shipyard Unpack(Shipyard obj)
		{
			obj.currStorage = resources;
			obj.currBuildItemIdx = currItem;
			if (constructing)
			{
				obj.TryStartConstruction(fromLoad: true);
			}
			obj.constructionProgress = constructionProgress;
			return obj;
		}
	}

	public Transform[] waterMarkers;

	public Transform[] optionalWaterMarkers;

	public Transform[] landMarkers;

	private int[] gatherTypes;

	public Building b;

	internal ResourceAmount currStorage = new ResourceAmount();

	internal ResourceAmount currStorageMax = new ResourceAmount();

	private int[] gatherTypeOrder;

	public float terrainDrop = 0.25f;

	private ArrayExt<int> typesAvailableToCollect = new ArrayExt<int>(5);

	public Material constructMaterial;

	public List<ShipBuildItem> buildItems;

	internal int currBuildItemIdx;

	public float minHeight = 0.5f;

	public Transform rallyPoint;

	public float constructionTime = 30f;

	private float constructionProgress;

	private bool constructing;

	private OneOffEffect buildEffect;

	private ResourceAmount freeCost = new ResourceAmount();

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		int num = 0;
		for (int i = 0; i < waterMarkers.Length; i++)
		{
			if (World.inst.GetCellDataClamped(waterMarkers[i].position).Type == TerrainType.Water)
			{
				num++;
			}
		}
		if (num != waterMarkers.Length)
		{
			validationResult = PlacementValidationResult.MustFaceOcean;
		}
		else
		{
			if (validationResult != PlacementValidationResult.MustBeOnFlatLand)
			{
				return;
			}
			bool flag = true;
			for (int j = 0; j < landMarkers.Length; j++)
			{
				if (World.inst.GetCellData(landMarkers[j].position).Type != TerrainType.None)
				{
					flag = false;
				}
			}
			bool flag2 = false;
			for (int k = 0; k < optionalWaterMarkers.Length; k++)
			{
				if (World.inst.GetCellData(optionalWaterMarkers[k].position).Type == TerrainType.Obstruction)
				{
					flag2 = false;
				}
			}
			if (flag && !flag2)
			{
				validationResult = PlacementValidationResult.Valid;
			}
		}
	}

	public void Deposit(ref ResourceAmount resources)
	{
		ResourceAmount currConstructCost = GetCurrConstructCost();
		for (int i = 0; i < currConstructCost.resources.Count; i++)
		{
			int resourceID = currConstructCost.resources[i].resourceID;
			int num = Mathff.Min(SpaceAvailable(resourceID), resources.Get(resourceID));
			currStorage.Add(resourceID, num);
			resources.Add(resourceID, -num);
		}
	}

	public int SpaceAvailable(int resourceID)
	{
		return currStorageMax.Get(resourceID) - currStorage.Get(resourceID);
	}

	public Vector3 DropOffLocation(int resourceID)
	{
		return b.Center();
	}

	private void Start()
	{
		b.PlacementValidaton = PlacementValidation;
		constructMaterial = UnityEngine.Object.Instantiate(constructMaterial);
	}

	private void OnAddJobs()
	{
		for (int i = 0; (float)i < (float)b.WorkersForFullYield * 0.6f; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(i, new FreeResourceGathererJob(b, _consumeOnPickup: true));
			}
			FreeResourceGathererJob obj = b.jobs[i] as FreeResourceGathererJob;
			obj.searchRadius = 30f;
			obj.typeOrder = gatherTypeOrder;
			obj.meshType = VillagerSystem.MeshType.HandCart;
			obj.bonusCarryCapacity = 3;
		}
	}

	public void OnBuilt()
	{
		Vector3 vector = b.Center() + b.GetOffset().transform.forward * 0.25f;
		if (b.revertLandOnDemolish)
		{
			b.CaptureTerrainForRevertDepression((int)vector.x, (int)vector.z, 0, 0, 2);
		}
		TerrainGen.inst.MakeSquareDepression((int)vector.x, (int)vector.z, 0, 0, 2, terrainDrop);
	}

	public bool CanConstruct(int itemIdx)
	{
		if (IsConstructing() || b.WorkersAllocated <= 0 || !HasCostForConstruction(itemIdx))
		{
			return false;
		}
		return true;
	}

	public bool HasCostForConstruction(int itemIdx)
	{
		if (!Player.inst.resourcesPerLandmass[b.LandMass()].HasCost(GetConstructCost(itemIdx)))
		{
			return false;
		}
		if (World.GetLandmassOwner(b.LandMass()).Gold < GetConstructCost(itemIdx).Get(4))
		{
			return false;
		}
		return true;
	}

	private void Update()
	{
		if (!b.IsPlaced())
		{
			Vector3 localPosition = b.GetOffset().localPosition;
			localPosition.y = 0f;
			b.GetOffset().localPosition = localPosition;
			if (b.GetOffset().position.y < minHeight)
			{
				Vector3 position = b.GetOffset().position;
				position.y = minHeight;
				b.GetOffset().position = position;
			}
		}
		MeshRenderer shipInProgress = buildItems[currBuildItemIdx].shipInProgress;
		if (IsConstructing())
		{
			Home.BuildGatherTypeOrder(b.LandMass(), typesAvailableToCollect, ref gatherTypeOrder, currStorage, currStorageMax, gatherTypes);
			if (Creative.inst.IsCreativeOptionOn(11))
			{
				if (!Creative.inst.IsCreativeOptionOn(0))
				{
					ConsumeOutstandingMaterialsFromWorld();
				}
				constructionProgress = 1f;
			}
			else
			{
				constructionProgress = Mathff.Clamp01(Mathf.Min(GetResourceFraction(), constructionProgress + Time.deltaTime / constructionTime));
			}
			float progress = GetProgress();
			if (progress >= 1f)
			{
				SpawnShip();
				EndConstruction(refund: false);
			}
			else
			{
				buildEffect.transform.position = shipInProgress.transform.position;
				constructMaterial.SetFloat("_WallProgress", Mathff.Max(progress, 0.1f));
				constructMaterial.SetFloat("_MinHeight", Mathff.Max(shipInProgress.bounds.min.y, TerrainGen.SeaLevel));
				if (shipInProgress.bounds.min.y < TerrainGen.SeaLevel)
				{
					constructMaterial.SetFloat("_MinYAdjustment", 0f);
				}
				constructMaterial.SetFloat("_MaxHeight", shipInProgress.bounds.max.y);
				shipInProgress.material = constructMaterial;
			}
		}
		for (int i = 0; i < buildItems.Count; i++)
		{
			Util.SetActive(buildItems[i].shipInProgress.gameObject, IsConstructing() && currBuildItemIdx == i);
		}
	}

	public bool IsConstructing()
	{
		return constructing;
	}

	private void SpawnShip()
	{
		MeshRenderer shipInProgress = buildItems[currBuildItemIdx].shipInProgress;
		GameObject gameObject = UnityEngine.Object.Instantiate(buildItems[currBuildItemIdx].spawnPrefab);
		gameObject.GetComponent<ShipBase>().SetPos(shipInProgress.transform.position);
		gameObject.GetComponent<ShipBase>().Init(GetComponent<Building>().TeamID());
		gameObject.transform.rotation = transform.GetChild(0).rotation;
		EffectsMan.inst.BuildPuff.CreateAndPlay(shipInProgress.transform.position);
		EffectsMan.inst.WaterHitEffect.CreateAndPlay(shipInProgress.transform.position);
		if (gameObject.GetComponent<UnitTransportShip>() != null)
		{
			UnitSystem.inst.MoveTo(gameObject.GetComponent<UnitTransportShip>(), World.inst.GetCellDataClamped(rallyPoint.position));
		}
		else if (gameObject.GetComponent<ShipBase>() != null)
		{
			gameObject.GetComponent<ShipBase>().MoveTo(World.inst.GetCellDataClamped(rallyPoint.position), displayPath: false);
		}
	}

	public void TryStartConstruction(bool fromLoad)
	{
		if (Creative.inst.IsCreativeOptionOn(11))
		{
			if (!fromLoad && !Creative.inst.IsCreativeOptionOn(0))
			{
				ResourceAmount currConstructCost = GetCurrConstructCost();
				World.GetLandmassOwner(b.LandMass()).Gold -= currConstructCost.Get(4);
				for (int i = 0; i < currConstructCost.resources.Count; i++)
				{
					Resource resource = currConstructCost.resources[i];
					if (resource.resourceID != 4 && resource.Amount > 0)
					{
						FreeResourceManager.inst.RemovePhysicalResources(resource.resourceID, resource.Amount, b.LandMass());
						ResourceStatistics.AddConsumption(b.LandMass(), "construction", resource.resourceID, resource.Amount);
					}
				}
			}
			SpawnShip();
			return;
		}
		ResourceAmount currConstructCost2 = GetCurrConstructCost();
		int num = 0;
		for (int j = 0; j < currConstructCost2.resources.Count; j++)
		{
			if (currConstructCost2.resources[j].resourceID != 4)
			{
				num++;
			}
		}
		gatherTypes = new int[num];
		for (int k = 0; k < currConstructCost2.resources.Count; k++)
		{
			if (currConstructCost2.resources[k].resourceID != 4)
			{
				gatherTypes[k] = currConstructCost2.resources[k].resourceID;
			}
		}
		gatherTypeOrder = new int[gatherTypes.Length];
		currStorageMax.Clear();
		for (int l = 0; l < currConstructCost2.resources.Count; l++)
		{
			currStorageMax.Set(currConstructCost2.resources[l].resourceID, currConstructCost2.resources[l].Amount);
		}
		constructionProgress = 0f;
		constructing = true;
		Vector3 position = buildItems[currBuildItemIdx].shipInProgress.transform.position;
		buildEffect = EffectsMan.inst.BuildEffect.CreateAndPlay(position);
		if (!fromLoad)
		{
			World.GetLandmassOwner(b.LandMass()).Gold -= currConstructCost2.Get(4);
			EffectsMan.inst.BuildPuff.CreateAndPlay(position);
		}
	}

	private void EndConstruction(bool refund)
	{
		if (refund)
		{
			World.GetLandmassOwner(b.LandMass()).Gold += GetCurrConstructCost().Get(4);
		}
		constructing = false;
		constructionProgress = 0f;
		currStorage.Clear();
		currStorageMax.Clear();
		if (buildEffect != null)
		{
			buildEffect.Stop();
			buildEffect.Release();
			buildEffect = null;
		}
	}

	public void TryCancelConstruction()
	{
		EndConstruction(refund: true);
	}

	private void OnDestroy()
	{
		if (buildEffect != null)
		{
			buildEffect.Stop();
			buildEffect.Release();
			buildEffect = null;
		}
	}

	public ResourceAmount GetCurrConstructCost()
	{
		return GetConstructCost(currBuildItemIdx);
	}

	public ResourceAmount GetConstructCost(int itemIdx)
	{
		if (Creative.inst.IsCreativeOptionOn(0))
		{
			return freeCost;
		}
		return buildItems[itemIdx].constructCost;
	}

	public float GetProgress()
	{
		return constructionProgress;
	}

	private float GetResourceFraction()
	{
		int num = 0;
		ResourceAmount currConstructCost = GetCurrConstructCost();
		for (int i = 0; i < currConstructCost.resources.Count; i++)
		{
			if (currConstructCost.resources[i].resourceID != 4)
			{
				num += currConstructCost.resources[i].Amount;
			}
		}
		if (num == 0)
		{
			return 1f;
		}
		int num2 = 0;
		for (int j = 0; j < currStorage.resources.Count; j++)
		{
			if (currStorage.resources[j].resourceID != 4)
			{
				num2 += currStorage.resources[j].Amount;
			}
		}
		return (float)num2 / (float)num;
	}

	private void ConsumeOutstandingMaterialsFromWorld()
	{
		ResourceAmount currConstructCost = GetCurrConstructCost();
		for (int i = 0; i < currConstructCost.resources.Count; i++)
		{
			Resource resource = currConstructCost.resources[i];
			if (resource.resourceID != 4)
			{
				int num = resource.Amount - currStorage.Get(resource.resourceID);
				if (num > 0)
				{
					FreeResourceManager.inst.RemovePhysicalResources(resource.resourceID, num, b.LandMass());
					ResourceStatistics.AddConsumption(b.LandMass(), "construction", resource.resourceID, num);
					currStorage.Set(resource.resourceID, resource.Amount);
				}
			}
		}
	}

	bool IWorkerUIDisplay.ShowOpenClose()
	{
		return true;
	}

	bool IWorkerUIDisplay.ShowDemolish()
	{
		return true;
	}
}
