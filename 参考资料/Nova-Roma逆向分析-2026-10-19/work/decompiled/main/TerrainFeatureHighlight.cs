using UnityEngine;
using cakeslice;

public class TerrainFeatureHighlight
{
	private ArrayExt<Outline> outlines = new ArrayExt<Outline>(8);

	private int currentCount;

	private int previousCount;

	public void UpdateHoveredCell(Cell targetCell, Cell selectedCell)
	{
		previousCount = currentCount;
		currentCount = 0;
		if (selectedCell != null)
		{
			OutlineFeaturesInSystem(World.inst.treeSystem, selectedCell, 1);
			OutlineFeaturesInSystem(World.inst.rockScatterSystem, selectedCell, 1);
		}
		if (targetCell != null && targetCell != selectedCell)
		{
			OutlineFeaturesInSystem(World.inst.treeSystem, targetCell);
			OutlineFeaturesInSystem(World.inst.rockScatterSystem, targetCell);
		}
		if (currentCount < previousCount)
		{
			for (int i = currentCount; i < outlines.Count; i++)
			{
				outlines.data[i].Disable();
			}
		}
	}

	public void AddCells(int minX, int maxX, int minZ, int maxZ)
	{
		previousCount = currentCount;
		currentCount = 0;
		for (int i = minX; i < maxX; i++)
		{
			for (int j = minZ; j < maxZ; j++)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(i, j);
				if (cellDataUnsafe != null)
				{
					OutlineFeaturesInSystem(World.inst.treeSystem, cellDataUnsafe);
					OutlineFeaturesInSystem(World.inst.rockScatterSystem, cellDataUnsafe);
				}
			}
		}
		if (currentCount < previousCount)
		{
			for (int k = currentCount; k < outlines.Count; k++)
			{
				outlines.data[k].Disable();
			}
		}
	}

	private void OutlineFeature(int idx, Mesh m, Vector3 pos, Quaternion rot, Vector3 scale, int color = 0)
	{
		if (outlines.Count == currentCount)
		{
			outlines.Add(new Outline(m));
		}
		OutlineEffect.Instance.AddBatchOutline(m, idx, color, Matrix4x4.TRS(pos, rot, scale));
	}

	private bool OutlineFeaturesInSystem(TreeSystem system, Cell targetCell, int color = 0)
	{
		if (targetCell == null)
		{
			return false;
		}
		TreeSystem.TreeCellData treeCellDataAt = system.GetTreeCellDataAt(targetCell.x, targetCell.z);
		if (treeCellDataAt == null)
		{
			return false;
		}
		bool result = false;
		for (int i = 0; i < treeCellDataAt.TreeIds.Length; i++)
		{
			int num = treeCellDataAt.TreeIds[i];
			if (num != -1)
			{
				TreeSystem.Chunk chunk = system.GetChunk(targetCell.x, targetCell.z);
				TreeSystem.TreeData treeData = chunk.itemData[num];
				int idx = (int)chunk.meshIdxs[num];
				OutlineFeature(idx, system.treeMesh, treeData.pos, treeData.rotation, treeData.scale, color);
				result = true;
			}
		}
		return result;
	}

	public void Reset()
	{
		currentCount = 0;
		previousCount = 0;
		for (int i = 0; i < outlines.Count; i++)
		{
			outlines.data[i].Disable();
		}
	}
}
