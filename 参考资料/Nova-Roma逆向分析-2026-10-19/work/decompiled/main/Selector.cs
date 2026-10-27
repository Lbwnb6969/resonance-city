using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class Selector : MonoBehaviour
{
	public enum Mode
	{
		Selecting,
		Highlighting
	}

	[Serializable]
	private struct Brush
	{
		public string uniqueName;

		public GameObject brushObj;

		public int hashCode;

		public void GenerateHashCode()
		{
			if (uniqueName != string.Empty)
			{
				hashCode = uniqueName.GetHashCode();
			}
		}

		public override bool Equals(object obj)
		{
			if (obj is Brush brush)
			{
				return brush.hashCode == hashCode;
			}
			if (obj == null)
			{
				return uniqueName == string.Empty;
			}
			return base.Equals(obj);
		}

		public static bool operator ==(Brush b1, object obj)
		{
			return b1.Equals(obj);
		}

		public override int GetHashCode()
		{
			return hashCode;
		}

		public static bool operator !=(Brush b1, object obj)
		{
			return !b1.Equals(obj);
		}
	}

	private static List<Selector> Selectors = new List<Selector>(8);

	private string uniqueName = "";

	private int hashCode = -1;

	private static List<Brush> BrushCollection = new List<Brush>(32);

	public Mode mode = Mode.Highlighting;

	[SerializeField]
	private List<Brush> brushes;

	private GameObject brushContainer;

	private Brush activeBrush;

	private bool isVisible;

	public GameObject highlightGO;

	private static Material highlightMaterialPrefab;

	private static Material cornerMaterialPrefab;

	private static Mesh singleCellMesh;

	private static Mesh multiCellMesh;

	[Header("Color Settings")]
	public Color baseColor;

	public Color baseEdgeColor;

	public Color baseCornerColor;

	public Color baseGridColor;

	private Material highlightMaterial;

	private Material cornerMaterial;

	private static Color[] selectionTextureColors;

	private static Texture2D selectionTexture;

	public static bool dirtySelectionTexture = false;

	private const float MIN_VERT_HEIGHT = 0f;

	private static readonly int PROP_SELECTION_TEXTURE = Shader.PropertyToID("_SelectionTexture");

	private static readonly int PROP_HIGHLIGHT_COLOR = Shader.PropertyToID("_Color");

	private static readonly int PROP_EDGE_COLOR = Shader.PropertyToID("_EdgeColor");

	private static readonly int PROP_GRID_COLOR = Shader.PropertyToID("_GridLineColor");

	private static readonly int PROP_WORLD_DIMENSIONS = Shader.PropertyToID("_WorldDimension");

	private static readonly int PROP_HIGHLIGHNT_CENTER = Shader.PropertyToID("_HighlightCenter");

	private static readonly int PROP_HIGHLIGHNT_SIZE = Shader.PropertyToID("_HighlightSize");

	private static readonly int PROP_HIGHLIGHT_GRID_THICKNESS = Shader.PropertyToID("_GridLinesThickness");

	private static readonly int PROP_CORNER_COLOR = Shader.PropertyToID("_Color");

	private static int prevWidth = -1;

	private static int prevTextureWidth = -1;

	private static int prevHeight = -1;

	private static int prevTextureHeight = -1;

	private Vector3 targetSize;

	private Vector3 targetPos;

	[Header("Animation Settings")]
	public float translateSpeed = 1f;

	public float scaleSpeed = 1f;

	[Header("Corner Settings")]
	private Transform[] corners;

	public float cornerYOffset;

	public float cornerXZOffset;

	public float cornerMaxXZOffset;

	public float cornerScaleInSpeed = 1f;

	private float cornerScaleIn = 1f;

	private Transform cornerContainer;

	public RectTransform heightCanvasRectT;

	public Canvas heightCanvas;

	public TextMeshProUGUI heightTMP;

	public RectTransform heightContainer;

	public RectTransform widthCanvasRectT;

	public Canvas widthCanvas;

	public TextMeshProUGUI widthTMP;

	public RectTransform widthContainer;

	public AnimationCurve distToSizeCurve;

	public bool doShowWorldSizes;

	private static bool EDITOR_DEBUG = false;

	private Vector3 cornerPos;

	private Vector3 cornerNormal;

	private static bool TryAddBrushToCollection(Brush b)
	{
		for (int i = 0; i < BrushCollection.Count; i++)
		{
			if (BrushCollection[i].hashCode == b.hashCode)
			{
				return false;
			}
		}
		BrushCollection.Add(b);
		return true;
	}

	public static bool CopyBrushGameObject(string uniqueName, out GameObject go)
	{
		go = null;
		for (int i = 0; i < BrushCollection.Count; i++)
		{
			Brush brush = BrushCollection[i];
			if (uniqueName == brush.uniqueName)
			{
				go = UnityEngine.Object.Instantiate(brush.brushObj);
				return true;
			}
		}
		return false;
	}

	public static bool GetSelector(string uniqueName, out Selector selector)
	{
		selector = null;
		for (int i = 0; i < Selectors.Count; i++)
		{
			if (Selectors[i].uniqueName == uniqueName)
			{
				selector = Selectors[i];
				return true;
			}
		}
		Debug.Log("Ensure Selector.SetupSelectorLookup(uniqueName) is called first");
		return false;
	}

	public static void UpdateTextureForAllHeights()
	{
		InitOrReset();
		for (int i = 0; i < selectionTextureColors.Length; i++)
		{
			int meshZ = i / prevTextureWidth;
			int meshX = i % prevTextureWidth;
			selectionTextureColors[i] = new Color(Mathff.Max(0f, TerrainGen.inst.GetVertY(meshX, meshZ)), 0f, 0f);
		}
		selectionTexture.SetPixels(selectionTextureColors);
		selectionTexture.Apply();
	}

	public static void UpdateTextureForChunkHeights(TerrainChunk chunk)
	{
		InitOrReset();
		Vector3 vector = new Vector2(chunk.x, chunk.z);
		Vector2 vector2 = new Vector2(chunk.MeshSizeX, chunk.MeshSizeZ);
		for (int i = 0; (float)i < vector2.y; i++)
		{
			for (int j = 0; (float)j < vector2.x; j++)
			{
				int num = ((int)vector.y + i) * prevTextureWidth + (int)vector.x + j;
				if (num < selectionTextureColors.Length)
				{
					selectionTextureColors[num] = new Color(Mathff.Max(0f, TerrainGen.inst.GetVertY((int)vector.x + j, (int)vector.y + i)), 0f, 0f);
				}
				else
				{
					Debug.Log($"Exceeding Selection Texture Color Length! x:{vector.x + (float)j} z:{vector.y + (float)i}");
				}
			}
		}
		dirtySelectionTexture = true;
	}

	public static void TryApplyTexture()
	{
		if (dirtySelectionTexture)
		{
			selectionTexture.SetPixels(selectionTextureColors);
			selectionTexture.Apply();
			dirtySelectionTexture = false;
		}
	}

	public static void InitOrReset()
	{
		bool flag = prevWidth != World.inst.GridWidth || prevHeight != World.inst.GridHeight;
		if ((selectionTexture == null) | flag)
		{
			selectionTexture = new Texture2D(World.inst.GridWidth * 2 + 1, World.inst.GridHeight * 2 + 1, TextureFormat.RGBAFloat, mipChain: false);
			selectionTexture.name = "SelectionTexture";
			selectionTexture.filterMode = FilterMode.Trilinear;
		}
		if ((selectionTextureColors == null) | flag)
		{
			selectionTextureColors = new Color[selectionTexture.width * selectionTexture.height];
		}
		if (flag)
		{
			for (int i = 0; i < Selectors.Count; i++)
			{
				Selectors[i].ResetMaterials();
			}
			prevWidth = World.inst.GridWidth;
			prevTextureWidth = selectionTexture.width;
			prevHeight = World.inst.GridHeight;
			prevTextureHeight = selectionTexture.height;
		}
	}

	public bool IsBrushActive()
	{
		return activeBrush != null;
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	private void Awake()
	{
		highlightGO = transform.GetChild(0).gameObject;
		if (highlightMaterial == null)
		{
			highlightMaterialPrefab = Resources.Load<Material>("Brushes/Materials/Highlight");
		}
		if (cornerMaterialPrefab == null)
		{
			cornerMaterialPrefab = Resources.Load<Material>("Brushes/Materials/CornerHighlight");
		}
		if (singleCellMesh == null)
		{
			singleCellMesh = Resources.Load<Mesh>("Brushes/HighlightMeshes/SingleCellMesh");
		}
		if (multiCellMesh == null)
		{
			multiCellMesh = Resources.Load<Mesh>("Brushes/HighlightMeshes/MultiCellMesh");
		}
		cornerContainer = transform.Find("Corners");
		corners = new Transform[cornerContainer.childCount];
		for (int i = 0; i < cornerContainer.childCount; i++)
		{
			corners[i] = cornerContainer.GetChild(i);
		}
		brushContainer = transform.Find("Brush Container")?.gameObject;
		if (brushContainer == null)
		{
			brushContainer = new GameObject("Brush Container");
			brushContainer.transform.SetParent(transform, worldPositionStays: false);
		}
		for (int j = 0; j < brushes.Count; j++)
		{
			brushes[j].GenerateHashCode();
			TryAddBrushToCollection(brushes[j]);
		}
		ResetMaterials();
		Selectors.Add(this);
		gameObject.SetActive(value: false);
	}

	public bool SetupSelectorLookup(string uniqueHighlightName)
	{
		int num = uniqueHighlightName.GetHashCode();
		for (int i = 0; i < Selectors.Count; i++)
		{
			if (Selectors[i].hashCode == num)
			{
				return false;
			}
		}
		transform.name = uniqueHighlightName;
		uniqueName = uniqueHighlightName;
		hashCode = num;
		return true;
	}

	public void SetSingleCellMesh()
	{
		if (highlightGO == null)
		{
			Debug.Log("Selector Not Initialized Yet");
		}
		else
		{
			highlightGO.GetComponent<MeshFilter>().mesh = singleCellMesh;
		}
	}

	public void SetMultiCellMesh()
	{
		if (highlightGO == null)
		{
			Debug.Log("Selector Not Initialized Yet");
		}
		else
		{
			highlightGO.GetComponent<MeshFilter>().mesh = multiCellMesh;
		}
	}

	public void DisableCorners()
	{
		for (int i = 0; i < corners.Length; i++)
		{
			corners[i].GetComponentInChildren<Renderer>().enabled = false;
		}
	}

	public void ResetMaterials()
	{
		if (highlightMaterial == null)
		{
			highlightMaterial = UnityEngine.Object.Instantiate(highlightMaterialPrefab);
			highlightMaterial.SetColor(PROP_HIGHLIGHT_COLOR, baseColor);
			highlightMaterial.SetColor(PROP_EDGE_COLOR, baseEdgeColor);
			highlightMaterial.SetColor(PROP_GRID_COLOR, baseGridColor);
			MeshRenderer component = highlightGO.GetComponent<MeshRenderer>();
			component.material = highlightMaterial;
			component.bounds.SetMinMax(new Vector3(0f, 0f, 0f), new Vector3(World.inst.GridWidth, 100f, World.inst.GridHeight));
		}
		if (cornerMaterial == null)
		{
			cornerMaterial = UnityEngine.Object.Instantiate(cornerMaterialPrefab);
			cornerMaterial.SetColor(PROP_CORNER_COLOR, baseCornerColor);
			for (int i = 0; i < corners.Length; i++)
			{
				if (!(corners[i] == null))
				{
					Renderer componentInChildren = corners[i].GetComponentInChildren<Renderer>();
					if (componentInChildren != null)
					{
						componentInChildren.material = cornerMaterial;
					}
				}
			}
		}
		highlightMaterial.SetTexture(PROP_SELECTION_TEXTURE, selectionTexture);
		highlightMaterial.SetVector(PROP_WORLD_DIMENSIONS, new Vector4(World.inst.GridWidth, World.inst.GridHeight, 1f, 1f));
		ResetBrushes();
	}

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		for (int i = 0; i < corners.Length; i++)
		{
			corners[i].gameObject.SetActive(isVisible);
		}
		if (isVisible)
		{
			transform.position = Vector3.Lerp(transform.position, targetPos, unscaledDeltaTime * translateSpeed);
			highlightGO.transform.localScale = Vector3.Lerp(highlightGO.transform.localScale, targetSize, unscaledDeltaTime * scaleSpeed);
			if (highlightMaterial != null)
			{
				highlightMaterial.SetVector(PROP_HIGHLIGHNT_CENTER, new Vector4(transform.position.x, transform.position.z));
				highlightMaterial.SetVector(PROP_HIGHLIGHNT_SIZE, new Vector4(highlightGO.transform.localScale.x, highlightGO.transform.localScale.z));
			}
			switch (mode)
			{
			case Mode.Highlighting:
				cornerScaleIn = Mathff.Clamp01(cornerScaleIn - unscaledDeltaTime * cornerScaleInSpeed);
				break;
			case Mode.Selecting:
				cornerScaleIn = Mathff.Clamp01(cornerScaleIn + unscaledDeltaTime * cornerScaleInSpeed);
				break;
			}
			Vector3 localScale = highlightGO.transform.localScale;
			Vector3 position = transform.position;
			float x = position.x - localScale.x / 2f;
			float z = position.z - localScale.z / 2f;
			float x2 = position.x + localScale.x / 2f;
			float z2 = position.z + localScale.z / 2f;
			UpdateCorner(x, z, -1f, -1f, 0);
			UpdateCorner(x2, z, 1f, -1f, 1);
			UpdateCorner(x, z2, -1f, 1f, 2);
			UpdateCorner(x2, z2, 1f, 1f, 3);
			if (doShowWorldSizes)
			{
				Vector3 camPos = Cam.inst.CamPos;
				Vector3 forward = widthContainer.position - camPos;
				Vector3 forward2 = heightContainer.position - camPos;
				widthContainer.rotation = Quaternion.LookRotation(forward, Vector3.up);
				heightContainer.rotation = Quaternion.LookRotation(forward2, Vector3.up);
			}
			float interpolatedHeightWithNormal = TerrainGen.inst.GetInterpolatedHeightWithNormal(targetPos, out var normal);
			brushContainer.transform.localPosition = new Vector3(0f, Mathff.Max(0f, interpolatedHeightWithNormal) + 0.1f, 0f);
			brushContainer.transform.localRotation = Quaternion.FromToRotation(Vector3.up, normal);
		}
		cornerContainer.gameObject.SetActive(isVisible);
	}

	private void UpdateCorner(float x, float z, float dirX, float dirZ, int idx)
	{
		float num = cornerScaleIn * cornerMaxXZOffset + cornerXZOffset;
		cornerPos.x = x + num * dirX;
		cornerPos.z = z + num * dirZ;
		cornerPos.y = TerrainGen.inst.GetInterpolatedHeightWithNormal(cornerPos, out cornerNormal);
		if (cornerPos.y < 0f)
		{
			cornerPos.y = 0f;
			cornerNormal = Vector3.up;
		}
		cornerPos.y += cornerYOffset;
		corners[idx].position = cornerPos;
		corners[idx].localRotation = Quaternion.FromToRotation(Vector3.up, cornerNormal);
	}

	public void SetVisibility(bool v)
	{
		isVisible = v;
		gameObject.SetActive(v);
		if (!v)
		{
			if (mode == Mode.Selecting)
			{
				cornerScaleIn = 0f;
			}
			highlightGO.SetActive(value: false);
			Util.SetEnabled(widthCanvas, active: false);
			Util.SetEnabled(heightCanvas, active: false);
			cornerContainer.gameObject.SetActive(value: false);
		}
	}

	public void SetTargetWorldBounds(Vector3 center, Vector3 newSize)
	{
		center.y = 0f;
		newSize.y = 1f;
		float num = highlightMaterial.GetFloat(PROP_HIGHLIGHT_GRID_THICKNESS) * 2f;
		newSize.x += num;
		newSize.z += num;
		targetSize = newSize;
		targetPos = center;
		if (doShowWorldSizes && ((int)newSize.x > 4 || (int)newSize.z > 4))
		{
			float num2 = center.x - newSize.x / 2f;
			float num3 = center.z - newSize.z / 2f;
			float fontSize = distToSizeCurve.Evaluate(Cam.inst.dist);
			Vector3 vector = new Vector3(center.x, 0f, num3 - 0.5f);
			vector.y = Mathff.Max(TerrainGen.SeaLevel, TerrainGen.inst.GetInterpolatedHeight(vector));
			widthCanvasRectT.transform.position = vector;
			widthTMP.fontSize = fontSize;
			Util.SetEnabled(widthCanvas, active: true);
			vector.x = num2 - 0.5f;
			vector.z = center.z;
			vector.y = Mathff.Max(TerrainGen.SeaLevel, TerrainGen.inst.GetInterpolatedHeight(vector));
			heightCanvasRectT.transform.position = vector;
			heightTMP.fontSize = fontSize;
			Util.SetEnabled(heightCanvas, active: true);
			widthTMP.text = newSize.x.ToString("0");
			heightTMP.text = newSize.z.ToString("0");
		}
		else
		{
			Util.SetEnabled(widthCanvas, active: false);
			Util.SetEnabled(heightCanvas, active: false);
		}
		if (!highlightGO.activeSelf)
		{
			transform.position = targetPos;
			highlightGO.transform.localScale = targetSize;
			if (highlightMaterial != null)
			{
				highlightMaterial.SetVector(PROP_HIGHLIGHNT_CENTER, new Vector4(transform.position.x, transform.position.z));
				highlightMaterial.SetVector(PROP_HIGHLIGHNT_SIZE, new Vector4(highlightGO.transform.localScale.x, highlightGO.transform.localScale.z));
			}
			highlightGO.SetActive(value: true);
		}
	}

	public void SetTargetWorldBounds(int minX, int maxX, int minZ, int maxZ)
	{
		targetSize = new Vector3(maxX - minX, 1f, maxZ - minZ);
		targetPos = new Vector3((float)(minX + maxX) * 0.5f, 0f, (float)(minZ + maxZ) * 0.5f);
		SetTargetWorldBounds(targetPos, targetSize);
	}

	public bool SetBrush(string uniqueName)
	{
		int brush = uniqueName.GetHashCode();
		return SetBrush(brush);
	}

	public bool SetBrush(int hash)
	{
		bool flag = false;
		for (int i = 0; i < brushes.Count; i++)
		{
			Brush brush = brushes[i];
			if (!(brush.brushObj == null))
			{
				if (!flag)
				{
					flag = hash == brush.hashCode;
					activeBrush = brush;
				}
				brush.brushObj.SetActive(hash == brush.hashCode);
			}
		}
		return flag;
	}

	public void ResetBrushes()
	{
		for (int i = 0; i < brushes.Count; i++)
		{
			brushes[i].brushObj.SetActive(value: false);
		}
		activeBrush = default;
	}

	public bool AddBrush(string uniqueName, GameObject go)
	{
		Brush brush = new Brush
		{
			uniqueName = uniqueName
		};
		brush.GenerateHashCode();
		for (int i = 0; i < brushes.Count; i++)
		{
			if (brushes[i].hashCode == brush.hashCode)
			{
				Debug.Log("Brush Already Exists: " + uniqueName);
				return false;
			}
		}
		brush.brushObj = UnityEngine.Object.Instantiate(go, brushContainer.transform, worldPositionStays: false);
		brushes.Add(brush);
		TryAddBrushToCollection(brush);
		return true;
	}

	public void SetHoverIcon(GameUI.HoverIcons newIcon)
	{
	}

	public void SetHighlightColor(Color color)
	{
		if (!(highlightMaterial == null))
		{
			highlightMaterial.SetColor(PROP_HIGHLIGHT_COLOR, color);
		}
	}

	public void SetEdgeColor(Color color)
	{
		if (!(highlightMaterial == null))
		{
			highlightMaterial.SetColor(PROP_EDGE_COLOR, color);
		}
	}

	public void SetCornerColor(Color color)
	{
		if (!(cornerMaterial == null))
		{
			cornerMaterial.SetColor(PROP_CORNER_COLOR, color);
		}
	}

	public void ResetHighlightColor()
	{
		SetHighlightColor(baseColor);
	}

	public void ApplyColors()
	{
		SetHighlightColor(baseColor);
		SetEdgeColor(baseEdgeColor);
		SetCornerColor(baseCornerColor);
	}
}
