using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

public class Spawner : MonoBehaviour
{
    public VisualEffect vfx;

    void Start()
    {
        vfx = GetComponent<VisualEffect>();
    }

    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            vfx.SetFloat("TimeOffset", Time.timeSinceLevelLoad);
            vfx.Play();
        }

        //click right mouse button to stop the effect
        if (Input.GetMouseButtonDown(1))
        {
            vfx.Stop();
        }
    }
}
