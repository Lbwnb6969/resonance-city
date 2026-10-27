using Assets.Code;
using UnityEngine;

public class Stack : MonoBehaviour
{
	[FreeResourceType]
	public int resourceID;

	public int maxStackCount;

	public int xStackSize;

	public int zStackSize;

	public int DegreesRotationVariation;

	public float spacing;

	public bool rowAlternateRotation = true;

	public int InitCount;

	public float HeightMultiplier = 1f;

	public bool useGameObjects;

	private CullingGroup cullingGroup;

	public Transform stackContainer;

	private RenderInstance[] instances;

	private Vector3[] positions;

	private Quaternion[] rots;

	private Vector3 scale;

	protected int internalCount;

	private bool visible = true;

	public bool ManualInit;

	internal Transform xform;

	internal Building b;

	private static ArrayExt<Stack> stacks = new ArrayExt<Stack>(1000);

	internal bool inited;

	public void Hide()
	{
		visible = false;
		if (!useGameObjects)
		{
			for (int i = 0; i < maxStackCount; i++)
			{
				instances[i].Visible = false;
			}
		}
		else
		{
			for (int j = 0; j < maxStackCount; j++)
			{
				stackContainer.GetChild(j).gameObject.SetActive(value: false);
			}
		}
	}

	public void Show()
	{
		visible = true;
		if (!useGameObjects)
		{
			for (int i = 0; i < maxStackCount; i++)
			{
				instances[i].Visible = i < internalCount;
			}
		}
		else
		{
			for (int j = 0; j < maxStackCount; j++)
			{
				stackContainer.GetChild(j).gameObject.SetActive(j < internalCount);
			}
		}
	}

	public void StateChangedMethod(CullingGroupEvent evt)
	{
		if (evt.hasBecomeVisible)
		{
			Show();
		}
		if (evt.hasBecomeInvisible)
		{
			Hide();
		}
	}

	public void Awake()
	{
		xform = transform;
		b = transform.GetComponentInParent<Building>();
		if (b != null)
		{
			b.visibilityChanged += B_visibilityChanged;
		}
		if (!ManualInit)
		{
			Init();
		}
	}

	public void B_visibilityChanged(bool v)
	{
		gameObject.SetActive(v);
	}

	public void TickOnce()
	{
		Vector3 zero = Vector3.zero;
		Vector3 position = transform.position;
		Quaternion rotation = transform.rotation;
		for (int i = 0; i < maxStackCount; i++)
		{
			Vector3 vector = position + rotation * positions[i];
			instances[i].UpdateTRS(vector, rotation * rots[i], scale);
			zero += vector;
		}
		zero /= (float)maxStackCount;
	}

	public static void Tick()
	{
		for (int i = 0; i < stacks.Count; i++)
		{
			stacks.data[i].TickOnce();
		}
		stacks.Clear();
	}

