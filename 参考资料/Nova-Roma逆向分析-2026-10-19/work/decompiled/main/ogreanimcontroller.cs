using System;
using UnityEngine;

public class ogreanimcontroller : MonoBehaviour
{
	public Animator anim;

	private Vector3 syncToLoc;

	private Quaternion syncToRot;

	private float syncTime = -1f;

	private float totalSyncTime = 1f;

	[NonSerialized]
	public float fwdVel;

	public float velSpeedScale = 8f;

	private void StartSyncTo(Vector3 syncPos, Quaternion syncRot, float time)
	{
		syncToLoc = syncPos;
		syncToRot = syncRot;
		totalSyncTime = time;
		syncTime = time;
	}

	public void TransitionToAttacking(Vector3 syncLoc, Quaternion syncRot, float time)
	{
		anim.CrossFade("mutant_swiping", 0.1f);
		anim.applyRootMotion = true;
		StartSyncTo(syncLoc, syncRot, time);
	}

	public void TransitionToDying()
	{
		anim.CrossFade("mutant_dying", 0.1f);
	}

	public void TransitionToWalking()
	{
		anim.applyRootMotion = true;
		anim.CrossFade("IdleWalk", 0.1f);
	}

	private void Update()
	{
		if (syncTime >= 0f)
		{
			syncTime -= Time.deltaTime;
			float t = Mathf.Clamp01(1f - syncTime / totalSyncTime);
			transform.position = Vector3.Lerp(transform.position, syncToLoc, t);
			transform.rotation = Quaternion.Slerp(transform.rotation, syncToRot, t);
		}
		float value = fwdVel * 8f;
		anim.SetFloat("vSpeed", value);
	}
}
