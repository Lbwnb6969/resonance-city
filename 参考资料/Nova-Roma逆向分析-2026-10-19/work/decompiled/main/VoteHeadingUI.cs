using I2.Loc;
using UnityEngine;

public class VoteHeadingUI : MonoBehaviour
{
	public void SetTerm(string term)
	{
		transform.Find("VoteItemText").GetComponent<Localize>().Term = term;
	}
}
