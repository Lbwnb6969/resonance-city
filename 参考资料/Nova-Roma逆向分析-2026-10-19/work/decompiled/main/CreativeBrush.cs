using UnityEngine;
using UnityEngine.UI;

public class CreativeBrush : MonoBehaviour
{
	private string uniqueName;

	public int hash;

	public StaticTooltipHook hook;

	public Button button;

	public Image btnImage;

	public Image iconImage;

	public GameObject selectedOverlay;

	public CreativeUI.BrushUpdate UpdateBrush;

	public CreativeUI.InputType inputType;

	public string UniqueName
	{
		get
		{
			return uniqueName;
		}
		set
		{
			uniqueName = value;
			hash = uniqueName.GetHashCode();
		}
	}
}
