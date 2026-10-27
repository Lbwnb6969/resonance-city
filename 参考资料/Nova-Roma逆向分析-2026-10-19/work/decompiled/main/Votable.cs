using System;
using System.Reflection;
using UnityEngine;

public class Votable
{
	public string category = "";

	public string TermSegment = "";

	private Type implementation;

	public int impHash;

	public bool playerEnabled = true;

	public Color color = Color.white;

	public Type Implementation
	{
		get
		{
			return implementation;
		}
		set
		{
			implementation = value;
			impHash = implementation.GetHashCode();
			TermSegment = (string)implementation.GetMethod("GetTermSegment", BindingFlags.Static | BindingFlags.Public | BindingFlags.FlattenHierarchy).Invoke(null, null);
		}
	}

	public string GetTitleTerm()
	{
		return "Votable" + TermSegment + "Title";
	}

	public string GetDescriptionTerm()
	{
		return "Votable" + TermSegment + "Description";
	}
}
