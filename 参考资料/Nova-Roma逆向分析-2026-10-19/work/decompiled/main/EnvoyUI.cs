using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class EnvoyUI : MonoBehaviour
{
	private struct NoteBuilding
	{
		public Building b;

		public ResourceTooltipUI note;
	}

	public ResourceAmountUI giftAmountUI;

	public Button cancelGift;

	public GameObject giveInstructions;

	public GameObject giftParent;

	public GameObject giftHint;

	private bool hadGift;

	private ArmySystem.Army army;

	private Envoy envoy;

	private List<NoteBuilding> notes = new List<NoteBuilding>();

	private bool visible;

	private void Start()
	{
	}

	private void Update()
	{
		if (!(envoy != null))
		{
			return;
		}
		bool flag = !envoy.giftAmount.IsNone();
		giftParent.SetActive(flag);
		giftHint.SetActive(!flag);
		if (!hadGift & flag)
		{
			giftAmountUI.SetResourceAmount(envoy.giftAmount);
		}
		hadGift = flag;
		for (int i = 0; i < notes.Count; i++)
		{
			int teamId = notes[i].b.TeamID();
			AIKingdom kingdomFromTeamId = AIBrainsContainer.inst.GetKingdomFromTeamId(teamId);
			if (kingdomFromTeamId == null)
			{
				notes[i].note.gameObject.SetActive(value: false);
				continue;
			}
			if (kingdomFromTeamId.audienceTimer > 0f)
			{
				notes[i].note.SetText("Busy");
			}
			else
			{
				notes[i].note.SetText("Right Click to Visit");
			}
			notes[i].note.gameObject.SetActive(notes[i].b.IsVisibleForFog());
		}
	}

	internal void SetSelectedArmy(ArmySystem.Army a)
	{
		army = a;
		envoy = army.general.GetComponent<Envoy>();
		hadGift = !envoy.giftAmount.IsNone();
		giftAmountUI.SetResourceAmount(envoy.giftAmount);
		if (envoy.giftAmount.IsNone())
		{
			cancelGift.gameObject.SetActive(value: false);
			giveInstructions.SetActive(value: false);
		}
	}

	internal void Show()
	{
		if (!visible)
		{
			notes.Clear();
			ArrayExt<Building> buildingList = Player.inst.GetBuildingList(World.keepHash);
			for (int i = 0; i < buildingList.Count; i++)
			{
				Building building = buildingList.data[i];
				if (building.TeamID() != 0)
				{
					GameObject gameObject = Object.Instantiate(World.inst.resourceTooltipPrefab);
					ResourceTooltipUI component = gameObject.GetComponent<ResourceTooltipUI>();
					component.SetText("Right click to Visit");
					component.EnableTextAutoSizing();
					gameObject.transform.position = building.GetPos() + new Vector3(0f, 3f, 0f);
					gameObject.transform.SetParent(World.inst.resourceTooltipContainer.transform);
					notes.Add(new NoteBuilding
					{
						b = building,
						note = component
					});
				}
			}
		}
		base.gameObject.SetActive(value: true);
		visible = true;
	}

	internal void Hide()
	{
		if (visible)
		{
			notes.Clear();
			World.inst.HideResourceTooltipUIs();
		}
		gameObject.SetActive(value: false);
		visible = false;
	}

	public void OnCancelGift()
	{
		envoy.TryDropGift();
		giftAmountUI.SetResourceAmount(envoy.giftAmount);
		cancelGift.gameObject.SetActive(value: false);
		giveInstructions.SetActive(value: false);
	}

	public void OnClickedDisband()
	{
		if (army != null)
		{
			if (!envoy.giftAmount.IsNone())
			{
				OnCancelGift();
			}
			army.Disband();
			army = null;
			Hide();
		}
	}
}
