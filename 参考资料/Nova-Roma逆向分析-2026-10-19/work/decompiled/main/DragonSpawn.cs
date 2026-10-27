using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets;
using UnityEngine;

public class DragonSpawn : MonoBehaviour, ICamTrackable
{
	[Serializable]
	public class DragonSpawnSaveData : SaveClass<DragonSpawn, DragonSpawnSaveData>
	{
		public int yearsUntilNextAttack;

		public int totalDragonAttacks;

		public DragonController.DragonControllerSaveData[] dragonSaves;

		[OptionalField(VersionAdded = 2)]
		public int dragonsSpawnedForAttack;

		[OptionalField(VersionAdded = 2)]
		public int dragonsKilledForAttack;

		[OptionalField(VersionAdded = 2)]
		public int escalation;

		[OptionalField(VersionAdded = 2)]
		public int totalYearsUntilNextAttack;

		[OptionalField(VersionAdded = 2)]
		public bool consumeDeferredEscalation;

		public override DragonSpawnSaveData Pack(DragonSpawn d)
		{
			yearsUntilNextAttack = d.yearsUntilNextAttack;
			totalDragonAttacks = d.totalDragonAttacks;
			totalYearsUntilNextAttack = d.totalYearsUntilNextAttack;
			consumeDeferredEscalation = d.consumeDeferredEscalation;
			escalation = d.escalation;
			dragonsSpawnedForAttack = d.dragonsSpawnedForAttack;
			dragonsKilledForAttack = d.dragonsKilledForAttack;
			dragonSaves = new DragonController.DragonControllerSaveData[d.currentDragons.Count];
			for (int i = 0; i < d.currentDragons.Count; i++)
			{
				dragonSaves[i] = new DragonController.DragonControllerSaveData().Pack(d.currentDragons.data[i].dragonController);
			}
			return this;
		}

		public override DragonSpawn Unpack(DragonSpawn d)
		{
			d.consumeDeferredEscalation = consumeDeferredEscalation;
			d.yearsUntilNextAttack = yearsUntilNextAttack;
			d.totalDragonAttacks = totalDragonAttacks;
			d.totalYearsUntilNextAttack = totalYearsUntilNextAttack;
			if (d.totalYearsUntilNextAttack == 0)
			{
				d.totalYearsUntilNextAttack = yearsUntilNextAttack + 1;
			}
			d.escalation = escalation;
			d.dragonsSpawnedForAttack = dragonsSpawnedForAttack;
			d.dragonsKilledForAttack = dragonsKilledForAttack;
			d.currentDragons.Clear();
			for (int i = 0; i < dragonSaves.Length; i++)
			{
				DragonController.DragonControllerSaveData dragonControllerSaveData = dragonSaves[i];
				DragonController component;
				switch (dragonControllerSaveData.type)
				{
				case DragonController.DragonType.Dragon:
					component = UnityEngine.Object.Instantiate(d.dragonLevel1Prefab).GetComponent<DragonController>();
					break;
				case DragonController.DragonType.BigDragon:
					component = UnityEngine.Object.Instantiate(d.dragonLevel2Prefab).GetComponent<DragonController>();
					break;
				default:
					Debug.LogError("Default case hit for dragon type");
					component = UnityEngine.Object.Instantiate(d.dragonLevel1Prefab).GetComponent<DragonController>();
					break;
				}
				dragonControllerSaveData.Unpack(component);
				d.currentDragons.Add(component.dragon);
			}
			return d;
		}
	}

	public FreeResource dragonMeat;

	public int viewIdx;

	[NonSerialized]
	public Dragon lastTracked;

	private int startSpawningPopulationThreshold = 65;

	private int MinAttackYearSpan = 9;

	private int MaxAttackYearSpan = 11;

	public GameObject dragonLevel1Prefab;

	public GameObject dragonLevel2Prefab;

	public ArrayExt<Dragon> currentDragons = new ArrayExt<Dragon>(4);

