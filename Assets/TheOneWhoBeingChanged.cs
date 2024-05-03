using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TheOneWhoBeingChanged : MonoBehaviour
{
    new private Rigidbody rigidbody;

    public Rigidbody Rigidbody { get => rigidbody; set => rigidbody = value; }

    void Awake()
    {
        rigidbody = GetComponent<Rigidbody>();
    }
    // Start is called before the first frame update
    void Start()
    {
        StartCoroutine(LogVelocity());
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    IEnumerator LogVelocity()
    {
        while (true)
        {
            Debug.Log(rigidbody.velocity);
            yield return new WaitForSeconds(3);
        }
    }
}
