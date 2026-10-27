using PixelCrushers.DialogueSystem;
using UnityEngine;

public class ConvoLuaFunctions : MonoBehaviour
{
	private void OnEnable()
	{
		Lua.RegisterFunction("IsDemo", this, SymbolExtensions.GetMethodInfo(() => IsDemo()));
		Lua.RegisterFunction("IsDedicatedTo", this, SymbolExtensions.GetMethodInfo(() => IsDedicatedTo(string.Empty)));
		Lua.RegisterFunction("HasShrineOfAsclepius", this, SymbolExtensions.GetMethodInfo(() => HasShrineOfAsclepius()));
		Lua.RegisterFunction("AcceptNewTask", this, SymbolExtensions.GetMethodInfo(() => AcceptNewTask()));
		Lua.RegisterFunction("ShowFavorPointsGained", this, SymbolExtensions.GetMethodInfo(() => ShowFavorPointsGained()));
		Lua.RegisterFunction("FirstSmallTemple", this, SymbolExtensions.GetMethodInfo(() => FirstSmallTemple(string.Empty)));
		Lua.RegisterFunction("FirstMediumTemple", this, SymbolExtensions.GetMethodInfo(() => FirstMediumTemple(string.Empty)));
		Lua.RegisterFunction("CanAppeaseWithOffering", this, SymbolExtensions.GetMethodInfo(() => CanAppeaseWithOffering()));
		Lua.RegisterFunction("AppeaseWithOffering", this, SymbolExtensions.GetMethodInfo(() => AppeaseWithOffering()));
		Lua.RegisterFunction("CancelAppease", this, SymbolExtensions.GetMethodInfo(() => CancelAppease()));
		Lua.RegisterFunction("WasGodAngry", this, SymbolExtensions.GetMethodInfo(() => WasGodAngry()));
		Lua.RegisterFunction("AcceptMission", this, SymbolExtensions.GetMethodInfo(() => AcceptMission()));
		Lua.RegisterFunction("CancelMission", this, SymbolExtensions.GetMethodInfo(() => CancelMission()));
		Lua.RegisterFunction("GetAudienceEndAmount", this, SymbolExtensions.GetMethodInfo(() => GetAudienceEndAmount()));
		Lua.RegisterFunction("ChangeMood", this, SymbolExtensions.GetMethodInfo(() => ChangeMood(string.Empty)));
		Lua.RegisterFunction("StartRulerMessage", this, SymbolExtensions.GetMethodInfo(() => StartRulerMessage()));
		Lua.RegisterFunction("ModifyStanding", this, SymbolExtensions.GetMethodInfo(() => ModifyStanding(0f)));
		Lua.RegisterFunction("GetStanding", this, SymbolExtensions.GetMethodInfo(() => GetStanding()));
		Lua.RegisterFunction("DeclareWar", this, SymbolExtensions.GetMethodInfo(() => DeclareWar()));
		Lua.RegisterFunction("EndWar", this, SymbolExtensions.GetMethodInfo(() => EndWar()));
		Lua.RegisterFunction("GrantControlToPlayer", this, SymbolExtensions.GetMethodInfo(() => GrantControlToPlayer()));
		Lua.RegisterFunction("RebuildKeep", this, SymbolExtensions.GetMethodInfo(() => RebuildKeep()));
		Lua.RegisterFunction("HidePortrait", this, SymbolExtensions.GetMethodInfo(() => HidePortrait()));
		Lua.RegisterFunction("ShowPortrait", this, SymbolExtensions.GetMethodInfo(() => ShowPortrait()));
		Lua.RegisterFunction("HideDiplomacyUI", this, SymbolExtensions.GetMethodInfo(() => HideDiplomacyUI()));
		Lua.RegisterFunction("HideGodUI", this, SymbolExtensions.GetMethodInfo(() => HideGodUI()));
		Lua.RegisterFunction("IsMissionNotStarted", this, SymbolExtensions.GetMethodInfo(() => IsMissionNotStarted()));
		Lua.RegisterFunction("IsMissionInProgress", this, SymbolExtensions.GetMethodInfo(() => IsMissionInProgress()));
		Lua.RegisterFunction("IsMissionComplete", this, SymbolExtensions.GetMethodInfo(() => IsMissionComplete()));
		Lua.RegisterFunction("IsMissionFailed", this, SymbolExtensions.GetMethodInfo(() => IsMissionFailed()));
		Lua.RegisterFunction("ShowMissionUI", this, SymbolExtensions.GetMethodInfo(() => ShowMissionUI()));
		Lua.RegisterFunction("StartMissionConvo", this, SymbolExtensions.GetMethodInfo(() => StartMissionConvo()));
		Lua.RegisterFunction("HasAlliance", this, SymbolExtensions.GetMethodInfo(() => HasAlliance()));
		Lua.RegisterFunction("MakeAlliance", this, SymbolExtensions.GetMethodInfo(() => MakeAlliance()));
		Lua.RegisterFunction("BreakAlliance", this, SymbolExtensions.GetMethodInfo(() => BreakAlliance()));
		Lua.RegisterFunction("GetGiftReaction", this, SymbolExtensions.GetMethodInfo(() => GetGiftReaction()));
		Lua.RegisterFunction("GiveGift", this, SymbolExtensions.GetMethodInfo(() => GiveGift()));
		Lua.RegisterFunction("GiveGiftToPlayer", this, SymbolExtensions.GetMethodInfo(() => GiveGiftToPlayer()));
		Lua.RegisterFunction("StartConvo", this, SymbolExtensions.GetMethodInfo(() => StartConvo(string.Empty)));
		Lua.RegisterFunction("StartSubConvo", this, SymbolExtensions.GetMethodInfo(() => StartSubConvo(string.Empty, 0f)));
		Lua.RegisterFunction("ReturnToMenuConvo", this, SymbolExtensions.GetMethodInfo(() => ReturnToMenuConvo()));
		Lua.RegisterFunction("StartChat", this, SymbolExtensions.GetMethodInfo(() => StartChat()));
		Lua.RegisterFunction("IsFavoriteFood", this, SymbolExtensions.GetMethodInfo(() => IsFavoriteFood(string.Empty)));
		Lua.RegisterFunction("HasGift", this, SymbolExtensions.GetMethodInfo(() => HasGift()));
		Lua.RegisterFunction("GiftMissionActive", this, SymbolExtensions.GetMethodInfo(() => GiftMissionActive()));
		Lua.RegisterFunction("DidChat", this, SymbolExtensions.GetMethodInfo(() => DidChat()));
		Lua.RegisterFunction("DoPlayerHallOfDiplomacyExist", this, SymbolExtensions.GetMethodInfo(() => DoPlayerHallOfDiplomacyExist()));
		Lua.RegisterFunction("DoAIDocksExist", this, SymbolExtensions.GetMethodInfo(() => DoAIDocksExist()));
		Lua.RegisterFunction("DoPlayerDocksExist", this, SymbolExtensions.GetMethodInfo(() => DoPlayerDocksExist()));
		Lua.RegisterFunction("AttemptOpenDocks", this, SymbolExtensions.GetMethodInfo(() => AttemptOpenDocks()));
		Lua.RegisterFunction("AreDocksOpen", this, SymbolExtensions.GetMethodInfo(() => AreDocksOpen()));
		Lua.RegisterFunction("RefreshMerchantOrders", this, SymbolExtensions.GetMethodInfo(() => RefreshMerchantOrders()));
		Lua.RegisterFunction("CloseDocks", this, SymbolExtensions.GetMethodInfo(() => CloseDocks()));
		Lua.RegisterFunction("LowerPrices", this, SymbolExtensions.GetMethodInfo(() => LowerPrices()));
		Lua.RegisterFunction("CanLowerPrices", this, SymbolExtensions.GetMethodInfo(() => CanLowerPrices()));
		Lua.RegisterFunction("DisplayNegotiationUI", this, SymbolExtensions.GetMethodInfo(() => DisplayNegotiationUI()));
		Lua.RegisterFunction("WasPreviousNegotationsFavorable", this, SymbolExtensions.GetMethodInfo(() => WasPreviousNegotationsFavorable()));
		Lua.RegisterFunction("IsNegotationsFavorable", this, SymbolExtensions.GetMethodInfo(() => IsNegotationsFavorable()));
		Lua.RegisterFunction("UpdateAISellPriceUI", this, SymbolExtensions.GetMethodInfo(() => UpdateAISellPriceUI()));
		Lua.RegisterFunction("ConfirmProposedPrices", this, SymbolExtensions.GetMethodInfo(() => ConfirmProposedPrices()));
		Lua.RegisterFunction("DidRulerMessage", this, SymbolExtensions.GetMethodInfo(() => DidRulerMessage()));
		Lua.RegisterFunction("AllowLibraries", this, SymbolExtensions.GetMethodInfo(() => AllowLibraries()));
		Lua.RegisterFunction("DidDialogAlready", this, SymbolExtensions.GetMethodInfo(() => DidDialogAlready(0f)));
		Lua.RegisterFunction("KickOut", this, SymbolExtensions.GetMethodInfo(() => KickOut()));
		Lua.RegisterFunction("Abdicate", this, SymbolExtensions.GetMethodInfo(() => Abdicate()));
		Lua.RegisterFunction("DeclineAbdicate", this, SymbolExtensions.GetMethodInfo(() => DeclineAbdicate()));
		Lua.RegisterFunction("DidAbdicateConvoAlready", this, SymbolExtensions.GetMethodInfo(() => DidAbdicateConvoAlready()));
		Lua.RegisterFunction("GetHappinessRollingAvg", this, SymbolExtensions.GetMethodInfo(() => GetHappinessRollingAvg()));
		Lua.RegisterFunction("PlayAnim", this, SymbolExtensions.GetMethodInfo(() => PlayAnim(string.Empty)));
		Lua.RegisterFunction("ShowResourceInfoUI", this, SymbolExtensions.GetMethodInfo(() => ShowResourceInfoUI()));
		Lua.RegisterFunction("PayDemandGold", this, SymbolExtensions.GetMethodInfo(() => PayDemandGold()));
		Lua.RegisterFunction("CanPayDemandGold", this, SymbolExtensions.GetMethodInfo(() => CanPayDemandGold()));
		Lua.RegisterFunction("DidFirstGoldDemand", this, SymbolExtensions.GetMethodInfo(() => DidFirstGoldDemand()));
		Lua.RegisterFunction("IsPlayerAnEnemy", this, SymbolExtensions.GetMethodInfo(() => IsPlayerAnEnemy()));
		Lua.RegisterFunction("AITroopsOnPlayerLand", this, SymbolExtensions.GetMethodInfo(() => AITroopsOnPlayerLand()));
		Lua.RegisterFunction("PlayerTroopsOnAILand", this, SymbolExtensions.GetMethodInfo(() => PlayerTroopsOnAILand()));
		Lua.RegisterFunction("GetPersonality", this, SymbolExtensions.GetMethodInfo(() => GetPersonality()));
		Lua.RegisterFunction("IsAIWinning", this, SymbolExtensions.GetMethodInfo(() => IsAIWinning()));
		Lua.RegisterFunction("IsAIBuildingUpTroops", this, SymbolExtensions.GetMethodInfo(() => IsAIBuildingUpTroops()));
		Lua.RegisterFunction("FoughtOffLastWave", this, SymbolExtensions.GetMethodInfo(() => FoughtOffLastWave()));
		Lua.RegisterFunction("GetPlayerHappiness", this, SymbolExtensions.GetMethodInfo(() => GetPlayerHappiness()));
		Lua.RegisterFunction("DeclareWarOnPlayerEnemies", this, SymbolExtensions.GetMethodInfo(() => DeclareWarOnPlayerEnemies()));
		Lua.RegisterFunction("PlayerHasGreatHall", this, SymbolExtensions.GetMethodInfo(() => PlayerHasGreatHall()));
		Lua.RegisterFunction("PayFeast", this, SymbolExtensions.GetMethodInfo(() => PayFeast(string.Empty)));
		Lua.RegisterFunction("CanAffordFeast", this, SymbolExtensions.GetMethodInfo(() => CanAffordFeast(string.Empty)));
		Lua.RegisterFunction("IsLeastFavoriteFood", this, SymbolExtensions.GetMethodInfo(() => IsLeastFavoriteFood(string.Empty)));
		Lua.RegisterFunction("ShowFoodMenu", this, SymbolExtensions.GetMethodInfo(() => ShowFoodMenu()));
		Lua.RegisterFunction("IsFeast", this, SymbolExtensions.GetMethodInfo(() => IsFeast(string.Empty)));
		Lua.RegisterFunction("DoFoodAnim", this, SymbolExtensions.GetMethodInfo(() => DoFoodAnim()));
		Lua.RegisterFunction("IdleWorkerCountAI", this, SymbolExtensions.GetMethodInfo(() => IdleWorkerCountAI()));
		Lua.RegisterFunction("SetImmigrateObjective", this, SymbolExtensions.GetMethodInfo(() => SetImmigrateObjective()));
		Lua.RegisterFunction("DeferDisbandEnvoy", this, SymbolExtensions.GetMethodInfo(() => DeferDisbandEnvoy()));
		Lua.RegisterFunction("HasMoreArcherTowersThanPlayer", this, SymbolExtensions.GetMethodInfo(() => HasMoreArcherTowersThanPlayer()));
		Lua.RegisterFunction("IsPlayerAtPeace", this, SymbolExtensions.GetMethodInfo(() => IsPlayerAtPeace()));
		Lua.RegisterFunction("GetDenyPeaceAmount", this, SymbolExtensions.GetMethodInfo(() => GetDenyPeaceAmount()));
		Lua.RegisterFunction("DenyPeace", this, SymbolExtensions.GetMethodInfo(() => DenyPeace()));
		Lua.RegisterFunction("NeedResource", this, SymbolExtensions.GetMethodInfo(() => NeedResource()));
		Lua.RegisterFunction("PlayerHasNoMerchants", this, SymbolExtensions.GetMethodInfo(() => PlayerHasNoMerchants()));
		Lua.RegisterFunction("DoEventSickDiplomat", this, SymbolExtensions.GetMethodInfo(() => DoEventSickDiplomat(0f)));
		Lua.RegisterFunction("DestroyAllBuildingsForPlayer", this, SymbolExtensions.GetMethodInfo(() => DestroyAllBuildingsForPlayer(string.Empty)));
		Lua.RegisterFunction("PlayerHasBuilding", this, SymbolExtensions.GetMethodInfo(() => PlayerHasBuilding(string.Empty)));
		Lua.RegisterFunction("DoEventTavern", this, SymbolExtensions.GetMethodInfo(() => DoEventTavern()));
		Lua.RegisterFunction("DoEventJoustingMatch", this, SymbolExtensions.GetMethodInfo(() => DoEventJoustingMatch(0f)));
		Lua.RegisterFunction("ShouldSurrender", this, SymbolExtensions.GetMethodInfo(() => ShouldSurrender()));
		Lua.RegisterFunction("PlayerNeedsToCallTroopsHome", this, SymbolExtensions.GetMethodInfo(() => PlayerNeedsToCallTroopsHome()));
		Lua.RegisterFunction("RemoveTroopCount", this, SymbolExtensions.GetMethodInfo(() => RemoveTroopCount()));
		Lua.RegisterFunction("PlayerHasEnemies", this, SymbolExtensions.GetMethodInfo(() => PlayerHasEnemies()));
		Lua.RegisterFunction("DidEnemyWarning", this, SymbolExtensions.GetMethodInfo(() => DidEnemyWarning()));
		Lua.RegisterFunction("DoEnemyWarning", this, SymbolExtensions.GetMethodInfo(() => DoEnemyWarning()));
	}

