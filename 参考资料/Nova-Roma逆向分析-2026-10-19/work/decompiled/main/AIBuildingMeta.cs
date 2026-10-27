using System;

public class AIBuildingMeta
{
	[Serializable]
	public class SaveData : SaveClass<AIBuildingMeta, SaveData>
	{
		public int parentPosX;

		public int parentPosZ;

		public int sizeX;

		public int sizeZ;

		public int offsetX;

		public int offsetZ;

		public int rot;

		public bool isRotated;

		public bool constructed;

		public bool inDevelopment;

		public bool invalid;

		public string uniqueName = "";

		public AIBuildingBlockType type;

		public override SaveData Pack(AIBuildingMeta v)
		{
			parentPosX = v.parentPosX;
			parentPosZ = v.parentPosZ;
			sizeX = v.sizeX;
			sizeZ = v.sizeZ;
			offsetX = v.offsetX;
			offsetZ = v.offsetZ;
			inDevelopment = v.inDevelopment;
			uniqueName = v.uniqueName;
			type = v.type;
			isRotated = v.IsRotated;
			return this;
		}

		public override AIBuildingMeta Unpack(AIBuildingMeta v)
		{
			v.parentPosX = parentPosX;
			v.parentPosZ = parentPosZ;
			v.sizeX = sizeX;
			v.sizeZ = sizeZ;
			v.offsetX = offsetX;
			v.offsetZ = offsetZ;
			v.uniqueName = uniqueName;
			v.type = type;
			v.IsRotated = isRotated;
			return v;
		}
	}

	public int parentPosX;

	public int parentPosZ;

	internal int sizeX;

	internal int sizeZ;

	internal int offsetX;

	internal int offsetZ;

	public bool IsRotated;

	public bool inDevelopment;

	public string uniqueName = "";

	public AIBuildingBlockType type;

	public int SizeX
	{
		get
		{
			if (!IsRotated)
			{
				return sizeX;
			}
			return sizeZ;
		}
		set
		{
			sizeX = value;
		}
	}

	public int SizeZ
	{
		get
		{
			if (!IsRotated)
			{
				return sizeZ;
			}
			return sizeX;
		}
		set
		{
			sizeZ = value;
		}
	}

	public int OffsetX
	{
		get
		{
			if (!IsRotated)
			{
				return offsetX;
			}
			return offsetZ;
		}
		set
		{
			offsetX = value;
		}
	}

	public int OffsetZ
	{
		get
		{
			if (!IsRotated)
			{
				return offsetZ;
			}
			return offsetX;
		}
		set
		{
			offsetZ = value;
		}
	}

	public int PosX => parentPosX + OffsetX;

	public int PosZ => parentPosZ + OffsetZ;
}
