using UnityEngine;

public class ProjectileSystem : MonoBehaviour
{
	public static ProjectileSystem inst;

	private float projectileSpeed = 9f;

	private void Start()
	{
		inst = this;
	}

	public void FireProjectile(Transform start, IProjectileHitable target, Projectile projectilePrefab, int teamID)
	{
		Vector3 position = start.position;
		Projectile obj = projectilePrefab.Alloc(position) as Projectile;
		obj.teamID = teamID;
		obj.Setup(position, projectileSpeed, target);
		float time = (position - target.GetPosition()).magnitude / projectileSpeed;
		Debug.DrawLine(target.GetPredictedPosition(time), position, Color.red);
	}

	private void Update()
	{
	}
}
