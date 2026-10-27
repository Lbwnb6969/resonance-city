using System;
using System.Collections.Generic;
using Assets;
using UnityEngine;

public class General : Tickable
{
	[NonSerialized]
	public ArmyWages armyWages;

	public MeshRenderer mesh;

	public UnitIGUI unitUI;

	public Mesh flagMesh;

	[NonSerialized]
	public ObjectHighlighter generalHighlight;

	public MeshRenderer[] meshes;

	private bool _visible = true;

	[NonSerialized]
	public ArmySystem.Army army;

	public bool visible => _visible;

	internal void UpdateMaterial(int teamId)
	{
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(teamId);
		if (landmassOwnerByTeamId != null)
		{
			mesh.material = World.inst.liverySets[landmassOwnerByTeamId.bannerIdx].armyMaterial;
		}
	}

	private void Start()
	{
		armyWages = GetComponent<ArmyWages>();
		if (armyWages != null)
		{
			armyWages.missedWageFunc = Disband;
			armyWages.teamId = army.teamId;
			UpdateMaterial(army.teamId);
		}
		unitUI = UnityEngine.Object.Instantiate(Player.inst.unitIGUIprefab).GetComponent<UnitIGUI>();
		unitUI.Init(army.teamId, flagMesh);
		List<MeshRenderer> list = new List<MeshRenderer>();
		for (int i = 0; i < transform.childCount; i++)
		{
			MeshRenderer component = transform.GetChild(i).GetComponent<MeshRenderer>();
			if ((bool)component)
			{
				list.Add(component);
			}
		}
		list.Add(unitUI.flag.GetComponent<MeshRenderer>());
		list.Add(unitUI.flagPole.GetComponent<MeshRenderer>());
		for (int j = 0; j < unitUI.selectors.Count; j++)
		{
			list.Add(unitUI.selectors[j].GetComponent<MeshRenderer>());
		}
		generalHighlight = ObjectHighlighter.SetupOutlines(gameObject, list, null);
	}

	public override void OnDisableInternal()
	{
		base.OnDisableInternal();
		if (unitUI != null)
		{
			UnityEngine.Object.Destroy(unitUI.gameObject);
			unitUI = null;
		}
		if (generalHighlight != null)
		{
			generalHighlight.Release();
			generalHighlight = null;
		}
	}

	public void SetVisible(bool v)
	{
		if (v != _visible)
		{
			EffectsMan.inst.FOWBurst.CreateAndPlay(transform.position);
		}
		_visible = v;
		for (int i = 0; i < meshes.Length; i++)
		{
			meshes[i].enabled = v;
		}
		if ((bool)unitUI)
		{
			unitUI.gameObject.SetActive(v);
		}
	}

	public void Disband()
	{
		if (!army.locked)
		{
			army.Disband();
		}
	}

	public override void Tick(float dt, int currFrame)
	{
		float num = 0f;
		Vector3 position = transform.position;
		Cell cellDataClamped = World.inst.GetCellDataClamped(position);
		for (int i = 0; i < cellDataClamped.OccupyingStructure.Count; i++)
		{
			Building building = cellDataClamped.OccupyingStructure[i];
			num += (building.Stackable ? ((float)building.StackHeight * 0.25f) : 0f);
		}
		bool active = num <= position.y + 0.2f || (cellDataClamped.OccupyingStructure.Count <= 0 && cellDataClamped.Type == TerrainType.Water);
		if (army != null && !ArmySystem.inst.IsAlive(army))
		{
			active = false;
		}
		if (unitUI != null)
		{
			unitUI.UpdateActive(active);
			unitUI.transform.position = position;
		}
	}
}
