using UnityEngine;

public class BathJob : Job
{
	private enum State
	{
		GoingToBath,
		Bathing,
		Waiting
	}

	private float totalTime;

	private Timer posUpdate = new Timer(1f);

	private Material oldBody;

	private State state;

	private Bathhouse bathhouse;

	private Vector3 workPos;

	private Vector3 oldPos;

	public BathJob(IEmployer e)
		: base(e)
	{
		totalTime = SRand.value * 1000f;
		bathhouse = (e as MonoBehaviour).GetComponent<Bathhouse>();
	}

	public Vector3 GetWaitingPositionForPerson(Villager person)
	{
		Building component = bathhouse.GetComponent<Building>();
		int value = -1;
		for (int i = 0; i < component.jobs.Count; i++)
		{
			if (component.jobs[i].Employee != null && component.jobs[i].Employee.guid == person.guid)
			{
				value = i;
				break;
			}
		}
		Vector3 position = bathhouse.transform.position;
		if (bathhouse.waitingPositions.Length != 0)
		{
			Transform transform = bathhouse.waitingPositions[Mathf.Clamp(value, 0, bathhouse.waitingPositions.Length - 1)];
			if (transform != null)
			{
				position = transform.position;
			}
		}
		return position;
	}

	public override void OnEmployeeAssigned()
	{
		Employee.MoveToDeferred(employer.GetPositionForPerson(Employee));
		state = State.GoingToBath;
		base.OnEmployeeAssigned();
		Employee.instancesRef.data[(int)Employee.MeshType].bodyColors.data[Employee.s][Employee.idx] = Employee.headColor;
	}

	public override void OnEmployeeQuit()
	{
		Employee.instancesRef.data[(int)Employee.MeshType].bodyColors.data[Employee.s][Employee.idx] = Employee.bodyColor;
		base.OnEmployeeQuit();
	}

	private void SetState(State newState)
	{
		switch (newState)
		{
		case State.Bathing:
			totalTime = 0f;
			oldPos = Employee.Pos;
			posUpdate.ForceExpire();
			state = State.Bathing;
			break;
		case State.Waiting:
			totalTime = 0f;
			oldPos = Employee.Pos;
			state = State.Bathing;
			workPos = GetWaitingPositionForPerson(Employee);
			break;
		}
		state = newState;
	}

	public override void UpdateWithEmployee(float dt)
	{
		Villager villager = Employee;
		totalTime += dt;
		switch (state)
		{
		case State.GoingToBath:
			if (Vector3.Distance(employer.GetPositionForPerson(villager).position, villager.Pos) < 0.1f)
			{
				SetState(State.Bathing);
			}
			break;
		case State.Bathing:
			if (bathhouse.HasWater)
			{
				if (posUpdate.Update(dt))
				{
					posUpdate.Duration = SRand.Range(0.5f, 2f);
					workPos = employer.GetPositionForPerson(villager).position;
					workPos += new Vector3(SRand.Range(-0.1f, 0.1f), 0f, SRand.Range(-0.1f, 0.1f));
					totalTime = 0f;
					oldPos = villager.Pos;
				}
				float t2 = Mathf.Clamp01(totalTime * 0.66f);
				villager.Pos = Vector3.Lerp(oldPos, workPos, Mathf.SmoothStep(0f, 1f, t2));
			}
			else
			{
				SetState(State.Waiting);
			}
			break;
		case State.Waiting:
		{
			if (bathhouse.HasWater)
			{
				SetState(State.Bathing);
				break;
			}
			float t = Mathf.Clamp01(totalTime * 0.66f);
			villager.Pos = Vector3.Lerp(oldPos, workPos, Mathf.SmoothStep(0f, 1f, t));
			break;
		}
		}
		base.UpdateWithEmployee(dt);
	}
}
