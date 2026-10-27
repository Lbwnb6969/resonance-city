using System.Collections.Generic;
using System.IO;
using System.Reflection;
using UnityEngine;
using UnityEngine.UI;

public class UIInvestigator : MonoBehaviour
{
	private class PathReference
	{
		public string path;

		public int layoutReferences;

		public int drawReferences;
	}

	private StreamWriter file;

	private bool running;

	private int totalFrames;

	private List<PathReference> pathRefs = new List<PathReference>();

	private Dictionary<string, PathReference> pathDict = new Dictionary<string, PathReference>();

	private void Start()
	{
	}

	private void OnEnable()
	{
		file = new StreamWriter("investigator.txt");
	}

	private void OnDisable()
	{
		file.Dispose();
	}

	private void LateUpdate()
	{
		if (Input.GetKeyDown(KeyCode.LeftControl) && Input.GetKey(KeyCode.LeftShift))
		{
			if (!running)
			{
				running = true;
				totalFrames = 0;
				pathRefs.Clear();
				pathDict.Clear();
				file.WriteLine("Starting layout rebuild thing");
				Debug.Log("Starting layout rebuild thing");
			}
			else
			{
				running = false;
				string text = $"Layout rebuild report, Total frames: {totalFrames}\n\n";
				pathRefs.Sort((PathReference a, PathReference b) => string.Compare(a.path, b.path));
				foreach (PathReference pathRef in pathRefs)
				{
					text += $"Layouts: {pathRef.layoutReferences} Draws:{pathRef.drawReferences} - {pathRef.path}\n";
				}
				file.WriteLine(text);
				Debug.Log(text);
			}
		}
		if (!running)
		{
			return;
		}
		totalFrames++;
		object value = typeof(CanvasUpdateRegistry).GetField("m_LayoutRebuildQueue", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(CanvasUpdateRegistry.instance);
		foreach (ICanvasElement item in value.GetType().GetField("m_List", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(value) as List<ICanvasElement>)
		{
			string gameObjectPath = Util.GetGameObjectPath(item.transform);
			MaybeInitPath(gameObjectPath);
			pathDict[gameObjectPath].layoutReferences = pathDict[gameObjectPath].layoutReferences + 1;
		}
		object value2 = typeof(CanvasUpdateRegistry).GetField("m_GraphicRebuildQueue", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(CanvasUpdateRegistry.instance);
		foreach (ICanvasElement item2 in value2.GetType().GetField("m_List", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(value2) as List<ICanvasElement>)
		{
			string gameObjectPath2 = Util.GetGameObjectPath(item2.transform);
			MaybeInitPath(gameObjectPath2);
			pathDict[gameObjectPath2].drawReferences = pathDict[gameObjectPath2].drawReferences + 1;
		}
	}

	private void MaybeInitPath(string path)
	{
		if (!pathDict.ContainsKey(path))
		{
			PathReference pathReference = new PathReference();
			pathReference.layoutReferences = 0;
			pathReference.drawReferences = 0;
			pathReference.path = path;
			pathRefs.Add(pathReference);
			pathDict[path] = pathReference;
		}
	}
}
