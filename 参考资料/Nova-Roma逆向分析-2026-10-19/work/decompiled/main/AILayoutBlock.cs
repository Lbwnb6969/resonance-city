using System;
using System.Collections.Generic;
using UnityEngine;

public class AILayoutBlock
{
	[Serializable]
	public class SaveData : SaveClass<AILayoutBlock, SaveData>
	{
		public int posX;

		public int posZ;

		public int sizeX;

		public int sizeZ;

		public AIBuildingBlockType layoutType;

		public AIBuildingMeta.SaveData[] buildingMetas;

		public Type layoutObjectType;

		public bool isRotated;

		public override SaveData Pack(AILayoutBlock v)
		{
			posX = v.posX;
			posZ = v.posZ;
			sizeX = v.sizeX;
			sizeZ = v.sizeZ;
			layoutType = v.layoutType;
			buildingMetas = new AIBuildingMeta.SaveData[v.buildingTransforms.Count];
			for (int i = 0; i < v.buildingTransforms.Count; i++)
			{
				buildingMetas[i] = new AIBuildingMeta.SaveData().Pack(v.buildingTransforms[i]);
			}
			layoutObjectType = v.GetType();
			isRotated = v.IsRotated;
			return this;
		}

		public override AILayoutBlock Unpack(AILayoutBlock v)
		{
			v.posX = posX;
			v.posZ = posZ;
			v.sizeX = sizeX;
			v.sizeZ = sizeZ;
			v.layoutType = layoutType;
			v.buildingTransforms = new List<AIBuildingMeta>(buildingMetas.Length);
			for (int i = 0; i < buildingMetas.Length; i++)
			{
				v.buildingTransforms.Add(buildingMetas[i].Unpack(new AIBuildingMeta()));
			}
			v.IsRotated = isRotated;
			return v;
		}
	}

	public int posX;

	public int posZ;

	internal int sizeX;

	internal int sizeZ;

	public int largestRectangleSizeX = int.MaxValue;

	public int largestRectangleSizeZ = int.MaxValue;

	public bool isUnique;

	public bool OutlineWithRoads = true;

	public bool OutlineWithCastle = true;

	public bool IsRotated;

	public AIBuildingBlockType layoutType;

	public List<AIBuildingMeta> buildingTransforms;

	public int SizeX
	{
		get
		{
			if (!IsRotated)
			{
				return sizeX;
			}
			return sizeZ;
		}
	}

	public int SizeZ
	{
		get
		{
			if (!IsRotated)
			{
				return sizeZ;
			}
			return sizeX;
		}
	}

	public static AIBuildingBlockType ConvertTypeCode(string code)
	{
		switch (code)
		{
		case "R":
			return AIBuildingBlockType.Residential;
		case "F":
			return AIBuildingBlockType.Food;
		case "C":
			return AIBuildingBlockType.Civic;
		case "O":
			return AIBuildingBlockType.Road;
		case "X":
			return AIBuildingBlockType.Any;
		case "D":
			return AIBuildingBlockType.Castle;
		case "N":
			return AIBuildingBlockType.None;
		default:
			Debug.LogError("Invalid block type: " + code);
			return AIBuildingBlockType.Food;
		}
	}

	public static string ConvertTypeCode(AIBuildingBlockType type)
	{
		switch (type)
		{
		case AIBuildingBlockType.Residential:
			return "R";
		case AIBuildingBlockType.Food:
			return "F";
		case AIBuildingBlockType.Civic:
			return "C";
		case AIBuildingBlockType.Road:
			return "O";
		case AIBuildingBlockType.Any:
			return "X";
		case AIBuildingBlockType.Castle:
			return "D";
		case AIBuildingBlockType.None:
			return "N";
		default:
			Debug.LogError("Invalid block type: " + type);
			return "X";
		}
	}

	public void UpdateBlockRotation(bool isRotated)
	{
		if (IsRotated != isRotated)
		{
			for (int i = 0; i < buildingTransforms.Count; i++)
			{
				buildingTransforms[i].IsRotated = isRotated;
			}
		}
		IsRotated = isRotated;
	}

	public void ParseEditorCodes(AIBuildingBlockType layoutType, string codes)
	{
		this.layoutType = layoutType;
		string[] array = codes.Split(':');
		string[] array2 = array[0].Split(',');
		sizeX = int.Parse(array2[0]);
		sizeZ = int.Parse(array2[1]);
		int num = array.Length;
		buildingTransforms = new List<AIBuildingMeta>(num - 1);
		for (int i = 1; i < num; i++)
		{
			string[] array3 = array[i].Split(',');
			AIBuildingBlockType type = ConvertTypeCode(array3[0]);
			string uniqueName = "";
			if (array3.Length == 6)
			{
				uniqueName = array3[1];
			}
			int num2 = array3.Length - 4;
			int num3 = int.Parse(array3[num2 + 2]);
			int num4 = int.Parse(array3[num2 + 3]);
			buildingTransforms.Add(new AIBuildingMeta
			{
				OffsetX = int.Parse(array3[num2]),
				OffsetZ = int.Parse(array3[num2 + 1]),
				SizeX = num3,
				SizeZ = num4,
				uniqueName = uniqueName,
				type = type
			});
		}
	}

	public void GenerateTypeRectangle(int width, int height, AIBuildingBlockType type)
	{
		string empty = string.Empty;
		empty = $"{width},{height}";
		for (int i = 0; i < height; i++)
		{
			for (int j = 0; j < width; j++)
			{
				empty += $":{ConvertTypeCode(type)},{j},{i},{1},{1}";
			}
		}
		largestRectangleSizeX = width;
		largestRectangleSizeZ = height;
		ParseEditorCodes(type, empty);
	}

	public void GenerateTypeMap(AIBuildingBlockType blockType, string[][] map)
	{
		string empty = string.Empty;
		empty = $"{map.Length},{map[0].Length}";
		for (int i = 0; i < map.Length; i++)
		{
			for (int j = 0; j < map[i].Length; j++)
			{
				string text = map[i][j].Trim();
				if (string.IsNullOrEmpty(text))
				{
					continue;
				}
				int num = 1;
				int num2 = 1;
				if (text.Length > 1)
				{
					bool flag = false;
					if (text.Contains("!"))
					{
						text.Replace("!", "");
						flag = true;
					}
					Building placeableByUniqueName = GameState.inst.GetPlaceableByUniqueName(text);
					if (placeableByUniqueName != null)
					{
						num = Mathf.RoundToInt(placeableByUniqueName.size.x);
						num2 = Mathf.RoundToInt(placeableByUniqueName.size.z);
						if (flag)
						{
							int num3 = num;
							num = num2;
							num2 = num3;
						}
					}
					else
					{
						Debug.LogError("Invalid prefab name in map definition: " + text);
					}
				}
				empty += $":{text},{i},{j},{num},{num2}";
			}
		}
		ParseEditorCodes(blockType, empty);
	}

	public virtual bool BlockValidityTest(int posX, int posZ)
	{
		return true;
	}

	public virtual void OnBlockPlaced(AILayout layout)
	{
	}

	public virtual void Init()
	{
	}
}
