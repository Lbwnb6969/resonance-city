using System;
using System.Collections.Generic;
using Assets.Code;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using UnityEngine;

public class Fire : PooledObject, IEmployer
{
	public enum FireColorVariant
	{
		YellowFire,
		YellowSmoke,
		GreenFire,
		GreenSmoke
	}

	[Serializable]
	public class FireSaveData : SaveClass<Fire, FireSaveData>
	{
		public float spreadTime;

		public bool dying;

		public SerializableVector3 pos;

		public float burnTime;

		public float life;

		public bool spreadable = true;

		public bool extinguishable = true;

		public FireColorVariant fireColor;

		public FireColorVariant smokeColor = FireColorVariant.YellowSmoke;

		public SerializableVector3[] firePositions;

		public override FireSaveData Pack(Fire f)
		{
			spreadTime = f.spreadTime;
			dying = f.dying;
			pos = f.cell.Position;
			burnTime = f.burnTime;
			life = f.life;
			spreadable = f.Spreadable;
			extinguishable = f.Extinguishable;
			fireColor = f.FireColor;
			smokeColor = f.SmokeColor;
			return this;
		}

		public override Fire Unpack(Fire f)
		{
			f.spreadTime = spreadTime;
			f.dying = dying;
			f.burnTime = burnTime;
			f.life = life;
			f.Spreadable = spreadable;
			f.Extinguishable = extinguishable;
			if (!f.Extinguishable)
			{
				f.RemoveJobs();
			}
			f.FireColor = fireColor;
			f.SmokeColor = smokeColor;
			return f;
		}
	}

	public Building RubblePrefab;

	private MiniMapUIPing mapFirePing;

	private float startingEmissionRate = float.NaN;

	public float life = 1f;

	private int maxFighters = 3;

	[NonSerialized]
	public List<Job> FireFightingJobs = new List<Job>();

	private float burnTime;

	public int fightersPerTile = 4;

	public MinMax BurnoutTimeRange = new MinMax(8f, 15f);

	private float burnoutTime = 15f;

	public float burnMaxVolume = 0.35f;

	public int instID = -1;

	private EventInstance burnSound;

	private List<Vector3> fireCells = new List<Vector3>();

	private ArrayExt<Cell> fireEngineCells = new ArrayExt<Cell>(12);

	private float spreadTime;

	public EventReference FireStartEvent;

	public EventReference FireBurnLoopEvent;

	private bool busyRemoved;

	private bool dying;

	private ParticleSystem fireParticles;

	private ParticleSystem smokeParticles;

	private FireColorVariant mFireColor;

	private FireColorVariant mSmokeColor;

	[SerializeField]
	public Gradient[] fireGradients;

	private Cell cell;

	private EventHandler<OnTechnologyTreeUnlock> unlockEventHandler;

	public float forestChance = 0.5f;

	public float meadowChance = 0.2f;

	public float castleChance;

	[NonSerialized]
	public float overrideForestChance;

	[NonSerialized]
	public float overrideCastleChance;

	[NonSerialized]
	public float overrideMeadowChance;

	[NonSerialized]
	public float overrideBuildingChance;

	public OneOffEffect putOutEffect;

	[NonSerialized]
	public bool suppress;

	public bool Spreadable = true;

	private bool Extinguishable = true;

	private Cell[] scratchNeighbors = new Cell[4];

	private float dyingTime;

	private float putOutTimeAtMaxFight
	{
		get
		{
			if (DifficultyManager.inst.currOption.fires == 2)
			{
				return 4.5f;
			}
			if (DifficultyManager.inst.currOption.fires == 3)
			{
				return 5.5f;
			}
			if (DifficultyManager.inst.currOption.fires == 4)
			{
				return 6f;
			}
			return 4f;
		}
	}

	public bool Dying => dying;

	public FireColorVariant FireColor
	{
		get
		{
			return mFireColor;
		}
		set
		{
			if (value != mFireColor)
			{
				mFireColor = value;
				AssignColorOverTime(fireParticles, fireGradients[(int)mFireColor]);
			}
		}
	}

