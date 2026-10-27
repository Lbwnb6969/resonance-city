using System;
using System.Collections.Generic;
using Assets.Code.Interface;
using UnityEngine;

public class RadiusBonus : MonoBehaviour, IOverlayUser
{
	public delegate int HappinessFunc();

	[NonSerialized]
	public Building b;

	public int Happiness = 5;

	public float radiusMin = 15f;

	public float radiusMax = 15f;

	public int residentialTileID;

	public HappinessFunc happinessFunc;

	public HappinessFunc maxHappinessFunc;

	internal bool processed;

	[NonSerialized]
	public Vector3 center;

	internal bool applied;

	public bool autoApplyBonus = true;

	public bool VariableBonus;

	public float Mod = 1f;

	public bool overlayWhenPlacing = true;

	public bool overlayWhenSelected = true;

	private Color transparent = Color.clear;

	public bool OverlayWhenPlacing => overlayWhenPlacing;

	public bool OverlayWhenSelected => overlayWhenSelected;

	private void OnEnable()
	{
		if (happinessFunc == null)
		{
			happinessFunc = GetDefaultHappiness;
		}
		if (maxHappinessFunc == null)
		{
			maxHappinessFunc = GetDefaultMaxHappiness;
		}
		b = GetComponent<Building>();
	}

	private void OnBuilt()
	{
		center = GetComponent<Building>().Center();
	}

	private void OnFinishedLoad()
	{
		center = GetComponent<Building>().Center();
	}

	public void ApplyBonus()
	{
		applied = true;
		float radius = radiusMax;
		b.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		World.inst.ForEachTileTouchingRadiusInBounds(minX, maxX, minZ, maxZ, radius, (Vector3 originPos, int x, int z, Cell cell) =>
		{
			World.inst.GetCellInfluenceDataClamped(x, z).radiusBonuses.Add(this);
		});
	}

	public void RemoveBonus()
	{
		applied = false;
		float radius = radiusMax;
		b.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		World.inst.ForEachTileTouchingRadiusInBounds(minX, maxX, minZ, maxZ, radius, (Vector3 originPos, int x, int z, Cell cell) =>
		{
			World.inst.GetCellInfluenceDataClamped(x, z).radiusBonuses.Remove(this);
		});
	}

	public void OnShutdown()
	{
		if (applied)
		{
			RemoveBonus();
		}
	}

	private void OnDestroy()
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

	public int GetCurrentHappiness()
	{
		return happinessFunc();
	}

	public int GetMaxHappiness()
	{
		return maxHappinessFunc();
	}

	private int GetDefaultHappiness()
	{
		return (int)((float)Happiness * Mod);
	}

	private int GetDefaultMaxHappiness()
	{
		return (int)((float)Happiness * Mod);
	}

	public int GetRadialHappiness(Vector3 p)
	{
		if (!b.IsBuilt() || !b.IsOpen() || (b.WorkersForFullYield > 0 && b.WorkersAllocated <= 0))
		{
			return 0;
		}
		float num = Mathff.DistXZ(center, p);
		float num2 = 0f;
		num2 = ((radiusMax != radiusMin) ? Mathf.Max((radiusMax - num) / (radiusMax - radiusMin), 0.1f) : 1f);
		int num3 = happinessFunc();
		if (num3 > 0)
		{
			return (int)Mathff.Lerp(1f, num3, Mathff.Clamp01(num2));
		}
		return (int)Mathff.Lerp(-1f, num3, Mathff.Clamp01(num2));
	}

	public void DrawIndividual()
	{
		_ = Color.clear;
		float currHappiness = GetCurrentHappiness();
		b.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		World.inst.ForEachTileTouchingRadiusInBounds(minX, maxX, minZ, maxZ, radiusMax, (Vector3 originPos, int x, int z, Cell cell) =>
		{
			float num = Mathff.DistXZ(originPos.x, originPos.z, (float)x + 0.5f, (float)z + 0.5f);
			float a = TerrainGen.inst.GetOverlayTileColor(x, z).a;
			if (a < 1f)
			{
				Color col = Color.Lerp(t: Mathff.Clamp01((!(num <= radiusMin)) ? (a + Mathff.Max((radiusMax - num) / (radiusMax - radiusMin), 0.1f)) : (a + 1f)), a: Player.inst.NoHappinessInfluence, b: (currHappiness < 0f) ? Player.inst.FullNegativeHappinessInfluence : Player.inst.FullHappinessInfluence);
				SetColorForTile(x, z, cell, col);
			}
		});
	}

	private void SetColorForTile(int x, int z, Cell cell, Color col)
	{
		TerrainGen.inst.SetOverlayTileColorNoBuilding(x, z, col);
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			int categoryHash = cell.OccupyingStructure[i].categoryHash;
			if (categoryHash == World.houseCategoryHash || categoryHash == World.pathHash)
			{
				TerrainGen.inst.SetOverlayBuildingColorOverlapCheck(x, z, cell, col * 0.8f, applyBuildingMaterial: false);
				break;
			}
		}
	}

	public void DrawOverlay(Vector3 origin)
	{
		if (!b)
		{
			return;
		}
		TerrainGen.inst.ClearOverlay(updateToo: false);
		for (int i = 0; i < Player.inst.RadiusBonuses.Count; i++)
		{
			RadiusBonus radiusBonus = Player.inst.RadiusBonuses.data[i];
			if (radiusBonus.residentialTileID != residentialTileID)
			{
				continue;
			}
			if (radiusBonus.residentialTileID == 229)
			{
				Temple component = radiusBonus.GetComponent<Temple>();
				if (component != null && component.bonusLevel <= 0)
				{
					continue;
				}
			}
			if (radiusBonus.applied)
			{
				radiusBonus.DrawIndividual();
			}
		}
		List<Building> buildings = GameUI.inst.CurrPlacementMode.buildings;
		for (int j = 0; j < buildings.Count; j++)
		{
			RadiusBonus component2 = buildings[j].GetComponent<RadiusBonus>();
			if (!(component2 == null))
			{
				component2.DrawIndividual();
			}
		}
		TerrainGen.inst.ApplyBuildingOverlayMaterial();
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}
}
