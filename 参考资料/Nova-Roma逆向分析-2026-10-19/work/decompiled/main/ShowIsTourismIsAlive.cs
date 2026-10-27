using UnityEngine;

public class ShowIsTourismIsAlive : MonoBehaviour
{
	private void Start()
	{
		SaveRepo.ServerIsAlive((bool b) =>
		{
			gameObject.SetActive(b);
		});
	}
}
