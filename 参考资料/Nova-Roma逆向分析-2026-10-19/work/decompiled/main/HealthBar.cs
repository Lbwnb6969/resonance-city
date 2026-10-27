using UnityEngine;

public class HealthBar : MonoBehaviour
{
	private Transform fill;

	private Transform xform;

	internal Vector3 origScale;

	private Vector3 pos;

	public float life = 0.3f;

	private float prevLife = -1f;

	private float timeShowing;

	public float maxTimeShowing = 5f;

	internal bool visible = true;

	private static ArrayExt<HealthBar> healthBars = new ArrayExt<HealthBar>(50);

	public Transform[] bonusIcons;

	private void Awake()
	{
		fill = transform.GetChild(0).GetChild(0);
		xform = transform;
		origScale = xform.localScale;
		SetAttackBonusCount(0);
	}

	public void SetPos(Vector3 worldPos)
	{
		pos = worldPos;
	}

	private void Tick(float dt, Vector3 targetUp, Vector3 camPos, Vector3 zeroScale)
	{
		float num = Mathff.Clamp01(life);
		if (num != prevLife)
		{
			timeShowing = 0f;
		}
		else
		{
			timeShowing += dt;
		}
		if (timeShowing < maxTimeShowing && num > 0f && visible)
		{
			Vector3 forward = new Vector3(pos.x - camPos.x, pos.y - camPos.y, pos.z - camPos.z);
			xform.SetPositionAndRotation(pos, Quaternion.LookRotation(forward, targetUp));
			float num2 = Mathff.Clamp01(life) * 0.98f;
			fill.localScale = new Vector3(num2, 0.7f, 1f);
			fill.localPosition = new Vector3((0f - (1f - num2)) * 0.5f + 0.01f, 0f, -0.016f);
			xform.localScale = origScale;
		}
		else
		{
			xform.localScale = zeroScale;
		}
		prevLife = num;
	}

	private void OnEnable()
	{
		xform = transform;
		healthBars.Add(this);
	}

	private void OnDisable()
	{
		healthBars.RemoveSwap(this);
	}

	public static void TickHealthBars(float dt)
	{
		Vector3 targetUp = Cam.inst.transform.rotation * Vector3.up;
		Vector3 position = Cam.inst.transform.position;
		Vector3 zero = Vector3.zero;
		for (int i = 0; i < healthBars.Count; i++)
		{
			healthBars.data[i].Tick(dt, targetUp, position, zero);
		}
	}

	internal void SetAttackBonusCount(int bonusCount)
	{
		for (int i = 0; i < bonusIcons.Length; i++)
		{
			Util.SetActive(bonusIcons[i], i < bonusCount);
		}
	}
}
