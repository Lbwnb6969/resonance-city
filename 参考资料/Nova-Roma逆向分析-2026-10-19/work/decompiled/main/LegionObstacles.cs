using System;
using Drawing;
using UnityEngine;

[Serializable]
public class LegionObstacles : MonoBehaviour
{
	public LegionObstaclesObject obstacles;

	public bool edit = true;

	public void Start()
	{
		for (int i = 0; i < obstacles.gridSize; i++)
		{
			for (int j = 0; j < obstacles.gridSize; j++)
			{
				if (obstacles.grid[i + j * obstacles.gridSize])
				{
					LegionPhysicsSystem.Inst.obstacles.Add(new Vector2Int(i, j));
					LegionPhysicsSystem.Inst.obstacles.Add(new Vector2Int((int)((float)i - (float)obstacles.gridSize * 0.5f), (int)((float)j - (float)obstacles.gridSize * 0.5f)));
				}
			}
		}
	}

	public void Update()
	{
		Draw();
		if (!edit)
		{
			return;
		}
		Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
		if (!Input.GetMouseButtonDown(0) || !Physics.Raycast(ray, out var hitInfo, 1000f))
		{
			return;
		}
		Vector3 pos = hitInfo.point;
		pos += new Vector3((float)obstacles.gridSize * 0.5f, 0f, (float)obstacles.gridSize * 0.5f);
		Debug.Log(pos);
		obstacles.grid[Mathf.FloorToInt(pos.x) + Mathf.FloorToInt(pos.z) * obstacles.gridSize] = !obstacles.grid[Mathf.FloorToInt(pos.x) + Mathf.FloorToInt(pos.z) * obstacles.gridSize];
		if (obstacles.grid[Mathf.FloorToInt(pos.x) + Mathf.FloorToInt(pos.z) * obstacles.gridSize])
		{
			LegionPhysicsSystem.Inst.obstacles.Add(new Vector2Int((int)((float)Mathf.FloorToInt(pos.x) - (float)obstacles.gridSize * 0.5f), (int)((float)Mathf.FloorToInt(pos.z) - (float)obstacles.gridSize * 0.5f)));
			return;
		}
		LegionPhysicsSystem.Inst.obstacles.RemoveAll((Vector2Int v) => v.x == (int)((float)Mathf.FloorToInt(pos.x) - (float)obstacles.gridSize * 0.5f) && v.y == (int)((float)Mathf.FloorToInt(pos.z) - (float)obstacles.gridSize * 0.5f));
	}

	public void Draw()
	{
		for (int i = 0; i < obstacles.gridSize; i++)
		{
			for (int j = 0; j < obstacles.gridSize; j++)
			{
				if (obstacles.grid[i + j * obstacles.gridSize])
				{
					Drawing.Draw.ingame.SolidCircle(new Vector3((float)i + 0.5f - (float)obstacles.gridSize * 0.5f, 0f, (float)j + 0.5f - (float)obstacles.gridSize * 0.5f), Vector3.up, 0.5f, Color.white);
					Drawing.Draw.ingame.Circle(new Vector3((float)i + 0.5f - (float)obstacles.gridSize * 0.5f, 0f, (float)j + 0.5f - (float)obstacles.gridSize * 0.5f), Vector3.up, 0.5f, Color.black);
				}
			}
		}
	}
}
