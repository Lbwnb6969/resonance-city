using UnityEngine;

public class BannerSwatch : MonoBehaviour
{
	private ChooseBannerUI reference;

	public void GiveBannerUIRef(ChooseBannerUI reference)
	{
		this.reference = reference;
	}

	public void SelectSwatch()
	{
		SfxSystem.PlayUiSelect();
		reference.HighlightBannerSwatch(this);
	}
}
