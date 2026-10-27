using System;
using UnityEngine;

public class Whale : MonoBehaviour
{
	public ParticleSystem spout;

	public ParticleSystem wake;

	public float minDistanceFromShore;

	public float maxDistanceFromShore;

	public float swimSpeed;

	public float turnSpeed;

	public float baseDepth = -1f;

	public float breathDepth;

	private Vector3 destination;

	private int currentRect;

	private Rect[] travelRects = new Rect[4];

	public Timer breathInterval = new Timer(4f);

	public Timer breathTime = new Timer(4f);

	private EdgeTrigger onStartSpouting = new EdgeTrigger();

	private EdgeTrigger onStartSurfacing = new EdgeTrigger();

	private void Awake()
	{
		gameObject.SetActive(value: false);
	}

	public void Init()
	{
		gameObject.SetActive(value: true);
		int gridWidth = World.inst.GridWidth;
		int gridHeight = World.inst.GridHeight;
		travelRects[0] = Rect.MinMaxRect(0f - maxDistanceFromShore, 0f - maxDistanceFromShore, 0f - minDistanceFromShore, 0f - minDistanceFromShore);
		travelRects[1] = Rect.MinMaxRect((float)gridWidth + minDistanceFromShore, 0f - maxDistanceFromShore, (float)gridWidth + maxDistanceFromShore, 0f - minDistanceFromShore);
		travelRects[2] = Rect.MinMaxRect((float)gridWidth + minDistanceFromShore, (float)gridHeight + minDistanceFromShore, (float)gridWidth + maxDistanceFromShore, (float)gridHeight + maxDistanceFromShore);
		travelRects[3] = Rect.MinMaxRect(0f - maxDistanceFromShore, (float)gridHeight + minDistanceFromShore, 0f - minDistanceFromShore, (float)gridHeight + maxDistanceFromShore);
		currentRect = SRand.Range(0, 4);
		Vector2 center = travelRects[currentRect].center;
		transform.position = new Vector3(center.x, 0f, center.y);
		NewDestination();
	}

	private void Update()
	{
		if (Vector3.Magnitude(transform.position - destination) < 1f)
		{
			NewDestination();
		}
		float y = UpdateBreath();
		Vector3 position = Vector3.MoveTowards(transform.position, transform.position + transform.forward * 10f, Time.deltaTime * swimSpeed);
		position.y = y;
		transform.position = position;
		transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation((destination - transform.position).xz(), Vector3.up), Time.deltaTime * turnSpeed);
		Vector3 position2 = wake.transform.position;
		wake.transform.position = position2;
	}

	private void NewDestination()
	{
		currentRect = (currentRect + ((!(UnityEngine.Random.value > 0.5f)) ? 1 : (-1))) % travelRects.Length;
		if (currentRect < 0)
		{
			currentRect += travelRects.Length;
		}
		Rect rect = travelRects[currentRect];
		destination = new Vector3(SRand.Range(rect.xMin, rect.xMax), 0f, SRand.Range(rect.yMin, rect.yMax));
	}

	private float UpdateBreath()
	{
		if (breathInterval.Update(Time.deltaTime))
		{
			breathInterval.Enabled = false;
			breathTime.Enabled = true;
		}
		if (breathTime.Update(Time.deltaTime))
		{
			breathInterval.Enabled = true;
			breathTime.Enabled = false;
		}
		if (breathInterval.Enabled)
		{
			return baseDepth;
		}
		float num = Mathf.Sin(breathTime.CurrTime / breathTime.Duration * MathF.PI);
		if (num > 0.98f)
		{
			spout.Play();
		}
		else
		{
			spout.Stop();
		}
		if (num > 0.2f)
		{
			wake.Play();
		}
		else
		{
			wake.Stop();
		}
		if (onStartSpouting.CheckRising(spout.isPlaying))
		{
			SfxSystem.inst.PlayFromBank("WhaleSpout", transform.position);
		}
		if (onStartSurfacing.CheckRising(wake.isPlaying))
		{
			SfxSystem.inst.PlayFromBank("WhaleSurface", transform.position);
		}
		return Mathff.Lerp(baseDepth, breathDepth, num);
	}
}
