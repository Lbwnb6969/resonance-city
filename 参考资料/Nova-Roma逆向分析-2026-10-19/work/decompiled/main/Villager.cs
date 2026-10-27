using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets;
using Assets.Interface;
using Drawing;
using I2.Loc;
using UnityEngine;

public class Villager : InstanceSystem.Owner, IResourceCarrier, ICamTrackable, IProjectileHitable
{
	[Serializable]
	public class VillagerSaveData : SaveClass<Villager, VillagerSaveData>
	{
		public Guid guid;

		public string name = "";

		public float age;

		public SerializableVector3 pos;

		public SerializableVector3 workPos;

		public bool sick;

		public float sickTime;

		public List<Skill> skills;

		public int carryCount;

		public int carryType;

		public float life;

		public float timeAlive;

		public int sicknessStrength;

		public bool sickFromDeadBody;

		public float health;

		public Skill[] skillsArray;

		public int tiredness;

		public float commuteTime;

		[OptionalField(VersionAdded = 2)]
		public PersonProfile profile;

		[OptionalField(VersionAdded = 2)]
		public bool lady;

		[OptionalField(VersionAdded = 3)]
		public string CustomName;

		[OnDeserialized]
		public void OnDeserializedMethod(StreamingContext context)
		{
			if (profile == null)
			{
				lady = SRand.srand.Next(0, 100) <= 50;
			}
		}

		public override VillagerSaveData Pack(Villager v)
		{
			guid = v.guid;
			pos = v.Pos;
			workPos = v.workPosition.position;
			sick = v.sick;
			sickTime = v.sickTime;
			sicknessStrength = v.sicknessStrength;
			sickFromDeadBody = v.sickFromDeadBody;
			skillsArray = new Skill[v.skills.Count];
			int i = 0;
			for (int count = v.skills.Count; i < count; i++)
			{
				skillsArray[i] = v.skills.data[i];
			}
			CustomName = v.CustomName;
			carryCount = v.HeldResources.Count;
			if (carryCount > 0)
			{
				carryType = v.HeldResources[0].resourceID;
			}
			life = v.life;
			timeAlive = v.timeAlive;
			health = v.health;
			tiredness = v.tiredness;
			profile = v.profile;
			lady = v.useLadyMesh;
			commuteTime = v.commuteTime;
			return this;
		}

		public override Villager Unpack(Villager v)
		{
			v.guid = guid;
			v.TeleportTo(pos);
			v.workPosition = new TransformData
			{
				position = workPos
			};
			v.sick = sick;
			v.needsDoctor = sick;
			v.sickTime = sickTime;
			v.sicknessStrength = sicknessStrength;
			v.sickFromDeadBody = sickFromDeadBody;
			if (skillsArray != null)
			{
				for (int i = 0; i < skillsArray.Length; i++)
				{
					v.skills.Add(skillsArray[i]);
					v.skills.data[i].nameHash = v.skills.data[i].name.GetHashCode();
				}
			}
			else if (skills != null)
			{
				for (int j = 0; j < skills.Count; j++)
				{
					v.skills.Add(skills[j]);
					v.skills.data[j].nameHash = v.skills.data[j].name.GetHashCode();
				}
			}
			v.profile = profile;
			if (v.profile == null || v.profile.version != 1)
			{
				v.profile = PersonProfile.GetRandomProfile(!v.useLadyMesh);
			}
			v.CustomName = CustomName;
			for (int k = 0; k < carryCount; k++)
			{
				v.PickupResource(FreeResourceSystem.inst.AddFreeResource(carryType, v.Pos, v.landMass), playSfx: false);
			}
			v.life = life;
			v.timeAlive = timeAlive;
			v.health = health;
			v.SetTiredness(tiredness);
			v.commuteTime = commuteTime;
			return v;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			System.Random srand = SRand.srand;
			float num = ((SeasonManager.inst != null) ? SeasonManager.inst.TimeInYear() : 0f);
			life = num * (float)srand.Next(2, 60);
			timeAlive = num * (float)srand.Next(15, 30);
			commuteTime = -1f;
		}
	}

	public bool useLadyMesh;

	public PersonProfile profile;

	public string CustomName = string.Empty;

	public bool enabled = true;

	public Guid guid;

	private IResidence home;

	[NonSerialized]
	public Job job;

	[NonSerialized]
	public IEmployer previousEmployer;

	[NonSerialized]
	public bool paralyzed;

	[NonSerialized]
	public bool scared;

	[NonSerialized]
	public bool lockMovement;

	[NonSerialized]
	public float timeAlive;

	[NonSerialized]
	public float life;

	private TransformData workPosition;

	private string textThought = "";

	private int idxIntoActiveVillagerList = -1;

	public int idxIntoPool = -1;

	public static int villagerPoolCount = 0;

	public static ArrayExt<Villager> villagerPool = new ArrayExt<Villager>(10000);

	public static ArrayExt<Villager> villagers = new ArrayExt<Villager>(10000);

	public bool consumeOnPickup = true;

	public Color headColor;

	public Color bodyColor;

	public Color hairColor;

	private VillagerSystem.MeshType meshType;

	private Vector3 desiredDirection;

	public int tiredness;

	internal const float defaultSpeed = 1f;

	private float activeSpeed = 1f;

	[NonSerialized]
	public ArrayExt<Vector3> gridPath = new ArrayExt<Vector3>(64);

	[NonSerialized]
	public ArrayExt<TravelNode> travelPath = new ArrayExt<TravelNode>(64);

	[NonSerialized]
	public bool debugDrawPath;

	public ThoughtBubbleSystem.ThoughtBubble thought;

	private const float learnRate = 0.001f;

	private static int fixedIdx = 0;

	private int fixedUpdateFrame;

	public Transform body;

	public Transform head;

	public Transform legs;

	public ObjectHighlighter highlighter;

	private Transform xform;

	internal bool shutdown;

	[NonSerialized]
	public IResourceStorage houseStorage;

	public int landMass;

	private float textThoughtTime;

	[NonSerialized]
	public int carryBonus = 1;

	[NonSerialized]
	public float speedBonusMultiplier = 1f;

	[NonSerialized]
	public List<FreeResource> HeldResources = new List<FreeResource>();

	private float happyThought;

	public float bounceSpeed = 6f;

	public float bounceMagnitude = 0.03f;

	private static int pathHash = "path".GetHashCode();

	private static int dockHash = "dock".GetHashCode();

	private static int fishinghutHash = "fishinghut".GetHashCode();

