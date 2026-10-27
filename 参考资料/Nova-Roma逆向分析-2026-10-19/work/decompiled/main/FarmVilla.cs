using System.Collections.Generic;
using UnityEngine;

public class FarmVilla : Tickable
{
	private const int frameSpread = 90;

	private int updateFrame = SRand.srand.Next(0, 90);

	public RadiusBonusBuildingProduction rb;

	public Building b;

	public Home home;

	public override void Tick(float dt, int currFrame)
	{
		base.Tick(dt, currFrame);
		if (currFrame % 90 == updateFrame && b.IsBuilt())
		{
			RehomeNearby();
		}
	}

	private void RehomeNearby()
	{
		b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = 1; (float)i < rb.radius; i++)
		{
			int num = Mathff.Clamp(minX - i, 0, World.inst.GridWidth - 1);
			int num2 = Mathff.Clamp(minZ - i, 0, World.inst.GridHeight - 1);
			int num3 = Mathff.Clamp(maxX + i, 0, World.inst.GridWidth - 1);
			int num4 = Mathff.Clamp(maxZ + i, 0, World.inst.GridHeight - 1);
			for (int j = num2; j <= num4; j++)
			{
				for (int k = num; k <= num3; k++)
				{
					if (k != num && k != num3 && j != num2 && j != num4)
					{
						continue;
					}
					Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(k, j);
					for (int l = 0; l < cellDataUnsafe.OccupyingStructure.Count; l++)
					{
						Building building = cellDataUnsafe.OccupyingStructure[l];
						if (building.categoryHash == World.houseCategoryHash || building.categoryHash == World.shopHash)
						{
							continue;
						}
						for (int m = 0; m < building.jobs.Count; m++)
						{
							if (!building.jobs[m].HasEmployee() || building.jobs[m].Employee.Residence == home || (object)(building.jobs[m].Employee.Residence as MonoBehaviour)?.GetComponent<FarmVilla>() != null)
							{
								continue;
							}
							bool flag = home.GetAvailableResidentialSlots() > 0;
							if (!flag)
							{
								flag = TryEvictForDistance();
							}
							if (flag)
							{
								Villager employee = building.jobs[m].Employee;
								if (employee.Residence == null)
								{
									Player.inst.Homeless.Remove(employee);
								}
								employee.LeaveHome();
								home.AddResident(employee);
							}
						}
					}
				}
			}
		}
	}

	private bool TryEvictForDistance()
	{
		Vector3 vector = b.Center();
		bool flag = false;
		float num = (rb.radius + 1f) * (rb.radius + 1f);
		List<Villager> residents = home.Residents;
		for (int i = 0; i < residents.Count; i++)
		{
			if (residents[i].job != null)
			{
				if (Mathff.DistSqrdXZ(residents[i].job.employer.GetPosition(), vector) > num)
				{
					flag = true;
				}
			}
			else
			{
				flag = true;
			}
			if (flag)
			{
				Player.inst.Homeless.Add(residents[i]);
				residents[i].LeaveHome();
				break;
			}
		}
		return flag;
	}
}
