using TMPro;
using UnityEngine;

namespace Assets;

public class VersionGetter : MonoBehaviour
{
	public TextMeshProUGUI Text;

	public void Start()
	{
		Text.text = Application.version;
	}

	public void UpdateText()
	{
		if (IntegrationManager.inst != null)
		{
			_ = KCModHelper.ModLoader.localModsLoadedAtStartup.Count;
		}
	}

	private void Update()
	{
		if (gameObject.activeSelf && PhotoMode.IsActive())
		{
			gameObject.SetActive(value: false);
		}
		else if (!gameObject.activeSelf)
		{
			gameObject.SetActive(value: true);
		}
	}
}