	private ArrayExt<Vector3> NodesForRemoval = new ArrayExt<Vector3>(10);

	private int randPosIdx = SRand.Range(0, 1000);

	private static float[] randPosOffset;

	private float roadLaneOffset;

	private const float laneJitterScale = 0.35f;

	private const float cellEdgeMargin = 0.2f;

	private Vector3 heightTestPos;

	private Ray ray = new Ray(Vector3.zero, Vector3.down);

	private Vector3 up = Vector3.up;

	private Vector3 lastDir;

	private float desiredAngle;

	private float lastCurrAngle;

	private Vector3 nonScaredDestination;

	[NonSerialized]
	public float health;

	private float currAngle;

	private float totalTime;

	private static Quaternion scratchQuat;

	public Timer scaredTimer = new Timer(3f);

	public ArrayExt<Skill> skills = new ArrayExt<Skill>(5);

	private static int drawbridgeHash = "drawbridge".GetHashCode();

	public int sicknessStrength;

	public bool sick;

	public bool sickFromDeadBody;

	internal bool needsDoctor;

	public float sickTime;

	public float healTime;

	[NonSerialized]
	public Cell cell;

	[NonSerialized]
	public Cell lastCell;

	public ArrayExt<VillagerSystem.VillagerInstanceSystem> instancesRef;

	private Vector3 fullScale = new Vector3(1f, 1f, 1f);

	private Vector3 pos;

	private Vector3 offset;

	private Quaternion rot;

	private Quaternion? finalRot;

	private GamePath deferredPath = new GamePath();

	private Building buildingToExit;

	private bool ignoreDeferred;

	public FreeTimeRoutine[] freeTimeRoutines = new FreeTimeRoutine[2]
	{
		new LeisureActivity(),
		new SleepAtHome()
	};

	public FreeTimeRoutine currentFreeTimeRoutine;

	public bool freeTime;

	private VillagerSystem.MeshType prevMesh;

	private bool commuting;

	private float startCommuteTime;

	internal float commuteTime = -1f;

	private Building bestHomelessBuilding;

	private Vector3 bestHomelessPosition = Vector3.zero;

	public const int MIN_TIREDNESS_EFFECT = 2;

	public string name
	{
		get
		{
			if (!string.IsNullOrEmpty(CustomName))
			{
				return CustomName;
			}
			return profile.Name;
		}
	}

	public VillagerSystem.MeshType MeshType
	{
		get
		{
			return meshType;
		}
		set
		{
			if (meshType != value)
			{
				instancesRef.data[(int)meshType].ReleaseInstance(this);
				meshType = value;
				instancesRef.data[(int)value].AddInstance(this, pos, rot, fullScale);
				instancesRef.data[(int)value].headColors.data[s][idx] = headColor;
				instancesRef.data[(int)value].bodyColors.data[s][idx] = bodyColor;
				instancesRef.data[(int)value].hairColors.data[s][idx] = hairColor;
			}
		}
	}

	public IResidence Residence
	{
		get
		{
			return home;
		}
		set
		{
			home = value;
			if (home != null)
			{
				houseStorage = (home as MonoBehaviour).GetComponent<IResourceStorage>();
			}
			else
			{
				houseStorage = null;
			}
		}
	}

	public Vector3 Pos
	{
		get
		{
			return pos;
		}
		set
		{
			bool num = (int)pos.x != (int)value.x || (int)pos.z != (int)value.z;
			pos = value;
			Mathff.SetTRS(ref instancesRef.data[(int)meshType].silos.data[s][idx], GetPosWithOffset(), rot, fullScale);
			if (num)
			{
				cell = World.inst.GetCellData(value);
				UpdateCell();
			}
		}
	}

	public Vector3 Offset
	{
		get
		{
			return offset;
		}
		set
		{
			offset = value;
		}
	}

	public Quaternion Rot
	{
		get
		{
			return rot;
		}
		set
		{
			rot = value;
			Mathff.SetTRS(ref instancesRef.data[(int)meshType].silos.data[s][idx], GetPosWithOffset(), value, fullScale);
		}
	}

	public void ApplyColorChanges()
	{
		instancesRef.data[(int)meshType].headColors.data[s][idx] = headColor;
		instancesRef.data[(int)meshType].bodyColors.data[s][idx] = bodyColor;
		instancesRef.data[(int)meshType].hairColors.data[s][idx] = hairColor;
	}

	public void InitMesh(VillagerSystem.MeshType mType)
	{
		meshType = mType;
	}

	public static Villager CreateVillager()
	{
		bool flag = SRand.Range(0, 100) >= 50;
		return VillagerSystem.inst.AddVillager(Vector3.zero, flag);
	}

	public static Villager CreateVillagerWithGender(bool lady)
	{
		return VillagerSystem.inst.AddVillager(Vector3.zero, lady);
	}

	public void Init()
	{
		if (randPosOffset == null)
		{
			randPosOffset = new float[32];
			for (int i = 0; i < randPosOffset.Length; i++)
			{
				randPosOffset[i] = SRand.Range(-0.13f, 0.13f);
			}
		}
		roadLaneOffset = SRand.Range(0.12f, 0.3f);
		consumeOnPickup = true;
		shutdown = false;
		fixedUpdateFrame = fixedIdx++;
		fixedUpdateFrame %= 20;
		health = 0.5f;
		pos = Vector3.zero;
		cell = null;
		lastCell = null;
		deferredPath = new GamePath();
		enabled = true;
		float num = SeasonManager.inst.TimeInYear();
		timeAlive = num * (float)SRand.Range(15, 55);
		life = num * (float)SRand.Range(40, 70);
		if (timeAlive > life - num * 10f)
		{
			timeAlive = life - num * 10f;
		}
		profile = PersonProfile.GetRandomProfile(!useLadyMesh);
		totalTime = SRand.Range(0f, 10f);
		guid = Guid.NewGuid();
		home = null;
		job = null;
		prevMesh = VillagerSystem.MeshType.Default;
		workPosition = default;
		if (thought == null)
		{
			thought = ThoughtBubbleSystem.inst.AddThoughtBubble(Pos);
		}
		thought.scaleMod = 0.7f;
		thought.visible = false;
		textThought = "";
		sick = false;
		needsDoctor = false;
		sickTime = 0f;
		healTime = 0f;
		happyThought = 0f;
		paralyzed = false;
		scared = false;
		lockMovement = false;
		gridPath.Clear();
		travelPath.Clear();
		tiredness = 0;
		HeldResources.Clear();
		villagers.Add(this);
		idxIntoActiveVillagerList = villagers.Count - 1;
		skills.Clear();
	}

