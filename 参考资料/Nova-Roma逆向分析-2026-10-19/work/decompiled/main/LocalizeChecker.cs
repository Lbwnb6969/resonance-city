using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;

public class LocalizeChecker : MonoBehaviour
{
	public static LocalizeChecker inst;

	private HashSet<int> checkedInstanceIDs = new HashSet<int>();

	private float timer;

	private void Awake()
	{
		inst = this;
	}

	private void Update()
	{
		timer += Time.unscaledDeltaTime;
		if (!(timer < 0.5f))
		{
			timer = 0f;
			TextMeshProUGUI[] array = Object.FindObjectsByType<TextMeshProUGUI>(FindObjectsSortMode.None);
			for (int i = 0; i < array.Length; i++)
			{
				CheckAndFix(array[i]);
			}
		}
	}

	private void CheckAndFix(TextMeshProUGUI tmp)
	{
		int instanceID = tmp.GetInstanceID();
		if (checkedInstanceIDs.Add(instanceID) && !(tmp.GetComponent<Localize>() != null))
		{
			string fullPath = GetFullPath(tmp.transform);
			Debug.LogWarning("[LocalizeChecker] Missing Localize on: " + fullPath, tmp.gameObject);
			string text = tmp.text;
			bool num = tmp.font != null && tmp.font.name == "Fundamental Brigade SDF - bold";
			Localize localize = tmp.gameObject.AddComponent<Localize>();
			localize.Term = "-";
			localize.SecondaryTerm = "Fundamental Brigade SDF";
			if (num)
			{
				tmp.fontStyle = FontStyles.Bold;
			}
			tmp.text = text;
		}
	}

	private static string GetFullPath(Transform t)
	{
		string text = t.name;
		while (t.parent != null)
		{
			t = t.parent;
			text = t.name + "/" + text;
		}
		return text;
	}
}
