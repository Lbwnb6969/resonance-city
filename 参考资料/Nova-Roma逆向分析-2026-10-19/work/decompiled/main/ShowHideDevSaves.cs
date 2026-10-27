using UnityEngine;

public class ShowHideDevSaves : MonoBehaviour
{
	private void Start()
	{
		gameObject.SetActive(BuiltInSaveManager.inst != null && BuiltInSaveManager.inst.saves.Length != 0);
	}
}
