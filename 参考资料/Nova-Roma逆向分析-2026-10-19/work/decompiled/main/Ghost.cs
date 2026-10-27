using UnityEngine;

public class Ghost : PooledObject
{
	public MeshRenderer ghostBody;

	public ParticleSystem sparkle;

	private Color color;

	private float startY;

	private float speed;

	private float baseSpeed = 2f;

	private void Awake()
	{
		color = ghostBody.sharedMaterial.color;
	}

	private void Update()
	{
		transform.position += Vector3.up * Time.unscaledDeltaTime * speed;
		Color color = new Color(this.color.r, this.color.g, this.color.b, transform.position.y.Remap(startY, startY + 5f, 0.75f, 0f));
		ghostBody.material.color = color;
		sparkle.Simulate(Time.unscaledDeltaTime, withChildren: true, restart: false);
		if (transform.position.y > startY + 5f)
		{
			if (sparkle.isEmitting || sparkle.isPlaying || !sparkle.isStopped)
			{
				sparkle.Stop();
			}
			if (sparkle.particleCount == 0)
			{
				Release();
			}
		}
	}

	private void OnEnable()
	{
		startY = transform.position.y;
		speed = SRand.Range(0.8f, 1.2f) * baseSpeed;
	}
}
