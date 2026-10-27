using Drawing;
using UnityEngine;

public class EditorGrid : MonoBehaviourGizmos
{
	public Color color = new Color(1f, 1f, 1f, 0.01f);

	public int cellSize = 15;

	public int gridSize = 5000;

	public bool showGrid;
}
