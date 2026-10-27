using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class GladiatorRecruitModal : MonoBehaviour
{
	private class PreviewGladiator
	{
		public string name;

		public GladiatorAlignment alignment;

		public GladiatorSkills skills;

		public GladiatorSkillType primarySkill;
	}

	public TextMeshProUGUI nameText;

	public TextMeshProUGUI alignmentText;

	public TextMeshProUGUI beastSkillsTxt;

	public TextMeshProUGUI secutorSkillsTxt;

	public TextMeshProUGUI retiariusSkillsTxt;

	public TextMeshProUGUI costText;

	public TextMeshProUGUI rerollCostText;

	[Header("Buttons")]
	public Button rerollButton;

	public Button recruitButton;

	public Button cancelButton;

	private GladiatorSchool currentSchool;

	private PreviewGladiator previewData;

	public Canvas canvas;

	public GraphicRaycaster gRaycaster;

	public static GladiatorRecruitModal inst;

	private bool isVisible;

	private Cam.TransformCapture oldCam;

	public GameObject gladiatorVisualPrefab;

	private GameObject gladiatorVisual;

	public float gladiatorFramingOffsetX;

	public float gladiatorFramingOffsetZ;

	public float camPhi = 55f;

	public float camDist = 4f;

	private int rerollCost = 15;

	private void Awake()
	{
		inst = this;
		rerollButton.onClick.AddListener(OnRerollClicked);
		recruitButton.onClick.AddListener(OnRecruitClicked);
		cancelButton.onClick.AddListener(OnCancelClicked);
	}

	private void Start()
	{
		SetVisible(v: false);
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	private void SetVisible(bool v)
	{
		isVisible = v;
		Util.SetEnabled(canvas, isVisible);
		Util.SetEnabled(gRaycaster, isVisible);
		canvas.renderMode = RenderMode.ScreenSpaceCamera;
		canvas.worldCamera = (v ? GUICamera.inst.cam : null);
	}

	public void Show(GladiatorSchool school)
	{
		if (!isVisible)
		{
			SetVisible(v: true);
			oldCam = Cam.inst.CaptureCameraTransform();
			GameUI.SetUIForModalHelper(v: false);
			TimeManager.inst.SetLocked(val: true);
		}
		GameUI.inst.ClearUIForClick();
		Cam.inst.desiredPhi = 47f;
		currentSchool = school;
		currentSchool.SetAnimVisuals(v: false);
		if (previewData == null)
		{
			GeneratePreview();
		}
		RefreshUI();
	}

	public void Hide()
	{
		if (isVisible)
		{
			SetVisible(v: false);
			GameUI.SetUIForModalHelper(v: true);
			Cam.inst.ApplyTransformCapture(oldCam);
			TimeManager.inst.SetLocked(val: false);
			GameUI.inst.SetSelectedBuildingNew(currentSchool.GetComponent<Building>(), forceUpdate: true);
		}
		if ((bool)currentSchool)
		{
			currentSchool.RefreshAnimObjVisibility();
		}
		currentSchool = null;
		if ((bool)gladiatorVisual)
		{
			Object.Destroy(gladiatorVisual);
		}
		previewData = null;
	}

	public void OnDestroy()
	{
		previewData = null;
	}

	private void GeneratePreview()
	{
		GladiatorSystem gladiatorSystem = GladiatorSystem.inst;
		GladiatorSkills skills = gladiatorSystem.GenerateRandomSkills();
		skills.GetHighestSkill(out var highestType);
		previewData = new PreviewGladiator
		{
			name = gladiatorSystem.GenerateRandomName(),
			alignment = (GladiatorAlignment)Random.Range(0, 3),
			skills = skills,
			primarySkill = highestType
		};
		if ((bool)gladiatorVisual)
		{
			Object.Destroy(gladiatorVisual);
		}
		gladiatorVisual = Object.Instantiate(gladiatorVisualPrefab);
		gladiatorVisual.GetComponent<GladiatorVisual>().GenerateFace();
		gladiatorVisual.transform.position = currentSchool.arenaCenter.position;
		Quaternion quaternion = Quaternion.LookRotation((Cam.inst.CamPos - gladiatorVisual.transform.position).xz());
		gladiatorVisual.transform.rotation = quaternion * Quaternion.Euler(-30f, 0f, 0f);
		EffectsMan.inst.BuildEffectPuffSmall.CreateAndPlay(gladiatorVisual.transform.position).UseRealtime = true;
	}

	private int GetRecruitCost()
	{
		return 100 + 50 * previewData.skills.TotalSkillPoints();
	}

	private void RefreshUI()
	{
		if (previewData != null)
		{
			nameText.text = previewData.name;
			string text = ((previewData.alignment == GladiatorAlignment.Hero) ? LocalizationManager.GetTranslation("gladiatorui_hero") : LocalizationManager.GetTranslation("gladiatorui_heel"));
			alignmentText.SetText(LocalizationManager.GetTranslation("gladiatorui_alignment") + ": " + text);
			beastSkillsTxt.SetText("{0}", previewData.skills.bestiarius);
			secutorSkillsTxt.SetText("{0}", previewData.skills.secutor);
			retiariusSkillsTxt.SetText("{0}", previewData.skills.retiarius);
			rerollButton.interactable = Player.inst.PlayerLandmassOwner.Gold >= rerollCost;
			costText.text = ResourceAmount.Make(4, GetRecruitCost()).ToString();
			rerollCostText.text = ResourceAmount.Make(4, rerollCost).ToString();
			if (currentSchool != null)
			{
				recruitButton.interactable = currentSchool.HasSlotForRecruit() && currentSchool.CanAffordRecruit(GetRecruitCost());
			}
		}
	}

	public void Update()
	{
		if (currentSchool != null)
		{
			Vector3 position = currentSchool.arenaCenter.position;
			position += Cam.inst.cam.transform.forward.xz() * gladiatorFramingOffsetZ + Cam.inst.cam.transform.right.xz() * gladiatorFramingOffsetX;
			Cam.inst.SetTrackingPos(position);
			Cam.inst.desiredDist = camDist;
			Cam.inst.desiredPhi = camPhi;
		}
	}

	private void OnRerollClicked()
	{
		if (Player.inst.PlayerLandmassOwner.Gold >= rerollCost)
		{
			Player.inst.PlayerLandmassOwner.Gold -= rerollCost;
			SfxSystem.PlayUiSelect();
			GeneratePreview();
			RefreshUI();
		}
	}

	private void OnRecruitClicked()
	{
		SfxSystem.PlayUiSelect();
		if (currentSchool != null && currentSchool.HasSlotForRecruit())
		{
			int recruitCost = GetRecruitCost();
			Gladiator gladiator = currentSchool.RecruitGladiator(recruitCost);
			EffectsMan.inst.ChariotSponsorEffect.CreateAndPlay(gladiatorVisual.transform.position).UseRealtime = true;
			if (gladiator != null)
			{
				gladiator.name = previewData.name;
				gladiator.alignment = previewData.alignment;
				gladiator.skills = previewData.skills;
				gladiator.primarySkill = previewData.primarySkill;
				gladiator.visualDef = gladiatorVisual.GetComponent<GladiatorVisual>().currDef;
			}
			GeneratePreview();
			Hide();
		}
	}

	private void OnCancelClicked()
	{
		SfxSystem.PlayUiSelect();
		Hide();
	}
}
