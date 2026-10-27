using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[DisallowMultipleComponent]
[RequireComponent(typeof(Graphic))]
[ExecuteAlways]
public class RectUnionSDFController : MonoBehaviour
{
	private const int MaxRects = 32;

	private const string ShaderName = "UI/RectUnionSDF";

	private const int GradientTextureWidth = 64;

	private static readonly int RectsId = Shader.PropertyToID("_Rects");

	private static readonly int RectCountId = Shader.PropertyToID("_RectCount");

	private static readonly int GradientWidthId = Shader.PropertyToID("_GradientWidth");

	private static readonly int GradientTexId = Shader.PropertyToID("_GradientTex");

	private static readonly int CornerRadiusId = Shader.PropertyToID("_CornerRadius");

	private static readonly int TextureOpacityId = Shader.PropertyToID("_TextureOpacity");

	[Tooltip("Pixels over which the gradient is evaluated.")]
	[SerializeField]
	private float gradientWidth = 10f;

	[Tooltip("Color gradient applied from the rect boundary inward.")]
	[SerializeField]
	private Gradient fillGradient = new Gradient();

	[Tooltip("Pixels used to round the rectangle corners before union.")]
	[SerializeField]
	private float cornerRadius = 3f;

	[Tooltip("Texture tiling applied to the material's MainTex.")]
	[SerializeField]
	private Vector2 textureTiling = Vector2.one;

	[Tooltip("Texture offset applied to the material's MainTex.")]
	[SerializeField]
	private Vector2 textureOffset = Vector2.zero;

	[Tooltip("Opacity multiplier for the overlay texture (matches shader range 0-1).")]
	[Range(0f, 1f)]
	[SerializeField]
	private float textureOpacity = 1f;

	[Tooltip("Optional override for the panel RectTransform. Defaults to the component's RectTransform.")]
	[SerializeField]
	private RectTransform rootRectOverride;

	[Tooltip("Collect all immediate children of this root (or the controller) as SDF rectangles.")]
	[SerializeField]
	private RectTransform handlesRoot;

	[Tooltip("Add explicit RectTransforms in addition to any automatically collected handles.")]
	[SerializeField]
	private List<RectTransform> extraRects = new List<RectTransform>();

	[Tooltip("Ignore handles that are currently inactive in the hierarchy.")]
	[SerializeField]
	private bool ignoreInactive = true;

	[Tooltip("Automatically gather rects from the handles root each frame.")]
	[SerializeField]
	private bool autoCollectChildren = true;

	private readonly Vector4[] rectBuffer = new Vector4[32];

	private readonly List<RectTransform> workingSet = new List<RectTransform>(32);

	private readonly Vector3[] worldCorners = new Vector3[4];

	private Graphic targetGraphic;

	private Material runtimeMaterial;

	private RectTransform rootRect;

	private Canvas cachedCanvas;

	private Vector2 externalTextureScale = Vector2.one;

	private Vector2 externalTextureOffset = Vector2.zero;

	private Texture2D gradientTexture;

	private bool gradientDirty = true;

	public RectTransform RootRect
	{
		get
		{
			if (!(rootRect != null))
			{
				if (!(targetGraphic != null))
				{
					return null;
				}
				return targetGraphic.rectTransform;
			}
			return rootRect;
		}
	}

	private void Awake()
	{
		EnsureGraphicReference();
		RefreshRootRect();
		CacheCanvas();
	}

	private void OnEnable()
	{
		EnsureGraphicReference();
		RefreshRootRect();
		EnsureMaterialInstance();
		UpdateSdfData();
	}

	private void OnDisable()
	{
		CleanupMaterial();
	}

	private void OnDestroy()
	{
		CleanupMaterial();
		CleanupGradientTexture();
	}

	private void CleanupMaterial()
	{
		if (targetGraphic != null && targetGraphic.material == runtimeMaterial)
		{
			targetGraphic.material = null;
		}
		if (!(runtimeMaterial == null))
		{
			if (Application.isPlaying)
			{
				Object.Destroy(runtimeMaterial);
			}
			else
			{
				Object.DestroyImmediate(runtimeMaterial);
			}
			runtimeMaterial = null;
		}
	}

	private void CleanupGradientTexture()
	{
		if (!(gradientTexture == null))
		{
			if (Application.isPlaying)
			{
				Object.Destroy(gradientTexture);
			}
			else
			{
				Object.DestroyImmediate(gradientTexture);
			}
			gradientTexture = null;
		}
	}

