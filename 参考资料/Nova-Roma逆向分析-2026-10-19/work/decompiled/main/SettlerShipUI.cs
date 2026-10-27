using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SettlerShipUI : MonoBehaviour
{
	public static SettlerShipUI inst;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	private TextMeshProUGUI statusTMP;

	[SerializeField]
	private TextMeshProUGUI settlerTMP;

	[SerializeField]
	private TextMeshProUGUI descriptionTMP;

	[SerializeField]
	private Button exitBtn;

	private bool isVisible;

	private SettlerShip targetShip;

	public bool IsVisible()
	{
		return isVisible;
	}

	private void Awake()
	{
		inst = this;
		exitBtn.onClick.AddListener(() =>
		{
			SetVisibility(v: false);
		});
		SetVisibility(v: false);
	}

	public void SetVisibility(bool v)
	{
		Util.SetEnabled(canvas, v);
		gRaycaster.enabled = v;
		enabled = v;
		if (isVisible != v)
		{
			if (v)
			{
				SfxSystem.PlayUiOpen();
			}
			else
			{
				GameUI.inst.RemoveFromSelection(targetShip);
				Cam.inst.ClearTrack();
			}
		}
		isVisible = v;
	}

	public void Select(SettlerShip sShip)
	{
		targetShip = sShip;
		UpdateStatusText(sShip);
		SetVisibility(v: true);
	}

	private void Update()
	{
		UpdateStatusText(targetShip);
	}

	private void UpdateStatusText(SettlerShip sShip)
	{
		if (sShip == null)
		{
			return;
		}
		switch (sShip.status)
		{
		case 1:
		{
			int num = sShip.GetSettlerCount() - sShip.GetSettledCount();
			if (num > 0)
			{
				statusTMP.text = string.Format(ScriptLocalization.settlershipui_unloading_heading, num);
			}
			else
			{
				statusTMP.text = string.Format(ScriptLocalization.settlershipui_departing_heading, Player.inst.LandMassNames[sShip.GetTargetLandmass()]);
			}
			break;
		}
		case 0:
			statusTMP.text = string.Format(ScriptLocalization.settlershipui_sailingto_heading, Player.inst.LandMassNames[sShip.GetTargetLandmass()]);
			break;
		case 2:
			statusTMP.text = string.Format(ScriptLocalization.settlershipui_departing_heading, Player.inst.LandMassNames[sShip.GetTargetLandmass()]);
			break;
		}
		if (sShip.status == 2)
		{
			descriptionTMP.text = "";
		}
		else
		{
			descriptionTMP.text = string.Format(ScriptLocalization.settlershipui_description, sShip.GetSettlerProspectCount() - sShip.GetSettledCount());
		}
	}
}
