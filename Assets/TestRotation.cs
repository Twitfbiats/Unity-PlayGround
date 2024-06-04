using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TestRotation : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        StartCoroutine(LogRotationEvery1s());
    }

    IEnumerator LogRotationEvery1s()
    {
        while (true)
        {
            Debug.Log("Rotation: " + transform.rotation.eulerAngles);
            yield return new WaitForSeconds(1);
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
