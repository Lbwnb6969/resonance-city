using UnityEngine;

public class GodShaderDriver : MonoBehaviour
{
	public Material godMaterial;

	public Transform chamStart;

	public Transform chamEnd;

	public ParticleSystem godBlinkIn;

	public ParticleSystem godBlinkOut;

	private ParticleSystem chamFollow;

	internal Vector3 oldLocalPos;

	internal Quaternion oldLocalRot;

	private float cham;

	public float chamInSpeed = 0.66f;

	public float chamOutSpeed = 0.66f;

	public bool shown;

	private float bloodOverdriveTarget = 10f;

	private Vector3 scaleTarget = new Vector3(16f, 16f, 16f);

	private float origOpacity = 0.7f;

	public Material godMaterialDisabled;

	private float delay;

	private float delayTime;

	public void SetHighlight(bool h)
	{
		if (h)
		{
			godMaterial.SetFloat("_Opacity", 0.8f);
		}
		else
		{
			godMaterial.SetFloat("_Opacity", origOpacity);
		}
	}

	private void Start()
	{
		chamFollow = Object.Instantiate(GodUI.inst.chamFollowFX).GetComponent<ParticleSystem>();
		delay = SRand.Range(0f, 0.25f);
		chamInSpeed += SRand.Range(0f, 0.25f);
		chamOutSpeed += SRand.Range(0f, 0.25f);
		godMaterial = Object.Instantiate(godMaterial);
		godMaterialDisabled = Object.Instantiate(godMaterialDisabled);
		origOpacity = godMaterial.GetFloat("_Opacity");
		if ((bool)transform.GetChild(0).GetComponent<MeshRenderer>())
		{
			SetAllMaterials(transform.GetChild(0).GetComponent<MeshRenderer>(), godMaterial);
		}
		if (transform.GetChild(0).childCount > 1 && (bool)transform.GetChild(0).GetChild(1).GetComponent<SkinnedMeshRenderer>())
		{
			transform.GetChild(0).GetChild(1).GetComponent<SkinnedMeshRenderer>()
				.material = godMaterial;
		}
		if (transform.GetChild(0).childCount > 1 && (bool)transform.GetChild(0).GetChild(0).GetComponent<SkinnedMeshRenderer>())
		{
			transform.GetChild(0).GetChild(0).GetComponent<SkinnedMeshRenderer>()
				.material = godMaterial;
		}
	}

	private static void SetAllMaterials(Renderer r, Material m)
	{
		Material[] sharedMaterials = r.sharedMaterials;
		for (int i = 0; i < sharedMaterials.Length; i++)
		{
			sharedMaterials[i] = m;
		}
		r.sharedMaterials = sharedMaterials;
	}

	internal void SetDisabled(bool v)
	{
		if (v)
		{
			if ((bool)transform.GetChild(0).GetComponent<MeshRenderer>())
			{
				SetAllMaterials(transform.GetChild(0).GetComponent<MeshRenderer>(), godMaterialDisabled);
			}
			if (transform.GetChild(0).childCount > 1 && (bool)transform.GetChild(0).GetChild(1).GetComponent<SkinnedMeshRenderer>())
			{
				transform.GetChild(0).GetChild(1).GetComponent<SkinnedMeshRenderer>()
					.material = godMaterialDisabled;
			}
			if (transform.GetChild(0).childCount > 1 && (bool)transform.GetChild(0).GetChild(0).GetComponent<SkinnedMeshRenderer>())
			{
				transform.GetChild(0).GetChild(0).GetComponent<SkinnedMeshRenderer>()
					.material = godMaterialDisabled;
			}
		}
		else
		{
			if ((bool)transform.GetChild(0).GetComponent<MeshRenderer>())
			{
				SetAllMaterials(transform.GetChild(0).GetComponent<MeshRenderer>(), godMaterial);
			}
			if (transform.GetChild(0).childCount > 1 && (bool)transform.GetChild(0).GetChild(0).GetComponent<SkinnedMeshRenderer>())
			{
				transform.GetChild(0).GetChild(0).GetComponent<SkinnedMeshRenderer>()
					.material = godMaterial;
			}
		}
	}

	private void Update()
	{
		godMaterial.SetVector("_ChamStart", chamStart.transform.position);
		godMaterial.SetVector("_ChamEnd", chamEnd.transform.position);
		godMaterialDisabled.SetVector("_ChamStart", chamStart.transform.position);
		godMaterialDisabled.SetVector("_ChamEnd", chamEnd.transform.position);
		Vector3 position = transform.GetChild(0).transform.position;
		godMaterial.SetVector("_FeetLocation", position);
		godMaterialDisabled.SetVector("_FeetLocation", position);
		delayTime += Time.unscaledDeltaTime;
		if (delayTime > delay)
		{
			if (shown)
			{
				cham = Mathf.Clamp(cham + Time.unscaledDeltaTime * chamInSpeed, 0f, 1f);
			}
			else
			{
				cham = Mathf.Clamp(cham - Time.unscaledDeltaTime * chamOutSpeed, 0f, 1f);
			}
			godMaterial.SetFloat("_Opacity", Mathf.Lerp(0f, origOpacity, cham));
		}
		godMaterial.SetFloat("_ChamAmount", cham);
		godMaterialDisabled.SetFloat("_ChamAmount", cham);
		if (!chamFollow)
		{
			return;
		}
		if (cham <= 1f && cham > 0.1f)
		{
			if (!chamFollow.isPlaying)
			{
				chamFollow.Play();
			}
			chamFollow.transform.position = Vector3.Lerp(chamStart.position, chamEnd.position, cham);
		}
		else if (chamFollow.isPlaying)
		{
			chamFollow.Stop();
		}
	}

	public void ShowGod(bool doDelay = true)
	{
		if (!shown)
		{
			if (doDelay)
			{
				delayTime = 0f;
			}
			else
			{
				delayTime = delay;
			}
			cham = 0f;
		}
		shown = true;
	}

	public void HideGod()
	{
		if (shown)
		{
			delayTime = 0f;
		}
		shown = false;
	}

	public void SetHidden()
	{
		delayTime = delay;
		cham = 0f;
		shown = false;
	}
}
