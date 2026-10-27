using UnityEngine;

public class LeviStatue : Tickable
{
	private Building b;

	private Timer treeTimer = new Timer(30f);

	public override void Tick(float dt, int currFrame)
	{
		if (!b)
		{
			b = GetComponent<Building>();
		}
		if (treeTimer.Update(dt) && b.IsBuilt())
		{
			Vector3 vector = GetComponent<Building>().Center();
			int num = ((SRand.Range(0, 100) > 25) ? 2 : 4);
			int num2 = SRand.Range(-num, num);
			int num3 = SRand.Range(-num, num);
			Cell cellDataClamped = World.inst.GetCellDataClamped(new Vector3(num2, 0f, num3) + vector);
			if (TreeGrowth.IsValidForTreePlanting(cellDataClamped))
			{
				World.inst.treeSystem.GrowTree(cellDataClamped);
			}
		}
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.attractionPositions.Length; i++)
		{
			if (!b.VerifyJobIs(i, typeof(IdleJob)))
			{
				b.SetAndAddJob(i, new IdleJob(b, IdleJob.IdleBehavior.Looking));
			}
		}
	}
}
