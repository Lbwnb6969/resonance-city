using UnityEngine;

public class FOWHider : MonoBehaviour
{
	public Building b;

	public GameObject[] toHide;

	private void Awake()
	{
		b.visibilityChanged += B_visibilityChanged;
	}

	private void B_visibilityChanged(bool v)
	{
		for (int i = 0; i < toHide.Length; i++)
		{
			toHide[i].SetActive(v);
		}
	}

	private void OnDestroy()
	{
		b.visibilityChanged -= B_visibilityChanged;
	}
}
