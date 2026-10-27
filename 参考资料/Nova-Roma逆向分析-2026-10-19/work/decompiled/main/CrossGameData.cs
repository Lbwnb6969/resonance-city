using System;
using System.IO;
using System.Runtime.Serialization;
using UnityEngine;

public class CrossGameData : MonoBehaviour
{
	[Serializable]
	public class CrossGameSaveData : SaveClass<CrossGameData, CrossGameSaveData>
	{
		public bool BeatSurvival;

		public override CrossGameSaveData Pack(CrossGameData obj)
		{
			BeatSurvival = obj.BeatSurvival;
			return this;
		}

		public override CrossGameData Unpack(CrossGameData obj)
		{
			obj.BeatSurvival = BeatSurvival;
			return obj;
		}

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			BeatSurvival = false;
		}
	}

	public static CrossGameData inst;

	public bool BeatSurvival { get; set; }

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		LoadData();
	}

	private void LoadData()
	{
		if (File.Exists(Application.persistentDataPath + "/Saves/crossgamedata.dat"))
		{
			Stream stream = null;
			try
			{
				stream = new FileStream(Application.persistentDataPath + "/Saves/crossgamedata.dat", FileMode.Open);
				SaveSerializer.DeserializeFromStream<CrossGameSaveData>(stream).Unpack(this);
				return;
			}
			catch
			{
				SetToDefaults();
				return;
			}
			finally
			{
				if (stream != null)
				{
					stream.Close();
					stream.Dispose();
				}
			}
		}
		SetToDefaults();
	}

	public void Save()
	{
		Stream stream = new FileStream(Application.persistentDataPath + "/Saves/crossgamedata.dat", FileMode.Create);
		SaveSerializer.SerializeToStream(new CrossGameSaveData().Pack(this), stream);
		stream.Close();
		stream.Dispose();
	}

	private void SetToDefaults()
	{
		BeatSurvival = false;
	}
}
