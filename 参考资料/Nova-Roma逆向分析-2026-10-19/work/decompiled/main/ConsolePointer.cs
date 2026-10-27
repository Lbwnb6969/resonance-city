using UnityEngine;

internal class ConsolePointer : IPointer
{
	public bool GetPrimaryDown()
	{
		return GamepadControl.inst.player.GetButtonDown("A");
	}

	public bool GetPrimaryDownThisFrame()
	{
		return GamepadControl.inst.player.GetButton("A");
	}

	public bool GetPrimaryUp()
	{
		return GamepadControl.inst.player.GetButtonUp("A");
	}

	public bool GetSecondaryDown()
	{
		return false;
	}

	public bool GetSecondaryDownThisFrame()
	{
		return false;
	}

	public bool GetSecondaryUp()
	{
		return false;
	}

	public bool GetTertiaryDown()
	{
		return false;
	}

	public bool GetTertiaryUp()
	{
		return false;
	}

	public Ray GetRay()
	{
		return new Ray
		{
			origin = Cam.inst.CamPos,
			direction = Cam.inst.GetDirection()
		};
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
