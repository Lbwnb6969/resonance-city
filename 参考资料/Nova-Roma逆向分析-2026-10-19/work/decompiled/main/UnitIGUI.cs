using System.Collections.Generic;
using UnityEngine;

public class UnitIGUI : MonoBehaviour
{
	public List<Transform> selectors;

	public GameObject flagPole;

	public GameObject flag;

	public GameObject moraleContainer;

	public HealthBar healthBar;

	private void OnDestroy()
	{
		if ((bool)healthBar)
		{
			Object.Destroy(healthBar.gameObject);
		}
	}

	internal void UpdateActive(bool active)
	{
		Util.SetActive(flagPole, active);
		Util.SetActive(flag, active);
	}

	public void SetMorale(int count)
	{
		for (int i = 0; i < moraleContainer.transform.childCount; i++)
		{
			Util.SetActive(moraleContainer.transform.GetChild(i).gameObject, i < count);
		}
	}

	internal void UpdateMaterial(int teamId)
	{
		LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(teamId);
		if (landmassOwnerByTeamId != null)
		{
			flag.GetComponent<MeshRenderer>().material = World.inst.liverySets[landmassOwnerByTeamId.bannerIdx].armyMaterialUnlit;
		}
	}

	internal void Init(int teamId, Mesh flagMesh, int numSelectors = 1)
	{
		SetMorale(0);
		if (flagMesh != null)
		{
			flag.GetComponent<MeshFilter>().mesh = flagMesh;
		}
		healthBar = Object.Instantiate(Player.inst.healthBarPrefab);
		UpdateMaterial(teamId);
		if (numSelectors == 0)
		{
			for (int i = 0; i < selectors.Count; i++)
			{
				selectors[i].gameObject.SetActive(value: false);
			}
			return;
		}
		for (int j = 1; j < numSelectors; j++)
		{
			GameObject gameObject = Object.Instantiate(selectors[0].gameObject);
			gameObject.transform.SetParent(transform);
			selectors.Add(gameObject.transform);
		}
	}
}
