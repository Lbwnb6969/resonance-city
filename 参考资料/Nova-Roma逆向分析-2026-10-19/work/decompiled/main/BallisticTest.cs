using UnityEngine;

public class BallisticTest : MonoBehaviour
{
	public GameObject physicsObjectPrefab;

	public float speed = 10f;

	public Transform subject;

	public Transform target;

	private Timer timer = new Timer(0.1f);

	private void Update()
	{
		if (timer.Update(Time.deltaTime) && fts.solve_ballistic_arc(subject.position, speed, target.position, Mathf.Abs(Physics.gravity.y), out var _, out var s2) != 0)
		{
			Object.Instantiate(physicsObjectPrefab, subject.position, Quaternion.identity).GetComponent<Rigidbody>().AddForce(s2, ForceMode.VelocityChange);
		}
	}
}