	public FireColorVariant SmokeColor
	{
		get
		{
			return mSmokeColor;
		}
		set
		{
			if (value != mSmokeColor)
			{
				mSmokeColor = value;
				AssignColorOverTime(smokeParticles, fireGradients[(int)mSmokeColor]);
			}
		}
	}

	public Cell Cell => cell;

	public bool IsOpen()
	{
		return true;
	}

	public Vector3 GetPosition()
	{
		return transform.position;
	}

	public Vector3 GetCenter()
	{
		return transform.GetChild(0).position;
	}

	public TransformData GetPositionForPerson(Villager p)
	{
		return new TransformData
		{
			position = transform.position
		};
	}

	public void OnAssigned(Villager p)
	{
		p.SetWorkPosition(GetPositionForPerson(p));
	}

	public void OnUnAssigned(Villager p)
	{
	}

	public void OnJobRemoved(Job j)
	{
	}

	public int LandMass()
	{
		return cell.landMassIdx;
	}

	public int GetJobCategory()
	{
		return 10;
	}

	public bool DuringWorkHours(float buffer)
	{
		return true;
	}

	public float GetStartHour()
	{
		return -1f;
	}

	public float GetEndHour()
	{
		return -1f;
	}

	string IEmployer.GetUsedSkill()
	{
		return "";
	}

	public Fire Create(Vector3 p, Quaternion r)
	{
		return Alloc(p, r) as Fire;
	}

	public void PostModifyBurnout(float mul)
	{
		spreadTime *= mul;
		burnoutTime *= mul;
	}

	private void AssignColorOverTime(ParticleSystem particleSystem, Gradient gradient)
	{
		if ((bool)particleSystem && gradient != null)
		{
			ParticleSystem.ColorOverLifetimeModule colorOverLifetime = particleSystem.colorOverLifetime;
			colorOverLifetime.color = gradient;
		}
	}

	public bool FullOfFighters()
	{
		return ActiveFighters() == maxFighters;
	}

	public static bool IsFireAlive(Fire f)
	{
		if (!(f == null) && !f.Equals(null) && f.gameObject.activeSelf)
		{
			return !f.Dying;
		}
		return false;
	}

	public int ActiveFighters()
	{
		int num = 0;
		for (int i = 0; i < FireFightingJobs.Count; i++)
		{
			if (FireFightingJobs[i].Employee != null)
			{
				num++;
			}
		}
		return num;
	}

