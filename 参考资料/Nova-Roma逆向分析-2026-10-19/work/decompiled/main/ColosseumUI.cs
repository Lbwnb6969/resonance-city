using UnityEngine;

public class ColosseumUI : MonoBehaviour
{
	[Header("Modals")]
	public RoundResultUI roundResultUI;

	public ColosseumSummaryUI summaryUI;

	public FightPresentationUI fightUI;

	public static ColosseumUI inst;

	private void Awake()
	{
		inst = this;
		roundResultUI.gameObject.SetActive(value: false);
		summaryUI.gameObject.SetActive(value: false);
		fightUI.gameObject.SetActive(value: false);
	}
}
