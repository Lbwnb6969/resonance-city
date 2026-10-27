using System.Collections.Generic;
using UnityEngine;

public class WaterWavefrontLabelSystem : MonoBehaviour
{
	public static WaterWavefrontLabelSystem inst;

	[Tooltip("Prefab root with a WaveFrontLabel (TextMeshPro + background sprite). Distinct from the hub prefab.")]
	public WaveFrontLabel labelPrefab;

	[Tooltip("On-screen size vs. distance to camera (matches the hub labels' feel).")]
	public AnimationCurve scaleToCamDist = AnimationCurve.Linear(0f, 0.5f, 100f, 5f);

	[Tooltip("Background footprint as a multiple of the measured text size, per axis. (1,1) hugs the glyph bounds exactly; larger leaves a margin. Multiplicative, so it holds regardless of font size or label scale — tune to taste. Only the wavefront labels auto-fit; the hub labels keep their authored background.")]
	public Vector2 backgroundFitPadding = new Vector2(1.5f, 1.9f);

	private readonly List<WaveFrontLabel> pool = new List<WaveFrontLabel>(64);

	private readonly List<AqueductLine.Wavefront> scratch = new List<AqueductLine.Wavefront>(64);

	private void Awake()
	{
		inst = this;
	}

	private void LateUpdate()
	{
		if (labelPrefab == null || Cam.inst == null || !AqueductLine.IsWaterBuildingSelected())
		{
			HideAll();
			return;
		}
		scratch.Clear();
		List<AqueductLine> allLines = AqueductLine.allLines;
		for (int i = 0; i < allLines.Count; i++)
		{
			if (allLines[i] != null)
			{
				allLines[i].CollectWavefronts(scratch);
			}
		}
		Camera cam = Cam.inst.cam;
		Vector3 position = cam.transform.position;
		for (int j = 0; j < scratch.Count; j++)
		{
			AqueductLine.Wavefront wavefront = scratch[j];
			float scale = scaleToCamDist.Evaluate(Vector3.Distance(wavefront.worldPos, position));
			WaveFrontLabel pooled = GetPooled(j);
			pooled.SetText(wavefront.label);
			pooled.Place(wavefront.worldPos, cam, scale);
		}
		for (int k = scratch.Count; k < pool.Count; k++)
		{
			SetActive(pool[k], active: false);
		}
	}

	private WaveFrontLabel GetPooled(int index)
	{
		while (pool.Count <= index)
		{
			pool.Add(Object.Instantiate(labelPrefab, transform));
		}
		WaveFrontLabel waveFrontLabel = pool[index];
		SetActive(waveFrontLabel, active: true);
		return waveFrontLabel;
	}

	private void HideAll()
	{
		for (int i = 0; i < pool.Count; i++)
		{
			SetActive(pool[i], active: false);
		}
	}

	private static void SetActive(WaveFrontLabel label, bool active)
	{
		if (label != null && label.gameObject.activeSelf != active)
		{
			label.gameObject.SetActive(active);
		}
	}
}
