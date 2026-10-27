using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(CanvasRenderer))]
public class NonGraphicRaycastTarget : Graphic
{
	public override void SetMaterialDirty()
	{
	}

	public override void SetVerticesDirty()
	{
	}
}
