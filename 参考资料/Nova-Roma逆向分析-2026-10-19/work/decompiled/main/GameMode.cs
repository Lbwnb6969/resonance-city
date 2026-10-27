using UnityEngine;

public class GameMode : MonoBehaviour
{
	private void Start()
	{
	}

	public virtual void Init()
	{
	}

	public virtual void UpdateManual(float dt)
	{
		if (GameUI.inst.PointerOverUI())
		{
			return;
		}
		if (GameUI.AltHeld())
		{
			if (PointingSystem.GetPointer().GetPrimaryDown())
			{
				Cam.inst.TryStartDrag(Input.mousePosition);
			}
		}
		else if (PointingSystem.GetPointer().GetSecondaryDown())
		{
			Cam.inst.TryStartDrag(Input.mousePosition);
		}
	}

	public virtual void Shutdown()
	{
	}
}
