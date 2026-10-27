using FMODUnity;
using UnityEngine;

public class GodDisplay : MonoBehaviour
{
	public enum State
	{
		Uninitialized,
		Appearing,
		Appeared,
		Disappearing,
		Disappeared
	}

	public GameObject[] columns;

	public GameObject[] gods;

	private State status;

	internal float transition;

	public Vector3 modelDisplayOffset;

	public Light spotLight1;

	public Light spotLight2;

	public ParticleSystem particles;

	private int dedicatedIdx = -1;

	public State Status
	{
		get
		{
			return status;
		}
		set
		{
			if (value != status)
			{
				transition = 0f;
			}
			status = value;
		}
	}

	public void ShowAt(Vector3 pos, int dedication)
	{
		if (status == State.Disappearing)
		{
			for (int i = 0; i < gods.Length; i++)
			{
				gods[i].transform.localPosition = gods[i].GetComponent<GodShaderDriver>().oldLocalPos;
				gods[i].transform.localRotation = gods[i].GetComponent<GodShaderDriver>().oldLocalRot;
			}
		}
		for (int j = 0; j < gods.Length; j++)
		{
			gods[j].GetComponent<GodShaderDriver>().oldLocalPos = gods[j].transform.localPosition;
			gods[j].GetComponent<GodShaderDriver>().oldLocalRot = gods[j].transform.localRotation;
		}
		spotLight1.intensity = 0f;
		spotLight2.intensity = 0f;
		dedicatedIdx = dedication;
		transform.position = pos;
		Vector3 vector = (pos - Cam.inst.transform.position).xz();
		transform.rotation = Quaternion.LookRotation(vector.normalized, Vector3.up);
		for (int k = 0; k < columns.Length; k++)
		{
			Vector3 pos2 = columns[k].transform.position;
			TerrainGen.inst.GetGroundHeight(ref pos2);
			columns[k].transform.position = pos2;
		}
		for (int l = 0; l < gods.Length; l++)
		{
			Vector3 pos3 = gods[l].transform.position;
			TerrainGen.inst.GetGroundHeight(ref pos3);
			gods[l].transform.position = pos3 + modelDisplayOffset;
		}
		for (int m = 0; m < gods.Length; m++)
		{
			if (dedicatedIdx == -1)
			{
				gods[m].GetComponent<GodShaderDriver>().ShowGod();
				gods[m].SetActive(value: true);
				continue;
			}
			if (dedicatedIdx != m)
			{
				gods[m].GetComponent<GodShaderDriver>().SetHidden();
				gods[m].SetActive(value: false);
				continue;
			}
			gods[m].GetComponent<GodShaderDriver>().ShowGod(doDelay: false);
			gods[m].transform.localPosition = gods[2].transform.localPosition;
			gods[m].transform.localRotation = gods[2].transform.localRotation;
			gods[m].SetActive(value: true);
		}
		Status = State.Appearing;
		gameObject.SetActive(value: true);
		RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_appear", pos);
		particles.Play();
	}

	public void ShowPillars(bool show)
	{
		for (int i = 0; i < columns.Length; i++)
		{
			columns[i].GetComponent<GodPillarDriver>().Showing = show;
		}
	}

	public void CompleteTaskAnim()
	{
		gods[dedicatedIdx].GetComponentInChildren<Animator>().CrossFade("taskComplete", 0.15f);
	}

	public void CompleteTaskAnim(int idx)
	{
		gods[idx].GetComponentInChildren<Animator>().CrossFade("taskComplete", 0.15f);
	}

	public void Hide()
	{
		if (status == State.Uninitialized)
		{
			return;
		}
		particles.Stop();
		if (status == State.Disappeared)
		{
			return;
		}
		Status = State.Disappearing;
		for (int i = 0; i < gods.Length; i++)
		{
			GodShaderDriver component = gods[i].GetComponent<GodShaderDriver>();
			if (component.shown)
			{
				component.HideGod();
			}
		}
		RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_disappear", transform.position);
		ShowPillars(show: false);
	}

	public void SelectGod(int s)
	{
		dedicatedIdx = s;
		if (dedicatedIdx == -1)
		{
			return;
		}
		for (int i = 0; i < gods.Length; i++)
		{
			if (i != dedicatedIdx)
			{
				gods[i].GetComponent<GodShaderDriver>().HideGod();
			}
		}
	}

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		transition = Mathf.Clamp01(transition + unscaledDeltaTime * 0.66f);
		switch (Status)
		{
		case State.Appearing:
			spotLight1.intensity = Mathf.Lerp(0f, 1.5f, transition);
			spotLight2.intensity = Mathf.Lerp(0f, 1.3f, transition);
			if (transition >= 1f)
			{
				Status = State.Appeared;
			}
			break;
		case State.Disappearing:
			spotLight1.intensity = Mathf.Lerp(1.5f, 0f, transition);
			spotLight2.intensity = Mathf.Lerp(1.3f, 0f, transition);
			if (transition >= 1f)
			{
				Status = State.Disappeared;
				for (int i = 0; i < gods.Length; i++)
				{
					gods[i].transform.localPosition = gods[i].GetComponent<GodShaderDriver>().oldLocalPos;
					gods[i].transform.localRotation = gods[i].GetComponent<GodShaderDriver>().oldLocalRot;
					gods[i].SetActive(value: false);
				}
			}
			break;
		}
	}
}
