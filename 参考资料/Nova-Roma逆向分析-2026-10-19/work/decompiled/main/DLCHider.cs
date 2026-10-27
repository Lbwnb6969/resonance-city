using UnityEngine;

public class DLCHider : MonoBehaviour
{
	private void Update()
	{
		gameObject.SetActive(Player.inst.IsDecorationsPack());
	}
}