	private bool IsDemo()
	{
		return World.inst.demoMode;
	}

	private void OnDisable()
	{
	}

	private bool CanAppeaseWithOffering()
	{
		return GodManager.inst.CanAppeaseWithOffering();
	}

	private void AppeaseWithOffering()
	{
		GodManager.inst.AppeaseWithOffering();
	}

	private void CancelAppease()
	{
		GodManager.inst.CancelAppease();
	}

	private bool WasGodAngry()
	{
		return GodUI.inst.WasGodAngry();
	}

	private bool FirstTemple(string name, int templeHash)
	{
		int dedicationIdx = GameUI.inst.godUI.GetDedicationIdx();
		if (!Player.inst.PlayerLandmassOwner.didTempleBonus[dedicationIdx].Contains(templeHash) && templeHash == GameUI.inst.godUI.temple.uniqueNameHash && GodManager.GodNameToIdx(name) == dedicationIdx)
		{
			Player.inst.PlayerLandmassOwner.didTempleBonus[dedicationIdx].Add(templeHash);
			return true;
		}
		return false;
	}

	public bool FirstSmallTemple(string name)
	{
		return FirstTemple(name, "temple".GetHashCode());
	}

	public bool FirstMediumTemple(string name)
	{
		return FirstTemple(name, "temple2".GetHashCode());
	}

