using System;
using System.Collections.Generic;
using Assets.Code.Interface;
using UnityEngine;

public class RadiusBonusBuildingProduction : MonoBehaviour, IOverlayUser
{
	[NonSerialized]
	public Building b;

	private EventHandler<OnBuildingAddRemove> eventHandler;

	public string descTerm;

	public string categoryMatch;

	public string[] uniqueNameMatch;

	public int Bonus = 1;

	public int buildingCount = 5;

	public float radius = 15f;

	internal float Mod = 1f;

	private List<Building> boostedBuildings = new List<Building>();

	private List<Building> oldBuildings = new List<Building>();

	private List<Building> scratch = new List<Building>(30);

	internal bool applied;

	private bool doEffects;

	public bool autoApplyBonus = true;

	public bool overlayWhenPlacing = true;

	public bool overlayWhenSelected = true;

	public bool showOverWater;

	private List<OneOffEffect> overlayEffects = new List<OneOffEffect>();

	private bool deferRefresh;

	public bool OverlayWhenPlacing => overlayWhenPlacing;

	public bool OverlayWhenSelected => overlayWhenSelected;

	private void OnEnable()
	{
		b = GetComponent<Building>();
		eventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
	}

	private void OnDisable()
	{
		if (eventHandler != null)
		{
			Broadcast.BuildingAddRemove.UnlistenAny(eventHandler);
		}
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (!applied || obj.targetBuilding.LandMass() != b.LandMass())
		{
			return;
		}
		Vector3 vector = transform.position + b.LocalCenter();
		Vector3 vector2 = obj.targetBuilding.Center();
		float num = Mathff.Abs(vector2.x - vector.x);
		float num2 = Mathff.Abs(vector2.z - vector.z);
		if (num < radius + 1f && num2 < radius + 1f)
		{
			if (obj.added)
			{
				DeferRefresh();
			}
			else
			{
				RefreshBoostedBuildings();
			}
		}
	}

	public int GetBonus()
	{
		return (int)((float)Bonus * Mod);
	}

	private bool IsSameAs(RadiusBonusBuildingProduction bb)
	{
		if (Bonus != bb.Bonus)
		{
			return false;
		}
		if (bb.categoryMatch != categoryMatch)
		{
			return false;
		}
		if (uniqueNameMatch.Length != bb.uniqueNameMatch.Length)
		{
			return false;
		}
		for (int i = 0; i < uniqueNameMatch.Length; i++)
		{
			if (uniqueNameMatch[i] != bb.uniqueNameMatch[i])
			{
				return false;
			}
		}
		return true;
	}

	public void RefreshBoostedBuildings()
	{
		oldBuildings.Clear();
		for (int i = 0; i < boostedBuildings.Count; i++)
		{
			Vector3 position = boostedBuildings[i].transform.position;
			World.inst.GetCellProductionInfluenceDataClamped((int)position.x, (int)position.z).radiusBonusesBuilding.Remove(this);
			oldBuildings.Add(boostedBuildings[i]);
		}
		boostedBuildings.Clear();
		scratch.Clear();
		Vector3 vector = transform.position + b.LocalCenter();
		World.inst.ForEachTileTouchingRadius(vector, radius, (int x, int z, Cell cell) =>
		{
			for (int j = 0; j < cell.OccupyingStructure.Count; j++)
			{
				bool flag = false;
				if (uniqueNameMatch != null)
				{
					for (int k = 0; k < uniqueNameMatch.Length; k++)
					{
						if (cell.OccupyingStructure[j].uniqueNameHash == uniqueNameMatch[k].GetHashCode())
						{
							flag = true;
							break;
						}
					}
				}
				if (cell.OccupyingStructure[j].categoryHash == categoryMatch.GetHashCode())
				{
					flag = true;
				}
				if (flag)
				{
					scratch.Add(cell.OccupyingStructure[j]);
				}
			}
		});
		for (int num = 0; num < buildingCount; num++)
		{
			float num2 = float.MaxValue;
			Building building = null;
			for (int num3 = 0; num3 < scratch.Count; num3++)
			{
				if (!boostedBuildings.Contains(scratch[num3]))
				{
					float num4 = Mathff.DistXZ(vector, scratch[num3].Center());
					if (num4 < num2)
					{
						num2 = num4;
						building = scratch[num3];
					}
				}
			}
			if (building != null)
			{
				boostedBuildings.Add(building);
			}
		}
		for (int num5 = 0; num5 < boostedBuildings.Count; num5++)
		{
			Vector3 position2 = boostedBuildings[num5].transform.position;
			World.inst.GetCellProductionInfluenceDataClamped((int)position2.x, (int)position2.z).radiusBonusesBuilding.Add(this);
			if (doEffects && !oldBuildings.Contains(boostedBuildings[num5]))
			{
				boostedBuildings[num5].ForEachTileInBounds((int x, int z, Cell cell) =>
				{
					OneOffEffect oneOffEffect = EffectsMan.inst.TileGodBonusEffect.CreateAndPlay(cell.Center3D);
					oneOffEffect.Color = Player.inst.FullProductionInfluence;
					oneOffEffect.Play();
				});
			}
		}
		oldBuildings.Clear();
		scratch.Clear();
	}

