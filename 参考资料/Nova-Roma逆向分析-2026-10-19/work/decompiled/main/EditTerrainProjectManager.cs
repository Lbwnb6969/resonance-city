using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class EditTerrainProjectManager : MonoBehaviour
{
	[Serializable]
	public class EditTerrainProjectManagerSaveData : SaveClass<EditTerrainProjectManager, EditTerrainProjectManagerSaveData>
	{
		public List<EditTerrainProject.EditTerrainProjectSaveData> projects = new List<EditTerrainProject.EditTerrainProjectSaveData>();

		public override EditTerrainProjectManagerSaveData Pack(EditTerrainProjectManager obj)
		{
			projects = obj.projects.Select((EditTerrainProject x) => new EditTerrainProject.EditTerrainProjectSaveData().Pack(x)).ToList();
			return this;
		}

		public override EditTerrainProjectManager Unpack(EditTerrainProjectManager obj)
		{
			obj.projects.Clear();
			foreach (EditTerrainProject.EditTerrainProjectSaveData project in projects)
			{
				EditTerrainProject editTerrainProject = EditTerrainProject.CreateNewEmptyProject();
				project.Unpack(editTerrainProject);
				obj.projects.Add(editTerrainProject);
			}
			return obj;
		}
	}

	public static EditTerrainProjectManager inst;

	public static int editterrainzoneHash = "editterrainzone".GetHashCode();

	private List<EditTerrainProject> projects = new List<EditTerrainProject>();

	public void Awake()
	{
		inst = this;
	}

	public void RegisterProject(EditTerrainProject project)
	{
		projects.Add(project);
	}

	public void DeregisterProject(EditTerrainProject project)
	{
		projects.Remove(project);
	}

	public void Update()
	{
		for (int i = 0; i < projects.Count; i++)
		{
			projects[i].Tick();
		}
	}

	public bool IsCellPartOfProject(Cell c, out EditTerrainProject project)
	{
		for (int i = 0; i < projects.Count; i++)
		{
			if (projects[i].editTerrainZones.ContainsKey(c.index))
			{
				project = projects[i];
				return true;
			}
		}
		project = null;
		return false;
	}

	public float CalculateHighestEndHeightFor(int vertIndex)
	{
		float num = float.MinValue;
		foreach (EditTerrainProject project in projects)
		{
			if (project.workPointIndexMap.TryGetValue(vertIndex, out var value))
			{
				num = Mathf.Max(num, project.endHeights[value]);
			}
		}
		return num;
	}

	public float CalculateNewestEndHeightFor(int vertIndex)
	{
		float result = float.MinValue;
		foreach (EditTerrainProject project in projects)
		{
			if (project.workPointIndexMap.TryGetValue(vertIndex, out var value))
			{
				result = project.endHeights[value];
			}
		}
		return result;
	}

	public void Reset()
	{
		foreach (EditTerrainProject project in projects)
		{
			UnityEngine.Object.Destroy(project.gameObject);
		}
		projects.Clear();
	}
}
