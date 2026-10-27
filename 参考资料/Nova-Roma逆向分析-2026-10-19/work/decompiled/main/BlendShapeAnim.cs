using UnityEngine;

public class BlendShapeAnim
{
	private SkinnedMeshRenderer renderer;

	private int NumShapes;

	private float[] weights;

	public int playToIndex = -1;

	private int idx;

	public void Init(int num, SkinnedMeshRenderer r)
	{
		renderer = r;
		NumShapes = num;
		weights = new float[NumShapes];
		for (int i = 0; i < weights.Length; i++)
		{
			renderer.SetBlendShapeWeight(i, 0f);
		}
		idx = 0;
	}

	public void Update(float dt)
	{
		int num = idx - 1;
		if (num < 0)
		{
			num = NumShapes - 1;
		}
		weights[num] = Mathf.Clamp01(weights[num] - dt * 1.1f);
		renderer.SetBlendShapeWeight(idx, weights[idx] * 100f);
		renderer.SetBlendShapeWeight(num, weights[num] * 100f);
		weights[idx] += dt;
		if (weights[idx] >= 1f && idx != playToIndex)
		{
			idx++;
			if (idx >= NumShapes)
			{
				idx = 0;
			}
		}
		weights[idx] = Mathf.Clamp01(weights[idx]);
	}
}
