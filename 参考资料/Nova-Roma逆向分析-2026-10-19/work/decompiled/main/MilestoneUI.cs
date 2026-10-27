using FMODUnity;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class MilestoneUI : MonoBehaviour
{
	public static MilestoneUI inst;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	private Button acceptBtn;

	[SerializeField]
	private RawImage radialAnimBackground;

	[SerializeField]
	private RawImage highlightAnimBackground;

	private float animTime;

	private bool animate;

	[SerializeField]
	private float animMaxTime = 4f;

	[SerializeField]
	private int animRotateAmt = 3;

	[SerializeField]
	private AnimationCurve animCurve;

	[SerializeField]
	private TextMeshProUGUI titleTMP;

	[SerializeField]
	private TextMeshProUGUI descriptionTMP;

	private bool isVisible;

	private int currMilestone = -1;

	private Timer doShowTime = new Timer(10f);

	private float visibilityTime;

	private bool isHovered;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		if (v && !isVisible)
		{
			RefreshVisuals();
			visibilityTime = 30f;
			animate = true;
			animTime = 0f;
			RuntimeManager.PlayOneShot("event:/OldSFX/aiHeadEmoteHappy1");
			Color color = radialAnimBackground.color;
			color.a = 0f;
			radialAnimBackground.color = color;
			Color color2 = highlightAnimBackground.color;
			color2.a = 0f;
			highlightAnimBackground.color = color2;
		}
		if (!v)
		{
			currMilestone = -1;
		}
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		isVisible = v;
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		acceptBtn.onClick.AddListener(() =>
		{
			SetVisibility(v: false);
		});
	}

	public void Reset()
	{
		currMilestone = -1;
		doShowTime.Reset();
		SetVisibility(v: false);
	}

	public void PointerEnter()
	{
		isHovered = true;
	}

	public void PointerExit()
	{
		isHovered = false;
	}

	private void Update()
	{
		if (isVisible)
		{
			float unscaledDeltaTime = Time.unscaledDeltaTime;
			if (isHovered && visibilityTime < 5f)
			{
				visibilityTime = 5f;
			}
			visibilityTime -= unscaledDeltaTime;
			if (visibilityTime <= 0f)
			{
				SetVisibility(v: false);
			}
			Color color = radialAnimBackground.color;
			color.a = Mathff.Clamp01(visibilityTime / 5f) * 0.3f;
			radialAnimBackground.color = color;
			if (animate)
			{
				animTime += unscaledDeltaTime;
				float num = Mathff.Clamp01(animTime / animMaxTime);
				float num2 = animCurve.Evaluate(num);
				Color color2 = highlightAnimBackground.color;
				color2.a = num2 * 0.65f;
				highlightAnimBackground.color = color2;
				float z = num * (360f * (float)animRotateAmt);
				highlightAnimBackground.transform.rotation = Quaternion.Euler(0f, 0f, z);
				if (num >= 1f)
				{
					animate = false;
				}
			}
		}
		else if (currMilestone != -1 && !IsPlayerOccupied() && doShowTime.Update(Time.unscaledDeltaTime))
		{
			SetVisibility(v: true);
		}
	}

	private void RefreshVisuals()
	{
		if (currMilestone != -1 && MilestoneManager.inst.TryGetEntry(currMilestone, out var entry))
		{
			if (entry.onCelebrate == null)
			{
				MusicSystem.inst.StartMilestoneMusic();
			}
			else
			{
				entry.onCelebrate?.Invoke();
			}
			titleTMP.text = LocalizationManager.GetTranslation(entry.titleTerm);
			descriptionTMP.text = LocalizationManager.GetTranslation(entry.descriptionTermUnfinished);
		}
	}

	public void ShowMilestone(int mStone)
	{
		if (!LoadSave.Loading)
		{
			currMilestone = mStone;
			doShowTime.Reset();
			if (!IsPlayerOccupied())
			{
				SetVisibility(v: true);
			}
		}
	}

	private bool IsPlayerOccupied()
	{
		if (GameUI.inst.currCursorMode != null || GameUI.inst.godUI.Visible() || AdvisorUI.inst.IsVisible() || TechnologyTree.inst.IsVisible() || GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			return true;
		}
		return false;
	}
}
