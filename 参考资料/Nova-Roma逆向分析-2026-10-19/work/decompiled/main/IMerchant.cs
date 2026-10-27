using Assets.Code;
using UnityEngine;

public interface IMerchant
{
	Dock GetCurrentDock();

	void RemoveFromHold(ResourceAmount amt);

	void AddToHold(ResourceAmount amt);

	ResourceAmount GetBuyFromPrice();

	ResourceAmount GetSellToPrice();

	ResourceAmount GetHold();

	int TeamID();

	Vector3 GetPos();

	Player.UpgradeType GetSpecialUpgrade();

	bool GetPathFailed();

	bool IsWaiting();
}
