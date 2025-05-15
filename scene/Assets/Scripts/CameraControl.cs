using UnityEngine;

//The script is modified from: https://discussions.unity.com/t/fly-cam-simple-cam-script/428226 done by Windexglow
public class FlyCamera : MonoBehaviour
{
    public float movementSpeed = 100.0f; // Regular movement speed
    public float sprintSpeedMultiplier = 250.0f; // Multiplier for sprint speed when holding shift
    public float maxSprintSpeed = 1000.0f; // Maximum speed when holding shift
    public float mouseSensitivity = 0.25f; // Sensitivity for mouse input
    private Vector3 previousMousePosition = new Vector3(255, 255, 255); // Stores the previous mouse position for calculating movement
    private float sprintTimeFactor = 1.0f; // Tracks the time factor for sprinting speed (accumulates over time when shift is held)

    void Update()
    {
        // If the Left Alt key is pressed, disable camera movement (e.g., when using other tools or UI)
        if (Input.GetKey(KeyCode.LeftAlt))
        {
            return;
        }

        // Calculate mouse movement for camera rotation
        Vector3 mouseDelta = Input.mousePosition - previousMousePosition;
        mouseDelta = new Vector3(-mouseDelta.y * mouseSensitivity, mouseDelta.x * mouseSensitivity, 0);

        // Apply mouse movement to camera rotation (pitch and yaw)
        mouseDelta = new Vector3(transform.eulerAngles.x + mouseDelta.x, transform.eulerAngles.y + mouseDelta.y, 0);
        transform.eulerAngles = mouseDelta;

        // Update the previous mouse position for the next frame
        previousMousePosition = Input.mousePosition;

        // Keyboard input for movement
        Vector3 movementDirection = GetMovementInput();

        if (movementDirection.sqrMagnitude > 0) // Only move if there's an active input
        {
            // If Left Shift is held, increase the speed (sprinting)
            if (Input.GetKey(KeyCode.LeftShift))
            {
                sprintTimeFactor += Time.deltaTime; // Increase sprinting factor over time
                movementDirection *= sprintTimeFactor * sprintSpeedMultiplier;

                // Clamp movement speed to maximum sprint speed
                movementDirection.x = Mathf.Clamp(movementDirection.x, -maxSprintSpeed, maxSprintSpeed);
                movementDirection.y = Mathf.Clamp(movementDirection.y, -maxSprintSpeed, maxSprintSpeed);
                movementDirection.z = Mathf.Clamp(movementDirection.z, -maxSprintSpeed, maxSprintSpeed);
            }
            else
            {
                sprintTimeFactor = Mathf.Clamp(sprintTimeFactor * 0.5f, 1f, 1000f); // Slow down the sprinting factor when shift is not pressed
                movementDirection *= movementSpeed; // Use normal movement speed
            }

            // Move the camera (scaled by Time.deltaTime for frame rate independence)
            movementDirection *= Time.deltaTime;

            Vector3 newPosition = transform.position;

            // If Space is pressed, limit the movement to the X and Z axes only (ignores Y-axis movement)
            if (Input.GetKey(KeyCode.Space))
            {
                transform.Translate(movementDirection);
                newPosition.x = transform.position.x;
                newPosition.z = transform.position.z;
                transform.position = newPosition;
            }
            else
            {
                transform.Translate(movementDirection); // Move freely in all directions
            }
        }
    }

    private Vector3 GetMovementInput()
    {
        // Returns a vector representing the movement direction based on input keys
        Vector3 inputDirection = new Vector3();

        // W key for forward movement
        if (Input.GetKey(KeyCode.W))
        {
            inputDirection += new Vector3(0, 0, 1);
        }
        // S key for backward movement
        if (Input.GetKey(KeyCode.S))
        {
            inputDirection += new Vector3(0, 0, -1);
        }
        // A key for left movement
        if (Input.GetKey(KeyCode.A))
        {
            inputDirection += new Vector3(-1, 0, 0);
        }
        // D key for right movement
        if (Input.GetKey(KeyCode.D))
        {
            inputDirection += new Vector3(1, 0, 0);
        }
        // Q key for downward movement (along the Y axis)
        if (Input.GetKey(KeyCode.Q))
        {
            inputDirection += new Vector3(0, -1, 0);
        }
        // E key for upward movement (along the Y axis)
        if (Input.GetKey(KeyCode.E))
        {
            inputDirection += new Vector3(0, 1, 0);
        }

        return inputDirection;
    }
}