	public void Shutdown()
	{
		if (shutdown)
		{
			return;
		}
		shutdown = true;
		ThoughtBubbleSystem.inst.RemoveThoughtBubble(ref thought);
		thought = null;
		World.inst.RemoveFromVillagerGrid(this, ref lastCell);
		VillagerSystem.inst.RemoveVillager(this);
		ResetTiredness();
		if (sick)
		{
			Player.inst.sick.Remove(this);
			Player.PlagueDeathInfo plageDeathInfoForLandmass = Player.inst.GetPlageDeathInfoForLandmass(landMass);
			if (plageDeathInfoForLandmass != null)
			{
				plageDeathInfoForLandmass.deaths++;
				plageDeathInfoForLandmass.deathTime = 0f;
			}
		}
		enabled = false;
		ReleaseFromPool(idxIntoPool, villagerPool);
		ReleaseFromList(idxIntoActiveVillagerList, villagers);
	}

	public static void ReleaseFromPool(int idx, ArrayExt<Villager> array)
	{
		array.RemoveAtSwapBoth(idx);
		if (array.Count > 0 && idx < array.Count)
		{
			array.data[idx].idxIntoPool = idx;
		}
	}

	public static void ReleaseFromList(int idx, ArrayExt<Villager> array)
	{
		array.RemoveAtSwap(idx);
		if (array.Count > 0 && idx < array.Count)
		{
			array.data[idx].idxIntoActiveVillagerList = idx;
		}
	}

	public void HealSickness()
	{
		if (sick)
		{
			sick = false;
			needsDoctor = false;
			Player.inst.sick.Remove(this);
			if (job != null && job is PlaguedJob)
			{
				QuitJob();
			}
			Player.PlagueDeathInfo plageDeathInfoForLandmass = Player.inst.GetPlageDeathInfoForLandmass(landMass);
			if (plageDeathInfoForLandmass != null)
			{
				plageDeathInfoForLandmass.healed++;
			}
		}
	}

	public void TrySeekShrine()
	{
		if (this.job is PlaguedJob || sickTime < Player.inst.GetPlagueSeekShrineThreshold())
		{
			return;
		}
		Job job = JobSystem.inst.FindClosestPlaguedJob(landMass, Pos);
		if (job != null)
		{
			if (this.job != null)
			{
				QuitJob();
			}
			job.AssignEmployee(this);
		}
	}

	public bool BecomeSick(int infectionStrength, bool fromDeadBody = false)
	{
		if (sick || (job != null && job.jobCategory == 8))
		{
			return false;
		}
		Player.PlagueDeathInfo plageDeathInfoForLandmass = Player.inst.GetPlageDeathInfoForLandmass(landMass);
		if (plageDeathInfoForLandmass != null)
		{
			plageDeathInfoForLandmass.plagued++;
		}
		sicknessStrength = infectionStrength;
		sickFromDeadBody = fromDeadBody;
		sick = true;
		needsDoctor = true;
		sickTime = SRand.Range(0f, Player.inst.GetInfectionJumpTime() * 0.2f);
		healTime = 0f;
		Player.inst.sick.Add(this);
		return true;
	}

	public void QuitJob(bool updateplacement = true)
	{
		DropResources();
		consumeOnPickup = true;
		if (job != null)
		{
			TryHideEmployerTirednessThought();
			FreeTime(_freeTime: false);
			previousEmployer = job.employer;
			job.employer.OnUnAssigned(this);
			job.OnEmployeeQuit();
			job.Employee = null;
			job = null;
			prevMesh = VillagerSystem.MeshType.Default;
			if (updateplacement)
			{
				UpdatePlacement();
			}
			ResetTiredness();
		}
	}

	public void SetHome(IResidence home)
	{
		home.AddResident(this);
		Residence = home;
	}

	public void LeaveHome()
	{
		ResetCommute();
		if (home != null)
		{
			home.RemoveResident(this);
		}
		Residence = null;
	}

	public void UpdatePlacement()
	{
		if (paralyzed || scared || lockMovement)
		{
			return;
		}
		if (job == null && home != null)
		{
			MoveToDeferred(home.GetPositionForPerson(this));
		}
		else if (job == null && home == null)
		{
			Vector3 vector = Vector3.Lerp(Vector3.zero, new Vector3(1f, 0f, 1f), SRand.value);
			Cell cell = World.inst.FindMatchingSurroundingCell(Pos, testOrigin: true, 5, (Cell cell2) => (cell2.OccupyingStructure.Count == 0 || cell2.BottomStructureIsCategory(World.pathHash)) && !cell2.HasAnyWater() && !cell2.Busy);
			if (cell != null)
			{
				MoveToDeferred(cell.Position + vector);
			}
		}
	}

	public string GetThought()
	{
		if (Player.inst.LandMassIsAPlayerLandMass(landMass))
		{
			if (sick)
			{
				if (sickTime >= Player.inst.GetPlagueSeekShrineThreshold())
				{
					textThought = LocalizationManager.GetTranslation("citizen_sick_severe_thought");
				}
				else
				{
					textThought = LocalizationManager.GetTranslation("citizen_sick_mild_thought");
				}
				textThoughtTime = 5f;
			}
			else if (Residence == null)
			{
				textThought = ScriptLocalization.VillagerHomeless;
				textThoughtTime = 0.1f;
			}
			else
			{
				string text = "";
				if (DragonSpawn.inst.currentDragons.Count > 0)
				{
					text = LocalizationManager.GetTranslation("VillagerThoughtDragon" + SRand.Range(1, Player.inst.dragonThoughtCount + 1));
				}
				if (text == "" && Time.time - World.inst.timeLastPlaced < 30f && SRand.Range(0, 100) <= 33)
				{
					text = Player.inst.GetBuildingListForLandMass(landMass).Last().ThoughtOnBuilt;
				}
				if (text == "")
				{
					text = LocalizationManager.GetTranslation("VillagerThoughtNormal" + SRand.Range(1, Player.inst.villagerThoughtsCount + 1));
				}
				textThought = text;
				textThoughtTime = SRand.Range(15, 30);
			}
		}
		return textThought;
	}

	internal void CompleteCommute()
	{
		if (commuting)
		{
			commuting = false;
			commuteTime = DayNightManager.inst.GameParameters._24HourTime - startCommuteTime;
		}
	}

	public void DestroyResources()
	{
		for (int i = 0; i < HeldResources.Count; i++)
		{
			HeldResources[i].Shutdown();
		}
		HeldResources.Clear();
	}

