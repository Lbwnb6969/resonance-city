using System.Collections.Generic;
using Assets;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class PersonUI : UIWindowBase
{
	public static PersonUI inst;

	public TextMeshProUGUI description;

	public TextMeshProUGUI thought;

	public TextMeshProUGUI age;

	public TextMeshProUGUI title;

	public TMP_InputField villagerName;

	public TextMeshProUGUI[] skillName = new TextMeshProUGUI[3];

	public TextMeshProUGUI[] skillValue = new TextMeshProUGUI[3];

	public Villager villager;

	public GameObject[] skills;

	public GameObject[] layoutsToForceUpdate;

	public GameObject personModel;

	public MeshFilter personModelMesh;

	public Material personModelMaterial;

	public PooledObject freeResourcePrefab;

	public Transform freeResourceContainer;

	private int previousFreeResourceCount;

	public Button residenceTrackBtn;

	private bool initedTitleEditor;

	private TMP_SelectionCaret caret;

	public TMP_InputField titleInput;

	public EventTrigger titleEventTrigger;

	public GameObject editBackground;

	private bool isTitleHovered;

	public Button focusWorkBtn;

	public GameObject tiredError;

	public GameObject plagueObj;

	public Image mildPlagueIcon;

	public Image severePlagueIcon;

	private IEmployer employer;

	public float offsetScale = 1f;

	private void Awake()
	{
		inst = this;
	}

	public static string SkillValueToTitle(float v)
	{
		if (v >= 0f && v < 0.15f)
		{
			return ScriptLocalization.PersonUISkillApprentice;
		}
		if (v >= 0.15f && v < 0.5f)
		{
			return ScriptLocalization.PersonUISkillJourneyman;
		}
		if (v >= 0.5f && v < 0.75f)
		{
			return ScriptLocalization.PersonUISkillMaster;
		}
		if (v >= 0.75f)
		{
			return ScriptLocalization.PersonUISkillGrandMaster;
		}
		return "error";
	}

	public override void SetVisible(bool v)
	{
		if (!v && Cam.inst.IsTracking(villager))
		{
			Cam.inst.ClearTrack();
		}
		base.SetVisible(v);
	}

	public void SetSelectedPerson(Villager v)
	{
		if (v == null)
		{
			villager = null;
			return;
		}
		TryInitTitleEditor();
		caret = titleInput.GetComponentInChildren<TMP_SelectionCaret>();
		villager = v;
		SfxSystem.inst.PlayFromBank("VillagerSelect", villager.Pos);
		villagerName.text = v.name;
		thought.text = v.GetThought();
		title.GetComponent<Localize>().SetTerm(v.profile.GetTitleTerm());
		if (v.job != null)
		{
			employer = v.job.employer;
			description.text = villager.job.GetDescription();
		}
		else
		{
			description.text = "";
		}
		skills[0].SetActive(value: false);
		skills[1].SetActive(value: false);
		skills[2].SetActive(value: false);
		age.text = string.Format(ScriptLocalization.PersonUIYearsOld, Mathf.FloorToInt(v.timeAlive / SeasonManager.inst.TimeInYear()));
		if (v.useLadyMesh)
		{
			personModelMesh.mesh = VillagerSystem.inst.ladyVillagerMeshs[(int)v.MeshType];
			personModelMaterial.SetVector("_HeadColor", VillagerSystem.inst.ladyInstances.data[(int)v.MeshType].headColors.data[v.s][v.idx]);
			personModelMaterial.SetVector("_BodyColor", VillagerSystem.inst.ladyInstances.data[(int)v.MeshType].bodyColors.data[v.s][v.idx]);
			personModelMaterial.SetVector("_HairColor", VillagerSystem.inst.ladyInstances.data[(int)v.MeshType].hairColors.data[v.s][v.idx]);
		}
		else
		{
			personModelMesh.mesh = VillagerSystem.inst.villagerMeshs[(int)v.MeshType];
			personModelMaterial.SetVector("_HeadColor", VillagerSystem.inst.instances.data[(int)v.MeshType].headColors.data[v.s][v.idx]);
			personModelMaterial.SetVector("_BodyColor", VillagerSystem.inst.instances.data[(int)v.MeshType].bodyColors.data[v.s][v.idx]);
			personModelMaterial.SetVector("_HairColor", VillagerSystem.inst.instances.data[(int)v.MeshType].hairColors.data[v.s][v.idx]);
		}
		previousFreeResourceCount = -1;
	}

	private void TryInitTitleEditor()
	{
		if (!initedTitleEditor)
		{
			EventTrigger.Entry entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerEnter;
			entry.callback.AddListener((BaseEventData eventData) =>
			{
				isTitleHovered = true;
			});
			titleEventTrigger.triggers.Add(entry);
			entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerExit;
			entry.callback.AddListener((BaseEventData eventData) =>
			{
				isTitleHovered = false;
			});
			titleEventTrigger.triggers.Add(entry);
			titleInput.onSelect.AddListener((string val) =>
			{
				GameState.inst.AlphaNumericHotkeysEnabled = false;
			});
			titleInput.onEndEdit.AddListener((string val) =>
			{
				villager.CustomName = titleInput.text;
				GameState.inst.AlphaNumericHotkeysEnabled = true;
				titleInput.textComponent.rectTransform.localPosition = Vector3.zero;
				caret.rectTransform.localPosition = Vector3.zero;
			});
			initedTitleEditor = true;
		}
	}

	private void OnDisable()
	{
	}

	public void OnClickTrack()
	{
		if (villager != null)
		{
			Cam.inst.Track(villager);
			SetCamera();
		}
	}

	private void SetCamera()
	{
		if (Cam.inst.desiredDist < 12f)
		{
			Cam.inst.desiredDist = 12f;
		}
		if (Cam.inst.desiredPhi < 35f)
		{
			Cam.inst.desiredPhi = 35f;
		}
	}

	public void OnClickTrackResidence()
	{
		if (villager != null)
		{
			Building component = (villager.Residence as Home).GetComponent<Building>();
			Cam.inst.SetDesiredTrackingPos(component.Center());
			GameUI.inst.ClearUIForClick();
			GameUI.inst.SetSelectedBuildingNew(component);
			SetCamera();
		}
	}

	public void OnClickTrackWorkplace()
	{
		if (villager != null)
		{
			Cam.inst.SetDesiredTrackingPos(villager.job.employer.GetPosition());
			if (villager.job.employer is MonoBehaviour monoBehaviour && (bool)monoBehaviour.GetComponent<Building>())
			{
				Building component = monoBehaviour.GetComponent<Building>();
				GameUI.inst.ClearUIForClick();
				GameUI.inst.SetSelectedBuildingNew(component);
			}
			SetCamera();
		}
	}

	public override void UpdateInternal(float dt)
	{
		base.UpdateInternal(dt);
		if (!(villager != null))
		{
			return;
		}
		IEmployer employer = null;
		if (villager.job != null)
		{
			employer = villager.job.employer;
			description.text = villager.job.GetDescription();
		}
		else
		{
			description.text = "";
		}
		if (this.employer != employer)
		{
			SetSelectedPerson(villager);
			this.employer = employer;
		}
		focusWorkBtn.interactable = villager.job != null;
		Util.SetActive(tiredError, villager.thought.thought == ThoughtBubbleSystem.Thought.Tired);
		if (villager.sick)
		{
			Player.inst.GetInfectionJumpTime();
			float plagueSeekShrineThreshold = Player.inst.GetPlagueSeekShrineThreshold();
			Util.SetEnabled(mildPlagueIcon, villager.sickTime < plagueSeekShrineThreshold);
			Util.SetEnabled(severePlagueIcon, villager.sickTime >= plagueSeekShrineThreshold);
			Util.SetActive(plagueObj, villager.sickTime >= plagueSeekShrineThreshold && !(villager.job is PlaguedJob));
		}
		else
		{
			Util.SetEnabled(mildPlagueIcon, active: false);
			Util.SetEnabled(severePlagueIcon, active: false);
			Util.SetActive(plagueObj, active: false);
		}
		residenceTrackBtn.interactable = villager.Residence != null;
		float num = villager.Rot.eulerAngles.y - Cam.inst.cam.transform.rotation.eulerAngles.y;
		num = ((num < 0f) ? (num + 360f) : num);
		personModel.transform.localRotation = Quaternion.AngleAxis(num, Vector3.up);
		List<FreeResource> heldResources = villager.HeldResources;
		if (previousFreeResourceCount != heldResources.Count)
		{
			if (heldResources.Count > freeResourceContainer.childCount)
			{
				for (int i = freeResourceContainer.childCount; i < heldResources.Count; i++)
				{
					PooledObject pooledObject = freeResourcePrefab.Alloc(Vector3.zero);
					pooledObject.transform.SetParent(freeResourceContainer, worldPositionStays: false);
					pooledObject.transform.localPosition = Vector3.zero;
				}
			}
			else if (heldResources.Count < freeResourceContainer.childCount)
			{
				for (int num2 = freeResourceContainer.childCount; num2 > heldResources.Count; num2--)
				{
					freeResourceContainer.GetChild(num2 - 1).GetComponent<PooledObject>().Release();
				}
			}
			for (int j = 0; j < heldResources.Count; j++)
			{
				Transform child = freeResourceContainer.GetChild(j);
				child.GetComponent<MeshFilter>().mesh = FreeResourceSystem.inst.resourceDefMap[heldResources[j].resourceID].cachedMesh;
				child.transform.localPosition = heldResources[j].offset;
				child.localScale = Vector3.one;
			}
			previousFreeResourceCount = heldResources.Count;
		}
		Vector2 anchoredPosition = Mathff.WorldPosToScreen(villager.GetPosWithOffset(), GameUI.inst.rectT);
		GetComponent<RectTransform>().anchoredPosition = anchoredPosition;
		editBackground.SetActive(titleInput.isFocused || isTitleHovered);
	}
}
