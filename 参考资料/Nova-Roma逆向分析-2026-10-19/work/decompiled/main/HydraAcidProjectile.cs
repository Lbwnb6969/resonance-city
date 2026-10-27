using UnityEngine;

public class HydraAcidProjectile : MonoBehaviour
{
	public GameObject chunk;

	public ParticleSystem acidTrail;

	public ParticleSystem acidSplash;

	private Timer expireTimer = new Timer(10f);

	private bool moving = true;

	private void Start()
	{
	}

	private void Update()
	{
		if (moving)
		{
			transform.position += transform.forward * Time.deltaTime * 10f;
		}
		else if (expireTimer.Update(Time.deltaTime))
		{
			Object.Destroy(gameObject);
		}
	}

	private void OnTriggerEnter(Collider other)
	{
		LayerMask.NameToLayer("Terrain");
		if (other.gameObject.layer == 11)
		{
			moving = false;
			chunk.SetActive(value: false);
			acidTrail.Stop(withChildren: false, ParticleSystemStopBehavior.StopEmitting);
			acidSplash.Play();
			transform.rotation = Quaternion.identity;
		}
	}
}
