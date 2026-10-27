using UnityEngine;

[CreateAssetMenu(fileName = "Obstacles", menuName = "ScriptableObjects/LegionObstaclesObject", order = 1)]
public class LegionObstaclesObject : ScriptableObject
{
	public int gridSize = 100;

	public bool[] grid;

	public void Init()
	{
		grid = new bool[gridSize * gridSize];
		for (int i = 0; i < gridSize * gridSize; i++)
		{
			grid[i] = false;
		}
	}
}
