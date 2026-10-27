using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class GovernorUI : MonoBehaviour
{
	public static GovernorUI inst;

	public SlideAnim slideAnim;

	public TextMeshProUGUI nameTxT;

	public TextMeshProUGUI descTxt;

	public TextMeshProUGUI termTxt;

	public GameObject explanationUI;

	public GameObject governorPortrait;

	public GameObject termNofity;

	public Button selectGovernor;

	private bool wasVisible;

	public bool forceUpdate;

	public Governor lastGov;

	private int enterCount;

	private void Awake()
	{
		inst = this;
	}

	private void Update()
	{
		bool flag = !GameState.inst.DevOptionShowUIforAIs() && Player.inst.FocusedLandMass != -1 && !GameUI.inst.workerUI.Visible && World.GetLandmassOwner(Player.inst.FocusedLandMass) == Player.inst.PlayerLandmassOwner && !GameUI.inst.diplomacyUI.gameObject.activeSelf && !ChariotRaceTrackUI.inst.IsVisible() && !MerchantUI.inst.IsVisible();
		slideAnim.Play(flag ? SlideAnim.PlayMode.Forward : SlideAnim.PlayMode.Reverse);
		if (flag)
		{
			Governor focusedGovenor = Player.inst.FocusedGovenor;
			if (!wasVisible || lastGov != focusedGovenor || forceUpdate)
			{
				if (focusedGovenor != null)
				{
					nameTxT.text = focusedGovenor.profile.Name;
					descTxt.text = GovernorEntryUI.GetTraitTxt(focusedGovenor);
				}
				forceUpdate = false;
			}
			int count = World.inst.GetVillagersForLandMass(Player.inst.FocusedLandMass).Count;
			Util.SetActive(governorPortrait, active: false);
			Util.SetActive(termTxt.gameObject, focusedGovenor != null || count < Player.inst.citizensGovernorReq);
			lastGov = focusedGovenor;
			bool flag2 = false;
			if (lastGov == null)
			{
				if (count < Player.inst.citizensGovernorReq)
				{
					termTxt.text = string.Format(ScriptLocalization.workerui_barracksui_locked, Player.inst.citizensGovernorReq);
				}
				else
				{
					termTxt.text = "";
				}
			}
			else
			{
				flag2 = lastGov.GetRemainingTerm() < 0f;
				if (!flag2)
				{
					termTxt.color = new Color(0.8571f, 0.9141f, 0.9245f);
					termTxt.text = AdvisorUI.GetTermTxt(lastGov);
				}
				else
				{
					termTxt.color = Color.yellow;
					termTxt.text = LocalizationManager.GetTranslation("governor_termup");
				}
			}
			Util.SetActive(termNofity, flag2 && lastGov != null);
			selectGovernor.interactable = count >= Player.inst.citizensGovernorReq || focusedGovenor != null;
			Util.SetActive(selectGovernor.gameObject, (focusedGovenor == null) | flag2);
		}
		else
		{
			enterCount = 0;
		}
		Util.SetActive(explanationUI.gameObject, ((enterCount > 0) & flag) && lastGov != null);
		wasVisible = flag;
	}

	public void OnClickedSelectGovernor()
	{
		AdvisorUI.inst.Show();
	}

	private void OnEnable()
	{
		enterCount = 0;
	}

	public void PointerEnter()
	{
		enterCount++;
	}

	public void PointerExit()
	{
		enterCount--;
		if (enterCount < 0)
		{
			enterCount = 0;
		}
	}
}
