using System.Collections.Generic;
using I2.Loc;
using UnityEngine;

public class CastellumAquae : AqueductBuilding, IWorkerUIDisplay, IOutputInfo
{
	public static Mesh waterMesh;

	[HideInInspector]
	private GameObject waterBlock;

	public Material material;

	public Transform filledPosition;

	public Transform emptyPosition;

	public float filledT;

	private bool errorNoLinesConnected;

	private bool errorNoInputLines;

	private bool errorNoWaterFlowing;

	private void Awake()
	{
		b.PlacementValidaton = PlacementValidation;
		waterBlock = new GameObject("WaterBlock");
		waterBlock.transform.SetParent(transform.GetChild(0));
		waterBlock.AddComponent<MeshFilter>();
		waterBlock.AddComponent<MeshRenderer>();
		if (waterMesh == null)
		{
			waterMesh = new Mesh();
			List<Vector3> list = new List<Vector3>();
			list.Add(new Vector3(-0.25f, 0f, -0.25f));
			list.Add(new Vector3(-0.25f, 0f, 0.25f));
			list.Add(new Vector3(0.25f, 0f, -0.25f));
			list.Add(new Vector3(0.25f, 0f, 0.25f));
			List<Vector2> list2 = new List<Vector2>();
			list2.Add(new Vector2(0.25f, 0.25f));
			list2.Add(new Vector2(0.25f, 0.75f));
			list2.Add(new Vector2(0.75f, 0.25f));
			list2.Add(new Vector2(0.75f, 0.75f));
			List<int> list3 = new List<int>();
			list3.Add(0);
			list3.Add(1);
			list3.Add(2);
			list3.Add(2);
			list3.Add(1);
			list3.Add(3);
			waterMesh.Clear();
			waterMesh.SetVertices(list);
			waterMesh.SetIndices(list3, MeshTopology.Triangles, 0);
			waterMesh.SetUVs(0, list2);
			waterMesh.RecalculateBounds();
			waterMesh.RecalculateNormals();
			waterMesh.RecalculateTangents();
		}
		waterBlock.GetComponent<MeshFilter>().sharedMesh = waterMesh;
		waterBlock.GetComponent<MeshRenderer>().sharedMaterial = material;
	}

	private void PlacementValidation(ref PlacementValidationResult result)
	{
		Cell cell = b.GetCell();
		if (result != PlacementValidationResult.ExistingStructure)
		{
			return;
		}
		bool flag = false;
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			if (cell.OccupyingStructure[i].categoryHash == World.pathHash)
			{
				flag = true;
				continue;
			}
			flag = false;
			break;
		}
		if (flag)
		{
			result = PlacementValidationResult.Valid;
		}
	}

	public void UpdateState()
	{
		errorNoLinesConnected = false;
		errorNoInputLines = false;
		errorNoWaterFlowing = false;
		if (b.thought == null)
		{
			return;
		}
		b.thought.visible = false;
		if (aqueductLines.Count == 0)
		{
			b.thought.thought = ThoughtBubbleSystem.Thought.Aqueduct;
			b.thought.visible = true;
			errorNoLinesConnected = true;
			return;
		}
		int num = 0;
		foreach (AqueductLine aqueductLine in aqueductLines)
		{
			if (aqueductLine.IsProvidingWaterTo(this))
			{
				num++;
			}
		}
		if (num == 0)
		{
			b.thought.thought = ThoughtBubbleSystem.Thought.Aqueduct;
			b.thought.visible = true;
			errorNoInputLines = true;
		}
		else if (waterFlow <= 0f)
		{
			b.thought.thought = ThoughtBubbleSystem.Thought.WaterCritical;
			b.thought.visible = true;
			errorNoWaterFlowing = true;
		}
	}

	public string GetError()
	{
		if (errorNoLinesConnected)
		{
			return LocalizationManager.GetTranslation("watersplitter_error_nolinesconnected");
		}
		if (errorNoInputLines)
		{
			return LocalizationManager.GetTranslation("watersplitter_error_noinputlines");
		}
		if (errorNoWaterFlowing)
		{
			return LocalizationManager.GetTranslation("watersplitter_error_nowaterflowing");
		}
		return string.Empty;
	}

	public void Update()
	{
		float num = Time.deltaTime * 1.5f;
		filledT = Mathf.Clamp01(filledT + ((waterFlow > 0f) ? num : (0f - num)));
		waterBlock.transform.position = Vector3.Lerp(emptyPosition.position, filledPosition.position, filledT);
	}

	private void OnBuilt()
	{
		UpdateState();
	}

	public override void UpdateWaterFlow()
	{
		base.UpdateWaterFlow();
		UpdateState();
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}
}
