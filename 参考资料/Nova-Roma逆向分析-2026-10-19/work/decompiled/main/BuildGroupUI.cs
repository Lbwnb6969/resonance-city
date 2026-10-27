using TMPro;
using UnityEngine;

public class BuildGroupUI : MonoBehaviour
{
	public Transform itemContainer;

	public TextMeshProUGUI emptyTMP;

	public void SetVisibility(bool v)
	{
		gameObject.SetActive(v);
	}
}
