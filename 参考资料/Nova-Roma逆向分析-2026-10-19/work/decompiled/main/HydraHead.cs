using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Splines;

public class HydraHead : MonoBehaviour
{
	private SplineContainer splineContainer;

	public GameObject segmentPrefab;

	public HydraFace facePrefab;

	public bool rebuildOnLayout;

	public float splineScale = 1f;

	public float tangentScale = 1f;

	public Transform bodyFollow;

	public Transform bottomBodyHandle;

	public Transform upperBodyHandle;

	public Transform neckBodyHandle;

	public Transform headHandle;

	public Transform acidSpitPoint;

	public BezierKnot[] knotCache;

	public HydraLookInterest[] lookInterestTargets;

	public Vector3 headPosition;

	public Quaternion headRotation;

	public Transform neckTransform;

	public HydraFace hydraFaceObject;

	public float growth;

	public float growthSpeed = 0.1f;

	public GameObject acidProjectilePrefab;

	public float shootPushBack;

	public Vector3 lookTarget;

	public GameObject lookTargetObject;

	public int lookAtType = -1;

	public bool easyOut;

	private List<Transform> segments = new List<Transform>();

	public float segmentSpacing = 1f;

	public float traversalStepSize;

	public int segmentIndex;

	public bool debugDraw;

	private Timer shootTimer = new Timer(0.5f);

	private int wantToShoot;

	public void KilledNoRegrow()
	{
		ConvertToPhysics();
		Util.FindInParents<Hydra>(gameObject).RemoveHead(this, regrow: false);
	}

	public void Killed()
	{
		ConvertToPhysics();
		Util.FindInParents<Hydra>(gameObject).RemoveHead(this, regrow: true);
	}

	public void ReplaceHead()
	{
		ConvertToPhysics();
		Util.FindInParents<Hydra>(gameObject).ReplaceHead(this);
	}

	public void SetLookAtTarget(Vector3 target)
	{
		lookTarget = target;
		lookAtType = 0;
	}

	public void SetLookAtTarget(GameObject target)
	{
		lookTargetObject = target;
		lookAtType = 1;
	}

	public void Rebuild(bool forceRebuild = false)
	{
		if ((rebuildOnLayout | forceRebuild) || splineContainer == null)
		{
			splineContainer = gameObject.GetComponent<SplineContainer>();
			knotCache = new BezierKnot[4]
			{
				new BezierKnot(new float3(0f, 0f, 0f), new float3(0f, 0f, 0f), new float3(0f, 0f, 1f * tangentScale), Quaternion.LookRotation(Vector3.forward)),
				new BezierKnot(new float3(0f, 0.332f * splineScale, 0.332f * splineScale), new float3(0f, 0f, -1f * tangentScale), new float3(0f, 0f, 1f * tangentScale), Quaternion.LookRotation(Vector3.up)),
				new BezierKnot(new float3(0f, 1f * splineScale, 0f), new float3(0f, 0f, -1f * tangentScale), new float3(0f, 0f, 1f * tangentScale), Quaternion.LookRotation(Vector3.up)),
				new BezierKnot(new float3(0f, 1.25f * splineScale, 1f * splineScale), new float3(0f, 0f, -1f * tangentScale), new float3(0f, 0f, 0f), Quaternion.LookRotation(Vector3.forward))
			};
			bottomBodyHandle.position = transform.TransformPoint(knotCache[1].Position);
			bottomBodyHandle.rotation = transform.rotation * knotCache[1].Rotation;
			upperBodyHandle.position = transform.TransformPoint(knotCache[2].Position);
			upperBodyHandle.rotation = transform.rotation * knotCache[2].Rotation;
			headHandle.position = transform.TransformPoint(knotCache[3].Position);
			headHandle.rotation = transform.rotation * knotCache[3].Rotation;
			Spline item = new Spline(knotCache);
			List<Spline> list = new List<Spline>();
			list.Add(item);
			splineContainer.Splines = list;
			neckTransform = transform.Find("Neck");
			foreach (Transform item2 in neckTransform)
			{
				Object.Destroy(item2.gameObject);
			}
			segments.Clear();
		}
		LayoutSegments();
	}

