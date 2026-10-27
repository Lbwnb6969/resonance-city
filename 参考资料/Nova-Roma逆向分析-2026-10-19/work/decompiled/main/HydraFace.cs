using Unity.Mathematics;
using UnityEngine;

public class HydraFace : MonoBehaviour
{
	public Vector3 desiredHeadPosition;

	public Quaternion desiredHeadRotation;

	public Transform jaw;

	public float jawOpenDegrees = 45f;

	private float openAmountCurrent;

	private float openAmount;

	public float OpenAmount
	{
		get
		{
			return openAmount;
		}
		set
		{
			openAmount = value;
		}
	}

	public void CloseMouth()
	{
		openAmount = 0f;
	}

	public void OpenMouth()
	{
		openAmount = 1f;
	}

	public bool IsMouthOpen()
	{
		return openAmount >= 1f;
	}

	public bool IsMouthClosed()
	{
		return openAmount >= 1f;
	}

	private void Update()
	{
		openAmountCurrent = Mathf.SmoothStep(openAmountCurrent, openAmount, Time.deltaTime * 10f);
		jaw.localRotation = Quaternion.AngleAxis(jawOpenDegrees * openAmountCurrent, Vector3.right);
	}

	private void LateUpdate()
	{
		transform.position = desiredHeadPosition;
		transform.rotation = desiredHeadRotation * Quaternion.AngleAxis(0f - jawOpenDegrees * 0.5f * openAmountCurrent, Vector3.right);
	}

	public void GetAcidSpitPosition(out Vector3 position, out Quaternion rotation)
	{
		position = jaw.position;
		rotation = Quaternion.Slerp(jaw.rotation, transform.rotation, 0.5f);
	}

	public void SetPositionOrientation(float3 headPos, quaternion lookRotation)
	{
		desiredHeadPosition = headPos;
		desiredHeadRotation = lookRotation;
	}
}
