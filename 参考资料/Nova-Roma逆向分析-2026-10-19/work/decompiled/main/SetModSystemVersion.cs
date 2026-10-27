using I2.Loc;
using TMPro;
using UnityEngine;

public class SetModSystemVersion : MonoBehaviour
{
	private void Start()
	{
		GetComponent<TextMeshProUGUI>().SetText(LocalizationManager.GetTranslation("ModSystemVersion"), KCModHelper.modVersion);
	}
}
