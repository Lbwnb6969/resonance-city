using System;
using UnityEngine;

[Serializable]
public class Upgrade
{
	[TextArea(3, 10)]
	public string description;

	public GameObject model;
}
