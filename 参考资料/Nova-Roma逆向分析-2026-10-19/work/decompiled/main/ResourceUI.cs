using Assets.Code;
using TMPro;
using UnityEngine;

public class ResourceUI : MonoBehaviour
{
	public TextMeshProUGUI woodTextUI;

	public TextMeshProUGUI stoneTextUI;

	public TextMeshProUGUI foodTextUI;

	public TextMeshProUGUI goldTextUI;

	public TextMeshProUGUI charcoalTextUI;

	public TextMeshProUGUI ironTextUI;

	public TextMeshProUGUI toolsTextUI;

	public TextMeshProUGUI armamentTextUI;

	private int lastStone = -1;

	private int lastWood = -1;

	private int lastFood = -1;

	private int lastGold = -1;

	private int lastMaxGold = -1;

	private int lastCharcoal = -1;

	private int lastIron = -1;

	private int lastTools = -1;

	private int lastArmaments = -1;

	private float resourceTextColorRestoreDelay;

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		LandmassOwner landmassOwner = World.GetLandmassOwner(Player.inst.FocusedLandMass);
		ResourceAmount focusedResources = Player.inst.FocusedResources;
		Util.TrySetText(woodTextUI, "{0}", Mathff.Max(0, focusedResources.Get(1)), ref lastWood);
		Util.TrySetText(stoneTextUI, "{0}", Mathff.Max(0, focusedResources.Get(2)), ref lastStone);
		if (landmassOwner != null)
		{
			if (lastGold != landmassOwner.Gold || lastMaxGold != landmassOwner.MaxGoldStorage)
			{
				goldTextUI.SetText("{0}/{1}", Mathff.Max(0, landmassOwner.Gold), landmassOwner.MaxGoldStorage);
			}
			lastGold = landmassOwner.Gold;
			lastMaxGold = landmassOwner.MaxGoldStorage;
		}
		Util.TrySetText(foodTextUI, "{0}", Mathf.Min(Mathff.Max(0, focusedResources.Get(0) + focusedResources.Get(8) + focusedResources.Get(10) + focusedResources.Get(9))), ref lastFood);
		Util.TrySetText(charcoalTextUI, "{0}", Mathff.Max(0, focusedResources.Get(3)), ref lastCharcoal);
		Util.TrySetText(ironTextUI, "{0}", Mathff.Max(0, focusedResources.Get(5)), ref lastIron);
		Util.TrySetText(toolsTextUI, "{0}", Mathff.Max(0, focusedResources.Get(6)), ref lastTools);
		Util.TrySetText(armamentTextUI, "{0}", Mathff.Max(0, focusedResources.Get(7)), ref lastArmaments);
		resourceTextColorRestoreDelay -= unscaledDeltaTime;
		if (resourceTextColorRestoreDelay < 0f && resourceTextColorRestoreDelay > -5f)
		{
			woodTextUI.color = Color.Lerp(woodTextUI.color, Color.white, unscaledDeltaTime * 5f);
			stoneTextUI.color = Color.Lerp(stoneTextUI.color, Color.white, unscaledDeltaTime * 5f);
			foodTextUI.color = Color.Lerp(foodTextUI.color, Color.white, unscaledDeltaTime * 5f);
			goldTextUI.color = Color.Lerp(goldTextUI.color, Color.white, unscaledDeltaTime * 5f);
		}
	}

	public void FlashResourcesUIRed(ResourceAmount R)
	{
		resourceTextColorRestoreDelay = 0.5f;
		Player inst = Player.inst;
		if (inst.FocusedResources.Get(0) < R.Get(0))
		{
			foodTextUI.color = Color.red;
		}
		if (inst.FocusedResources.Get(1) < R.Get(1))
		{
			woodTextUI.color = Color.red;
		}
		if (inst.FocusedResources.Get(2) < R.Get(2))
		{
			stoneTextUI.color = Color.red;
		}
		if (inst.PlayerLandmassOwner.Gold < R.Get(4))
		{
			goldTextUI.color = Color.red;
		}
	}
}