	public bool IsDedicatedTo(string name)
	{
		int dedicationIdx = GameUI.inst.godUI.GetDedicationIdx();
		if (GodManager.GodNameToIdx(name) == dedicationIdx)
		{
			return true;
		}
		return false;
	}

	public bool HasShrineOfAsclepius()
	{
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(World.templeHash);
		for (int i = 0; i < buildingList.Count; i++)
		{
			Temple component = buildingList.data[i].GetComponent<Temple>();
			if (component != null && component.GetDedicateIdx() == 3 && component.bonusLevel > 0)
			{
				return true;
			}
		}
		return false;
	}

	public void ShowFavorPointsGained()
	{
		GameUI.inst.godUI.ShowFavorPointsGained();
	}

	public void AcceptNewTask()
	{
		GameUI.inst.godUI.AcceptNewTask();
	}

	public int GetHappinessRollingAvg()
	{
		return GameUI.inst.diplomacyUI.GetHappinessRollingAvg();
	}

	public void CancelMission()
	{
		GameUI.inst.diplomacyUI.CancelMission();
	}

	public void ChangeMood(string mood)
	{
		GameUI.inst.diplomacyUI.ChangeMood(mood);
	}

	public void StartRulerMessage()
	{
		GameUI.inst.diplomacyUI.StartRulerMessage();
	}

