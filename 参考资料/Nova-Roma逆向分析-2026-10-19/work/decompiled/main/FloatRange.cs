using System;

[Serializable]
public class FloatRange
{
	public float min;

	public float max;

	public FloatRange(float min, float max)
	{
		this.min = min;
		this.max = max;
	}

	public bool Contains(float val)
	{
		if (val >= min)
		{
			return val <= max;
		}
		return false;
	}
}
