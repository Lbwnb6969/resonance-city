using UnityEngine;

public class Park : MonoBehaviour, IOutputInfo
{
	private int irrigationBonus;

	public int baseHappiness = 5;

	public MeshFilter flowers;

	public Transform splash;

	string IOutputInfo.GetError()
	{
		return null;
	}

	private void OnEnable()
	{
		GetComponent<RadiusBonus>().happinessFunc = GetHappiness;
	}

	private int GetHappiness()
	{
		return HappinessModifierSystem.inst.GetPositiveHappiness(214) + irrigationBonus;
	}

	private void OnDestroy()
	{
		Player.inst.irrigation.OnReservoirIrrigationUpdated -= Irrigation_OnIrrigationUpdated;
	}

	private void OnInit()
	{
		Player.inst.irrigation.OnReservoirIrrigationUpdated += Irrigation_OnIrrigationUpdated;
	}

	private void OnBuilt()
	{
		RefreshBonuses();
	}

	private void Irrigation_OnIrrigationUpdated()
	{
		RefreshBonuses();
	}

	private void OnFinishedLoad()
	{
		RefreshBonuses();
	}

	private void RefreshBonuses()
	{
		Cell cell = GetComponent<Building>().GetCell();
		irrigationBonus = Mathff.Clamp(cell.IrrigationCoverage, 0, 1);
		if ((bool)flowers)
		{
			flowers.gameObject.SetActive(irrigationBonus > 0);
		}
		if ((bool)splash)
		{
			splash.gameObject.SetActive(irrigationBonus > 0);
		}
	}
}
