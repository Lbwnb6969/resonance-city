using UnityEngine;
using UnityEngine.UI;

public class KeepUI : MonoBehaviour, IWorkerUIElement
{
	public RawImage banner;

	public void OnClick()
	{
		GameState.inst.playingMode.OnClickedBannerChange();
		GameState.inst.mainMenuMode.chooseBannerUI.GetComponent<ChooseBannerUI>().Show(GameUI.inst.workerUI.GetComponent<ConsoleUIItem>());
	}

	private void Update()
	{
		if (banner.texture != Player.inst.PlayerLandmassOwner.BannerTexture)
		{
			banner.texture = Player.inst.PlayerLandmassOwner.BannerTexture;
		}
	}

	public void UpdateForNewSelection()
	{
	}

	void IWorkerUIElement.TryShow()
	{
		gameObject.SetActive(CanShow());
	}

	public bool CanShow()
	{
		return GameUI.inst.SelectedBuildingIs(World.keepHash);
	}
}
