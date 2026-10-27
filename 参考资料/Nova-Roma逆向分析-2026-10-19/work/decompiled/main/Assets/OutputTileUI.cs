using UnityEngine;

namespace Assets;

public class OutputTileUI : MonoBehaviour
{
	[Header("Order matters! Keep same as enum")]
	public GameObject[] Tiles;

	public Transform IconLayout;

	private OnOffElement[] elements;

	private TooltipHook[] tooltips;

	private bool m_inUse;

	public bool inUse => m_inUse;

	private void Init()
	{
	}

	public void Reset()
	{
	}

	public void ShowCategory(int tileID, bool positive, string text)
	{
	}

	public void Show()
	{
	}
}