	private void LateUpdate()
	{
		UpdateSdfData();
	}

	private void EnsureMaterialInstance()
	{
		if (!(runtimeMaterial != null))
		{
			EnsureGraphicReference();
			Shader shader = Shader.Find("UI/RectUnionSDF");
			if (shader == null)
			{
				Debug.LogError("Unable to find shader 'UI/RectUnionSDF'. Make sure it exists in the project.", this);
				return;
			}
			runtimeMaterial = new Material(shader)
			{
				name = "UI/RectUnionSDF (Instance)"
			};
			targetGraphic.material = runtimeMaterial;
		}
	}

	private void UpdateSdfData()
	{
		if (!(runtimeMaterial == null) && !(rootRect == null))
		{
			int num = BuildRectBuffer();
			runtimeMaterial.SetVectorArray(RectsId, rectBuffer);
			runtimeMaterial.SetFloat(RectCountId, num);
			float contentScaleFactor = GetContentScaleFactor();
			runtimeMaterial.SetFloat(GradientWidthId, gradientWidth * GetCanvasScale() * contentScaleFactor);
			runtimeMaterial.SetFloat(TextureOpacityId, textureOpacity);
			runtimeMaterial.SetFloat(CornerRadiusId, Mathf.Max(0f, cornerRadius) * GetCanvasScale());
			EnsureGradientTexture();
			if (gradientDirty)
			{
				RebuildGradientTexture();
			}
			runtimeMaterial.SetTexture(GradientTexId, gradientTexture);
			Vector2 vector = Vector2.Scale(textureTiling, externalTextureScale);
			float rootAspectRatio = GetRootAspectRatio();
			vector.x *= rootAspectRatio;
			Vector2 value = textureOffset;
			value.x *= rootAspectRatio;
			value += Vector2.Scale(externalTextureOffset, vector);
			runtimeMaterial.SetTextureScale("_MainTex", vector);
			runtimeMaterial.SetTextureOffset("_MainTex", value);
			if (targetGraphic != null)
			{
				targetGraphic.SetVerticesDirty();
			}
		}
	}

	public void SetExternalTextureTransform(Vector2 scale, Vector2 offset)
	{
		externalTextureScale.x = (Mathf.Approximately(scale.x, 0f) ? 0.0001f : scale.x);
		externalTextureScale.y = (Mathf.Approximately(scale.y, 0f) ? 0.0001f : scale.y);
		externalTextureOffset = offset;
	}

	public void ResetExternalTextureTransform()
	{
		externalTextureScale = Vector2.one;
		externalTextureOffset = Vector2.zero;
	}

	private float GetRootAspectRatio()
	{
		if (rootRect == null)
		{
			return 1f;
		}
		float num = Mathf.Max(0.0001f, Mathf.Abs(rootRect.rect.height));
		return Mathf.Max(0.0001f, Mathf.Abs(rootRect.rect.width)) / num;
	}

	public void SetRootRectOverride(RectTransform rect)
	{
		if (!(rootRectOverride == rect))
		{
			rootRectOverride = rect;
			RefreshRootRect();
		}
	}

	private int BuildRectBuffer()
	{
		workingSet.Clear();
		if (autoCollectChildren)
		{
			RectTransform source = ((handlesRoot != null) ? handlesRoot : rootRect);
			CollectChildren(source, workingSet);
		}
		if (extraRects != null && extraRects.Count > 0)
		{
			for (int i = 0; i < extraRects.Count; i++)
			{
				RectTransform rectTransform = extraRects[i];
				if (rectTransform != null && !workingSet.Contains(rectTransform))
				{
					workingSet.Add(rectTransform);
				}
			}
		}
		int index = 0;
		for (int j = 0; j < workingSet.Count; j++)
		{
			if (index >= 32)
			{
				break;
			}
			RectTransform rectTransform2 = workingSet[j];
			if (!(rectTransform2 == null) && !(rectTransform2 == rootRect) && (!ignoreInactive || rectTransform2.gameObject.activeInHierarchy) && TryWriteRect(rectTransform2, ref index) && index >= 32)
			{
				break;
			}
		}
		for (int k = index; k < 32; k++)
		{
			rectBuffer[k] = Vector4.zero;
		}
		return index;
	}

