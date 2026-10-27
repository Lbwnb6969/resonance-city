using System;
using UnityEngine;

public class DiplomacyNotificationUI : MonoBehaviour
{
	public DiplomacyNotificationItem[] bannerItems;

	private int focusIdx;

	private bool registerEvent = true;

	private void Inst_OnUnitRemoved(IMoveableUnit u)
	{
		CloseBanner(u.TeamID());
	}

	private void Start()
	{
		GamepadControl inst = GamepadControl.inst;
		inst.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(inst.controllerUpdate, new GamepadControl.ControllerActivity(ControllerUpdate));
	}

	private void ControllerUpdate(bool isControllerActive)
	{
		for (int i = 0; i < bannerItems.Length; i++)
		{
			DiplomacyNotificationItem obj = bannerItems[i];
			obj.consoleLeftStickImage.gameObject.SetActive(isControllerActive);
			obj.notificationButton.gameObject.SetActive(!isControllerActive);
		}
	}

	internal void NotifyArrived(Envoy envoy)
	{
		int num = envoy.TeamID();
		if (num - 2 >= 0)
		{
			DiplomacyNotificationItem obj = bannerItems[num - 2];
			obj.targetEnvoy = envoy;
			obj.statusTxt.text = "I2.Loc.ScriptLocalization.DiplomatArrived";
			LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(num);
			obj.bannerImage.texture = landmassOwnerByTeamId.BannerTexture;
			obj.notificationBackground.color = World.inst.liverySets[landmassOwnerByTeamId.bannerIdx].bannerColor;
			obj.gameObject.SetActive(value: true);
			MiniMapUI.inst.SetupEnvoyExclamation(envoy.general.transform.position, num);
		}
	}

	internal void NotifyEnroute(Envoy envoy)
	{
		if (registerEvent)
		{
			OrdersManager.inst.OnUnitRemoved += Inst_OnUnitRemoved;
			registerEvent = false;
		}
		int num = envoy.TeamID();
		if (num - 2 >= 0)
		{
			DiplomacyNotificationItem obj = bannerItems[num - 2];
			obj.targetEnvoy = envoy;
			obj.statusTxt.text = "I2.Loc.ScriptLocalization.DiplomatOnTheWay";
			LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(num);
			obj.bannerImage.texture = landmassOwnerByTeamId.BannerTexture;
			obj.notificationBackground.color = World.inst.liverySets[landmassOwnerByTeamId.bannerIdx].bannerColor;
			obj.gameObject.SetActive(value: true);
		}
	}

	internal void CloseBanner(int teamId)
	{
		if (teamId - 2 >= 0)
		{
			DiplomacyNotificationItem diplomacyNotificationItem = bannerItems[teamId - 2];
			if (!GameState.IsQuitting)
			{
				diplomacyNotificationItem.gameObject.SetActive(value: false);
				MiniMapUI.inst.RemoveEnvoyExclamation(teamId);
				CheckForAnotherEnvoy();
			}
		}
	}

	private void CheckForAnotherEnvoy()
	{
		for (int i = 0; i < bannerItems.Length; i++)
		{
			DiplomacyNotificationItem diplomacyNotificationItem = bannerItems[i];
			if (diplomacyNotificationItem.gameObject.activeSelf && diplomacyNotificationItem.targetEnvoy != null)
			{
				MiniMapUI.inst.SetupEnvoyExclamation(diplomacyNotificationItem.targetEnvoy.general.transform.position, diplomacyNotificationItem.targetEnvoy.TeamID());
				break;
			}
		}
	}

	internal void CloseAllBanners()
	{
		for (int i = 0; i < bannerItems.Length; i++)
		{
			bannerItems[i].gameObject.SetActive(value: false);
			if ((bool)MiniMapUI.inst && (bool)bannerItems[i].targetEnvoy)
			{
				MiniMapUI.inst.RemoveEnvoyExclamation(bannerItems[i].targetEnvoy.TeamID());
			}
		}
	}

	internal bool IsNotificationActive()
	{
		for (int i = 0; i < bannerItems.Length; i++)
		{
			if (bannerItems[i].gameObject.activeSelf)
			{
				return true;
			}
		}
		return false;
	}

	internal void FocusNextBanner()
	{
		for (int i = 1; i <= bannerItems.Length; i++)
		{
			int num = (focusIdx + i) % bannerItems.Length;
			if (bannerItems[num].gameObject.activeSelf)
			{
				bannerItems[num].OnNotificationViewedButton();
				focusIdx = num;
				break;
			}
		}
	}
}