	private void UpdateThoughtBubble(float dt)
	{
		if (scared)
		{
			thought.visible = false;
		}
		else
		{
			bool flag = false;
			if (freeTime && currentFreeTimeRoutine is SleepAtHome sleepAtHome)
			{
				flag = sleepAtHome.gotHome;
			}
			if (sick)
			{
				if (sickTime > Player.inst.GetInfectionJumpTime() * 0.25f)
				{
					thought.thought = ThoughtBubbleSystem.Thought.PlagueCritical;
				}
				else
				{
					thought.thought = ThoughtBubbleSystem.Thought.Plague;
				}
				thought.visible = true;
			}
			else if (Residence == null)
			{
				if (job == null || job.employer == null || !(job.employer is RomanBarracks))
				{
					thought.thought = ThoughtBubbleSystem.Thought.House;
					thought.visible = true;
				}
			}
			else if (tiredness >= 2 && !flag)
			{
				thought.thought = ThoughtBubbleSystem.Thought.Tired;
				thought.visible = true;
				if (job != null && job.employer != null)
				{
					Building component = (job.employer as MonoBehaviour).GetComponent<Building>();
					if (component != null && !component.thought.visible)
					{
						component.thought.thought = ThoughtBubbleSystem.Thought.Tired;
						component.thought.visible = true;
					}
				}
			}
			else
			{
				TryHideEmployerTirednessThought();
				if (thought.visible && thought.thought != ThoughtBubbleSystem.Thought.Satisfied)
				{
					thought.thought = ThoughtBubbleSystem.Thought.Satisfied;
					happyThought = 2f;
				}
			}
		}
		if (happyThought > 0f)
		{
			happyThought -= dt;
			if (happyThought <= 0f)
			{
				thought.visible = false;
			}
		}
	}

	private void UpdateSkills(float fixedTime)
	{
		float num = fixedTime * 0.001f * 2f;
		if (job != null)
		{
			string usedSkill = job.employer.GetUsedSkill();
			int hashCode = usedSkill.GetHashCode();
			if (usedSkill.Length > 0)
			{
				bool flag = false;
				float num2 = fixedTime * 0.001f + num;
				int i = 0;
				for (int count = skills.Count; i < count; i++)
				{
					if (skills.data[i].nameHash == hashCode)
					{
						skills.data[i].value += num2;
						if (skills.data[i].value > 1f)
						{
							skills.data[i].value = 1f;
						}
						flag = true;
						break;
					}
				}
				if (!flag)
				{
					Skill skill = new Skill();
					skill.name = usedSkill;
					skill.nameHash = usedSkill.GetHashCode();
					skill.value = num2;
					skills.Add(skill);
				}
			}
		}
		for (int j = 0; j < skills.Count; j++)
		{
			skills.data[j].value -= num;
			if (skills.data[j].value < 0f || skills.data[j].name.Length == 0)
			{
				skills.RemoveAtSwap(j);
				j--;
			}
		}
	}

	public int GetCarryCapacity(int resourceID)
	{
		int num = FreeResourceSystem.inst.GetCarryCapacity(resourceID) + carryBonus;
		if (StreamerEffects.Flag_VillagersCarryMore && num > 0)
		{
			num++;
		}
		return num;
	}

	public int GetRemainingCapacity(int type)
	{
		int num = 0;
		for (int i = 0; i < HeldResources.Count; i++)
		{
			if (HeldResources[i].resourceID == type)
			{
				num++;
			}
		}
		return GetCarryCapacity(type) - num;
	}

	public FreeResource GetFirstHeldResourceOfType(int type)
	{
		for (int i = 0; i < HeldResources.Count; i++)
		{
			if (HeldResources[i].resourceID == type)
			{
				return HeldResources[i];
			}
		}
		return null;
	}

	public int CarryingCount()
	{
		return HeldResources.Count;
	}

	public int GetCarriedResourceAmount()
	{
		return HeldResources.Count;
	}

	public int GetCarriedType()
	{
		if (HeldResources.Count <= 0)
		{
			return -1;
		}
		return HeldResources[0].resourceID;
	}

	public void PickupResource(FreeResource resource, bool playSfx = true)
	{
		PickupResource(resource, Pos, playSfx);
	}

	public void PickupResource(FreeResource resource, Vector3 carryPos, bool playSfx = true)
	{
		if (meshType == VillagerSystem.MeshType.HandCart)
		{
			float num = (float)(HeldResources.Count % 2) * resource.bounds.z * 0.9f;
			float num2 = (float)(HeldResources.Count / 2) * resource.bounds.y * 0.9f;
			resource.offset.x = 0f;
			resource.offset.y = 0.1f + num2;
			resource.offset.z = 0.05f + num;
		}
		else
		{
			MeshType = VillagerSystem.MeshType.Carrying;
			float num3 = 0f;
			for (int i = 0; i < HeldResources.Count; i++)
			{
				num3 += HeldResources[i].bounds.y * 0.9f;
			}
			resource.offset.x = 0f;
			resource.offset.y = 0.1f + num3;
			resource.offset.z = 0.075f;
		}
		resource.Holder = this;
		if (playSfx && Mathff.DistSqrd(Pos, Cam.inst.CamPos) < 2500f)
		{
			switch (resource.resourceID)
			{
			case 1:
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("woodcollect", Pos);
				break;
			case 2:
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("stonecollect", Pos);
				break;
			case 0:
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("wheatcollect", Pos);
				break;
			}
		}
		HeldResources.Add(resource);
	}

	public void DestroyHeldResources()
	{
		if (job != null)
		{
			MeshType = job.meshType;
		}
		else
		{
			MeshType = VillagerSystem.MeshType.Default;
		}
		float num = Mathff.DistSqrd(Pos, Cam.inst.CamPos);
		for (int i = 0; i < HeldResources.Count; i++)
		{
			if (!LoadSave.Loading && !Player.inst.resetting && i == 0 && num < 2500f)
			{
				switch (HeldResources[i].resourceID)
				{
				case 1:
					SfxSystem.inst.PlayFromBankIfVisibleOneShot("wooddeliver", Pos);
					break;
				case 2:
					SfxSystem.inst.PlayFromBankIfVisibleOneShot("stonedeliver", Pos);
					break;
				case 0:
					SfxSystem.inst.PlayFromBankIfVisibleOneShot("wheatdeliver", Pos);
					break;
				}
			}
			HeldResources[i].Shutdown();
		}
		HeldResources.Clear();
	}

