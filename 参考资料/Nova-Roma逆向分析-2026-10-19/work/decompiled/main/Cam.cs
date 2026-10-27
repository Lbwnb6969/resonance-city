using System;
using Assets;
using Colorful;
using UnityEngine;
using UnityStandardAssets.ImageEffects;

public class Cam : MonoBehaviour
{
	public class TransformCapture
	{
		public Vector3 trackingPos;

		public float phi;

		public float theta;

		public float dist;
	}

	[Serializable]
	public class CamSaveData : SaveClass<Cam, CamSaveData>
	{
		private float Phi;

		private float Theta;

		private float Dist;

		private SerializableVector3 TrackingPos;

		public override CamSaveData Pack(Cam c)
		{
			Phi = c.Phi;
			Theta = c.Theta;
			Dist = c.Dist;
			TrackingPos = c.TrackingPos;
			return this;
		}

		public override Cam Unpack(Cam c)
		{
			c.DesiredPhi = (c.Phi = Phi);
			c.DesiredTheta = (c.Theta = Theta);
			c.DesiredDist = (c.Dist = Dist);
			c.DesiredTrackingPos = (c.TrackingPos = TrackingPos);
			return c;
		}
	}

	public static Cam inst;

	public Camera cam;

	public Transform microphoneT;

	public float phiMicrophoneMin;

	public float phiMicrophoneMax = 35f;

	public AnimationCurve phiMicrophoneCurve;

	public float distMicrophoneMin;

	public float distMicrophoneMax = 35f;

	public AnimationCurve distMicrophoneCurve;

	public SSAOPro ssao;

	public Bloom bloom;

	public Antialiasing antialiasing;

	public ColorCorrectionCurves colorCorrection;

	public Levels levels;

	public GlobalFog globalFog;

	private float Dist = 10f;

	public MinMax zoomRangeMapEdit = new MinMax(1f, 180f);

	public MinMax zoomRangeNewMap = new MinMax(1f, 300f);

	public MinMax zoomRange = new MinMax(1f, 75f);

	public MinMax zoomRangeColosseumGames = new MinMax(0f, 1000f);

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

	public bool hasZoomedIn;

	public bool hasZoomedOut;

	private Plane dragPlane = new Plane(Vector3.up, Vector3.zero);

	private float distVel;

	public float zoomDrag = 10f;

	public float zoomAccel = 250f;

	private float edgeBuffer = 1f;

	private float edgeTimeToActivate;

	private bool isEdgeScrolling;

	private float timeStill;

	public AnimationCurve HoverSpeedToDist;

	public float minEdgeScrollingSpeed = 0.1f;

	public float maxEdgeScrollingSpeed = 1.25f;

	[NonSerialized]
	public bool mapEditCameraParamsOn;

	[NonSerialized]
	public bool isNewMap;

	[NonSerialized]
	public bool isGenerateZoomedOut;

	[NonSerialized]
	public bool disableDrag;

	[NonSerialized]
	public bool disableZoom;

	[NonSerialized]
	public bool disableRotate;

	[NonSerialized]
	public bool isNotHoveringApplication;

	public AnimationCurve DistToPhiOffset;

	public float posSmoothDampTimeDefault = 0.1f;

	public float posSmoothDampTime = 0.2f;

	public float distSmoothDampTime = 0.1f;

	public float phiSmoothDampTime = 0.05f;

	public float thetaSmoothDampTime = 0.05f;

	public float phiAdjustCancelRange = 20f;

	private bool setTrackThisFrame;

	private Vector3 startDesiredTrackingPos;

	public Camera startDragCam;

	private RaycastHit[] scratchHitResults = new RaycastHit[32];

	[NonSerialized]
	public Vector3 CamPos;

	public float heightClipBuffer = 2f;

	public float MaxShakeMagnitude = 20f;

	public Vector3 ShakeOffsetVel;

