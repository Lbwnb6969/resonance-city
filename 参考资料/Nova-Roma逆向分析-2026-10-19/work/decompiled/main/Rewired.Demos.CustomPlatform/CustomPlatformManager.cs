using Rewired.Platforms.Custom;
using UnityEngine;

namespace Rewired.Demos.CustomPlatform;

public sealed class CustomPlatformManager : MonoBehaviour, ICustomPlatformInitializer
{
	public CustomPlatformHardwareJoystickMapProvider mapProvider;

	public CustomPlatformInitOptions GetCustomPlatformInitOptions()
	{
		CustomPlatformInitOptions customPlatformInitOptions = new CustomPlatformInitOptions
		{
			platformId = 0,
			platformIdentifierString = "MyPlatform",
			hardwareJoystickMapCustomPlatformMapProvider = mapProvider
		};
		CustomPlatformConfigVars configVars = new CustomPlatformConfigVars
		{
			ignoreInputWhenAppNotInFocus = true,
			useNativeKeyboard = true,
			useNativeMouse = true
		};
		customPlatformInitOptions.inputSource = new MyPlatformInputSource(configVars);
		return customPlatformInitOptions;
	}
}