	private void DeferRefresh()
	{
		doEffects = !LoadSave.Loading;
		deferRefresh = true;
	}

	public void ApplyBonus()
	{
		applied = true;
		DeferRefresh();
	}

	public void RemoveBonus()
	{
		applied = false;
		for (int i = 0; i < boostedBuildings.Count; i++)
		{
			if (boostedBuildings[i] != null)
			{
				Vector3 position = boostedBuildings[i].transform.position;
				World.inst.GetCellProductionInfluenceDataClamped((int)position.x, (int)position.z).radiusBonusesBuilding.Remove(this);
			}
		}
		boostedBuildings.Clear();
	}

	private void OnDestroy()
	{
		if (!GameState.IsQuitting)
		{
			if (applied)
			{
				RemoveBonus();
			}
			ClearBuildingEffects();
		}
	}

	public void OnShutdown()
	{
		if (applied)
		{
			RemoveBonus();
		}
	}

	private void OnFinishedLoad()
	{
		if (autoApplyBonus && b.IsBuilt())
		{
			ApplyBonus();
		}
	}

	private void OnBuilt()
	{
		if (autoApplyBonus)
		{
			ApplyBonus();
		}
	}

	public void ClearBuildingEffects()
	{
		for (int i = 0; i < overlayEffects.Count; i++)
		{
			overlayEffects[i].Stop();
			overlayEffects[i].Release();
		}
		overlayEffects.Clear();
	}

	public void DrawIndividual()
	{
		Color color = Player.inst.FullProductionInfluence;
		Vector3 pos = transform.position + b.LocalCenter();
		DebugEx.DrawCircleXZ(pos, radius, Color.red, 16f, 1f);
		DebugEx.DrawCircleXZ(pos, 0.25f, Color.red, 16f, 1f);
		World.inst.ForEachTileTouchingRadius(pos, radius, (int x, int z, Cell cell) =>
		{
			float t = Mathff.DistXZ((float)x + 0.5f, (float)z + 0.5f, pos.x, pos.z) / radius;
			float a = Mathff.Lerp(0.05f, 0.25f, t);
			color.a = a;
			TerrainGen.inst.SetOverlayTileColor(x, z, color);
		});
	}

	public void DrawOverlay(Vector3 origin)
	{
		if (!b)
		{
			return;
		}
		TerrainGen.inst.ClearOverlay(updateToo: false);
		DrawIndividual();
		if ((bool)b.GetComponent<Temple>())
		{
			b.GetComponent<Temple>().GetDedicateIdx();
		}
		for (int i = 0; i < boostedBuildings.Count; i++)
		{
			Building building = boostedBuildings[i];
			building.SetInfoColor(Player.inst.FullProductionInfluence);
			TerrainGen.inst.AddBuildingToOverlay(building);
			building.ForEachTileInBounds((int x, int z, Cell cell) =>
			{
				OneOffEffect oneOffEffect = EffectsMan.inst.TileGodBonusLoopingEffect.CreateAndPlay(cell.Center3D);
				oneOffEffect.Color = Player.inst.FullProductionInfluence;
				overlayEffects.Add(oneOffEffect);
			});
		}
		TerrainGen.inst.UpdateOverlayTextures();
		TerrainGen.inst.FadeOverlay(1f);
	}

	private void OnSelectionChanged()
	{
		if (GameUI.inst.GetBuildingSelected() != b)
		{
			ClearBuildingEffects();
		}
	}

	public void Update()
	{
		if (deferRefresh)
		{
			RefreshBoostedBuildings();
			deferRefresh = false;
		}
	}
}
