using System.Collections.Generic;
using UnityEngine;

public class HeightMarker : MonoBehaviour
{
	private static HeightMarker inst;

	private GameObject markerPrefab;

	private List<AqueductBuildingElevationMarker> pool = new List<AqueductBuildingElevationMarker>();

	private int activeCount;

	private static readonly int[] waterBuildingHashes = new int[4]
	{
		World.waterTowerHash,
		World.bathReservoirHash,
		World.waterOutletHash,
		World.ironOreMillHash
	};

	private void Awake()
	{
		inst = this;
	}

	private void OnDestroy()
	{
		if (inst == this)
		{
			inst = null;
		}
	}

	public static void BeginFrame()
	{
		if (!(inst == null))
		{
			inst.activeCount = 0;
		}
	}

	public static void Show(Vector3 position)
	{
		if (!(inst == null))
		{
			inst.ShowMarker(position, Vector3.up * 0.7f);
		}
	}

	public static void Show(AqueductBuilding building)
	{
		if (!(inst == null) && !(building == null))
		{
			building.GetPortBox(out var min, out var max, 0);
			Vector3 position = (min + max) / 2f;
			Vector3 textOffset = Vector3.up * 0.7f;
			if (building is RiverTap { damMounted: not false } riverTap)
			{
				textOffset -= riverTap.mountDir * 1.2f;
			}
			inst.ShowMarker(position, textOffset);
		}
	}

	public static void ShowLandmassWaterBuildings(int landMass)
	{
		if (inst == null)
		{
			return;
		}
		for (int i = 0; i < waterBuildingHashes.Length; i++)
		{
			ArrayExt<Building> buildingListForLandMass = Player.inst.GetBuildingListForLandMass(landMass, waterBuildingHashes[i]);
			for (int j = 0; j < buildingListForLandMass.Count; j++)
			{
				if (buildingListForLandMass.data[j] != null)
				{
					Show(buildingListForLandMass.data[j].GetComponent<AqueductBuilding>());
				}
			}
		}
	}

	private void ShowMarker(Vector3 position, Vector3 textOffset)
	{
		AqueductBuildingElevationMarker fromPool = GetFromPool();
		fromPool.transform.position = position;
		fromPool.textOffset = textOffset;
		fromPool.gameObject.SetActive(value: true);
	}

	private void LateUpdate()
	{
		for (int i = activeCount; i < pool.Count; i++)
		{
			if (pool[i] != null && pool[i].gameObject.activeSelf)
			{
				pool[i].gameObject.SetActive(value: false);
			}
		}
	}

	private AqueductBuildingElevationMarker GetFromPool()
	{
		if (activeCount < pool.Count)
		{
			return pool[activeCount++];
		}
		if (markerPrefab == null)
		{
			markerPrefab = Resources.Load<GameObject>("AqueductBuildingElevationMarker");
		}
		AqueductBuildingElevationMarker component = Object.Instantiate(markerPrefab, transform).GetComponent<AqueductBuildingElevationMarker>();
		pool.Add(component);
		activeCount++;
		return component;
	}

	public static void EnsureInitialized()
	{
		if (!(inst != null))
		{
			inst = new GameObject("HeightMarkerSystem").AddComponent<HeightMarker>();
		}
	}

	public static void Shutdown()
	{
		if (inst != null)
		{
			Object.Destroy(inst.gameObject);
			inst = null;
		}
	}
}
