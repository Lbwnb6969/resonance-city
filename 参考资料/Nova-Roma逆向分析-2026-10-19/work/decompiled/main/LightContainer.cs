using Assets;
using UnityEngine;

public class LightContainer : MonoBehaviour
{
	public Light sun;

	public Light moon;

	private void Update()
	{
		sun.shadows = (Settings.inst.Shadows ? LightShadows.Hard : LightShadows.None);
		moon.shadows = LightShadows.None;
	}
}
