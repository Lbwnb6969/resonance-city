using System.Collections.Generic;
using UnityEngine;

public class FogOfWar : MonoBehaviour
{
	public class FOWCube
	{
		public enum Status
		{
			Uninitialized,
			IdleIn,
			AnimatingIn,
			IdleOut,
			AnimatingOut
		}

		public Status status;

		public Vector3 pos;

		public Cell cell;

		public Vector3 origScale;

		public Vector3 currScale;

		public Quaternion rot;

		public float animTime;

		public float delayTime;

		public int sIdx;

		public int aIdx;
	}

	public static FogOfWar inst;

	private ArrayExt<Matrix4x4[]> matrices = new ArrayExt<Matrix4x4[]>(10);

	private ArrayExt<ArrayExt<FOWCube>> cubesPerLandmass = new ArrayExt<ArrayExt<FOWCube>>(10);

	private bool[] staticVisPerLandmass;

	private bool[] dynamicVisPerLandmass;

	private bool[] visibility;

	private bool[] inDynamicVisList;

	private FOWCube[] cubeGrid;

	private ArrayExt<FOWCube> updateList = new ArrayExt<FOWCube>(5000);

	private int gridWidth;

	private int gridHeight;

	private Color[] colors;

	private Color[] offColors;

	public Texture2D fogTex;

	private ArrayExt<FOWCube> dynamicVis = new ArrayExt<FOWCube>(100);

	private int minx;

	private int minz;

	private int maxx;

	private int maxz;

	private bool lastHideFogOfWar;

	public bool dirty;

	public Mesh mesh;

	public Material material;

	private void Start()
	{
		inst = this;
	}

	public void RefreshVisible(int lm, bool visible, bool force = false)
	{
		if (staticVisPerLandmass[lm] == visible && !force)
		{
			return;
		}
		dirty = true;
		staticVisPerLandmass[lm] = visible;
		ArrayExt<FOWCube> arrayExt = cubesPerLandmass.data[lm];
		if (force)
		{
			for (int i = 0; i < arrayExt.Count; i++)
			{
				FOWCube fOWCube = arrayExt.data[i];
				if (inDynamicVisList[fOWCube.cell.z * gridWidth + fOWCube.cell.x])
				{
					dynamicVis.RemoveSwap(fOWCube);
					inDynamicVisList[fOWCube.cell.z * gridWidth + fOWCube.cell.x] = false;
				}
				UpdateCellVisibility(fOWCube.cell, visible);
				UpdateHeightFor(fOWCube);
				if (!visible)
				{
					fOWCube.currScale = fOWCube.origScale;
					fOWCube.status = FOWCube.Status.IdleIn;
				}
				else
				{
					fOWCube.currScale = Vector3.zero;
					fOWCube.status = FOWCube.Status.IdleOut;
				}
				Mathff.SetTRS(ref matrices.data[fOWCube.sIdx][fOWCube.aIdx], fOWCube.pos, fOWCube.rot, fOWCube.currScale);
			}
			return;
		}
		for (int j = 0; j < arrayExt.Count; j++)
		{
			if (visible)
			{
				TryAddToUpdateList(arrayExt.data[j], FOWCube.Status.AnimatingOut);
			}
			else
			{
				TryAddToUpdateList(arrayExt.data[j], FOWCube.Status.AnimatingIn);
			}
		}
	}

	private void UpdateHeightFor(FOWCube newCube)
	{
		if (Player.inst.keep == null)
		{
			newCube.origScale = new Vector3(0f, 0f, 0f);
		}
		else
		{
			newCube.origScale = new Vector3(1f, 1f, 1f);
		}
	}