	public static DragonSpawn inst;

	public int yearsUntilNextAttack;

	public int totalYearsUntilNextAttack;

	public int totalDragonAttacks;

	private int escalation;

	private int dragonsSpawnedForAttack;

	private int dragonsKilledForAttack;

	private bool consumeDeferredEscalation;

	private int peasantsKilled;

	private float peasantKilledTimer;

	public void LookAtNearestDragon()
	{
		lastTracked = null;
		Vector3 trackingPos = Cam.inst.TrackingPos;
		float num = float.MaxValue;
		for (int i = 0; i < currentDragons.Count; i++)
		{
			Dragon dragon = currentDragons.data[i];
			float num2 = Mathff.DistSqrdXZ(dragon.transform.position, trackingPos);
			if (num2 < num)
			{
				num = num2;
				lastTracked = dragon;
			}
		}
	}

	public void LookAtNextDragon(int dir)
	{
		for (int i = 0; i < currentDragons.Count; i++)
		{
			if (currentDragons.data[i] == lastTracked)
			{
				int num = i + dir;
				if (num >= currentDragons.Count)
				{
					num = 0;
				}
				if (num < 0)
				{
					num = currentDragons.Count - 1;
				}
				if (num >= 0 && num < currentDragons.Count)
				{
					lastTracked = currentDragons.data[num];
					return;
				}
			}
		}
		lastTracked = null;
	}

	Vector3 ICamTrackable.GetDesiredTrackingPos()
	{
		if (lastTracked != null)
		{
			return lastTracked.transform.position;
		}
		int num = 0;
		if (num < currentDragons.Count)
		{
			return (lastTracked = currentDragons.data[num]).transform.position;
		}
		return Player.inst.keep.transform.position;
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		Broadcast.SeasonEvent.Listen(OnSeasonChange);
	}

	public bool AllowSpawning()
	{
		if (Player.inst.Workers.Count > startSpawningPopulationThreshold)
		{
			return Creative.inst.IsCreativeOptionOn(6);
		}
		return false;
	}

	public void ResetTimer()
	{
		yearsUntilNextAttack = totalYearsUntilNextAttack;
	}

	private void OnSeasonChange(object sender, SeasonEventData e)
	{
		if (Player.inst.difficulty == Player.Difficulty.Peaceful || !Creative.inst.IsCreativeOptionOn(6) || currentDragons.Count > 0)
		{
			return;
		}
		dragonsSpawnedForAttack = 0;
		dragonsKilledForAttack = 0;
		if (Player.inst.Workers.Count >= startSpawningPopulationThreshold && totalDragonAttacks == 0)
		{
			SpawnBabyDragonToVisit(DragonController.NewEntryExitPoint());
			totalDragonAttacks++;
		}
		else
		{
			if (e.SeasonDefinition.id != 0 || Player.inst.Workers.Count <= startSpawningPopulationThreshold)
			{
				return;
			}
			if (yearsUntilNextAttack <= 0)
			{
				totalDragonAttacks++;
				Vector3 vector = DragonController.NewEntryExitPoint();
				int num = 1 + escalation;
				if (Player.inst.difficulty != Player.Difficulty.Survival)
				{
					num = Mathff.Clamp(num, 1, 20);
				}
				int num2 = 75;
				while (num > 0)
				{
					if (num >= 3 && SRand.Range(0, 100) < num2)
					{
						SpawnMamaDragon(vector + new Vector3(SRand.Range(-4, 4), 0f, SRand.Range(-4, 4)));
						num -= 3;
						num2 /= 2;
					}
					SpawnBabyDragon(vector + new Vector3(SRand.Range(-4, 4), 0f, SRand.Range(-4, 4)));
					num--;
				}
			}
			else
			{
				yearsUntilNextAttack--;
			}
		}
	}

