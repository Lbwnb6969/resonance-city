using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class GridNumbering : MonoBehaviour
{
	public GameObject gridTextPrefab;

	private List<GameObject> gridTiles = new List<GameObject>();

	private void Start()
	{
		World.inst.worldGenerationComplete.AddListener(() =>
		{
			Regen();
		});
		Regen();
	}

	private void Regen()
	{
		foreach (GameObject gridTile in gridTiles)
		{
			Object.Destroy(gridTile);
		}
		gridTiles.Clear();
		for (int i = 0; i < World.inst.GridHeight; i++)
		{
			for (int j = 0; j < World.inst.GridWidth; j++)
			{
				GameObject gameObject = Object.Instantiate(gridTextPrefab);
				gameObject.transform.position = new Vector3((float)j + 0.5f, 0.02f, (float)i + 0.5f);
				gameObject.GetComponent<TextMeshPro>().text = $"{j},{i}";
				gridTiles.Add(gameObject);
			}
		}
	}
}
