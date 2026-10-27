using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class AILayout
{
	[Serializable]
	public struct TempInvalidZone
	{
		public int x;

		public int z;

		public int radius;

		public float life;
	}

	public enum IslandSize
	{
		Small = 0,
		Medium = 30,
		Large = 35,
		ExtraLarge = 40
	}

	public struct BlockOption(AILayoutBlock block, float dist)
	{
		public AILayoutBlock block = block;

		public float dist = dist;
	}

	[Serializable]
	public class AILayoutSaveData : SaveClass<AILayout, AILayoutSaveData>
	{
		public SerializableVector3 kingdomStart;

		public SerializableVector3 kingdomGridStart;

		public int landmass;

		public int width;

		public int height;

		public AILayoutBlock.SaveData[] layoutBlockData;

		public GridCell[][] gridKnowledge;

		public GridManager grids;

		public List<TempInvalidZone> invalidZones;

		public override AILayoutSaveData Pack(AILayout v)
		{
			kingdomStart = v.KingdomStart;
			landmass = v.LandMass;
			width = v.width;
			height = v.height;
			layoutBlockData = new AILayoutBlock.SaveData[v.layoutBlocks.Count];
			for (int i = 0; i < v.layoutBlocks.Count; i++)
			{
				layoutBlockData[i] = new AILayoutBlock.SaveData().Pack(v.layoutBlocks[i]);
			}
			grids = v.Grids;
			kingdomGridStart = v.KingdomGridStart;
			invalidZones = new List<TempInvalidZone>();
			for (int j = 0; j < v.invalidZones.Count; j++)
			{
				invalidZones.Add(v.invalidZones.data[j]);
			}
			return this;
		}

		public AILayout Unpack(AILayout v, AIKingdom kingdom)
		{
			v.Grids = grids;
			v.Setup(width, height, landmass, kingdomStart, kingdom);
			for (int i = 0; i < layoutBlockData.Length; i++)
			{
				Type type = layoutBlockData[i].layoutObjectType;
				if (type == null)
				{
					type = typeof(AILayoutBlock);
				}
				v.layoutBlocks.Add(layoutBlockData[i].Unpack((AILayoutBlock)Activator.CreateInstance(type)));
			}
			for (int j = 0; j < v.aiCells.Length; j++)
			{
				AICell aICell = v.aiCells[j];
				for (int k = 0; k < v.layoutBlocks.Count; k++)
				{
					AILayoutBlock aILayoutBlock = v.layoutBlocks[k];
					if (aICell.x >= aILayoutBlock.posX && aICell.z >= aILayoutBlock.posZ && aICell.x < aILayoutBlock.posX + aILayoutBlock.SizeX && aICell.z < aILayoutBlock.posZ + aILayoutBlock.SizeZ)
					{
						aICell.blockReference = aILayoutBlock;
					}
					for (int l = 0; l < v.layoutBlocks[k].buildingTransforms.Count; l++)
					{
						AIBuildingMeta aIBuildingMeta = v.layoutBlocks[k].buildingTransforms[l];
						if (aICell.x >= aIBuildingMeta.PosX && aICell.z >= aIBuildingMeta.PosZ && aICell.x < aIBuildingMeta.PosX + aIBuildingMeta.SizeX && aICell.z < aIBuildingMeta.PosZ + aIBuildingMeta.SizeZ)
						{
							aICell.buildingMeta = aIBuildingMeta;
						}
					}
				}
			}
			if (kingdomGridStart != Vector3.zero)
			{
				v.KingdomGridStart = kingdomGridStart;
			}
			else
			{
				v.KingdomGridStart = kingdomStart;
			}
			if (invalidZones != null)
			{
				v.invalidZones = new ArrayExt<TempInvalidZone>(invalidZones.Count);
				for (int m = 0; m < invalidZones.Count; m++)
				{
					v.invalidZones.Add(invalidZones[m]);
				}
			}
			else
			{
				v.invalidZones = new ArrayExt<TempInvalidZone>(1);
			}
			return v;
		}

		public override AILayout Unpack(AILayout obj)
		{
			throw new NotImplementedException();
		}
	}

	private ArrayExt<TempInvalidZone> invalidZones = new ArrayExt<TempInvalidZone>(10);

	private int width;

	private int height;

	public Vector3 KingdomStart;

	public Vector3 KingdomGridStart;

	public int LandMass;

	public GridManager Grids;

	public AICell[] aiCells;

	public DefenseCell[] defCells;

	public List<AILayoutBlock> layoutBlocks;

	public AIKingdom kingdom;

	public AIIntentionManager IntentionManager;

	private Dictionary<string, List<Type>> uniqueBuildingLookup = new Dictionary<string, List<Type>>();

	private Dictionary<AIBuildingBlockType, List<AILayoutBlock>> blockTypeLookup = new Dictionary<AIBuildingBlockType, List<AILayoutBlock>>();

	public const int ROADS_PER_FRAME = 3;

	internal List<Cell> deferredRoads = new List<Cell>();

	private List<List<AILayoutBlock>> sortedLayoutBlocks = new List<List<AILayoutBlock>>();

	public int residentialCheckRadius = 4;

	public int foodCheckRadius = 4;

	public const int MAX_CHECK_RADIUS = 128;

	public const int CHECK_RADIUS_INCREMENT = 4;

	private int landmassReferenceSize = -1;

	private int testidx = 400;

	private Color[] cArray = new Color[4]
	{
		Color.white,
		Color.green,
		Color.red,
		Color.magenta
	};

	private Cell[] scratchCells = new Cell[4];

	private float drawHeight = 0.1f;

	private ArrayExt<Vector3> scratch = new ArrayExt<Vector3>(32);

	private Cell[] scratchCells4 = new Cell[4];

	private bool[] isRoad = new bool[4];

	private DefenseCell[] scratchDCell4 = new DefenseCell[4];

	private List<BlockOption> nearbyBlocks = new List<BlockOption>(8);

	private Cell[] scratchCells8 = new Cell[8];

	private Cell[] scratchCells12 = new Cell[12];

	public int LandmassReferenceSize
	{
		get
		{
			if (landmassReferenceSize == -1)
			{
				landmassReferenceSize = (int)Mathf.Sqrt(World.inst.cellsToLandmass[LandMass].Count);
			}
			return landmassReferenceSize;
		}
	}

	public void AddInvalidZone(int _x, int _z)
	{
		int num = 75;
		int num2 = 7;
		int num3 = num2 + num2;
		for (int i = 0; i < invalidZones.Count; i++)
		{
			if ((invalidZones.data[i].x - _x) * (invalidZones.data[i].x - _x) + (invalidZones.data[i].z - _z) * (invalidZones.data[i].z - _z) < num3 * num3)
			{
				invalidZones.data[i].life = num;
			}
		}
		invalidZones.Add(new TempInvalidZone
		{
			x = _x,
			z = _z,
			radius = num2,
			life = num
		});
		MarkInvalidForZone(_x, _z, num2, invalid: true);
	}

	private void MarkInvalidForZone(int x, int z, int radius, bool invalid)
	{
		int num = Mathff.Clamp(x - 10, 0, World.inst.GridWidth - 1);
		int num2 = Mathff.Clamp(z - 10, 0, World.inst.GridHeight - 1);
		int num3 = Mathff.Clamp(x + 10, 0, World.inst.GridWidth - 1);
		int num4 = Mathff.Clamp(z + 10, 0, World.inst.GridHeight - 1);
		for (int i = num2; i <= num4; i++)
		{
			for (int j = num; j <= num3; j++)
			{
				if ((float)((x - j) * (x - j) + (z - i) * (z - i)) <= (float)(radius * radius))
				{
					aiCells[i * World.inst.GridWidth + j].invalid = invalid;
				}
			}
		}
	}

	public void UpdateInvalidZones(float dt)
	{
		for (int i = 0; i < invalidZones.Count; i++)
		{
			invalidZones.data[i].life -= dt;
			if (invalidZones.data[i].life < 0f)
			{
				MarkInvalidForZone(invalidZones.data[i].x, invalidZones.data[i].z, invalidZones.data[i].radius, invalid: false);
				invalidZones.RemoveAt(i);
				i--;
			}
		}
	}

	public void AddDeferredRoad(Cell c)
	{
		if (!deferredRoads.Contains(c))
		{
			deferredRoads.Add(c);
		}
	}

	public void Setup(int width, int height, int landmass, Vector3 kingdomStart, AIKingdom aiKingdom)
	{
		if (Grids == null)
		{
			Grids = new GridManager(width, height);
		}
		LandMass = landmass;
		KingdomStart = kingdomStart;
		kingdom = aiKingdom;
		IntentionManager = kingdom.IntentionManager;
		AIKingdom.AddToLandmassMap(landmass, IntentionManager.Kingdom);
		layoutBlocks = new List<AILayoutBlock>();
		this.width = width;
		this.height = height;
		aiCells = Grids.GetGrid<AICell>();
		defCells = Grids.GetGrid<DefenseCell>();
		for (int i = 0; i < kingdom.personality.BlockStamps.Length; i++)
		{
			ProcessBlockData(kingdom.personality.BlockStamps[i]);
		}
		if (!uniqueBuildingLookup.ContainsKey(World.greatHallName))
		{
			uniqueBuildingLookup.Add(World.greatHallName, new List<Type> { typeof(AL_CastleBlock3x3_GreatHall) });
		}
	}

	private void ProcessBlockData(AILayoutBlock block)
	{
		for (int i = 0; i < block.buildingTransforms.Count; i++)
		{
			string uniqueName = block.buildingTransforms[i].uniqueName;
			if (!uniqueBuildingLookup.ContainsKey(uniqueName))
			{
				uniqueBuildingLookup.Add(uniqueName, new List<Type>());
			}
			if (!uniqueBuildingLookup[uniqueName].Contains(block.GetType()))
			{
				uniqueBuildingLookup[uniqueName].Add(block.GetType());
			}
			AIBuildingBlockType type = block.buildingTransforms[i].type;
			if (!blockTypeLookup.ContainsKey(type))
			{
				blockTypeLookup.Add(type, new List<AILayoutBlock>());
			}
			if (!blockTypeLookup[type].Contains(block))
			{
				blockTypeLookup[type].Add(block);
			}
			AIBuildingBlockType layoutType = block.layoutType;
			if (!blockTypeLookup.ContainsKey(layoutType))
			{
				blockTypeLookup.Add(layoutType, new List<AILayoutBlock>());
			}
			if (!blockTypeLookup[layoutType].Contains(block))
			{
				blockTypeLookup[layoutType].Add(block);
			}
		}
	}

	public AICell GetAICell(int x, int z)
	{
		if (x >= 0 && x < width && z >= 0 && z < height)
		{
			return aiCells[x + z * width];
		}
		return null;
	}

	public AICell GetAICell(Cell c)
	{
		return aiCells[c.x + c.z * width];
	}

	public void GetNeighborAICells(AICell cell, ref AICell[] array)
	{
		array[0] = GetAICell(cell.x + 1, cell.z);
		array[1] = GetAICell(cell.x, cell.z + 1);
		array[2] = GetAICell(cell.x - 1, cell.z);
		array[3] = GetAICell(cell.x, cell.z - 1);
	}

	public DefenseCell GetDefenceCell(int x, int z)
	{
		if (x >= 0 && x < width && z >= 0 && z < height)
		{
			return defCells[x + z * width];
		}
		return null;
	}

	public DefenseCell GetDefenceCell(Cell c)
	{
		return defCells[c.x + c.z * width];
	}

	public void GetNeighborDefenceCells(DefenseCell cell, ref DefenseCell[] array)
	{
		array[0] = GetDefenceCell(cell.x + 1, cell.z);
		array[1] = GetDefenceCell(cell.x, cell.z + 1);
		array[2] = GetDefenceCell(cell.x - 1, cell.z);
		array[3] = GetDefenceCell(cell.x, cell.z - 1);
	}

	public void GetNeighborDefenceCellsExtended(DefenseCell cell, ref DefenseCell[] array)
	{
		array[0] = GetDefenceCell(cell.x + 1, cell.z);
		array[1] = GetDefenceCell(cell.x + 1, cell.z + 1);
		array[2] = GetDefenceCell(cell.x, cell.z + 1);
		array[3] = GetDefenceCell(cell.x - 1, cell.z + 1);
		array[4] = GetDefenceCell(cell.x - 1, cell.z);
		array[5] = GetDefenceCell(cell.x - 1, cell.z - 1);
		array[6] = GetDefenceCell(cell.x, cell.z - 1);
		array[7] = GetDefenceCell(cell.x + 1, cell.z - 1);
	}

	public bool PlaceNewBlockContainingUniqueName(string uniqueName, out AILayoutBlock newBlock, int idealX, int idealZ, int checkRadius = 100)
	{
		newBlock = null;
		bool flag = uniqueBuildingLookup.ContainsKey(uniqueName);
		List<Type> list = null;
		if (flag)
		{
			list = uniqueBuildingLookup[uniqueName];
			int num = int.MaxValue;
			if (LandmassReferenceSize < 30)
			{
				num = 9;
			}
			else if (LandmassReferenceSize < 35)
			{
				num = 21;
			}
			for (int i = 0; i < list.Count; i++)
			{
				AILayoutBlock blockOfType = GetBlockOfType(list[i]);
				if (blockOfType == null)
				{
					return false;
				}
				if (blockOfType.SizeX * blockOfType.SizeZ <= num)
				{
					if (blockOfType is AL_ForesterStamp aL_ForesterStamp)
					{
						aL_ForesterStamp.avoidPlacingForesterOnLand = kingdom.avoidPlacingForesterOnLand;
					}
					if (blockOfType is AL_GraveStamp3x3 aL_GraveStamp3x)
					{
						aL_GraveStamp3x.avoidPlacingOnFertile = kingdom.avoidPlacingGravesOnFertile;
					}
					if (PlaceNewBlock(blockOfType, out newBlock, idealX, idealZ, checkRadius))
					{
						return true;
					}
				}
			}
			if (uniqueName.GetHashCode() == World.cemeteryHash || uniqueName.GetHashCode() == World.cemeteryKeeperHash)
			{
				kingdom.avoidPlacingGravesOnFertile = false;
			}
			newBlock = null;
			return false;
		}
		return false;
	}

	public AILayoutBlock GetBlockOfType(Type type)
	{
		AILayoutBlock[] blockStamps = kingdom.personality.BlockStamps;
		for (int i = 0; i < blockStamps.Length; i++)
		{
			if (blockStamps[i].GetType() == type)
			{
				return blockStamps[i];
			}
		}
		return null;
	}

	public AILayoutBlock CopyLayoutBlock(AILayoutBlock template)
	{
		AILayoutBlock aILayoutBlock = (AILayoutBlock)Activator.CreateInstance(template.GetType());
		aILayoutBlock.buildingTransforms = new List<AIBuildingMeta>(template.buildingTransforms.Count);
		for (int i = 0; i < template.buildingTransforms.Count; i++)
		{
			AIBuildingMeta aIBuildingMeta = template.buildingTransforms[i];
			aILayoutBlock.buildingTransforms.Add(new AIBuildingMeta
			{
				parentPosX = aIBuildingMeta.parentPosX,
				parentPosZ = aIBuildingMeta.parentPosZ,
				SizeX = aIBuildingMeta.sizeX,
				SizeZ = aIBuildingMeta.sizeZ,
				OffsetX = aIBuildingMeta.offsetX,
				OffsetZ = aIBuildingMeta.offsetZ,
				inDevelopment = false,
				uniqueName = aIBuildingMeta.uniqueName,
				type = aIBuildingMeta.type,
				IsRotated = aIBuildingMeta.IsRotated
			});
		}
		aILayoutBlock.posX = template.posX;
		aILayoutBlock.posZ = template.posZ;
		aILayoutBlock.sizeX = template.sizeX;
		aILayoutBlock.sizeZ = template.sizeZ;
		aILayoutBlock.largestRectangleSizeX = template.largestRectangleSizeX;
		aILayoutBlock.largestRectangleSizeZ = template.largestRectangleSizeZ;
		aILayoutBlock.isUnique = template.isUnique;
		aILayoutBlock.OutlineWithRoads = template.OutlineWithRoads;
		aILayoutBlock.OutlineWithCastle = template.OutlineWithCastle;
		aILayoutBlock.IsRotated = template.IsRotated;
		aILayoutBlock.layoutType = template.layoutType;
		return aILayoutBlock;
	}

	public bool PlaceNewBlockOfType(Building buildingToFit, AIBuildingBlockType blockType, int idealX, int idealZ, out AILayoutBlock placedBlock, int checkRadius = 400)
	{
		bool flag = uniqueBuildingLookup.ContainsKey(buildingToFit.UniqueName);
		List<Type> list = null;
		if (flag)
		{
			list = uniqueBuildingLookup[buildingToFit.UniqueName];
		}
		bool flag2 = uniqueBuildingLookup.ContainsKey("");
		List<Type> list2 = null;
		if (flag2)
		{
			list2 = uniqueBuildingLookup[""];
		}
		int num = Mathf.CeilToInt(buildingToFit.size.x / 3f) * 3;
		num += num / 3 - 1;
		int num2 = Mathf.CeilToInt(buildingToFit.size.z / 3f) * 3;
		num2 += num2 / 3 - 1;
		sortedLayoutBlocks.Clear();
		int num3 = int.MaxValue;
		int num4 = int.MaxValue;
		if (LandmassReferenceSize < 30)
		{
			num4 = 9;
		}
		else if (LandmassReferenceSize < 35)
		{
			num4 = 21;
		}
		for (int i = 0; i < blockTypeLookup[blockType].Count; i++)
		{
			AILayoutBlock aILayoutBlock = blockTypeLookup[blockType][i];
			int num5 = aILayoutBlock.SizeX * aILayoutBlock.SizeZ;
			if ((num5 > num4 && num4 > num * num2) || ((aILayoutBlock.SizeX < num || aILayoutBlock.SizeZ < num2) && (aILayoutBlock.SizeX < num2 || aILayoutBlock.SizeZ < num || ((aILayoutBlock.largestRectangleSizeX < num || aILayoutBlock.largestRectangleSizeZ < num2) && (aILayoutBlock.largestRectangleSizeX < num2 || aILayoutBlock.largestRectangleSizeZ < num)))))
			{
				continue;
			}
			Type type = aILayoutBlock.GetType();
			if ((flag && list.Contains(type)) || (flag2 && list2.Contains(type)))
			{
				if (num3 != num5)
				{
					sortedLayoutBlocks.Add(new List<AILayoutBlock>());
				}
				sortedLayoutBlocks.Last().Add(aILayoutBlock);
				num3 = num5;
			}
		}
		placedBlock = null;
		bool flag3 = false;
		do
		{
			int startIndex = 4;
			for (int j = 0; j < sortedLayoutBlocks.Count; j++)
			{
				int num6 = SRand.Range(0, sortedLayoutBlocks[j].Count);
				for (int k = 0; k < sortedLayoutBlocks[j].Count; k++)
				{
					AILayoutBlock aILayoutBlock2 = sortedLayoutBlocks[j][num6];
					if (aILayoutBlock2 is AL_ResidentialStamp aL_ResidentialStamp)
					{
						aL_ResidentialStamp.avoidPlacingResidentialOnFertile = kingdom.avoidPlacingResidentialOnFertile;
					}
					switch (blockType)
					{
					case AIBuildingBlockType.Food:
						checkRadius = foodCheckRadius;
						startIndex = Mathff.Max(4, checkRadius - 4);
						break;
					case AIBuildingBlockType.Residential:
						checkRadius = residentialCheckRadius;
						startIndex = Mathff.Max(4, checkRadius - 4);
						break;
					}
					if (PlaceNewBlock(aILayoutBlock2, out placedBlock, idealX, idealZ, checkRadius, startIndex))
					{
						flag3 = true;
						break;
					}
					if (!sortedLayoutBlocks[j][num6].isUnique)
					{
						break;
					}
					num6 = (num6 + 1) % sortedLayoutBlocks[j].Count;
				}
				if (flag3)
				{
					break;
				}
			}
			if (flag3)
			{
				continue;
			}
			switch (blockType)
			{
			case AIBuildingBlockType.Food:
				foodCheckRadius += 4;
				break;
			case AIBuildingBlockType.Residential:
				residentialCheckRadius += 4;
				if (!kingdom.maintainWallDefense.firstWallComplete)
				{
					int num7 = Mathff.Max(4, Mathf.FloorToInt((float)LandmassReferenceSize * 0.1f) / 4 * 4);
					if (residentialCheckRadius >= num7 && foodCheckRadius >= num7)
					{
						kingdom.maintainWallDefense.UpdateCastleWalls(num7);
						kingdom.maintainWallDefense.firstWallComplete = true;
					}
				}
				else if (!kingdom.avoidPlacingResidentialOnFertile && !kingdom.maintainWallDefense.secondWallComplete)
				{
					int num8 = Mathff.Clamp(Mathf.FloorToInt((float)LandmassReferenceSize * 0.5f) / 4 * 4, 8, 12);
					if (residentialCheckRadius >= num8 && foodCheckRadius >= num8)
					{
						kingdom.maintainWallDefense.UpdateCastleWalls(num8);
						kingdom.maintainWallDefense.secondWallComplete = true;
					}
				}
				break;
			}
		}
		while (!flag3 && ((blockType == AIBuildingBlockType.Residential && residentialCheckRadius < 128) || (blockType == AIBuildingBlockType.Food && foodCheckRadius < 128)));
		if (!flag3)
		{
			if (blockType == AIBuildingBlockType.Residential)
			{
				kingdom.avoidPlacingResidentialOnFertile = false;
				residentialCheckRadius = 8;
			}
			placedBlock = null;
		}
		return flag3;
	}

	private bool IsBlockValidAt(AILayoutBlock block, int ix, int iz, int gridWidth, int gridHeight, Cell[] worldCells, AICell[] cells, bool rotate90)
	{
		int num = block.sizeX;
		int num2 = block.sizeZ;
		if (rotate90)
		{
			num = block.sizeZ;
			num2 = block.sizeX;
		}
		bool flag = true;
		for (int i = 0; i < num2; i++)
		{
			for (int j = 0; j < num; j++)
			{
				if (iz + i >= gridHeight || ix + j >= gridWidth)
				{
					flag = false;
					break;
				}
				int num3 = (iz + i) * gridWidth + (ix + j);
				AICell ac = cells[num3];
				Cell wc = worldCells[num3];
				if (InvalidForBlock(ac, wc))
				{
					flag = false;
					break;
				}
			}
			if (!flag)
			{
				break;
			}
		}
		return flag;
	}

	public bool PlaceNewBlock(AILayoutBlock templateBlock, out AILayoutBlock newBlock, int idealX, int idealZ, int checkRadius = 100, int startIndex = 4)
	{
		int num = Mathf.CeilToInt(((float)idealX - KingdomGridStart.x) / 4f) * 4 + (int)KingdomGridStart.x;
		int num2 = Mathf.CeilToInt(((float)idealZ - KingdomGridStart.z) / 4f) * 4 + (int)KingdomGridStart.z;
		drawHeight = 0.8f;
		Cell[] cellsData = World.inst.GetCellsData();
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		newBlock = null;
		bool flag = templateBlock.sizeX != templateBlock.sizeZ;
		int num3 = 0;
		for (int i = startIndex; i <= checkRadius; i += 4)
		{
			int num4 = num - i;
			int num5 = num2 - i;
			int num6 = num + i;
			int num7 = num2 + i;
			for (int j = num5; j <= num7; j += 4)
			{
				if (j < 0)
				{
					continue;
				}
				if (j >= gridHeight)
				{
					break;
				}
				for (int k = num4; k <= num6; k += 4)
				{
					if (k != num4 && j != num5 && k != num6 && j != num7)
					{
						continue;
					}
					num3++;
					if (k < 0)
					{
						continue;
					}
					if (k >= gridWidth)
					{
						break;
					}
					Cell cell = cellsData[j * gridWidth + k];
					if (cell.deepWater || cell.landMassIdx != LandMass)
					{
						continue;
					}
					bool flag2 = false;
					bool flag3 = IsBlockValidAt(templateBlock, k, j, gridWidth, gridHeight, cellsData, aiCells, rotate90: false);
					if (flag && !flag3)
					{
						flag3 = IsBlockValidAt(templateBlock, k, j, gridWidth, gridHeight, cellsData, aiCells, rotate90: true);
						if (flag3)
						{
							templateBlock.UpdateBlockRotation(isRotated: true);
							flag2 = true;
						}
					}
					if (flag3 && templateBlock.BlockValidityTest(k, j))
					{
						newBlock = CopyLayoutBlock(templateBlock);
						PlaceBlock(k, j, newBlock);
						OutlineBlockWithRoads(newBlock);
						if (flag2)
						{
							templateBlock.UpdateBlockRotation(isRotated: false);
						}
						return true;
					}
					if (flag2)
					{
						templateBlock.UpdateBlockRotation(isRotated: false);
					}
				}
			}
		}
		return false;
	}

	public void PlaceBlock(int X, int Z, AILayoutBlock layoutBlock)
	{
		layoutBlock.posX = X;
		layoutBlock.posZ = Z;
		for (int i = 0; i < layoutBlock.buildingTransforms.Count; i++)
		{
			AIBuildingMeta aIBuildingMeta = layoutBlock.buildingTransforms[i];
			aIBuildingMeta.parentPosX = X;
			aIBuildingMeta.parentPosZ = Z;
			for (int j = 0; j < aIBuildingMeta.SizeZ; j++)
			{
				for (int k = 0; k < aIBuildingMeta.SizeX; k++)
				{
					AICell aICell = GetAICell(X + k + aIBuildingMeta.OffsetX, Z + j + aIBuildingMeta.OffsetZ);
					aICell.Road = aIBuildingMeta.type == AIBuildingBlockType.Road;
					aICell.blockReference = layoutBlock;
					aICell.buildingMeta = aIBuildingMeta;
				}
			}
		}
		layoutBlocks.Add(layoutBlock);
		layoutBlock.OnBlockPlaced(this);
	}

	public void UnplaceBlock(AILayoutBlock layoutBlock)
	{
		for (int i = 0; i < layoutBlock.buildingTransforms.Count; i++)
		{
			AIBuildingMeta aIBuildingMeta = layoutBlock.buildingTransforms[i];
			for (int j = 0; j < aIBuildingMeta.SizeZ; j++)
			{
				for (int k = 0; k < aIBuildingMeta.SizeX; k++)
				{
					int num = layoutBlock.posX + k + aIBuildingMeta.OffsetX;
					int num2 = layoutBlock.posZ + j + aIBuildingMeta.OffsetZ;
					AICell obj = aiCells[num2 * width + num];
					obj.Road = false;
					obj.blockReference = null;
					obj.buildingMeta = null;
				}
			}
		}
		layoutBlocks.Remove(layoutBlock);
	}

	public void OutlineBlockWithRoads(AILayoutBlock layoutBlock)
	{
		if (!layoutBlock.OutlineWithRoads)
		{
			return;
		}
		int num = Mathff.Clamp(layoutBlock.posX - 1, 1, World.inst.GridWidth - 2);
		int num2 = Mathff.Clamp(layoutBlock.posX + layoutBlock.SizeX, 1, World.inst.GridWidth - 2);
		int num3 = Mathff.Clamp(layoutBlock.posZ - 1, 1, World.inst.GridWidth - 2);
		int num4 = Mathff.Clamp(layoutBlock.posZ + layoutBlock.SizeZ, 1, World.inst.GridWidth - 2);
		bool flag = false;
		List<Cell> list = new List<Cell>();
		for (int i = num3; i <= num4; i++)
		{
			for (int j = num; j <= num2; j++)
			{
				if (j != num && j != num2 && i != num3 && i != num4)
				{
					continue;
				}
				Cell cellDataClamped = World.inst.GetCellDataClamped(j, i);
				AICell aICell = GetAICell(cellDataClamped);
				if (aICell.buildingMeta != null || cellDataClamped.Type == TerrainType.Obstruction)
				{
					continue;
				}
				if (cellDataClamped.Type == TerrainType.Water)
				{
					if (!flag)
					{
						list.Add(cellDataClamped);
						if (cellDataClamped.deepWater || layoutBlock.layoutType == AIBuildingBlockType.Any)
						{
							flag = true;
						}
					}
				}
				else
				{
					aICell.Road = true;
					AddDeferredRoad(cellDataClamped);
				}
			}
		}
		if (!flag && list.Count < 5)
		{
			for (int k = 0; k < list.Count; k++)
			{
				GetAICell(list[k]).Road = true;
				AddDeferredRoad(list[k]);
			}
		}
		for (int l = num3 - 1; l <= num4 + 1; l++)
		{
			for (int m = num - 1; m <= num2 + 1; m++)
			{
				if ((((m == num - 1) | (m == num2 + 1)) || l == num3 - 1 || l == num4 + 1) && GetAICell(m, l).Road)
				{
					return;
				}
			}
		}
		BuildOutRoad(num, num2, num3, num4, null, prioritizeCorners: true);
	}

	public int GetLandMass()
	{
		return LandMass;
	}

	internal void ReplaceKeep()
	{
		Building building = UnityEngine.Object.Instantiate(GameState.inst.GetPlaceableByUniqueName(World.keepName));
		building.transform.position = KingdomGridStart;
		building.Init();
		World.inst.Place(building);
	}

	public Vector3 PlaceInitialBlocks()
	{
		AILayoutBlock newBlock = null;
		Building building = UnityEngine.Object.Instantiate(GameState.inst.GetPlaceableByUniqueName(World.keepName));
		PlaceNewBlockContainingUniqueName(World.keepName, out newBlock, (int)KingdomStart.x, (int)KingdomStart.z);
		if (newBlock != null && FitBuildingIntoBlockBuildingMeta(building, newBlock))
		{
			building.Init();
			World.inst.Place(building);
			Player.inst.SetupInitialWorkers(building.GetComponent<Keep>());
			building.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
			for (int i = minZ; i <= maxZ; i++)
			{
				for (int j = minX; j <= maxX; j++)
				{
					GetDefenceCell(j, i).DisallowCastleEdge = true;
				}
			}
			KingdomGridStart = building.GetCell().Position;
			PlaceRoadsAroundKeep(building);
			for (int k = 0; k < TerrainResource.terrainResources.Count; k++)
			{
				TerrainResource terrainResource = TerrainResource.terrainResources.data[k];
				Cell cellData = World.inst.GetCellData(terrainResource.x, terrainResource.z);
				if (cellData.landMassIdx != LandMass)
				{
					continue;
				}
				if (terrainResource.resourceID == 2)
				{
					World.inst.GetNeighborCells(cellData, ref scratchCells);
					int num = 2;
					for (int l = 0; l < 4; l++)
					{
						if (scratchCells[l].Type == TerrainType.None && num > 0)
						{
							AL_QuarryBlock1x1 aL_QuarryBlock1x = new AL_QuarryBlock1x1();
							aL_QuarryBlock1x.Init();
							PlaceBlock(scratchCells[l].x, scratchCells[l].z, aL_QuarryBlock1x);
							num--;
						}
					}
				}
				else
				{
					if (terrainResource.resourceID != 5)
					{
						continue;
					}
					World.inst.GetNeighborCells(cellData, ref scratchCells);
					int num2 = 2;
					for (int m = 0; m < 4; m++)
					{
						if (scratchCells[m].Type == TerrainType.None && num2 > 0)
						{
							AL_IronMineBlock1x1 aL_IronMineBlock1x = new AL_IronMineBlock1x1();
							aL_IronMineBlock1x.Init();
							PlaceBlock(scratchCells[m].x, scratchCells[m].z, aL_IronMineBlock1x);
							num2--;
						}
					}
				}
			}
			int num3 = 0;
			bool flag = false;
			while (num3 < 36 && !flag)
			{
				int index = SRand.Range(0, blockTypeLookup[AIBuildingBlockType.Castle].Count);
				Type type = blockTypeLookup[AIBuildingBlockType.Castle][index].GetType();
				AILayoutBlock blockOfType = GetBlockOfType(type);
				num3 += blockOfType.SizeX * blockOfType.SizeZ;
				AILayoutBlock newBlock2 = null;
				if (PlaceNewBlock(blockOfType, out newBlock2, (int)KingdomGridStart.x, (int)KingdomGridStart.z))
				{
					DesignateCastleRegion(newBlock2);
				}
				else
				{
					flag = true;
				}
			}
			AL_CivicBlock3_3_3 aL_CivicBlock3_3_ = new AL_CivicBlock3_3_3();
			aL_CivicBlock3_3_.Init();
			AILayoutBlock newBlock3 = null;
			if (PlaceNewBlock(aL_CivicBlock3_3_, out newBlock3, (int)KingdomGridStart.x, (int)KingdomGridStart.z))
			{
				DesignateCastleRegion(newBlock3);
			}
			if (newBlock3 == null)
			{
				Debug.Log($"Failed to Place Initial MasonBlock For AI at Position {KingdomStart}");
			}
			if (landmassReferenceSize >= 35)
			{
				AL_CastleBlock3x3_GreatHall aL_CastleBlock3x3_GreatHall = new AL_CastleBlock3x3_GreatHall();
				aL_CastleBlock3x3_GreatHall.Init();
				AILayoutBlock newBlock4 = null;
				if (PlaceNewBlock(aL_CastleBlock3x3_GreatHall, out newBlock4, (int)KingdomGridStart.x, (int)KingdomGridStart.z))
				{
					DesignateCastleRegion(newBlock4);
				}
			}
			return building.GetPos();
		}
		UnityEngine.Object.Destroy(building.gameObject);
		return KingdomStart;
	}

	private void DesignateCastleRegion(AILayoutBlock block)
	{
		int posX = block.posX;
		int num = block.posX + block.SizeX - 1;
		int posZ = block.posZ;
		int num2 = block.posZ + block.SizeZ - 1;
		DesignateCastleRegion(posX - 2, posZ - 2, num + 2, num2 + 2);
		for (int i = posZ; i <= num2; i++)
		{
			for (int j = posX; j <= num; j++)
			{
				GetDefenceCell(j, i).DisallowCastleEdge = true;
			}
		}
	}

	public AILayoutBlock FindLayoutBlockOfTypeClosest(AIBuildingBlockType type, Vector3 position, int minSizeX = -1, int minSizeZ = -1)
	{
		AILayoutBlock result = null;
		float num = float.MaxValue;
		for (int i = 0; i < layoutBlocks.Count; i++)
		{
			AILayoutBlock aILayoutBlock = layoutBlocks[i];
			if (aILayoutBlock.layoutType == type && (minSizeX < 0 || aILayoutBlock.SizeX >= minSizeX) && (minSizeZ < 0 || aILayoutBlock.SizeZ >= minSizeZ))
			{
				float num2 = Vector3.Distance(position, new Vector3(aILayoutBlock.posX, 0f, aILayoutBlock.posZ));
				if (num2 < num)
				{
					num = num2;
					result = aILayoutBlock;
				}
			}
		}
		return result;
	}

	public AIBuildingMeta FindMetaBuildingOfUniqueName(string uniqueName)
	{
		for (int i = 0; i < layoutBlocks.Count; i++)
		{
			for (int j = 0; j < layoutBlocks[i].buildingTransforms.Count; j++)
			{
				AIBuildingMeta aIBuildingMeta = layoutBlocks[i].buildingTransforms[j];
				Cell cellData = World.inst.GetCellData(aIBuildingMeta.PosX, aIBuildingMeta.PosZ);
				DefenseCell defenceCell = GetDefenceCell(cellData);
				AICell aICell = GetAICell(cellData);
				if (cellData.OccupyingStructure.Count == 0 && !aIBuildingMeta.inDevelopment && !aICell.invalid && aIBuildingMeta.uniqueName == uniqueName && !defenceCell.CastleEdge)
				{
					return aIBuildingMeta;
				}
			}
		}
		return null;
	}

	public void PlaceRoadsAroundKeep(Building keep)
	{
		keep.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minZ - 1; i <= maxZ + 1; i++)
		{
			for (int j = minX - 1; j <= maxX + 1; j++)
			{
				if (i == minZ - 1 || j == minX - 1 || j == maxX + 1 || i == maxZ + 1)
				{
					Cell cellData = World.inst.GetCellData(j, i);
					AICell aICell = GetAICell(cellData);
					if (cellData.Type != TerrainType.Obstruction)
					{
						aICell.Road = aICell.buildingMeta == null;
						AddDeferredRoad(cellData);
					}
				}
			}
		}
	}

	public void DrawBoxThing(float x, float z, float sizeX, float sizeZ, Color color, float duration = 0f)
	{
		DebugEx.DrawBox(new Vector3(x, drawHeight, z), new Vector3(x + sizeX, drawHeight, z + sizeZ), color, duration);
	}

	public void DebugTest()
	{
		if (Input.GetKey(KeyCode.PageUp))
		{
			testidx++;
		}
		if (Input.GetKey(KeyCode.PageDown))
		{
			testidx--;
		}
	}

	private bool InvalidForBlock(AICell ac, Cell wc)
	{
		if (ac == null)
		{
			return true;
		}
		if (ac.Road || ac.blockReference != null)
		{
			return true;
		}
		if (!wc.deepWater)
		{
			return wc.landMassIdx != LandMass;
		}
		return true;
	}

	private Vector3 RotatePointAroundPivot(Vector3 point, Vector3 pivot, Quaternion angles)
	{
		Vector3 vector = point - pivot;
		vector = angles * vector;
		point = vector + pivot;
		return point;
	}

	public Cell PositionBuilding(AIBuildingMeta bm, ref Building b)
	{
		for (int i = 0; i < bm.SizeZ; i++)
		{
			for (int j = 0; j < bm.SizeX; j++)
			{
				b.transform.position = new Vector3(bm.PosX + j, 0f, bm.PosZ + i);
				if (b.transform.position.x >= (float)width || b.transform.position.z >= (float)height)
				{
					continue;
				}
				GameUI.inst.CurrPlacementMode.TryRotateBuildingObjAuto(b);
				for (int k = 0; k < 4; k++)
				{
					if (World.inst.CanPlace(b, ignoreLandMassChecks: true, allowBuildOverForest: true) == PlacementValidationResult.Valid)
					{
						bool contained = true;
						if (b.uniqueNameHash != World.noriaHash)
						{
							b.ForEachTileInBounds((int x, int z, Cell cell) =>
							{
								bool flag = false;
								for (int l = 0; l < bm.SizeZ; l++)
								{
									for (int m = 0; m < bm.SizeX; m++)
									{
										flag |= x == m + bm.PosX && z == l + bm.PosZ;
									}
								}
								if (!flag)
								{
									contained = false;
								}
							});
						}
						if (contained)
						{
							return World.inst.GetCellData(bm.PosX + j, bm.PosZ + i);
						}
					}
					GameUI.inst.RotateBuilding(b, 90f);
				}
			}
		}
		return null;
	}

	public void BuildOutRoad(int minX, int maxX, int minZ, int maxZ, AIIntentionBase parent = null, bool prioritizeCorners = false)
	{
		Cell cell = null;
		Cell cell2 = World.inst.GetCellData(KingdomStart);
		if (cell2 != null)
		{
			List<Cell> list = new List<Cell>();
			bool[] array = new bool[World.inst.GridWidth * World.inst.GridHeight];
			list.Add(cell2);
			while (list.Count > 0)
			{
				Cell cell3 = list[0];
				AICell aICell = GetAICell(cell3);
				list.RemoveAt(0);
				int num = cell3.z * width + cell3.x;
				if (array[num])
				{
					continue;
				}
				array[num] = true;
				if (cell3 != null && (cell3.Type != TerrainType.Water || !cell3.deepWater))
				{
					if (aICell.Road)
					{
						cell = cell3;
						break;
					}
					Cell[] array2 = new Cell[4];
					World.inst.GetNeighborCells(cell3, ref array2);
					for (int i = 0; i < array2.Length; i++)
					{
						list.Add(array2[i]);
					}
				}
			}
		}
		bool flag = false;
		bool flag2 = false;
		float num2 = float.MaxValue;
		if (cell != null)
		{
			for (int j = minZ; j <= maxZ; j++)
			{
				for (int k = minX; k <= maxX; k++)
				{
					Cell cellData = World.inst.GetCellData(k, j);
					AICell aICell2 = GetAICell(cellData);
					if ((aICell2.buildingMeta != null && !aICell2.Road) || cellData.Type != TerrainType.None)
					{
						continue;
					}
					float num3 = Vector3.Distance(cell.Position, new Vector3(cellData.x, 0f, cellData.z));
					if (!(num3 < num2))
					{
						continue;
					}
					if (prioritizeCorners && ((j == minZ && k == minX) || (j == maxZ && k == minX) || (j == maxZ && k == maxX) || (j == minZ && k == maxX)))
					{
						flag2 = true;
						cell2 = cellData;
					}
					else if (!flag2)
					{
						if (aICell2.Road)
						{
							flag = true;
							cell2 = cellData;
						}
						else if (!flag)
						{
							cell2 = cellData;
						}
					}
					num2 = num3;
				}
			}
		}
		if (cell == null || cell2 == null)
		{
			return;
		}
		FindRoadPath(cell, cell2, ref scratch);
		if (scratch.Count == 0)
		{
			Debug.LogError($"[WARNING] No Path Between- {cell.Position} -> {cell2.Position}");
		}
		for (int l = 0; l < scratch.Count; l++)
		{
			Cell cellData2 = World.inst.GetCellData(scratch.data[l]);
			if (cellData2.OccupyingStructure.Count == 0 || CellNeedsGate(cellData2, out var _))
			{
				GetAICell(cellData2).Road = true;
				AddDeferredRoad(cellData2);
			}
		}
	}

	public void BuildOutRoad(Building building, AIIntentionBase parent = null, bool prioritizeCorners = false)
	{
		building.GetCell();
		building.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		minX = Mathff.Clamp(minX - 1, 0, World.inst.GridWidth - 1);
		maxX = Mathff.Clamp(maxX + 1, 0, World.inst.GridWidth - 1);
		minZ = Mathff.Clamp(minZ - 1, 0, World.inst.GridHeight - 1);
		maxZ = Mathff.Clamp(maxZ + 1, 0, World.inst.GridHeight - 1);
		BuildOutRoad(minX, maxX, minZ, maxZ, parent, prioritizeCorners);
	}

	public void RemoveBuilding(Building b, bool reclaimResources)
	{
		b.ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			if (GetAICell(x, z).buildingMeta != null)
			{
				GetAICell(x, z).buildingMeta.inDevelopment = false;
			}
		});
		World.inst.DemolishBuilding(b, reclaimResources);
	}

	public bool CellNeedsGate(Cell c, out float angle)
	{
		angle = 0f;
		DefenseCell defenceCell = GetDefenceCell(c);
		if (!GetAICell(c).Road)
		{
			return false;
		}
		World.inst.GetNeighborCells(c, ref scratchCells4);
		GetNeighborDefenceCells(defenceCell, ref scratchDCell4);
		for (int i = 0; i < scratchCells4.Length; i++)
		{
			if (scratchCells4[i] != null)
			{
				if ((bool)scratchCells4[i].StructureFindByCategory(World.gateHash))
				{
					return false;
				}
				isRoad[i] = GetAICell(scratchCells4[i]).Road;
				DefenseCell obj = scratchDCell4[i];
				if (obj != null && obj.CastleEdge)
				{
					isRoad[i] = false;
				}
			}
			else
			{
				isRoad[i] = false;
			}
		}
		if (isRoad[0] && isRoad[2])
		{
			DefenseCell obj2 = scratchDCell4[1];
			if (obj2 != null && obj2.CastleEdge)
			{
				DefenseCell obj3 = scratchDCell4[3];
				if (obj3 != null && obj3.CastleEdge)
				{
					angle = 90f;
					return true;
				}
			}
		}
		DefenseCell obj4 = scratchDCell4[0];
		if (obj4 != null && obj4.CastleEdge)
		{
			DefenseCell obj5 = scratchDCell4[2];
			if (obj5 != null && obj5.CastleEdge && isRoad[1] && isRoad[3])
			{
				angle = 0f;
				return true;
			}
		}
		return false;
	}

	public void FindRoadPath(Cell startCell, Cell endCell, ref ArrayExt<Vector3> path)
	{
		World.inst.FindPath(startCell, endCell, ref path, RoadBlocksPathTest, RoadBlocksPathTest, applyExtraCost, 2, doDiagonal: false, useUpperPathGrid: false);
	}

	public bool RoadBlocksPathTest(PathCell pc, int teamId)
	{
		Cell cellData = World.inst.GetCellData(pc);
		AICell aICell = GetAICell(cellData);
		if (aICell.buildingMeta != null && !aICell.Road)
		{
			return true;
		}
		if (cellData.Type == TerrainType.Water)
		{
			return cellData.deepWater;
		}
		return cellData.Type == TerrainType.Obstruction;
	}

	public int applyExtraCost(PathCell c, int teamId)
	{
		if (GetAICell(c.x, c.z).Road)
		{
			if (c.Type == TerrainType.Water)
			{
				return 2;
			}
			return 1;
		}
		bool flag = ((float)c.x - KingdomGridStart.x + 1f) % 4f != 0f && ((float)c.z - KingdomGridStart.z + 1f) % 4f != 0f;
		if (c.Type == TerrainType.Water)
		{
			if (!flag)
			{
				return 60;
			}
			return 120;
		}
		if (!flag)
		{
			return 15;
		}
		return 30;
	}

	public void FindAqueductPath(Cell startCell, Cell endCell, ref ArrayExt<Vector3> path)
	{
		World.inst.FindPath(startCell, endCell, ref path, AqueductBlocksPathTest, AqueductBlocksPathTest, applyExtraCostAqueduct, 2, doDiagonal: false, useUpperPathGrid: false);
	}

	public int applyExtraCostAqueduct(PathCell pc, int teamId)
	{
		Cell cellData = World.inst.GetCellData(pc);
		if (cellData.StructureCompareUniqueNameAll(World.aqueductHash))
		{
			return 1;
		}
		if (GetAICell(cellData.x, cellData.z).Road)
		{
			return 3;
		}
		return 30;
	}

	public bool AqueductBlocksPathTest(PathCell pc, int teamId)
	{
		Cell cellData = World.inst.GetCellData(pc);
		AICell aICell = GetAICell(cellData);
		if (cellData.OccupyingStructure.Count > 0)
		{
			bool flag = true;
			for (int i = 0; i < cellData.OccupyingStructure.Count; i++)
			{
				Building building = cellData.OccupyingStructure[i];
				if (building.uniqueNameHash == World.noriaHash)
				{
					Vector3 position = building.GetComponent<Noria>().basePos.position;
					int num = (int)position.x;
					int num2 = (int)position.z;
					if (cellData.x == num && cellData.z == num2)
					{
						return false;
					}
					return true;
				}
				if (building.uniqueNameHash == World.reservoirHash || building.uniqueNameHash == World.aqueductHash)
				{
					return false;
				}
				if (!building.allowOverAndUnderAqueducts)
				{
					flag = false;
				}
			}
			if (flag)
			{
				return false;
			}
		}
		if (aICell?.buildingMeta != null && !aICell.Road)
		{
			return true;
		}
		return cellData.Type != TerrainType.None;
	}

	public void DrawDebug()
	{
		for (int i = 0; i < width * height; i++)
		{
			AICell aICell = GetAICell(i % width, i / width);
			bool flag = false;
			Color color = Color.cyan;
			if (aICell.Road)
			{
				color = Color.yellow;
				flag = true;
			}
			if (aICell.buildingMeta != null)
			{
				if (aICell.buildingMeta.type == AIBuildingBlockType.Civic)
				{
					color = Color.blue;
				}
				if (aICell.buildingMeta.type == AIBuildingBlockType.Food)
				{
					color = Color.green;
				}
				if (aICell.buildingMeta.type == AIBuildingBlockType.Residential)
				{
					color = Color.red;
				}
				if (aICell.buildingMeta.type == AIBuildingBlockType.None)
				{
					color = Color.black;
				}
				if (aICell.buildingMeta.type == AIBuildingBlockType.Castle)
				{
					color = Color.white;
				}
				if (aICell.buildingMeta.uniqueName == World.greatHallName)
				{
					color = Color.magenta;
				}
				flag = true;
			}
			if (aICell.invalid)
			{
				DebugEx.DrawCircleXZ(new Vector3((float)aICell.x + 0.5f, 0f, (float)aICell.z + 0.5f), 0.4f, Color.red, 8f);
				DebugEx.DrawCircleXZ(new Vector3((float)aICell.x + 0.5f, 0f, (float)aICell.z + 0.5f), 0.2f, Color.red, 8f);
			}
			if (flag)
			{
				DebugEx.DrawBox(new Vector3((float)aICell.x + 0.05f, 0f, (float)aICell.z + 0.05f), new Vector3((float)aICell.x + 0.95f, 0f, (float)aICell.z + 0.95f), color);
			}
		}
		for (int j = 0; j < layoutBlocks.Count; j++)
		{
			_ = layoutBlocks[j];
		}
	}

	public void CollectNearbyBlocks(AIBuildingBlockType blockType, int idealX, int idealZ, int checkRadius)
	{
		nearbyBlocks.Clear();
		int num = checkRadius * checkRadius + 1;
		Vector3 a = new Vector3(idealX, 0f, idealZ);
		for (int i = 0; i < layoutBlocks.Count; i++)
		{
			AILayoutBlock aILayoutBlock = layoutBlocks[i];
			if (aILayoutBlock.layoutType != blockType && (blockType != AIBuildingBlockType.Any || aILayoutBlock.layoutType == AIBuildingBlockType.Castle))
			{
				continue;
			}
			float num2 = Mathff.DistSqrdXZ(a, new Vector3(aILayoutBlock.posX, 0f, aILayoutBlock.posZ));
			if (!(num2 <= (float)num))
			{
				continue;
			}
			BlockOption item = new BlockOption(aILayoutBlock, num2);
			int num3 = 0;
			while (true)
			{
				if (num3 < nearbyBlocks.Count)
				{
					if (num2 < nearbyBlocks[num3].dist)
					{
						nearbyBlocks.Insert(num3, item);
						break;
					}
					num3++;
					continue;
				}
				nearbyBlocks.Add(item);
				break;
			}
		}
	}

	public bool FitBuildingIntoBuildingMeta(Building pendingBuilding, AIBuildingBlockType blockType, int idealX, int idealZ, int checkRadius = 100)
	{
		Cell[] cellsData = World.inst.GetCellsData();
		if (!uniqueBuildingLookup.TryGetValue(pendingBuilding.UniqueName, out var value))
		{
			return false;
		}
		CollectNearbyBlocks(blockType, idealX, idealZ, checkRadius);
		for (int i = 0; i < nearbyBlocks.Count; i++)
		{
			AILayoutBlock block = nearbyBlocks[i].block;
			Type type = block.GetType();
			if (value.Contains(type) && FitBuildingIntoBlockBuildingMeta(pendingBuilding, block, cellsData))
			{
				return true;
			}
		}
		return false;
	}

	public bool FitBuildingIntoBlockBuildingMeta(Building pendingBuilding, AILayoutBlock block, Cell[] wCells = null)
	{
		if (wCells == null)
		{
			wCells = World.inst.GetCellsData();
		}
		for (int i = 0; i < block.buildingTransforms.Count; i++)
		{
			AIBuildingMeta aIBuildingMeta = block.buildingTransforms[i];
			if (!(aIBuildingMeta.uniqueName == pendingBuilding.UniqueName) || aIBuildingMeta.inDevelopment)
			{
				continue;
			}
			bool flag = true;
			int num = aIBuildingMeta.PosX + aIBuildingMeta.SizeX;
			int num2 = aIBuildingMeta.PosZ + aIBuildingMeta.SizeZ;
			for (int j = aIBuildingMeta.PosZ; j < num2; j++)
			{
				for (int k = aIBuildingMeta.PosX; k < num; k++)
				{
					int num3 = k + j * width;
					if (aiCells[num3].invalid || defCells[num3].CastleEdge || wCells[num3].OccupyingStructure.Count > 0)
					{
						flag = false;
						break;
					}
				}
				if (!flag)
				{
					break;
				}
			}
			if (flag && PositionBuilding(aIBuildingMeta, ref pendingBuilding) != null)
			{
				return true;
			}
		}
		return false;
	}

	public bool FitBuildingIntoBlockType(Building pendingBuilding, AIBuildingBlockType blockType, int idealX, int idealZ, int checkRadius = 100)
	{
		int idealX2 = Mathf.CeilToInt(((float)idealX - KingdomGridStart.x) / 4f) * 4 + (int)KingdomGridStart.x;
		int idealZ2 = Mathf.CeilToInt(((float)idealZ - KingdomGridStart.z) / 4f) * 4 + (int)KingdomGridStart.z;
		nearbyBlocks.Clear();
		if (FitBuildingIntoBuildingMeta(pendingBuilding, blockType, idealX2, idealZ2, checkRadius))
		{
			return true;
		}
		if (nearbyBlocks.Count == 0)
		{
			CollectNearbyBlocks(blockType, idealX, idealZ, checkRadius);
		}
		for (int i = 0; i < nearbyBlocks.Count; i++)
		{
			AILayoutBlock block = nearbyBlocks[i].block;
			if (FitBuildingIntoBlock(pendingBuilding, blockType, block))
			{
				return true;
			}
		}
		return false;
	}

	public bool FitBuildingIntoBlock(Building pendingBuilding, AIBuildingBlockType queryType, AILayoutBlock block)
	{
		Cell[] wGrid = World.inst.GetCellsData();
		int gridWidth = World.inst.GridWidth;
		AIBuildingBlockType blockType = block.layoutType;
		return RectangleFinder.FindValidRectangle(block.posX, block.posX + block.SizeX, block.posZ, block.posZ + block.SizeZ, (int)pendingBuilding.size.x, (int)pendingBuilding.size.z, (int x, int z) =>
		{
			int num = x + gridWidth * z;
			AICell aICell = aiCells[num];
			DefenseCell obj = defCells[num];
			Cell cell = wGrid[num];
			return !obj.CastleEdge && aICell.buildingMeta != null && ((aICell.buildingMeta.uniqueName.Length == 0 && (blockType == aICell.buildingMeta.type || (queryType == AIBuildingBlockType.Any && aICell.buildingMeta.type != AIBuildingBlockType.None))) || aICell.buildingMeta.uniqueName == pendingBuilding.UniqueName) && !aICell.buildingMeta.inDevelopment && !aICell.invalid && !aICell.Road && cell.OccupyingStructure.Count == 0 && (cell.Type == TerrainType.None || cell.Type == TerrainType.Water);
		}, (int lowerX, int lowerZ, int upperX, int upperZ, bool square, bool horizontal) =>
		{
			Vector3 position = new Vector3(lowerX, 0f, lowerZ);
			if (!square)
			{
				Transform child = pendingBuilding.transform.GetChild(0);
				GameUI.inst.RotateBuilding(pendingBuilding, 0f - child.localEulerAngles.y);
				if (!horizontal)
				{
					if (SRand.Range(0, 2) == 0)
					{
						GameUI.inst.RotateBuilding(pendingBuilding, 90f);
						position.z += pendingBuilding.size.x - 1f;
					}
					else
					{
						GameUI.inst.RotateBuilding(pendingBuilding, -90f);
						position.x += pendingBuilding.size.z - 1f;
					}
				}
				else if (SRand.Range(0, 2) == 1)
				{
					GameUI.inst.RotateBuilding(pendingBuilding, -180f);
					position.x += pendingBuilding.size.x - 1f;
					position.z += pendingBuilding.size.z - 1f;
				}
			}
			pendingBuilding.transform.position = position;
			return World.inst.CanPlace(pendingBuilding, ignoreLandMassChecks: true, allowBuildOverForest: true, ai: true) == PlacementValidationResult.Valid;
		}).foundRectangle;
	}

	public void DesignateCastleRegion(int xMin, int zMin, int xMax, int zMax, bool connect = false)
	{
		bool flag = true;
		for (int i = zMin; i <= zMax; i++)
		{
			for (int j = xMin; j <= xMax; j++)
			{
				DefenseCell defenceCell = GetDefenceCell(j, i);
				if (defenceCell == null || defenceCell.DisallowCastle)
				{
					continue;
				}
				flag = true;
				Cell worldCell = defenceCell.GetWorldCell();
				if (worldCell.Type == TerrainType.Water)
				{
					flag = false;
					World.inst.GetNeighborCells(worldCell, ref scratchCells4);
					for (int k = 0; k < scratchCells4.Length; k++)
					{
						if (scratchCells4[k].Type != TerrainType.Water)
						{
							flag = true;
							break;
						}
					}
				}
				defenceCell.Castle = flag;
				if (!defenceCell.innerWall & flag)
				{
					defenceCell.innerWall = kingdom.maintainWallDefense == null || !kingdom.maintainWallDefense.firstWallComplete;
				}
			}
		}
		if (connect)
		{
			xMin -= 2;
			xMax += 2;
			zMin -= 2;
			zMax += 2;
			int num = Mathf.FloorToInt((float)(xMax - xMin) / 2f) + xMin;
			int num2 = Mathf.FloorToInt((float)(zMax - zMin) / 2f) + zMin;
			for (int l = zMin; l <= zMax; l++)
			{
				for (int m = xMin; m <= xMax; m++)
				{
					if ((m == xMin || l == zMin || m == xMax || l == zMax) && (m != xMin || l != zMin) && (m != xMax || l != zMin) && (m != xMax || l != zMax) && (m != xMin || l != zMax) && GetDefenceCell(m, l).Castle)
					{
						if (l == zMin || l == zMax)
						{
							GetDefenceCell(m, l - (int)Mathf.Sign(l - num2)).Castle = true;
						}
						else if (m == xMin || m == xMax)
						{
							GetDefenceCell(m - (int)Mathf.Sign(m - num), l).Castle = true;
						}
					}
				}
			}
		}
		Broadcast.CastleRegionUpdateEvent.Broadcast(new OnAICastleRegionUpdateEvent
		{
			xMin = xMin,
			zMin = zMin,
			xMax = xMax,
			zMax = zMax,
			landmass = LandMass
		});
	}

	private bool TestNeighbor(int x, int z, DefenseCell cell)
	{
		DefenseCell defenceCell = GetDefenceCell(x, z);
		if (defenceCell != null && defenceCell.Castle && !defenceCell.DisallowCastleEdge)
		{
			return true;
		}
		return false;
	}
}