	public void Reset()
	{
		yearsUntilNextAttack = 0;
		totalYearsUntilNextAttack = 1;
		totalDragonAttacks = 0;
		dragonsKilledForAttack = 0;
		escalation = 0;
		for (int i = 0; i < currentDragons.Count; i++)
		{
			UnityEngine.Object.Destroy(currentDragons.data[i].gameObject);
		}
		currentDragons.Clear();
	}

	private void Update()
	{
		peasantKilledTimer -= Time.deltaTime;
		if (peasantKilledTimer < 0f && peasantsKilled > 0)
		{
			peasantsKilled = 0;
		}
		for (int i = 0; i < currentDragons.Count; i++)
		{
			Dragon dragon = currentDragons.data[i];
			if (!dragon.dragonController.IsCompleted())
			{
				continue;
			}
			if (dragon.HP() <= 0f)
			{
				dragonsKilledForAttack++;
			}
			if (lastTracked == dragon)
			{
				lastTracked = null;
			}
			UnityEngine.Object.Destroy(dragon.gameObject);
			currentDragons.RemoveAt(i);
			i--;
			if (currentDragons.Count != 0)
			{
				continue;
			}
			int min = Mathff.Clamp(MinAttackYearSpan - totalDragonAttacks / 2, 7, MaxAttackYearSpan);
			int max = Mathff.Clamp(MaxAttackYearSpan - totalDragonAttacks / 2, 7, MaxAttackYearSpan);
			yearsUntilNextAttack = SRand.Range(min, max);
			if (Player.inst.difficulty == Player.Difficulty.Easy)
			{
				yearsUntilNextAttack += yearsUntilNextAttack / 2;
			}
			totalYearsUntilNextAttack = yearsUntilNextAttack;
			if (dragonsSpawnedForAttack == dragonsKilledForAttack)
			{
				if (consumeDeferredEscalation)
				{
					escalation += ((Player.inst.difficulty < Player.Difficulty.Hard) ? 1 : 2);
					consumeDeferredEscalation = false;
				}
				else
				{
					consumeDeferredEscalation = true;
				}
			}
		}
	}

	public void SpawnMamaDragon()
	{
		SpawnMamaDragon(DragonController.NewEntryExitPoint());
	}

	public void SpawnMamaDragon(Vector3 start)
	{
		bool flag = Player.inst.difficulty >= Player.Difficulty.Hard;
		List<DragonController.DragonState> list = new List<DragonController.DragonState>
		{
			DragonController.DragonState.HarmlessMoveAction,
			DragonController.DragonState.BurnLineAction,
			DragonController.DragonState.BurnMoveAction
		};
		if (Player.inst.Workers.Count > startSpawningPopulationThreshold * 4)
		{
			list.Add(DragonController.DragonState.BurnLineAction);
		}
		if (flag)
		{
			if (Player.inst.Workers.Count > startSpawningPopulationThreshold * 5)
			{
				list.Add(DragonController.DragonState.BurnMoveAction);
			}
			if (Player.inst.Workers.Count > startSpawningPopulationThreshold * 6)
			{
				list.Add(DragonController.DragonState.BurnLineAction);
			}
		}
		if (Player.inst.Workers.Count > startSpawningPopulationThreshold * 7)
		{
			list.Add(DragonController.DragonState.BurnLineAction);
		}
		SetupExamineStatue(list);
		DragonController component = UnityEngine.Object.Instantiate(dragonLevel2Prefab).GetComponent<DragonController>();
		Spawn(component, start, list, 600, 900, 3f, 4f, 1f);
	}

	public void SpawnBabyDragon()
	{
		SpawnBabyDragon(DragonController.NewEntryExitPoint());
	}

