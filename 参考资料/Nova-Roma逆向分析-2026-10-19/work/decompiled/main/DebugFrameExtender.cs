using System.Diagnostics;
using System.Threading;
using UnityEngine;

public class DebugFrameExtender : MonoBehaviour
{
	public bool frameRateControlEnabled;

	public float targetFrameRate = 20f;

	private readonly Stopwatch timing = new Stopwatch();

	private void Start()
	{
		timing.Start();
	}

	private void LateUpdate()
	{
		timing.Stop();
		float num = 1000f / targetFrameRate - (float)timing.ElapsedMilliseconds;
		if (num > 0f && frameRateControlEnabled)
		{
			Thread.Sleep((int)num);
		}
		timing.Restart();
	}
}
