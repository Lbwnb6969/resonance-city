using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class PersonListItemUI : MonoBehaviour
{
	public Button MagGlass;

	public TextMeshProUGUI Description;

	public Villager Villager;

	public GameObject HeadOfHouseholdIcon;

	public GameObject tiredIcon;

	private void Start()
	{
		MagGlass.onClick.AddListener(OnMagClick);
	}

	private void OnMagClick()
	{
		if (Villager != null)
		{
			GameUI.inst.SelectPerson(Villager);
			Cam.inst.Track(Villager);
		}
	}

	public void SetHohIconVisible(bool visible)
	{
		HeadOfHouseholdIcon.SetActive(visible);
	}
}
