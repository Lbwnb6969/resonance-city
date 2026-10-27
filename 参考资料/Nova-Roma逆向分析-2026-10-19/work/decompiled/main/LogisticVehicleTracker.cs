using UnityEngine;

public class LogisticVehicleTracker : LineTracker
{
	public static LogisticVehicleTracker inst;

	public static ArrayExtRef<LogisticsVehicle> vehicles = new ArrayExtRef<LogisticsVehicle>(128);

	private ArrayExtRef<Building> buildings = new ArrayExtRef<Building>(10);

	private void Awake()
	{
		inst = this;
	}

	public void TrackLogisticStorageForVehicles(LogisticsVehicle targetVehicle)
	{
		TryInit();
		buildings.ClearFast();
		for (int i = 0; i < targetVehicle.routes.Count; i++)
		{
			Building targetBuilding = targetVehicle.routes[i].targetBuilding;
			if (!buildings.Contains(targetBuilding))
			{
				buildings.Add(targetBuilding);
			}
		}
		startOffsetRadius = 0.25f;
		for (int j = 0; j < buildings.Count; j++)
		{
			Vector3 position = targetVehicle.transform.position;
			Vector3 endPoint = buildings.data[j].Center();
			endPoint.y += 0.25f;
			DisplayLine(position, endPoint, Color.white);
		}
	}

	public void TrackCartsForLogisticStorage(LogisticsManager.LogisticsForStorage storage, bool doHighlight = false)
	{
		if (storage == null || storage.targetBuilding == null || storage.sourceBuildings.Count <= 0)
		{
			return;
		}
		vehicles.ClearFast();
		Building targetBuilding = storage.targetBuilding;
		for (int i = 0; i < LogisticsManager.vehicles.Count; i++)
		{
			LogisticsVehicle logisticsVehicle = LogisticsManager.vehicles[i];
			for (int j = 0; j < logisticsVehicle.routes.Count; j++)
			{
				if (logisticsVehicle.routes[j].targetBuilding == targetBuilding)
				{
					if (!vehicles.Contains(logisticsVehicle))
					{
						vehicles.Add(logisticsVehicle);
					}
					break;
				}
			}
		}
		for (int k = 0; k < vehicles.Count; k++)
		{
			LogisticsVehicle logisticsVehicle2 = vehicles.data[k];
			if (logisticsVehicle2 == null)
			{
				continue;
			}
			if (doHighlight)
			{
				logisticsVehicle2.GetComponent<LogisticCart>()?.SetHighlightImmediate(0);
				logisticsVehicle2.GetComponent<TransportShip>()?.highlighter.SetOutlineImmediate(0);
			}
			Vector3 position = logisticsVehicle2.transform.position;
			if (targetBuilding != null)
			{
				targetBuilding.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
				if (position.x >= (float)minX - 0.15f && position.x <= (float)maxX + 1.15f && position.z >= (float)minZ - 0.15f && position.z <= (float)maxZ + 1.15f)
				{
					continue;
				}
				startOffsetRadius = ((targetBuilding.size.x > targetBuilding.size.z) ? targetBuilding.size.x : targetBuilding.size.z) * 0.5f * 1.4142135f;
			}
			else
			{
				startOffsetRadius = 0f;
			}
			Vector3 startPoint = targetBuilding.Center();
			Vector3 endPoint = position;
			endPoint.y += 0.25f;
			DisplayLine(startPoint, endPoint, Color.white);
		}
	}
}
