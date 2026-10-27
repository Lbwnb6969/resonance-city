using System;
using System.Collections.Generic;
using Assets;
using UnityEngine;

public class GladiatorVisual : MonoBehaviour
{
	[Serializable]
	public class Def
	{
		public int headIdx;

		public int noseIdx;

		public int hairIdx;

		public int eyesIdx;

		public int earsIdx;

		public int browsIdx;

		public int facialHairIdx;

		public int bodyIdx;

		public int shoulderArmorRIdx;

		public SerializableVector3 bodyScale;

		public SerializableVector3 noseScale;
	}

	public GameObject secutorHandR;

	public GameObject secutorHandL;

	public GameObject secutorHead;

	public GameObject retiariusHandR;

	public GameObject retiariusHandL;

	public GameObject retiarusHead;

	public GameObject bestiariusHandR;

	public GameObject bestiariusHandL;

	public GameObject bestiariusHead;

	public GameObject head;

	public GameObject nose;

	public GameObject hair;

	public GameObject eyes;

	public GameObject brows;

	public GameObject ear0;

	public GameObject ear1;

	public GameObject facialHair;

	public GameObject body;

	public GameObject shoulderArmorR;

	public List<Mesh> heads;

	public List<Mesh> noses;

	public List<Mesh> hairStyles;

	public List<Mesh> eyeStyles;

	public List<Mesh> browStyles;

	public List<Mesh> ears;

	public List<Mesh> beards;

	public List<Mesh> bodies;

	public List<Mesh> shoulderArmorsR;

	internal ObjectHighlighter highlight;

	internal Def currDef;

	internal ColosseumRound.Role currRole;

	private void RebuildOutlines()
	{
		highlight?.Release();
		List<MeshRenderer> list = new List<MeshRenderer>();
		GetComponentsInChildren(list);
		highlight = ObjectHighlighter.SetupOutlines(gameObject, list, null);
	}

	private void OnEnable()
	{
		SetRole(ColosseumRound.Role.None);
	}

	public Def GenerateDef()
	{
		Def def = new Def();
		def.headIdx = SRand.Range(0, heads.Count);
		def.noseIdx = SRand.Range(0, noses.Count);
		def.noseScale = new Vector3(SRand.Range(1f, 1.2f), SRand.Range(1f, 1.2f), SRand.Range(1f, 1.2f));
		def.hairIdx = SRand.Range(0, hairStyles.Count);
		def.eyesIdx = SRand.Range(0, eyeStyles.Count);
		def.browsIdx = SRand.Range(0, browStyles.Count);
		def.bodyIdx = SRand.Range(0, bodies.Count);
		if (SRand.Range(0, 100) > 70)
		{
			def.facialHairIdx = SRand.Range(0, beards.Count);
		}
		else
		{
			def.facialHairIdx = -1;
		}
		def.earsIdx = SRand.Range(0, ears.Count);
		def.shoulderArmorRIdx = SRand.Range(0, shoulderArmorsR.Count);
		def.bodyScale = new Vector3(SRand.Range(1f, 1.1f), SRand.Range(1f, 1.1f), SRand.Range(1f, 1.1f));
		return def;
	}

	public void ApplyDef(Def def)
	{
		currDef = def;
		head.GetComponent<MeshFilter>().mesh = heads[def.headIdx];
		nose.GetComponent<MeshFilter>().mesh = noses[def.noseIdx];
		nose.transform.localScale = def.noseScale;
		hair.GetComponent<MeshFilter>().mesh = hairStyles[def.hairIdx];
		eyes.GetComponent<MeshFilter>().mesh = eyeStyles[def.eyesIdx];
		brows.GetComponent<MeshFilter>().mesh = browStyles[def.browsIdx];
		body.GetComponent<MeshFilter>().mesh = bodies[def.bodyIdx];
		shoulderArmorR.GetComponent<MeshFilter>().mesh = shoulderArmorsR[def.shoulderArmorRIdx];
		if (def.facialHairIdx != -1)
		{
			facialHair.GetComponent<MeshFilter>().mesh = beards[def.facialHairIdx];
			facialHair.SetActive(value: true);
		}
		else
		{
			facialHair.SetActive(value: false);
		}
		ear0.GetComponent<MeshFilter>().mesh = ears[def.earsIdx];
		ear1.GetComponent<MeshFilter>().mesh = ears[def.earsIdx];
		transform.localScale = def.bodyScale;
		RebuildOutlines();
	}

