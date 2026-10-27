using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class EffectBanner : MonoBehaviour
{
	public Button dismissButton;

	public Sprite twitchSprite;

	public Image bannerTitleImage;

	public Localize bannerSuperTitle;

	public TextMeshProUGUI bannerTitle;

	public TextMeshProUGUI bannerDescription;

	public TextMeshProUGUI bannerVoterName;

	public Color bannerVoterColor;

	public Animator BannerAnimator;

	public ConsoleUIItem entryItem;

	public static EffectBanner inst;

	private Votable pendingEffect;

	private bool resetVotesOnDismiss;

	private int prevGameSpeed;

	private void Awake()
	{
		inst = this;
	}

	private void OnEnable()
	{
		dismissButton.onClick.AddListener(DismissBanner);
	}

	private void OnDisable()
	{
		dismissButton.onClick.RemoveListener(DismissBanner);
	}

	public void ShowBannerGeneric(Votable votable, string voterName, Sprite bannerImage, string bannerTitleTerm)
	{
		bannerTitleImage.sprite = bannerImage;
		bannerSuperTitle.Term = bannerTitleTerm;
		ShowBanner(votable, voterName, resetVotes: false);
	}

	public void ShowBannerVoteSystem(Votable votable, string voterName)
	{
		bannerTitleImage.sprite = twitchSprite;
		bannerSuperTitle.Term = "Twitch Viewer Results";
		ShowBanner(votable, voterName, resetVotes: true);
	}

	public bool Showing()
	{
		return BannerAnimator.GetCurrentAnimatorStateInfo(0).IsName("VoteResultBannerShow");
	}

	private void ShowBanner(Votable votable, string voterName, bool resetVotes)
	{
		resetVotesOnDismiss = resetVotes;
		dismissButton.interactable = true;
		pendingEffect = null;
		prevGameSpeed = TimeManager.inst.speedInUse;
		TimeManager.inst.SetPaused();
		if (resetVotes && (bool)StreamerUI.inst)
		{
			StreamerUI.inst.RemoveLastVoteOptions();
		}
		if (votable != null)
		{
			if ((bool)StreamerUI.inst)
			{
				StreamerUI.inst.Visible(visible: false);
			}
			SfxSystem.inst.PlayFromBank("StreamerUIDing", Vector3.zero);
			pendingEffect = votable;
			bannerTitle.text = Util.ColorTextWrap(LocalizationManager.GetTranslation(votable.GetTitleTerm()), votable.color);
			bannerDescription.text = LocalizationManager.GetTranslation(votable.GetDescriptionTerm());
			bannerVoterName.text = string.Format(LocalizationManager.GetTranslation("VoteBannerVoterName"), Util.ColorTextWrap(voterName, bannerVoterColor));
			BannerAnimator.Play("VoteResultBannerShow");
			GameUI.inst.ClearCellSelected();
			if ((bool)StreamerUI.inst)
			{
				StreamerUI.inst.voteTimer.Enabled = false;
			}
			if (GamepadControl.inst.isControllerActive)
			{
				entryItem.Hover();
			}
		}
	}

	public void DismissBanner()
	{
		dismissButton.interactable = false;
		BannerAnimator.Play("VoteResultBannerHide");
		if (pendingEffect != null)
		{
			StatusEffectsManager.inst.StartEffect(pendingEffect.Implementation);
		}
		TimeManager.inst.SetSpeed(prevGameSpeed);
		if ((bool)StreamerUI.inst)
		{
			if (resetVotesOnDismiss)
			{
				StreamerUI.inst.NewVoteSet();
			}
			else
			{
				StreamerUI.inst.ResumeCountdown();
			}
		}
		SfxSystem.PlayUiSelect();
	}
}