	public override void Init()
	{
		cell = World.inst.GetCellData(transform.position);
		Extinguishable = true;
		busyRemoved = false;
		dyingTime = 0f;
		Spreadable = true;
		if (!fireParticles)
		{
			fireParticles = transform.Find("FireParticles").gameObject.GetComponent<ParticleSystem>();
		}
		FireColor = FireColorVariant.YellowFire;
		if (!smokeParticles)
		{
			smokeParticles = transform.GetChild(0).GetChild(0).GetComponent<ParticleSystem>();
		}
		SmokeColor = FireColorVariant.YellowSmoke;
		if (float.IsNaN(startingEmissionRate))
		{
			startingEmissionRate = fireParticles.emission.rateOverTime.constant;
		}
		burnoutTime = BurnoutTimeRange.Rand();
		if ((bool)cell.TopStructure)
		{
			burnoutTime += cell.TopStructure.size.xz().magnitude;
		}
		burnTime = 0f;
		life = 1f;
		dying = false;
		transform.parent = FireManager.inst.fireContainer.transform;
		fireParticles.Play(withChildren: true);
		transform.localScale = new Vector3(1f, 1f, 1f);
		int tileSum = 0;
		fireCells = new List<Vector3>();
		int minX = 0;
		int maxX = 0;
		int minZ = 0;
		int maxZ = 0;
		if (cell.OccupyingStructure.Count > 0)
		{
			Building topStructure = cell.TopStructure;
			Vector3 bounds = topStructure.GetBounds();
			bounds.y = 0f;
			topStructure.GetBoundingFootprint(out minX, out minZ, out maxX, out maxZ);
			topStructure.ForEachTileInBounds((int x, int z, Cell c) =>
			{
				fireCells.Add(c.Center2D);
				c.AddBusy(this);
				tileSum++;
			});
			Vector3 position = topStructure.Center() - bounds / 2f;
			position.y = cell.TopStructure.transform.position.y + topStructure.size.y * 0.5f;
			transform.position = position;
			transform.localScale = new Vector3(bounds.x, 0f, bounds.z);
			if (topStructure.categoryHash == World.farmHash)
			{
				Field component = topStructure.GetComponent<Field>();
				if (component != null)
				{
					component.ResetTime();
				}
			}
		}
		else
		{
			maxX = cell.x;
			maxZ = cell.z;
			fireCells.Add(cell.Center2D);
			cell.AddBusy(this);
			tileSum = 1;
		}
		maxFighters = fightersPerTile * tileSum;
		spreadTime = burnoutTime / 2.5f;
		RuntimeManager.PlayOneShot("event:/OldSFX/FireStart", transform.position);
		burnSound = SfxSystem.inst.PlayFromBankIfVisible("BuildingFire", transform.position);
		if (FogOfWar.inst.IsVisible(cell.Position))
		{
			mapFirePing = MiniMapUI.inst.SetupFirePing(transform.position);
		}
		if (cell.landMassIdx != -1)
		{
			int num = maxFighters - FireFightingJobs.Count;
			for (int num2 = 0; num2 < num; num2++)
			{
				FireFighterVolunteer fireFighterVolunteer = new FireFighterVolunteer(this);
				JobSystem.inst.AddNewJob(fireFighterVolunteer);
				FireFightingJobs.Add(fireFighterVolunteer);
			}
		}
		LandmassOwner landmassOwner = World.GetLandmassOwner(LandMass());
		if (landmassOwner != null && landmassOwner.teamId == 0 && TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_fireengines"))
		{
			CollectFireEngineCells();
			TryAssignFireEngines();
		}
		if (unlockEventHandler == null)
		{
			unlockEventHandler = Broadcast.TechnologyTreeUnlockEvent.Listen(OnTechnologyTreeUnlock);
		}
	}

	private void OnTechnologyTreeUnlock(object sender, OnTechnologyTreeUnlock data)
	{
		LandmassOwner landmassOwner = World.GetLandmassOwner(LandMass());
		if (!(landmassOwner == null) && (!IsFireAlive(this) || landmassOwner.teamId == 0) && !(data.unlockKey != "unlockkey_fireengines"))
		{
			CollectFireEngineCells();
		}
	}

	private void CollectFireEngineCells()
	{
		int minX = 0;
		int maxX = 0;
		int minZ = 0;
		int maxZ = 0;
		if (cell.OccupyingStructure.Count == 0)
		{
			return;
		}
		cell.TopStructure.GetBoundingFootprint(out minX, out minZ, out maxX, out maxZ);
		fireEngineCells.ClearFast();
		for (int i = minX - 1; i <= maxX + 1; i++)
		{
			for (int j = minZ - 1; j <= maxZ + 1; j++)
			{
				Cell cellData = World.inst.GetCellData(i, j);
				if (cellData != null && (i == minX - 1 || i == maxX + 1 || j == minZ - 1 || j == maxZ + 1) && !FireEngine.IsBlockingCell(cellData))
				{
					fireEngineCells.Add(cellData);
				}
			}
		}
	}

	private void TryAssignFireEngines()
	{
		if (!IsFireAlive(this))
		{
			return;
		}
		int num = fireEngineCells.Count - 1;
		while (num >= 0)
		{
			Cell cell = fireEngineCells.data[num];
			FireEngine fireEngine = null;
			float num2 = float.MaxValue;
			for (int i = 0; i < FireEngineSystem.inst.fireEngines.Count; i++)
			{
				FireEngine fireEngine2 = FireEngineSystem.inst.fireEngines.data[i];
				if (!fireEngine2.IsBusy() && cell.landMassIdx == fireEngine2.owner.b.LandMass())
				{
					float num3 = Mathff.DistSqrdXZ(fireEngine2.transform.position, cell.Center2D);
					if (num3 < num2)
					{
						num2 = num3;
						fireEngine = fireEngine2;
					}
				}
			}
			if (!(fireEngine == null))
			{
				fireEngine.SetFireTarget(this, cell.Center2D);
				fireEngineCells.RemoveAt(num);
				num--;
				continue;
			}
			break;
		}
	}

	public void RemoveJobs()
	{
		for (int i = 0; i < FireFightingJobs.Count; i++)
		{
			Job job = FireFightingJobs[i];
			if (job.HasEmployee())
			{
				job.Employee.QuitJob();
			}
			JobSystem.inst.RemoveJob(job);
		}
		FireFightingJobs.Clear();
	}

	public void Burnout(bool burndown)
	{
		if (!dying)
		{
			RemoveJobs();
			dying = true;
			fireParticles.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmitting);
			if (burndown && World.inst.treeSystem.ItemAmount(cell) > 0)
			{
				World.inst.treeSystem.DeleteTreesAt(cell);
				cell.Type = TerrainType.None;
			}
			RemoveBusy();
		}
	}

