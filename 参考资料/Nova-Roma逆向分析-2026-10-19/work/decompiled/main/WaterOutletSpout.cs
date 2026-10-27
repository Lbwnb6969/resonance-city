using UnityEngine;

public class WaterOutletSpout : MonoBehaviour
{
	[Tooltip("Where the waterfall particles originate (the spout lip). Defaults to this transform.")]
	public Transform waterfallOrigin;

	[Tooltip("Falling-water particle system; the outlet scales its lifetime to reach any drop height.")]
	public ParticleSystem fall;

	[Tooltip("Splash burst played where the stream lands; defaults to a child named \"Splash\". The outlet places it on the surface, tilted to the surface normal, while the stream is reaching the bottom.")]
	public ParticleSystem splash;

	public Transform Origin
	{
		get
		{
			if (!(waterfallOrigin != null))
			{
				return transform;
			}
			return waterfallOrigin;
		}
	}

	public ParticleSystem Splash
	{
		get
		{
			if (splash == null)
			{
				Transform transform = base.transform.Find("Splash");
				if (transform != null)
				{
					splash = transform.GetComponent<ParticleSystem>();
				}
			}
			return splash;
		}
	}
}