	public void ModifyStanding(float amt)
	{
		GameUI.inst.diplomacyUI.ModifyStanding((int)amt);
	}

	public double GetStanding()
	{
		return GameUI.inst.diplomacyUI.GetStanding();
	}

	public void DeclareWar()
	{
		GameUI.inst.diplomacyUI.DeclareWar();
	}

	public void EndWar()
	{
		GameUI.inst.diplomacyUI.EndWar();
	}

	public void GrantControlToPlayer()
	{
		GameUI.inst.diplomacyUI.GrantControlToPlayer();
	}

	public void RebuildKeep()
	{
		GameUI.inst.diplomacyUI.RebuildKeep();
	}

	public double GetAudienceEndAmount()
	{
		return GameUI.inst.diplomacyUI.GetAudienceEndAmount();
	}

	public bool IsPlayerAnEnemy()
	{
		return GameUI.inst.diplomacyUI.IsPlayerAnEnemy();
	}

	public bool AITroopsOnPlayerLand()
	{
		return GameUI.inst.diplomacyUI.AITroopsOnPlayerLand();
	}

	public bool PlayerTroopsOnAILand()
	{
		return GameUI.inst.diplomacyUI.PlayerTroopsOnAILand();
	}

	public string GetPersonality()
	{
		return GameUI.inst.diplomacyUI.GetPersonality();
	}

