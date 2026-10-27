using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class GovernorEntryUI : MonoBehaviour, IPointerEnterHandler, IEventSystemHandler, IPointerExitHandler, IPointerClickHandler
{
	public string message;

	public string sound;

	public string anim;

	public float animTime;

	public Animator animator;

	public Light light;

	internal bool lightOn;

	public TextMeshProUGUI localizedName;

	public TextMeshProUGUI traits;

	public GameObject detailDimmer;

	public GameObject currentContainer;

	public GameObject confirmContainer;

	public Button confirm;

	public Button cancel;

	public Localize confirmButtonTerm;

	internal int idx;

	internal bool ignoreClick;

	private void Start()
	{
		confirm.onClick.AddListener(() =>
		{
			AdvisorUI.inst.OnClickedConfirmAppoint();
		});
		cancel.onClick.AddListener(() =>
		{
			AdvisorUI.inst.OnClickedCancelAppoint();
		});
	}

	public void OnPointerEnter(PointerEventData pd)
	{
		if (AdvisorUI.inst.status == AdvisorUI.Status.SelectingGovernor)
		{
			lightOn = true;
			animator.CrossFadeInFixedTime("interested", 0.4f);
			animTime = 0.5f;
		}
	}

	public static string GetTraitTxt(Governor governor)
	{
		string text = "";
		for (int i = 0; i < governor.traits.Count; i++)
		{
			Traits.Trait def = Traits.inst.GetDef(governor.traits[i].id);
			text = ((!governor.traits[i].negative) ? (text + "<b><color=#D6FF8E>" + LocalizationManager.GetTranslation("trait_" + def.locTerm + "_positivetitle") + "</color></b>\n") : (text + "<b><color=#FFA68D>" + LocalizationManager.GetTranslation("trait_" + def.locTerm + "_negativetitle") + "</color></b>\n"));
			text = text + def.GetDesc(governor.traits[i]) + "\n\n";
		}
		return text;
	}

	public void SetGovernor(Governor governor, bool current)
	{
		localizedName.text = governor.profile.Name;
		traits.text = GetTraitTxt(governor);
		Util.SetActive(currentContainer, current);
		Util.SetActive(confirmContainer, active: false);
		if (current)
		{
			confirmButtonTerm.Term = "advisorui_governorreappoint";
		}
		else
		{
			confirmButtonTerm.Term = "advisorui_governorappoint";
		}
	}

	public void OnPointerExit(PointerEventData pd)
	{
		lightOn = false;
	}

	public void OnPointerClick(PointerEventData eventData)
	{
		if (!ignoreClick)
		{
			AdvisorUI.inst.OnSelectedGovernor(idx);
		}
	}
}
