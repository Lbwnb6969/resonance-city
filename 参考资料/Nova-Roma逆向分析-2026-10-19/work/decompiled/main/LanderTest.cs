using System.Collections.Generic;
using UnityEngine;

public class LanderTest : MonoBehaviour, ICamTrackable
{
	private SplineTraveler<object> traverler;

	private CatmullRomSpline<object> spline = new CatmullRomSpline<object>(looping: false);

	public Transform[] wayPoints;

	private List<GameObject> landingMarkers = new List<GameObject>();

	public GameObject landingMarkerSquare;

	public float markerDist;

	private List<GameObject> landingMarkersCorner = new List<GameObject>();

	public GameObject landingMarkerSquareCorner;

	public float markerDistCorner = 1f;

	public ParticleSystem[] boosters;

	public GameObject[] supports;

	public float landingMakrerScaleMod = 1f;

	private float origEmission;

	public ParticleSystem groundPuff;

	public float groundPuffHeight = 10f;

	public float speed = 10f;

	public float decel = 1f;

	private float currSpeed = 1f;

	public AnimationCurve phiCurve;

	public AnimationCurve zoomCurve;

	public float shakeMag = 1f;

	public float startLandingTime = 0.8f;

	public float supportRotateTime = 1f;

	private float currSupportRotateTime;

	private float totalRot;

	private void Start()
	{
		for (int i = 0; i < wayPoints.Length; i++)
		{
			spline.AddControlPoint(wayPoints[i].position);
		}
		traverler = new SplineTraveler<object>(spline);
		RefreshMarkers();
		origEmission = groundPuff.emission.rateOverTime.constant;
	}

	private void RefreshMarkers()
	{
		for (int i = 0; i < landingMarkers.Count; i++)
		{
			Object.Destroy(landingMarkers[i]);
		}
		landingMarkers.Clear();
		float num = landingMakrerScaleMod;
		traverler.Reset();
		while (!traverler.AtEnd())
		{
			GameObject gameObject = Object.Instantiate(landingMarkerSquare);
			gameObject.transform.position = traverler.Travel(markerDist);
			gameObject.transform.rotation = Quaternion.LookRotation(-traverler.GetForward(), new Vector3(0f, 0f, 1f)) * Quaternion.Euler(90f, 0f, 0f);
			gameObject.transform.localScale *= num;
			num *= 0.8f;
			landingMarkers.Add(gameObject);
		}
		traverler.Reset();
		for (int j = 0; j < landingMarkersCorner.Count; j++)
		{
			Object.Destroy(landingMarkersCorner[j]);
		}
		landingMarkersCorner.Clear();
		num = landingMakrerScaleMod;
		traverler.Reset();
		while (!traverler.AtEnd())
		{
			GameObject gameObject2 = Object.Instantiate(landingMarkerSquareCorner);
			gameObject2.transform.position = traverler.Travel(markerDistCorner);
			gameObject2.transform.rotation = Quaternion.LookRotation(-traverler.GetForward(), new Vector3(0f, 0f, 1f)) * Quaternion.Euler(90f, 0f, 0f);
			gameObject2.transform.localScale *= num;
			num *= 0.985f;
			landingMarkersCorner.Add(gameObject2);
		}
		traverler.Reset();
	}

	private void Update()
	{
		float deltaTime = Time.deltaTime;
		float num = deltaTime * currSpeed;
		currSpeed -= decel * deltaTime;
		transform.position = traverler.Travel(num);
		transform.rotation = Quaternion.LookRotation(-traverler.GetForward(), new Vector3(0f, 0f, 1f)) * Quaternion.Euler(90f, 0f, 0f);
		if (!traverler.AtEnd())
		{
			totalRot += deltaTime * 10f;
		}
		transform.Rotate(new Vector3(0f, totalRot, 0f), Space.Self);
		if (Input.GetKeyDown(KeyCode.H))
		{
			currSupportRotateTime = 0f;
			currSpeed = speed;
			RefreshMarkers();
			traverler.Reset();
			for (int i = 0; i < supports.Length; i++)
			{
				supports[i].transform.localRotation = Quaternion.identity;
			}
		}
		float tileHeight = TerrainGen.inst.GetTileHeight(World.inst.GetCellData(transform.position));
		float num2 = transform.position.y - tileHeight;
		if (num2 < groundPuffHeight && !traverler.AtEnd())
		{
			if (!groundPuff.isPlaying)
			{
				groundPuff.Play();
			}
			ParticleSystem.EmissionModule emission = groundPuff.emission;
			emission.rateOverTime = Mathf.Max(origEmission * 0.25f, origEmission * Mathf.Sqrt(1f - num2 / groundPuffHeight));
		}
		else if (groundPuff.isPlaying)
		{
			groundPuff.Stop();
		}
		if (traverler.AtEnd())
		{
			for (int j = 0; j < boosters.Length; j++)
			{
				boosters[j].Stop();
			}
		}
		else if (!boosters[0].isPlaying)
		{
			for (int k = 0; k < boosters.Length; k++)
			{
				boosters[k].Play();
			}
		}
		if (traverler.GetTotalTime() > startLandingTime && !traverler.AtEnd() && currSupportRotateTime < supportRotateTime)
		{
			currSupportRotateTime += deltaTime;
			for (int l = 0; l < supports.Length; l++)
			{
				Vector3 normalized = (supports[l].transform.position - transform.position).normalized;
				normalized = -Vector3.Cross(normalized, transform.up);
				supports[l].transform.Rotate(normalized, 1f * deltaTime * 57.29578f, Space.World);
			}
		}
		groundPuff.transform.position = new Vector3(transform.position.x, tileHeight, transform.position.z);
		Cam.inst.SetPhi(phiCurve.Evaluate(traverler.GetTotalTime()));
		Cam.inst.desiredDist = zoomCurve.Evaluate(traverler.GetTotalTime());
		Cam.inst.Track(this);
		if (!traverler.AtEnd())
		{
			Cam.inst.Shake(new Vector3(SRand.Range(-1f, 1f), SRand.Range(-1f, 1f), SRand.Range(-1f, 1f)) * shakeMag);
		}
	}

	public Vector3 GetDesiredTrackingPos()
	{
		return transform.position;
	}
}