	public void SpawnBabyDragon(Vector3 start)
	{
		dragonsSpawnedForAttack++;
		bool flag = Player.inst.difficulty >= Player.Difficulty.Hard;
		List<DragonController.DragonState> list = new List<DragonController.DragonState>();
		list.Add(DragonController.DragonState.BurnMoveAction);
		if (Player.inst.Workers.Count > startSpawningPopulationThreshold * 2)
		{
			if (flag && totalDragonAttacks > 1)
			{
				list.Add(DragonController.DragonState.BurnMoveAction);
			}
			else if (totalDragonAttacks > 2)
			{
				list.Add(DragonController.DragonState.BurnMoveAction);
			}
		}
		if (Player.inst.Workers.Count > startSpawningPopulationThreshold * 3)
		{
			if (flag && totalDragonAttacks > 3)
			{
				list.Add(DragonController.DragonState.BurnMoveAction);
				list.Add(DragonController.DragonState.BurnMoveAction);
			}
			else if (totalDragonAttacks > 5)
			{
				list.Add(DragonController.DragonState.BurnMoveAction);
			}
		}
		if (Player.inst.Workers.Count > startSpawningPopulationThreshold * 4 && flag && totalDragonAttacks > 5)
		{
			list.Add(DragonController.DragonState.BurnMoveAction);
		}
		SetupExamineStatue(list);
		DragonController component = UnityEngine.Object.Instantiate(dragonLevel1Prefab).GetComponent<DragonController>();
		Spawn(component, start, list, 600, 480, 2f, 3f, 1f);
	}

	private void SetupExamineStatue(List<DragonController.DragonState> actions)
	{
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList("statue_sam".GetHashCode());
		if (buildingList.Count <= 0)
		{
			return;
		}
		int num = SRand.Range(1, 1 + buildingList.Count / 2);
		for (int i = 0; i < num; i++)
		{
			int num2 = SRand.Range(0, 100);
			if (i == 0 || num2 < 30)
			{
				int index = SRand.Range(0, actions.Count);
				actions[index] = DragonController.DragonState.CircleStatue;
			}
		}
	}

	public void SpawnBabyDragonToVisit(Vector3 start)
	{
		dragonsSpawnedForAttack++;
		List<DragonController.DragonState> list = new List<DragonController.DragonState>();
		list.Add(DragonController.DragonState.HarmlessMoveAction);
		list.Add(DragonController.DragonState.HarmlessMoveAction);
		list.Add(DragonController.DragonState.HarmlessMoveAction);
		DragonController component = UnityEngine.Object.Instantiate(dragonLevel1Prefab).GetComponent<DragonController>();
		Spawn(component, start, list, 600, 480, 2f, 3f, 1f);
	}

	public void Spawn(DragonController dragon, Vector3 start, List<DragonController.DragonState> actions, int maxStay, int hp, float normalFly, float retreatFly, float strengthScaler)
	{
		dragon.gameObject.SetActive(value: true);
		dragon.Init(start, hp, actions, maxStay, normalFly, retreatFly, strengthScaler);
		currentDragons.Add(dragon.dragon);
	}

	public Dragon ClosestDragon(Vector3 pos)
	{
		Dragon result = null;
		float num = float.PositiveInfinity;
		for (int i = 0; i < currentDragons.Count; i++)
		{
			Dragon dragon = currentDragons.data[i];
			if (dragon.dragonController.GetState() != DragonController.DragonState.Dead)
			{
				float num2 = Vector3.Distance(dragon.transform.position, pos);
				if (num2 < num)
				{
					num = num2;
					result = dragon;
				}
			}
		}
		return result;
	}

	public bool IsAttackInProgress()
	{
		float num = 20f;
		for (int i = 0; i < currentDragons.Count; i++)
		{
			Vector3 position = currentDragons.data[i].transform.position;
			if (position.x >= 0f - num && position.x <= (float)World.inst.GridWidth + num && position.z >= 0f - num && position.z <= (float)World.inst.GridHeight + num)
			{
				return true;
			}
		}
		return false;
	}

	public void NotePeasantKilled(Vector3 p)
	{
		if (World.GetLandmassOwner(World.inst.GetCellDataClamped(p).landMassIdx) == Player.inst.PlayerLandmassOwner)
		{
			peasantsKilled++;
			peasantKilledTimer = 15f;
		}
	}
}
