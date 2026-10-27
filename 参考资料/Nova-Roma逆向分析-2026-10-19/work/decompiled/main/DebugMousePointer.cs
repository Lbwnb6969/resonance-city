using UnityEngine;
using UnityEngine.UI;

public class DebugMousePointer : MonoBehaviour, IPointer
{
	public RectTransform cursor;

	[HideInInspector]
	public bool Locked;

	private Vector3 lastMouse;

	private bool[] buttonsDown = new bool[3];

	private bool[] buttonsUp = new bool[3];

	private void Start()
	{
		if (Application.isEditor)
		{
			PointingSystem.ReplacePointer(this);
		}
		else
		{
			enabled = false;
		}
	}

	public bool GetPrimaryDown()
	{
		if (Locked)
		{
			return buttonsDown[0];
		}
		bool mouseButtonDown;
		buttonsDown[0] = (mouseButtonDown = Input.GetMouseButtonDown(0));
		return mouseButtonDown;
	}

	public bool GetPrimaryDownThisFrame()
	{
		if (Locked)
		{
			return buttonsDown[0];
		}
		bool mouseButton;
		buttonsDown[0] = (mouseButton = Input.GetMouseButton(0));
		return mouseButton;
	}

	public bool GetPrimaryUp()
	{
		if (Locked)
		{
			return buttonsUp[0];
		}
		bool mouseButtonUp;
		buttonsUp[0] = (mouseButtonUp = Input.GetMouseButtonUp(0));
		return mouseButtonUp;
	}

	public bool GetSecondaryDown()
	{
		if (Locked)
		{
			return buttonsDown[1];
		}
		bool mouseButtonDown;
		buttonsDown[1] = (mouseButtonDown = Input.GetMouseButtonDown(1));
		return mouseButtonDown;
	}

	public bool GetSecondaryDownThisFrame()
	{
		if (Locked)
		{
			return buttonsDown[1];
		}
		bool mouseButton;
		buttonsDown[1] = (mouseButton = Input.GetMouseButton(1));
		return mouseButton;
	}

	public bool GetSecondaryUp()
	{
		if (Locked)
		{
			return buttonsUp[1];
		}
		bool mouseButtonUp;
		buttonsUp[1] = (mouseButtonUp = Input.GetMouseButtonUp(1));
		return mouseButtonUp;
	}

	public bool GetTertiaryDown()
	{
		if (Locked)
		{
			return buttonsDown[2];
		}
		bool mouseButtonDown;
		buttonsDown[2] = (mouseButtonDown = Input.GetMouseButtonDown(2));
		return mouseButtonDown;
	}

	public bool GetTertiaryUp()
	{
		if (Locked)
		{
			return buttonsUp[2];
		}
		bool mouseButtonUp;
		buttonsUp[2] = (mouseButtonUp = Input.GetMouseButtonUp(2));
		return mouseButtonUp;
	}

	public Ray GetRay()
	{
		return Cam.inst.cam.ScreenPointToRay(GetMousePos());
	}

	public Vector3 GetMousePos()
	{
		if (Locked)
		{
			return lastMouse;
		}
		return lastMouse = Input.mousePosition;
	}

	public Vector3 GetScreenPos(Vector3 p)
	{
		return Cam.inst.cam.WorldToScreenPoint(p);
	}

	private void Update()
	{
		if (Input.GetKeyDown(KeyCode.F10))
		{
			Locked = !Locked;
			if (Locked)
			{
				Canvas component = cursor.parent.GetComponent<Canvas>();
				RectTransformUtility.ScreenPointToLocalPointInRectangle(component.transform as RectTransform, GetMousePos(), component.worldCamera, out var localPoint);
				cursor.transform.position = component.transform.TransformPoint(localPoint);
			}
			cursor.GetComponent<Image>().enabled = Locked;
		}
	}
}
