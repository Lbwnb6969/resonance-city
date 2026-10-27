using System;
using I2.Loc;
using UnityEngine;

[Serializable]
public class BeastTemplate
{
	public string templateId;

	public float baseDeathChance = 0.15f;

	public float spectacleBonus = 10f;

	public int tier = 1;

	public int goldCost = 50;

	public GameObject mesh;

	public string GetLocalizedName()
	{
		return LocalizationManager.GetTranslation("colosseum_beast_" + templateId);
	}
}
