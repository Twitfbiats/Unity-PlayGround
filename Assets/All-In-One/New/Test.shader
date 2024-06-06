Shader "Unlit/Test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TimeScale ("Time Scale", Float) = 1.0
        _FireMovement ("Fire Movement", Vector) = (-0.01, -0.5, 0, 0)
        _DistortionMovement ("Distortion Movement", Vector) = (-0.01, -0.3, 0, 0)
        _NormalStrength ("Normal Strength", Float) = 40.0
        _DistortionStrength ("Distortion Strength", Float) = 0.1
        _RemoveBlackColor ("Remove Black Color", Float) = 0.1
        _FirePower("Fire Power", Float) = 1.0
        _FireVector1("Fire Vector 1", Vector) = (2., 2., 1., 0)
        _FireVector2("Fire Vector 2", Vector) = (1., 3., 4., 0)
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _TimeScale;
            float4 _FireMovement;
            float4 _DistortionMovement;
            float _NormalStrength;
            float _DistortionStrength;
            float _RemoveBlackColor;
            float _FirePower;
            float3 _FireVector1;
            float3 _FireVector2;


            float rand(float2 co) {
                return frac(sin(dot(co.xy ,float2(12.9898,78.233))) * 43758.5453);
            }
            
            float2 hash( float2 p ) {
                p = float2( dot(p,float2(127.1,311.7)),
                        dot(p,float2(269.5,183.3)) );
            
                return -1.0 + 2.0*frac(sin(p)*43758.5453123);
            }
            
            float noise( in float2 p ) {
                const float K1 = 0.366025404; // (sqrt(3)-1)/2;
                const float K2 = 0.211324865; // (3-sqrt(3))/6;
            
                float2 i = floor( p + (p.x+p.y)*K1 );
                
                float2 a = p - i + (i.x+i.y)*K2;
                float2 o = step(a.yx,a.xy);    
                float2 b = a - o + K2;
                float2 c = a - 1.0 + 2.0*K2;
            
                float3 h = max( 0.5-float3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
            
                float3 n = h*h*h*h*float3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
            
                return dot( n, float3(70.0, 70., 70.) );
            }
            
            float fbm(float2 p) {
                float f = 0.0;
                float2x2 m = float2x2(1.6, 1.2,
                                       -1.2, 1.6);
                f += 0.5000 * noise(p); p = mul(m, p);
                f += 0.2500 * noise(p); p = mul(m, p);
                f += 0.1250 * noise(p); p = mul(m, p);
                f += 0.0625 * noise(p); p = mul(m, p);
                f = 0.5 + 0.5 * f;
                return f;
            }            
            
            
            /** DISTORTION **/
            float3 bumpMap(float2 uv) { 
                float2 s = 1. / _ScreenParams.xy;
                float p =  fbm(uv);
                float h1 = fbm(uv + s * float2(1., 0));
                float v1 = fbm(uv + s * float2(0, 1.));
                    
                    float2 xy = (p - float2(h1, v1)) * _NormalStrength;
                return float3(xy + .5, 1.);
            }
              

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float realTime = _Time.y * _TimeScale;

                float3 normal = bumpMap(uv * float2(1.0, 0.3) + _DistortionMovement * realTime);
                
                float2 displacement = clamp((normal.xy - .5) * _DistortionStrength, -1., 1.);
                uv += displacement; 
                
                float2 uvT = (uv * float2(1.0, 0.5)) + realTime * _FireMovement;
                float n = pow(fbm(8.0 * uvT), 1.0);    
                
                float gradient = pow(1.0 - uv.y, _FirePower) * 5.;
                float finalNoise = n * gradient;
                float3 color = finalNoise * float3(_FireVector1.x * pow(n, _FireVector2.x), _FireVector1.y * pow(n, _FireVector2.y), _FireVector1.z * pow(n, _FireVector2.z));
                float cond = min(min(step(_RemoveBlackColor, color.x), step(_RemoveBlackColor, color.y)), step(_RemoveBlackColor, color.z));

                return float4(color, 1.) * cond + float4(0., 0., 0., 0.) * (1. - cond);
            }
            ENDCG
        }
    }
}
