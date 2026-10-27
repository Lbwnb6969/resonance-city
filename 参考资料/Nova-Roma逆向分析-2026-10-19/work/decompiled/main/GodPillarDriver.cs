using UnityEngine;

public class GodPillarDriver : MonoBehaviour
{
	public Material godMaterial;

	public Transform chamStart;

	public Transform chamEnd;

	private float t;

	private bool showing;

	public bool Showing
	{
		get
		{
			return showing;
		}
		set
		{
			if (value != showing)
			{
				godMaterial.SetVector("_ChamStart", chamStart.transform.position);
				godMaterial.SetVector("_ChamEnd", chamEnd.transform.position);
				Transform transform = chamStart;
				Transform transform2 = chamEnd;
				chamEnd = transform;
				chamStart = transform2;
			}
			showing = value;
		}
	}

	private void Start()
	{
		godMaterial = Object.Instantiate(godMaterial);
		transform.GetChild(0).GetComponent<MeshRenderer>().material = godMaterial;
		godMaterial.SetVector("_ChamStart", chamStart.transform.position);
		godMaterial.SetVector("_ChamEnd", chamEnd.transform.position);
		godMaterial.SetVector("_FeetLocation", new Vector3(0f, -1000f, 0f));
	}

	private void Update()
	{
		float num = Time.unscaledDeltaTime * 0.5f;
		if (Showing)
		{
			t += num;
		}
		else
		{
			t -= num;
		}
		t = Mathf.Clamp01(t);
		godMaterial.SetFloat("_ChamAmount", t);
	}

	private void ToggleVisibility()
	{
		Showing = !Showing;
	}
}