	public bool IsAIWinning()
	{
		return GameUI.inst.diplomacyUI.IsAIWinning();
	}

	public bool FoughtOffLastWave()
	{
		return GameUI.inst.diplomacyUI.FoughtOffLastWave();
	}

	public int GetPlayerHappiness()
	{
		return GameUI.inst.diplomacyUI.GetPlayerHappiness();
	}

	public bool IsAIBuildingUpTroops()
	{
		return GameUI.inst.diplomacyUI.IsAIBuildingUpTroops();
	}

	public void DeclareWarOnPlayerEnemies()
	{
		GameUI.inst.diplomacyUI.DeclareWarOnPlayerEnemies();
	}

	public bool IsMissionNotStarted()
	{
		return GameUI.inst.diplomacyUI.IsMissionNotStarted();
	}

	public bool IsMissionInProgress()
	{
		return GameUI.inst.diplomacyUI.IsMissionInProgress();
	}

	public bool IsMissionComplete()
	{
		return GameUI.inst.diplomacyUI.IsMissionComplete();
	}

	public bool IsMissionFailed()
	{
		return GameUI.inst.diplomacyUI.IsMissionFailed();
	}

	public void AcceptMission()
	{
		GameUI.inst.diplomacyUI.AcceptMission();
	}

	public void ShowMissionUI()
	{
		GameUI.inst.diplomacyUI.SetMissionUIVisibility(v: true);
	}