	public void Reset()
	{
		gridWidth = World.inst.GridWidth;
		gridHeight = World.inst.GridHeight;
		if ((bool)fogTex)
		{
			Object.Destroy(fogTex);
		}
		fogTex = new Texture2D(gridWidth, gridHeight, TextureFormat.RGBA32, mipChain: false);
		fogTex.name = "FogOfWarTexture";
		fogTex.filterMode = FilterMode.Point;
		colors = new Color[gridWidth * gridHeight];
		offColors = new Color[gridWidth * gridHeight];
		for (int i = 0; i < offColors.Length; i++)
		{
			offColors[i] = Color.white;
			colors[i] = Color.white;
		}
		dynamicVis.Clear();
		updateList.Clear();
		cubesPerLandmass.Clear();
		cubeGrid = new FOWCube[gridWidth * gridHeight];
		visibility = new bool[gridWidth * gridHeight];
		inDynamicVisList = new bool[gridWidth * gridHeight];
		staticVisPerLandmass = new bool[World.inst.NumLandMasses];
		dynamicVisPerLandmass = new bool[World.inst.NumLandMasses];
		int num = 0;
		for (int j = 0; j < World.inst.NumLandMasses; j++)
		{
			cubesPerLandmass.Add(new ArrayExt<FOWCube>(1000));
			ArrayExt<Cell> arrayExt = World.inst.cellsToLandmass[j];
			for (int k = 0; k < arrayExt.Count; k++)
			{
				FOWCube fOWCube = new FOWCube();
				fOWCube.cell = arrayExt.data[k];
				fOWCube.pos = arrayExt.data[k].Center2D;
				fOWCube.pos.y += 0.0249f;
				fOWCube.sIdx = num / 1023;
				fOWCube.aIdx = num - num / 1023 * 1023;
				int x = arrayExt.data[k].x;
				int z = arrayExt.data[k].z;
				cubeGrid[z * gridWidth + x] = fOWCube;
				UpdateHeightFor(fOWCube);
				num++;
				cubesPerLandmass.data[j].Add(fOWCube);
			}
		}
		matrices.Clear();
		int num2 = Mathf.CeilToInt((float)(gridWidth * gridHeight) / 1023f);
		for (int l = 0; l < num2; l++)
		{
			matrices.Add(new Matrix4x4[1023]);
		}
	}

