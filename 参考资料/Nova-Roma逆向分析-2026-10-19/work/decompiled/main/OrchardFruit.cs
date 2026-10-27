using System;
using UnityEngine;

public class OrchardFruit : MonoBehaviour
{
	public Transform fruitContainer;

	[NonSerialized]
	public Vector3 fruitSize;

	public RenderInstanceBehaviour treetop;

	public RenderInstanceBehaviour treetrunk;

	public Vector3 cachedTopPosition;

	public Quaternion cachedTopRotation;

	public Vector3 cachedTopScale;

	public Vector3 cachedTrunkPosition;

	public Quaternion cachedTrunkRotation;

	public Vector3 cachedTrunkScale;

	private Vector3 rootPosition;

	private Quaternion rootRotation;

	private Matrix4x4 rootMatrix;

	private Matrix4x4 scratch;

	public void SetTreeTrunkTopVisible(bool v)
	{
		treetop.gameObject.SetActive(v);
		treetrunk.gameObject.SetActive(v);
	}

	public void Setup()
	{
		cachedTopPosition = treetop.transform.localPosition;
		cachedTopRotation = treetop.transform.localRotation;
		cachedTopScale = treetop.transform.localScale;
		cachedTrunkPosition = treetrunk.transform.localPosition;
		cachedTrunkRotation = treetrunk.transform.localRotation;
		cachedTrunkScale = treetrunk.transform.localScale;
		rootPosition = transform.position;
		rootRotation = transform.rotation;
		treetop.MatchUnityTransform();
		treetrunk.MatchUnityTransform();
	}

	public void UpdateTreeTransform(Vector3 scalev)
	{
		Mathff.SetTRS(ref rootMatrix, rootPosition, rootRotation, scalev);
		Mathff.SetTRS(ref scratch, cachedTopPosition, cachedTopRotation, cachedTopScale);
		treetop.UpdateMatrix(rootMatrix * scratch);
		Mathff.SetTRS(ref scratch, cachedTrunkPosition, cachedTrunkRotation, cachedTrunkScale);
		treetrunk.UpdateMatrix(rootMatrix * scratch);
	}
}
