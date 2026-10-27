using UnityEngine;

public class BMMeshSwitcher : MonoBehaviour
{
	public MeshFilter[] targets;

	public Mesh[] alternatives;

	private void Start()
	{
		for (int i = 0; i < targets.Length; i++)
		{
			targets[i].mesh = alternatives[SRand.Range(0, alternatives.Length)];
		}
	}
}