	private void CollectChildren(RectTransform source, List<RectTransform> target)
	{
		if (source == null)
		{
			return;
		}
		for (int i = 0; i < source.childCount; i++)
		{
			if (target.Count >= 32)
			{
				break;
			}
			RectTransform rectTransform = source.GetChild(i) as RectTransform;
			if (!(rectTransform == null) && !(rectTransform == rootRect) && (!ignoreInactive || rectTransform.gameObject.activeInHierarchy))
			{
				target.Add(rectTransform);
			}
		}
	}

	private bool TryWriteRect(RectTransform rect, ref int index)
	{
		rect.GetWorldCorners(worldCorners);
		Vector2 vector = new Vector2(float.PositiveInfinity, float.PositiveInfinity);
		Vector2 vector2 = new Vector2(float.NegativeInfinity, float.NegativeInfinity);
		for (int i = 0; i < 4; i++)
		{
			Vector3 vector3 = rootRect.InverseTransformPoint(worldCorners[i]);
			Vector2 rhs = new Vector2(vector3.x, vector3.y);
			vector = Vector2.Min(vector, rhs);
			vector2 = Vector2.Max(vector2, rhs);
		}
		Vector2 vector4 = (vector2 - vector) * 0.5f;
		if (vector4.x <= 0f || vector4.y <= 0f)
		{
			return false;
		}
		Vector2 vector5 = (vector2 + vector) * 0.5f;
		rectBuffer[index++] = new Vector4(vector5.x, vector5.y, vector4.x, vector4.y);
		return true;
	}

	private float GetCanvasScale()
	{
		CacheCanvas();
		if (cachedCanvas == null || cachedCanvas.renderMode == RenderMode.WorldSpace)
		{
			return 1f;
		}
		return cachedCanvas.scaleFactor;
	}

	private float GetContentScaleFactor()
	{
		float num = 0f;
		int num2 = 0;
		if (!Mathf.Approximately(externalTextureScale.x, 0f))
		{
			num += 1f / Mathf.Abs(externalTextureScale.x);
			num2++;
		}
		if (!Mathf.Approximately(externalTextureScale.y, 0f))
		{
			num += 1f / Mathf.Abs(externalTextureScale.y);
			num2++;
		}
		if (num2 == 0)
		{
			return 1f;
		}
		return Mathf.Max(num / (float)num2, 0.0001f);
	}

	private void EnsureGraphicReference()
	{
		if (targetGraphic == null)
		{
			targetGraphic = GetComponent<Graphic>();
		}
	}

	private void RefreshRootRect()
	{
		if (targetGraphic == null)
		{
			targetGraphic = GetComponent<Graphic>();
		}
		ref RectTransform reference = ref rootRect;
		RectTransform rectTransform;
		if (rootRectOverride != null)
		{
			rectTransform = rootRectOverride;
		}
		else
		{
			rectTransform = ((targetGraphic != null) ? targetGraphic.rectTransform : null);
		}
		reference = rectTransform;
	}

	private void CacheCanvas()
	{
		if (!(rootRect == null))
		{
			Canvas componentInParent = rootRect.GetComponentInParent<Canvas>();
			if (componentInParent != cachedCanvas)
			{
				cachedCanvas = componentInParent;
			}
		}
	}

	public void ForceRootRectUpdate()
	{
		EnsureGraphicReference();
		RefreshRootRect();
		CacheCanvas();
	}

	public void OnValidate()
	{
		gradientWidth = Mathf.Max(0.01f, gradientWidth);
		cornerRadius = Mathf.Max(0f, cornerRadius);
		if (fillGradient == null)
		{
			fillGradient = new Gradient();
		}
		gradientDirty = true;
		EnsureGraphicReference();
		RefreshRootRect();
		CacheCanvas();
		if (isActiveAndEnabled)
		{
			EnsureMaterialInstance();
			UpdateSdfData();
		}
	}

	private void EnsureGradientTexture()
	{
		if (!(gradientTexture != null))
		{
			gradientTexture = new Texture2D(64, 1, TextureFormat.RGBA32, mipChain: false)
			{
				wrapMode = TextureWrapMode.Clamp,
				filterMode = FilterMode.Bilinear,
				name = "RectUnionSDF_Gradient"
			};
			gradientDirty = true;
		}
	}

	private void RebuildGradientTexture()
	{
		if (!(gradientTexture == null) && fillGradient != null)
		{
			for (int i = 0; i < gradientTexture.width; i++)
			{
				float time = (float)i / ((float)gradientTexture.width - 1f);
				Color color = fillGradient.Evaluate(time);
				gradientTexture.SetPixel(i, 0, color);
			}
			gradientTexture.Apply();
			gradientDirty = false;
		}
	}
}
