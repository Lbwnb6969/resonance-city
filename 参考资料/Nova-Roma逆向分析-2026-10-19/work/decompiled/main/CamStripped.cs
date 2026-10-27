using System;
using Assets;
using Colorful;
using UnityEngine;
using UnityStandardAssets.ImageEffects;

public class CamStripped : MonoBehaviour
{
	[Serializable]
	public class CamSaveData : SaveClass<CamStripped, CamSaveData>
	{
		private float Phi;

		private float Theta;

		private float Dist;

		private SerializableVector3 TrackingPos;

		public override CamSaveData Pack(CamStripped c)
		{
			Phi = c.Phi;
			Theta = c.Theta;
			Dist = c.Dist;
			TrackingPos = c.TrackingPos;
			return this;
		}

		public override CamStripped Unpack(CamStripped c)
		{
			c.DesiredPhi = (c.Phi = Phi);
			c.DesiredTheta = (c.Theta = Theta);
			c.DesiredDist = (c.Dist = Dist);
			c.DesiredTrackingPos = (c.TrackingPos = TrackingPos);
			return c;
		}
	}

	public static CamStripped inst;

	public Camera cam;

	public SSAOPro ssao;

	public Bloom bloom;

	public Antialiasing antialiasing;

	public ColorCorrectionCurves colorCorrection;

	public Levels levels;

	public GlobalFog globalFog;

	private float Dist = 10f;

	public MinMax zoomRangeMapEdit = new MinMax(1f, 180f);

	public MinMax zoomRange = new MinMax(1f, 75f);

	private float DesiredDist = 10f;

	private float DistVel;

	private float Theta;

	private float DesiredTheta = 10f;

	private float ThetaVel;

	private float Phi = 20f;

	private float DesiredPhi = 45f;

	private float PhiVel;

	public Vector3 TrackingPos;

	[NonSerialized]
	public Vector3 DesiredTrackingPos = new Vector3(12.5f, 0f, 12.5f);

	private float TrackingVelX;

	private float TrackingVelY;

	private float TrackingVelZ;

	[NonSerialized]
	public Vector3 LastTrackingPos;

	public float ThetaSpeed = 0.5f;

	public float PhiSpeed = 0.5f;

	public Material lineMaterial;

	private bool hasFocus = true;

	private Vector3 LastMousePos;

	private Vector3 startDragPosition;

	private Vector3 startMousePosition;

	public float DragThresholdInches = 0.5f;

	private int pixelDragThreshold;

	private bool dragging;

	private bool achieveThreshold;

	private float cameraSpeed;

	private float distVel;

	public float zoomDrag = 10f;

	public float zoomAccel = 250f;

	private float timeStill;

	public AnimationCurve HoverSpeedToDist;

	[NonSerialized]
	public bool mapEditCameraParamsOn;

	[NonSerialized]
	public bool disableDrag;

	public AnimationCurve DistToPhiOffset;

	public float posSmoothDampTime = 1f;

	[NonSerialized]
	public Vector3 CamPos;

	private Vector3 ShakeOffsetVel;

	private Vector3 ShakeOffset;

	public float K = 10f;

	public float Drag = 1f;

	[NonSerialized]
	public ICamTrackable OverrideTrack;

	public float dist
	{
		get
		{
			return Dist;
		}
		set
		{
			Dist = zoomRange.Clamp(value);
		}
	}

	public float desiredDist
	{
		get
		{
			return DesiredDist;
		}
		set
		{
			if (mapEditCameraParamsOn)
			{
				DesiredDist = zoomRangeMapEdit.Clamp(value);
			}
			else
			{
				DesiredDist = zoomRange.Clamp(value);
			}
		}
	}

	public float desiredTheta
	{
		get
		{
			return DesiredTheta;
		}
		set
		{
			DesiredTheta = value;
		}
	}

	public float desiredPhi
	{
		get
		{
			return DesiredPhi;
		}
		set
		{
			DesiredPhi = value;
		}
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		cam = GetComponent<Camera>();
		pixelDragThreshold = (int)(DragThresholdInches * ((Screen.dpi != 0f) ? Screen.dpi : 72f));
		if (World.inst != null)
		{
			DesiredTrackingPos = new Vector3((float)World.inst.GridWidth / 2f, 0f, (float)World.inst.GridHeight / 2f);
		}
		Dist = DesiredDist;
		Theta = DesiredTheta;
		Phi = DesiredPhi;
		TrackingPos = DesiredTrackingPos;
		cam.nearClipPlane = 0.1f;
	}

