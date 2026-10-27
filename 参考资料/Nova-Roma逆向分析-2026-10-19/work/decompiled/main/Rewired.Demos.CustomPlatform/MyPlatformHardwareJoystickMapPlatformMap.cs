using System;
using System.Collections.Generic;
using Rewired.Data.Mapping;
using Rewired.Platforms.Custom;

namespace Rewired.Demos.CustomPlatform;

public sealed class MyPlatformHardwareJoystickMapPlatformMap : HardwareJoystickMapCustomPlatformMapSO
{
	[Serializable]
	public class PlatformMapBase : HardwareJoystickMapCustomPlatformMap<MatchingCriteria>
	{
		protected override object CreateInstance()
		{
			return new PlatformMapBase();
		}
	}

	[Serializable]
	public sealed class PlatformMap : PlatformMapBase
	{
		public PlatformMapBase[] variants;

		public override IList<HardwareJoystickMap.Platform> GetVariants()
		{
			return variants;
		}

		protected override object CreateInstance()
		{
			return new PlatformMap();
		}
	}

	[Serializable]
	public sealed class MatchingCriteria : HardwareJoystickMapCustomPlatformMap.MatchingCriteria
	{
		public uint vendorId;

		public uint productId;

		public override bool Matches(object customIdentifier)
		{
			if (!(customIdentifier is MyPlatformControllerIdentifier myPlatformControllerIdentifier))
			{
				return false;
			}
			if (myPlatformControllerIdentifier.productId == productId)
			{
				return myPlatformControllerIdentifier.vendorId == vendorId;
			}
			return false;
		}

		protected override object CreateInstance()
		{
			return new MatchingCriteria();
		}

		protected override void DeepClone(object destination)
		{
			base.DeepClone(destination);
			MatchingCriteria matchingCriteria = (MatchingCriteria)destination;
			matchingCriteria.vendorId = vendorId;
			matchingCriteria.productId = productId;
		}
	}

	public PlatformMap platformMap;

	public override HardwareJoystickMap.Platform GetPlatformMap()
	{
		return platformMap;
	}
}
