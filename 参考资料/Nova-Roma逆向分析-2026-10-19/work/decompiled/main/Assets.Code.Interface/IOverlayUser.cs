using UnityEngine;

namespace Assets.Code.Interface;

internal interface IOverlayUser
{
	bool OverlayWhenPlacing { get; }

	bool OverlayWhenSelected { get; }

	void DrawOverlay(Vector3 origin);
}
