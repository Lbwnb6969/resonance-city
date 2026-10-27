using UnityEngine;

public class SteamWishlistButton : MonoBehaviour
{
	public void ClickButton()
	{
		Application.OpenURL("steam://openurl/https://store.steampowered.com/app/2426530/Nova_Roma/");
	}
}
