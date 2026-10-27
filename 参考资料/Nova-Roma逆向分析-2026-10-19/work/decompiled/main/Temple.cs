using System;
using System.Collections.Generic;
using FMOD;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using PlayEveryWare.Common.Extensions;
using UnityEngine;

public class Temple : Tickable, IOutputInfo, IEmployer
{
	[Serializable]
	public class TempleSaveData : SaveClass<Temple, TempleSaveData>
	{
		private int dedicateIdx;

		private int bonusLevel;

		private float festivalTime;

		public override TempleSaveData Pack(Temple obj)
		{
			dedicateIdx = obj.dedicateIdx;
			bonusLevel = obj.bonusLevel;
			festivalTime = obj.festivalTime;
			return this;
		}

		public override Temple Unpack(Temple obj)
		{
			if (dedicateIdx != -1)
			{
				obj.SetDedicateIdx(dedicateIdx);
			}
			obj.bonusLevel = bonusLevel;
			obj.SetupBonus();
			obj.festivalTime = festivalTime;
			return obj;
		}
	}

	public Building b;

	public EventReference[] onSelectEvent;

	public EventInstance eFestivalAmb;

	internal InWorldExclamation issueButton;

	public Mesh[] godTemples;

	public Mesh apolloBonusMesh;

	public ParticleSystem apolloHealthFX;

	private EventInstance eShrineHealingAmb;

	public ArrayExtRef<PlaguedJob> plagued = new ArrayExtRef<PlaguedJob>(20);

	public const int MAX_SHRINE_VILLAGERS = 20;

	public Transform[] plaguedPositions;

	private int dedicateIdx = -1;

	public OneOffEffect dedicateEffect;

	private List<int> festivalFXPick;

	private float animTime;

	public AnimationCurve festivalAnim;

	public GameObject festivalDecor;

	public RadiusBonus radBonus;

	public RadiusBonusProduction radBonusProduction;

	public RadiusBonusBuildingProduction radBonusBuildingProduction;

	internal int bonusLevel;

	private float festivalTimeMax = 100f;

	private float festivalTime;

	public GameObject[] festivalFX;

	public Transform[] festivalSpots;

	public string GetError()
	{
		return null;
	}

	public int GetActivePlaguedCount()
	{
		int num = 0;
		for (int i = 0; i < plagued.Count; i++)
		{
			PlaguedJob plaguedJob = plagued.data[i];
			if (plaguedJob != null && plaguedJob.HasEmployee())
			{
				num++;
			}
		}
		return num;
	}

	private TransformData GetPlaguedPosition(Villager p)
	{
		Transform transform = plaguedPositions[plagued.IndexOf((PlaguedJob)p.job)];
		return new TransformData
		{
			position = transform.position,
			rotation = transform.rotation
		};
	}

	Vector3 IEmployer.GetPosition()
	{
		return b.GetPosition();
	}

	TransformData IEmployer.GetPositionForPerson(Villager p)
	{
		return GetPlaguedPosition(p);
	}

	bool IEmployer.IsOpen()
	{
		return b.IsOpen();
	}

	void IEmployer.OnAssigned(Villager p)
	{
		p.SetWorkPosition(GetPlaguedPosition(p));
	}

	void IEmployer.OnUnAssigned(Villager p)
	{
	}

	void IEmployer.OnJobRemoved(Job j)
	{
	}

	string IEmployer.GetUsedSkill()
	{
		return "";
	}

	int IEmployer.LandMass()
	{
		return b.LandMass();
	}

	int IEmployer.GetJobCategory()
	{
		return 64;
	}

	bool IEmployer.DuringWorkHours(float buffer)
	{
		return true;
	}

	float IEmployer.GetStartHour()
	{
		return -1f;
	}

	float IEmployer.GetEndHour()
	{
		return -1f;
	}

	public int GetDedicateIdx()
	{
		return dedicateIdx;
	}