	public void SetDist(float distance)
	{
		float num = (dist = distance);
		desiredDist = num;
	}

	public void SetPhi(float phi)
	{
		DesiredPhi = (Phi = phi);
	}

	public void SetTrackingPos(Vector3 p)
	{
		SetDesiredTrackingPos(p);
		TrackingPos = p;
	}

	public void CancelDrag()
	{
		dragging = false;
	}

	public bool IsDragging()
	{
		if (dragging)
		{
			return achieveThreshold;
		}
		return false;
	}

	public void Rotate(float deltaTheta, float deltaPhi)
	{
		DesiredTheta += deltaTheta;
		DesiredPhi += deltaPhi;
	}

	public void MoveRight(float amount)
	{
		Vector3 vector = transform.rotation * Vector3.right;
		vector.y = 0f;
		vector.Normalize();
		SetDesiredTrackingPos(DesiredTrackingPos + vector * amount);
	}

	public void MoveForward(float amount)
	{
		Vector3 vector = transform.rotation * Vector3.forward;
		vector.y = 0f;
		vector.Normalize();
		SetDesiredTrackingPos(DesiredTrackingPos + vector * amount);
	}

	public void Zoom(float amount)
	{
		desiredDist += amount;
	}

	private Vector3 ProjecToGround(Vector3 MousePos)
	{
		Ray ray = cam.ScreenPointToRay(MousePos);
		new Plane(new Vector3(0f, 1f, 0f), new Vector3(0f, 0f, 0f)).Raycast(ray, out var enter);
		return ray.GetPoint(enter);
	}

	private void UpdateMouseZoom(float dt)
	{
		if (GamepadControl.inst != null && GamepadControl.inst.isControllerActive)
		{
			return;
		}
		bool flag = true;
		if ((bool)GameState.inst && (bool)GameUI.inst)
		{
			flag = !GameState.inst.mainMenuMode.saveLoadUI.isActiveAndEnabled && !GameUI.inst.PointerOverUI();
		}
		if (flag)
		{
			int num = -1;
			if (Settings.inst != null)
			{
				num = ((!Settings.inst.InvertZoom) ? 1 : (-1));
			}
			float t = Mathf.InverseLerp(zoomRange.Min, zoomRange.Max, desiredDist);
			float num2 = Mathf.Lerp(0.33f, 1.5f, t);
			distVel += Input.GetAxis("Mouse ScrollWheel") * zoomAccel * (float)num * num2;
		}
		distVel += (0f - distVel) * zoomDrag * dt;
		desiredDist += distVel * dt;
	}

	private void UpdateMouseRotate(Vector3 MouseDelta)
	{
		bool flag = Input.GetMouseButton(2) && !Input.GetMouseButton(0);
		if (Input.GetMouseButton(1) && GameUI.AltHeld())
		{
			flag = true;
		}
		if (flag)
		{
			DesiredTheta += MouseDelta.x * ThetaSpeed;
			DesiredPhi += (0f - MouseDelta.y) * PhiSpeed;
		}
	}

	public void SetDesiredTrackingPos(Vector3 p)
	{
		DesiredTrackingPos = p;
		ClearTrack();
	}

	private void UpdateMouseHoverPan(float dt)
	{
		bool flag = false;
		if ((bool)Settings.inst)
		{
			flag = Settings.inst.EdgeScroll;
		}
		if (dragging || !hasFocus || !flag || GameUI.IsOnConsole())
		{
			return;
		}
		Vector3 mousePosition = Input.mousePosition;
		if ((LastMousePos - mousePosition).magnitude > 1f)
		{
			timeStill = 0f;
		}
		else
		{
			timeStill += dt;
		}
		float num = 1f;
		if (!(mousePosition.x < 0f) && !(mousePosition.y < 0f) && !(mousePosition.x > (float)Screen.width) && !(mousePosition.y > (float)Screen.height) && !(timeStill < 0.05f))
		{
			Vector3 vector = transform.rotation * Vector3.forward;
			vector.y = 0f;
			vector.Normalize();
			Vector3 vector2 = transform.rotation * Vector3.right;
			vector2.y = 0f;
			vector2.Normalize();
			float num2 = HoverSpeedToDist.Evaluate(Dist) * dt;
			Vector3 zero = Vector3.zero;
			bool flag2 = false;
			if (mousePosition.y >= (float)Screen.height - num)
			{
				zero += vector;
				flag2 = true;
			}
			if (mousePosition.y <= num)
			{
				zero -= vector;
				flag2 = true;
			}
			if (mousePosition.x >= (float)Screen.width - num)
			{
				zero += vector2;
				flag2 = true;
			}
			if (mousePosition.x <= num)
			{
				zero -= vector2;
				flag2 = true;
			}
			if (flag2)
			{
				zero.Normalize();
				SetDesiredTrackingPos(TrackingPos + zero * num2);
			}
		}
	}

