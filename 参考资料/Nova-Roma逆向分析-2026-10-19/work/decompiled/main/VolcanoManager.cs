using FMOD.Studio;
using UnityEngine;

public class VolcanoManager : MonoBehaviour
{
	public delegate void OnVolcanoEvent(int volcanoID);

	public float SmokeTime = 10f;

	public float EruptionTime = 10f;

	public float CoolingTime = 10f;

	public float MaxLavaProduction = 6f;

	public float FormingRaiseHeight = 1f;

	private const int STATE_SMOKING = 1;

	private const int STATE_ERUPTING = 2;

	private const int STATE_COOLING = 3;

	private const int STATE_DONE = 4;

	private int MaxVolcanos = 10;

	private int VolcanoCount;

	private bool[] active;

	private int[] lavaSource;

	private float[] currTime;

	private int[] state;

	private int[] prevState;

	private OneOffEffect[] smokeEffect;

	private OneOffEffect[] eruptionEffect;

	private float[] formingProgress;

	private EventInstance[] preeruptionSound;

	private EventInstance[] eruptionSound;

	public static VolcanoManager inst;

	public OnVolcanoEvent onVolcanoStart;

	public OnVolcanoEvent onVolcanoEnd;

	private void Awake()
	{
		inst = this;
		active = new bool[MaxVolcanos];
		lavaSource = new int[MaxVolcanos];
		currTime = new float[MaxVolcanos];
		state = new int[MaxVolcanos];
		prevState = new int[MaxVolcanos];
		smokeEffect = new OneOffEffect[MaxVolcanos];
		eruptionEffect = new OneOffEffect[MaxVolcanos];
		formingProgress = new float[MaxVolcanos];
		preeruptionSound = new EventInstance[MaxVolcanos];
		eruptionSound = new EventInstance[MaxVolcanos];
	}

	public (bool, int) CreateVolcano(int lavaSource)
	{
		for (int i = 0; i < MaxVolcanos; i++)
		{
			if (!active[i])
			{
				active[i] = true;
				this.lavaSource[i] = lavaSource;
				currTime[i] = 0f;
				state[i] = 1;
				prevState[i] = 4;
				formingProgress[i] = 0f;
				return (true, i);
			}
		}
		return (false, -1);
	}

	public (bool, int) CreateVolcano(Vector3 pos)
	{
		Cell cellData = World.inst.GetCellData(pos);
		if (cellData == null)
		{
			return (false, -1);
		}
		int num = DynamicLava.MapIndexWorldToMesh(cellData.index, World.inst.GridWidth);
		for (int i = 0; i < MaxVolcanos; i++)
		{
			if (!active[i])
			{
				active[i] = true;
				lavaSource[i] = num;
				currTime[i] = 0f;
				state[i] = 1;
				prevState[i] = 4;
				formingProgress[i] = 0f;
				return (true, i);
			}
		}
		return (false, -1);
	}

	private void DestroyVolcano(int volcano)
	{
		onVolcanoEnd?.Invoke(volcano);
		DynamicLava.inst.ReadyForWrite();
		active[volcano] = false;
		smokeEffect[volcano]?.Stop();
		eruptionEffect[volcano]?.Stop();
		DynamicLava.inst.RemoveWaterSource(lavaSource[volcano]);
	}

	private Vector3 SourcePosition(int sourceIndex)
	{
		Vector3 pos = new Vector3((float)(sourceIndex % World.MeshWidth) / 2f, 0f, (float)(sourceIndex / World.MeshWidth) / 2f);
		TerrainGen.inst.GetGroundHeight(ref pos);
		return pos;
	}

	public void TriggerEruption(int idx)
	{
		state[idx] = 2;
	}

	private void Update()
	{
		for (int i = 0; i < MaxVolcanos; i++)
		{
			if (!active[i])
			{
				continue;
			}
			if (state[i] != prevState[i])
			{
				currTime[i] = 0f;
				if (state[i] == 1)
				{
					smokeEffect[i] = EffectsMan.inst.VolcanoSmokeEffect.CreateAndPlay(SourcePosition(lavaSource[i]));
					preeruptionSound[i] = SfxSystem.inst.PlayFromBank("Volcano_Rumble", SourcePosition(lavaSource[i]));
				}
				if (state[i] == 2)
				{
					preeruptionSound[i].stop(STOP_MODE.ALLOWFADEOUT);
					eruptionSound[i] = SfxSystem.inst.PlayFromBank("Volcano_Erupt", SourcePosition(lavaSource[i]));
					eruptionEffect[i] = EffectsMan.inst.VolcanoEruptionEffect.CreateAndPlay(SourcePosition(lavaSource[i]) + new Vector3(0f, 3f, 0f));
					DynamicLava.inst.SetProduction(lavaSource[i], MaxLavaProduction);
					Cam.inst.Shake(new Vector3(0f, -20f, 0f));
				}
				if (state[i] == 3)
				{
					eruptionEffect[i].Stop();
				}
				prevState[i] = state[i];
			}
			switch (state[i])
			{
			case 1:
				smokeEffect[i].transform.position = SourcePosition(lavaSource[i]);
				break;
			case 2:
				currTime[i] += Time.deltaTime;
				if (currTime[i] > EruptionTime)
				{
					state[i] = 3;
				}
				break;
			case 3:
				currTime[i] += Time.deltaTime;
				DynamicLava.inst.SetProduction(lavaSource[i], Mathf.Lerp(MaxLavaProduction, 0f, currTime[i] / CoolingTime));
				if (currTime[i] > CoolingTime)
				{
					smokeEffect[i].Stop();
					DestroyVolcano(i);
				}
				break;
			}
		}
	}
}
