using UnityEngine;
using UnityEngine.Events;

public class HydraAttackScenario : MonoBehaviour
{
	public GameObject hydraInstance;

	public GameObject hydraPrefab;

	public Transform moveTarget;

	private Hydra hydra;

	private HydraMoveController hydraMoveController;

	private GamePath deferredPath = new GamePath();

	private const int STATE_WANDER = 0;

	private const int STATE_ATTACK = 1;

	private const int STATE_ENJOY_ROCK = 2;

	private const int STATE_THINK = 3;

	private const int STATE_EXIT = 4;

	private int state;

	public HydraAttackScenario inst;

	private UnityAction[] stateFunctions;

	private Vector3 lastMoveTarget = Vector3.zero;

	private Timer boredTimer = new Timer(3f);

	private Timer thinkingTimer = new Timer(2f);

	public bool debugMode;

	private bool ready;

	private Timer timer = new Timer(1f);

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		hydraInstance = Object.Instantiate(hydraPrefab, transform);
		hydra = hydraInstance.GetComponentInChildren<Hydra>();
		hydraMoveController = hydraInstance.GetComponentInChildren<HydraMoveController>();
		hydra.transform.position = new Vector3(World.inst.GridWidth / 2, 0f, World.inst.GridHeight / 2);
		moveTarget = hydraInstance.transform.Find("HydraMoveTarget");
		moveTarget.transform.position = new Vector3(World.inst.GridWidth / 2, 0f, World.inst.GridHeight / 2);
		SetupStateFunctions();
	}

	private void SetupStateFunctions()
	{
		stateFunctions = new UnityAction[5];
		stateFunctions[0] = StateWanderUpdate;
		stateFunctions[1] = StateAttackUpdate;
		stateFunctions[2] = StateWanderEnjoyRockUpdate;
		stateFunctions[3] = StateWanderThinkUpdate;
		stateFunctions[4] = StateExitUpdate;
		state = 3;
	}

	private void StateWanderUpdate()
	{
		if (hydra.hydraAcceleration <= 0.0001f && !hydra.hydraNeedToMove && hydra.pathData.Count > 0 && !debugMode)
		{
			state = 2;
		}
		if (Vector3.Distance(lastMoveTarget, moveTarget.position) > 0.5f && deferredPath.status != GamePath.Status.Finding)
		{
			lastMoveTarget = moveTarget.position;
			deferredPath.start = new Vector3(Mathf.Clamp(hydra.transform.position.x, 0f, World.inst.GridWidth), hydra.transform.position.y, Mathf.Clamp(hydra.transform.position.z, 0f, World.inst.GridHeight));
			deferredPath.end = moveTarget.position;
			deferredPath.pathType = GamePath.PathType.HydraPath;
			World.inst.threadedPather.RequestPath(deferredPath);
		}
	}

	private void StateWanderEnjoyRockUpdate()
	{
		if (boredTimer.Update(Time.deltaTime))
		{
			hydra.pathData.Clear();
			state = 3;
		}
	}

	private void StateWanderThinkUpdate()
	{
		if (thinkingTimer.Update(Time.deltaTime))
		{
			TerrainResource terrainResource = TerrainResource.terrainResources.RandomElement();
			if (terrainResource != null)
			{
				moveTarget.position = terrainResource.transform.position;
			}
			else
			{
				Debug.LogWarning("No terrain features found, wandering randomly");
				moveTarget.position = new Vector3(Random.Range(0, World.inst.GridWidth), 0f, Random.Range(0, World.inst.GridHeight));
			}
			state = 0;
		}
	}

	private void StateExitUpdate()
	{
		if (thinkingTimer.Update(Time.deltaTime))
		{
			TerrainResource terrainResource = TerrainResource.terrainResources.RandomElement();
			if (terrainResource != null)
			{
				moveTarget.position = terrainResource.transform.position;
			}
			else
			{
				Debug.LogWarning("No terrain features found, wandering randomly");
				moveTarget.position = new Vector3(Random.Range(0, World.inst.GridWidth), 0f, Random.Range(0, World.inst.GridHeight));
			}
			state = 0;
		}
	}

	private void StateAttackUpdate()
	{
	}

	private void Update()
	{
		ready |= timer.Update(Time.deltaTime);
		if (!ready)
		{
			return;
		}
		if (deferredPath.TryConsume(ref hydra.pathData))
		{
			for (int i = 0; i < hydra.pathData.Count; i++)
			{
				Vector3 vector = hydra.pathData.data[i];
				if (Physics.Raycast(new Ray(vector + Vector3.up * 10f, -Vector3.up), out var hitInfo, 1000f, LayerMask.GetMask("Terrain")))
				{
					vector = hitInfo.point;
				}
				hydra.pathData.data[i] = vector;
			}
		}
		hydra.ManualUpdate();
		stateFunctions[state]();
	}
}
