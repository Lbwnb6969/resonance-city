using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ThoughtBubbleSystem : MonoBehaviour
{
	public class ThoughtBubble : InstanceSystem.Owner
	{
		public Vector3 pos;

		public Quaternion rot;

		public Vector3 offset;

		public float scaleMod = 1f;

		private bool _visible;

		public int idxInList = -1;

		public ThoughtCategory category;

		private Thought m_thought;

		public bool visible
		{
			get
			{
				return _visible;
			}
			set
			{
				if (!value && _visible)
				{
					Mathff.SetTRS(ref inst.instances.data[(int)m_thought].silos.data[s][idx], pos, rot, Vector3.zero);
				}
				_visible = value;
			}
		}

		public Thought thought
		{
			get
			{
				return m_thought;
			}
			set
			{
				SetThought(value);
			}
		}

		public void SetThought(Thought value, ThoughtCategory? overrideCategory = null)
		{
			if (m_thought != value)
			{
				inst.instances.data[(int)m_thought].ReleaseInstance(this);
				m_thought = value;
				inst.instances.data[(int)m_thought].AddInstance(this, pos, rot, Vector3.zero);
			}
			category = overrideCategory ?? DefaultCategoryFor(value);
		}
	}

	public enum Thought
	{
		Satisfied,
		House,
		Food,
		FoodCritical,
		Plague,
		Wage,
		WageCritical,
		GeneralError,
		Rats,
		DeadBodyWarning,
		DeadBodySafe,
		DeadBody,
		PlagueCritical,
		Water,
		Cold,
		Pottery,
		Wine,
		Tired,
		Demolish,
		Aqueduct,
		WaterCritical,
		PoopCritical,
		NumOfThoughts
	}

	[Flags]
	public enum ThoughtCategory
	{
		Default = 0,
		Water = 1
	}

	public sealed class ThoughtMaskHandle
	{
		public readonly ThoughtCategory mask;

		internal ThoughtMaskHandle(ThoughtCategory mask)
		{
			this.mask = mask;
		}
	}

	public static ThoughtBubbleSystem inst;

	private readonly List<ThoughtMaskHandle> activeMasks = new List<ThoughtMaskHandle>(4);

	private ThoughtCategory activeMask;

	public bool forceThoughtsOn;

	private static ArrayExt<ThoughtBubble> thoughts = new ArrayExt<ThoughtBubble>(50);

	private ArrayExt<InstanceSystem> instances = new ArrayExt<InstanceSystem>(22);

	public Material[] thoughtMaterials = new Material[22];

	public AnimationCurve ScaleToCamDist;

	public bool disableUI;

	public Mesh thoughtBubbleMesh;

	public static ThoughtCategory DefaultCategoryFor(Thought t)
	{
		if (t == Thought.Water || (uint)(t - 19) <= 2u)
		{
			return ThoughtCategory.Water;
		}
		return ThoughtCategory.Default;
	}

	public ThoughtMaskHandle PushMask(ThoughtCategory mask)
	{
		ThoughtMaskHandle thoughtMaskHandle = new ThoughtMaskHandle(mask);
		activeMasks.Add(thoughtMaskHandle);
		RecomputeActiveMask();
		return thoughtMaskHandle;
	}

	public void PopMask(ref ThoughtMaskHandle handle)
	{
		if (handle != null)
		{
			activeMasks.Remove(handle);
			handle = null;
			RecomputeActiveMask();
		}
	}

	private void RecomputeActiveMask()
	{
		ThoughtCategory thoughtCategory = ThoughtCategory.Default;
		for (int i = 0; i < activeMasks.Count; i++)
		{
			thoughtCategory |= activeMasks[i].mask;
		}
		activeMask = thoughtCategory;
	}

	private void Start()
	{
		inst = this;
		for (int i = 0; i < 22; i++)
		{
			instances.Add(new InstanceSystem());
			instances.data[i].shadowCastingMode = ShadowCastingMode.Off;
		}
	}

	public void Init()
	{
		Reset();
	}

	private void Update()
	{
		if (disableUI)
		{
			return;
		}
		_ = Cam.inst.transform.rotation * Vector3.up;
		Vector3 position = Cam.inst.transform.position;
		Vector3 zero = Vector3.zero;
		Vector3 zero2 = Vector3.zero;
		_ = Vector3.zero;
		Vector3 zero3 = Vector3.zero;
		ThoughtCategory thoughtCategory = ((!forceThoughtsOn) ? activeMask : ThoughtCategory.Default);
		int i = 0;
		for (int count = thoughts.Count; i < count; i++)
		{
			ThoughtBubble thoughtBubble = thoughts.data[i];
			if (thoughtBubble.visible)
			{
				if (thoughtCategory != ThoughtCategory.Default && (thoughtBubble.category & thoughtCategory) == 0)
				{
					Mathff.SetTRS(ref instances.data[(int)thoughtBubble.thought].silos.data[thoughtBubble.s][thoughtBubble.idx], thoughtBubble.pos, thoughtBubble.rot, Vector3.zero);
					continue;
				}
				zero.x = thoughtBubble.pos.x - position.x;
				zero.y = thoughtBubble.pos.y - position.y;
				zero.z = thoughtBubble.pos.z - position.z;
				float time = Mathff.Magnitude(zero);
				float num = ScaleToCamDist.Evaluate(time) * thoughtBubble.scaleMod * 0.75f;
				zero3.x = thoughtBubble.pos.x + thoughtBubble.offset.x;
				zero3.y = thoughtBubble.pos.y + (num + 0.5f * num) + thoughts.data[i].offset.y;
				zero3.z = thoughtBubble.pos.z + thoughtBubble.offset.z;
				zero2.x = num;
				zero2.y = num;
				zero2.z = num;
				Mathff.SetTRS(ref instances.data[(int)thoughtBubble.thought].silos.data[thoughtBubble.s][thoughtBubble.idx], zero3, thoughtBubble.rot, zero2);
			}
		}
	}

	public void Reset()
	{
		thoughts.Clear();
		for (int i = 0; i < instances.Count; i++)
		{
			instances.data[i].ResetInstances();
		}
		activeMasks.Clear();
		activeMask = ThoughtCategory.Default;
	}

	private void LateUpdate()
	{
		bool flag = (!(DebugCam.inst != null) || !DebugCam.inst.enabled) && !disableUI && !GodUI.inst.gameObject.activeSelf && !Cinematics.inst.IsCinematicRunning() && !PhotoMode.IsActive() && (GameUI.inst.currCursorMode == null || !GameUI.inst.currCursorMode.HideThoughtBubble()) && !WorkerUI.inst.aqueductBuildingFlowUI.gameObject.activeInHierarchy && !GladiatorRecruitModal.inst.IsVisible() && !ColosseumPlannerUI.inst.IsVisible();
		if (forceThoughtsOn)
		{
			flag = true;
		}
		bool flag2 = false;
		if (Player.inst.Buildings.Count > 0)
		{
			flag2 = Player.inst.Buildings.data[0].IsBuilt();
		}
		if (flag & flag2)
		{
			for (int i = 0; i < instances.Count; i++)
			{
				instances.data[i].DrawInstances(thoughtBubbleMesh, thoughtMaterials[i]);
			}
		}
	}

	public ThoughtBubble AddThoughtBubble(Vector3 pos)
	{
		ThoughtBubble thoughtBubble = new ThoughtBubble();
		thoughtBubble.pos = pos;
		thoughts.Add(thoughtBubble);
		thoughtBubble.idxInList = thoughts.Count - 1;
		instances.data[(int)thoughtBubble.thought].AddInstance(thoughtBubble, pos, Quaternion.identity, Vector3.zero);
		return thoughtBubble;
	}

	public void RemoveThoughtBubble(ref ThoughtBubble curr)
	{
		int idxInList = curr.idxInList;
		thoughts.RemoveAtSwap(idxInList);
		if (thoughts.Count > 0 && idxInList < thoughts.Count)
		{
			thoughts.data[curr.idxInList].idxInList = idxInList;
		}
		instances.data[(int)curr.thought].ReleaseInstance(curr);
		curr = null;
	}
}
