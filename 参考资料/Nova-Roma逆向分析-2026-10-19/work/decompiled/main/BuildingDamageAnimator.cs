using System.Collections.Generic;
using UnityEngine;

public class BuildingDamageAnimator
{
	private struct AnimData
	{
		public Transform offset;

		public Vector3 leveledDamageOffset;

		public Vector3 damagePos;

		public float animTime;

		public Vector3 oldPositionOffset;

		public List<Material> fullMaterial;
	}

	private ArrayExt<AnimData> animData = new ArrayExt<AnimData>(100);

	public void Tick(float dt)
	{
		for (int i = 0; i < animData.Count; i++)
		{
			animData.data[i].animTime -= dt * 10f;
			float animTime = animData.data[i].animTime;
			Transform offset = animData.data[i].offset;
			Vector3 oldPositionOffset = animData.data[i].oldPositionOffset;
			Vector3 leveledDamageOffset = animData.data[i].leveledDamageOffset;
			bool flag = false;
			if (animTime > 0.5f)
			{
				float t = (1f - animTime) / 0.5f;
				offset.position = Vector3.Lerp(oldPositionOffset, oldPositionOffset + leveledDamageOffset, t);
			}
			else if (animTime > 0f)
			{
				float t2 = (0.5f - animTime) / 0.5f;
				offset.position = Vector3.Lerp(oldPositionOffset + leveledDamageOffset, oldPositionOffset, t2);
			}
			else if (animTime <= 0f)
			{
				offset.position = animData.data[i].oldPositionOffset;
				flag = true;
			}
			if (flag)
			{
				animData.RemoveAtSwap(i);
				i--;
			}
		}
	}

	public bool IsAnimating(Transform offset)
	{
		for (int i = 0; i < animData.Count; i++)
		{
			if (animData.data[i].offset == offset)
			{
				return true;
			}
		}
		return false;
	}

	public void CleanUp(Transform offset)
	{
		for (int i = 0; i < animData.Count; i++)
		{
			if (animData.data[i].offset == offset)
			{
				animData.RemoveAtSwap(i);
				break;
			}
		}
	}

	public void Reset()
	{
		animData.Clear();
	}

	public void AddAnimation(Transform offset, Vector3 leveledDamageOffset, Vector3 damagePos, List<Material> fullMaterial)
	{
		AnimData item = new AnimData
		{
			animTime = 1f,
			damagePos = damagePos,
			oldPositionOffset = offset.position,
			leveledDamageOffset = leveledDamageOffset,
			fullMaterial = fullMaterial,
			offset = offset
		};
		animData.Add(item);
	}
}
