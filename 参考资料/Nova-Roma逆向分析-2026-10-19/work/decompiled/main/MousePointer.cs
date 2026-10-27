using UnityEngine;

internal class MousePointer : IPointer
{
	public bool GetPrimaryDown()
	{
		return Input.GetMouseButtonDown(0);
	}

	public bool GetPrimaryDownThisFrame()
	{
		return Input.GetMouseButton(0);
	}

	public bool GetPrimaryUp()
	{
		return Input.GetMouseButtonUp(0);
	}

	public bool GetSecondaryDown()
	{
		return Input.GetMouseButtonDown(1);
	}

	public bool GetSecondaryDownThisFrame()
	{
		return Input.GetMouseButton(1);
	}

	public bool GetSecondaryUp()
	{
		return Input.GetMouseButtonUp(1);
	}

	public bool GetTertiaryDown()
	{
		return Input.GetMouseButtonDown(2);
	}

	public bool GetTertiaryUp()
	{
		return Input.GetMouseButtonUp(2);
	}

	public Ray GetRay()
	{
		return Cam.inst.cam.ScreenPointToRay(GetMousePos());
	}

	public Vector3 GetScreenPos(Vector3 worldPos)
	{
		return Cam.inst.cam.WorldToScreenPoint(worldPos);
	}

	public Vector3 GetMousePos()
	{
		return Input.mousePosition;
	}
}