	public void DropResources()
	{
		if (job != null)
		{
			MeshType = job.meshType;
		}
		else
		{
			MeshType = VillagerSystem.MeshType.Default;
		}
		if (HeldResources.Count == 0)
		{
			return;
		}
		for (int i = 0; i < HeldResources.Count; i++)
		{
		}
		int resourceID = HeldResources[0].resourceID;
		if (resourceID == 17)
		{
			for (int j = 0; j < HeldResources.Count; j++)
			{
				FreeResource freeResource = HeldResources[j];
				if (freeResource != null)
				{
					freeResource.Holder = null;
					freeResource.claim = null;
					freeResource.Shutdown();
				}
			}
			HeldResources.Clear();
			return;
		}
		if (!Player.inst.resetting)
		{
			Vector3 p = Pos;
			p.y = TerrainGen.inst.GetInterpolatedHeight(p);
			if (HeldResources.Count > 1)
			{
				FreeResourceManager.inst.AddOrMakeAutoStackFor(resourceID, HeldResources.Count, p);
				for (int k = 0; k < HeldResources.Count; k++)
				{
					FreeResource freeResource2 = HeldResources[k];
					if (freeResource2 != null)
					{
						freeResource2.Holder = null;
						freeResource2.claim = null;
						freeResource2.Shutdown();
					}
				}
			}
			else
			{
				HeldResources[0].Pos = p;
				HeldResources[0].Holder = null;
			}
		}
		HeldResources.Clear();
		if (!Player.inst.resetting && !LoadSave.Loading && Mathff.DistSqrd(Pos, Cam.inst.CamPos) < 2500f)
		{
			switch (resourceID)
			{
			case 1:
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("wooddeliver", Pos);
				break;
			case 2:
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("stonedeliver", Pos);
				break;
			case 0:
				SfxSystem.inst.PlayFromBankIfVisibleOneShot("wheatdeliver", Pos);
				break;
			}
		}
	}

