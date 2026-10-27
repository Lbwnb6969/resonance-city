using System;
using UnityEngine;

public class ForumTile : MonoBehaviour
{
	private Building b;

	private AdjacentMesh adjMesh;

	[SerializeField]
	private GameObject stairFoundationObj;

	[SerializeField]
	private GameObject stairsPrefab;

	private int stairsPoolCount;

	private ArrayExtRef<GameObject> stairsPool = new ArrayExtRef<GameObject>(4);

	private int idleJobCount = 1;

	private Transform offset;

	private static Cell[] scratch4 = new Cell[4];

	private void Awake()
	{
		b = GetComponent<Building>();
		adjMesh = GetComponent<AdjacentMesh>();
		adjMesh.shouldConnect = ShouldConnect;
		AdjacentMesh adjacentMesh = adjMesh;
		adjacentMesh.onRotationUpdate = (AdjacentMesh.OnRotationUpdate)Delegate.Combine(adjacentMesh.onRotationUpdate, new AdjacentMesh.OnRotationUpdate(OnRotationUpdate));
		offset = b.GetOffset();
	}

	private void OnInit()
	{
		idleJobCount = SRand.Range(2, b.attractionPositions.Length);
		for (int i = 0; i < idleJobCount / 2; i++)
		{
			int num = SRand.Range(0, idleJobCount);
			Transform[] attractionPositions = b.attractionPositions;
			int num2 = i;
			Transform[] attractionPositions2 = b.attractionPositions;
			int num3 = num;
			Transform transform = b.attractionPositions[num];
			Transform transform2 = b.attractionPositions[i];
			attractionPositions[num2] = transform;
			attractionPositions2[num3] = transform2;
		}
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.attractionPositions.Length; i++)
		{
			if (!b.VerifyJobIs(i, typeof(IdleJob)))
			{
				b.SetAndAddJob(i, new IdleJob(b, IdleJob.IdleBehavior.IdleLooking));
			}
		}
	}

	private void OnBuilt()
	{
		adjMesh.RefreshSurroundingRotation(b);
	}

	private bool ShouldConnect(Cell c)
	{
		if (c == null)
		{
			return false;
		}
		Building building = GameUI.inst.CurrPlacementMode.buildingMap[c.index];
		if (building != null && building.categoryHash == World.forumHash)
		{
			return true;
		}
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			if (c.OccupyingStructure[i].categoryHash == World.forumHash || c.OccupyingStructure[i].categoryHash == World.templeHash)
			{
				return true;
			}
		}
		return false;
	}

	private void OnRotationUpdate(AdjacentMesh.AdjacentType adjtype)
	{
		stairsPoolCount = 0;
		Cell cell = b.GetCell();
		World.inst.GetNeighborCells(cell, ref scratch4);
		bool active = false;
		for (int i = 0; i < scratch4.Length; i++)
		{
			Cell cell2 = scratch4[i];
			if (cell2 == null)
			{
				continue;
			}
			bool flag = true;
			for (int j = 0; j < cell2.OccupyingStructure.Count; j++)
			{
				if (cell2.OccupyingStructure[j].categoryHash != b.categoryHash)
				{
					flag = false;
					break;
				}
			}
			for (int k = 0; k < cell2.OccupyingStructure.Count; k++)
			{
				Building building = cell2.OccupyingStructure[k];
				if (building.categoryHash != b.categoryHash)
				{
					continue;
				}
				float num = b.transform.position.y - building.transform.position.y;
				if (num > 0.05f)
				{
					active = true;
					if (flag && num < 0.8f)
					{
						GameObject stair = GetStair();
						Vector3 input = new Vector3(cell2.x - cell.x, 0f, cell2.z - cell.z);
						input.NonAllocateNormalize();
						stair.transform.rotation = Quaternion.LookRotation(input, Vector3.up);
						Util.SetActive(stair, active: true);
					}
				}
			}
		}
		Util.SetActive(stairFoundationObj, active);
		for (int num2 = stairsPool.Count - 1; num2 >= stairsPoolCount; num2--)
		{
			Util.SetActive(stairsPool.data[num2].gameObject, active: false);
		}
	}

	private GameObject GetStair()
	{
		if (stairsPoolCount == stairsPool.Count)
		{
			GameObject item = UnityEngine.Object.Instantiate(stairsPrefab, offset);
			stairsPool.Add(item);
		}
		return stairsPool.data[stairsPoolCount++];
	}
}
