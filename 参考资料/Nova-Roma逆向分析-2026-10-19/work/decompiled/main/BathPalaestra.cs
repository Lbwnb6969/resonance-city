using System;
using UnityEngine;

public class BathPalaestra : MonoBehaviour
{
	[NonSerialized]
	public Building b;

	[NonSerialized]
	public DynamicMesh dMesh;

	public GameObject meshObj;

	private void Awake()
	{
		b = GetComponent<Building>();
		dMesh = GetComponent<DynamicMesh>();
	}

	public void OnBuildingPlacement(bool undo)
	{
		if (!undo)
		{
			if (LoadSave.Loading && b.IsBuilt())
			{
				BathManager.inst.Register(b);
				dMesh.OnAdded();
			}
		}
		else if (b.IsBuilt())
		{
			BathManager.inst.Deregister(b);
			dMesh.OnRemoved();
		}
	}

	public void OnBuilt()
	{
		BathManager.inst.Register(b);
		dMesh.OnAdded();
	}

	public void OnAddJobs()
	{
		for (int i = 0; i < b.attractionPositions.Length; i++)
		{
			if (!b.VerifyJobIs(i, typeof(IdleJob)))
			{
				IdleJob idleJob = new IdleJob(b, IdleJob.IdleBehavior.Wander);
				idleJob.SetWanderSettings(0.1f, 0.1f);
				b.SetAndAddJob(i, idleJob);
			}
		}
	}
}
