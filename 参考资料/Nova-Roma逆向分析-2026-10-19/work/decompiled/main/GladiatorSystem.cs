using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets;
using I2.Loc;
using UnityEngine;

public class GladiatorSystem : MonoBehaviour
{
	[Serializable]
	public class GladiatorSystemSaveData : SaveClass<GladiatorSystem, GladiatorSystemSaveData>
	{
		public List<Gladiator.GladiatorSaveData> gladiatorsData;

		public int nextGladiatorId;

		public override GladiatorSystemSaveData Pack(GladiatorSystem obj)
		{
			gladiatorsData = new List<Gladiator.GladiatorSaveData>();
			foreach (Gladiator value in obj.gladiators.Values)
			{
				gladiatorsData.Add(new Gladiator.GladiatorSaveData().Pack(value));
			}
			nextGladiatorId = obj.nextGladiatorId;
			return this;
		}

		public override GladiatorSystem Unpack(GladiatorSystem obj)
		{
			obj.gladiators.Clear();
			if (gladiatorsData != null)
			{
				foreach (Gladiator.GladiatorSaveData gladiatorsDatum in gladiatorsData)
				{
					Gladiator gladiator = gladiatorsDatum.Unpack(null);
					obj.gladiators[gladiator.gladiatorId] = gladiator;
				}
			}
			obj.nextGladiatorId = nextGladiatorId;
			return obj;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			gladiatorsData = new List<Gladiator.GladiatorSaveData>();
			nextGladiatorId = 1;
		}
	}

	public static GladiatorSystem inst;

	private Dictionary<int, Gladiator> gladiators = new Dictionary<int, Gladiator>();

	private int nextGladiatorId = 1;

	[Header("Data")]
	public TrainingCourse[] trainingCourses;

	public GladiatorTitle[] titles;

	[Header("Appearance Palettes")]
	public Color[] skinPalette = new Color[5]
	{
		new Color(0.96f, 0.87f, 0.7f),
		new Color(0.87f, 0.72f, 0.53f),
		new Color(0.76f, 0.57f, 0.38f),
		new Color(0.55f, 0.38f, 0.24f),
		new Color(0.4f, 0.26f, 0.15f)
	};

	public Color[] hairPalette = new Color[5]
	{
		new Color(0.15f, 0.1f, 0.05f),
		new Color(0.35f, 0.2f, 0.1f),
		new Color(0.6f, 0.4f, 0.15f),
		new Color(0.8f, 0.6f, 0.3f),
		new Color(0.25f, 0.25f, 0.25f)
	};

	public Color[] tintPalette = new Color[7]
	{
		new Color(0.6f, 0.15f, 0.15f),
		new Color(0.15f, 0.15f, 0.6f),
		new Color(0.15f, 0.5f, 0.15f),
		new Color(0.8f, 0.7f, 0.3f),
		new Color(0.5f, 0.25f, 0.5f),
		new Color(0.85f, 0.85f, 0.85f),
		new Color(0.2f, 0.2f, 0.2f)
	};

	private static readonly string[] gladiatorEpithetKeys = new string[10] { "gladiator_epithet_0", "gladiator_epithet_1", "gladiator_epithet_2", "gladiator_epithet_3", "gladiator_epithet_4", "gladiator_epithet_5", "gladiator_epithet_6", "gladiator_epithet_7", "gladiator_epithet_8", "gladiator_epithet_9" };

	public List<BeastTemplate> beastDefs;

	public event Action<Gladiator> OnGladiatorCreated;

	public event Action<Gladiator> OnGladiatorRemoved;

	public event Action<Gladiator> OnGladiatorRetired;

	public BeastTemplate GetBeastDefByName(string name)
	{
		for (int i = 0; i < beastDefs.Count; i++)
		{
			if (beastDefs[i].templateId == name)
			{
				return beastDefs[i];
			}
		}
		return null;
	}

	private void Awake()
	{
		inst = this;
		LoadData();
	}

	private void LoadData()
	{
	}

	public Gladiator CreateGladiator(Guid ownerSchoolBuildingId)
	{
		Gladiator gladiator = new Gladiator
		{
			gladiatorId = nextGladiatorId++,
			name = GenerateRandomName(),
			isNameCustom = false,
			fame = UnityEngine.Random.Range(0, 1),
			alignment = (GladiatorAlignment)UnityEngine.Random.Range(0, 3),
			skills = GenerateRandomSkills(),
			fatigueTier = 0,
			bravery = UnityEngine.Random.Range(0.3f, 0.7f),
			crowdFavor = UnityEngine.Random.Range(0.3f, 0.7f),
			ownerSchoolBuildingId = ownerSchoolBuildingId
		};
		gladiator.skills.GetHighestSkill(out var highestType);
		gladiator.primarySkill = highestType;
		gladiators[gladiator.gladiatorId] = gladiator;
		OnGladiatorCreated?.Invoke(gladiator);
		return gladiator;
	}

	public Gladiator GetGladiator(int gladiatorId)
	{
		gladiators.TryGetValue(gladiatorId, out var value);
		return value;
	}

	public IEnumerable<Gladiator> GetAllGladiators()
	{
		return gladiators.Values;
	}

	public int GetGladiatorCount()
	{
		return gladiators.Count;
	}

	public void RemoveGladiator(int gladiatorId)
	{
		if (gladiators.TryGetValue(gladiatorId, out var value))
		{
			gladiators.Remove(gladiatorId);
			OnGladiatorRemoved?.Invoke(value);
		}
	}

	public bool RetireGladiator(int gladiatorId)
	{
		Gladiator gladiator = GetGladiator(gladiatorId);
		if (gladiator == null || !gladiator.CanRetire())
		{
			return false;
		}
		gladiators.Remove(gladiatorId);
		OnGladiatorRetired?.Invoke(gladiator);
		return true;
	}

	public string GenerateRandomName()
	{
		PersonProfile randomProfile = PersonProfile.GetRandomProfile();
		randomProfile.Type = 1;
		string text = randomProfile.Name;
		if (UnityEngine.Random.value < 0.3f)
		{
			return string.Format(LocalizationManager.GetTranslation(gladiatorEpithetKeys[UnityEngine.Random.Range(0, gladiatorEpithetKeys.Length)]), text);
		}
		return text;
	}

	public GladiatorSkills GenerateRandomSkills()
	{
		GladiatorSkills result = new GladiatorSkills
		{
			bestiarius = UnityEngine.Random.Range(0, 4),
			retiarius = UnityEngine.Random.Range(0, 4),
			secutor = UnityEngine.Random.Range(0, 4)
		};
		switch (UnityEngine.Random.Range(0, 3))
		{
		case 0:
			result.bestiarius = Mathf.Max(result.bestiarius, UnityEngine.Random.Range(2, 5));
			break;
		case 1:
			result.retiarius = Mathf.Max(result.retiarius, UnityEngine.Random.Range(2, 5));
			break;
		case 2:
			result.secutor = Mathf.Max(result.secutor, UnityEngine.Random.Range(2, 5));
			break;
		}
		return result;
	}

	public TrainingCourse GetTrainingCourse(string courseId)
	{
		if (trainingCourses == null)
		{
			return null;
		}
		TrainingCourse[] array = trainingCourses;
		foreach (TrainingCourse trainingCourse in array)
		{
			if (trainingCourse.courseId == courseId)
			{
				return trainingCourse;
			}
		}
		return null;
	}

	public TrainingCourse[] GetAllTrainingCourses()
	{
		return trainingCourses;
	}

	public void Reset()
	{
		gladiators.Clear();
		nextGladiatorId = 1;
	}
}