	public void GenerateFace()
	{
		Def def = GenerateDef();
		ApplyDef(def);
	}

	private void OnDestroy()
	{
		if (highlight != null)
		{
			highlight.Release();
		}
		highlight = null;
	}

	private void Update()
	{
		if (Input.GetKeyDown(KeyCode.L))
		{
			GenerateFace();
		}
	}

	private void HideAllRole()
	{
		if ((bool)ear0)
		{
			ear0.SetActive(value: false);
		}
		if ((bool)ear1)
		{
			ear1.SetActive(value: false);
		}
		if ((bool)hair)
		{
			hair.SetActive(value: false);
		}
		if ((bool)secutorHandL)
		{
			secutorHandL.SetActive(value: false);
		}
		if ((bool)secutorHandR)
		{
			secutorHandR.SetActive(value: false);
		}
		if ((bool)secutorHead)
		{
			secutorHead.SetActive(value: false);
		}
		if ((bool)retiariusHandL)
		{
			retiariusHandL.SetActive(value: false);
		}
		if ((bool)retiariusHandR)
		{
			retiariusHandR.SetActive(value: false);
		}
		if ((bool)bestiariusHandR)
		{
			bestiariusHandR.SetActive(value: false);
		}
		if ((bool)bestiariusHandL)
		{
			bestiariusHandL.SetActive(value: false);
		}
		if ((bool)bestiariusHead)
		{
			bestiariusHead.SetActive(value: false);
		}
	}

	internal void GetEquipped(List<GameObject> into)
	{
		AddIfEquipped(into, secutorHandR);
		AddIfEquipped(into, secutorHandL);
		AddIfEquipped(into, secutorHead);
		AddIfEquipped(into, retiariusHandR);
		AddIfEquipped(into, retiariusHandL);
		AddIfEquipped(into, retiarusHead);
		AddIfEquipped(into, bestiariusHandR);
		AddIfEquipped(into, bestiariusHandL);
		AddIfEquipped(into, bestiariusHead);
	}

	private static void AddIfEquipped(List<GameObject> into, GameObject go)
	{
		if ((bool)go && go.activeSelf)
		{
			into.Add(go);
		}
	}

	internal void ShowBareHead()
	{
		ear0.SetActive(value: true);
		ear1.SetActive(value: true);
		hair.SetActive(value: true);
	}

	internal void SetRole(ColosseumRound.Role role)
	{
		currRole = role;
		HideAllRole();
		switch (role)
		{
		case ColosseumRound.Role.None:
			if ((bool)ear0)
			{
				ear0.SetActive(value: true);
			}
			if ((bool)ear1)
			{
				ear1.SetActive(value: true);
			}
			if ((bool)hair)
			{
				hair.SetActive(value: true);
			}
			break;
		case ColosseumRound.Role.Retiarus:
			retiariusHandL.SetActive(value: true);
			retiariusHandR.SetActive(value: true);
			ear0.SetActive(value: true);
			ear1.SetActive(value: true);
			hair.SetActive(value: true);
			break;
		case ColosseumRound.Role.Secutor:
			secutorHandL.SetActive(value: true);
			secutorHandR.SetActive(value: true);
			secutorHead.SetActive(value: true);
			break;
		case ColosseumRound.Role.Bestiarius:
			bestiariusHandL.SetActive(value: true);
			bestiariusHandR.SetActive(value: true);
			bestiariusHead.SetActive(value: true);
			break;
		}
		RebuildOutlines();
	}
}
