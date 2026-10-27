using UnityEngine;

public class PublicToiletManager : MonoBehaviour
{
	public static PublicToiletManager inst;

	private float[] coverageMap;

	private ArrayExtRef<PublicToilet>[] publicToiletMap;

	private ArrayExtRef<PublicToilet> toilets = new ArrayExtRef<PublicToilet>(64);

	private int currWidth;

	private int currHeight;

	[ColorUsage(true, true)]
	public Color color;

	private int toiletHash = "publictoilets".GetHashCode();

	private void Awake()
	{
		inst = this;
	}

	public void Init()
	{
		toilets.ClearFast();
		currWidth = World.inst.GridWidth;
		currHeight = World.inst.GridHeight;
		int num = currWidth * currHeight;
		if (coverageMap == null || coverageMap.Length != num)
		{
			coverageMap = new float[num];
			publicToiletMap = new ArrayExtRef<PublicToilet>[num];
			return;
		}
		Util.Memset(coverageMap, 0);
		for (int i = 0; i < publicToiletMap.Length; i++)
		{
			publicToiletMap[i] = null;
		}
	}

	public void AddWell(PublicToilet w)
	{
		if (toilets.Contains(w))
		{
			return;
		}
		Vector3 pos = w.b.Center();
		World.inst.ForEachTileTouchingRadius(pos, w.maxProtectionRadius, (int x, int z, Cell cell) =>
		{
			float num = Mathff.DistXZ(pos, cell.Center2D);
			int num2 = x + z * currWidth;
			if (num < w.minProtectionRadius)
			{
				coverageMap[num2]++;
			}
			else
			{
				coverageMap[num2] += GetProtection(w.minProtectionRadius, w.maxProtectionRadius, num);
			}
			ArrayExtRef<PublicToilet>[] array = publicToiletMap;
			int num3 = num2;
			if (array[num3] == null)
			{
				array[num3] = new ArrayExtRef<PublicToilet>(4);
			}
			publicToiletMap[num2].Add(w);
		});
		toilets.Add(w);
	}

	public void RemoveWell(PublicToilet w)
	{
		if (!toilets.Contains(w))
		{
			return;
		}
		Vector3 pos = w.b.Center().xz();
		World.inst.ForEachTileTouchingRadius(pos, w.maxProtectionRadius, (int x, int z, Cell cell) =>
		{
			float num = Mathff.DistXZ(pos, cell.Center2D);
			int num2 = x + z * currWidth;
			if (num < w.minProtectionRadius)
			{
				coverageMap[num2]--;
			}
			else
			{
				coverageMap[num2] -= GetProtection(w.minProtectionRadius, w.maxProtectionRadius, num);
			}
			if (publicToiletMap[num2] != null)
			{
				publicToiletMap[num2].RemoveSwap(w);
			}
		});
		toilets.RemoveSwap(w);
	}

	public void DrawOverlay()
	{
		for (int i = 0; i < toilets.Count; i++)
		{
			PublicToilet publicToilet = toilets.data[i];
			Vector3 s = publicToilet.GetComponent<Building>().Center().xz();
			World.inst.ForEachTileTouchingRadius(s, publicToilet.maxProtectionRadius, (int x, int z, Cell cell) =>
			{
				Color color = new Color(this.color.r, this.color.g, this.color.b, Mathff.Clamp01(coverageMap[x + z * currWidth]));
				SetColorForTile(x, z, cell, color * 0.9f);
			});
		}
	}

	private float GetProtection(float minProtectionRadius, float maxProtectionRadius, float dist)
	{
		return Mathff.Max(0.25f, (maxProtectionRadius - dist) / (maxProtectionRadius - minProtectionRadius));
	}

	public void DrawWellOverlay(PublicToilet w)
	{
		Vector3 pos = w.GetComponent<Building>().Center().xz();
		World.inst.ForEachTileTouchingRadius(pos, w.maxProtectionRadius, (int x, int z, Cell cell) =>
		{
			float dist = Vector3.Distance(pos, cell.Center2D);
			float a = TerrainGen.inst.GetOverlayTileColor(x, z).a;
			float protection = GetProtection(w.minProtectionRadius, w.maxProtectionRadius, dist);
			Color overlayTileColor = TerrainGen.inst.GetOverlayTileColor(x, z);
			Color color = new Color(this.color.r, this.color.g, this.color.b, Mathff.Clamp01(a + protection));
			SetColorForTile(x, z, cell, Color.Lerp(overlayTileColor, color * 0.9f, 0.85f));
		});
	}

	private void SetColorForTile(int x, int z, Cell cell, Color col)
	{
		TerrainGen.inst.SetOverlayTileColorNoBuilding(x, z, col);
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			if (cell.OccupyingStructure[i].uniqueNameHash != toiletHash)
			{
				TerrainGen.inst.SetOverlayBuildingColorOverlapCheck(x, z, cell, col * 0.85f, applyBuildingMaterial: false);
			}
		}
	}

	public float GetProtectionWithStaff(int x, int z)
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
		if (publicToiletMap[num] != null)
		{
			float num2 = 0f;
			for (int i = 0; i < publicToiletMap[num].Count; i++)
			{
				float num3 = coverageMap[x + z * currWidth] * (float)((publicToiletMap[num].data[i].b.WorkersAllocated > 0) ? 1 : 0);
				if (num3 > num2)
				{
					num2 = num3;
				}
			}
			return Mathf.Clamp01(num2);
		}
		Debug.LogError("Toilet Not Added To Map But Has Coverage");
		return 0f;
	}
}
