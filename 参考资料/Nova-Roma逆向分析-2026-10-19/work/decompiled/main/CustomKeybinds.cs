using UnityEngine;

[CreateAssetMenu(fileName = "CustomKeybinds", menuName = "ScriptableObjects/CustomKeybinds")]
public class CustomKeybinds : ScriptableObject
{
	public ConfigurableControls.Keybind[] keybinds;
}
