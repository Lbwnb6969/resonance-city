using System.Collections.Generic;
using UnityEngine;

public class BlockStackUpdateSystem : MonoBehaviour
{
	private static BlockStackUpdateSystem _inst;

	private Cell[] tempNeighbors = new Cell[8];

	private Dictionary<MeshCollider, Mesh> pendingColliderUpdates = new Dictionary<MeshCollider, Mesh>();

	private Dictionary<Transform, Quaternion> pendingColliderRotationResets = new Dictionary<Transform, Quaternion>();

	private HashSet<Cell> pendingWaterCells = new HashSet<Cell>();

	private HashSet<Cell> pendingBlockStackCells = new HashSet<Cell>();

	private readonly HashSet<Cell> markedWithNeighbors = new HashSet<Cell>();

	public static BlockStackUpdateSystem inst
	{
		get
		{
			if (_inst == null)
			{
				_inst = new GameObject("BlockStackUpdateSystem").AddComponent<BlockStackUpdateSystem>();
			}
			return _inst;
		}
	}

	public bool SuppressColliderUpdates { get; set; }

	public bool FlushColliderUpdatesAfterProcess { get; set; }

	public bool SuppressWaterUpdates { get; set; }

	public bool FlushWaterUpdatesAfterProcess { get; set; }

	public void QueueColliderUpdate(MeshCollider collider, Mesh mesh)
	{
		if (collider != null)
		{
			pendingColliderUpdates[collider] = mesh;
		}
	}

	public void QueueColliderRotationReset(Transform colliderTransform, Quaternion originalRotation)
	{
		if (colliderTransform != null && !pendingColliderRotationResets.ContainsKey(colliderTransform))
		{
			pendingColliderRotationResets[colliderTransform] = originalRotation;
		}
	}

	public void FlushColliderUpdates()
	{
		foreach (KeyValuePair<MeshCollider, Mesh> pendingColliderUpdate in pendingColliderUpdates)
		{
			if (pendingColliderUpdate.Key != null)
			{
				pendingColliderUpdate.Key.sharedMesh = pendingColliderUpdate.Value;
			}
		}
		pendingColliderUpdates.Clear();
		foreach (KeyValuePair<Transform, Quaternion> pendingColliderRotationReset in pendingColliderRotationResets)
		{
			if (pendingColliderRotationReset.Key != null)
			{
				pendingColliderRotationReset.Key.localRotation = pendingColliderRotationReset.Value;
			}
		}
		pendingColliderRotationResets.Clear();
	}

	public void ClearColliderUpdates()
	{
		pendingColliderUpdates.Clear();
		pendingColliderRotationResets.Clear();
	}

	public void MarkWaterDirty(Cell cell)
	{
		if (cell != null)
		{
			if (SuppressWaterUpdates)
			{
				pendingWaterCells.Add(cell);
			}
			else
			{
				TerrainGen.inst.RecalcWaterObstructionForArea(cell.x - 1, cell.z - 1, 3, 3);
			}
		}
	}

	public void FlushWaterUpdates()
	{
		if (pendingWaterCells.Count == 0)
		{
			return;
		}
		int num = int.MaxValue;
		int num2 = int.MaxValue;
		int num3 = int.MinValue;
		int num4 = int.MinValue;
		foreach (Cell pendingWaterCell in pendingWaterCells)
		{
			if (pendingWaterCell.x < num)
			{
				num = pendingWaterCell.x;
			}
			if (pendingWaterCell.z < num2)
			{
				num2 = pendingWaterCell.z;
			}
			if (pendingWaterCell.x > num3)
			{
				num3 = pendingWaterCell.x;
			}
			if (pendingWaterCell.z > num4)
			{
				num4 = pendingWaterCell.z;
			}
		}
		TerrainGen.inst.RecalcWaterObstructionForArea(num - 1, num2 - 1, num3 - num + 3, num4 - num2 + 3);
		pendingWaterCells.Clear();
	}

	public void ClearWaterUpdates()
	{
		pendingWaterCells.Clear();
	}

	public void MarkBlockStackDirty(Cell cell)
	{
		if (cell != null)
		{
			pendingBlockStackCells.Add(cell);
		}
	}

	public void MarkBlockStackAndNeighborsDirty(Cell cell)
	{
		if (cell == null || !markedWithNeighbors.Add(cell))
		{
			return;
		}
		pendingBlockStackCells.Add(cell);
		World.inst.GetNeighborCellsExtended(cell, ref tempNeighbors);
		for (int i = 0; i < tempNeighbors.Length; i++)
		{
			if (tempNeighbors[i] != null)
			{
				pendingBlockStackCells.Add(tempNeighbors[i]);
			}
		}
	}

	public void FlushBlockStackUpdates()
	{
		if (pendingBlockStackCells.Count == 0)
		{
			return;
		}
		foreach (Cell pendingBlockStackCell in pendingBlockStackCells)
		{
			BlockBuilding.UpdateBlockStack(pendingBlockStackCell);
		}
		pendingBlockStackCells.Clear();
		markedWithNeighbors.Clear();
	}

	public void Reset()
	{
		pendingBlockStackCells.Clear();
		markedWithNeighbors.Clear();
		pendingWaterCells.Clear();
		pendingColliderUpdates.Clear();
		pendingColliderRotationResets.Clear();
		SuppressColliderUpdates = false;
		SuppressWaterUpdates = false;
		FlushColliderUpdatesAfterProcess = false;
		FlushWaterUpdatesAfterProcess = false;
	}

	private void LateUpdate()
	{
		if (!GameState.IsQuitting)
		{
			FlushBlockStackUpdates();
			if (FlushColliderUpdatesAfterProcess)
			{
				FlushColliderUpdatesAfterProcess = false;
				FlushColliderUpdates();
			}
			if (FlushWaterUpdatesAfterProcess)
			{
				FlushWaterUpdatesAfterProcess = false;
				FlushWaterUpdates();
			}
		}
	}
}
