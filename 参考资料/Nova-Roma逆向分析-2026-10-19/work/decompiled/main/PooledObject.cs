using UnityEngine;

public class PooledObject : MonoBehaviour
{
	private PooledObject prefab;

	private PooledObject next;

	public static ArrayExtRef<PooledObject> needTick = new ArrayExtRef<PooledObject>(1000);

	private static bool insideTick = false;

	private static ArrayExt<PooledObject> deferredRemoval = new ArrayExt<PooledObject>(100);

	public virtual void Init()
	{
	}

	public virtual void Shutdown()
	{
	}

	public virtual void Tick(float dt)
	{
	}

	public PooledObject Alloc(Vector3 position)
	{
		return Alloc(position, Quaternion.identity);
	}

	public PooledObject Alloc(Vector3 position, Quaternion rotation)
	{
		PooledObject pooledObject = null;
		if (next != null)
		{
			pooledObject = next;
			next = pooledObject.next;
			pooledObject.next = null;
			pooledObject.transform.SetPositionAndRotation(position, rotation);
			pooledObject.gameObject.SetActive(value: true);
		}
		else
		{
			pooledObject = Object.Instantiate(this);
			pooledObject.transform.SetPositionAndRotation(position, rotation);
			pooledObject.prefab = this;
		}
		pooledObject.Init();
		needTick.Add(pooledObject);
		return pooledObject;
	}

	public static void ClearAll()
	{
		for (int i = 0; i < needTick.Count; i++)
		{
			deferredRemoval.Add(needTick.data[i]);
		}
		for (int j = 0; j < deferredRemoval.Count; j++)
		{
			deferredRemoval.data[j].Release();
		}
		deferredRemoval.Clear();
	}

	public static void TickAll(float dt)
	{
		insideTick = true;
		for (int i = 0; i < needTick.Count; i++)
		{
			needTick.data[i].Tick(dt);
		}
		insideTick = false;
		for (int j = 0; j < deferredRemoval.Count; j++)
		{
			deferredRemoval.data[j].Release();
		}
		deferredRemoval.Clear();
	}

	public void Release()
	{
		if (!gameObject.activeSelf)
		{
			return;
		}
		if (insideTick)
		{
			deferredRemoval.Add(this);
			return;
		}
		Shutdown();
		needTick.RemoveSwap(this);
		if (prefab != null)
		{
			transform.SetParent(null, worldPositionStays: true);
			gameObject.SetActive(value: false);
			next = prefab.next;
			prefab.next = this;
		}
		else if ((bool)gameObject)
		{
			gameObject.SetActive(value: false);
			Object.Destroy(gameObject);
		}
	}
}
