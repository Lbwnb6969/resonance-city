using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class FirstPersonManager : MonoBehaviour
{
	public static FirstPersonManager inst;

	[Header("Transition Settings")]
	public float fadeDuration = 1f;

	public Color fadeColor = Color.black;

	[Header("Spawn Settings")]
	public float spawnDistance = 3f;

	private bool isInFirstPerson;

	public FirstPersonController fpController;

	private GameObject fadePanel;

	private Image fadeImage;

	private Cam.TransformCapture originalCamState;

	private bool originalCamEnabled;

	private bool originalAlphaNumericHotkeys;

	private bool originalGameUIActive;

	private bool originalThoughtBubblesEnabled;

	private void Awake()
	{
		inst = this;
		SetupFadePanel();
	}

	private void SetupFadePanel()
	{
		GameObject gameObject = new GameObject("FirstPersonFadeCanvas");
		Canvas canvas = gameObject.AddComponent<Canvas>();
		canvas.renderMode = RenderMode.ScreenSpaceOverlay;
		canvas.sortingOrder = 1000;
		CanvasScaler canvasScaler = gameObject.AddComponent<CanvasScaler>();
		canvasScaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
		canvasScaler.referenceResolution = new Vector2(1920f, 1080f);
		gameObject.AddComponent<GraphicRaycaster>();
		fadePanel = new GameObject("FadePanel");
		fadePanel.transform.SetParent(gameObject.transform, worldPositionStays: false);
		fadeImage = fadePanel.AddComponent<Image>();
		fadeImage.color = new Color(fadeColor.r, fadeColor.g, fadeColor.b, 0f);
		RectTransform component = fadePanel.GetComponent<RectTransform>();
		component.anchorMin = Vector2.zero;
		component.anchorMax = Vector2.one;
		component.offsetMin = Vector2.zero;
		component.offsetMax = Vector2.zero;
		fadePanel.SetActive(value: false);
	}

	public void ToggleFirstPerson()
	{
		if (isInFirstPerson)
		{
			ExitFirstPerson();
		}
		else
		{
			EnterFirstPerson();
		}
	}

	public void EnterFirstPerson()
	{
		if (!isInFirstPerson)
		{
			StartCoroutine(EnterFirstPersonCoroutine());
		}
	}

	public void ExitFirstPerson()
	{
		if (isInFirstPerson)
		{
			StartCoroutine(ExitFirstPersonCoroutine());
		}
	}

	private IEnumerator EnterFirstPersonCoroutine()
	{
		Vector3 spawnPos = FindNearestRomanOutpostSpawnPoint();
		if (spawnPos == Vector3.zero)
		{
			Ray ray = PointingSystem.GetRay();
			TerrainGen.inst.Raycast(ray, out var hitInfo);
			float y = TerrainGen.inst.GetGroundHeight(hitInfo.point.x, hitInfo.point.z) + 0.1f;
			spawnPos = new Vector3(hitInfo.point.x, y, hitInfo.point.z);
		}
		yield return StartCoroutine(FadeToBlack());
		originalCamState = Cam.inst.CaptureCameraTransform();
		originalCamEnabled = Cam.inst.enabled;
		originalAlphaNumericHotkeys = GameState.inst.AlphaNumericHotkeysEnabled;
		originalGameUIActive = GameUI.inst.gameObject.activeSelf;
		originalThoughtBubblesEnabled = ThoughtBubbleSystem.inst != null && ThoughtBubbleSystem.inst.enabled;
		GameState.inst.AlphaNumericHotkeysEnabled = false;
		GameUI.inst.gameObject.SetActive(value: false);
		if (ThoughtBubbleSystem.inst != null)
		{
			ThoughtBubbleSystem.inst.enabled = false;
		}
		Cam.inst.enabled = false;
		Cam.inst.disableDrag = true;
		Cam.inst.disableZoom = true;
		Cam.inst.disableRotate = true;
		fpController.gameObject.SetActive(value: true);
		fpController.SetPosition(spawnPos);
		fpController.SetRotation(Random.Range(0f, 360f));
		Cam.inst.cam.enabled = false;
		TreeSystem.UpdateAllSystemsCullingCamera(fpController.GetCamera());
		isInFirstPerson = true;
		yield return StartCoroutine(FadeFromBlack());
	}

	private IEnumerator ExitFirstPersonCoroutine()
	{
		if (fpController.gameObject.activeInHierarchy)
		{
			IsNearRomanOutpostDoor();
			yield return StartCoroutine(FadeToBlack());
			GameState.inst.AlphaNumericHotkeysEnabled = originalAlphaNumericHotkeys;
			GameUI.inst.gameObject.SetActive(originalGameUIActive);
			if (ThoughtBubbleSystem.inst != null)
			{
				ThoughtBubbleSystem.inst.enabled = originalThoughtBubblesEnabled;
			}
			Cam.inst.cam.enabled = true;
			Cam.inst.enabled = originalCamEnabled;
			Cam.inst.disableDrag = false;
			Cam.inst.disableZoom = false;
			Cam.inst.disableRotate = false;
			TreeSystem.UpdateAllSystemsCullingCamera(Cam.inst.cam);
			if (originalCamState != null)
			{
				Cam.inst.ApplyTransformCapture(originalCamState);
			}
			Cursor.lockState = CursorLockMode.None;
			Cursor.visible = true;
			if (fpController.gameObject.activeInHierarchy)
			{
				fpController.gameObject.SetActive(value: false);
			}
			isInFirstPerson = false;
			yield return StartCoroutine(FadeFromBlack());
		}
	}

	private IEnumerator FadeToBlack()
	{
		fadePanel.SetActive(value: true);
		float timer = 0f;
		Color startColor = new Color(fadeColor.r, fadeColor.g, fadeColor.b, 0f);
		Color endColor = new Color(fadeColor.r, fadeColor.g, fadeColor.b, 1f);
		while (timer < fadeDuration)
		{
			timer += Time.unscaledDeltaTime;
			float t = timer / fadeDuration;
			fadeImage.color = Color.Lerp(startColor, endColor, t);
			yield return null;
		}
		fadeImage.color = endColor;
	}

	private IEnumerator FadeFromBlack()
	{
		float timer = 0f;
		Color startColor = new Color(fadeColor.r, fadeColor.g, fadeColor.b, 1f);
		Color endColor = new Color(fadeColor.r, fadeColor.g, fadeColor.b, 0f);
		while (timer < fadeDuration)
		{
			timer += Time.unscaledDeltaTime;
			float t = timer / fadeDuration;
			fadeImage.color = Color.Lerp(startColor, endColor, t);
			yield return null;
		}
		fadeImage.color = endColor;
		fadePanel.SetActive(value: false);
	}

	private Vector3 FindNearestRomanOutpostSpawnPoint()
	{
		Vector3 position = Cam.inst.transform.position;
		float num = float.MaxValue;
		Vector3 result = Vector3.zero;
		Keep[] array = Object.FindObjectsByType<Keep>(FindObjectsSortMode.None);
		for (int i = 0; i < array.Length; i++)
		{
			Vector3 position2 = array[i].transform.position;
			float num2 = Vector3.Distance(position, position2);
			if (num2 < num)
			{
				num = num2;
				Vector3 normalized = (position - position2).normalized;
				normalized.y = 0f;
				result = position2 + normalized * spawnDistance;
				result.y = TerrainGen.inst.GetGroundHeight(result.x, result.z) + 0.1f;
			}
		}
		return result;
	}

	private bool IsNearRomanOutpostDoor()
	{
		if (!fpController.gameObject.activeInHierarchy)
		{
			return false;
		}
		Vector3 position = fpController.transform.position;
		Keep[] array = Object.FindObjectsByType<Keep>(FindObjectsSortMode.None);
		for (int i = 0; i < array.Length; i++)
		{
			Vector3 position2 = array[i].transform.position;
			if (Vector3.Distance(position, position2) <= spawnDistance + 1f)
			{
				return true;
			}
		}
		return false;
	}

	public bool IsInFirstPerson()
	{
		return isInFirstPerson;
	}

	public FirstPersonController GetController()
	{
		return fpController;
	}

	private void Update()
	{
	}
}
