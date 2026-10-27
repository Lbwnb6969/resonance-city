using Assets;
using UnityEngine;

public class BirdSystem : MonoBehaviour
{
	public GameObject BirdPrefab;

	public float drag = 1f;

	public float attractRadius = 15f;

	public float attract = 1f;

	public float repelRadius = 5f;

	public float repel = 2f;

	public float alignRadius = 10f;

	public float align = 1f;

	public float maxSpeed = 5f;

	public float rotDrag = 10f;

	public float rotAlign = 10f;

	public float unroll = 1f;

	public int numBirds = 10;

	private Bird[] birds;

	public static BirdSystem inst;

	public Transform Bounds;

	private bool birdsOn = true;

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		birds = new Bird[numBirds];
		for (int i = 0; i < numBirds; i++)
		{
			GameObject gameObject = Object.Instantiate(BirdPrefab);
			birds[i] = gameObject.GetComponent<Bird>();
			birds[i].Init();
		}
		BirdPrefab.SetActive(value: false);
		Reset();
	}

	public void Reset()
	{
		for (int i = 0; i < numBirds; i++)
		{
			Vector3 vector = new Vector3(SRand.Range(0, World.inst.GridWidth), 10f, SRand.Range(0, World.inst.GridHeight));
			if (i > 0)
			{
				Vector3 vector2 = vector - birds[i - 1].CurrLoc;
				vector = birds[i - 1].CurrLoc + vector2.normalized * attractRadius;
			}
			birds[i].SetPosition(vector);
			birds[i].Reset();
		}
		Vector3 position = new Vector3((float)World.inst.GridWidth * 0.5f, 10f, (float)World.inst.GridHeight * 0.5f);
		Bounds.position = position;
		Bounds.localScale = new Vector3((float)World.inst.GridWidth * 0.9f, 10f, (float)World.inst.GridHeight * 0.9f);
	}

	private void Update()
	{
		if (birdsOn != Settings.inst.Birds)
		{
			birdsOn = Settings.inst.Birds;
			for (int i = 0; i < numBirds; i++)
			{
				birds[i].gameObject.SetActive(birdsOn);
			}
		}
		if (birdsOn)
		{
			float deltaTime = Time.deltaTime;
			deltaTime = Mathf.Clamp(deltaTime, 0.001f, 0.1f);
			for (int j = 0; j < numBirds; j++)
			{
				birds[j].UpdateBird(deltaTime, birds, this, Bounds);
			}
		}
	}
}