	public void StartMissionConvo()
	{
		GameUI.inst.diplomacyUI.doInquire = true;
	}

	public bool HasAlliance()
	{
		return GameUI.inst.diplomacyUI.HasAlliance();
	}

	public void MakeAlliance()
	{
		GameUI.inst.diplomacyUI.MakeAlliance();
	}

	public void BreakAlliance()
	{
		GameUI.inst.diplomacyUI.BreakAlliance();
	}

	public void HideDiplomacyUI()
	{
		GameUI.inst.diplomacyUI.Hide();
	}

	public void HideGodUI()
	{
		GodUI.inst.Hide();
	}

	public int GetGiftReaction()
	{
		return GameUI.inst.diplomacyUI.GetGiftReaction();
	}

	public void GiveGift()
	{
		GameUI.inst.diplomacyUI.GiveGift();
	}

	public void GiveGiftToPlayer()
	{
		GameUI.inst.diplomacyUI.GiveGiftToPlayer();
	}

	public void StartConvo(string c)
	{
		GameUI.inst.diplomacyUI.StartConvo(c);
	}

	public void StartSubConvo(string c, float returnNode)
	{
		GameUI.inst.diplomacyUI.StartSubConvo(c, (int)returnNode);
	}

	public void ReturnToMenuConvo()
	{
		GameUI.inst.diplomacyUI.ReturnToMenuConvo();
	}

	public bool HasGift()
	{
		return GameUI.inst.diplomacyUI.HasGift();
	}

	public bool GiftMissionActive()
	{
		return GameUI.inst.diplomacyUI.GiftMissionActive();
	}

	public void StartChat()
	{
		GameUI.inst.diplomacyUI.StartChat();
	}

	public bool IsFavoriteFood(string s)
	{
		return GameUI.inst.diplomacyUI.IsFavoriteFood(s);
	}

	public bool DidChat()
	{
		return GameUI.inst.diplomacyUI.DidChat();
	}

	public bool DoPlayerHallOfDiplomacyExist()
	{
		return GameUI.inst.diplomacyUI.DoPlayerHallOfDiplomacyExist();
	}

	public bool DoAIDocksExist()
	{
		return GameUI.inst.diplomacyUI.DoAIDocksExist();
	}

	public bool DoPlayerDocksExist()
	{
		return GameUI.inst.diplomacyUI.DoPlayerDocksExist();
	}

	public void AttemptOpenDocks()
	{
		GameUI.inst.diplomacyUI.AttemptOpenDocks();
	}

