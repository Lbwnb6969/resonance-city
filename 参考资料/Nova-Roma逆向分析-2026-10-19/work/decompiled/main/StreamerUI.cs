using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class StreamerUI : MonoBehaviour
{
	public static StreamerUI inst;

	private Regex voteStringMatcher;

	private TMP_InputField twitchHandleInputField;

	public TextMeshProUGUI voteTimerText;

	public Transform voteItemContainerContent;

	public EventTrigger scrollableRegion;

	private int voteCount = 3;

	public TMP_InputField input;

	public GameObject VoteOptionPrefab;

	public GameObject VoteHeadingPrefab;

	public Transform activeVoteContainer;

	public GameObject activeVotePrefab;

	public List<ActiveVoteUI> activelyVotableUI = new List<ActiveVoteUI>(3);

	public Animator ThisAnimator;

	public Color onlineColor = Color.green;

	public Color offlineColor = Color.red;

	public Color pendingColor = Color.yellow;

	public Image check;

	public Image checkSmall;

	public Localize statusConnectionText;

	public TMP_Dropdown intervalDropdown;

	public TMP_Dropdown voteCountDropdown;

	private bool twitchMode;

	public TwitchIRC twitchIrc;

	public Timer voteTimer = new Timer(120f);

	private Timer pendingUsernameLookupTimer = new Timer(1f);

	private Timer roomExistTimeout = new Timer(10f);

	private string pendingUsername;

	private bool visible;

	private List<int> topIndexs = new List<int>(6);

	private List<Votable> lastVoteSet = new List<Votable>(6);

	private List<Votable> thisVoteSet = new List<Votable>(6);

	private int voteIndex = 1;

	public bool TwitchMode => twitchMode;

	private void Awake()
	{
		voteStringMatcher = new Regex("^#*\\s*([0-9]+)", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
		inst = this;
		object[] uIVotableLayout = TwitchBonus.UIVotableLayout;
		foreach (object obj in uIVotableLayout)
		{
			if (obj is Votable votable)
			{
				TwitchBonus.VotablesOnly.Add(votable);
				VotableUI component = UnityEngine.Object.Instantiate(VoteOptionPrefab).GetComponent<VotableUI>();
				component.SetVotable(votable);
				component.transform.SetParent(voteItemContainerContent, worldPositionStays: false);
				component.gameObject.SetActive(value: true);
			}
			if (obj is VoteListHeading voteListHeading)
			{
				VoteHeadingUI component2 = UnityEngine.Object.Instantiate(VoteHeadingPrefab).GetComponent<VoteHeadingUI>();
				component2.SetTerm(voteListHeading.GetTitleTerm());
				component2.transform.SetParent(voteItemContainerContent, worldPositionStays: false);
				component2.gameObject.SetActive(value: true);
			}
		}
		intervalDropdown.value = 3;
		voteCountDropdown.value = 1;
		voteCount = 3;
		twitchIrc = GetComponent<TwitchIRC>();
	}

	public void SetIntervalOption(int option)
	{
		switch (option)
		{
		case 0:
			voteTimer.Duration = 30f;
			break;
		case 1:
			voteTimer.Duration = 60f;
			break;
		case 2:
			voteTimer.Duration = 90f;
			break;
		case 3:
			voteTimer.Duration = 120f;
			break;
		case 4:
			voteTimer.Duration = 180f;
			break;
		case 5:
			voteTimer.Duration = 240f;
			break;
		case 6:
			voteTimer.Duration = 300f;
			break;
		case 7:
			voteTimer.Duration = 600f;
			break;
		}
	}

	public void SetVoteCountOption(int option)
	{
		switch (option)
		{
		case 0:
			voteCount = 2;
			break;
		case 1:
			voteCount = 3;
			break;
		case 2:
			voteCount = 4;
			break;
		case 3:
			voteCount = 5;
			break;
		case 4:
			voteCount = 6;
			break;
		}
	}

	private void OnEnable()
	{
		twitchHandleInputField = GetComponentInChildren<TMP_InputField>();
		twitchHandleInputField.onSelect.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = false;
		});
		twitchHandleInputField.onEndEdit.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = true;
		});
		GetComponent<TwitchIRC>().messageRecievedEvent.AddListener(ChatProcessor);
		visible = false;
		SetOnline(show: false);
		if (!string.IsNullOrEmpty(pendingUsername))
		{
			SetUsername(pendingUsername);
		}
	}

	private void OnDisable()
	{
		GetComponent<TwitchIRC>().messageRecievedEvent.RemoveListener(ChatProcessor);
		twitchHandleInputField.onSelect.RemoveAllListeners();
		twitchHandleInputField.onEndEdit.RemoveAllListeners();
	}

	public void ToggleVisible()
	{
		Visible(!visible);
	}

	public void Visible(bool visible)
	{
		this.visible = visible;
		ThisAnimator.Play(visible ? "VoterSettingsAnimationShow" : "VoterSettingsAnimationHide");
		if (visible && string.IsNullOrEmpty(pendingUsername))
		{
			SelectInputField();
		}
	}

	private void SelectInputField()
	{
		Invoke("SelectInputFieldInvoke", 0f);
	}

	private void SelectInputFieldInvoke()
	{
		twitchHandleInputField.ActivateInputField();
		twitchHandleInputField.Select();
	}

	private void Update()
	{
		if (pendingUsernameLookupTimer.Update(Time.unscaledDeltaTime))
		{
			pendingUsernameLookupTimer.Enabled = false;
			GetComponent<TwitchIRC>().SwitchUsername(pendingUsername);
			roomExistTimeout.Enabled = true;
			roomExistTimeout.Reset();
		}
		if (roomExistTimeout.Update(Time.unscaledDeltaTime))
		{
			roomExistTimeout.Enabled = false;
			SetOnline(show: false);
		}
		else if (roomExistTimeout.Enabled && !twitchIrc.pendingJoin && twitchIrc.joined)
		{
			roomExistTimeout.Enabled = false;
			SfxSystem.inst.PlayFromBank("StreamerUIConnect", Vector3.zero);
			SetOnline(show: true);
			NewVoteSet();
		}
		activeVoteContainer.gameObject.SetActive(activeVoteContainer.childCount > 2);
		int num = (int)(voteTimer.Duration - voteTimer.CurrTime);
		if (activeVoteContainer.gameObject.activeSelf && voteTimer.Update(Time.unscaledDeltaTime))
		{
			OnVotingEnd();
		}
		else
		{
			TimeSpan timeSpan = TimeSpan.FromSeconds(voteTimer.Duration - voteTimer.CurrTime);
			voteTimerText.text = $"{timeSpan.Minutes:00}:{timeSpan.Seconds:00}";
		}
		int num2 = (int)(voteTimer.Duration - voteTimer.CurrTime);
		if (num2 < 3 && num2 != num)
		{
			SfxSystem.inst.PlayFromBank("StreamerUITick", Vector3.zero);
		}
	}

	private void SetOnline(bool show)
	{
		check.color = (show ? onlineColor : offlineColor);
		checkSmall.color = (show ? onlineColor : offlineColor);
		statusConnectionText.Term = (show ? "VoterStatusConnected" : "VoterStatusNotConnected");
		RemoveLastVoteOptions();
		twitchMode = show;
	}

	public void SetUsername(string username)
	{
		username = username.ToLowerInvariant();
		check.color = pendingColor;
		checkSmall.color = pendingColor;
		statusConnectionText.Term = "VoterStatusPending";
		pendingUsername = username;
		pendingUsernameLookupTimer.Reset();
		pendingUsernameLookupTimer.Enabled = true;
	}

	private void ChatProcessor(TwitchChatMessage msg)
	{
		ChatProcessor(msg.message, msg.username);
	}

	public void ChatProcessor(string message, string username)
	{
		if (message.Length <= 0)
		{
			return;
		}
		Match match = voteStringMatcher.Match(message);
		if (!match.Success)
		{
			return;
		}
		int result = 0;
		if (!int.TryParse(match.Groups[match.Groups.Count - 1].Captures[0].Value, out result))
		{
			return;
		}
		for (int i = 0; i < activelyVotableUI.Count; i++)
		{
			ActiveVoteUI activeVoteUI = activelyVotableUI[i];
			if (activeVoteUI.GetIndex() == result)
			{
				activeVoteUI.AddVoter(username);
			}
			else
			{
				activeVoteUI.RemoveVoter(username);
			}
		}
	}

	public Votable GetWinningVote(out string randomVoterName)
	{
		int num = -1;
		int num2 = activelyVotableUI.Max((ActiveVoteUI x) => x.Votes.Count);
		topIndexs.Clear();
		for (int num3 = 0; num3 < activelyVotableUI.Count; num3++)
		{
			if (activelyVotableUI[num3].Votes.Count == num2)
			{
				topIndexs.Add(num3);
			}
		}
		randomVoterName = string.Empty;
		if (num2 == 0)
		{
			return null;
		}
		num = topIndexs[SRand.Range(0, topIndexs.Count)];
		Votable votable = activelyVotableUI[num].GetVotable();
		randomVoterName = activelyVotableUI[num].Votes[0];
		RemoveLastVoteOptions();
		return votable;
	}

	public void RemoveLastVoteOptions()
	{
		foreach (Transform item in activeVoteContainer.transform)
		{
			if (item.gameObject.activeSelf && item.gameObject.name != "Title")
			{
				UnityEngine.Object.Destroy(item.gameObject);
			}
		}
		activelyVotableUI.Clear();
	}

	public void NewVoteSet()
	{
		RemoveLastVoteOptions();
		List<Votable> list = new List<Votable>();
		int i = 0;
		for (int count = TwitchBonus.VotablesOnly.Count; i < count; i++)
		{
			Votable votable = TwitchBonus.VotablesOnly[i];
			bool flag = (bool)votable.Implementation.GetMethod("PrereqSatisfied", BindingFlags.Static | BindingFlags.Public | BindingFlags.FlattenHierarchy).Invoke(null, null);
			if ((votable.playerEnabled & flag) && !lastVoteSet.Contains(votable))
			{
				list.Add(TwitchBonus.VotablesOnly[i]);
			}
		}
		for (int j = 0; j < voteCount; j++)
		{
			if (list.Count <= 0)
			{
				break;
			}
			int index = SRand.Range(0, list.Count);
			Votable votable2 = list[index];
			list.RemoveAt(index);
			AddActiveVotable(votable2);
			thisVoteSet.Add(votable2);
		}
		if (thisVoteSet.Count < voteCount)
		{
			int num = voteCount - thisVoteSet.Count;
			for (int k = 0; k < num && k < lastVoteSet.Count; k++)
			{
				Votable votable3 = lastVoteSet[k];
				bool flag2 = (bool)votable3.Implementation.GetMethod("PrereqSatisfied", BindingFlags.Static | BindingFlags.Public | BindingFlags.FlattenHierarchy).Invoke(null, null);
				if (votable3.playerEnabled & flag2)
				{
					AddActiveVotable(votable3);
					thisVoteSet.Add(votable3);
				}
			}
		}
		List<Votable> list2 = lastVoteSet;
		lastVoteSet = thisVoteSet;
		thisVoteSet = list2;
		thisVoteSet.Clear();
		voteTimer.Enabled = lastVoteSet.Count > 0;
		voteTimer.Reset();
	}

	public void ResumeCountdown()
	{
		voteTimer.Enabled = lastVoteSet.Count > 0;
	}

	public void AddActiveVotable(Votable votable)
	{
		ActiveVoteUI component = UnityEngine.Object.Instantiate(activeVotePrefab).GetComponent<ActiveVoteUI>();
		component.gameObject.SetActive(value: true);
		component.transform.SetParent(activeVoteContainer, worldPositionStays: false);
		component.SetVotable(voteIndex, votable);
		activelyVotableUI.Add(component);
		voteIndex++;
		if (voteIndex > 9)
		{
			voteIndex -= 9;
		}
	}

	public void OnVotingEnd()
	{
		if (TwitchMode)
		{
			Votable winningVote = GetWinningVote(out var randomVoterName);
			if (winningVote != null)
			{
				EffectBanner.inst.ShowBannerVoteSystem(winningVote, randomVoterName);
			}
			else
			{
				NewVoteSet();
			}
		}
	}
}
