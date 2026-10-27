using System;

[Serializable]
public class Skill
{
	public string name;

	public float value;

	[NonSerialized]
	public int nameHash;
}
