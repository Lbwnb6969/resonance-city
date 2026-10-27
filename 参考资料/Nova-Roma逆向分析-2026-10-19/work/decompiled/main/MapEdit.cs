using System.Collections;
using System.Collections.Generic;
using Code;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class MapEdit : MonoBehaviour
{
	public enum Validation
	{
		NoError,
		NoStone,
		NoIron,
		NoFertile,
		NoShallowWater,
		NoTrees
	}

	public enum BrushMode
	{
		None,
		BarrenLand,
		FertileLand,
		VeryFertileLand,
		Forest,
		ShallowWater,
		DeepWater,
		UnusableStone,
		Stone,
		Iron,
		EmptyCave,
		Fish,
		Marble,
		ScatterRocks,
		Erase,
		NumBrushes
	}

	private class CellSnapshot
	{
		public TerrainType type;

		public bool deepWater;

		public float fertilityNoise;

		public int treeCount;

		public int rockCount;

		public bool hadFish;

		public float[] vertHeights = new float[9];
	}

	private class DepositSnapshot
	{
		public int x;

		public int z;

		public int sizeX;

		public int sizeZ;

		public int resourceID;
	}

	private class PaintStrokeUndo : IMapEditorUndoEntry
	{
		public readonly Dictionary<Cell, CellSnapshot> cells = new Dictionary<Cell, CellSnapshot>();

		public readonly HashSet<TerrainResource> seenDeposits = new HashSet<TerrainResource>();

		public readonly List<DepositSnapshot> deposits = new List<DepositSnapshot>();

		public void Undo()
		{
			inst.RestorePaintStroke(this);
		}
	}

	public static MapEdit inst;

	public BrushMode brushMode;

	public bool dirty;

	public bool resourceLabelsDirty;

	private bool eraseDirtyValid;

	private int eraseMinX;

	private int eraseMaxX;

	private int eraseMinZ;

	private int eraseMaxZ;

	private PaintStrokeUndo currentStroke;

	private float radius = 1f;

	private float maxBrushSize = 19f;

	public TextMeshProUGUI brushSize;

	private Cell lastCell;

	private Vector3 rightMouseDownPos;

	private Color cursorColor = new Color(1f, 1f, 1f, 0.25f);

	public Slider brushSizeSlider;

	public float BrushRadius => radius;

	public Validation Validate()
	{
		bool flag = false;
		bool flag2 = false;
		bool flag3 = false;
		bool flag4 = false;
		bool flag5 = false;
		Cell[] cellsData = World.inst.GetCellsData();
		foreach (Cell cell in cellsData)
		{
			flag4 |= cell.Type == TerrainType.Water && !cell.deepWater;
			flag2 |= cell.HasTerrainResourceType(5);
			flag |= cell.HasTerrainResourceType(2);
			flag3 |= cell.GetFertility() > 0;
			flag5 |= World.inst.treeSystem.ItemAmount(cell) > 0;
		}
		if (!flag)
		{
			return Validation.NoStone;
		}
		if (!flag2)
		{
			return Validation.NoIron;
		}
		if (!flag3)
		{
			return Validation.NoFertile;
		}
		if (!flag4)
		{
			return Validation.NoShallowWater;
		}
		if (!flag5)
		{
			return Validation.NoTrees;
		}
		return Validation.NoError;
	}

	private void Awake()
	{
		inst = this;
	}

	private void OnEnable()
	{
		radius = 1f;
		brushMode = BrushMode.None;
		StartCoroutine(ClearToolSelectionNextFrame());
		brushSizeSlider.onValueChanged.AddListener((float v) =>
		{
			radius = (int)(v * maxBrushSize);
		});
	}

	private IEnumerator ClearToolSelectionNextFrame()
	{
		yield return null;
		if (brushMode != BrushMode.None)
		{
			ClearBrush();
		}
		else
		{
			MapEditorPaletteUI.ClearToolToggles();
		}
	}

	private void SetBrushMode(BrushMode brush)
	{
		CommitPaintStroke();
		brushMode = brush;
		lastCell = null;
	}

	public void SetBarrenLand()
	{
		SetBrushMode(BrushMode.BarrenLand);
	}

	public void SetFertileLand()
	{
		SetBrushMode(BrushMode.FertileLand);
	}

	public void SetVeryFertileLand()
	{
		SetBrushMode(BrushMode.VeryFertileLand);
	}

	public void SetForest()
	{
		SetBrushMode(BrushMode.Forest);
	}

	public void SetShallowWater()
	{
		SetBrushMode(BrushMode.ShallowWater);
	}

	public void SetDeepWater()
	{
		SetBrushMode(BrushMode.DeepWater);
	}

	public void SetUnusableStone()
	{
		SetBrushMode(BrushMode.UnusableStone);
	}

	public void SetStone()
	{
		SetBrushMode(BrushMode.Stone);
	}

	public void SetIron()
	{
		SetBrushMode(BrushMode.Iron);
	}

	public void SetEmptyCave()
	{
		SetBrushMode(BrushMode.EmptyCave);
	}

	public void SetFish()
	{
		SetBrushMode(BrushMode.Fish);
	}

	public void SetMarble()
	{
		SetBrushMode(BrushMode.Marble);
	}

	public void SetScatterRocks()
	{
		SetBrushMode(BrushMode.ScatterRocks);
	}

	public void SetErase()
	{
		SetBrushMode(BrushMode.Erase);
	}

	private void ApplyDeposit(Cell c, int resourceType)
	{
		World.inst.treeSystem.DeleteTreesAt(c);
		if (c.Type == TerrainType.Water)
		{
			TerrainGen.inst.SetLandTile(c.x, c.z);
			TerrainGen.inst.AddNoise(c);
		}
		c.Type = TerrainType.None;
		Object.Instantiate(TerrainGen.inst.GetTerrainResourcePrefabOfType(resourceType)).Init(Vector2.one, c);
	}

	private static bool Is1x1DepositOfType(Cell c, int resourceType)
	{
		if (c != null && c.terrainResource != null && c.terrainResource.sizeX == 1 && c.terrainResource.sizeZ == 1)
		{
			return c.terrainResource.resourceID == resourceType;
		}
		return false;
	}

	private void MergeDepositClusters(Cell center, int r)
	{
		for (int i = center.z - r; i <= center.z + r; i++)
		{
			for (int j = center.x - r; j <= center.x + r; j++)
			{
				Cell cellData = World.inst.GetCellData(j, i);
				if (cellData != null && !(cellData.terrainResource == null) && cellData.terrainResource.sizeX == 1 && cellData.terrainResource.sizeZ == 1)
				{
					int resourceID = cellData.terrainResource.resourceID;
					Cell cellData2 = World.inst.GetCellData(j + 1, i);
					Cell cellData3 = World.inst.GetCellData(j, i + 1);
					Cell cellData4 = World.inst.GetCellData(j + 1, i + 1);
					if (Is1x1DepositOfType(cellData2, resourceID) && Is1x1DepositOfType(cellData3, resourceID) && Is1x1DepositOfType(cellData4, resourceID))
					{
						TerrainResource.Remove(cellData.terrainResource);
						TerrainResource.Remove(cellData2.terrainResource);
						TerrainResource.Remove(cellData3.terrainResource);
						TerrainResource.Remove(cellData4.terrainResource);
						Object.Instantiate(TerrainGen.inst.GetTerrainResourcePrefabOfType(resourceID)).Init(new Vector2(2f, 2f), cellData);
					}
				}
			}
		}
	}

	private void ApplyEmptyCave(Cell c)
	{
		c.Type = TerrainType.EmptyCave;
		TerrainGen.inst.SetLandTile(c.x, c.z);
		TerrainGen.inst.AddNoise(c);
		World.inst.AddEmptyCave(c.x, c.z).replaceOnKeepPlacement = true;
	}

	private void ApplyDeepWater(Cell c)
	{
		World.inst.treeSystem.DeleteTreesAt(c);
		TerrainGen.inst.SetWaterTile(c.x, c.z);
		c.deepWater = true;
		c.landMassIdx = -1;
	}

	private static bool IsFertilityBrush(BrushMode brush)
	{
		if (brush != BrushMode.BarrenLand && brush != BrushMode.FertileLand)
		{
			return brush == BrushMode.VeryFertileLand;
		}
		return true;
	}

	private static bool IsDepositBrush(BrushMode brush)
	{
		if (brush != BrushMode.Stone && brush != BrushMode.Iron)
		{
			return brush == BrushMode.Marble;
		}
		return true;
	}

	public static bool BrushChangesShoreline(BrushMode brush)
	{
		if (brush != BrushMode.ShallowWater && brush != BrushMode.DeepWater && brush != BrushMode.Stone && brush != BrushMode.Iron && brush != BrushMode.Marble)
		{
			return brush == BrushMode.EmptyCave;
		}
		return true;
	}

	private static int DepositTypeFor(BrushMode brush)
	{
		return brush switch
		{
			BrushMode.Marble => 14, 
			BrushMode.Iron => 5, 
			_ => 2, 
		};
	}

	private void ApplyBrush(BrushMode brush, Cell c)
	{
		dirty = true;
		TrackPaintCell(c);
		if (brush == BrushMode.Erase)
		{
			World.inst.treeSystem.DeleteTreesAt(c);
			World.inst.rockScatterSystem.DeleteTreesAt(c);
			FishSystem.inst.ForceClearFish(c.x, c.z);
			if (c.terrainResource != null)
			{
				TerrainResource.Remove(c.terrainResource);
				if (c.Type == TerrainType.Obstruction)
				{
					c.Type = TerrainType.None;
				}
			}
			resourceLabelsDirty = true;
			MarkEraseDirty(c);
		}
		else
		{
			if (IsDepositBrush(brush) && c.terrainResource != null && c.terrainResource.resourceID == DepositTypeFor(brush))
			{
				return;
			}
			if (IsFertilityBrush(brush))
			{
				if (c.Type != TerrainType.Water)
				{
					TerrainGen.inst.SetFertilityNoiseForCell(c.x, c.z, TerrainGen.inst.GetPaintNoiseForFertility(c.x, c.z, brush switch
					{
						BrushMode.FertileLand => 1, 
						BrushMode.BarrenLand => 0, 
						_ => 2, 
					}));
				}
				return;
			}
			switch (brush)
			{
			case BrushMode.ScatterRocks:
				if (c.Type == TerrainType.None && World.inst.GetCardinalAdjacentType(c.x, c.z, TerrainType.Water) == null && World.inst.rockScatterSystem.ItemAmount(c) == 0)
				{
					int num = SRand.Range(1, 3);
					for (int i = 0; i < num; i++)
					{
						World.inst.rockScatterSystem.PlaceItem(c);
					}
				}
				return;
			case BrushMode.Forest:
				if (c.Type == TerrainType.None && World.inst.treeSystem.ItemAmount(c) == 0)
				{
					int num2 = SRand.Range(1, 5);
					for (int j = 0; j < num2; j++)
					{
						World.inst.treeSystem.PlaceItem(c);
					}
				}
				return;
			case BrushMode.Fish:
				if (c.Type == TerrainType.Water)
				{
					FishSystem.inst.ForceFish(c.x, c.z);
					resourceLabelsDirty = true;
				}
				return;
			}
			if (c.terrainResource != null || IsDepositBrush(brush))
			{
				resourceLabelsDirty = true;
			}
			if (brush != BrushMode.None)
			{
				World.inst.ClearRocksDuringEdit(c);
			}
			c.deepWater = false;
			FishSystem.inst.ForceClearFish(c.x, c.z);
			switch (brush)
			{
			case BrushMode.ShallowWater:
				World.inst.treeSystem.DeleteTreesAt(c);
				TerrainGen.inst.SetWaterTile(c.x, c.z);
				TerrainGen.inst.SetBakedTileHeight(c.x, c.z, TerrainGen.waterHeightShallow - SRand.value * 0.1f);
				TerrainGen.inst.AddNoise(c);
				c.landMassIdx = -1;
				break;
			case BrushMode.DeepWater:
				ApplyDeepWater(c);
				break;
			case BrushMode.Stone:
				ApplyDeposit(c, 2);
				break;
			case BrushMode.Iron:
				ApplyDeposit(c, 5);
				break;
			case BrushMode.Marble:
				ApplyDeposit(c, 14);
				break;
			case BrushMode.EmptyCave:
				ApplyEmptyCave(c);
				break;
			case BrushMode.UnusableStone:
			case BrushMode.Fish:
				break;
			}
		}
	}

	private void MarkEraseDirty(Cell c)
	{
		if (!eraseDirtyValid)
		{
			eraseMinX = (eraseMaxX = c.x);
			eraseMinZ = (eraseMaxZ = c.z);
			eraseDirtyValid = true;
			return;
		}
		if (c.x < eraseMinX)
		{
			eraseMinX = c.x;
		}
		if (c.x > eraseMaxX)
		{
			eraseMaxX = c.x;
		}
		if (c.z < eraseMinZ)
		{
			eraseMinZ = c.z;
		}
		if (c.z > eraseMaxZ)
		{
			eraseMaxZ = c.z;
		}
	}

	private void FlushEraseReclassify()
	{
		if (eraseDirtyValid)
		{
			eraseDirtyValid = false;
			TerrainRockReclassifier.ReclassifyVertRect(Mathf.Max(0, (eraseMinX - 1) * 2), Mathf.Max(0, (eraseMinZ - 1) * 2), Mathf.Min(World.MeshWidth - 1, (eraseMaxX + 1) * 2 + 2), Mathf.Min(World.MeshHeight - 1, (eraseMaxZ + 1) * 2 + 2));
		}
	}

	private void TrackPaintCell(Cell c)
	{
		if (currentStroke == null)
		{
			currentStroke = new PaintStrokeUndo();
		}
		if (currentStroke.cells.ContainsKey(c))
		{
			return;
		}
		CellSnapshot cellSnapshot = new CellSnapshot
		{
			type = c.Type,
			deepWater = c.deepWater,
			fertilityNoise = TerrainGen.inst.GetFertilityNoiseForCell(c.x, c.z),
			treeCount = World.inst.treeSystem.ItemAmount(c),
			rockCount = World.inst.rockScatterSystem.ItemAmount(c)
		};
		FishSystem.FishCell fishCell = FishSystem.inst.fishCells[c.z * World.inst.GridWidth + c.x];
		cellSnapshot.hadFish = fishCell.owners.Count > 0 || fishCell.baseProbability >= 0.99f;
		int num = 0;
		for (int i = 0; i <= 2; i++)
		{
			for (int j = 0; j <= 2; j++)
			{
				cellSnapshot.vertHeights[num++] = TerrainGen.inst.GetVertY(c.x * 2 + i, c.z * 2 + j);
			}
		}
		currentStroke.cells[c] = cellSnapshot;
		TerrainResource terrainResource = c.terrainResource;
		if (!(terrainResource != null) || !currentStroke.seenDeposits.Add(terrainResource))
		{
			return;
		}
		currentStroke.deposits.Add(new DepositSnapshot
		{
			x = terrainResource.x,
			z = terrainResource.z,
			sizeX = terrainResource.sizeX,
			sizeZ = terrainResource.sizeZ,
			resourceID = terrainResource.resourceID
		});
		for (int k = 0; k < terrainResource.sizeX; k++)
		{
			for (int l = 0; l < terrainResource.sizeZ; l++)
			{
				Cell cellData = World.inst.GetCellData(terrainResource.x + k, terrainResource.z + l);
				if (cellData != null)
				{
					TrackPaintCell(cellData);
				}
			}
		}
	}

	private void CommitPaintStroke()
	{
		if (currentStroke != null && currentStroke.cells.Count > 0)
		{
			MapEditorUndoStack.Push(currentStroke);
			Water.UpdateNeeded = true;
		}
		currentStroke = null;
	}

	private void RestorePaintStroke(PaintStrokeUndo stroke)
	{
		int num = int.MaxValue;
		int num2 = int.MinValue;
		int num3 = int.MaxValue;
		int num4 = int.MinValue;
		foreach (Cell key2 in stroke.cells.Keys)
		{
			if (key2.terrainResource != null)
			{
				TerrainResource.Remove(key2.terrainResource);
			}
		}
		foreach (KeyValuePair<Cell, CellSnapshot> cell in stroke.cells)
		{
			Cell key = cell.Key;
			CellSnapshot value = cell.Value;
			if (key.x < num)
			{
				num = key.x;
			}
			if (key.x > num2)
			{
				num2 = key.x;
			}
			if (key.z < num3)
			{
				num3 = key.z;
			}
			if (key.z > num4)
			{
				num4 = key.z;
			}
			int num5 = 0;
			for (int i = 0; i <= 2; i++)
			{
				for (int j = 0; j <= 2; j++)
				{
					TerrainGen.inst.SetVert(key.x * 2 + i, key.z * 2 + j, value.vertHeights[num5++], bakeDown: true);
				}
			}
			key.Type = value.type;
			key.deepWater = value.deepWater;
			TerrainGen.inst.SetFertilityNoiseForCell(key.x, key.z, value.fertilityNoise);
			World.inst.treeSystem.DeleteTreesAt(key);
			for (int k = 0; k < value.treeCount; k++)
			{
				World.inst.treeSystem.PlaceItem(key);
			}
			World.inst.rockScatterSystem.DeleteTreesAt(key);
			for (int l = 0; l < value.rockCount; l++)
			{
				World.inst.rockScatterSystem.PlaceItem(key);
			}
			if (value.hadFish)
			{
				FishSystem.inst.ForceFish(key.x, key.z);
			}
			else
			{
				FishSystem.inst.ForceClearFish(key.x, key.z);
			}
			key.StorePostGenerationType();
		}
		foreach (DepositSnapshot deposit in stroke.deposits)
		{
			Cell cellData = World.inst.GetCellData(deposit.x, deposit.z);
			if (cellData != null && !(cellData.terrainResource != null))
			{
				Object.Instantiate(TerrainGen.inst.GetTerrainResourcePrefabOfType(deposit.resourceID)).Init(new Vector2(deposit.sizeX, deposit.sizeZ), cellData);
			}
		}
		TerrainGen.inst.UpdateTextures();
		TerrainGen.inst.UpdateTerrainDeformations();
		if (num2 >= num)
		{
			TerrainRockReclassifier.ReclassifyVertRect(Mathf.Max(0, (num - 1) * 2), Mathf.Max(0, (num3 - 1) * 2), Mathf.Min(World.MeshWidth - 1, (num2 + 1) * 2 + 2), Mathf.Min(World.MeshHeight - 1, (num4 + 1) * 2 + 2));
		}
		World.inst.ShowResourceGroupTooltipUIs(-1, doShowFish: true);
		dirty = true;
	}

	public void IncreaseRadius()
	{
		radius++;
		if (radius > maxBrushSize)
		{
			radius = maxBrushSize;
		}
		brushSizeSlider.SetValueWithoutNotify(radius / maxBrushSize);
	}

	public void DecreaseRadius()
	{
		radius--;
		if (radius < 0f)
		{
			radius = 0f;
		}
		brushSizeSlider.SetValueWithoutNotify(radius / maxBrushSize);
	}

	private void StampBrush(Cell center)
	{
		if (center == null)
		{
			return;
		}
		World.inst.ForEachTileTouchingRadius(center.Center2D, radius, (int x, int z, Cell c) =>
		{
			if (c.x > 0 && c.z > 0 && c.x < World.inst.GridWidth - 1 && c.z < World.inst.GridHeight - 1)
			{
				ApplyBrush(brushMode, c);
			}
		});
		if (center.x > 0 && center.z > 0 && center.x < World.inst.GridWidth - 1 && center.z < World.inst.GridHeight - 1)
		{
			ApplyBrush(brushMode, center);
		}
		World.inst.ForEachTileTouchingRadius(center.Center2D, radius + 2f, (int x, int z, Cell c) =>
		{
			if (c.Type == TerrainType.Water && brushMode != BrushMode.None && brushMode != BrushMode.ShallowWater && brushMode != BrushMode.DeepWater && brushMode != BrushMode.Fish && brushMode != BrushMode.ScatterRocks && brushMode != BrushMode.Forest && brushMode != BrushMode.Erase && !IsFertilityBrush(brushMode) && c.x > 0 && c.z > 0 && c.x < World.inst.GridWidth - 1 && c.z < World.inst.GridHeight - 1)
			{
				ApplyBrush(BrushMode.ShallowWater, c);
			}
		});
		if (IsDepositBrush(brushMode))
		{
			MergeDepositClusters(center, Mathf.CeilToInt(radius) + 1);
		}
	}

	private void OnDisable()
	{
		if ((bool)Cam.inst)
		{
			Cam.inst.disableDrag = false;
		}
	}

	public void ClearBrush()
	{
		CommitPaintStroke();
		brushMode = BrushMode.None;
		TerrainGen.inst.FadeOverlay(0f);
		MapEditorPaletteUI.ClearToolToggles();
	}

	private void Update()
	{
		brushSize.SetText("{0}", radius + 1f);
		Vector3 worldPos = MapSelectionTool.CursorWaterFloorPoint();
		Cell cellData = World.inst.GetCellData(worldPos);
		if (PointingSystem.GetPointer().GetPrimaryDownThisFrame() && !GameUI.inst.PointerOverUI() && brushMode != BrushMode.None)
		{
			if (lastCell != cellData && cellData != null)
			{
				if (lastCell == null || Mathf.Abs(cellData.x - lastCell.x) + Mathf.Abs(cellData.z - lastCell.z) > 64)
				{
					StampBrush(cellData);
				}
				else
				{
					foreach (int item in GridLine.Walk(lastCell.index, cellData.index, World.inst.GridWidth))
					{
						if (item != lastCell.index)
						{
							StampBrush(World.inst.GetCellDataUnsafe(item));
						}
					}
				}
				TerrainGen.inst.UpdateTextures();
				Cell[] cellsData = World.inst.GetCellsData();
				for (int i = 0; i < cellsData.Length; i++)
				{
					cellsData[i].StorePostGenerationType();
				}
			}
			lastCell = cellData;
		}
		if (PointingSystem.GetPointer().GetPrimaryUp() && brushMode != BrushMode.None)
		{
			lastCell = null;
			FlushEraseReclassify();
			CommitPaintStroke();
			if (resourceLabelsDirty)
			{
				resourceLabelsDirty = false;
				World.inst.ShowResourceGroupTooltipUIs(-1, doShowFish: true);
			}
		}
		if (PointingSystem.GetPointer().GetSecondaryDown())
		{
			rightMouseDownPos = Input.mousePosition;
		}
		if (PointingSystem.GetPointer().GetSecondaryUp() && Vector3.Distance(rightMouseDownPos, Input.mousePosition) < 4f && brushMode != BrushMode.None)
		{
			brushMode = BrushMode.None;
			lastCell = null;
			TerrainGen.inst.FadeOverlay(0f);
			MapEditorPaletteUI.ClearToolToggles();
		}
		if (cellData != null && brushMode != BrushMode.None)
		{
			Vector3 center2D = cellData.Center2D;
			center2D.y = Mathf.Max(0f, center2D.y);
			TerrainGen.inst.ClearOverlay(updateToo: false);
			TerrainGen.inst.SetOverlayCircle(center2D, radius, cursorColor);
			TerrainGen.inst.FadeOverlay(1f);
		}
	}
}
