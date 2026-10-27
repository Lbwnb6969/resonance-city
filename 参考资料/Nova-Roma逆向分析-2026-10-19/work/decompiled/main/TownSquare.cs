using System;
using FMOD.Studio;
using UnityEngine;

public class TownSquare : MonoBehaviour, IWorkerUIDisplay
{
	private enum FestivalStage
	{
		Starting,
		Running,
		Ending,
		Done
	}

	public GameObject[] festivalBuildings;

	private Building b;

	public GameObject pumpkins;

	private EventInstance festivalSfx;

	public float FestivalDuration = 30f;

	private int[] HappinessBoost = new int[5] { 15, 10, 5, 3, 1 };

	private FestivalStage stage = FestivalStage.Done;

	private float startTime = -999f;

	public bool ShowOpenClose()
	{
		return true;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public int GetFestivalCost()
	{
		int count = World.inst.GetVillagersForLandMass(b.LandMass()).Count;
		int result = 50;
		if (count > 250)
		{
			result = 75;
		}
		if (count > 500)
		{
			result = 100;
		}
		if (count > 750)
		{
			result = 150;
		}
		if (count > 1000)
		{
			result = 200;
		}
		if (count > 2000)
		{
			result = 300;
		}
		if (count > 3000)
		{
			result = 400;
		}
		return result;
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		PlacementValidationResult result = PlacementValidationResult.Valid;
		b.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			if ((bool)cell.TopStructure && World.IsLandRoad(cell.TopStructure))
			{
				result = PlacementValidationResult.Valid;
			}
			if (cell.Type != TerrainType.None)
			{
				result = PlacementValidationResult.MustBeOnFlatLand;
			}
			if (cell.OccupyingStructure.Count > 0 && !cell.TopStructureCategoryIs(World.pathHash))
			{
				result = PlacementValidationResult.ExistingStructure;
			}
		});
		validationResult = result;
	}

	public bool TryStartFestival()
	{
		if (World.GetLandmassOwner(b.LandMass()).Gold >= GetFestivalCost())
		{
			World.GetLandmassOwner(b.LandMass()).Gold -= GetFestivalCost();
			BeginFestival();
			return true;
		}
		return false;
	}

	private void Awake()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
		for (int i = 0; i < festivalBuildings.Length; i++)
		{
			festivalBuildings[i].transform.localScale = Vector3.zero;
		}
	}

	private void OnInit()
	{
		pumpkins.SetActive(value: false);
		try
		{
			if (DateTime.Now.Month == 10)
			{
				pumpkins.SetActive(value: true);
				FOWHider component = GetComponent<FOWHider>();
				GameObject[] array = new GameObject[component.toHide.Length];
				component.toHide.CopyTo(array, 0);
				array[^1] = pumpkins;
				component.toHide = array;
			}
		}
		catch
		{
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		int num = 1;
		Vector3 bounds = b.GetBounds();
		Vector3 position = GetComponent<Building>().transform.position;
		int num2 = (int)position.x;
		int num3 = (int)position.z;
		int num4 = Mathf.Max(num2 - num, 0);
		int num5 = Mathf.Max(num3 - num, 0);
		int num6 = Mathf.Min(num2 + Mathf.RoundToInt(bounds.x) + num, World.inst.GridWidth - 1);
		int num7 = Mathf.Min(num3 + Mathf.RoundToInt(bounds.z) + num, World.inst.GridHeight - 1);
		for (int i = num4; i < num6; i++)
		{
			for (int j = num5; j < num7; j++)
			{
				if ((i != num4 || (j != num5 && j != num7 - 1)) && (i != num6 - 1 || (j != num5 && j != num7 - 1)))
				{
					World.inst.GetCellData(i, j).AddRoadCoverage((!undo) ? 1 : (-1));
				}
			}
		}
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(b.TeamID());
		GetComponentInChildren<SkinnedMeshRenderer>().material.mainTexture = landmassOwnerByTeamId.BannerTexture;
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Combine(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
	}

	private void OnShutdown()
	{
		AdjacentMesh.RefreshSurroundingRoads(GetComponent<Building>());
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Remove(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
	}

	public void UpdateBanners()
	{
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(b.TeamID());
		GetComponentInChildren<SkinnedMeshRenderer>(includeInactive: true).material.mainTexture = landmassOwnerByTeamId.BannerTexture;
	}

	public void BeginFestival()
	{
		stage = FestivalStage.Starting;
		festivalSfx = SfxSystem.inst.PlayFromBankIfVisible("EventFestival", transform.position);
	}

	public bool IsFestivalDone()
	{
		return stage == FestivalStage.Done;
	}

	public bool FestivalActive()
	{
		return stage != FestivalStage.Done;
	}

	private void Update()
	{
		float deltaTime = Time.deltaTime;
		switch (stage)
		{
		case FestivalStage.Starting:
		{
			for (int j = 0; j < festivalBuildings.Length; j++)
			{
				festivalBuildings[j].transform.localScale = Vector3.Lerp(festivalBuildings[j].transform.localScale, Vector3.one, deltaTime * 10f);
			}
			if (!(festivalBuildings[0].transform.localScale.x > 0.99f))
			{
				break;
			}
			stage = FestivalStage.Running;
			startTime = Time.time;
			int num = 0;
			ArrayExt<Building> buildingList = Player.inst.GetBuildingList("townsquare");
			LandmassOwner landmassOwner = World.GetLandmassOwner(b.LandMass());
			for (int k = 0; k < buildingList.Count; k++)
			{
				if (!(World.GetLandmassOwner(buildingList.data[k].LandMass()) != landmassOwner) && !(buildingList.data[k] == b) && buildingList.data[k].GetComponent<TownSquare>().stage != FestivalStage.Done)
				{
					num++;
				}
			}
			num = Mathff.Clamp(num, 0, HappinessBoost.Length - 1);
			Player.inst.AddHappinessMod("festival", FestivalDuration, HappinessBoost[num], "ScriptLocalization.TownSquareHappinessMod", b.GetCell().landMassIdx, addition: true);
			break;
		}
		case FestivalStage.Running:
			if (Time.time - startTime > FestivalDuration)
			{
				stage = FestivalStage.Ending;
				TrySettleAttractedPeople();
			}
			break;
		case FestivalStage.Ending:
		{
			for (int i = 0; i < festivalBuildings.Length; i++)
			{
				festivalBuildings[i].transform.localScale = Vector3.Lerp(festivalBuildings[i].transform.localScale, Vector3.zero, deltaTime * 5f);
			}
			festivalSfx.stop(STOP_MODE.ALLOWFADEOUT);
			if (festivalBuildings[0].transform.localScale.x < 0.001f)
			{
				stage = FestivalStage.Done;
			}
			break;
		}
		}
	}

	private void TrySettleAttractedPeople()
	{
	}

	private void OnAddJobs(Building b)
	{
		if (!b.VerifyJobIs(0, typeof(IdleJob)))
		{
			b.SetAndAddJob(0, new IdleJob(b, IdleJob.IdleBehavior.Wander));
		}
		for (int i = 1; i < b.attractionPositions.Length; i++)
		{
			if (!b.VerifyJobIs(i, typeof(IdleJob)))
			{
				b.SetAndAddJob(i, new IdleJob(b, IdleJob.IdleBehavior.Looking));
			}
		}
	}
}