	public void ConvertToPhysics()
	{
		enabled = false;
		hydraFaceObject.transform.SetParent(null, worldPositionStays: true);
		hydraFaceObject.GetComponent<Rigidbody>().isKinematic = false;
		hydraFaceObject.GetComponent<Rigidbody>().mass = 1f;
		CharacterJoint characterJoint = hydraFaceObject.gameObject.AddComponent<CharacterJoint>();
		characterJoint.connectedBody = segments[0].GetComponent<Rigidbody>();
		characterJoint.anchor = Vector3.zero;
		Vector3 axis = (characterJoint.swingAxis = (segments[0].transform.position - hydraFaceObject.transform.position).normalized);
		characterJoint.axis = axis;
		characterJoint.swing1Limit = new SoftJointLimit
		{
			limit = 45f
		};
		characterJoint.swing2Limit = new SoftJointLimit
		{
			limit = 177f
		};
		for (int i = 0; i < segmentIndex - 1; i++)
		{
			segments[i].transform.SetParent(null, worldPositionStays: true);
			segments[i].GetComponent<Rigidbody>().isKinematic = false;
			segments[i].GetComponent<Rigidbody>().mass = 1f;
			if (i != segmentIndex - 2)
			{
				CharacterJoint characterJoint2 = segments[i].gameObject.AddComponent<CharacterJoint>();
				characterJoint2.connectedBody = segments[i + 1].GetComponent<Rigidbody>();
				characterJoint2.anchor = Vector3.zero;
				axis = (characterJoint2.swingAxis = (segments[i + 1].transform.position - segments[i].transform.position).normalized);
				characterJoint2.axis = axis;
				characterJoint2.swing1Limit = new SoftJointLimit
				{
					limit = 45f
				};
				characterJoint2.swing2Limit = new SoftJointLimit
				{
					limit = 177f
				};
			}
		}
		hydraFaceObject.GetComponent<Rigidbody>().AddForceAtPosition(hydraFaceObject.transform.right * 50f, hydraFaceObject.transform.position, ForceMode.Impulse);
	}

	public GameObject makeSegment()
	{
		float num = 1f;
		GameObject gameObject = Object.Instantiate(segmentPrefab, neckTransform.transform);
		gameObject.transform.localScale = new Vector3(num, num, 1f);
		foreach (Transform item in gameObject.transform)
		{
			item.localPosition += new Vector3(0f, num / 2f, 0f);
		}
		gameObject.SetActive(value: true);
		segments.Add(gameObject.transform);
		return gameObject;
	}

	public void LayoutSegments()
	{
		float num = 1f;
		float num2 = 0f;
		float3 x = splineContainer.EvaluatePosition(1f);
		segmentIndex = 0;
		bool flag = false;
		while (!flag)
		{
			float num3 = (float)(segmentIndex + 1) * segmentSpacing * transform.lossyScale.z;
			while (num2 < num3 && !easyOut)
			{
				num -= traversalStepSize;
				float3 float5 = splineContainer.EvaluatePosition(num);
				num2 += math.max(math.distance(x, float5), 0.0001f);
				x = float5;
				if (num < 0f)
				{
					flag = true;
					break;
				}
			}
			if (flag)
			{
				break;
			}
			if (segmentIndex >= segments.Count)
			{
				if (segmentIndex >= 100)
				{
					break;
				}
				makeSegment();
			}
			segments[segmentIndex].gameObject.SetActive(value: true);
			splineContainer.Evaluate(num, out var position, out var tangent, out var upVector);
			tangent = math.normalize(tangent);
			segments[segmentIndex].rotation = quaternion.LookRotation(tangent, upVector);
			segments[segmentIndex].position = (Vector3)position - segments[segmentIndex].transform.up * (0.5f * transform.lossyScale.z);
			segmentIndex++;
			if (debugDraw)
			{
				for (int i = 0; i < 20; i++)
				{
					splineContainer.Evaluate((float)i / 20f, out var position2, out var tangent2, out var upVector2);
					tangent2 = math.normalize(tangent2);
					Debug.DrawRay(position2, tangent2, Color.blue, 0f, depthTest: false);
					Debug.DrawRay(position2, upVector2, Color.green, 0f, depthTest: false);
					Debug.DrawRay(position2, math.cross(tangent2, upVector2), Color.red, 0f, depthTest: false);
				}
			}
		}
		if (hydraFaceObject == null)
		{
			hydraFaceObject = Object.Instantiate(facePrefab, transform).GetComponent<HydraFace>();
			hydraFaceObject.gameObject.SetActive(value: true);
			acidSpitPoint = hydraFaceObject.transform.Find("SpitPoint");
		}
		splineContainer.Evaluate(1f, out var position3, out var tangent3, out var upVector3);
		tangent3 = math.normalize(tangent3);
		hydraFaceObject.SetPositionOrientation(position3, quaternion.LookRotation(tangent3, upVector3));
		for (int j = segmentIndex; j < segments.Count; j++)
		{
			segments[j].gameObject.SetActive(value: false);
		}
	}

