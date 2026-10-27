using System.Collections.Generic;
using UnityEngine;

public class CloserHomeFinder : MonoBehaviour
{
	public static CloserHomeFinder inst;

	private ArrayExtRef<Villager> candidates = new ArrayExtRef<Villager>(200);

	private Villager currCandidate;

	private FloodFillCrawler commuteSearch = new FloodFillCrawler();

	private Vector3 homePos;

	private Vector3 workPos;

	private int minX;

	private int maxX;

	private int minZ;

	private int maxZ;

	private float maxDimension;

	private float origDist;

	private void Start()
	{
		inst = this;
	}

	public void Reset()
	{
		candidates.Clear();
		commuteSearch = new FloodFillCrawler();
		commuteSearch.cellsPerFrame = 250;
		currCandidate = null;
	}

	private void ClearCandidate()
	{
		candidates.Remove(currCandidate);
		currCandidate = null;
		commuteSearch.Reset();
	}

	public void OnPersonRemoved(Villager v)
	{
		if (currCandidate == v)
		{
			ClearCandidate();
		}
	}

	public void AddCandidate(Villager v)
	{
		if (!candidates.Contains(v))
		{
			candidates.Add(v);
		}
	}

	private void Update()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		if (candidates.Count > 0 && currCandidate == null)
		{
			currCandidate = candidates.Last();
			commuteSearch.Reset();
			if (currCandidate.NeedsCloserHome())
			{
				origDist = Mathff.Dist(currCandidate.Residence.GetPosition(), currCandidate.job.employer.GetPosition());
			}
		}
		if (!(currCandidate != null))
		{
			return;
		}
		if (currCandidate.NeedsCloserHome())
		{
			homePos = currCandidate.Residence.GetPosition();
			workPos = currCandidate.job.employer.GetPosition();
			maxDimension = Mathff.Max(Mathff.Abs(homePos.x - workPos.x), Mathff.Abs(homePos.z - workPos.z));
			maxDimension = (int)maxDimension - 1;
			minX = (int)(workPos.x - maxDimension);
			maxX = (int)(workPos.x + maxDimension);
			minZ = (int)(workPos.z - maxDimension);
			maxZ = (int)(workPos.z + maxDimension);
			commuteSearch.Tick(workPos, VisitCell);
			if (commuteSearch.finishedCrawl)
			{
				candidates.Remove(currCandidate);
				candidates.Insert(0, currCandidate);
				currCandidate = null;
			}
			else if (commuteSearch.exitedEarly)
			{
				Mathff.Dist(currCandidate.Residence.GetPosition(), currCandidate.job.employer.GetPosition());
				ClearCandidate();
			}
		}
		else
		{
			ClearCandidate();
		}
	}

	private bool VisitCell(Cell cell, ref List<Cell> openSet)
	{
		if (Mathff.DistSqrdXZ(cell.x, cell.z, workPos.x, workPos.z) <= maxDimension * maxDimension && currCandidate.landMass == cell.landMassIdx && cell.Type != TerrainType.Obstruction)
		{
			if (cell.Type != TerrainType.Water && cell.StructureCompareCategory(World.houseCategoryHash) && cell.OccupyingStructure[0].IsBuilt())
			{
				Building building = cell.OccupyingStructure[0];
				if (building.GetComponent<IResidence>() != currCandidate.Residence)
				{
					Home component = building.GetComponent<Home>();
					if (Player.inst.TrySwapResidents(currCandidate.Residence, component, currCandidate, homePos))
					{
						return false;
					}
					building.GetBoundingFootprint(out var num, out var num2, out var num3, out var num4);
					for (int i = num2; i <= num4; i++)
					{
						for (int j = num; j <= num3; j++)
						{
							commuteSearch.visited[i * World.inst.GridWidth + j] = true;
						}
					}
				}
			}
			if (cell.x - 1 > minX)
			{
				commuteSearch.AddCellToOpenSet(World.inst.GetCellDataClamped(cell.x - 1, cell.z));
			}
			if (cell.x + 1 < maxX)
			{
				commuteSearch.AddCellToOpenSet(World.inst.GetCellDataClamped(cell.x + 1, cell.z));
			}
			if (cell.z - 1 > minZ)
			{
				commuteSearch.AddCellToOpenSet(World.inst.GetCellDataClamped(cell.x, cell.z - 1));
			}
			if (cell.z + 1 < maxZ)
			{
				commuteSearch.AddCellToOpenSet(World.inst.GetCellDataClamped(cell.x, cell.z + 1));
			}
		}
		return true;
	}
}
