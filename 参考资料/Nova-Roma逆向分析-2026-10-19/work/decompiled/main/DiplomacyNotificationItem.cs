using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class DiplomacyNotificationItem : MonoBehaviour
{
	public Button notificationButton;

	public TextMeshProUGUI statusTxt;

	public RawImage bannerImage;

	public Image notificationBackground;

	public Image consoleLeftStickImage;

	public Envoy targetEnvoy;

	public void OnNotificationViewedButton()
	{
		Cam.inst.Track(targetEnvoy.GetComponent<General>().army);
	}
}
