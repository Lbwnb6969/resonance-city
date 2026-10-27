using UnityEngine;

public class ThiefSack : MonoBehaviour
{
	public GameObject sackFull;

	public GameObject sackEmpty;

	private void Start()
	{
		SetStolenVisibility(show: false);
	}

	public void SetStolenVisibility(bool show)
	{
		sackFull.SetActive(show);
		sackEmpty.SetActive(!show);
	}
}