	public void SetDedicateIdx(int i)
	{
		dedicateIdx = i;
		if (i != 3 || bonusLevel <= 0)
		{
			transform.GetComponentInChildren<MeshFilter>().sharedMesh = godTemples[i];
		}
		b.onBuildingSelectEvent = onSelectEvent[i];
		if (dedicateIdx == 2)
		{
			if ((bool)radBonus)
			{
				radBonus.residentialTileID = 229;
				radBonus.overlayWhenSelected = true;
			}
		}
		else if (dedicateIdx == 5)
		{
			if ((bool)radBonusBuildingProduction)
			{
				radBonusBuildingProduction.radius = 5f;
				radBonusBuildingProduction.buildingCount = 5;
				radBonusBuildingProduction.categoryMatch = "farm";
				radBonusBuildingProduction.Bonus = 1;
				radBonusBuildingProduction.overlayWhenSelected = true;
			}
		}
		else if (dedicateIdx == 1)
		{
			if ((bool)radBonusBuildingProduction)
			{
				radBonusBuildingProduction.radius = 3f;
				radBonusBuildingProduction.buildingCount = 5;
				radBonusBuildingProduction.uniqueNameMatch = new string[6] { "charcoalmaker", "largecharcoalmaker", "toolsmith", "weaponsmith", "potteryworkshop", "largepotteryworkshop" };
				radBonusBuildingProduction.Bonus = 1;
				radBonusBuildingProduction.overlayWhenSelected = true;
			}
		}
		else if (dedicateIdx == 7)
		{
			if ((bool)radBonusBuildingProduction)
			{
				radBonusBuildingProduction.radius = 3f;
				radBonusBuildingProduction.buildingCount = 5;
				radBonusBuildingProduction.uniqueNameMatch = new string[1] { "fishinghut" };
				radBonusBuildingProduction.Bonus = 1;
				radBonusBuildingProduction.overlayWhenSelected = true;
			}
		}
		else if (dedicateIdx == 4 && (bool)radBonusBuildingProduction)
		{
			radBonusBuildingProduction.radius = 3f;
			radBonusBuildingProduction.buildingCount = 3;
			radBonusBuildingProduction.uniqueNameMatch = new string[1] { "archer" };
			radBonusBuildingProduction.Bonus = 25;
			radBonusBuildingProduction.overlayWhenSelected = true;
		}
	}

	private void Awake()
	{
		b = GetComponent<Building>();
		radBonus = GetComponent<RadiusBonus>();
		radBonusProduction = GetComponent<RadiusBonusProduction>();
		radBonusBuildingProduction = GetComponent<RadiusBonusBuildingProduction>();
	}

	public override void OnEnableInternal()
	{
		HideFestivalFX();
		festivalFXPick = new List<int>(festivalFX.Length);
		for (int i = 0; i < festivalFX.Length; i++)
		{
			festivalFXPick.Add(i);
		}
		festivalFXPick.Shuffle();
		base.OnEnableInternal();
	}

	private void Start()
	{
		TryInitIssueButton();
	}

