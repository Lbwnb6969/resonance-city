using I2.Loc;
using UnityEngine;

public class TutorialUI : MonoBehaviour
{
	public GameObject root;

	public Localize text;

	private void Start()
	{
	}

	private void Update()
	{
		int num = 0;
		LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
		for (int i = 0; i < playerLandmassOwner.ownedLandMasses.Count; i++)
		{
			num += Player.inst.GetBuildingListForLandMass(playerLandmassOwner.ownedLandMasses.data[i]).Count;
		}
		Util.SetActive(root.gameObject, num <= 0);
		if (num <= 0)
		{
			if (Player.inst.FocusedLandMass == -1)
			{
				text.Term = "tutorialui_focusland";
			}
			else
			{
				text.Term = "tutorialui_builddock";
			}
		}
	}
}