	private bool BuildingVisible(Building b)
	{
		b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				if (IsVisible(j, i))
				{
					return true;
				}
			}
		}
		return false;
	}

	private void UpdateCellVisibility(Cell cell, bool visible)
	{
		if (cell.StructureCompareUniqueNameAll(World.spilloverHash))
		{
			return;
		}
		List<Building> occupyingStructure = cell.OccupyingStructure;
		List<Building> subStructure = cell.SubStructure;
		if (visible)
		{
			for (int i = 0; i < occupyingStructure.Count; i++)
			{
				occupyingStructure[i].SetVisibleForFog(val: true);
			}
			for (int j = 0; j < subStructure.Count; j++)
			{
				subStructure[j].SetVisibleForFog(val: true);
			}
			return;
		}
		for (int k = 0; k < occupyingStructure.Count; k++)
		{
			if (!BuildingVisible(occupyingStructure[k]))
			{
				occupyingStructure[k].SetVisibleForFog(val: false);
			}
		}
		for (int l = 0; l < subStructure.Count; l++)
		{
			if (!BuildingVisible(subStructure[l]))
			{
				subStructure[l].SetVisibleForFog(val: false);
			}
		}
	}

	private bool TryAddToUpdateList(FOWCube cube, FOWCube.Status newStatus)
	{
		if (((newStatus == FOWCube.Status.AnimatingIn && cube.status != FOWCube.Status.IdleIn) || (newStatus == FOWCube.Status.AnimatingOut && cube.status != FOWCube.Status.IdleOut)) && cube.status != newStatus)
		{
			if (cube.cell.OccupyingStructure.Count > 0)
			{
				for (int i = 0; i < cube.cell.OccupyingStructure.Count; i++)
				{
					Building building = cube.cell.OccupyingStructure[i];
					building.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
					if (building.seenByPlayer)
					{
						continue;
					}
					for (int j = minX; j <= maxX; j++)
					{
						for (int k = minZ; k <= maxZ; k++)
						{
							for (int l = 0; (float)l < building.size.y; l++)
							{
								EffectsMan.inst.FOWBurst.CreateAndPlay(new Vector3((float)j + 0.5f, 0.5f + (float)l + building.GetPos().y, (float)k + 0.5f));
							}
						}
					}
				}
			}
			if (newStatus == FOWCube.Status.AnimatingOut)
			{
				UpdateCellVisibility(cube.cell, visible: true);
			}
			if (newStatus == FOWCube.Status.AnimatingIn)
			{
				visibility[cube.cell.z * gridWidth + cube.cell.x] = false;
				UpdateCellVisibility(cube.cell, visible: false);
			}
			if (newStatus != FOWCube.Status.AnimatingOut || cube.status != FOWCube.Status.AnimatingIn)
			{
				updateList.Add(cube);
				cube.animTime = 0f;
			}
			cube.status = newStatus;
			return true;
		}
		return false;
	}

	public bool HasAnyVisibilityOnLandmass(int lm)
	{
		if (lm != -1)
		{
			if (!staticVisPerLandmass[lm])
			{
				return dynamicVisPerLandmass[lm];
			}
			return true;
		}
		return false;
	}

	private void SetDynamicVisible(Vector3 p, float radius, int gridWidth, int gridHeight)
	{
		int num = (int)Mathff.Clamp(p.x - radius, 0f, gridWidth - 1);
		int num2 = (int)Mathff.Clamp(p.x + radius, 0f, gridWidth - 1);
		int num3 = (int)Mathff.Clamp(p.z - radius, 0f, gridHeight - 1);
		int num4 = (int)Mathff.Clamp(p.z + radius, 0f, gridHeight - 1);
		float x = p.x;
		float z = p.z;
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num; j <= num2; j++)
			{
				if (!(((float)j + 0.5f - x) * ((float)j + 0.5f - x) + ((float)i + 0.5f - z) * ((float)i + 0.5f - z) <= radius * radius))
				{
					continue;
				}
				FOWCube fOWCube = cubeGrid[i * gridWidth + j];
				if (fOWCube != null)
				{
					if (TryAddToUpdateList(fOWCube, FOWCube.Status.AnimatingOut))
					{
						dirty = true;
					}
					dynamicVisPerLandmass[fOWCube.cell.landMassIdx] = true;
					if (!staticVisPerLandmass[fOWCube.cell.landMassIdx])
					{
						if (!inDynamicVisList[i * gridWidth + j])
						{
							dynamicVis.Add(fOWCube);
							inDynamicVisList[i * gridWidth + j] = true;
						}
						fOWCube.delayTime = 4f;
					}
				}
				visibility[i * gridWidth + j] = true;
			}
		}
	}

	private void Update()
	{
		_ = LoadSave.Loading;
	}

	public void UpdateShaders()
	{
		int num = gridWidth;
		Color white = Color.white;
		Color clear = Color.clear;
		for (int i = 0; i < World.inst.NumLandMasses; i++)
		{
			ArrayExt<Cell> arrayExt = World.inst.cellsToLandmass[i];
			if (staticVisPerLandmass[i])
			{
				int j = 0;
				for (int count = arrayExt.Count; j < count; j++)
				{
					Cell cell = arrayExt.data[j];
					int num2 = cell.z * num + cell.x;
					colors[num2] = white;
				}
				continue;
			}
			int k = 0;
			for (int count2 = arrayExt.Count; k < count2; k++)
			{
				Cell cell2 = arrayExt.data[k];
				int num3 = cell2.z * num + cell2.x;
				if (visibility[num3])
				{
					colors[num3] = white;
				}
				else
				{
					colors[num3] = clear;
				}
			}
		}
		if (Creative.inst.IsCreativeOptionOn(9) || Player.inst.keep == null)
		{
			fogTex.SetPixels(offColors);
		}
		else
		{
			fogTex.SetPixels(colors);
		}
		fogTex.Apply(updateMipmaps: false, makeNoLongerReadable: false);
		Shader.SetGlobalInt("_Width", num);
		Shader.SetGlobalInt("_Height", gridHeight);
		Shader.SetGlobalTexture("_Fog", fogTex);
	}

	internal bool IsVisible(int x, int z)
	{
		if (Creative.inst.IsCreativeOptionOn(9))
		{
			return true;
		}
		if (Player.inst.keep == null)
		{
			return true;
		}
		if (z <= 0 || x <= 0 || x >= gridWidth || z >= gridHeight)
		{
			return true;
		}
		int landMassIdx = World.inst.GetCellDataClamped(x, z).landMassIdx;
		if (landMassIdx != -1)
		{
			if (!visibility[z * gridWidth + x])
			{
				return staticVisPerLandmass[landMassIdx];
			}
			return true;
		}
		return true;
	}

	internal bool IsVisible(Vector3 pos)
	{
		return IsVisible((int)pos.x, (int)pos.z);
	}
}
