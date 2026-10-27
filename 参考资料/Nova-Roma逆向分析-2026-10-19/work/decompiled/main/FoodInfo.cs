using System.Text;
using Assets.Code;
using TMPro;
using UnityEngine;

public class FoodInfo : InfoBase
{
	private StringBuilder builder = new StringBuilder(500);

	public TextMeshProUGUI currWheatTxt;

	public TextMeshProUGUI maxWheatTxt;

	public TextMeshProUGUI currApplesTxt;

	public TextMeshProUGUI maxApplesTxt;

	public TextMeshProUGUI currFishTxt;

	public TextMeshProUGUI maxFishTxt;

	public TextMeshProUGUI currPorkTxt;

	public TextMeshProUGUI maxPorkTxt;

	public GameObject exclamation;

	public GameObject wheatExclaim;

	public GameObject appleExclaim;

	public GameObject fishExclaim;

	public GameObject porkExclaim;

	public TextMeshProUGUI Text;

	private bool SetFoodValues(ResourceAmount resources, ResourceAmount storage, TextMeshProUGUI currTxt, TextMeshProUGUI maxTxt, int t)
	{
		bool result = false;
		int num = resources.Get(t);
		int num2 = storage.Get(t);
		if ((float)num < (float)num2 * 0.1f)
		{
			currTxt.SetText("<color=yellow>{0} /</color>", num);
			maxTxt.SetText("{0}", num2);
		}
		else if ((float)num > (float)num2 * 0.9f)
		{
			currTxt.SetText("{0} /", num);
			maxTxt.SetText("<color=yellow>{0}</color>", num2);
			result = true;
		}
		else
		{
			currTxt.SetText("{0} /", num);
			maxTxt.SetText("{0}", num2);
		}
		return result;
	}

	private void Update()
	{
	}
}
