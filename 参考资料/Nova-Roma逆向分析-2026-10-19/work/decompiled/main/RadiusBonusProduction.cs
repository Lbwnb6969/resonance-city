using System;
using Assets.Code;
using Assets.Code.Interface;
using UnityEngine;

public class RadiusBonusProduction : MonoBehaviour, IOverlayUser
{
	[NonSerialized]
	public Building b;

	[Header("Resource Settings")]
	[FreeResourceType]
	public int[] resourceIDs;

	public int Bonus = 5;

	public float radiusMin = 15f;

	public float radiusMax = 15f;

	internal float Mod = 1f;

	internal bool processed;

	internal bool applied;

	public bool autoApplyBonus = true;

	public bool overlayWhenPlacing = true;

	public bool overlayWhenSelected = true;

	public bool showOverWater;

	public bool OverlayWhenPlacing => overlayWhenPlacing;

	public bool OverlayWhenSelected => overlayWhenSelected;

	private void OnEnable()
	{
		b = GetComponent<Building>();
	}

	public int GetBonus()
	{
		return (int)((float)Bonus * Mod);
	}

	public bool BoostsResource(int rID)
	{
		for (int i = 0; i < resourceIDs.Length; i++)
		{
			if (resourceIDs[i] == rID)
			{
				return true;
			}
		}
		return false;
	}

	public void ApplyBonus()
	{
		applied = true;
		float radius = radiusMax;
		Vector3 s = transform.position + b.LocalCenter();
		World.inst.ForEachTileTouchingRadius(s, radius, (int x, int z, Cell cell) =>
		{
			World.inst.GetCellProductionInfluenceDataClamped(x, z).radiusBonuses.Add(this);
		});
	}

	public void RemoveBonus()
	{
		applied = false;
		float radius = radiusMax;
		Vector3 s = transform.position + b.LocalCenter();
		World.inst.ForEachTileTouchingRadius(s, radius, (int x, int z, Cell cell) =>
		{
			World.inst.GetCellProductionInfluenceDataClamped(x, z).radiusBonuses.Remove(this);
		});
	}

	private void OnDestroy()
	{
		if (applied)
		{
			RemoveBonus();
		}
	}

	public void OnShutdown()
	{
		if (applied)
		{
			RemoveBonus();
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (autoApplyBonus && !undo)
		{
			ApplyBonus();
		}
	}

	public void DrawOverlay(Vector3 origin)
	{
		if (!b)
		{
			return;
		}
		TerrainGen.inst.ClearOverlay(updateToo: false);
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		for (int i = 0; i < gridWidth; i++)
		{
			for (int j = 0; j < gridHeight; j++)
			{
				float num = 0f;
				CellProductionInfluence cellProductionInfluenceDataClamped = World.inst.GetCellProductionInfluenceDataClamped(i, j);
				Cell cellData = World.inst.GetCellData(i, j);
				if ((cellData.landMassIdx != -1 && !Player.inst.LandMassIsAPlayerLandMass(cellData.landMassIdx)) || (cellData.landMassIdx == -1 && !showOverWater))
				{
					continue;
				}
				for (int k = 0; k < cellProductionInfluenceDataClamped.radiusBonuses.Count; k++)
				{
					RadiusBonusProduction radiusBonusProduction = cellProductionInfluenceDataClamped.radiusBonuses[k];
					if (!(radiusBonusProduction.b == null))
					{
						float num2 = (int)Mathff.DistXZ(radiusBonusProduction.b.transform.position + radiusBonusProduction.b.LocalCenter(), cellData.Center2D);
						if (num2 <= radiusBonusProduction.radiusMin)
						{
							num++;
						}
						else if (num2 <= radiusBonusProduction.radiusMax)
						{
							num += Mathff.Max((radiusBonusProduction.radiusMax - num2) / (radiusBonusProduction.radiusMax - radiusBonusProduction.radiusMin), 0.1f);
						}
					}
				}
				if (num >= 0f)
				{
					TerrainGen.inst.SetOverlayTileColor(i, j, new Color(0f, 0f, 0f, Mathff.Clamp01(num)));
				}
				else
				{
					TerrainGen.inst.SetOverlayTileColor(i, j, new Color(0f, 0f, 0f, 0f));
				}
			}
		}
		if (b == GameUI.inst.CurrPlacementMode.GetHoverBuilding())
		{
			Vector3 a = b.transform.position + b.LocalCenter();
			int num3 = (int)Mathff.Clamp(a.x - (radiusMax + 1f), 0f, World.inst.GridWidth - 1);
			int num4 = (int)Mathff.Clamp(a.x + (radiusMax + 1f), 0f, World.inst.GridWidth - 1);
			int num5 = (int)Mathff.Clamp(a.z - (radiusMax + 1f), 0f, World.inst.GridHeight - 1);
			int num6 = (int)Mathff.Clamp(a.z + (radiusMax + 1f), 0f, World.inst.GridHeight - 1);
			for (int l = num3; l <= num4; l++)
			{
				for (int m = num5; m < num6; m++)
				{
					float num7 = (int)Mathff.DistXZ(a, new Vector3((float)l + 0.5f, 0f, (float)m + 0.5f));
					float num8 = TerrainGen.inst.GetOverlayTileColor(l, m).a;
					if (num7 <= radiusMin)
					{
						num8++;
					}
					else if (num7 <= radiusMax)
					{
						num8 += Mathff.Max((radiusMax - num7) / (radiusMax - radiusMin), 0.1f);
					}
					TerrainGen.inst.SetOverlayTileColor(l, m, new Color(0f, 0f, 0f, Mathff.Clamp01(num8)));
				}
			}
		}
		Color fullProductionInfluence = Player.inst.FullProductionInfluence;
		Color noProductionInfluence = Player.inst.NoProductionInfluence;
		Color fullNegativeProductionInfluence = Player.inst.FullNegativeProductionInfluence;
		int bonus = GetBonus();
		for (int n = 0; n < gridWidth; n++)
		{
			for (int num9 = 0; num9 < gridHeight; num9++)
			{
				float a2 = TerrainGen.inst.GetOverlayTileColor(n, num9).a;
				if (a2 > 0f)
				{
					TerrainGen.inst.SetOverlayTileColor(n, num9, Color.Lerp(noProductionInfluence, (bonus < 0) ? fullNegativeProductionInfluence : fullProductionInfluence, Mathff.Clamp01(a2)));
				}
			}
		}
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}
}
