using UnityEngine;

public class WellManager : MonoBehaviour
{
	public static WellManager inst;

	private float[] wellMap;

	private ArrayExt<Well> wells = new ArrayExt<Well>(64);

	private int currWidth;

	private int currHeight;

	[ColorUsage(true, true)]
	public Color color;

	private void Awake()
	{
		inst = this;
	}

	public void Init()
	{
		wells.ClearFast();
		currWidth = World.inst.GridWidth;
		currHeight = World.inst.GridHeight;
		int num = currWidth * currHeight;
		if (wellMap == null || wellMap.Length != num)
		{
			wellMap = new float[num];
		}
		else
		{
			Util.Memset(wellMap, 0);
		}
	}

	public void AddWell(Well w)
	{
		if (wells.Contains(w))
		{
			return;
		}
		Vector3 pos = w.GetComponent<Building>().Center();
		World.inst.ForEachTileTouchingRadius(pos, w.maxProtectionRadius, (int x, int z, Cell cell) =>
		{
			float num = Vector3.Distance(pos.xz(), cell.Center2D);
			if (num < w.minProtectionRadius)
			{
				wellMap[x + z * currWidth]++;
			}
			else
			{
				wellMap[x + z * currWidth] += GetProtection(w.minProtectionRadius, w.maxProtectionRadius, num);
			}
		});
		wells.Add(w);
	}

	public void RemoveWell(Well w)
	{
		if (!wells.Contains(w))
		{
			return;
		}
		Vector3 pos = w.GetComponent<Building>().Center().xz();
		World.inst.ForEachTileTouchingRadius(pos, w.maxProtectionRadius, (int x, int z, Cell cell) =>
		{
			float num = Vector3.Distance(pos.xz(), cell.Center2D);
			if (num < w.minProtectionRadius)
			{
				wellMap[x + z * currWidth]--;
			}
			else
			{
				wellMap[x + z * currWidth] -= GetProtection(w.minProtectionRadius, w.maxProtectionRadius, num);
			}
		});
		wells.RemoveSwap(w);
	}

	public void DrawOverlay()
	{
		for (int i = 0; i < wells.Count; i++)
		{
			Well well = wells.data[i];
			Vector3 s = well.GetComponent<Building>().Center().xz();
			World.inst.ForEachTileTouchingRadius(s, well.maxProtectionRadius, (int x, int z, Cell cell) =>
			{
				Color overlayTileColor = TerrainGen.inst.GetOverlayTileColor(x, z);
				TerrainGen.inst.SetOverlayTileColor(x, z, Color.Lerp(overlayTileColor, new Color(color.r, color.g, color.b, wellMap[x + z * currWidth]), 0.85f));
			});
		}
	}

	private float GetProtection(float minProtectionRadius, float maxProtectionRadius, float dist)
	{
		return Mathff.Max(0.25f, (maxProtectionRadius - dist) / (maxProtectionRadius - minProtectionRadius));
	}

	public void DrawWellOverlay(Well w)
	{
		Color col = color;
		Vector3 pos = w.GetComponent<Building>().Center().xz();
		World.inst.ForEachTileTouchingRadius(pos, w.maxProtectionRadius, (int x, int z, Cell cell) =>
		{
			float num = Vector3.Distance(pos, cell.Center2D);
			if (num < w.minProtectionRadius)
			{
				col.a = 1f;
			}
			else
			{
				float a = TerrainGen.inst.GetOverlayTileColor(x, z).a;
				float protection = GetProtection(w.minProtectionRadius, w.maxProtectionRadius, num);
				col.a = a + protection;
			}
			Color overlayTileColor = TerrainGen.inst.GetOverlayTileColor(x, z);
			TerrainGen.inst.SetOverlayTileColor(x, z, Color.Lerp(overlayTileColor, col, 0.85f));
		});
	}

	public float GetProtection(int x, int z)
	{
		if (wellMap == null)
		{
			return 0f;
		}
		return Mathff.Clamp01(wellMap[x + z * currWidth]);
	}
}