	public bool GetPathBuildingAtPos(Vector3 pos, out Building b)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(pos);
		if (cellDataClamped.OccupyingStructure.Count > 0)
		{
			Building building = null;
			float num = float.MaxValue;
			int i = 0;
			for (int count = cellDataClamped.OccupyingStructure.Count; i < count; i++)
			{
				Building building2 = cellDataClamped.OccupyingStructure[i];
				if (building2.IsBuilt() && building2.hasBakedPathingData)
				{
					float num2 = Mathff.DistSqrd(pos, building2.Center());
					if (num2 < num)
					{
						building = building2;
						num = num2;
					}
				}
			}
			b = building;
			return building != null;
		}
		b = null;
		return false;
	}

	private static bool IsLaneBiasCell(Cell c)
	{
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			Building building = c.OccupyingStructure[i];
			if ((building.categoryHash == World.pathHash || building.categoryHash == World.gateHash) && building.IsBuilt())
			{
				return true;
			}
		}
		return false;
	}

	private void ConsumePath()
	{
		if (deferredPath.status != GamePath.Status.Complete)
		{
			return;
		}
		if (!ignoreDeferred)
		{
			if (deferredPath.TryConsume(ref gridPath))
			{
				int num = randPosOffset.Length;
				Vector3 vector = deferredPath.start;
				for (int i = 0; i < gridPath.Count - 2; i++)
				{
					Vector3 vector2 = gridPath.data[i];
					float num2 = randPosOffset[randPosIdx++ % num];
					float num3 = randPosOffset[randPosIdx++ % num];
					float num4 = 0f;
					float num5 = 0f;
					if (IsLaneBiasCell(World.inst.GetCellDataUnsafe((int)vector2.x, (int)vector2.z)))
					{
						float num6 = gridPath.data[i + 1].x - vector.x;
						float num7 = gridPath.data[i + 1].z - vector.z;
						float num8 = num6 * num6 + num7 * num7;
						if (num8 > 0.0001f)
						{
							float num9 = roadLaneOffset / Mathf.Sqrt(num8);
							num4 = num7 * num9;
							num5 = (0f - num6) * num9;
							num2 *= 0.35f;
							num3 *= 0.35f;
						}
					}
					gridPath.data[i].x = vector2.x + Mathf.Clamp(num4 + num2, -0.3f, 0.3f);
					gridPath.data[i].z = vector2.z + Mathf.Clamp(num5 + num3, -0.3f, 0.3f);
					vector = vector2;
				}
				if (gridPath.Count != 0)
				{
					gridPath.Add(deferredPath.end);
				}
				for (int j = 0; j < gridPath.Count; j++)
				{
					Cell cellDataUnsafe = World.inst.GetCellDataUnsafe((int)gridPath.data[j].x, (int)gridPath.data[j].z);
					float groundHeight = TerrainGen.inst.GetGroundHeight(gridPath.data[j].x, gridPath.data[j].z);
					float num10 = Mathff.Max(groundHeight, gridPath.data[j].y);
					Building topStructure = cellDataUnsafe.TopStructure;
					if ((object)topStructure != null && topStructure.IsBuilt())
					{
						if (topStructure.uniqueNameHash == World.stoneBridgeHash || topStructure.uniqueNameHash == World.woodBridgeHash)
						{
							heightTestPos.x = gridPath.data[j].x;
							heightTestPos.y = 100f;
							heightTestPos.z = gridPath.data[j].z;
							Bridge component = topStructure.GetComponent<Bridge>();
							ray.origin = heightTestPos;
							component.walkPlane.Raycast(ray, out var enter);
							Vector3 point = ray.GetPoint(enter);
							if (point.y > num10)
							{
								num10 = point.y;
							}
						}
						else if (topStructure.categoryHash == World.forumHash)
						{
							num10 = topStructure.cachedPos.y + 0.015f;
						}
						else if (topStructure.uniqueNameHash == World.stoneRoadHash)
						{
							num10 = groundHeight + 0.1f;
						}
					}
					gridPath.data[j].y = num10;
				}
				GetPathBuildingAtPos(deferredPath.start, out var b);
				GetPathBuildingAtPos(deferredPath.end, out var b2);
				Building building = b;
				travelPath.ClearFast();
				for (int k = 0; k < gridPath.Count; k++)
				{
					GetPathBuildingAtPos(gridPath.data[k], out var b3);
					if ((object)b3 != null && !b3.hasBakedPathingData)
					{
						b3 = null;
					}
					if (b3 != building && (object)building != null)
					{
						Vector3 start = ((travelPath.Count == 0) ? deferredPath.start : travelPath.data[travelPath.Count - 1].pos);
						Vector3 end = gridPath.data[k];
						if (building == b)
						{
							PathingGraphBaked.AddPathNodesForStartPath(start, end, travelPath, travelPath.Count, ref building.bakedPathingData, out var _, building);
						}
						else
						{
							PathingGraphBaked.AddPathNodesExternalsOnly(start, end, travelPath, travelPath.Count, ref building.bakedPathingData, out var _, building);
						}
					}
					else if ((object)b3 == null)
					{
						travelPath.Add(new TravelNode
						{
							pos = gridPath.data[k],
							isLocal = false
						});
					}
					building = b3;
				}
				if ((object)building != null && building == b2)
				{
					Vector3 start2 = ((travelPath.Count == 0) ? deferredPath.start : travelPath.data[travelPath.Count - 1].pos);
					Vector3 end2 = deferredPath.end;
					PathingGraphBaked.AddPathNodesForEndPath(start2, end2, travelPath, travelPath.Count, ref building.bakedPathingData, out var _, building);
					travelPath.Add(new TravelNode
					{
						pos = deferredPath.end,
						isLocal = true
					});
				}
				else
				{
					travelPath.Add(new TravelNode
					{
						pos = deferredPath.end,
						isLocal = false
					});
				}
			}
		}
		else
		{
			deferredPath.Reset();
		}
		ignoreDeferred = false;
	}

	public bool IsTraveling()
	{
		return travelPath.Count > 0;
	}

	private void WalkPath(float dt, float twitchSpeedModDt, float rotateDistanceDt)
	{
		if (travelPath.Count <= 0)
		{
			return;
		}
		float num = activeSpeed * twitchSpeedModDt * (float)((!scared) ? 1 : 2);
		TravelNode[] data = travelPath.data;
		while (num > 0f)
		{
			if (Mathff.MoveTowards(pos, data[0].pos, num, out var actualAmt, out var newPos))
			{
				buildingToExit = data[0].building;
				travelPath.RemoveAt(0);
			}
			desiredDirection.x = newPos.x - pos.x;
			desiredDirection.y = 0f;
			desiredDirection.z = newPos.z - pos.z;
			pos = newPos;
			num -= actualAmt;
			int count = travelPath.Count;
			if (!(num <= 0f) && count > 0)
			{
				continue;
			}
			cell = World.inst.GetCellDataClamped(pos);
			if (count <= 0)
			{
				Offset = Vector3.zero;
				if (finalRot.HasValue)
				{
					rot = finalRot.Value;
				}
				if (currentFreeTimeRoutine != null)
				{
					currentFreeTimeRoutine.OnFinishedPath();
				}
				CompleteCommute();
			}
			else
			{
				if (Mathff.Abs(desiredDirection.x - lastDir.x) > 0.001f || Mathff.Abs(desiredDirection.z - lastDir.z) > 0.001f)
				{
					desiredAngle = Mathf.Atan2(desiredDirection.x, desiredDirection.z);
					lastDir = desiredDirection;
				}
				currAngle = Mathff.MoveTowardsAngle(currAngle, desiredAngle, rotateDistanceDt);
				if (Mathff.Abs(currAngle - lastCurrAngle) > 0.001f)
				{
					lastCurrAngle = currAngle;
					Mathff.SetRotationY(ref scratchQuat, currAngle);
					rot = scratchQuat;
				}
			}
			Mathff.SetTRS(ref instancesRef.data[(int)meshType].silos.data[s][idx], GetPosWithOffset(), rot, fullScale);
			break;
		}
	}

	public static void GetYAdjust(Cell cell, ref float yAdjust, ref float magnitudeMul, ref float bounceSpeedMul)
	{
		if (cell.Type == TerrainType.Water)
		{
			bool flag = false;
			if (cell.OccupyingStructure.Count > 0)
			{
				Building building = cell.OccupyingStructure[0];
				flag = (building.categoryHash == pathHash || building.uniqueNameHash == dockHash || building.uniqueNameHash == fishinghutHash) && building.IsBuilt();
			}
			if (!flag)
			{
				yAdjust = -0.3f;
				magnitudeMul = 0.35f;
				bounceSpeedMul = 0.5f;
			}
		}
	}

	private void UpdateAnim(float dt)
	{
		float yAdjust = 0f;
		float magnitudeMul = 1f;
		float bounceSpeedMul = 1f;
		GetYAdjust(cell, ref yAdjust, ref magnitudeMul, ref bounceSpeedMul);
		if (travelPath.Count > 0)
		{
			totalTime += dt * bounceSpeed * bounceSpeedMul;
			if (totalTime > 1f)
			{
				totalTime = 0f;
			}
			yAdjust += Player.inst.walkBounce.Evaluate(totalTime) * bounceMagnitude * magnitudeMul;
		}
		offset.y = Mathff.Lerp(offset.y, yAdjust, Mathff.Min(dt * 30f, 1f));
	}

	public void Scare(Vector3 toPos)
	{
		if (!scared)
		{
			if (!scared)
			{
				nonScaredDestination = ((travelPath.Count > 0) ? travelPath.data[travelPath.Count - 1].pos : Pos);
			}
			scared = true;
			scaredTimer.Reset();
			MoveToDeferred(toPos);
		}
	}

	public void UpdateMind(float dt, float twitchSpeedModDt, float rotateDistanceDt, int currFrame)
	{
		textThoughtTime -= dt;
		if (scared && scaredTimer.Update(dt))
		{
			scared = false;
			MoveToDeferred(nonScaredDestination);
		}
		if (paralyzed)
		{
			return;
		}
		if (!lockMovement && !scared && freeTime)
		{
			currentFreeTimeRoutine.Update(dt);
			if (!currentFreeTimeRoutine.IsActive())
			{
				currentFreeTimeRoutine = freeTimeRoutines[freeTimeRoutines.Length - 1];
				currentFreeTimeRoutine.Init(this);
			}
		}
		life -= dt * Mathff.Lerp(1.2f, 0.8f, health);
		timeAlive += dt;
		if (!lockMovement)
		{
			if (debugDrawPath && travelPath.Count > 0)
			{
				GetPathBuildingAtPos(Pos, out var b);
				Debug.DrawLine(travelPath.data[0].pos, Pos, OnLocalPath(b) ? Color.red : Color.green, 0f, depthTest: false);
				for (int i = 1; i < travelPath.Count; i++)
				{
					Draw.SolidBox(travelPath.data[i].pos, Quaternion.identity, Vector3.one * 0.05f, travelPath.data[i].isLocal ? Color.red : Color.green);
					Debug.DrawLine(travelPath.data[i].pos, travelPath.data[i - 1].pos, travelPath.data[i].isLocal ? Color.red : Color.green, 0f, depthTest: false);
				}
				Draw.SolidBox(travelPath.data[0].pos, Quaternion.identity, Vector3.one * 0.05f, travelPath.data[0].isLocal ? Color.red : Color.green);
				Draw.SolidBox(Pos, Quaternion.identity, Vector3.one * 0.1f, OnLocalPath(b) ? Color.red : Color.green);
			}
			ConsumePath();
			WalkPath(dt, twitchSpeedModDt, rotateDistanceDt);
			if (cell == null)
			{
				cell = World.inst.GetCellDataClamped(Pos);
			}
			if (meshType != VillagerSystem.MeshType.HandCart && dt < 0.0166f)
			{
				UpdateAnim(dt);
			}
			UpdateCell();
		}
		if (currFrame % 20 == fixedUpdateFrame)
		{
			float num = dt * 20f;
			UpdateThoughtBubble(num);
			UpdateSkills(num);
			if (job != null && job.idleJob && job.employer is Building building && !building.DuringWorkHours(-0.01f))
			{
				QuitJob();
			}
			if (NeedsCloserHome())
			{
				CloserHomeFinder.inst.AddCandidate(this);
			}
		}
		if (thought.visible)
		{
			thought.pos = Pos;
			if (cell.OccupyingStructure.Count > 0)
			{
				thought.offset.y = Mathff.Clamp(cell.OccupyingStructure[0].size.y - 0.5f, 0f, 1.5f);
				return;
			}
			thought.offset.x = 0f;
			thought.offset.y = 0f;
			thought.offset.z = 0f;
		}
	}

	public bool NeedsCloserHome()
	{
		if (job != null && job.employer.GetStartHour() != -1f && !job.idleJob && Residence != null && ((Mathf.Clamp01(commuteTime / (job.employer.GetEndHour() - job.employer.GetStartHour())) >= 0.6f && commuteTime != -1f) || tiredness >= 1))
		{
			return true;
		}
		return false;
	}

	private bool DoSwapSearchAt(Vector3 searchOrigin, Home currResidence, Vector3 homePos)
	{
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		for (int i = 1; i < 8; i++)
		{
			int num = (int)searchOrigin.x - i;
			int num2 = (int)searchOrigin.z - i;
			int num3 = (int)searchOrigin.x + i;
			int num4 = (int)searchOrigin.z + i;
			for (int j = num2; j <= num4; j++)
			{
				if (j < 0)
				{
					continue;
				}
				if (j >= gridHeight)
				{
					break;
				}
				for (int k = num; k <= num3; k++)
				{
					if (k < 0)
					{
						continue;
					}
					if (k >= gridWidth)
					{
						break;
					}
					if (k != num && j != num2 && k != num3 && j != num4)
					{
						continue;
					}
					Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(k + j * gridWidth);
					if (cellDataUnsafe == null || cellDataUnsafe.Type != TerrainType.None)
					{
						continue;
					}
					Building building = cellDataUnsafe.StructureFindByCategory(World.houseCategoryHash);
					if (!(building == null) && building.IsBuilt())
					{
						Home component = building.GetComponent<Home>();
						if (Player.inst.TrySwapResidents(currResidence, component, this, homePos))
						{
							return true;
						}
					}
				}
			}
		}
		return false;
	}

	public float FindSkill(int hash)
	{
		int i = 0;
		for (int count = skills.Count; i < count; i++)
		{
			if (skills.data[i].nameHash == hash)
			{
				return skills.data[i].value;
			}
		}
		return 0f;
	}

	private void UpdateCell()
	{
		if (lastCell != cell)
		{
			World inst = World.inst;
			inst.RemoveFromVillagerGrid(this, ref lastCell);
			inst.AddToVillagerGrid(this);
			UpdateSpeed();
		}
	}

	public void UpdateSpeed()
	{
		activeSpeed = 1f * cell.speedModifier;
		activeSpeed *= speedBonusMultiplier;
		if (sick)
		{
			activeSpeed *= 0.5f;
		}
	}

	public void UpdateTRS()
	{
		Mathff.SetTRS(ref instancesRef.data[(int)meshType].silos.data[s][idx], GetPosWithOffset(), rot, fullScale);
	}

	public Vector3 GetPosWithOffset()
	{
		Vector3 result = pos;
		result.y += offset.y;
		result.x += offset.x;
		result.z += offset.z;
		return result;
	}

	public void TeleportTo(Vector3 newPos)
	{
		newPos.y = TerrainGen.inst.GetHeight(newPos);
		Pos = newPos;
		Cell cellDataClamped = World.inst.GetCellDataClamped(newPos);
		Cell newCell = null;
		bool flag = AddToLandMassGrid(cellDataClamped, ref newCell);
		if (newCell != null)
		{
			if (flag)
			{
				newPos = newCell.Center2D;
			}
			if (landMass != newCell.landMassIdx)
			{
				Player.inst.Homeless.Add(this);
				LeaveHome();
				QuitJob();
			}
			for (int i = 0; i < HeldResources.Count; i++)
			{
				HeldResources[i].landMassIdx = newCell.landMassIdx;
			}
		}
		travelPath.Clear();
	}

	public bool AddToLandMassGrid(Cell cell, ref Cell newCell)
	{
		bool result = false;
		if (cell.landMassIdx == -1)
		{
			result = true;
			cell = World.inst.FindMatchingSurroundingCell(cell, testOrigin: false, 10, (Cell c) => c.landMassIdx != -1);
			if (cell == null)
			{
				Debug.LogError("could not find matching landmass");
				life = -1f;
			}
		}
		if (cell != null)
		{
			World.inst.RemoveVillagerFromLandmass(this);
			landMass = cell.landMassIdx;
			World.inst.AddVillagerToLandmass(cell.landMassIdx, this);
			newCell = cell;
			if (lastCell != null)
			{
				World.inst.RemoveFromVillagerGrid(this, ref lastCell);
			}
			World.inst.AddToVillagerGrid(this);
		}
		return result;
	}

	public bool OnLocalPath(Building buildingWeAreIn)
	{
		if (travelPath.Count <= 0 || !travelPath.data[0].isLocal)
		{
			if (buildingToExit != null)
			{
				return buildingWeAreIn == buildingToExit;
			}
			return false;
		}
		return true;
	}

	public bool IsMoving()
	{
		if (deferredPath.status != GamePath.Status.Complete && travelPath.Count > 0)
		{
			return true;
		}
		return false;
	}

	public void MoveToDeferred(TransformData newPos)
	{
		MoveToDeferred(newPos.position, newPos.rotation);
	}

	public void MoveToDeferred(Vector3 newPos, Quaternion? rot = null)
	{
		GetPathBuildingAtPos(Pos, out var b);
		if (object.Equals(newPos, deferredPath.end) && OnLocalPath(b))
		{
			return;
		}
		if (object.Equals(newPos, Pos))
		{
			travelPath.Clear();
			ignoreDeferred = true;
			return;
		}
		Cell cellData = World.inst.GetCellData(newPos);
		Cell cellData2 = World.inst.GetCellData(Pos);
		bool flag = cellData.OccupyingStructure.Count > 0;
		for (int i = 0; i < cellData.OccupyingStructure.Count; i++)
		{
			if (!cellData.OccupyingStructure[i].IsBuilt())
			{
				flag = false;
				break;
			}
		}
		if (cellData == cellData2 && (!flag || cellData.OccupyingStructure.Count == 0 || cellData.BottomStructureIsCategory(World.pathHash) || cellData.StructureCompareCategoryAll(World.editTerrainZoneHash) || cellData.BottomStructureIsCategory(World.farmHash) || cellData.BottomStructureIsCategory(World.forumHash) || cellData.BottomStructureIsCategory(World.damHash) || cellData.BottomStructureIsCategory(World.castleblockHash) || cellData.BottomStructureIsCategory(World.bathCategoryHash) || cellData.BottomStructureIsCategory(World.templeHash)))
		{
			ignoreDeferred = true;
			travelPath.Clear();
			travelPath.Add(new TravelNode
			{
				pos = newPos,
				isLocal = false
			});
			deferredPath.start = Pos;
			deferredPath.end = newPos;
			finalRot = rot;
			return;
		}
		GetPathBuildingAtPos(newPos, out var b2);
		if (b != null && b == b2)
		{
			ignoreDeferred = true;
			travelPath.Clear();
			PathingGraphBaked.AddPathNodesBetween(Pos, newPos, travelPath, 0, ref b.bakedPathingData, out var _, b);
			travelPath.Insert(0, new TravelNode
			{
				pos = Pos,
				isLocal = true
			});
			travelPath.Add(new TravelNode
			{
				pos = newPos,
				isLocal = true
			});
			deferredPath.start = Pos;
			deferredPath.end = newPos;
			finalRot = rot;
		}
		else
		{
			ignoreDeferred = false;
			deferredPath.start = Pos;
			deferredPath.end = newPos;
			finalRot = rot;
			World.inst.threadedPather.RequestPath(deferredPath);
		}
	}

	public static void ValidatePath(Vector3 start, List<Vector3> path)
	{
		Vector3 vector = start;
		float amt = 0.05f;
		while (path.Count > 0)
		{
			float actualAmt = 0f;
			if (Mathff.MoveTowards(vector, path[0], amt, out actualAmt, out var newPos))
			{
				path.RemoveAt(0);
			}
			vector = newPos;
			World.inst.GetCellDataClamped(vector);
		}
	}

	public void SetWorkPosition(TransformData newWorkPosition)
	{
		workPosition = newWorkPosition;
	}

	public TransformData GetWorkPosition()
	{
		return workPosition;
	}

	public static bool operator ==(Villager c1, object c2)
	{
		if ((object)c1 == null)
		{
			return c2 == null;
		}
		if (!c1.enabled && c2 == null)
		{
			return true;
		}
		return c1.Equals(c2);
	}

	public static bool operator !=(Villager c1, object c2)
	{
		return !(c1 == c2);
	}

	public Vector3 GetDesiredTrackingPos()
	{
		return GetPosWithOffset();
	}

	public float GetRadius()
	{
		return 0.25f;
	}

	public Vector3 GetPosition()
	{
		return Pos;
	}

	public Vector3 GetVelocity()
	{
		return Vector3.zero;
	}

	public Vector3 GetPredictedPosition(float time)
	{
		return Pos;
	}

	public HitSfxResult TakeProjectileDamage(float dmg, DamageType dmgType, DamageSource dmgSource, Vector3 pos, Vector3 incomingVel, int teamID)
	{
		return HitSfxResult.None;
	}

	public bool IsInvalid()
	{
		return false;
	}

	public void FreeTime(bool _freeTime)
	{
		if (freeTime == _freeTime)
		{
			return;
		}
		freeTime = _freeTime;
		if (freeTime)
		{
			if (tiredness > 0)
			{
				currentFreeTimeRoutine = freeTimeRoutines[freeTimeRoutines.Length - 1];
			}
			else
			{
				currentFreeTimeRoutine = freeTimeRoutines[0];
			}
			currentFreeTimeRoutine.Init(this);
			if (meshType == VillagerSystem.MeshType.HandCart)
			{
				prevMesh = meshType;
				MeshType = VillagerSystem.MeshType.Default;
			}
			return;
		}
		currentFreeTimeRoutine.End();
		currentFreeTimeRoutine = null;
		if (job != null)
		{
			MoveToDeferred(job.employer.GetPositionForPerson(this));
		}
		if (!(job is IdleJob))
		{
			commuting = true;
			startCommuteTime = DayNightManager.inst.GameParameters._24HourTime;
		}
		if (prevMesh == VillagerSystem.MeshType.HandCart)
		{
			MeshType = prevMesh;
		}
	}

	public void ResetCommute()
	{
		commuteTime = -1f;
		commuting = false;
	}

	public void AddTiredness(int amt = 1)
	{
		tiredness += amt;
	}

	private void SetTiredness(int amt)
	{
		tiredness = amt;
	}

	public void ResetTiredness()
	{
		tiredness = 0;
	}

	private void TryHideEmployerTirednessThought()
	{
		if (job == null || !(job.employer as MonoBehaviour != null))
		{
			return;
		}
		Building component = (job.employer as MonoBehaviour).GetComponent<Building>();
		if (!(component != null) || !component.thought.visible || component.thought.thought != ThoughtBubbleSystem.Thought.Tired)
		{
			return;
		}
		for (int i = 0; i < component.jobs.Count; i++)
		{
			if (component.jobs[i] != null && component.jobs[i].HasEmployee() && !(component.jobs[i].Employee == this) && component.jobs[i].Employee.tiredness >= 2)
			{
				return;
			}
		}
		component.thought.thought = ThoughtBubbleSystem.Thought.GeneralError;
		component.thought.visible = false;
	}
}
