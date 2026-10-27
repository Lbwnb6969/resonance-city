using System.Text;
using TMPro;
using UnityEngine.UI;

public class ToolInfo : InfoBase
{
	public static ToolInfo inst;

	public Toggle foresterToggle;

	public Toggle quarryToggle;

	public Toggle mineToggle;

	public Toggle fishmongerToggle;

	public Toggle butcherToggle;

	private StringBuilder builder = new StringBuilder(500);

	public TextMeshProUGUI Text;

	private void Awake()
	{
		inst = this;
		clicked += SetTogglesFromPlayerData;
	}

	public void SetTogglesFromPlayerData()
	{
		foresterToggle.isOn = Player.inst.CanUseTool(Player.ToolUser.Forester);
		quarryToggle.isOn = Player.inst.CanUseTool(Player.ToolUser.Quarry);
		mineToggle.isOn = Player.inst.CanUseTool(Player.ToolUser.IronMine);
		fishmongerToggle.isOn = Player.inst.CanUseTool(Player.ToolUser.FishMonger);
		butcherToggle.isOn = Player.inst.CanUseTool(Player.ToolUser.Butcher);
	}

	public void ToggleFishmongers()
	{
		Player.inst.SetUseTool(Player.ToolUser.FishMonger, fishmongerToggle.isOn);
		timer.ForceExpire();
		SfxSystem.PlayUiSelect();
	}

	public void ToggleButchers()
	{
		Player.inst.SetUseTool(Player.ToolUser.Butcher, butcherToggle.isOn);
		timer.ForceExpire();
		SfxSystem.PlayUiSelect();
	}

	public void ToggleForesters()
	{
		Player.inst.SetUseTool(Player.ToolUser.Forester, foresterToggle.isOn);
		timer.ForceExpire();
		SfxSystem.PlayUiSelect();
	}

	public void ToggleQuarries()
	{
		Player.inst.SetUseTool(Player.ToolUser.Quarry, quarryToggle.isOn);
		timer.ForceExpire();
		SfxSystem.PlayUiSelect();
	}

	public void ToggleMines()
	{
		Player.inst.SetUseTool(Player.ToolUser.IronMine, mineToggle.isOn);
		timer.ForceExpire();
		SfxSystem.PlayUiSelect();
	}

	private void Update()
	{
	}
}
