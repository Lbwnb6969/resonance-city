using UnityEngine;

public class TaxOfficeManager : MonoBehaviour
{
	public static TaxOfficeManager inst;

	private float[] coverageMap;

	private ArrayExtRef<TaxOffice>[] taxOfficeMap;

	private ArrayExtRef<TaxOffice> taxOffices = new ArrayExtRef<TaxOffice>(64);

	private int prevWidth = -1;

	private int prevHeight = -1;

	[ColorUsage(true, true)]
	public Color color;

	public ArrayExtRef<TaxOffice> GetOfficesForCell(int x, int z)
	{
		int num = x + z * prevWidth;
		return taxOfficeMap[num];
	}

	private void Awake()
	{
		inst = this;
	}

	private void TryInit()
	{
		if (World.inst.GridWidth != prevWidth || World.inst.GridHeight != prevHeight)
		{
			coverageMap = new float[World.inst.GridWidth * World.inst.GridHeight];
			taxOfficeMap = new ArrayExtRef<TaxOffice>[World.inst.GridWidth * World.inst.GridHeight];
			prevWidth = World.inst.GridWidth;
			prevHeight = World.inst.GridHeight;
		}
	}

	public void Reset()
	{
		TryInit();
		taxOffices.ClearFast();
		if (coverageMap == null)
		{
			return;
		}
		Util.Memset(coverageMap, 0);
		for (int i = 0; i < taxOfficeMap.Length; i++)
		{
			if (taxOfficeMap[i] != null)
			{
				taxOfficeMap[i].ClearFast();
			}
		}
	}

	public static bool InsideRadius(Vector3 origin, float radius, Vector3 testPos)
	{
		if (Mathff.DistSqrdXZ(origin, testPos) < radius * radius)
		{
			return true;
		}
		return false;
	}

	public void AddTaxOffice(TaxOffice t)
	{
		TryInit();
		if (taxOffices.Contains(t))
		{
			return;
		}
		Vector3 pos = t.GetComponent<Building>().Center();
		World.inst.ForEachTileTouchingRadius(pos, t.Radius, (int x, int z, Cell cell) =>
		{
			if (InsideRadius(pos, t.Radius, cell.Center2D))
			{
				int num = x + z * prevWidth;
				coverageMap[num]++;
				ArrayExtRef<TaxOffice>[] array = taxOfficeMap;
				int num2 = num;
				if (array[num2] == null)
				{
					array[num2] = new ArrayExtRef<TaxOffice>(4);
				}
				taxOfficeMap[num].Add(t);
			}
		});
		taxOffices.Add(t);
	}

	public void RemoveTaxOffice(TaxOffice t)
	{
		TryInit();
		if (!taxOffices.Contains(t))
		{
			return;
		}
		Vector3 pos = t.GetComponent<Building>().Center().xz();
		World.inst.ForEachTileTouchingRadius(pos, t.Radius, (int x, int z, Cell cell) =>
		{
			if (InsideRadius(pos, t.Radius, cell.Center2D))
			{
				int num = x + z * prevWidth;
				coverageMap[num]--;
				if (taxOfficeMap[num] != null)
				{
					taxOfficeMap[num].RemoveSwap(t);
				}
			}
		});
		taxOffices.RemoveSwap(t);
	}

	public void DrawOverlay()
	{
		TryInit();
		Color col = Color.white;
		for (float num = 0f; num <= 3f; num += 0.5f)
		{
			for (int i = 0; i < taxOffices.Count; i++)
			{
				TaxOffice taxOffice = taxOffices.data[i];
				Vector3 s = taxOffice.GetComponent<Building>().Center().xz();
				if (!(Mathf.Abs(taxOffice.Rate - num) < 0.001f))
				{
					continue;
				}
				float rate = GetAlpha(taxOffice.Rate);
				World.inst.ForEachTileTouchingRadius(s, taxOffice.Radius, (int x, int z, Cell cell) =>
				{
					if (coverageMap[x + z * prevWidth] > 0f)
					{
						col.r = color.r;
						col.g = color.g;
						col.b = color.b;
						col.a = rate;
						SetColorForTile(x, z, cell, col);
					}
				});
			}
		}
	}

	private float GetAlpha(float rate)
	{
		return Mathff.Lerp(0.2f, 0.8f, rate / 3f);
	}

	public void DrawTaxOfficeOverlay(TaxOffice t)
	{
		float rate = GetAlpha(t.Rate);
		Vector3 pos = t.GetComponent<Building>().Center().xz();
		World.inst.ForEachTileTouchingRadius(pos, t.Radius, (int x, int z, Cell cell) =>
		{
			if (InsideRadius(pos, t.Radius, cell.Center2D))
			{
				Color col = new Color(color.r, color.g, color.b, rate);
				SetColorForTile(x, z, cell, col);
			}
		});
	}

	private void SetColorForTile(int x, int z, Cell cell, Color col)
	{
		TerrainGen.inst.SetOverlayTileColorNoBuilding(x, z, col);
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			if (cell.OccupyingStructure[i].categoryHash == World.houseCategoryHash)
			{
				TerrainGen.inst.SetOverlayBuildingColorOverlapCheck(x, z, cell, col, applyBuildingMaterial: false);
				break;
			}
		}
	}

	public float GetTaxOfficeCoverageWithStaff(int x, int z)
	{
		if (coverageMap == null)
		{
			return 0f;
		}
		int num = x + z * prevWidth;
		if (Mathff.Clamp01(coverageMap[num]) <= 0f)
		{
			return 0f;
		}
		if (taxOfficeMap[num] != null)
		{
			float num2 = 0f;
			for (int i = 0; i < taxOfficeMap[num].Count; i++)
			{
				TaxOffice taxOffice = taxOfficeMap[num].data[i];
				float num3 = taxOffice.Rate * taxOffice.GetWorkerPercent();
				if (num3 > num2)
				{
					num2 = num3;
				}
			}
			return num2;
		}
		Debug.LogError("Tax Office Not Added To Map But Has Coverage");
		return 0f;
	}
}
