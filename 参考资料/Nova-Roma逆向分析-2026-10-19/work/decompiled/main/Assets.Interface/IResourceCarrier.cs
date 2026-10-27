namespace Assets.Interface;

public interface IResourceCarrier
{
	void DropResources();

	void PickupResource(FreeResource resource, bool playSfx = true);
}
