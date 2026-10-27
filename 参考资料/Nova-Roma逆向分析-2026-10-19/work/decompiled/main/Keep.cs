using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Assets.Code.Jobs;
using Assets.Interface;
using I2.Loc;
using UnityEngine;

public class Keep : MonoBehaviour, IOutputInfo, IResourceStorage, IResourceStorageBase, IResourceProviderContainer, IWorkerUIDisplay, IStorageInfo
{
	private enum EAdvisor
	{
		Food,
		City,
		Military
	}

	private class AdvisorMsg
	{
		public EAdvisor advisor;

		public string tag;

		public string sound;

		public float timeSinceLastHeard;

		public float timeToWaitFromLast;

		public AdvisorMsg(EAdvisor a, string _sound, string _tag, float _timeToWait)
		{
			advisor = a;
			tag = _tag;
			sound = _sound;
			timeSinceLastHeard = 0f;
			timeToWaitFromLast = _timeToWait;
		}
	}

	[Serializable]
	public class KeepSaveData : SaveClass<Keep, KeepSaveData>
	{
		private int stone;

		private int wood;

		private int food;

		[OptionalField(VersionAdded = 2)]
		private int apples;

		public override KeepSaveData Pack(Keep k)
		{
			stone = k.stoneStack.Count();
			wood = k.woodStack.Count();
			food = k.foodStack.Count();
			apples = k.appleStack.Count();
			return this;
		}

		public override Keep Unpack(Keep k)
		{
			k.stoneStack.Clear();
			k.woodStack.Clear();
			k.foodStack.Clear();
			k.stoneStack.Add(stone);
			k.woodStack.Add(wood);
			k.foodStack.Add(food);
			k.appleStack.Add(apples);
			return k;
		}
	}

	public InWorldExclamation issuePrefab;

	[NonSerialized]
	public InWorldExclamation issueButton;

	public HealthBar healthBar;

	private Building b;

	public SeedShip seedShip;

	public int placementRadius = 10;

	private AdvisorMsg[] advisorMessages = new AdvisorMsg[28]
	{
		new AdvisorMsg(EAdvisor.Food, "AgricultureAdvisorThinking", "farmneed0", 0f),
		new AdvisorMsg(EAdvisor.Food, "AgricultureAdvisorBad", "croprot", 140f),
		new AdvisorMsg(EAdvisor.Food, "AgricultureAdvisorThinking", "farmadvise1", 90f),
		new AdvisorMsg(EAdvisor.Food, "AgricultureAdvisorBad", "farmadvise2", 70f),
		new AdvisorMsg(EAdvisor.Food, "AgricultureAdvisorBad", "farmadvise3", 45f),
		new AdvisorMsg(EAdvisor.Food, "AgricultureAdvisorThinking", "maxfood", 240f),
		new AdvisorMsg(EAdvisor.Food, "AgricultureAdvisorAcceptance", "maxfood-construction", 120f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorAcceptance", "houseneed0", 0f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorAcceptance", "houseneed", 0f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorThinking", "hopeneed", 240f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorDispleased", "happy1", 240f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorThinking", "happy2", 240f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorThinking", "happy3", 480f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorAcceptance", "happy4", 480f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorAcceptance", "happy5", 540f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorPompous", "happy6", 660f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorAcceptance", "happy3-house", 480f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorAcceptance", "happy3-tavern", 420f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorAcceptance", "happy3-townsquare", 480f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorBad", "productionhalt-quarry", 240f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorBad", "productionhalt-forester", 240f),
		new AdvisorMsg(EAdvisor.City, "CityAdvisorBad", "nobuilders", 60f),
		new AdvisorMsg(EAdvisor.Military, "MilitaryAdvisorThinking", "vikingwarning1", 300f),
		new AdvisorMsg(EAdvisor.Military, "MilitaryAdvisorThinking", "vikingwarning2", 300f),
		new AdvisorMsg(EAdvisor.Military, "MilitaryAdvisorAccepance", "dragonkill", 600f),
		new AdvisorMsg(EAdvisor.Military, "MilitaryAdvisorThinking", "dragonnokill", 600f),
		new AdvisorMsg(EAdvisor.Military, "MilitaryAdvisorAccepance", "dragonnokillretreat", 600f),
		new AdvisorMsg(EAdvisor.Military, "MilitaryAdvisorNo", "dragonwarn", 600f)
	};

