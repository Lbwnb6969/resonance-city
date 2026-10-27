using UnityEngine;

public class FirstPersonController : MonoBehaviour
{
	[Header("Movement Settings")]
	public float walkSpeed = 5f;

	public float runSpeed = 10f;

	public float jumpForce = 8f;

	public float gravity = 20f;

	[Header("Mouse Look Settings")]
	public float mouseSensitivity = 2f;

	public float verticalLookRange = 60f;

	[Header("Water Settings")]
	public float waterLevel = 0.25f;

	public float waterWalkSpeed = 2f;

	private CharacterController characterController;

	private Camera fpCamera;

	private Vector3 moveDirection;

	private Vector3 velocity;

	private float verticalRotation;

	private bool isGrounded;

	private bool isInWater;

	private bool isRunning;

	private void Awake()
	{
		SetupFirstPersonRig();
	}

	private void SetupFirstPersonRig()
	{
		characterController = gameObject.GetComponent<CharacterController>();
		characterController.enableOverlapRecovery = true;
		if (fpCamera == null)
		{
			CreateClonedFirstPersonCamera();
		}
		Cursor.lockState = CursorLockMode.Locked;
		Cursor.visible = false;
	}

	private void CreateClonedFirstPersonCamera()
	{
		Cam inst = Cam.inst;
		if (inst == null)
		{
			Debug.LogError("Cannot find main Cam component to clone from!");
			return;
		}
		GameObject gameObject = Object.Instantiate(inst.gameObject);
		gameObject.name = "FirstPersonCamera";
		gameObject.transform.SetParent(transform);
		gameObject.transform.localPosition = new Vector3(0f, characterController.height * 0.9f, 0f);
		gameObject.transform.localRotation = Quaternion.identity;
		fpCamera = gameObject.GetComponent<Camera>();
		Cam component = gameObject.GetComponent<Cam>();
		if (component != null)
		{
			Object.DestroyImmediate(component);
		}
		fpCamera.fieldOfView = 75f;
		fpCamera.nearClipPlane = 0.01f;
		fpCamera.farClipPlane = 1000f;
		Debug.Log("First person camera created with cloned visual effects");
	}

	private void Update()
	{
		AdjustNumbers();
		HandleMouseLook();
		HandleMovement();
		CheckWater();
		HandleInput();
	}

	public void AdjustNumbers()
	{
		characterController.center = new Vector3(0f, characterController.height * 0.5f, 0f);
	}

	private void HandleMouseLook()
	{
		float num = Input.GetAxis("Mouse X") * mouseSensitivity;
		float num2 = Input.GetAxis("Mouse Y") * mouseSensitivity;
		transform.Rotate(Vector3.up * num);
		verticalRotation -= num2;
		verticalRotation = Mathf.Clamp(verticalRotation, 0f - verticalLookRange, verticalLookRange);
		fpCamera.transform.localRotation = Quaternion.Euler(verticalRotation, 0f, 0f);
	}

	private void HandleMovement()
	{
		float axis = Input.GetAxis("Horizontal");
		float axis2 = Input.GetAxis("Vertical");
		isRunning = Input.GetKey(KeyCode.LeftShift);
		if (axis != 0f || axis2 != 0f)
		{
			Debug.Log($"Input detected: H={axis}, V={axis2}");
		}
		Vector3 vector = transform.TransformDirection(Vector3.forward);
		Vector3 vector2 = transform.TransformDirection(Vector3.right);
		moveDirection = (vector * axis2 + vector2 * axis).normalized;
		float num;
		if (isInWater)
		{
			num = waterWalkSpeed;
		}
		else
		{
			num = (isRunning ? runSpeed : walkSpeed);
		}
		moveDirection *= num;
		if (isGrounded && Input.GetButtonDown("Jump") && !isInWater)
		{
			velocity.y = jumpForce;
		}
		if (!isGrounded)
		{
			velocity.y -= gravity * Time.deltaTime;
		}
		Vector3 vector3 = moveDirection + Vector3.up * velocity.y;
		Debug.Log(velocity.y);
		Vector3 vector4 = vector3 * Time.deltaTime;
		if (vector4.magnitude > 0.001f)
		{
			Debug.Log($"Moving character: {vector4}, CharacterController enabled: {characterController.enabled}");
		}
		characterController.Move(vector4);
		isGrounded = characterController.isGrounded;
	}

	private void CheckWater()
	{
		Vector3 position = transform.position;
		float groundHeight = TerrainGen.inst.GetGroundHeight(position.x, position.z);
		isInWater = groundHeight < waterLevel && position.y <= waterLevel + 0.5f;
		if (isInWater && position.y < waterLevel)
		{
			position.y = waterLevel;
			transform.position = position;
			velocity.y = 0f;
		}
	}

	private void HandleInput()
	{
		if (Input.GetKeyDown(KeyCode.Escape) || Input.GetKeyDown(KeyCode.F))
		{
			FirstPersonManager.inst.ExitFirstPerson();
		}
	}

	private bool CheckGrounded()
	{
		Vector3 position = transform.position;
		float groundHeight = TerrainGen.inst.GetGroundHeight(position.x, position.z);
		float num = position.y + characterController.center.y - characterController.height * 0.5f;
		float num2 = 0.1f;
		return num <= groundHeight + num2;
	}

	public void SetPosition(Vector3 position)
	{
		characterController.enabled = false;
		transform.position = position;
		characterController.enabled = true;
	}

	public void SetRotation(float yRotation)
	{
		transform.rotation = Quaternion.Euler(0f, yRotation, 0f);
		verticalRotation = 0f;
		fpCamera.transform.localRotation = Quaternion.identity;
	}

	public Camera GetCamera()
	{
		return fpCamera;
	}

	public bool IsInWater()
	{
		return isInWater;
	}
}
