using UnityEngine;

public class DebugCam : MonoBehaviour
{
	private enum Mode
	{
		FreeLook,
		Playback
	}

	private enum InterpMode
	{
		Linear,
		SmoothStep,
		Square,
		Sqrt,
		NumModes
	}

	public static DebugCam inst;

	private float theta;

	private float phi;

	private Mode mode;

	private InterpMode interpMode;

	private bool recording;

	private Vector3 startRecLoc;

	private Vector3 endRecLoc;

	private Quaternion startRecRot;

	private Quaternion endRecRot;

	private float playbackSpeed = 1f;

	private float playbackTime;

	private CameraState[] saveStates = new CameraState[10];

	private Vector3 mouseStartScreen;

	private float WaitTime = 1f;

	private void Start()
	{
		inst = this;
		enabled = false;
		for (int i = 0; i < saveStates.Length; i++)
		{
			saveStates[i] = new CameraState();
		}
	}

	private void OnEnable()
	{
		Vector3 eulerAngles = transform.rotation.eulerAngles;
		theta = eulerAngles.y;
		phi = eulerAngles.x;
	}

	private void Update()
	{
		Vector3 forward = transform.forward;
		Vector3 right = transform.right;
		Vector3 position = transform.position;
		switch (mode)
		{
		case Mode.FreeLook:
		{
			if (Input.GetMouseButtonDown(1))
			{
				mouseStartScreen = Input.mousePosition;
			}
			float unscaledDeltaTime = Time.unscaledDeltaTime;
			float num2 = 2f * unscaledDeltaTime;
			if (Input.GetKey(KeyCode.LeftShift))
			{
				num2 *= 10f;
			}
			if (Input.GetMouseButton(1))
			{
				Vector3 vector = Input.mousePosition - mouseStartScreen;
				theta += vector.x * unscaledDeltaTime * 7f;
				phi -= vector.y * unscaledDeltaTime * 7f;
				transform.rotation = Quaternion.Euler(phi, theta, 0f);
				mouseStartScreen = Input.mousePosition;
			}
			for (int i = 0; i < saveStates.Length; i++)
			{
				if (Input.GetKeyDown(i.ToString()))
				{
					if (Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl))
					{
						saveStates[i].Position = transform.position;
						saveStates[i].Theta = theta;
						saveStates[i].Phi = phi;
					}
					else if (saveStates[i].Position != Vector3.zero)
					{
						position = saveStates[i].Position;
						theta = saveStates[i].Theta;
						phi = saveStates[i].Phi;
						transform.rotation = Quaternion.Euler(phi, theta, 0f);
					}
				}
			}
			if (Input.GetKey(KeyCode.LeftControl))
			{
				Vector3 vector2 = forward;
				vector2.y = 0f;
				vector2.Normalize();
				Vector3 vector3 = Vector3.Cross(vector2, new Vector3(0f, 1f, 0f));
				if (Input.GetKey(KeyCode.W))
				{
					position += vector2 * num2;
				}
				if (Input.GetKey(KeyCode.S))
				{
					position -= vector2 * num2;
				}
				if (Input.GetKey(KeyCode.A))
				{
					position += vector3 * num2;
				}
				if (Input.GetKey(KeyCode.D))
				{
					position -= vector3 * num2;
				}
			}
			else
			{
				if (Input.GetKey(KeyCode.W))
				{
					position += forward * num2;
				}
				if (Input.GetKey(KeyCode.S))
				{
					position -= forward * num2;
				}
				if (Input.GetKey(KeyCode.A))
				{
					position -= right * num2;
				}
				if (Input.GetKey(KeyCode.D))
				{
					position += right * num2;
				}
			}
			transform.position = position;
			if (Input.GetKeyDown(KeyCode.R))
			{
				if (!recording)
				{
					recording = true;
					startRecLoc = transform.position;
					startRecRot = transform.rotation;
				}
				else
				{
					recording = false;
					endRecLoc = transform.position;
					endRecRot = transform.rotation;
					mode = Mode.Playback;
				}
			}
			break;
		}
		case Mode.Playback:
		{
			playbackTime += Time.unscaledDeltaTime * playbackSpeed;
			if (playbackTime > 1f + WaitTime * playbackSpeed)
			{
				playbackTime = 0f;
			}
			if (Input.GetKeyDown(KeyCode.KeypadPlus) || Input.GetKeyDown(KeyCode.Equals))
			{
				playbackSpeed += 0.02f;
			}
			if (Input.GetKeyDown(KeyCode.KeypadMinus) || Input.GetKeyDown(KeyCode.Minus))
			{
				playbackSpeed -= 0.02f;
			}
			float num = Mathf.Clamp01(playbackTime);
			if (interpMode == InterpMode.SmoothStep)
			{
				num = Mathf.SmoothStep(0f, 1f, num);
			}
			if (interpMode == InterpMode.Square)
			{
				num *= num;
			}
			if (interpMode == InterpMode.Sqrt)
			{
				num = Mathf.Sqrt(num);
			}
			transform.position = Vector3.Lerp(startRecLoc, endRecLoc, num);
			transform.rotation = Quaternion.Slerp(startRecRot, endRecRot, num);
			if (Input.GetKeyDown(KeyCode.R))
			{
				mode = Mode.FreeLook;
			}
			if (Input.GetKeyDown(KeyCode.I))
			{
				interpMode++;
				if (interpMode == InterpMode.NumModes)
				{
					interpMode = InterpMode.Linear;
				}
			}
			break;
		}
		}
	}
}
