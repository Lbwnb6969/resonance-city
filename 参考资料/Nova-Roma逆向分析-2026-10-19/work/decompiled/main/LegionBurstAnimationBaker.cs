using System.Collections.Generic;
using System.Linq;
using Unity.Collections;
using Unity.Entities;
using UnityEngine;

public class LegionBurstAnimationBaker : MonoBehaviour
{
	public enum Animations
	{
		Stabby = 1,
		Dodge,
		DodgeLeft,
		Idle1,
		Idle2,
		Battlecheer,
		Die1,
		ShieldWallRow2,
		ShieldWallRow2a
	}

	public enum Entity
	{
		PersonPositionX,
		PersonPositionY,
		PersonPositionZ,
		PersonRotationX,
		PersonRotationY,
		PersonRotationZ,
		SwordPositionX,
		SwordPositionY,
		SwordPositionZ,
		SwordRotationX,
		SwordRotationY,
		SwordRotationZ,
		ShieldPositionX,
		ShieldPositionY,
		ShieldPositionZ,
		ShieldRotationX,
		ShieldRotationY,
		ShieldRotationZ
	}

	public struct OneAnimation
	{
		public BlobArray<NativeCurve> Curves;
	}

	public struct AllAnimations
	{
		public BlobArray<OneAnimation> Animations;
	}

	public List<AnimationClip> animations;

	public List<string> entityNames;

	public static LegionBurstAnimationBaker inst;

	public LegionAnimationDataStorage animationDataStorageCache;

	public string animationDataStorageCachePath = "Assets/LegionAnimationDataStorage.asset";

	public List<string> nameMatches = new List<string>
	{
		"Personm_LocalPosition.x", "Personm_LocalPosition.y", "Personm_LocalPosition.z", "PersonlocalEulerAnglesRaw.x", "PersonlocalEulerAnglesRaw.y", "PersonlocalEulerAnglesRaw.z", "Swordm_LocalPosition.x", "Swordm_LocalPosition.y", "Swordm_LocalPosition.z", "SwordlocalEulerAnglesRaw.x",
		"SwordlocalEulerAnglesRaw.y", "SwordlocalEulerAnglesRaw.z", "Shieldm_LocalPosition.x", "Shieldm_LocalPosition.y", "Shieldm_LocalPosition.z", "ShieldlocalEulerAnglesRaw.x", "ShieldlocalEulerAnglesRaw.y", "ShieldlocalEulerAnglesRaw.z"
	};

	private void Awake()
	{
		inst = this;
	}

	public BlobAssetReference<AllAnimations> GetAnimationBlob()
	{
		if (animationDataStorageCache == null)
		{
			Debug.LogError("Animation data storage cache is not set!");
			return default;
		}
		BlobBuilder blobBuilder = new BlobBuilder(Allocator.Temp);
		ref AllAnimations reference = ref blobBuilder.ConstructRoot<AllAnimations>();
		int num = nameMatches.Count();
		int num2 = animationDataStorageCache.data.Length / num;
		BlobBuilderArray<OneAnimation> blobBuilderArray = blobBuilder.Allocate(ref reference.Animations, num2);
		for (int i = 0; i < num2; i++)
		{
			blobBuilderArray[i] = default;
			BlobBuilderArray<NativeCurve> blobBuilderArray2 = blobBuilder.Allocate(ref blobBuilderArray[i].Curves, num);
			for (int j = 0; j < num; j++)
			{
				int num3 = i * num + j;
				blobBuilderArray2[j] = animationDataStorageCache.data[num3].ToNative();
			}
		}
		return blobBuilder.CreateBlobAssetReference<AllAnimations>(Allocator.Persistent);
	}
}