	private void OnDestroy()
	{
		if (b.destroyedWhileInPlay)
		{
			for (int i = 0; i < plagued.Count; i++)
			{
				JobSystem.inst.RemoveJob(plagued.data[i]);
			}
			plagued.Clear();
		}
		if (eFestivalAmb.isValid() && eFestivalAmb.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
		{
			eFestivalAmb.stop(STOP_MODE.IMMEDIATE);
		}
		StopShrineHealingAmb(STOP_MODE.IMMEDIATE);
	}

	private void StopShrineHealingAmb(STOP_MODE mode)
	{
		if (eShrineHealingAmb.isValid())
		{
			eShrineHealingAmb.stop(mode);
			eShrineHealingAmb.clearHandle();
		}
	}

	private void OnBuilt()
	{
		ResourceStatistics.inst.TrySetEncounteredResource(4);
	}

	private void TryInitIssueButton()
	{
		if (issueButton == null)
		{
			issueButton = UnityEngine.Object.Instantiate(World.inst.issuePrefab);
			issueButton.transform.SetParent(transform.GetChild(0));
			issueButton.transform.localPosition = new Vector3(0f, b.size.y + 0.5f, 0f);
			issueButton.onClick = () =>
			{
				ShowGods();
			};
			issueButton.gameObject.SetActive(value: false);
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		if (b.WorkersAllocated <= 0)
		{
			radBonus.Mod = 0f;
			radBonusProduction.Mod = 0f;
		}
		else
		{
			radBonus.Mod = 1f;
			radBonusProduction.Mod = 1f;
		}
		if (festivalTime > 0f && festivalTime - dt <= 0f)
		{
			if (festivalFX != null)
			{
				for (int i = 0; i < festivalFX.Length; i++)
				{
					if (festivalFX[i].activeSelf)
					{
						EffectsMan.inst.BuildPuff.CreateAndPlay(festivalFX[i].transform.position);
					}
				}
			}
			HideFestivalFX();
			if (eFestivalAmb.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
			{
				eFestivalAmb.stop(STOP_MODE.ALLOWFADEOUT);
			}
		}
		if (festivalTime > 0f)
		{
			animTime += dt * 2f;
			float num = festivalAnim.Evaluate(animTime);
			Vector3 localScale = new Vector3(num, num, num);
			for (int j = 0; j < festivalFX.Length; j++)
			{
				festivalFX[j].transform.localScale = localScale;
			}
		}
		festivalTime -= dt;
		if (festivalTime <= 0f)
		{
			festivalTime = 0f;
		}
		int num2;
		int num3;
		if (dedicateIdx == 3)
		{
			num2 = ((b.uniqueNameHash == World.templeHash) ? 1 : 0);
			if (num2 != 0 && Player.inst.sick.Count > 0)
			{
				num3 = ((bonusLevel > 0) ? 1 : 0);
				goto IL_01ae;
			}
		}
		else
		{
			num2 = 0;
		}
		num3 = 0;
		goto IL_01ae;
		IL_01ae:
		bool flag = (byte)num3 != 0;
		if (num2 != 0)
		{
			Util.SetParticleEffects(apolloHealthFX, flag);
		}
		if (flag && !eShrineHealingAmb.isValid())
		{
			eShrineHealingAmb = RuntimeManager.CreateInstance("event:/SFX ASITP/sfx_apollo_shrine_healing_lp");
			eShrineHealingAmb.set3DAttributes(b.Center().To3DAttributes());
			eShrineHealingAmb.start();
			eShrineHealingAmb.release();
		}
		else if (!flag)
		{
			StopShrineHealingAmb(STOP_MODE.ALLOWFADEOUT);
		}
		base.Tick(dt, currFrame);
	}

	private void HideFestivalFX()
	{
		if (festivalFX != null)
		{
			for (int i = 0; i < festivalFX.Length; i++)
			{
				festivalFX[i].SetActive(value: false);
			}
		}
		if ((bool)festivalDecor)
		{
			festivalDecor.SetActive(value: false);
		}
	}

	public void ShowGods()
	{
		Building component = GetComponent<Building>();
		GameUI.inst.SetSelectedBuildingNew(component);
		GameUI.inst.ClearUIForClick();
		GodUI.inst.Show(component, component.Center());
		if (dedicateIdx != -1)
		{
			GodUI.inst.SetSelectedGod(dedicateIdx);
		}
		issueButton.gameObject.SetActive(value: false);
	}

	private void SetupBonus()
	{
		if (dedicateIdx == 2)
		{
			if (bonusLevel > 0)
			{
				radBonus.ApplyBonus();
				radBonus.overlayWhenSelected = true;
			}
		}
		else if (dedicateIdx == 5)
		{
			if (bonusLevel > 0 && (bool)radBonusBuildingProduction)
			{
				radBonusBuildingProduction.ApplyBonus();
			}
		}
		else if (dedicateIdx == 1)
		{
			if (bonusLevel > 0 && (bool)radBonusBuildingProduction)
			{
				radBonusBuildingProduction.ApplyBonus();
			}
		}
		else if (dedicateIdx == 7)
		{
			if (bonusLevel > 0 && (bool)radBonusBuildingProduction)
			{
				radBonusBuildingProduction.ApplyBonus();
			}
		}
		else if (dedicateIdx == 4)
		{
			if (bonusLevel > 0 && (bool)radBonusBuildingProduction)
			{
				radBonusBuildingProduction.ApplyBonus();
			}
		}
		else
		{
			if (dedicateIdx != 3)
			{
				return;
			}
			MeshFilter componentInChildren = transform.GetComponentInChildren<MeshFilter>();
			if (bonusLevel > 0)
			{
				if (b.customName == b.FriendlyName)
				{
					b.customName = LocalizationManager.GetTranslation("building_shrineofasclepius_title");
				}
				componentInChildren.sharedMesh = apolloBonusMesh;
				for (int i = 0; i < 20; i++)
				{
					if (plagued.Count == i)
					{
						PlaguedJob plaguedJob = new PlaguedJob(this);
						plaguedJob.ManualAssignment = true;
						JobSystem.inst.AddNewJob(plaguedJob, 64);
						plagued.Add(plaguedJob);
					}
				}
			}
			else
			{
				componentInChildren.sharedMesh = godTemples[3];
			}
		}
	}

	internal void UnlockBonus()
	{
		bonusLevel++;
		SetupBonus();
	}

	public float GetFestivalProgress()
	{
		return 1f - festivalTime / festivalTimeMax;
	}

	internal void StartFestival()
	{
		festivalTime = festivalTimeMax;
		SetupFestivalFX();
		EvalFestivalForumHappinessBonus(out var okTiles, out var _, out var _);
		okTiles = Mathff.Min(okTiles, 6);
		Player.inst.AddHappinessMod("festival", festivalTime, okTiles * 2, LocalizationManager.GetTranslation("happinessmod_fesitval"), b.LandMass(), addition: true);
	}

	internal void OnLoadAfterAllBuildingsPlaced()
	{
		if (festivalTime > 0f)
		{
			SetupFestivalFX(fromLoad: true);
		}
	}

	private void SetupFestivalFX(bool fromLoad = false)
	{
		festivalFXPick.Shuffle();
		animTime = (fromLoad ? 1 : 0);
		int num = 0;
		for (int i = 0; i < festivalSpots.Length; i++)
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(festivalSpots[i].position);
			if (cellDataClamped.OccupyingStructure.Count == 1 && cellDataClamped.StructureCompareCategory(World.forumHash))
			{
				festivalFX[festivalFXPick[num]].SetActive(value: true);
				festivalFX[festivalFXPick[num]].transform.position = cellDataClamped.Center3D;
				festivalFX[festivalFXPick[num]].transform.localRotation = Quaternion.Euler(0f, SRand.Range(0, 4) * 90 + SRand.Range(-5, 5), 0f);
				festivalFX[festivalFXPick[num]].transform.localScale = (fromLoad ? Vector3.one : Vector3.zero);
				if (!fromLoad)
				{
					EffectsMan.inst.BuildPuff.CreateAndPlay(cellDataClamped.Center3D);
				}
				num++;
				if (num >= 6)
				{
					break;
				}
			}
		}
		Util.SetActive(festivalDecor, active: true);
		if (eFestivalAmb.isValid())
		{
			eFestivalAmb.stop(STOP_MODE.IMMEDIATE);
		}
		eFestivalAmb = RuntimeManager.CreateInstance("event:/SFX ASITP/Ambiences/ambSpot_templeFestival");
		eFestivalAmb.set3DAttributes(b.Center().To3DAttributes());
		eFestivalAmb.start();
		eFestivalAmb.release();
	}

	public void EvalFestivalForumHappinessBonus(out int okTiles, out int occupied, out int fail)
	{
		okTiles = 0;
		occupied = 0;
		fail = 0;
		for (int i = 0; i < festivalSpots.Length; i++)
		{
			Cell cellDataClamped = World.inst.GetCellDataClamped(festivalSpots[i].position);
			if (cellDataClamped.StructureCompareCategoryNameAll(World.forumHash))
			{
				if (cellDataClamped.OccupyingStructure.Count == 1)
				{
					okTiles++;
				}
				else
				{
					occupied++;
				}
			}
			else
			{
				fail++;
			}
		}
	}
}
