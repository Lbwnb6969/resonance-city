using UnityEngine;

public class BuiltInSaveManager : MonoBehaviour
{
	public BuiltInSave[] saves;

	public static BuiltInSaveManager inst;

	public void Awake()
	{
		inst = this;
	}
}
