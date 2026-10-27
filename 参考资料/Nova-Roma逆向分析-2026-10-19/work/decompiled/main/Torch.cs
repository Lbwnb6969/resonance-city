using System;
using UnityEngine;

public class Torch : MonoBehaviour
{
	[SerializeField]
	private ParticleSystem pSystem;

	private Vector3 startPosition;

	private Vector3 endPosition;

	public const float MAX_TIME = 1f;

	public const float MAX_HEIGHT = 1f;

	private float maxTime = 1f;

	private float maxHeight = 1f;

	private float currTime;

	private bool inited;

	public static Torch Create(Vector3 sPos, Vector3 ePos, bool doVariance = false)
	{
		Torch torch = UnityEngine.Object.Instantiate(UnitSystem.inst.torchPrefab, null);
		torch.Init(sPos, ePos);
		if (doVariance)
		{
			torch.maxTime = 1f + SRand.Range(-0.25f, 0.25f);
			torch.maxHeight = 1f + SRand.Range(-1f, 1f);
		}
		return torch;
	}

	private void Awake()
	{
		Util.SetActive(gameObject, active: false);
		inited = false;
	}

	public void Init(Vector3 sPos, Vector3 ePos)
	{
		startPosition = sPos;
		endPosition = ePos;
		currTime = 0f;
		inited = true;
		Util.SetActive(gameObject, active: true);
	}

	private void Update()
	{
		if (inited)
		{
			currTime += Time.deltaTime;
			float num = currTime / maxTime;
			if (num >= 1f)
			{
				transform.position = endPosition;
				UnityEngine.Object.Destroy(gameObject);
				return;
			}
			float num2 = Mathf.Sin(num * MathF.PI) * maxHeight;
			Vector3 position = Vector3.Lerp(startPosition, endPosition, num);
			position.y += num2;
			transform.position = position;
		}
	}
}
