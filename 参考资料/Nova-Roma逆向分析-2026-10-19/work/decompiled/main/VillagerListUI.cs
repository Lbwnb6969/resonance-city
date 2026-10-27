using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class VillagerListUI : MonoBehaviour
{
	public PersonListItemUI PersonListItemUIPrefab;

	public Transform ContentRectTransform;

	public ScrollRect ScrollRect;

	public GameObject findVillagersButton;

	private List<PersonListItemUI> listItems;

	private IResidence residentialSource;

	private IEmployer buildingAsEmployerSource;

	private Building buildingSource;

	private bool isResidence;

	private void Start()
	{
		for (int i = 0; i < ContentRectTransform.transform.childCount; i++)
		{
			Object.Destroy(ContentRectTransform.GetChild(i).gameObject);
		}
		listItems = new List<PersonListItemUI>(30);
		for (int j = 0; j < 30; j++)
		{
			PersonListItemUI item = Object.Instantiate(PersonListItemUIPrefab, ContentRectTransform, worldPositionStays: false);
			listItems.Add(item);
		}
	}

	public void SetDataSource(GameObject dataSource, bool isResidence)
	{
		this.isResidence = isResidence;
		residentialSource = dataSource.GetComponent<IResidence>();
		buildingSource = dataSource.GetComponent<Building>();
		buildingAsEmployerSource = dataSource.GetComponent<IEmployer>();
		ScrollRect.velocity = new Vector2(0f, -1000f);
	}

	private void Update()
	{
		if (isResidence && residentialSource != null && !residentialSource.Equals(null))
		{
			List<Villager> residents = residentialSource.GetResidents();
			for (int i = 0; i < listItems.Count; i++)
			{
				if (i < residents.Count)
				{
					listItems[i].Description.text = residents[i].name;
					listItems[i].Villager = residents[i];
					listItems[i].SetHohIconVisible(residents[i].job != null && residents[i].job.employer == buildingAsEmployerSource);
					Util.SetActive(listItems[i].tiredIcon, residents[i].thought.thought == ThoughtBubbleSystem.Thought.Tired);
					listItems[i].gameObject.SetActive(value: true);
				}
				else
				{
					listItems[i].gameObject.SetActive(value: false);
				}
			}
		}
		else if (buildingSource != null)
		{
			List<Job> jobs = buildingSource.jobs;
			for (int j = 0; j < listItems.Count; j++)
			{
				if (j < jobs.Count && jobs[j] != null && jobs[j].HasEmployee())
				{
					listItems[j].Description.text = jobs[j].Employee.name;
					listItems[j].Villager = jobs[j].Employee;
					listItems[j].gameObject.SetActive(value: true);
					Util.SetActive(listItems[j].tiredIcon, jobs[j].Employee.thought.thought == ThoughtBubbleSystem.Thought.Tired);
					listItems[j].SetHohIconVisible(visible: false);
				}
				else
				{
					listItems[j].gameObject.SetActive(value: false);
				}
			}
		}
		else
		{
			for (int k = 0; k < listItems.Count; k++)
			{
				listItems[k].gameObject.SetActive(value: false);
			}
		}
	}
}
