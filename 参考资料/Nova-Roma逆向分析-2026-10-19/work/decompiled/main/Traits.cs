using System;
using System.Collections.Generic;
using I2.Loc;
using Sirenix.OdinInspector;
using UnityEngine;

public class Traits : MonoBehaviour
{
	[Serializable]
	public class Trait
	{
		public int id;

		public string locTerm;

		public bool showPlusForNegative;

		public bool isPercentage = true;

		internal string GetDesc(Governor.TraitInstance traitInstance)
		{
			float num = traitInstance.magnitude;
			if (isPercentage)
			{
				num *= 100f;
			}
			string text = "";
			if (traitInstance.negative)
			{
				text = "<color=#FFA68D>";
				text = ((!showPlusForNegative) ? (text + "-") : (text + "+"));
			}
			else
			{
				text = "<color=#D6FF8E>";
				text = (showPlusForNegative ? (text + "-") : (text + "+"));
			}
			text = text + Mathf.RoundToInt(num) + (isPercentage ? "%" : "") + "</color>";
			return "<color=#C4DDE6>" + string.Format(LocalizationManager.GetTranslation("trait_" + locTerm + "_desc"), text) + "</color>";
		}
	}

	public static int FireRisk = 100;

	public static int BuildingDecay = 101;

	public static int SettlerShipRate = 102;

	public static int TaxRevenues = 103;

	public static int Happiness = 104;

	public static int MerchantPrices = 105;

	public static int FoodConsumption = 106;

	public static int BuildCosts = 107;

	public static ValueDropdownList<int> DropdownOptions = new ValueDropdownList<int>
	{
		{ "FireRisk", FireRisk },
		{ "BuildingDecay", BuildingDecay },
		{ "SettlerShipRate", SettlerShipRate },
		{ "TaxRevenues", TaxRevenues },
		{ "Happiness", Happiness },
		{ "MerchantPrices", MerchantPrices },
		{ "FoodConsumption", FoodConsumption },
		{ "BuildCosts", BuildCosts }
	};

	public List<Trait> traits;

	public static Traits inst;

	public Trait GetDef(int id)
	{
		for (int i = 0; i < traits.Count; i++)
		{
			if (traits[i].id == id)
			{
				return traits[i];
			}
		}
		return null;
	}

	public void Start()
	{
		inst = this;
	}
}