	private void OnApplicationFocus(bool hasFocus)
	{
		this.hasFocus = hasFocus;
	}

	public void TryStartDrag(Vector3 mousePos)
	{
		if (!disableDrag && !dragging)
		{
			startMousePosition = mousePos;
			dragging = true;
			achieveThreshold = false;
		}
	}

	private void Update()
	{
		if (Settings.inst != null)
		{
			bloom.enabled = Settings.inst.PostEffects;
			antialiasing.enabled = Settings.inst.AntiAliasing;
			levels.enabled = Settings.inst.PostEffects;
		}
		if (Application.isEditor)
		{
			zoomRange.Max = 120f;
		}
		if (GameUI.inst == null)
		{
			if (GameUI.AltHeld())
			{
				if (PointingSystem.GetPointer().GetPrimaryDown())
				{
					TryStartDrag(Input.mousePosition);
				}
			}
			else if (PointingSystem.GetPointer().GetSecondaryDown())
			{
				TryStartDrag(Input.mousePosition);
			}
		}
		float num = Mathf.Clamp(Time.unscaledDeltaTime, 1E-05f, 0.03f);
		Vector3 mousePosition = Input.mousePosition;
		Vector2 vector = mousePosition - LastMousePos;
		UpdateMouseHoverPan(num);
		UpdateMouseZoom(num);
		UpdateMouseRotate(vector);
		if ((GameUI.inst != null && !GameUI.inst.WasEventConsumed()) || dragging)
		{
			bool flag = false;
			if (Input.GetMouseButton(0) && GameUI.AltHeld())
			{
				flag = true;
			}
			if (Input.GetMouseButton(1) && !GameUI.AltHeld())
			{
				flag = true;
			}
			Vector3 vector2 = ProjecToGround(mousePosition);
			if (dragging & flag)
			{
				if ((startMousePosition - mousePosition).magnitude > (float)pixelDragThreshold && !achieveThreshold)
				{
					ClearTrack();
					achieveThreshold = true;
					startDragPosition = vector2;
				}
				if (achieveThreshold)
				{
					DesiredTrackingPos -= vector2 - startDragPosition;
				}
			}
			else
			{
				dragging = false;
			}
		}
		LastMousePos = mousePosition;
		if (dragging)
		{
			if (World.inst != null)
			{
				TrackingPos = ClampToWorldBounds(DesiredTrackingPos);
			}
			else
			{
				TrackingPos = DesiredTrackingPos;
			}
		}
		else
		{
			if (OverrideTrack != null && !OverrideTrack.Equals(null))
			{
				DesiredTrackingPos = OverrideTrack.GetDesiredTrackingPos();
			}
			float y = 0f;
			if (World.inst != null)
			{
				DesiredTrackingPos = ClampToWorldBounds(DesiredTrackingPos);
				y = TerrainGen.inst.GetGroundHeight(DesiredTrackingPos.x, DesiredTrackingPos.z);
			}
			DesiredTrackingPos.y = y;
			TrackingPos.x = Mathf.SmoothDamp(TrackingPos.x, DesiredTrackingPos.x, ref TrackingVelX, posSmoothDampTime, float.MaxValue, num);
			TrackingPos.y = Mathf.SmoothDamp(TrackingPos.y, DesiredTrackingPos.y, ref TrackingVelY, posSmoothDampTime, float.MaxValue, num);
			TrackingPos.z = Mathf.SmoothDamp(TrackingPos.z, DesiredTrackingPos.z, ref TrackingVelZ, posSmoothDampTime, float.MaxValue, num);
		}
		Theta = Mathf.SmoothDamp(Theta, DesiredTheta, ref ThetaVel, 0.05f, float.MaxValue, num);
		Phi = Mathf.SmoothDamp(Phi, DesiredPhi, ref PhiVel, 0.05f, float.MaxValue, num);
		Dist = Mathf.SmoothDamp(Dist, DesiredDist, ref DistVel, 0.1f, float.MaxValue, num);
		float enter = Dist;
		bool flag2 = false;
		if (GamepadControl.inst != null)
		{
			flag2 = GamepadControl.inst.isControllerActive;
		}
		if (flag2)
		{
			Plane plane = new Plane(Vector3.up, 0f);
			Ray ray = new Ray(CamPos, TrackingPos - CamPos);
			plane.Raycast(ray, out enter);
		}
		float num2 = DistToPhiOffset.Evaluate(enter);
		if (flag2)
		{
			num2 *= 0.75f;
		}
		float angle = Mathf.Clamp(Phi + num2, 10f, 65f - num2);
		DesiredPhi = Mathf.Clamp(DesiredPhi, 5f, 65f - num2);
		Vector3 vector3 = Quaternion.AngleAxis(angle, new Vector3(0f, 0f, 1f)) * new Vector3(1f, 0f, 0f);
		vector3 = Quaternion.AngleAxis(Theta, new Vector3(0f, 1f, 0f)) * vector3;
		vector3.Normalize();
		CamPos = TrackingPos + Dist * vector3;
		ShakeOffsetVel += (0f - K) * ShakeOffset * num;
		ShakeOffsetVel += Drag * -ShakeOffsetVel * num;
		ShakeOffset += ShakeOffsetVel * num;
		LastTrackingPos.x = transform.position.x;
		LastTrackingPos.y = transform.position.y;
		LastTrackingPos.z = transform.position.z;
		transform.position = CamPos + transform.rotation * ShakeOffset;
		cameraSpeed = (transform.position - LastTrackingPos).magnitude;
		Vector3 forward = TrackingPos - CamPos;
		forward.Normalize();
		Quaternion rotation = Quaternion.LookRotation(forward);
		transform.rotation = rotation;
	}

