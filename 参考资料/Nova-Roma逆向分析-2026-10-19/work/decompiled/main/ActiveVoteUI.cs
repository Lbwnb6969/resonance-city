using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class ActiveVoteUI : MonoBehaviour
{
	private TextMeshProUGUI voteNum;

	private TextMeshProUGUI voteName;

	private TextMeshProUGUI voteCount;

	private Votable votable;

	private int index;

	private Image flashBG;

	public List<string> Votes;

	private EventTrigger trigger;

	public Votable GetVotable()
	{
		return votable;
	}

	public int GetIndex()
	{
		return index;
	}

	public void SetVotable(int index, Votable votable)
	{
		Setup();
		this.votable = votable;
		this.index = index;
		voteNum.text = "#" + index;
		voteName.GetComponent<Localize>().Term = votable.GetTitleTerm();
		voteName.color = votable.color;
		Votes.Clear();
		voteCount.text = "+" + 0;
	}

	public void AddVoter(string username)
	{
		if (!Votes.Contains(username))
		{
			if (Votes.Count == 0)
			{
				SfxSystem.inst.PlayFromBank("StreamerUIVote", Vector3.zero);
			}
			Votes.Add(username);
			flashBG.color = new Color(1f, 1f, 1f, 0.5f);
			voteCount.text = "+" + Votes.Count;
		}
	}

	public void RemoveVoter(string username)
	{
		if (Votes.Contains(username))
		{
			Votes.Remove(username);
			voteCount.text = "+" + Votes.Count;
		}
	}

	private void Start()
	{
		Setup();
	}

	private void Setup()
	{
		if (voteNum == null)
		{
			voteNum = transform.Find("VoteNum").GetComponent<TextMeshProUGUI>();
		}
		if (voteName == null)
		{
			voteName = transform.Find("VoteName").GetComponent<TextMeshProUGUI>();
		}
		if (voteCount == null)
		{
			voteCount = transform.Find("VoteCount").GetComponent<TextMeshProUGUI>();
		}
		if (flashBG == null)
		{
			flashBG = GetComponent<Image>();
		}
		if (Votes == null)
		{
			Votes = new List<string>(10);
		}
		if (trigger == null)
		{
			trigger = GetComponent<EventTrigger>();
			EventTrigger.Entry entry = new EventTrigger.Entry
			{
				eventID = EventTriggerType.PointerClick
			};
			entry.callback.AddListener((BaseEventData data) =>
			{
				StreamerUI.inst.ChatProcessor(voteNum.text, "host");
			});
			trigger.triggers.Add(entry);
		}
	}

	private void Update()
	{
		if (flashBG.color.a >= 0f)
		{
			flashBG.color = new Color(1f, 1f, 1f, flashBG.color.a - Time.unscaledDeltaTime);
		}
	}
}
