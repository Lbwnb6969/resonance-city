using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class RivalItemUI : MonoBehaviour
{
	internal int bannerIdx = -1;

	private bool hover;

	private float hoverTime;

	public RawImage bannerImage;

	public TextMeshProUGUI rivalName;

	public TextMeshProUGUI flavorText;

	public TMP_Dropdown personalityDropdown;

	public Button removeButton;

	public Button enableButton;

	public GameObject disabledCover;

	public GameObject lockedCover;

	public AIStartFlagpole flag;

	public GameObject d3Banner;

	public EventTrigger bannerTrigger;

	public Animator animator;

	public MeshRenderer flagMesh;

	public RawImage flagImage;

	public GameObject top;

	public GameObject bottom;

	public bool Enabled
	{
		get
		{
			return !disabledCover.activeSelf;
		}
		set
		{
			enabled = value;
			if (Locked)
			{
				top.SetActive(value: false);
				bottom.SetActive(value: false);
				disabledCover.SetActive(value: false);
			}
			else if (disabledCover.activeSelf && enabled)
			{
				top.SetActive(enabled);
				bottom.SetActive(enabled);
				disabledCover.SetActive(!enabled);
			}
			else if (!disabledCover.activeSelf && !enabled)
			{
				disabledCover.SetActive(!enabled);
				top.SetActive(enabled);
				bottom.SetActive(enabled);
			}
		}
	}

	public bool Locked
	{
		get
		{
			return lockedCover.activeSelf;
		}
		set
		{
			lockedCover.SetActive(value);
			Enabled = value;
		}
	}

	public void Start()
	{
		personalityDropdown.value = 1;
		animator = GetComponent<Animator>();
		EventTrigger.Entry entry = new EventTrigger.Entry();
		entry.eventID = EventTriggerType.PointerEnter;
		entry.callback.AddListener((BaseEventData eventData) =>
		{
			OnEnter3dBanner();
		});
		bannerTrigger.triggers.Add(entry);
		EventTrigger.Entry entry2 = new EventTrigger.Entry();
		entry2.eventID = EventTriggerType.PointerExit;
		entry2.callback.AddListener((BaseEventData eventData) =>
		{
			OnExit3dBanner();
		});
		bannerTrigger.triggers.Add(entry2);
	}

	private void OnEnter3dBanner()
	{
		hover = true;
	}

	private void OnExit3dBanner()
	{
		hover = false;
	}

	public void Update()
	{
		if (hover)
		{
			hoverTime = Mathf.Clamp01(hoverTime + Time.deltaTime * 8f);
		}
		else
		{
			hoverTime = Mathf.Clamp01(hoverTime - Time.deltaTime * 8f);
		}
		animator.SetFloat("HoverTime", hoverTime);
		bool activeInHierarchy = flag.gameObject.activeInHierarchy;
		flagImage.enabled = activeInHierarchy;
		d3Banner.gameObject.SetActive(!activeInHierarchy);
	}

	public void SetTexture(Texture texture)
	{
		flagMesh.material.SetTexture("_MainTex", texture);
		flagImage.texture = texture;
	}

	public AIKingdom.SkillLevel GetSkillLevel()
	{
		return (AIKingdom.SkillLevel)personalityDropdown.value;
	}
}
