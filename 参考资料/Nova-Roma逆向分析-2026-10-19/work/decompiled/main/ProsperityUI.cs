using System;
using FMODUnity;
using I2.Loc;
using PixelCrushers.DialogueSystem;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ProsperityUI : MonoBehaviour
{
	public static ProsperityUI inst;

	[SerializeField]
	private ProsperityTaskItemUI taskItemPrefab;

	private int taskItemCount;

	private ArrayExt<ProsperityTaskItemUI> taskItemPool = new ArrayExt<ProsperityTaskItemUI>(32);

	[SerializeField]
	private Button taskShowBtn;

	[SerializeField]
	private Button taskExitBtn;

	[SerializeField]
	private RectTransform taskItemContainer;

	[SerializeField]
	private GameObject taskEmptyGO;

	[SerializeField]
	private GameObject taskNotify;

	[SerializeField]
	private Canvas taskCanvas;

	[SerializeField]
	private GraphicRaycaster taskGraphicRayCaster;

	[SerializeField]
	private RawImage isSelectedBackground;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster graphicRaycaster;

	[SerializeField]
	private TextMeshProUGUI titleText;

	[SerializeField]
	private TextMeshProUGUI gainedText;

	[SerializeField]
	public GameObject prosperityNotifyObj;

	[SerializeField]
	public TextMeshProUGUI prosperityNotifyTMP;

	[SerializeField]
	private Button showTechnologyTreeBtn;

	[SerializeField]
	private GameObject container;

	[SerializeField]
	private GameObject lockContainer;

	[SerializeField]
	private RectTransform rectT;

	private bool isTechnologyUnlocked;

	public float maxAnimationTime = 5f;

	private bool isVisible = true;

	internal bool isTasksVisible;

	private bool[] hasSeenTasks = new bool[GodManager.numGods];

	public TextMeshProUGUI animatedRewardTxt;

	private float animationTime;

	private int futureProsperity;

	private ArrayExt<Building> tempBuildings = new ArrayExt<Building>(32);

	private bool animatePlusOne;

	private float currAnimationTime;

	private float nextUpdateSliderTime = 0.05f;

	public int curveSegments = 8;

	public float animationSpeed = 1f;

	public float yOffsetMultiplier = 1f;

	public RectTransform rewardRectT;

	public RectTransform targetRectT;

	public Vector2[] points;

	private Vector3 originalPos;

	private bool isAnimating;

	private ProsperityTaskItemUI GetTaskItem()
	{
		while (taskItemCount >= taskItemPool.Count)
		{
			ProsperityTaskItemUI prosperityTaskItemUI = UnityEngine.Object.Instantiate(taskItemPrefab, taskItemContainer, worldPositionStays: false);
			prosperityTaskItemUI.completeBtn.gameObject.SetActive(value: false);
			taskItemPool.Add(prosperityTaskItemUI);
		}
		return taskItemPool.data[taskItemCount++];
	}

	public bool IsTechnologyUnlocked()
	{
		return isTechnologyUnlocked;
	}

	private void Awake()
	{
		inst = this;
		rectT = GetComponent<RectTransform>();
	}

	public void SetVisibility(bool v)
	{
		if (!v)
		{
			SetMissionVisibility(v: false);
		}
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(graphicRaycaster, v);
		isVisible = v;
	}

	public void SetMissionVisibility(bool v)
	{
		if (!v && isTasksVisible)
		{
			for (int i = 0; i < hasSeenTasks.Length; i++)
			{
				hasSeenTasks[i] = true;
			}
		}
		Util.SetEnabled(taskCanvas, v);
		taskGraphicRayCaster.enabled = v;
		isTasksVisible = v;
		isSelectedBackground.enabled = v;
		if (v)
		{
			taskNotify.SetActive(value: false);
			BuildUI.inst.HideGroups();
		}
	}

	public void SetNotifyOnTasks(int godIdx)
	{
		taskNotify.SetActive(value: true);
		if (godIdx != -1)
		{
			hasSeenTasks[godIdx] = false;
		}
	}

	public void SetProsperityNotifyVisibility(bool v)
	{
		if (v && TechnologyTree.inst.IsVisible())
		{
			v = false;
		}
		if (v)
		{
			prosperityNotifyTMP.text = futureProsperity.ToString();
		}
		Util.SetActive(prosperityNotifyObj, v);
	}

	private void Start()
	{
		showTechnologyTreeBtn.onClick.AddListener(() =>
		{
			TechnologyTree.inst.SetVisibility(!TechnologyTree.inst.IsVisible());
		});
		taskShowBtn.onClick.AddListener(() =>
		{
			SetMissionVisibility(!isTasksVisible);
		});
		taskExitBtn.onClick.AddListener(() =>
		{
			SetMissionVisibility(v: false);
		});
		Player player = Player.inst;
		player.onProsperityGained = (Player.OnProsperityChanged)Delegate.Combine(player.onProsperityGained, new Player.OnProsperityChanged(OnProsperityGained));
		Player player2 = Player.inst;
		player2.onProsperityChanged = (Player.OnProsperityChanged)Delegate.Combine(player2.onProsperityChanged, new Player.OnProsperityChanged(OnProsperityChanged));
		titleText.text = $"{Player.inst.ProsperityPoints}";
		taskNotify.SetActive(value: false);
		for (int num = 0; num < GodManager.numGods; num++)
		{
			ProsperityTaskItemUI mItem = GetTaskItem();
			GameObject gameObject = GameUI.inst.godUI.godDisplay.gods[num];
			if (gameObject != null)
			{
				mItem.godNameLocalize.Term = gameObject.GetComponent<GodInfoUI>().GetLocalizedName();
			}
			int godIdx = num;
			mItem.completeBtn.onClick.AddListener(() =>
			{
				OnCompleteCurrTask(godIdx, mItem);
			});
		}
	}

	public void OnProsperityChanged(int amt)
	{
		titleText.text = $"{Player.inst.ProsperityPoints}";
	}

	private void Update()
	{
		if (isTasksVisible)
		{
			bool flag = false;
			for (int i = 0; i < GodManager.numGods; i++)
			{
				GodTask currTask = GodManager.inst.GetCurrTask(i);
				ProsperityTaskItemUI prosperityTaskItemUI = taskItemPool.data[i];
				if (currTask != null)
				{
					prosperityTaskItemUI.descriptionTMP.text = currTask.GetDesc();
					prosperityTaskItemUI.progressSlider.value = currTask.GetProgress();
					prosperityTaskItemUI.rewardTMP.text = currTask.reward.ToString();
					Util.SetActive(prosperityTaskItemUI.newObj, !hasSeenTasks[i]);
					bool flag2 = Player.inst.IsGodAngry(World.GetLandmassOwner(Player.inst.FocusedLandMass), i);
					Util.SetActive(prosperityTaskItemUI.angerContainer, flag2);
					int num = 0;
					bool flag3 = true;
					Player.GodHonorInfo[] godHonor = Player.inst.PlayerLandmassOwner.godHonor;
					num += godHonor[i].honor;
					if (godHonor[i].templeNotStaffed)
					{
						flag3 = false;
					}
					Util.SetActive(prosperityTaskItemUI.disableContainer, num <= 0);
					if (!flag3)
					{
						GodInfoUI component = GodUI.inst.godDisplay.gods[i].GetComponent<GodInfoUI>();
						prosperityTaskItemUI.disableTxt.text = string.Format(LocalizationManager.GetTranslation("godhonorui_templesnotstaffed"), LocalizationManager.GetTranslation(component.GetLocalizedName()));
					}
					else
					{
						prosperityTaskItemUI.disableTxt.text = LocalizationManager.GetTranslation("UnlockWithTempleTooltip");
					}
					bool flag4 = currTask.IsComplete();
					if (flag4)
					{
						string text = ((currTask is OfferingTask) ? "godui_makeoffering_button" : "godui_completetask_button");
						if (text != prosperityTaskItemUI.completeLocalize.Term)
						{
							prosperityTaskItemUI.completeLocalize.Term = text;
						}
					}
					Util.SetActive(prosperityTaskItemUI.completionIcon, flag4);
					Util.SetActive(prosperityTaskItemUI.completeBtn.gameObject, flag4 && !flag2 && num > 0 && (!GodUI.inst.Visible() || DialogueManager.lastConversationStarted != "GodTaskComplete"));
					Util.SetActive(prosperityTaskItemUI.gameObject, active: true);
					flag = true;
				}
				else
				{
					Util.SetActive(prosperityTaskItemUI.gameObject, active: false);
				}
			}
			taskEmptyGO.SetActive(!flag);
		}
		if (isAnimating)
		{
			float num2 = 1f / (float)(points.Length - 1);
			animationTime += Time.unscaledDeltaTime * animationSpeed;
			float num3 = animationTime / num2;
			float t = num3 % 1f;
			int num4 = Mathf.FloorToInt(num3);
			if (num4 >= points.Length - 1)
			{
				isAnimating = false;
				rewardRectT.transform.position = originalPos;
				rewardRectT.gameObject.SetActive(value: false);
				SetProsperityNotifyVisibility(v: true);
			}
			else
			{
				rewardRectT.transform.position = Vector2.Lerp(points[num4], points[num4 + 1], t);
			}
		}
		ArrayExt<int> ownedLandMasses = Player.inst.PlayerLandmassOwner.ownedLandMasses;
		if (IsValidToSetVisibility())
		{
			bool visibility = false;
			for (int j = 0; j < ownedLandMasses.Count; j++)
			{
				if (Player.inst.GetBuildingListForLandMass(ownedLandMasses.data[j]).Count > 0)
				{
					visibility = true;
				}
			}
			SetVisibility(visibility);
		}
		isTechnologyUnlocked = false;
		ArrayExt<ArrayExt<Building>> buildingArrays = new ArrayExt<ArrayExt<Building>>(3);
		for (int k = 0; k < ownedLandMasses.Count; k++)
		{
			int landMass = ownedLandMasses.data[k];
			Player.inst.GetBuildingListsByCategoryForLandMass(landMass, "temple".GetHashCode(), ref buildingArrays);
			for (int l = 0; l < buildingArrays.Count; l++)
			{
				ArrayExt<Building> arrayExt = buildingArrays.data[l];
				for (int m = 0; m < arrayExt.Count; m++)
				{
					if (arrayExt.data[m].IsBuilt())
					{
						Temple component2 = arrayExt.data[m].GetComponent<Temple>();
						if ((object)component2 == null || component2.GetDedicateIdx() != -1)
						{
							isTechnologyUnlocked = true;
							break;
						}
					}
				}
			}
		}
		Util.SetActive(lockContainer, !isTechnologyUnlocked);
		if (animatePlusOne)
		{
			currAnimationTime += Time.unscaledDeltaTime;
			SetColorAlpha(gainedText, 1f - currAnimationTime / maxAnimationTime);
			if (currAnimationTime >= maxAnimationTime)
			{
				animatePlusOne = false;
				currAnimationTime = 0f;
				SetColorAlpha(gainedText, 0f);
			}
		}
		for (int n = taskItemCount; n < taskItemPool.Count; n++)
		{
			taskItemPool.data[n].completeBtn.gameObject.SetActive(value: false);
			taskItemPool.data[n].gameObject.SetActive(value: false);
		}
	}

	private bool IsValidToSetVisibility()
	{
		if (!(GameUI.inst.currCursorMode is DockRouteCursorMode) && !ConsoleBuildMenu.inst.Active && !MerchantUI.inst.IsVisible())
		{
			return !GameUI.inst.IsChariotRaceModeActive();
		}
		return false;
	}

	private void OnCompleteCurrTask(int godIdx, ProsperityTaskItemUI itemUI)
	{
		GodTask currTask = GodManager.inst.GetCurrTask(godIdx);
		AnimateReward(itemUI.rewardTMP.transform.position, currTask.reward);
		Player.inst.GiveProsperityPoints(currTask.reward);
		GodManager.inst.CompleteCurrTask(godIdx);
		if (GodManager.inst.GetNextTask(godIdx) != null)
		{
			GodManager.inst.AcceptNextTask(godIdx);
		}
		RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_favourGained");
	}

	private void OnProsperityGained(int amt)
	{
		gainedText.text = $"+{amt}";
		animatePlusOne = true;
		currAnimationTime = 0f;
		SetColorAlpha(gainedText, 1f);
		titleText.text = $"{Player.inst.ProsperityPoints}";
	}

	public void Reset()
	{
		titleText.text = $"{Player.inst.ProsperityPoints}";
		animatePlusOne = false;
		currAnimationTime = 0f;
		SetColorAlpha(gainedText, 0f);
		taskNotify.SetActive(value: false);
		SetProsperityNotifyVisibility(v: false);
	}

	private void SetColorAlpha(TextMeshProUGUI text, float alpha)
	{
		Color color = text.color;
		color.a = alpha;
		text.color = color;
	}

	public void AnimateReward(Vector2 worldPos, int amt = 0)
	{
		futureProsperity = amt + Player.inst.ProsperityPoints;
		animatedRewardTxt.SetText("{0}", amt);
		animationTime = 0f;
		originalPos = rewardRectT.transform.position;
		rewardRectT.gameObject.SetActive(value: true);
		int num = curveSegments + 2;
		points = new Vector2[num];
		Vector2 vector = targetRectT.transform.position;
		Vector2 vector2 = vector - worldPos;
		Vector2 vector3 = vector;
		vector3.y += vector2.magnitude * yOffsetMultiplier;
		points[0] = worldPos;
		points[^1] = vector;
		float num2 = 1f / (float)(curveSegments + 1);
		for (int i = 1; i <= curveSegments + 1; i++)
		{
			points[i] = DeCasteljauCurve(num2 * (float)i, new Vector2[3] { worldPos, vector3, vector });
		}
		isAnimating = true;
	}

	private Vector3 DeCasteljauCurve(float t, Vector2[] points)
	{
		float num = 1f - t;
		for (int i = 1; i < points.Length; i++)
		{
			for (int j = 0; j < points.Length - i; j++)
			{
				points[j].x = points[j].x * num + points[j + 1].x * t;
				points[j].y = points[j].y * num + points[j + 1].y * t;
			}
		}
		return points[0];
	}
}