	public void CantBeExtinguished()
	{
		Extinguishable = false;
		RemoveJobs();
	}

	public void ContributeToExtinguish()
	{
		life -= 1f / (float)maxFighters * Time.deltaTime / putOutTimeAtMaxFight;
	}

	public override void Tick(float dt)
	{
		base.Tick(dt);
		CheckParticleVisibility();
		if (!suppress)
		{
			burnTime += Time.deltaTime;
		}
		int num = 0;
		if (SeasonManager.inst.CurrWeather == SeasonManager.WeatherType.HeavyRain)
		{
			num = maxFighters;
		}
		else if (SeasonManager.inst.CurrWeather == SeasonManager.WeatherType.Rain)
		{
			num = maxFighters / 2;
		}
		else if (SeasonManager.inst.CurrentSeason.id == 2)
		{
			num = maxFighters / 4;
		}
		for (int i = 0; i < num; i++)
		{
			ContributeToExtinguish();
		}
		Building topStructure = cell.TopStructure;
		if (topStructure != null && topStructure.uniqueNameHash == World.rubbleHash)
		{
			Burnout(burndown: false);
		}
		if (!dying)
		{
			LandmassOwner landmassOwner = World.GetLandmassOwner(LandMass());
			if (landmassOwner != null && landmassOwner.teamId == 0 && TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_fireengines"))
			{
				TryAssignFireEngines();
			}
			if (topStructure != null && topStructure.fireChance > 0f)
			{
				float num2 = 0.025f;
				if (DifficultyManager.inst.currOption.fires == 2)
				{
					num2 = 0.035f;
				}
				if (DifficultyManager.inst.currOption.fires == 3)
				{
					num2 = 0.045f;
				}
				if (DifficultyManager.inst.currOption.fires == 4)
				{
					num2 = 0.055f;
				}
				topStructure.TakeDamage(dt * num2, transform.position, "");
				if (topStructure.Life <= 0f)
				{
					bool flag = FirehouseManager.inst.GetProtection(cell.x, cell.z) > 0f;
					string friendlyName = topStructure.FriendlyName;
					Vector3 vector = topStructure.Center();
					NotificationUI.NotificationMessage message = new NotificationUI.NotificationMessage
					{
						single = string.Format(ScriptLocalization.FireHasClaimed, friendlyName),
						multiple = LocalizationManager.GetTranslation("FireHasClaimedMultiple"),
						individual = friendlyName,
						tail = (flag ? string.Empty : ("<b>" + ScriptLocalization.notificationui_fire_firestation_warning + "</b>"))
					};
					NotificationUI.TryNotify(NotificationUI.FireGroup, instID, "firewreck", message, NotificationStatus.Warning, 0f, vector, title: false, cell.landMassIdx);
					Burnout(burndown: true);
				}
			}
			if (burnTime > spreadTime)
			{
				spreadTime = float.PositiveInfinity;
				if (!suppress && Spreadable)
				{
					World.inst.GetNeighborCells(cell, ref scratchNeighbors);
					for (int j = 0; j < scratchNeighbors.Length; j++)
					{
						if (scratchNeighbors[j] == null)
						{
							continue;
						}
						float num3 = 0f;
						if (World.inst.treeSystem.ItemAmount(scratchNeighbors[j]) > 0)
						{
							num3 = ((overrideForestChance > 0f) ? overrideForestChance : forestChance);
						}
						else if (scratchNeighbors[j].Type == TerrainType.None)
						{
							num3 = ((overrideMeadowChance > 0f) ? overrideMeadowChance : meadowChance);
						}
						if (scratchNeighbors[j].OccupyingStructure.Count > 0)
						{
							Building topStructure2 = scratchNeighbors[j].TopStructure;
							if (topStructure2.UniqueName == "castleblock")
							{
								num3 = ((overrideCastleChance > 0f) ? overrideCastleChance : castleChance);
							}
							else
							{
								num3 = ((overrideBuildingChance > 0f) ? overrideBuildingChance : topStructure2.fireChance);
							}
							if (topStructure2.IsBeingDamaged())
							{
								num3 = 0f;
							}
							YieldProducerSeason component = topStructure2.GetComponent<YieldProducerSeason>();
							if (topStructure2.uniqueNameHash == World.farmHash && component.actualYieldPercentage <= 0.2f)
							{
								num3 = 0f;
							}
							if (SeasonManager.inst.CurrentSeason.id == 2)
							{
								num3 *= 0.75f;
							}
						}
						float protection = FirehouseManager.inst.GetProtection(scratchNeighbors[j].x, scratchNeighbors[j].z);
						num3 *= 1f - protection;
						if (protection <= 0f)
						{
							num3 *= 1.5f;
						}
						if (DifficultyManager.inst.currOption.fires == 1)
						{
							num3 *= 0.75f;
						}
						if (DifficultyManager.inst.currOption.fires == 2)
						{
							num3 *= 1f;
						}
						if (DifficultyManager.inst.currOption.fires == 3)
						{
							num3 *= 1.2f;
						}
						if (DifficultyManager.inst.currOption.fires == 4)
						{
							num3 *= 1.5f;
						}
						Governor governor = ((cell.landMassIdx != -1) ? Player.inst.governors[cell.landMassIdx] : null);
						if (governor != null)
						{
							Governor.TraitInstance trait = governor.GetTrait(Traits.FireRisk);
							if (trait != null)
							{
								num3 *= 1f + (trait.negative ? trait.magnitude : (0f - trait.magnitude));
							}
						}
						if (SRand.value < num3)
						{
							FireManager.inst.StartFireAt(scratchNeighbors[j], instID);
						}
					}
				}
			}
			if (burnTime > burnoutTime)
			{
				if (topStructure != null && topStructure.UniqueName == "keep")
				{
					Burnout(burndown: false);
				}
				else
				{
					Burnout(burndown: true);
				}
			}
			if (life <= 0f)
			{
				Burnout(burndown: false);
				putOutEffect.CreateAndPlay(transform.position);
			}
		}
		else
		{
			dyingTime += Time.deltaTime;
			if (dyingTime > 7f)
			{
				Release();
			}
		}
		suppress = false;
	}

	public override void Shutdown()
	{
		fireParticles.Stop(withChildren: false);
		burnSound.stop(STOP_MODE.ALLOWFADEOUT);
		if (mapFirePing != null)
		{
			MiniMapUI.inst.RemovePing(mapFirePing);
		}
		RemoveJobs();
		RemoveBusy();
		Broadcast.TechnologyTreeUnlockEvent.Unlisten(unlockEventHandler);
		unlockEventHandler = null;
	}

	public void CheckParticleVisibility()
	{
		if (!FogOfWar.inst.IsVisible(transform.position))
		{
			if (fireParticles.isPlaying)
			{
				fireParticles.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmittingAndClear);
				smokeParticles.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmittingAndClear);
			}
		}
		else if (fireParticles.isStopped && !dying)
		{
			fireParticles.Play();
			smokeParticles.Play();
		}
	}

	public void RemoveBusy()
	{
		if (!busyRemoved)
		{
			busyRemoved = true;
			for (int i = 0; i < fireCells.Count; i++)
			{
				World.inst.GetCellData(fireCells[i]).RemoveBusy(this);
			}
		}
	}

	private void OnDrawGizmos()
	{
		if (!(Camera.current != Camera.main))
		{
			Gizmos.color = Color.red;
			Gizmos.DrawWireSphere(cell.Center2D, life * 0.5f);
		}
	}
}
