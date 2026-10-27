using System;
using System.Collections.Generic;
using FMODUnity;
using UnityEngine;

public class GodDisplayIndividual : MonoBehaviour
{
	public delegate void OnClickDelegate();

	public enum State
	{
		Idle,
		Appearing,
		Appeared,
		Disappearing,
		Disappeared
	}

	public OnClickDelegate onClick;

	public GameObject[] gods;

	private State status;

	internal float transition;

	public Vector3 modelDisplayOffset;

	public Light spotLight1;

	public Light spotLight2;

	private int dedicatedIdx = -1;

	[NonSerialized]
	public static GodDisplayIndividual hovered;

	public static List<GodDisplayIndividual> activeGods = new List<GodDisplayIndividual>();

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

	private void Awake()
	{
		for (int i = 0; i < gods.Length; i++)
		{
			gods[i].gameObject.SetActive(value: false);
		}
	}

	public GodInfoUI GetGodInfo()
	{
		return gods[dedicatedIdx].GetComponent<GodInfoUI>();
	}

	public void ShowAt(Vector3 pos, int dedication)
	{
		if (status != State.Appearing && status != State.Appeared)
		{
			spotLight1.intensity = 0f;
			spotLight2.intensity = 0f;
			dedicatedIdx = dedication;
			for (int i = 0; i < gods.Length; i++)
			{
				gods[i].gameObject.SetActive(i == dedicatedIdx);
			}
			Vector3 vector = (pos - Cam.inst.transform.position).xz();
			transform.rotation = Quaternion.LookRotation(-vector.normalized, Vector3.up);
			transform.position = pos;
			Vector3 pos2 = gods[dedicatedIdx].transform.position;
			TerrainGen.inst.GetGroundHeight(ref pos2);
			gods[dedicatedIdx].transform.position = pos2 + modelDisplayOffset;
			gods[dedicatedIdx].GetComponent<GodShaderDriver>().ShowGod();
			status = State.Appearing;
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_appear", pos);
		}
	}

	public void CompleteTaskAnim()
	{
		gods[dedicatedIdx].GetComponentInChildren<Animator>().CrossFade("taskComplete", 0.15f);
	}

	public void Hide()
	{
		if (status != State.Disappeared && status != State.Disappearing)
		{
			Status = State.Disappearing;
			GodShaderDriver component = gods[dedicatedIdx].GetComponent<GodShaderDriver>();
			if (component.shown)
			{
				component.HideGod();
			}
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_gods_disappear", transform.position);
		}
	}

	public static void RaycastAll()
	{
		_ = Time.unscaledDeltaTime;
		Ray ray = PointingSystem.GetRay();
		hovered = null;
		float num = float.MaxValue;
		for (int i = 0; i < activeGods.Count; i++)
		{
			if (activeGods[i].IsVisible() && activeGods[i].GetGodInfo().Raycast(ray, out var hit) && hit.distance < num)
			{
				num = hit.distance;
				hovered = activeGods[i];
			}
		}
		if ((bool)hovered)
		{
			hovered.GetGodInfo().highlight.SetOutlineImmediate(0);
		}
	}

	public static bool WillClick()
	{
		return hovered;
	}

	public static void DoClick()
	{
		if ((bool)hovered)
		{
			hovered.Click();
		}
	}

	public void Click()
	{
		SfxSystem.PlayUiSelect();
		onClick();
	}

	public bool IsVisible()
	{
		return status == State.Appeared;
	}

	private void OnEnable()
	{
		activeGods.Add(this);
	}

	private void OnDisable()
	{
		activeGods.Remove(this);
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
					gods[i].SetActive(value: false);
				}
			}
			break;
		}
	}
}