	private int LQA_TextCycler;

	private float foodLowTime;

	private float houseAdviseTime;

	private Timer updateLogTimer = new Timer(3f);

	public GraphicalResourceStack woodStack;

	public GraphicalResourceStack stoneStack;

	public GraphicalResourceStack foodStack;

	public GraphicalResourceStack appleStack;

	public float test;

	public bool DoesStoreResource(int r)
	{
		return AcceptsType(r);
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public bool CanCreateSettlers()
	{
		return false;
	}

	string IOutputInfo.GetError()
	{
		return null;
	}

	public void Awake()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
		issueButton = UnityEngine.Object.Instantiate(issuePrefab);
		issueButton.transform.SetParent(transform);
		issueButton.transform.localPosition = new Vector3(1.5f, 2.5f, 1.5f);
		issueButton.gameObject.SetActive(value: false);
		issueButton.onClick = () =>
		{
			Building component = GetComponent<Building>();
			GameUI.inst.SetSelectedBuildingNew(component);
			AdvisorUI.inst.Show();
			Cam.inst.SetDesiredTrackingPos(component.transform.position + component.size.xz() * 0.5f);
			component = null;
			issueButton.gameObject.SetActive(value: false);
		};
	}

	public void OnShutdown()
	{
		UnityEngine.Object.Destroy(issueButton.gameObject);
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Remove(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
		if (healthBar != null)
		{
			UnityEngine.Object.Destroy(healthBar.gameObject);
		}
	}

	public Vector3 GetPositionForPerson(Villager p)
	{
		return b.personPositions[0].position;
	}

	public bool Open()
	{
		return true;
	}

	public int GetHappiness()
	{
		return 100;
	}

	private void OnBuildingPlacement(bool undo)
	{
		b.ConstructionForeman.AddBuildResource(b.GetCost(b.LandMass()));
		World.inst.HideResourceTooltipUIs();
		healthBar = UnityEngine.Object.Instantiate(Player.inst.healthBarPrefab);
		healthBar.SetPos(b.Center() + new Vector3(0f, 2f, 0f));
		healthBar.gameObject.SetActive(value: true);
		healthBar.maxTimeShowing = 25f;
		IEnumerable<Cloth> enumerable = Util.ComponentsInNodeAndAllDescendants<Cloth>(gameObject);
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(b.TeamID());
		foreach (Cloth item in enumerable)
		{
			item.GetComponent<SkinnedMeshRenderer>().material.mainTexture = landmassOwnerByTeamId.BannerTexture;
		}
		Player inst = Player.inst;
		inst.updateBanner = (Player.UpdateBanner)Delegate.Combine(inst.updateBanner, new Player.UpdateBanner(UpdateBanners));
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		PlacementValidationResult result = PlacementValidationResult.Valid;
		b.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			if (seedShip != null)
			{
				int num = placementRadius * placementRadius;
				Vector3 vector = World.inst.SnapToGrid2D(seedShip.GetPos());
				if (((float)cell.x + 0.5f - vector.x) * ((float)cell.x + 0.5f - vector.x) + ((float)cell.z + 0.5f - vector.z) * ((float)cell.z + 0.5f - vector.z) > (float)num)
				{
					result = PlacementValidationResult.OutpostTooFarFromSeedShip;
				}
			}
		});
		if (result != PlacementValidationResult.Valid)
		{
			validationResult = result;
		}
	}

	public void UpdateBanners()
	{
		if (b.TeamID() != 0)
		{
			return;
		}
		foreach (Cloth item in Util.ComponentsInNodeAndAllDescendants<Cloth>(gameObject))
		{
			item.GetComponent<SkinnedMeshRenderer>().material.mainTexture = Player.inst.PlayerLandmassOwner.BannerTexture;
		}
	}

	private void OnInit()
	{
		string[] array = new string[3] { "AgricultureAdvisorAcceptance", "CityAdvisorAcceptance", "MilitaryAdvisorAccepance" };
		for (int i = 0; i < 3; i++)
		{
			AdvisorUI.SetAdvisorMessage(i, "ScriptLocalization.AdvisorGoodDaySire", array[i], "neutral_happy");
		}
	}

	public void OnDemolished()
	{
		if (Player.inst.difficulty == Player.Difficulty.Survival && Player.inst.keep == this)
		{
			GameState.inst.SetNewMode(GameState.inst.mainMenuMode);
			GameState.inst.mainMenuMode.TransitionTo(MainMenuMode.State.KeepDestroyed);
			TimeManager.inst.SetPaused(skipSfx: true);
		}
	}

	public void AdviseVikings()
	{
		if (!Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("archer", mustBeBuilt: false))
		{
			SetAdvisorMessage("vikingwarning1");
		}
		else
		{
			SetAdvisorMessage("vikingwarning2");
		}
	}

	public void SetAdvisorMessage(string tag, string anim = null)
	{
		if (!b.IsPlayerBuilding() || !Settings.inst.AdvisorNotifications)
		{
			return;
		}
		for (int i = 0; i < advisorMessages.Length; i++)
		{
			if (!(tag == advisorMessages[i].tag))
			{
				continue;
			}
			AdvisorMsg advisorMsg = advisorMessages[i];
			if (advisorMsg.timeSinceLastHeard > advisorMsg.timeToWaitFromLast)
			{
				advisorMsg.timeSinceLastHeard = 0f;
				AdvisorUI.SetAdvisorMessage((int)advisorMsg.advisor, LocalizationManager.GetTranslation(tag), advisorMsg.sound, anim);
				if (!AdvisorUI.inst.gameObject.activeSelf)
				{
					issueButton.gameObject.SetActive(value: true);
				}
			}
			break;
		}
	}

	private void OnPlayerPlacement()
	{
		if (World.inst.inFirstPlacementPhase)
		{
			b.ForEachTileInBounds((int x, int z, Cell cell) =>
			{
				cell.ClearCell();
			});
			Player.inst.LandMassNames[b.LandMass()] = TownNameUI.inst.townName;
			World.inst.HideResourceTooltipUIs();
			SeasonManager.inst.CancelHold();
			NotificationUI.TryLog(-1, "year", string.Format(ScriptLocalization.LogGameUIYear, SeasonManager.inst.CurrentYear()), NotificationStatus.Neutral, 0f, null, title: true);
			MilestoneManager.inst.TryFirstOutpostMilestone();
			MusicSystem.inst.StartSettleLandMusic();
			int num = 15;
			for (int num2 = 0; num2 < num; num2++)
			{
				Villager villager = Villager.CreateVillager();
				Player.inst.Workers.Add(villager);
				Player.inst.Homeless.Add(villager);
				villager.TeleportTo(b.Center());
			}
		}
		Cam.inst.SetDesiredTrackingPos(b.Center());
		if (Cam.inst.desiredDist > 25f)
		{
			Cam.inst.desiredDist = 25f;
		}
		NotificationUI.NotificationMessage message = new NotificationUI.NotificationMessage
		{
			single = ScriptLocalization.new_town_established
		};
		NotificationUI.TryNotify(NotificationUI.GeneralGroup, -1, "intro", message);
	}

	private void OnBuilt()
	{
		SetAdvisorMessage("houseneed0");
		SetAdvisorMessage("farmneed0");
	}

	private void Update()
	{
		float deltaTime = Time.deltaTime;
		for (int i = 0; i < advisorMessages.Length; i++)
		{
			advisorMessages[i].timeSinceLastHeard += deltaTime;
		}
		if (!Settings.inst.AdvisorNotifications)
		{
			issueButton.gameObject.SetActive(value: false);
		}
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.WorkersForFullYield; i++)
		{
			if (!b.VerifyJobIs(i, typeof(FreeResourceGathererJob)))
			{
				b.SetAndAddJob(i, new FreeResourceGathererJob(b));
			}
			(b.jobs[i] as FreeResourceGathererJob).filterPrimary = JobFilter;
			(b.jobs[i] as FreeResourceGathererJob).consumer = false;
			b.jobInitIdx++;
		}
	}

	private void OnFinishedLoad()
	{
		if (string.IsNullOrEmpty(Player.inst.LandMassNames[b.LandMass()]))
		{
			Player.inst.LandMassNames[b.LandMass()] = TownNameUI.inst.townName;
		}
	}

	private bool JobFilter(IResourceProvider x, int type)
	{
		if (x.GetType() != typeof(Stockpile) && x.GetType() != typeof(Keep) && x.GetType() != typeof(Market) && x.GetType() != typeof(Baker))
		{
			return x.GetType() != typeof(Mason);
		}
		return false;
	}

	public bool AcceptsType(int t)
	{
		if (t != 0 && t != 2 && t != 1)
		{
			return t == 9;
		}
		return true;
	}

	public bool StoresTypePublic(int t)
	{
		return AcceptsType(t);
	}

	public void Deposit(ref ResourceAmount resources)
	{
		int num = 0;
		if (resources.Get(0) > 0)
		{
			num = foodStack.Add(resources.Get(0));
			resources.Add(0, -num);
		}
		if (resources.Get(9) > 0)
		{
			num = appleStack.Add(resources.Get(9));
			resources.Add(9, -num);
		}
		if (resources.Get(2) > 0)
		{
			num = stoneStack.Add(resources.Get(2));
			resources.Add(2, -num);
		}
		if (resources.Get(1) > 0)
		{
			num = woodStack.Add(resources.Get(1));
			resources.Add(1, -num);
		}
	}

	void IResourceStorage.RemoveResources(ResourceAmount amount)
	{
		foodStack.Remove(amount.Get(0));
		appleStack.Remove(amount.Get(9));
		stoneStack.Remove(amount.Get(2));
		woodStack.Remove(amount.Get(1));
	}

	int IResourceStorage.MaxStorageFor(int t)
	{
		return t switch
		{
			0 => foodStack.MaxCapacity(), 
			9 => appleStack.MaxCapacity(), 
			2 => stoneStack.MaxCapacity(), 
			1 => woodStack.MaxCapacity(), 
			_ => 0, 
		};
	}

	public int SpaceAvailable(int resourceID)
	{
		return resourceID switch
		{
			0 => foodStack.MaxCapacity() - foodStack.Count(), 
			9 => appleStack.MaxCapacity() - appleStack.Count(), 
			2 => stoneStack.MaxCapacity() - stoneStack.Count(), 
			1 => woodStack.MaxCapacity() - woodStack.Count(), 
			_ => 0, 
		};
	}

	int IResourceStorage.StoredPublicResources(int rID)
	{
		return rID switch
		{
			0 => foodStack.AvailableAmount(), 
			9 => appleStack.AvailableAmount(), 
			2 => stoneStack.AvailableAmount(), 
			1 => woodStack.AvailableAmount(), 
			_ => 0, 
		};
	}

	public Vector3 DropOffLocation(int type)
	{
		switch (type)
		{
		case 2:
			return stoneStack.ResourcePosition(type);
		case 1:
			return woodStack.ResourcePosition(type);
		case 0:
		case 9:
			return transform.GetChild(0).Find("resourceDropoff").transform.position;
		default:
			return transform.position;
		}
	}

	public int LandMass()
	{
		return b.GetCell().landMassIdx;
	}

	void IResourceProviderContainer.AddResourceProvider()
	{
		stoneStack.owner = b;
		woodStack.owner = b;
		appleStack.owner = b;
		foodStack.owner = b;
		stoneStack.validToPickupToStoreElsewhere = false;
		woodStack.validToPickupToStoreElsewhere = false;
		appleStack.validToPickupToStoreElsewhere = false;
		foodStack.validToPickupToStoreElsewhere = false;
		FreeResourceManager.inst.AddResourceProviderChecked(stoneStack);
		FreeResourceManager.inst.AddResourceProviderChecked(woodStack);
		FreeResourceManager.inst.AddResourceProviderChecked(appleStack);
		FreeResourceManager.inst.AddResourceProviderChecked(foodStack);
	}

	void IResourceProviderContainer.RemoveResourceProvider()
	{
		FreeResourceManager.inst.RemoveResourceProvider(stoneStack);
		FreeResourceManager.inst.RemoveResourceProvider(woodStack);
		FreeResourceManager.inst.RemoveResourceProvider(appleStack);
		FreeResourceManager.inst.RemoveResourceProvider(foodStack);
	}
}
