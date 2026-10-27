using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class WaterConsumer : MonoBehaviour
{
	public Building b;

	public float availableWaterPercentage;

	public float consumptionRate = 1f;

	private static ArrayExt<ArrayExt<WaterConsumer>> consumersByLandmass = new ArrayExt<ArrayExt<WaterConsumer>>(50);

	private UnityAction waterChangeCallback;

	private static List<WaterSupplier> allSuppliersScratch = new List<WaterSupplier>();

	public static ArrayExt<WaterConsumer> GetConsumersForLandmass(int landmassId)
	{
		while (consumersByLandmass.Count <= landmassId)
		{
			consumersByLandmass.Add(new ArrayExt<WaterConsumer>(100));
		}
		return consumersByLandmass.data[landmassId];
	}

	public void SetupChangeCallback(UnityAction callback)
	{
		waterChangeCallback = callback;
	}

	public void ClearChangeCallback()
	{
		waterChangeCallback = null;
	}

	public void OnBuilt()
	{
		RegisterWithWaterSystem();
	}

	public void SetupFromLoad()
	{
		if (b.IsBuilt())
		{
			RegisterWithWaterSystem();
		}
	}

	public void OnDestroy()
	{
		if (!GameState.IsQuitting && b.IsBuilt())
		{
			UnregisterWithWaterSystem();
		}
	}

	public void RegisterWithWaterSystem()
	{
		allSuppliersScratch.Clear();
		b.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			List<WaterSupplier> waterSuppliers = World.inst.GetCellWaterSupplyDataClamped(x, z).waterSuppliers;
			for (int i = 0; i < waterSuppliers.Count; i++)
			{
				if (!allSuppliersScratch.Contains(waterSuppliers[i]))
				{
					allSuppliersScratch.Add(waterSuppliers[i]);
				}
			}
		});
		float num = float.MaxValue;
		WaterSupplier waterSupplier = null;
		for (int num2 = 0; num2 < allSuppliersScratch.Count; num2++)
		{
			float num3 = Vector3.Distance(b.GetCell().Center2D, allSuppliersScratch[num2].b.GetCell().Center2D);
			if (num3 < num)
			{
				num = num3;
				waterSupplier = allSuppliersScratch[num2];
			}
		}
		if (waterSupplier != null)
		{
			waterSupplier.AddConsumer(this);
		}
		GetConsumersForLandmass(b.LandMass()).Add(this);
	}

	public void UnregisterWithWaterSystem()
	{
		allSuppliersScratch.Clear();
		b.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			List<WaterSupplier> waterSuppliers = World.inst.GetCellWaterSupplyDataClamped(x, z).waterSuppliers;
			for (int i = 0; i < waterSuppliers.Count; i++)
			{
				if (!allSuppliersScratch.Contains(waterSuppliers[i]))
				{
					allSuppliersScratch.Add(waterSuppliers[i]);
				}
			}
		});
		for (int num = 0; num < allSuppliersScratch.Count; num++)
		{
			allSuppliersScratch[num].RemoveConsumer(this);
		}
		GetConsumersForLandmass(b.LandMass()).RemoveSwap(this);
		AvailableWaterChanged(0f);
	}

	public void AvailableWaterChanged(float availableWaterPercentage)
	{
		this.availableWaterPercentage = Mathf.Clamp01(availableWaterPercentage);
		waterChangeCallback?.Invoke();
	}
}
