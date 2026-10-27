using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class RegionNameUI : MonoBehaviour
{
	public TMP_InputField regionNameInput;

	public Button editButton;

	private bool deferredDisableInteractable;

	private int lastFocusedLandMass = -1;

	private bool lastframeBuildingsOnLandMass;

	private void Awake()
	{
		editButton.onClick.AddListener(() =>
		{
			regionNameInput.interactable = !regionNameInput.interactable;
			if (regionNameInput.interactable)
			{
				regionNameInput.ActivateInputField();
			}
			else
			{
				regionNameInput.DeactivateInputField();
			}
		});
		regionNameInput.onSelect.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = false;
			regionNameInput.text = Player.inst.GetFocusedLandMassName();
		});
		regionNameInput.onEndEdit.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = true;
			Player.inst.SetFocusedLandMassName(val.Trim());
			if (string.IsNullOrEmpty(val.Trim()) || val == ScriptLocalization.PopulationUIUnnamedRegion)
			{
				val = ScriptLocalization.PopulationUIUnnamedRegion;
			}
			regionNameInput.text = val;
			deferredDisableInteractable = true;
			TownNameUI.inst.SetTownNameQuiet(val);
		});
	}

	private void Update()
	{
		bool flag = false;
		if (lastFocusedLandMass != Player.inst.FocusedLandMass)
		{
			lastFocusedLandMass = Player.inst.FocusedLandMass;
			flag = true;
		}
		bool flag2 = Player.inst.AnyBuildingsOnLandMass(Player.inst.FocusedLandMass);
		if (lastframeBuildingsOnLandMass != flag2)
		{
			lastframeBuildingsOnLandMass = flag2;
			flag = true;
		}
		if (flag)
		{
			RefreshRegionName();
		}
		if (deferredDisableInteractable)
		{
			regionNameInput.interactable = false;
			deferredDisableInteractable = false;
		}
		bool active = World.GetLandmassOwner(Player.inst.FocusedLandMass) == Player.inst.PlayerLandmassOwner;
		editButton.gameObject.SetActive(active);
	}

	public void RefreshRegionName()
	{
		if (Player.inst.AnyBuildingsOnLandMass(Player.inst.FocusedLandMass) || Player.inst.FocusedLandMass == -1)
		{
			string text = Player.inst.GetFocusedLandMassName();
			if (string.IsNullOrEmpty(text))
			{
				text = ScriptLocalization.PopulationUIUnnamedRegion;
			}
			regionNameInput.text = text;
		}
		else
		{
			regionNameInput.interactable = false;
			if (Player.inst.keep == null)
			{
				regionNameInput.text = "ScriptLocalization.PopulationUIBuildaKeep";
			}
			else
			{
				regionNameInput.text = "ScriptLocalization.PopulationUIBuildAnOutput";
			}
		}
	}
}
