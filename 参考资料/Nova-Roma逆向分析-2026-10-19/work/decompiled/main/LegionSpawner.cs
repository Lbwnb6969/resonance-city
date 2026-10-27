using System.Collections.Generic;
using UnityEngine;

public class LegionSpawner : MonoBehaviour
{
	public LegionGroup prefab;

	public int level;

	public int[] levels = new int[6] { 3, 4, 5, 6, 7, 8 };

	public List<LegionGroup> groups = new List<LegionGroup>();

	private Timer spawnTimer = new Timer(15f);

	private void Update()
	{
	}

	private void SpawnLegions()
	{
	}

	public void OnGUI()
	{
	}
}