	public void RefreshMerchantOrders()
	{
		GameUI.inst.diplomacyUI.RefreshMerchantOrders();
	}

	public bool AreDocksOpen()
	{
		return GameUI.inst.diplomacyUI.AreDocksOpen();
	}

	public void CloseDocks()
	{
		GameUI.inst.diplomacyUI.CloseDocks();
	}

	public void LowerPrices()
	{
		GameUI.inst.diplomacyUI.LowerPrices();
	}

	public bool CanLowerPrices()
	{
		return GameUI.inst.diplomacyUI.CanLowerPrices();
	}

	public void DisplayNegotiationUI()
	{
		GameUI.inst.diplomacyUI.DisplayNegotiationUI();
	}

	public bool WasPreviousNegotationsFavorable()
	{
		return GameUI.inst.diplomacyUI.WasPreviousNegotationsFavorable();
	}

	public bool IsNegotationsFavorable()
	{
		return GameUI.inst.diplomacyUI.IsNegotationsFavorable();
	}

	public void UpdateAISellPriceUI()
	{
		GameUI.inst.diplomacyUI.UpdateAISellPriceUI();
	}

	public void ConfirmProposedPrices()
	{
		GameUI.inst.diplomacyUI.ConfirmProposedPrices();
	}

	public bool DidRulerMessage()
	{
		return GameUI.inst.diplomacyUI.DidRulerMessage();
	}

	public void HidePortrait()
	{
		GameUI.inst.diplomacyUI.HidePortrait();
	}

	public void ShowPortrait()
	{
		GameUI.inst.diplomacyUI.ShowPortrait();
	}

	public void AllowLibraries()
	{
		GameUI.inst.diplomacyUI.kingdom.allowLibraries = true;
	}

	public bool DidDialogAlready(float id)
	{
		return GameUI.inst.diplomacyUI.DidDialogNodeAlready((int)id);
	}

	public void KickOut()
	{
		GameUI.inst.diplomacyUI.KickOut();
	}

	public void Abdicate()
	{
		GameUI.inst.diplomacyUI.Abdicate();
	}

	public void DeclineAbdicate()
	{
		GameUI.inst.diplomacyUI.DeclineAbdicate();
	}

	public bool DidAbdicateConvoAlready()
	{
		return GameUI.inst.diplomacyUI.DidAbdicateConvoAlready();
	}

	public void PlayAnim(string name)
	{
		switch (name)
		{
		case "surprise":
			GameUI.inst.diplomacyUI.Surprise();
			break;
		case "sad":
			GameUI.inst.diplomacyUI.Sad();
			break;
		case "upset":
			GameUI.inst.diplomacyUI.Upset();
			break;
		case "mischief":
			GameUI.inst.diplomacyUI.Mischief();
			break;
		case "delight":
			GameUI.inst.diplomacyUI.Delight();
			break;
		case "happy":
			GameUI.inst.diplomacyUI.Happy();
			break;
		case "angry":
			GameUI.inst.diplomacyUI.Angry();
			break;
		case "skeptical":
			GameUI.inst.diplomacyUI.Skeptical();
			break;
		case "scared":
			GameUI.inst.diplomacyUI.Scared();
			break;
		case "intrigued":
			GameUI.inst.diplomacyUI.Intrigued();
			break;
		case "interested":
			GameUI.inst.diplomacyUI.Interested();
			break;
		case "ohwell":
			GameUI.inst.diplomacyUI.OhWell();
			break;
		case "neutral_grumpy":
			GameUI.inst.diplomacyUI.NeutralGrumpy();
			break;
		case "neutral_happy":
			GameUI.inst.diplomacyUI.NeutralHappy();
			break;
		case "lookatside":
			GameUI.inst.diplomacyUI.LookAtSide();
			break;
		default:
			Debug.LogError("missing anim");
			break;
		}
	}

	public void ShowResourceInfoUI()
	{
		GameUI.inst.diplomacyUI.SetResourceInfoUIVisibility(v: true);
	}

