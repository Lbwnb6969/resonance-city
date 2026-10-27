using System;
using UnityEngine;

public class Clinic : MonoBehaviour
{
	[NonSerialized]
	public Building b;

	private RadiusBonusHealth rHealthBonus;

	private void Awake()
	{
		b = GetComponent<Building>();
		rHealthBonus = GetComponent<RadiusBonusHealth>();
		rHealthBonus.healthFunc = () => (b.GetWorkerPercent() > 0f) ? rHealthBonus.Health : 0;
	}
}
