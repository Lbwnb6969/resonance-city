using UnityEngine;

public class FirehouseManager : MonoBehaviour
{
	public static FirehouseManager inst;

	private float[] coverageMap;

	private ArrayExtRef<FireRiskReduction>[] buildingMap;

	private ArrayExt<FireRiskReduction> fireRiskReductions = new ArrayExt<FireRiskReduction>(64);

	private int currWidth;

	private int currHeight;

	[ColorUsage(true, true)]
	public Color color;

	private int firehouseHash = "firehouse".GetHashCode();

	private int wellHash = "well".GetHashCode();

	private void Awake()
	{
		inst = this;
	}

	public void Init()
	{
		fireRiskReductions.ClearFast();
		currWidth = World.inst.GridWidth;
		currHeight = World.inst.GridHeight;
		int num = currWidth * currHeight;
		if (coverageMap == null || coverageMap.Length != num)
		{
			coverageMap = new float[num];
			buildingMap = new ArrayExtRef<FireRiskReduction>[num];
			return;
		}
		Util.Memset(coverageMap, 0);
		for (int i = 0; i < buildingMap.Length; i++)
		{
			buildingMap[i] = null;
		}
	}

	public void Add(FireRiskReduction w)
	{
		if (fireRiskReductions.Contains(w))
		{
			return;
		}
		Vector3 pos = w.GetComponent<Building>().Center();
		World.inst.ForEachTileTouchingRadius(pos, w.maxProtectionRadius, (int x, int z, Cell cell) =>
		{
			float num = Vector3.Distance(pos.xz(), cell.Center2D);
			int num2 = x + z * currWidth;
			if (num < w.minProtectionRadius)
			{
				coverageMap[num2] += w.strength * 1f;
			}
			else
			{
				coverageMap[num2] += w.strength * GetProtectionAlpha(w.minProtectionRadius, w.maxProtectionRadius, num);
			}
			ArrayExtRef<FireRiskReduction>[] array = buildingMap;
			int num3 = num2;
			if (array[num3] == null)
			{
				array[num3] = new ArrayExtRef<FireRiskReduction>(4);
			}
			buildingMap[num2].Add(w);
		});
		fireRiskReductions.Add(w);
	}

	public void Remove(FireRiskReduction w)
	{
		if (!fireRiskReductions.Contains(w))
		{
			return;
		}
		Vector3 pos = w.GetComponent<Building>().Center().xz();
		World.inst.ForEachTileTouchingRadius(pos, w.maxProtectionRadius, (int x, int z, Cell cell) =>
		{
			float num = Vector3.Distance(pos.xz(), cell.Center2D);
			int num2 = x + z * currWidth;
			if (num < w.minProtectionRadius)
			{
				coverageMap[num2] -= w.strength * 1f;
			}
			else
			{
				coverageMap[num2] -= w.strength * GetProtectionAlpha(w.minProtectionRadius, w.maxProtectionRadius, num);
			}
			if (buildingMap[num2] != null)
			{
				buildingMap[num2].RemoveSwap(w);
			}
		});
		fireRiskReductions.RemoveSwap(w);
	}

	public void DrawOverlay()
	{
		for (int i = 0; i < fireRiskReductions.Count; i++)
		{
			FireRiskReduction fireRiskReduction = fireRiskReductions.data[i];
			Vector3 pos = fireRiskReduction.GetComponent<Building>().Center().xz();
			World.inst.ForEachTileTouchingRadius(pos, fireRiskReduction.maxProtectionRadius, (int x, int z, Cell cell) =>
			{
				if (((int)pos.x != x || (int)pos.z != z) && !cell.StructureCompareCategoryNameAll(firehouseHash) && !cell.StructureCompareCategoryNameAll(wellHash))
				{
					Color color = new Color(this.color.r, this.color.g, this.color.b, Mathff.Clamp01(coverageMap[x + z * currWidth]));
					TerrainGen.inst.SetOverlayTileColorOverlapCheck(x, z, cell, color, color * 0.9f, applyBuildingMaterial: false);
				}
			});
		}
	}

	private float GetProtectionAlpha(float minProtectionRadius, float maxProtectionRadius, float dist)
	{
		return Mathff.Max(0.25f, (maxProtectionRadius - dist) / (maxProtectionRadius - minProtectionRadius));
	}

	public void DrawOverlay(FireRiskReduction w)
	{
		Vector3 pos = w.GetComponent<Building>().Center().xz();
		World.inst.ForEachTileTouchingRadius(pos, w.maxProtectionRadius, (int x, int z, Cell cell) =>
		{
			if (((int)pos.x != x || (int)pos.z != z) && !cell.StructureCompareCategoryNameAll(firehouseHash) && !cell.StructureCompareCategoryNameAll(wellHash))
			{
				float dist = Vector3.Distance(pos, cell.Center2D);
				float a = TerrainGen.inst.GetOverlayTileColor(x, z).a;
				float num = w.strength * GetProtectionAlpha(w.minProtectionRadius, w.maxProtectionRadius, dist);
				Color color = new Color(this.color.r, this.color.g, this.color.b, Mathff.Clamp01(a + num));
				TerrainGen.inst.SetOverlayTileColorOverlapCheck(x, z, cell, color, color * 0.9f, applyBuildingMaterial: false);
			}
		});
	}

	public float GetProtection(int x, int z)
	{
		if (coverageMap == null)
		{
			return 0f;
		}
		int num = x + z * currWidth;
		if (Mathff.Clamp01(coverageMap[num]) <= 0f)
		{
			return 0f;
		}
		if (buildingMap[num] != null)
		{
			float num2 = 0f;
			for (int i = 0; i < buildingMap[num].Count; i++)
			{
				float num3 = coverageMap[x + z * currWidth];
				Building b = buildingMap[num].data[i].b;
				num3 *= b.GetWorkerPercent();
				if (num3 > num2)
				{
					num2 = num3;
				}
			}
			return Mathff.Clamp01(num2);
		}
		Debug.LogError("Toilet Not Added To Map But Has Coverage");
		return 0f;
	}
}