	public void PayDemandGold()
	{
		GameUI.inst.diplomacyUI.PayDemandGold();
	}

	public bool CanPayDemandGold()
	{
		return Player.inst.PlayerLandmassOwner.Gold >= GameUI.inst.diplomacyUI.GetGoldDemandAmount();
	}

	public bool DidFirstGoldDemand()
	{
		return GameUI.inst.diplomacyUI.DidFirstGoldDemand();
	}

	public bool PlayerHasGreatHall()
	{
		return GameUI.inst.diplomacyUI.PlayerHasGreatHall();
	}

	public void PayFeast(string feast)
	{
		GameUI.inst.diplomacyUI.PayFeast(feast);
	}

	public bool CanAffordFeast(string feast)
	{
		return GameUI.inst.diplomacyUI.CanAffordFeast(feast);
	}

	public bool IsLeastFavoriteFood(string food)
	{
		return GameUI.inst.diplomacyUI.IsLeastFavoriteFood(food);
	}

	public void ShowFoodMenu()
	{
		GameUI.inst.diplomacyUI.ShowFoodMenu();
	}

	public bool IsFeast(string f)
	{
		return GameUI.inst.diplomacyUI.IsFeast(f);
	}

	public void DoFoodAnim()
	{
		GameUI.inst.diplomacyUI.DoFoodAnim();
	}

	public int IdleWorkerCountAI()
	{
		return GameUI.inst.diplomacyUI.IdleWorkerCountAI();
	}

	public void SetImmigrateObjective()
	{
		GameUI.inst.diplomacyUI.SetImmigrateObjective();
	}

	public void DeferDisbandEnvoy()
	{
		GameUI.inst.diplomacyUI.DeferDisbandEnvoy();
	}

	public bool HasMoreArcherTowersThanPlayer()
	{
		return GameUI.inst.diplomacyUI.HasMoreArcherTowersThanPlayer();
	}

	public bool IsPlayerAtPeace()
	{
		return GameUI.inst.diplomacyUI.IsPlayerAtPeace();
	}

	public int GetDenyPeaceAmount()
	{
		return GameUI.inst.diplomacyUI.GetDenyPeaceAmount();
	}

	public void DenyPeace()
	{
		GameUI.inst.diplomacyUI.DenyPeace();
	}

	public string NeedResource()
	{
		return GameUI.inst.diplomacyUI.NeedResource();
	}

	public bool PlayerHasNoMerchants()
	{
		return GameUI.inst.diplomacyUI.PlayerHasNoMerchants();
	}

	public void DoEventSickDiplomat(float o)
	{
		GameUI.inst.diplomacyUI.DoEventSickDiplomat((int)o);
	}

	public void DestroyAllBuildingsForPlayer(string name)
	{
		GameUI.inst.diplomacyUI.DestroyAllBuildingsForPlayer(name);
	}

	public bool PlayerHasBuilding(string name)
	{
		return Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("hospital", mustBeBuilt: true);
	}

	public void DoEventTavern()
	{
		GameUI.inst.diplomacyUI.DoEventTavern();
	}

	public bool ShouldSurrender()
	{
		return GameUI.inst.diplomacyUI.ShouldSurrender();
	}

	public bool PlayerNeedsToCallTroopsHome()
	{
		return GameUI.inst.diplomacyUI.PlayerNeedsToCallTroopsHome();
	}

	public int RemoveTroopCount()
	{
		return GameUI.inst.diplomacyUI.RemoveTroopCount();
	}

	public bool PlayerHasEnemies()
	{
		return GameUI.inst.diplomacyUI.PlayerHasEnemies();
	}

	public void DoEventJoustingMatch(float o)
	{
		GameUI.inst.diplomacyUI.DoEventJoustingMatch((int)o);
	}

	public bool DidEnemyWarning()
	{
		return GameUI.inst.diplomacyUI.DidEnemyWarning();
	}

	public void DoEnemyWarning()
	{
		GameUI.inst.diplomacyUI.DoEnemyWarning();
	}
}
