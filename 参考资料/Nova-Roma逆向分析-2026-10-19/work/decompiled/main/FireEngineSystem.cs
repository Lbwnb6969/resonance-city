using UnityEngine;

public class FireEngineSystem : MonoBehaviour
{
	public static FireEngineSystem inst;

	public ArrayExt<FireEngine> fireEngines = new ArrayExt<FireEngine>(64);

	public FireEngine enginePrefab;

	private void Awake()
	{
		inst = this;
	}

	public FireEngine SpawnEngine(FireHouse owner, Vector3 targetPos, Quaternion targetRot)
	{
		targetPos.y = TerrainGen.inst.GetInterpolatedHeight(targetPos);
		FireEngine fireEngine = Object.Instantiate(enginePrefab, transform);
		fireEngine.transform.position = targetPos;
		fireEngine.transform.rotation = targetRot;
		fireEngine.owner = owner;
		Util.SetActive(fireEngine.gameObject, owner.TeamID() != 0 || TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_fireengines"));
		fireEngines.Add(fireEngine);
		return fireEngine;
	}

	public bool Remove(FireEngine fireEngine)
	{
		if (fireEngine == null)
		{
			return false;
		}
		bool result = fireEngines.RemoveSwap(fireEngine);
		Object.Destroy(fireEngine.gameObject);
		return result;
	}
}