	public void OnEnable()
	{
		Rebuild(forceRebuild: true);
		lookInterestTargets = Object.FindObjectsByType<HydraLookInterest>(FindObjectsSortMode.None);
	}

	private void Update()
	{
		if (wantToShoot > 0)
		{
			hydraFaceObject.OpenMouth();
		}
		if (wantToShoot > 0 && hydraFaceObject.IsMouthOpen())
		{
			if (shootTimer.Update(Time.deltaTime))
			{
				GameObject gameObject = Object.Instantiate(acidProjectilePrefab, null, worldPositionStays: false);
				hydraFaceObject.GetAcidSpitPosition(out var position, out var rotation);
				gameObject.transform.position = position;
				gameObject.transform.rotation = rotation;
				wantToShoot--;
			}
			if (wantToShoot == 0)
			{
				hydraFaceObject.CloseMouth();
			}
		}
		growth = math.clamp(growth + growthSpeed * Time.deltaTime, 0f, 1f);
		transform.GetChild(0).localScale = new Vector3(growth, growth, growth);
		float3 float5 = new float3(0f, 0f, 1f * tangentScale * transform.GetChild(0).lossyScale.z * 2f);
		knotCache[0].Position = transform.InverseTransformPoint(bodyFollow.transform.position + Vector3.up * (0.5f * transform.lossyScale.z));
		knotCache[0].Rotation = quaternion.LookRotation(transform.InverseTransformDirection(bodyFollow.transform.forward), Vector3.up);
		knotCache[0].TangentIn = -float5;
		knotCache[0].TangentOut = float5;
		knotCache[1].Position = transform.InverseTransformPoint(bottomBodyHandle.transform.position);
		knotCache[1].Rotation = bottomBodyHandle.localRotation;
		knotCache[1].TangentIn = -float5;
		knotCache[1].TangentOut = float5;
		knotCache[2].Position = transform.InverseTransformPoint(upperBodyHandle.transform.position);
		knotCache[2].Rotation = upperBodyHandle.localRotation;
		knotCache[2].TangentIn = -float5;
		knotCache[2].TangentOut = float5;
		shootPushBack = math.clamp(shootPushBack - Time.deltaTime, 0f, 1f);
		float num = float.MaxValue;
		HydraLookInterest hydraLookInterest = null;
		for (int i = 0; i < lookInterestTargets.Length; i++)
		{
			float num2 = Vector3.Distance(lookInterestTargets[i].transform.position, headHandle.position);
			if (num2 < num && Vector3.Dot(lookInterestTargets[i].transform.position - headHandle.position, headHandle.forward) > 0f)
			{
				num = num2;
				hydraLookInterest = lookInterestTargets[i];
			}
		}
		headPosition = transform.InverseTransformPoint(headHandle.transform.GetChild(0).position);
		headRotation = Quaternion.Inverse(transform.rotation) * headHandle.GetChild(0).rotation;
		knotCache[3].Position = Vector3.MoveTowards(knotCache[3].Position, headPosition, 100f * Time.deltaTime);
		knotCache[3].Rotation = Quaternion.RotateTowards(knotCache[3].Rotation, headRotation, 360f * Time.deltaTime);
		knotCache[3].TangentIn = -float5;
		knotCache[3].TangentOut = float5;
		splineContainer.Spline.Knots = knotCache;
	}

	private void LateUpdate()
	{
		LayoutSegments();
	}

	public Vector3 GetBaseNeckJoint()
	{
		if (segments.Count > 0 && segments[segmentIndex - 1].gameObject.activeSelf)
		{
			return segments[segmentIndex - 1].position + segments[segmentIndex - 1].up * (0.5f * transform.lossyScale.z);
		}
		return bodyFollow.transform.position;
	}

	public void ShootAcid()
	{
		wantToShoot++;
		hydraFaceObject.OpenMouth();
	}
}
