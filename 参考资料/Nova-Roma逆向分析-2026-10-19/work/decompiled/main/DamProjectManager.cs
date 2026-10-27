using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class DamProjectManager : MonoBehaviour
{
	[Serializable]
	public class DamProjectManagerSaveData : SaveClass<DamProjectManager, DamProjectManagerSaveData>
	{
		public List<DamPlanningProject.DamPlanningProjectSaveData> projects = new List<DamPlanningProject.DamPlanningProjectSaveData>();

		public override DamProjectManagerSaveData Pack(DamProjectManager obj)
		{
			projects = obj.projects.Select((DamPlanningProject x) => new DamPlanningProject.DamPlanningProjectSaveData().Pack(x)).ToList();
			return this;
		}

		public override DamProjectManager Unpack(DamProjectManager obj)
		{
			obj.projects.Clear();
			foreach (DamPlanningProject.DamPlanningProjectSaveData project2 in projects)
			{
				Cell cell = null;
				if (project2.damsToAdd.Count > 0)
				{
					cell = World.inst.GetCellDataClamped(project2.damsToAdd[0].position);
				}
				else if (project2.damsToRemove.Count > 0)
				{
					cell = World.inst.GetCellDataClamped(project2.damsToRemove[0].position);
				}
				if (cell != null && !inst.IsCellPartOfProject(cell, out var _))
				{
					DamPlanningProject damPlanningProject = DamPlanningProject.CreateNewProject();
					project2.Unpack(damPlanningProject);
					damPlanningProject.RecalcWaterObstruction();
				}
			}
			return obj;
		}
	}

	public static DamProjectManager inst;

	public Mesh scaffoldMesh;

	public Material scaffoldMaterial;

	private List<DamPlanningProject> projects = new List<DamPlanningProject>();

	private List<DamPlanningProject> projectsToRemove = new List<DamPlanningProject>();

	public void Awake()
	{
		inst = this;
	}

	public bool IsCellPartOfProject(Cell cell, out DamPlanningProject project)
	{
		for (int i = 0; i < projects.Count; i++)
		{
			if (projects[i].IsCellPartOfProject(cell))
			{
				project = projects[i];
				return true;
			}
		}
		project = null;
		return false;
	}

	public void MarkSpillwayManuallyAdjusted(int cellIndex)
	{
		for (int i = 0; i < projects.Count; i++)
		{
			if (!projects[i].Done && projects[i].plannedSpillwayHeights.ContainsKey(cellIndex))
			{
				projects[i].MarkSpillwayManuallyAdjusted(cellIndex);
			}
		}
	}

	public void RegisterProject(DamPlanningProject project)
	{
		projects.Add(project);
	}

	public void Update()
	{
		foreach (DamPlanningProject project in projects)
		{
			if (!project.Done)
			{
				project.Tick();
			}
			if (project.Done)
			{
				projectsToRemove.Add(project);
			}
		}
		foreach (DamPlanningProject item in projectsToRemove)
		{
			projects.Remove(item);
			UnityEngine.Object.Destroy(item.gameObject);
		}
		projectsToRemove.Clear();
	}

	public void Reset()
	{
		foreach (DamPlanningProject project in projects)
		{
			UnityEngine.Object.Destroy(project.gameObject);
		}
		projects.Clear();
	}
}
