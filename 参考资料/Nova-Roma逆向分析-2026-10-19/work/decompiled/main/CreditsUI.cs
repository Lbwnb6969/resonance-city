using LeTai.Asset.TranslucentImage;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class CreditsUI : MonoBehaviour
{
	public RectTransform Viewport;

	public RectTransform CreditsContainer;

	public CreditsData creditsData;

	[Header("Prefabs")]
	public GameObject titlePrefab;

	public GameObject header1Prefab;

	public GameObject header2Prefab;

	public GameObject header3Prefab;

	public GameObject roleBlockPrefab;

	public GameObject nameItemPrefab;

	public GameObject spacerPrefab;

	public Button backButton;

	private const float fadeDuration = 0.5f;

	private CanvasGroup canvasGroup;

	private float fadeTimer;

	private bool fadingIn;

	private bool fadingOut;

	private float endWaitTimer = -1f;

	private const float endWaitDuration = 3f;

	private const float creditsBlurStrength = 5.5f;

	private ScalableBlurConfig blurConfig;

	private float originalBlurStrength;

	private Vector3[] ViewportCorners = new Vector3[4];

	private Vector3[] ParentCorners = new Vector3[4];

	private Vector3[] ChildCorners = new Vector3[4];

	private bool generated;

	private bool layoutFrozen;

	private int generatedFrame;

	private void RebuildCredits()
	{
		for (int num = CreditsContainer.childCount - 1; num >= 0; num--)
		{
			if (Application.isPlaying)
			{
				Object.Destroy(CreditsContainer.GetChild(num).gameObject);
			}
			else
			{
				Object.DestroyImmediate(CreditsContainer.GetChild(num).gameObject);
			}
		}
		generated = false;
		GenerateCredits();
	}

	private void Start()
	{
		canvasGroup = GetComponent<CanvasGroup>();
		backButton.onClick.AddListener(BackButtonClicked);
	}

	private void BackButtonClicked()
	{
		if (!fadingOut)
		{
			fadingOut = true;
			fadingIn = false;
			fadeTimer = 0f;
		}
	}

	private void Update()
	{
		if (fadingIn)
		{
			fadeTimer += Time.unscaledDeltaTime;
			float num = Mathf.Clamp01(fadeTimer / 0.5f);
			canvasGroup.alpha = num;
			if ((bool)blurConfig)
			{
				blurConfig.Strength = Mathf.Lerp(originalBlurStrength, 5.5f, num);
			}
			if (num >= 1f)
			{
				fadingIn = false;
				canvasGroup.blocksRaycasts = true;
			}
		}
		else if (fadingOut)
		{
			fadeTimer += Time.unscaledDeltaTime;
			float num2 = Mathf.Clamp01(fadeTimer / 0.5f);
			canvasGroup.alpha = 1f - num2;
			if ((bool)blurConfig)
			{
				blurConfig.Strength = Mathf.Lerp(5.5f, originalBlurStrength, num2);
			}
			if (num2 >= 1f)
			{
				fadingOut = false;
				canvasGroup.alpha = 1f;
				MusicSystem.inst.StartMainMenuMusic();
				GameState.inst.mainMenuMode.OnClickedBackToTopLevel();
			}
		}
		if (!generated || fadingOut)
		{
			return;
		}
		bool mouseButton = Input.GetMouseButton(0);
		if (!mouseButton)
		{
			CreditsContainer.transform.position += Vector3.up * 1f * Time.unscaledDeltaTime;
		}
		CreditsContainer.GetWorldCorners(ParentCorners);
		float num3 = Mathf.Min(ParentCorners[0].y, ParentCorners[1].y, ParentCorners[2].y, ParentCorners[3].y);
		Viewport.GetWorldCorners(ViewportCorners);
		float num4 = Mathf.Min(ViewportCorners[0].y, ViewportCorners[1].y, ViewportCorners[2].y, ViewportCorners[3].y);
		bool flag = num3 > num4;
		if (mouseButton || !flag)
		{
			endWaitTimer = -1f;
			return;
		}
		if (endWaitTimer < 0f)
		{
			endWaitTimer = 0f;
			return;
		}
		endWaitTimer += Time.unscaledDeltaTime;
		if (endWaitTimer >= 3f)
		{
			BackButtonClicked();
		}
	}

	private void LateUpdate()
	{
		if (generated && !layoutFrozen && Time.frameCount > generatedFrame)
		{
			Canvas.ForceUpdateCanvases();
			LayoutRebuilder.ForceRebuildLayoutImmediate(CreditsContainer);
			layoutFrozen = true;
			LayoutGroup[] componentsInChildren = CreditsContainer.GetComponentsInChildren<LayoutGroup>(includeInactive: true);
			for (int i = 0; i < componentsInChildren.Length; i++)
			{
				componentsInChildren[i].enabled = false;
			}
			ContentSizeFitter[] componentsInChildren2 = CreditsContainer.GetComponentsInChildren<ContentSizeFitter>(includeInactive: true);
			for (int i = 0; i < componentsInChildren2.Length; i++)
			{
				componentsInChildren2[i].enabled = false;
			}
			RectTransform[] componentsInChildren3 = CreditsContainer.GetComponentsInChildren<RectTransform>(includeInactive: true);
			foreach (RectTransform rectTransform in componentsInChildren3)
			{
				if (!(rectTransform == CreditsContainer))
				{
					float y = rectTransform.anchoredPosition.y;
					float y2 = rectTransform.sizeDelta.y;
					rectTransform.anchorMin = new Vector2(0f, 1f);
					rectTransform.anchorMax = new Vector2(1f, 1f);
					rectTransform.anchoredPosition = new Vector2(0f, y);
					rectTransform.sizeDelta = new Vector2(0f, y2);
				}
			}
		}
		if (!generated)
		{
			return;
		}
		Viewport.GetWorldCorners(ViewportCorners);
		float num = Mathf.Max(ViewportCorners[0].y, ViewportCorners[1].y, ViewportCorners[2].y, ViewportCorners[3].y);
		float num2 = Mathf.Min(ViewportCorners[0].y, ViewportCorners[1].y, ViewportCorners[2].y, ViewportCorners[3].y);
		foreach (RectTransform item in CreditsContainer.transform)
		{
			item.GetWorldCorners(ParentCorners);
			float num3 = Mathf.Max(ParentCorners[0].y, ParentCorners[1].y, ParentCorners[2].y, ParentCorners[3].y);
			float num4 = Mathf.Min(ParentCorners[0].y, ParentCorners[1].y, ParentCorners[2].y, ParentCorners[3].y);
			if (!(num3 < num2) && !(num4 > num))
			{
				ProcessChildrenVisible(item, num, num2);
			}
		}
	}

	public void ProcessChildrenVisible(RectTransform topItem, float viewMaxY, float viewMinY)
	{
		if (topItem.childCount <= 0)
		{
			return;
		}
		foreach (RectTransform item in topItem)
		{
			item.GetWorldCorners(ChildCorners);
			float num = Mathf.Max(ChildCorners[0].y, ChildCorners[1].y, ChildCorners[2].y, ChildCorners[3].y);
			float num2 = Mathf.Min(ChildCorners[0].y, ChildCorners[1].y, ChildCorners[2].y, ChildCorners[3].y);
			bool flag = num < viewMinY || num2 > viewMaxY;
			if (item.childCount > 0)
			{
				ProcessChildrenVisible(item, viewMaxY, viewMinY);
			}
			else
			{
				item.gameObject.SetActive(!flag);
			}
		}
	}

	private void OnEnable()
	{
		CreditsContainer.position = CreditsContainer.position.xz();
		TranslucentImageSource component = Cam.inst.cam.GetComponent<TranslucentImageSource>();
		if ((bool)component)
		{
			blurConfig = component.BlurConfig as ScalableBlurConfig;
			if ((bool)blurConfig)
			{
				originalBlurStrength = blurConfig.Strength;
			}
		}
		fadingIn = true;
		fadingOut = false;
		fadeTimer = 0f;
		endWaitTimer = -1f;
		if (canvasGroup == null)
		{
			canvasGroup = GetComponent<CanvasGroup>();
		}
		canvasGroup.alpha = 0f;
		canvasGroup.blocksRaycasts = false;
		for (int num = CreditsContainer.childCount - 1; num >= 0; num--)
		{
			Object.DestroyImmediate(CreditsContainer.GetChild(num).gameObject);
		}
		generated = false;
		layoutFrozen = false;
		GenerateCredits();
		generated = true;
		generatedFrame = Time.frameCount;
	}

	private void OnDisable()
	{
		for (int num = CreditsContainer.childCount - 1; num >= 0; num--)
		{
			Object.Destroy(CreditsContainer.GetChild(num).gameObject);
		}
		generated = false;
		layoutFrozen = false;
		endWaitTimer = -1f;
		fadingIn = false;
		fadingOut = false;
	}

	private void GenerateCredits()
	{
		if (creditsData == null || creditsData.entries == null)
		{
			return;
		}
		VerticalLayoutGroup verticalLayoutGroup = CreditsContainer.GetComponent<VerticalLayoutGroup>();
		if (verticalLayoutGroup == null)
		{
			verticalLayoutGroup = CreditsContainer.gameObject.AddComponent<VerticalLayoutGroup>();
			verticalLayoutGroup.childAlignment = TextAnchor.UpperCenter;
			verticalLayoutGroup.childControlWidth = true;
			verticalLayoutGroup.childControlHeight = true;
			verticalLayoutGroup.childForceExpandWidth = true;
			verticalLayoutGroup.childForceExpandHeight = false;
			verticalLayoutGroup.spacing = 0f;
		}
		verticalLayoutGroup.enabled = true;
		ContentSizeFitter contentSizeFitter = CreditsContainer.GetComponent<ContentSizeFitter>();
		if (contentSizeFitter == null)
		{
			contentSizeFitter = CreditsContainer.gameObject.AddComponent<ContentSizeFitter>();
			contentSizeFitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
			contentSizeFitter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
		}
		contentSizeFitter.enabled = true;
		GameObject gameObject = new GameObject("InitialSpacer", typeof(RectTransform), typeof(LayoutElement));
		gameObject.transform.SetParent(CreditsContainer, worldPositionStays: false);
		gameObject.GetComponent<LayoutElement>().preferredHeight = ((RectTransform)transform.parent).rect.height;
		CreditEntry[] entries = creditsData.entries;
		foreach (CreditEntry creditEntry in entries)
		{
			switch (creditEntry.type)
			{
			case CreditEntryType.Title:
				InstantiateHeader(titlePrefab, creditEntry.text);
				break;
			case CreditEntryType.Header1:
				InstantiateHeader(header1Prefab, creditEntry.text);
				break;
			case CreditEntryType.Header2:
				InstantiateHeader(header2Prefab, creditEntry.text);
				break;
			case CreditEntryType.Header3:
				InstantiateHeader(header3Prefab, creditEntry.text);
				break;
			case CreditEntryType.RoleNames:
				InstantiateRoleBlock(creditEntry);
				break;
			case CreditEntryType.Spacer:
				InstantiateSpacer();
				break;
			}
		}
		GameObject gameObject2 = new GameObject("FinalSpacer", typeof(RectTransform), typeof(LayoutElement));
		gameObject2.transform.SetParent(CreditsContainer, worldPositionStays: false);
		gameObject2.GetComponent<LayoutElement>().preferredHeight = ((RectTransform)transform.parent).rect.height * 0.5f;
	}

	private void InstantiateHeader(GameObject prefab, string text)
	{
		if (!(prefab == null))
		{
			GameObject gameObject = Object.Instantiate(prefab, CreditsContainer, worldPositionStays: false);
			gameObject.transform.localScale = Vector3.one;
			TextMeshProUGUI component = gameObject.GetComponent<TextMeshProUGUI>();
			if ((bool)component)
			{
				component.text = text;
			}
		}
	}

	private void InstantiateRoleBlock(CreditEntry entry)
	{
		if (roleBlockPrefab == null)
		{
			return;
		}
		GameObject gameObject = Object.Instantiate(roleBlockPrefab, CreditsContainer, worldPositionStays: false);
		gameObject.transform.localScale = Vector3.one;
		if (gameObject.transform.childCount > 0)
		{
			TextMeshProUGUI component = gameObject.transform.GetChild(0).GetComponent<TextMeshProUGUI>();
			if ((bool)component)
			{
				component.text = entry.text ?? "";
				if (string.IsNullOrEmpty(entry.text))
				{
					component.gameObject.SetActive(value: false);
				}
			}
		}
		if (entry.names == null || !(nameItemPrefab != null))
		{
			return;
		}
		string[] names = entry.names;
		foreach (string text in names)
		{
			GameObject gameObject2 = Object.Instantiate(nameItemPrefab, gameObject.transform, worldPositionStays: false);
			gameObject2.transform.localScale = Vector3.one;
			TextMeshProUGUI component2 = gameObject2.GetComponent<TextMeshProUGUI>();
			if ((bool)component2)
			{
				component2.text = text;
			}
		}
	}

	private void InstantiateSpacer()
	{
		if (!(spacerPrefab == null))
		{
			Object.Instantiate(spacerPrefab, CreditsContainer, worldPositionStays: false).transform.localScale = Vector3.one;
		}
	}
}