	public void Init()
	{
		if (inited)
		{
			return;
		}
		inited = true;
		GameObject prefab = FreeResourceSystem.inst.resourceDefMap[resourceID].prefab;
		MeshRenderer componentInChildren = prefab.GetComponentInChildren<MeshRenderer>();
		Material sharedMaterial = componentInChildren.sharedMaterial;
		Mesh sharedMesh = prefab.GetComponentInChildren<MeshFilter>().sharedMesh;
		Bounds bounds = componentInChildren.bounds;
		Vector3 position = transform.position;
		position.y += bounds.extents.y;
		transform.position = position;
		float num = bounds.size.y * HeightMultiplier;
		scale = prefab.transform.localScale;
		if ((bool)stackContainer)
		{
			maxStackCount = stackContainer.childCount;
			if (!useGameObjects)
			{
				instances = new RenderInstance[maxStackCount];
				positions = new Vector3[maxStackCount];
				rots = new Quaternion[maxStackCount];
				for (int i = 0; i < maxStackCount; i++)
				{
					Transform child = stackContainer.GetChild(i);
					instances[i] = new RenderInstance(sharedMesh, sharedMaterial);
					positions[i] = child.localPosition;
					rots[i] = child.localRotation;
					instances[i].Visible = false;
					instances[i].castShadows = false;
				}
				Object.Destroy(stackContainer.gameObject);
			}
			else
			{
				for (int j = 0; j < maxStackCount; j++)
				{
					Transform child2 = stackContainer.GetChild(j);
					child2.gameObject.SetActive(value: false);
					child2.GetComponentInChildren<MeshRenderer>().material = sharedMaterial;
				}
			}
		}
		else
		{
			int num2 = xStackSize * zStackSize;
			if (num2 == 0)
			{
				Debug.LogError("Error with " + b.FriendlyName);
			}
			stackContainer = new GameObject("container").transform;
			stackContainer.SetParent(transform, worldPositionStays: false);
			stackContainer.localPosition = Vector3.zero;
			if (!useGameObjects)
			{
				instances = new RenderInstance[maxStackCount];
				positions = new Vector3[maxStackCount];
				rots = new Quaternion[maxStackCount];
			}
			for (int k = 0; k < maxStackCount; k++)
			{
				int num3 = k / num2;
				GameObject gameObject = null;
				if (!useGameObjects)
				{
					instances[k] = new RenderInstance(sharedMesh, sharedMaterial);
					instances[k].castShadows = false;
				}
				else
				{
					gameObject = Object.Instantiate(prefab);
					gameObject.transform.SetParent(stackContainer, worldPositionStays: false);
				}
				int num4 = k % num2;
				float num5 = (float)(num4 % xStackSize) * spacing - (float)(xStackSize - 1) * spacing / 2f;
				float num6 = (float)(num4 / xStackSize) * spacing - (float)(zStackSize - 1) * spacing / 2f;
				Quaternion quaternion;
				if (rowAlternateRotation && num3 % 2 == 1)
				{
					float num7 = num5;
					num5 = num6;
					num6 = num7;
					quaternion = Quaternion.Euler(0f, 90f + (Random.value - 0.5f) * (float)DegreesRotationVariation, 0f);
				}
				else
				{
					quaternion = Quaternion.Euler(0f, (Random.value - 0.5f) * (float)DegreesRotationVariation, 0f);
				}
				if (!useGameObjects)
				{
					rots[k] = quaternion;
				}
				else
				{
					gameObject.transform.localRotation = quaternion;
				}
				if (!useGameObjects)
				{
					positions[k] = new Vector3(num5, num * (float)num3, num6);
					instances[k].Visible = false;
				}
				else
				{
					gameObject.transform.localPosition = new Vector3(num5, num * (float)num3, num6);
					gameObject.SetActive(value: false);
					gameObject.GetComponentInChildren<MeshRenderer>().material = sharedMaterial;
				}
			}
		}
		internalCount = 0;
		Add(InitCount);
		if (!useGameObjects && (b == null || b.IsPlaced()))
		{
			stacks.Add(this);
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (!useGameObjects)
		{
			Init();
			stacks.Add(this);
		}
	}

	private void OnEnable()
	{
		if (!useGameObjects && instances != null)
		{
			for (int i = 0; i < maxStackCount; i++)
			{
				instances[i].Visible = i < internalCount;
			}
		}
	}

	private void OnDisable()
	{
		if (!useGameObjects && instances != null)
		{
			for (int i = 0; i < maxStackCount; i++)
			{
				instances[i].Visible = false;
			}
		}
	}

	private void Start()
	{
		if (useGameObjects)
		{
			Material sharedMaterial = FreeResourceSystem.inst.resourceDefMap[resourceID].prefab.GetComponentInChildren<MeshRenderer>().sharedMaterial;
			for (int i = 0; i < maxStackCount; i++)
			{
				stackContainer.GetChild(i).GetComponentInChildren<MeshRenderer>().material = sharedMaterial;
			}
		}
	}

	private void OnDestroy()
	{
		if (!useGameObjects && instances != null)
		{
			for (int i = 0; i < maxStackCount; i++)
			{
				instances[i].Visible = false;
			}
		}
		if (cullingGroup != null)
		{
			cullingGroup.Dispose();
			cullingGroup = null;
		}
		if (b != null)
		{
			b.visibilityChanged -= B_visibilityChanged;
		}
		stacks.RemoveSwap(this);
	}

	public int Add(int num)
	{
		int num2 = Mathf.Min(num, maxStackCount - internalCount);
		if (!useGameObjects)
		{
			if (gameObject.activeSelf)
			{
				for (int i = internalCount; i < internalCount + num2; i++)
				{
					instances[i].Visible = visible;
				}
			}
		}
		else
		{
			for (int j = internalCount; j < internalCount + num2; j++)
			{
				stackContainer.GetChild(j).gameObject.SetActive(value: true);
			}
		}
		internalCount += num2;
		return num2;
	}

	public int Remove(int num)
	{
		int num2 = Mathf.Min(num, internalCount);
		if (!useGameObjects)
		{
			int num3 = instances.Length;
			for (int num4 = internalCount - 1; num4 >= internalCount - num2; num4--)
			{
				if (num4 >= 0 && num4 < num3)
				{
					instances[num4].Visible = false;
				}
				else
				{
					Debug.LogError("trying to remove more than we have in the stack");
				}
			}
		}
		else
		{
			int childCount = stackContainer.childCount;
			for (int num5 = internalCount - 1; num5 >= internalCount - num2; num5--)
			{
				if (num5 >= 0 && num5 < childCount)
				{
					stackContainer.GetChild(num5).gameObject.SetActive(value: false);
				}
				else
				{
					Debug.LogError("trying to remove more than we have in the stack");
				}
			}
		}
		internalCount -= num2;
		return num2;
	}

	public int Count()
	{
		return internalCount;
	}

	public int MaxCapacity()
	{
		return maxStackCount;
	}

	public void Set(int newCount)
	{
		if (!useGameObjects)
		{
			for (int i = 0; i < maxStackCount; i++)
			{
				instances[i].Visible = i < newCount;
			}
		}
		else
		{
			for (int j = 0; j < maxStackCount; j++)
			{
				stackContainer.GetChild(j).gameObject.SetActive(j < newCount);
			}
		}
		internalCount = Mathf.Min(newCount, maxStackCount);
	}
}
