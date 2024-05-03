using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TheOneWhoChange : MonoBehaviour
{
    TheOneWhoBeingChanged theOneWhoBeingChanged;
    public float changeVelocity;
    // Start is called before the first frame update
    void Start()
    {
        theOneWhoBeingChanged = GetComponent<TheOneWhoBeingChanged>();
    }

    // Update is called once per frame
    void Update()
    {
        theOneWhoBeingChanged.Rigidbody.velocity = new Vector3(changeVelocity, 0, 0);
    }
}
