namespace Assets.Code.Interface;

public interface IResourceOrderable
{
	ResourceAmount DesiredResources { get; set; }

	bool IsOrderable(int resourceID);

	bool ShowLockNonSurplus();

	void SetNonSurplusPrivate(int resourceID, bool val);

	bool GetNonSurplusPrivate(int resourceID);
}
