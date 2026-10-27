using System;
using System.Text.RegularExpressions;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using TMPro;
using UnityEngine;

public class SlabStatue : Statue
{
	[Serializable]
	public class SlabSaveData : SaveClass<SlabStatue, SlabSaveData>
	{
		private string text = "";

		private int chiselProgress;

		public override SlabSaveData Pack(SlabStatue s)
		{
			text = s.messageText;
			chiselProgress = s.chiselProgress;
			return this;
		}

		public override SlabStatue Unpack(SlabStatue s)
		{
			TextMeshPro component = s.transform.Find("Offset/statue_slab/Text").GetComponent<TextMeshPro>();
			s.messageText = text;
			component.SetText(s.messageText);
			s.chiselProgress = s.messageText.Length;
			s.SetCharactersInitialAlphas();
			s.UpdateSoundsAndParticles();
			return s;
		}
	}

	public string messageText = string.Empty;

	[HideInInspector]
	public int chiselProgress;

	public TextMeshPro tmp;

	public Localize localize;

	public ParticleSystem particles;

	public bool rewritable = true;

	public Color32[] characterColors = Array.Empty<Color32>();

	[HideInInspector]
	public string PreviewMaterialLoc = "Fundamental Brigade SDF SlabPreview";

	[HideInInspector]
	public string MaterialLoc = "Fundamental Brigade SDF For Slab";

	public EventInstance chiselLoop;

	private float CharacterProgress;

	private static Regex allBadWordsEnglish = new Regex("\\W*(anal|anus|ass fuck|ass hole|assfucker|asshole|assshole|bastard|bitch|boong|cock|cockfucker|cocksuck|cocksucker|coon|coonnass|cunt|cyberfuck|dick|douche|erotic|fags|faggot|fuck|fuckass|fuckhole|gook|homoerotic|jews|mother fucker|motherfuck|motherfucker|nazi|negro|nigger|orgasim|orgasm|penis|penisfucker|porn|porno|pornography|pussy|retard|shit|slut|son of a bitch|tits|viagra|whore)\\W*");

	private void Awake()
	{
		tmp = transform.Find("Offset/statue_slab/Text").GetComponent<TextMeshPro>();
		localize = tmp.gameObject.GetComponent<Localize>();
	}

	private void Update()
	{
		if (messageText.Length <= 0)
		{
			return;
		}
		if (chiselProgress < tmp.textInfo.characterCount)
		{
			CharacterProgress = Mathf.Clamp01(CharacterProgress + Time.deltaTime * 3f);
			if (CharacterProgress >= 1f)
			{
				SetCharacterAlpha(chiselProgress, characterColors[chiselProgress].a);
				UpdateMeshColors();
				chiselProgress++;
				SkipWhitespace();
				if (chiselProgress < tmp.textInfo.characterCount)
				{
					UpdateSoundsAndParticles();
				}
				CharacterProgress = 0f;
			}
		}
		else
		{
			chiselLoop.stop(STOP_MODE.IMMEDIATE);
		}
	}

	public void SetCharacterAlpha(int index, byte alpha)
	{
		Color32 color = tmp.textInfo.characterInfo[index].color;
		color.a = alpha;
		int materialReferenceIndex = tmp.textInfo.characterInfo[index].materialReferenceIndex;
		int vertexIndex = tmp.textInfo.characterInfo[index].vertexIndex;
		Color32[] colors = tmp.textInfo.meshInfo[materialReferenceIndex].colors32;
		colors[vertexIndex] = color;
		colors[vertexIndex + 1] = color;
		colors[vertexIndex + 2] = color;
		colors[vertexIndex + 3] = color;
	}

	public void SetCharactersInitialAlphas()
	{
		tmp.ForceMeshUpdate(ignoreActiveState: true);
		characterColors = new Color32[tmp.textInfo.characterCount];
		Debug.Log("Slab characters: " + tmp.textInfo.characterCount);
		for (int i = 0; i < tmp.textInfo.characterCount; i++)
		{
			characterColors[i] = tmp.textInfo.characterInfo[i].color;
			byte alpha = (byte)((i <= chiselProgress) ? characterColors[i].a : 0);
			SetCharacterAlpha(i, alpha);
		}
		UpdateMeshColors();
	}

	public void UpdateMeshColors()
	{
		tmp.UpdateVertexData(TMP_VertexDataUpdateFlags.All);
	}

	private void UpdateSoundsAndParticles()
	{
		if (chiselProgress < tmp.textInfo.characterCount)
		{
			chiselLoop.getPlaybackState(out var state);
			if (state == PLAYBACK_STATE.STOPPED)
			{
				chiselLoop = SfxSystem.inst.PlayFromBankIfVisible("chiselLoop", transform.position);
			}
			TMP_CharacterInfo tMP_CharacterInfo = tmp.textInfo.characterInfo[chiselProgress];
			Vector3 vector = (tMP_CharacterInfo.vertex_BL.position + tMP_CharacterInfo.vertex_BR.position + tMP_CharacterInfo.vertex_TL.position + tMP_CharacterInfo.vertex_TR.position) / 4f;
			chiselLoop.set3DAttributes(transform.TransformPoint(vector).To3DAttributes());
			particles.transform.localPosition = vector;
			ParticleSystem.MainModule main = particles.main;
			ParticleSystem.ShapeModule shape = particles.shape;
			ParticleSystem.EmissionModule emission = particles.emission;
			float num = tMP_CharacterInfo.vertex_BR.position.x - tMP_CharacterInfo.vertex_BL.position.x;
			float num2 = tMP_CharacterInfo.vertex_TL.position.y - tMP_CharacterInfo.vertex_BL.position.y;
			float num3 = 100f * num * num2 * 4f;
			main.maxParticles = (int)num3;
			emission.rateOverTime = num3;
			shape.scale = new Vector3(num, num2, 1f);
			particles.Play(withChildren: true);
		}
	}

	private void SkipWhitespace()
	{
		while (chiselProgress < tmp.textInfo.characterCount && char.IsWhiteSpace(tmp.textInfo.characterInfo[chiselProgress].character))
		{
			chiselProgress++;
		}
	}

	public void SetPreviewText(string message)
	{
		messageText = string.Empty;
		chiselLoop.stop(STOP_MODE.IMMEDIATE);
		localize.SecondaryTerm = PreviewMaterialLoc;
		tmp.text = CleanMessage(message);
	}

	public void StartChiseling(string message)
	{
		localize.SecondaryTerm = MaterialLoc;
		messageText = CleanMessage(message);
		tmp.text = messageText;
		chiselProgress = 0;
		SkipWhitespace();
		SetCharactersInitialAlphas();
		UpdateSoundsAndParticles();
	}

	public static string CleanMessage(string message)
	{
		message = allBadWordsEnglish.Replace(message, "");
		return message;
	}
}
