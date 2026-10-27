using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class WaterSupplier : MonoBehaviour
{
	public Building b;

	public float radiusMax = 7f;

	public float waterLoad;

	public List<WaterConsumer> consumers = new List<WaterConsumer>();

	private UnityAction waterChangeCallback;

	private static List<WaterConsumer> allConsumersScratch = new List<WaterConsumer>();

	[NonSerialized]
	public Vector3 center;

	internal bool applied;

	public void SetupChangeCallback(UnityAction callback)
	{
		waterChangeCallback = callback;
	}

	public void AddConsumer(WaterConsumer consumer)
	{
		if (!consumers.Contains(consumer))
		{
			waterLoad += consumer.consumptionRate;
			float num = Vector3.Distance(consumer.b.GetCell().Center2D, b.GetCell().Center2D);
			int i;
			for (i = 0; i < consumers.Count && Vector3.Distance(consumers[i].b.GetCell().Center2D, b.GetCell().Center2D) <= num; i++)
			{
			}
			consumers.Insert(i, consumer);
			waterChangeCallback();
		}
	}

	public void RemoveConsumer(WaterConsumer consumer)
	{
		if (consumers.Contains(consumer))
		{
			waterLoad -= consumer.consumptionRate;
			consumers.Remove(consumer);
			waterChangeCallback();
		}
	}

	public void AvailableWaterChanged(float availableWater)
	{
		float num = availableWater;
		for (int i = 0; i < consumers.Count; i++)
		{
			float consumptionRate = consumers[i].consumptionRate;
			float num2 = Mathf.Min(consumptionRate, num);
			num -= num2;
			consumers[i].AvailableWaterChanged((consumptionRate > 0f) ? (num2 / consumptionRate) : 1f);
		}
	}

	public void Apply()
	{
		applied = true;
		allConsumersScratch.Clear();
		float radius = radiusMax;
		Vector3 s = transform.position + b.LocalCenter();
		World.inst.ForEachTileTouchingRadius(s, radius, (int x, int z, Cell cell) =>
		{
			if (cell.OccupyingStructure != null)
			{
				for (int i = 0; i < cell.OccupyingStructure.Count; i++)
				{
					WaterConsumer component = cell.OccupyingStructure[i].GetComponent<WaterConsumer>();
					if (!(component == null) && component.b.IsBuilt() && !allConsumersScratch.Contains(component))
					{
						allConsumersScratch.Add(component);
					}
				}
			}
			World.inst.GetCellWaterSupplyDataClamped(x, z).waterSuppliers.Add(this);
		});
		for (int num = 0; num < allConsumersScratch.Count; num++)
		{
			allConsumersScratch[num].UnregisterWithWaterSystem();
			allConsumersScratch[num].RegisterWithWaterSystem();
		}
	}

	public void Remove()
	{
		applied = false;
		allConsumersScratch.Clear();
		float radius = radiusMax;
		Vector3 s = transform.position + b.LocalCenter();
		World.inst.ForEachTileTouchingRadius(s, radius, (int x, int z, Cell cell) =>
		{
			if (cell.OccupyingStructure != null && cell.OccupyingStructure.Count > 0 && cell.OccupyingStructure[0] != null && cell.BottomStructureIs<WaterConsumer>())
			{
				WaterConsumer component = cell.OccupyingStructure[0].GetComponent<WaterConsumer>();
				if (component.b.IsBuilt() && !allConsumersScratch.Contains(component))
				{
					allConsumersScratch.Add(component);
				}
			}
			World.inst.GetCellWaterSupplyDataClamped(x, z).waterSuppliers.Remove(this);
		});
		for (int num = 0; num < allConsumersScratch.Count; num++)
		{
			allConsumersScratch[num].UnregisterWithWaterSystem();
			allConsumersScratch[num].RegisterWithWaterSystem();
		}
	}

	private void OnDestroy()
	{
		if (!GameState.IsQuitting && applied)
		{
			Remove();
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (b.IsBuilt() && !undo)
		{
			Apply();
		}
	}

	private void OnFinishedLoad()
	{
		center = GetComponent<Building>().Center();
	}

	private void OnBuilt()
	{
		center = GetComponent<Building>().Center();
		Apply();
	}
}
