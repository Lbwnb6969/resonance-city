using UnityEngine;
using UnityEngine.UI;

public class ModButtonMainMenu : MonoBehaviour
{
	public Button button;

	public void Start()
	{
		button.gameObject.SetActive(KCModHelper.ModLoader.localModsLoadedAtStartup.Count > 0);
		button.gameObject.SetActive(SteamManager.Initialized);
	}
}
