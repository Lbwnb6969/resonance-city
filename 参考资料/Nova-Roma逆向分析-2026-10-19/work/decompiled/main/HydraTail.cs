using System.Collections.Generic;
using UnityEngine;

public class HydraTail : MonoBehaviour
{
	public GameObject tailSegmentPrefab;

	public int segmentCount = 10;

	public float segmentSpacing = 0.5f;

	public AnimationCurve BodySizeGradient;

	private List<GameObject> tailSegments = new List<GameObject>();

	private GameObject worldSpaceObject;

	public HydraHead primaryHeadForAlignment;

	private List<Vector3> waypoints = new List<Vector3>();

	private float lastMagnitude;

	private Vector3 lastPosition;

	public float panicBlendSpeed = 2f;

	public float panicOffsetScale = 1f;

	public float panicWiggleSpeed = 1f;

	public float panicRotationMaxDegrees = 90f;

	private float bodyPanicBlender;

	private bool bodyPanic;

	private void Start()
	{
		BuildTail();
		lastPosition = transform.position;
	}

	private void BuildTail()
	{
		foreach (GameObject tailSegment in tailSegments)
		{
			Object.Destroy(tailSegment);
		}
		tailSegments.Clear();
		waypoints.Clear();
		for (int i = 0; i < segmentCount; i++)
		{
			float time = (float)i / (float)segmentCount;
			float num = BodySizeGradient.Evaluate(time);
			GameObject gameObject = Object.Instantiate(tailSegmentPrefab, transform);
			gameObject.transform.localPosition = new Vector3(0f, 0f, (float)(-i) * segmentSpacing);
			foreach (Transform item in transform)
			{
				item.localPosition += new Vector3(0f, num / 2f, 0f);
			}
			gameObject.transform.localScale = new Vector3(num, num, 1f);
			gameObject.SetActive(value: true);
			tailSegments.Add(gameObject);
			waypoints.Add(gameObject.transform.position);
		}
		PlaceOnGround();
	}

	private void PlaceOnGround()
	{
		for (int i = 0; i < tailSegments.Count; i++)
		{
			GameObject gameObject = tailSegments[i];
			if (Physics.Raycast(new Ray(gameObject.transform.position + Vector3.up * 10f, -Vector3.up), out var hitInfo, 1000f, LayerMask.GetMask("Terrain")))
			{
				gameObject.transform.position = hitInfo.point;
				Vector3 vector = transform.forward;
				if (i != 0)
				{
					vector = (tailSegments[i - 1].transform.position - gameObject.transform.position).normalized;
				}
				gameObject.transform.rotation = Quaternion.LookRotation(Vector3.ProjectOnPlane(vector, hitInfo.normal), hitInfo.normal);
			}
		}
	}

	private void LateUpdate()
	{
		bodyPanicBlender = Mathf.MoveTowards(bodyPanicBlender, (!bodyPanic) ? 1 : 0, Time.deltaTime * panicBlendSpeed);
		float magnitude = (transform.position - lastPosition).magnitude;
		bool flag = false;
		Vector3 position = transform.position;
		if (magnitude < lastMagnitude)
		{
			flag = true;
			position = lastPosition;
		}
		if ((double)magnitude > 0.1)
		{
			flag = true;
		}
		if (flag)
		{
			waypoints.Insert(0, position);
			lastPosition = position;
			lastMagnitude = 0f;
		}
		else
		{
			lastMagnitude = magnitude;
		}
		Vector3 vector = Vector3.Lerp(new Vector3(Mathf.Sin(Time.time * panicWiggleSpeed), Mathf.Sin(Time.time * panicWiggleSpeed * 2f) * 0.5f + 0.5f, Mathf.Cos(Time.time * panicWiggleSpeed)), Vector3.zero, bodyPanicBlender);
		tailSegments[0].transform.position = transform.position + (vector + Vector3.up * BodySizeGradient.Evaluate(0f) / 2f) * transform.lossyScale.z;
		int num = 0;
		int num2 = 1;
		Vector3 vector2 = transform.position;
		float num3 = segmentSpacing * transform.lossyScale.z;
		while (num2 < segmentCount)
		{
			float num4 = Vector3.Distance(vector2, waypoints[num]);
			if (num4 < num3)
			{
				vector2 = waypoints[num];
				num3 -= num4;
				num++;
				continue;
			}
			float num5 = (float)num2 / (float)segmentCount;
			Vector3 vector3 = Vector3.Lerp(new Vector3(Mathf.Sin(Time.time * panicWiggleSpeed + num5 * panicOffsetScale), Mathf.Sin(Time.time * panicWiggleSpeed * 2f + num5 * panicOffsetScale) * 0.5f + 0.5f, Mathf.Cos(Time.time * panicWiggleSpeed + num5 * panicOffsetScale)), Vector3.zero, bodyPanicBlender);
			vector2 = Vector3.MoveTowards(vector2, waypoints[num], num3);
			float time = (float)num2 / (float)segmentCount;
			float num6 = BodySizeGradient.Evaluate(time);
			tailSegments[num2].transform.position = vector2 + (vector3 + Vector3.up * num6 / 2f) * transform.lossyScale.z;
			num2++;
			num3 = segmentSpacing * transform.lossyScale.z;
		}
		if (num + 5 < waypoints.Count)
		{
			waypoints.RemoveRange(num + 1, waypoints.Count - (num + 1));
		}
		for (int i = 0; i < segmentCount; i++)
		{
			Vector3 vector4 = ((i == 0) ? primaryHeadForAlignment.GetBaseNeckJoint() : tailSegments[i - 1].transform.position);
			Vector3 position2;
			if (i != segmentCount - 1)
			{
				position2 = tailSegments[i + 1].transform.position;
			}
			else
			{
				List<GameObject> list = tailSegments;
				position2 = list[list.Count - 1].transform.position;
			}
			Vector3 vector5 = position2;
			Quaternion rotation = Quaternion.Slerp(Quaternion.AngleAxis(Mathf.Sin(Time.time * panicWiggleSpeed + (float)i / (float)segmentCount * panicOffsetScale) * panicRotationMaxDegrees, (vector4 - vector5).normalized), Quaternion.identity, bodyPanicBlender) * Quaternion.LookRotation(vector4 - vector5, Vector3.up);
			tailSegments[i].transform.rotation = rotation;
		}
	}

	public void BodyPanic(bool on)
	{
		bodyPanic = on;
	}
}