	public Vector3 ShakeOffset;

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
			if (isNewMap && isGenerateZoomedOut)
			{
				DesiredDist = zoomRangeNewMap.Clamp(value);
			}
			else if (mapEditCameraParamsOn || isNewMap)
			{
				DesiredDist = zoomRangeMapEdit.Clamp(value);
			}
			else if (GameUI.inst.currCursorMode is ColosseumCursorMode)
			{
				DesiredDist = zoomRangeColosseumGames.Clamp(value);
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

	public Vector3 DesiredCamPos => CalcCamPos(DesiredTrackingPos, DesiredTheta, DesiredPhi, DesiredDist);

	public TransformCapture CaptureCameraTransform()
	{
		return new TransformCapture
		{
			phi = Phi,
			theta = Theta,
			dist = Dist,
			trackingPos = TrackingPos
		};
	}

	public void ApplyTransformCapture(TransformCapture capture)
	{
		if (capture != null)
		{
			DesiredPhi = capture.phi;
			DesiredTheta = capture.theta;
			DesiredDist = capture.dist;
			DesiredTrackingPos = capture.trackingPos;
		}
	}

	private void Awake()
	{
		inst = this;
	}

	public int GetPixelCamDragThreshold()
	{
		return pixelDragThreshold;
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
		cam.nearClipPlane = 1f;
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

	public void SetTheta(float t)
	{
		DesiredTheta = (Theta = t);
	}

	public void SetTrackingPos(Vector3 p)
	{
		setTrackThisFrame = true;
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
		Vector3 desiredTrackingPos = DesiredTrackingPos + vector * amount;
		desiredTrackingPos.y = Mathf.Max(0f, TerrainGen.inst.GetGroundHeight(desiredTrackingPos.x, desiredTrackingPos.z));
		SetDesiredTrackingPos(desiredTrackingPos);
	}

	public void MoveForward(float amount)
	{
		Vector3 vector = transform.rotation * Vector3.forward;
		vector.y = 0f;
		vector.Normalize();
		Vector3 desiredTrackingPos = DesiredTrackingPos + vector * amount;
		desiredTrackingPos.y = Mathf.Max(0f, TerrainGen.inst.GetGroundHeight(desiredTrackingPos.x, desiredTrackingPos.z));
		SetDesiredTrackingPos(desiredTrackingPos);
	}

	public void Zoom(float amount)
	{
		hasZoomedOut |= amount > 0.01f;
		hasZoomedIn |= amount < -0.01f;
		desiredDist += amount;
	}

	private Vector3 ProjecToGround(Vector3 MousePos)
	{
		if (!achieveThreshold)
		{
			startDragCam.transform.SetPositionAndRotation(cam.transform.position, cam.transform.rotation);
			startDragCam.CopyFrom(cam);
			if (Phi < 10f && Phi > -10f)
			{
				Vector3 inNormal = Vector3.Lerp(Vector3.up, -startDragCam.transform.forward, 0.25f);
				inNormal.Normalize();
				dragPlane.SetNormalAndPosition(inNormal, startDragCam.transform.position + startDragCam.transform.forward.xz().normalized * 50f);
			}
			else
			{
				dragPlane.SetNormalAndPosition(Vector3.up, Vector3.zero);
			}
		}
		Ray ray = startDragCam.ScreenPointToRay(MousePos);
		dragPlane.Raycast(ray, out var enter);
		return ray.GetPoint(enter);
	}

	private void UpdateMouseZoom(float dt)
	{
		if (!GamepadControl.inst.isControllerActive && !disableZoom && !isNotHoveringApplication && hasFocus && !GameUI.inst.PointerOverUI())
		{
			float t = Mathf.InverseLerp(zoomRange.Min, zoomRange.Max, desiredDist);
			float num = Mathf.Lerp(0.33f, 1.5f, t);
			float num2 = (Settings.inst.ZoomSpeed - 0.5f) * 125f;
			distVel += Input.GetAxis("Mouse ScrollWheel") * (zoomAccel + num2) * (float)((!Settings.inst.InvertZoom) ? 1 : (-1)) * num;
			distVel += (0f - distVel) * zoomDrag * dt;
			Zoom(distVel * dt);
		}
	}

	private void UpdateMouseRotate(Vector3 MouseDelta)
	{
		if (!disableRotate)
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
	}

	public void SetDesiredTrackingPos(Vector3 p)
	{
		DesiredTrackingPos = p;
		ClearTrack();
	}

	public bool IsEdgeScrolling()
	{
		return isEdgeScrolling;
	}

	private void UpdateMouseHoverPan(float dt)
	{
		if (dragging || !hasFocus || !Settings.inst.EdgeScroll || GameUI.IsOnConsole() || Cinematics.inst.IsCinematicRunning() || GodUI.inst.gameObject.activeSelf || TechnologyTree.inst.IsVisible())
		{
			return;
		}
		Vector2 vector = Input.mousePosition;
		Vector2 vector2 = default;
		bool flag = true;
		if (vector.x <= edgeBuffer)
		{
			vector2.x = -1f;
		}
		else if (vector.x >= (float)Screen.width - edgeBuffer)
		{
			vector2.x = 1f;
		}
		else
		{
			flag = false;
		}
		bool flag2 = true;
		if (vector.y <= edgeBuffer)
		{
			vector2.y = -1f;
		}
		else if (vector.y >= (float)Screen.height - edgeBuffer)
		{
			vector2.y = 1f;
		}
		else
		{
			flag2 = false;
		}
		if (flag | flag2)
		{
			edgeTimeToActivate += Time.unscaledDeltaTime;
			if (edgeTimeToActivate >= 0.05f)
			{
				isEdgeScrolling = true;
				Vector3 input = transform.rotation * Vector3.forward;
				input.y = 0f;
				input.NonAllocateNormalize();
				Vector3 input2 = transform.rotation * Vector3.right;
				input2.y = 0f;
				input2.NonAllocateNormalize();
				Vector3 input3 = default;
				input3.NonAllocateAdd(input2 * vector2.x);
				input3.NonAllocateAdd(input * vector2.y);
				input3.NonAllocateNormalize();
				float num = HoverSpeedToDist.Evaluate(Dist) * (dt * Mathff.Lerp(minEdgeScrollingSpeed, maxEdgeScrollingSpeed, Settings.inst.MaxPanningSpeed));
				Vector3 desiredTrackingPos = TrackingPos + input3 * num;
				desiredTrackingPos.y = Mathf.Max(0f, TerrainGen.inst.GetGroundHeight(desiredTrackingPos.x, desiredTrackingPos.z));
				SetDesiredTrackingPos(desiredTrackingPos);
			}
		}
		else
		{
			isEdgeScrolling = false;
			edgeTimeToActivate = 0f;
		}
	}

	private void OnApplicationFocus(bool hasFocus)
	{
		this.hasFocus = hasFocus;
	}

	public void TryStartDrag(Vector3 mousePos)
	{
		if (!Cinematics.inst.IsCinematicRunning() && !GodUI.inst.gameObject.activeSelf && !disableDrag && !dragging)
		{
			startMousePosition = mousePos;
			dragging = true;
			achieveThreshold = false;
		}
	}

	private void Update()
	{
		hasZoomedIn = false;
		hasZoomedOut = false;
		ssao.enabled = Settings.inst.SSAO;
		bloom.enabled = Settings.inst.PostEffects;
		antialiasing.enabled = Settings.inst.AntiAliasing;
		levels.enabled = Settings.inst.PostEffects;
		float num = Mathf.Clamp(Time.unscaledDeltaTime, 1E-05f, 0.03f);
		Vector3 mousePosition = Input.mousePosition;
		Vector2 vector = mousePosition - LastMousePos;
		UpdateMouseHoverPan(num);
		UpdateMouseZoom(num);
		UpdateMouseRotate(vector);
		if (((bool)GameUI.inst && !GameUI.inst.WasEventConsumed()) || dragging)
		{
			bool flag = false;
			if (Input.GetMouseButton(0) && GameUI.AltHeld())
			{
				flag = true;
			}
			if (Input.GetMouseButton(1) && !GameUI.AltHeld() && !Cinematics.inst.IsCinematicRunning() && !GodUI.inst.gameObject.activeSelf)
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
					startDesiredTrackingPos = DesiredTrackingPos;
				}
				if (achieveThreshold)
				{
					Vector3 vector3 = startDragPosition - vector2;
					DesiredTrackingPos = startDesiredTrackingPos + vector3;
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
			DesiredTrackingPos = ClampToWorldBounds(DesiredTrackingPos);
			TrackingPos.x = Mathf.SmoothDamp(TrackingPos.x, DesiredTrackingPos.x, ref TrackingVelX, posSmoothDampTime * 0.33f, float.MaxValue, num);
			TrackingPos.z = Mathf.SmoothDamp(TrackingPos.z, DesiredTrackingPos.z, ref TrackingVelZ, posSmoothDampTime * 0.33f, float.MaxValue, num);
			DesiredTrackingPos.y = GetAvgHeightAt(TrackingPos);
			TrackingPos.y = Mathf.SmoothDamp(TrackingPos.y, DesiredTrackingPos.y, ref TrackingVelY, posSmoothDampTime * 0.33f, float.MaxValue, num);
		}
		else
		{
			if (OverrideTrack != null && !OverrideTrack.Equals(null))
			{
				DesiredTrackingPos = OverrideTrack.GetDesiredTrackingPos();
			}
			DesiredTrackingPos = ClampToWorldBounds(DesiredTrackingPos);
			TrackingPos.x = Mathf.SmoothDamp(TrackingPos.x, DesiredTrackingPos.x, ref TrackingVelX, posSmoothDampTime, float.MaxValue, num);
			TrackingPos.z = Mathf.SmoothDamp(TrackingPos.z, DesiredTrackingPos.z, ref TrackingVelZ, posSmoothDampTime, float.MaxValue, num);
			if (OverrideTrack == null)
			{
				DesiredTrackingPos.y = GetAvgHeightAt(TrackingPos);
			}
			if (!setTrackThisFrame)
			{
				TrackingPos.y = Mathf.SmoothDamp(TrackingPos.y, DesiredTrackingPos.y, ref TrackingVelY, posSmoothDampTime, float.MaxValue, num);
			}
		}
		setTrackThisFrame = false;
		if (Theta >= 360f || Theta <= -360f)
		{
			Theta = Mathff.UnwindAngle(Theta);
			DesiredTheta = Mathff.UnwindAngle(DesiredTheta);
		}
		Theta = Mathf.SmoothDamp(Theta, DesiredTheta, ref ThetaVel, thetaSmoothDampTime, float.MaxValue, num);
		float num2 = desiredPhi;
		Vector3 vector4 = CalcCamPos(DesiredTrackingPos, desiredTheta, num2, desiredDist);
		float num3 = TerrainGen.inst.GetGroundHeight(vector4.x, vector4.z);
		RaycastHit closestRayHitWithRay = PointingSystem.GetClosestRayHitWithRay(new Ray(new Vector3(vector4.x, 100f, vector4.z), Vector3.down), scratchHitResults);
		if (closestRayHitWithRay.collider != null && closestRayHitWithRay.point.y > num3)
		{
			num3 = closestRayHitWithRay.point.y;
		}
		if (num3 < 0.25f)
		{
			num3 = 0.25f;
		}
		if (vector4.y < num3 + heightClipBuffer && desiredDist > heightClipBuffer)
		{
			Vector3 b = vector4;
			b.y = num3 + 2f;
			float y = b.y - DesiredTrackingPos.y;
			float x = Mathff.DistXZ(DesiredTrackingPos, b);
			num2 = (DesiredPhi = Mathf.Atan2(y, x) * 57.29578f);
		}
		Phi = Mathf.SmoothDamp(Phi, num2, ref PhiVel, phiSmoothDampTime, float.MaxValue, num);
		Dist = Mathf.SmoothDamp(Dist, DesiredDist, ref DistVel, distSmoothDampTime, float.MaxValue, num);
		float num4 = DistToPhiOffset.Evaluate(Dist);
		if (GamepadControl.inst.isControllerActive)
		{
			num4 *= 0.75f;
		}
		if (GameState.inst.IsMainMenuMode())
		{
			num2 = Mathf.Clamp(num2, -75f, 75f);
			DesiredPhi = Mathf.Clamp(DesiredPhi, -75f, 75f);
		}
		else
		{
			num2 = Mathf.Clamp(num2, -30f, 65f);
			DesiredPhi = Mathf.Clamp(DesiredPhi, -30f, 65f);
		}
		Vector3 vector5 = Quaternion.AngleAxis(num2, new Vector3(0f, 0f, 1f)) * new Vector3(1f, 0f, 0f);
		vector5 = Quaternion.AngleAxis(Theta, new Vector3(0f, 1f, 0f)) * vector5;
		vector5.Normalize();
		CamPos = TrackingPos + Dist * vector5;
		ShakeOffsetVel += (0f - K) * ShakeOffset * num;
		ShakeOffsetVel += Drag * -ShakeOffsetVel * num;
		ShakeOffset += ShakeOffsetVel * num;
		LastTrackingPos.x = transform.position.x;
		LastTrackingPos.y = transform.position.y;
		LastTrackingPos.z = transform.position.z;
		transform.position = CamPos + transform.rotation * ShakeOffset;
		cameraSpeed = (transform.position - LastTrackingPos).magnitude;
		Vector3 forward = TrackingPos + new Vector3(0f, num4, 0f) - CamPos;
		forward.Normalize();
		Quaternion rotation = Quaternion.LookRotation(forward);
		transform.rotation = rotation;
		Vector2 vector6 = cam.ScreenToViewportPoint(Input.mousePosition);
		isNotHoveringApplication = vector6.x < 0f || vector6.x > 1f || vector6.y < 0f || vector6.y > 1f;
		Ray ray = cam.ViewportPointToRay(new Vector3(0.5f, 0.5f));
		float a = distMicrophoneCurve.Evaluate(1f - Mathff.Clamp01((Dist - distMicrophoneMin) / (distMicrophoneMax - distMicrophoneMin)));
		float t = phiMicrophoneCurve.Evaluate(1f - Mathff.Clamp01((Phi - phiMicrophoneMin) / (phiMicrophoneMax - phiMicrophoneMin)));
		Vector3 position = transform.position;
		position.y = 0f;
		Vector3 trackingPos = TrackingPos;
		trackingPos.y = 0f;
		Vector3 vector7 = trackingPos - position;
		float num5 = Mathff.Lerp(a, 0f, t);
		vector7.x *= num5;
		vector7.z *= num5;
		Vector3 vector8 = position + vector7;
		if (Mathff.ClosestPointsOnTwoLines(out var closestPointLine, out var _, ray.origin, ray.direction, vector8, Vector3.up))
		{
			vector8 = closestPointLine;
		}
		microphoneT.position = vector8;
	}

	private static Vector3 CalcCamPos(Vector3 center, float theta, float phi, float dist)
	{
		Vector3 vector = Quaternion.AngleAxis(phi, new Vector3(0f, 0f, 1f)) * new Vector3(1f, 0f, 0f);
		vector = Quaternion.AngleAxis(theta, new Vector3(0f, 1f, 0f)) * vector;
		vector.Normalize();
		return center + dist * vector;
	}

	private float GetAvgHeightAt(Vector3 Pos)
	{
		float groundHeight = TerrainGen.inst.GetGroundHeight(Pos.x, Pos.z);
		groundHeight += TerrainGen.inst.GetGroundHeight(Pos.x + 2f, Pos.z);
		groundHeight += TerrainGen.inst.GetGroundHeight(Pos.x - 2f, Pos.z);
		groundHeight += TerrainGen.inst.GetGroundHeight(Pos.x, Pos.z + 2f);
		groundHeight += TerrainGen.inst.GetGroundHeight(Pos.x, Pos.z - 2f);
		groundHeight += TerrainGen.inst.GetGroundHeight(Pos.x + 2f, Pos.z + 2f);
		groundHeight += TerrainGen.inst.GetGroundHeight(Pos.x - 2f, Pos.z - 2f);
		groundHeight += TerrainGen.inst.GetGroundHeight(Pos.x - 2f, Pos.z + 2f);
		groundHeight += TerrainGen.inst.GetGroundHeight(Pos.x + 2f, Pos.z - 2f);
		groundHeight /= 9f;
		if (groundHeight < 0f)
		{
			groundHeight = 0f;
		}
		return Mathf.Lerp(groundHeight, 0f, Mathff.Clamp01((desiredDist - 15f) / 65f));
	}

	private Vector3 ClampToWorldBounds(Vector3 p)
	{
		if (Cinematics.inst.IsCinematicRunning() || GodUI.inst.gameObject.activeSelf)
		{
			return p;
		}
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
		if (ShakeOffsetVel.magnitude > MaxShakeMagnitude)
		{
			ShakeOffsetVel = ShakeOffsetVel.normalized * MaxShakeMagnitude;
		}
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

	public void BringIntoView(Vector3 origin, ArrayExt<Vector3> points, float addDist = 2f)
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
		Ray ray = new Ray(position, (vector - position).normalized);
		plane.Raycast(ray, out var enter);
		Vector3 point = ray.GetPoint(enter);
		for (int j = 0; j < points.Count; j++)
		{
			ray = new Ray(position, (points.data[j] - position).normalized);
			plane.Raycast(ray, out enter);
			float num3 = (ray.GetPoint(enter) - point).magnitude + addDist;
			if (num3 > num2)
			{
				num2 = num3;
			}
		}
		ray = new Ray(position, (origin - position).normalized);
		plane.Raycast(ray, out enter);
		float num4 = (ray.GetPoint(enter) - point).magnitude + addDist;
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

	public void BringIntoView(ArrayExt<Vector3> points)
	{
		float num = 0f;
		Vector3 zero = Vector3.zero;
		for (int i = 0; i < points.Count; i++)
		{
			zero += points.data[i].xz();
			num++;
		}
		if (!(num > 0f))
		{
			return;
		}
		zero /= num;
		float num2 = 0f;
		Vector3 position = inst.transform.position;
		Plane plane = new Plane(inst.GetDirection(), inst.TrackingPos);
		for (int j = 0; j < points.Count; j++)
		{
			Ray ray = new Ray(position, (points.data[j] - position).normalized);
			plane.Raycast(ray, out var enter);
			float num3 = (ray.GetPoint(enter) - zero).magnitude + 2f;
			if (num3 > num2)
			{
				num2 = num3;
			}
		}
		Camera component = GetComponent<Camera>();
		float f = MathF.PI / 180f * component.fieldOfView;
		float b = num2 / Mathf.Atan(f);
		desiredDist = Mathf.Max(10f, b);
		DesiredTrackingPos = zero.xz();
	}

	public bool IsInFrustum(Vector3 point)
	{
		Vector3 vector = cam.WorldToViewportPoint(point);
		bool num = vector.x >= 0f && vector.x <= 1f;
		bool flag = vector.y >= 0f && vector.y <= 1f;
		bool flag2 = vector.z > 0f;
		return num & flag & flag2;
	}

	internal Ray GetRay()
	{
		return new Ray(CamPos, transform.forward);
	}
}