	private Vector3 ClampToWorldBounds(Vector3 p)
	{
		float num = 5f;
		float min = 0f - num;
		float min2 = 0f - num;
		float max = (float)World.inst.GridWidth + num;
		float max2 = (float)World.inst.GridHeight + num;
		p.x = Mathf.Clamp(p.x, min, max);
		p.z = Mathf.Clamp(p.z, min2, max2);
		return p;
	}

	public Vector3 GetDirection()
	{
		return (TrackingPos - transform.position).normalized;
	}

	public void Shake(Vector3 Vel)
	{
		ShakeOffsetVel += Vel;
	}

	public void Track(ICamTrackable track)
	{
		OverrideTrack = track;
	}

	public void ClearTrack()
	{
		OverrideTrack = null;
	}

	public bool IsTracking(ICamTrackable obj)
	{
		return OverrideTrack == obj;
	}

	public float CameraSpeed()
	{
		return cameraSpeed;
	}

	public void BringIntoView(Vector3 origin, ArrayExt<Vector3> points)
	{
		float num = 1f;
		Vector3 vector = origin;
		for (int i = 0; i < points.Count; i++)
		{
			vector += points.data[i].xz();
			num++;
		}
		if (!(num > 0f))
		{
			return;
		}
		vector /= num;
		float num2 = 0f;
		Vector3 position = inst.transform.position;
		Plane plane = new Plane(inst.GetDirection(), inst.TrackingPos);
		for (int j = 0; j < points.Count; j++)
		{
			Ray ray = new Ray(position, (points.data[j] - position).normalized);
			plane.Raycast(ray, out var enter);
			float num3 = (ray.GetPoint(enter) - vector).magnitude + 2f;
			if (num3 > num2)
			{
				num2 = num3;
			}
		}
		Ray ray2 = new Ray(position, (origin - position).normalized);
		plane.Raycast(ray2, out var enter2);
		float num4 = (ray2.GetPoint(enter2) - vector).magnitude + 2f;
		if (num4 > num2)
		{
			num2 = num4;
		}
		Camera component = inst.GetComponent<Camera>();
		float f = MathF.PI / 180f * component.fieldOfView;
		float b = num2 / Mathf.Atan(f);
		inst.desiredDist = Mathf.Max(10f, b);
		inst.DesiredTrackingPos = vector.xz();
	}
}
