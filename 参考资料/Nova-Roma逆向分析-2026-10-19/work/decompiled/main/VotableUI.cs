using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class VotableUI : MonoBehaviour
{
	private Toggle toggle;

	private TextMeshProUGUI text;

	private Votable votable;

	private void SetupMembers()
	{
		if (toggle == null)
		{
			toggle = GetComponentInChildren<Toggle>();
		}
		if (text == null)
		{
			text = GetComponentInChildren<TextMeshProUGUI>();
		}
	}

	public void SetVotable(Votable votable)
	{
		this.votable = votable;
		SetupMembers();
		text.GetComponent<Localize>().Term = this.votable.GetTitleTerm();
		text.color = votable.color;
	}

	private void Start()
	{
		SetupMembers();
		toggle.onValueChanged.AddListener((bool toggleState) =>
		{
			SfxSystem.PlayUiSelect();
			votable.playerEnabled = toggleState;
			text.color = (toggleState ? votable.color : Color.gray);
		});
	}

	private void Update()
	{
	}
}
