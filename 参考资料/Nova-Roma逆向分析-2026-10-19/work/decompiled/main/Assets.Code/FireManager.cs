using System;
using System.Collections.Generic;
using I2.Loc;
using UnityEngine;

namespace Assets.Code;

public class FireManager : MonoBehaviour
{
	[Serializable]
	public class FireManagerSaveData : SaveClass<FireManager, FireManagerSaveData>
	{
		private Fire.FireSaveData[] _fireData;

		public override FireManagerSaveData Pack(FireManager d)
		{
			Fire[] componentsInChildren = d.fireContainer.transform.GetComponentsInChildren<Fire>();
			List<Fire.FireSaveData> list = new List<Fire.FireSaveData>();
			Fire[] array = componentsInChildren;
			foreach (Fire fire in array)
			{
				if (!fire.Dying)
				{
					list.Add(new Fire.FireSaveData().Pack(fire));
				}
			}
			_fireData = list.ToArray();
			return this;
		}

		public override FireManager Unpack(FireManager d)
		{
			Fire.FireSaveData[] fireData = _fireData;
			foreach (Fire.FireSaveData fireSaveData in fireData)
			{
				Cell cellData = World.inst.GetCellData(fireSaveData.pos);
				Fire obj = d.FirePrefab.Create(cellData.Position, d.FirePrefab.transform.rotation);
				fireSaveData.Unpack(obj);
			}
			return d;
		}
	}

	public static FireManager inst;

	public Fire FirePrefab;

	public GameObject fireContainer;

	private void Awake()
	{
		inst = this;
	}

	public Fire ClosestFireWithinRadius(Vector3 pos, float radius = float.PositiveInfinity, bool includeFullFires = false)
	{
		float num = radius;
		Fire result = null;
		Fire[] componentsInChildren = fireContainer.GetComponentsInChildren<Fire>();
		foreach (Fire fire in componentsInChildren)
		{
			if (includeFullFires || !fire.FullOfFighters())
			{
				float num2 = Vector3.Distance(pos, fire.transform.position);
				if (num2 < num)
				{
					num = num2;
					result = fire;
				}
			}
		}
		return result;
	}

	public Fire StartFireForCurse(Cell cell)
	{
		if (cell != null && !(cell.busyObj is Fire))
		{
			if (cell.busyObj != null && cell.busyObj is Job)
			{
				Job job = cell.busyObj as Job;
				if (job.Employee != null)
				{
					Player.inst.DestroyPerson(job.Employee, leaveBehindBody: true);
				}
				if (job is ClearCutterJob)
				{
					JobSystem.inst.RemoveJob(job);
					Debug.Log("RemovedJob");
				}
				cell.busyObj = null;
			}
			Fire fire = FirePrefab.Create(cell.Position, FirePrefab.transform.rotation);
			fire.Spreadable = false;
			fire.CantBeExtinguished();
			fire.FireColor = Fire.FireColorVariant.GreenFire;
			fire.SmokeColor = Fire.FireColorVariant.GreenSmoke;
			return fire;
		}
		return null;
	}

	public Fire StartFireAt(Cell cell, int instID = -1, float _forestChance = -1f, float _meadowChance = -1f, float _castleChance = -1f, float _buildingChance = -1f)
	{
		if (cell == null)
		{
			return null;
		}
		if (cell.FindHighestNotFireImmune() == null)
		{
			return null;
		}
		if (cell.HasAnyWater() && !cell.StructureCompareUniqueNameAll(World.woodBridgeHash))
		{
			return null;
		}
		if (cell.Type == TerrainType.Obstruction)
		{
			return null;
		}
		if (!(cell.busyObj is Fire))
		{
			if (cell.busyObj != null && cell.busyObj is Job)
			{
				Job job = cell.busyObj as Job;
				if (job.Employee != null && World.inst.GetVillagerCountForLandmass(cell.landMassIdx) > 5)
				{
					Player.inst.DestroyPerson(job.Employee, leaveBehindBody: true);
				}
				if (job is ClearCutterJob)
				{
					JobSystem.inst.RemoveJob(job);
					Debug.Log("RemovedJob");
				}
				cell.busyObj = null;
			}
			if (!cell.Busy)
			{
				Fire fire = FirePrefab.Create(cell.Position, FirePrefab.transform.rotation);
				fire.overrideForestChance = _forestChance;
				fire.overrideBuildingChance = _buildingChance;
				fire.overrideMeadowChance = _meadowChance;
				fire.overrideCastleChance = _castleChance;
				if (instID == -1)
				{
					instID = SRand.Range(0, int.MaxValue);
				}
				fire.instID = instID;
				if (TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_firehouse") && !Player.inst.DoesAnyBuildingHaveCategoryOnPlayerLandmass(World.firehouseCategoryName, mustBeBuilt: false))
				{
					NotificationUI.TryNotify(message: new NotificationUI.NotificationMessage
					{
						single = ScriptLocalization.notificationui_fire_firestation_warning
					}, groupID: NotificationUI.FireGroup, instID: -1, id: "firestationwarning", status: NotificationStatus.Warning, interval: 240f);
				}
				return fire;
			}
		}
		return null;
	}

	public void ClearFires()
	{
		UnityEngine.Object.Destroy(fireContainer);
		fireContainer = new GameObject
		{
			name = "Fire Container"
		};
	}
}
