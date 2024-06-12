Shader "Unlit/Slash"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _BlackCondition ("Black Condition", Range(0, 1)) = 0.01
        _Color ("Color", Color) = (1,1,1,1)
        _ColorPower ("Color Power", Range(1, 10)) = 1
        
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "RenderType"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uvNoise : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float4 _MainTex_ST;
            float4 _NoiseTex_ST;
            float _BlackCondition;
            float4 _Color;
            float _ColorPower;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); 
                o.uvNoise = TRANSFORM_TEX(v.uv, _NoiseTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float cond = min(min(step(_BlackCondition, col.r), step(_BlackCondition, col.g)), step(_BlackCondition, col.b));
                col = cond * col * _Color * fixed4(_ColorPower.xxx, 1.) + (1 - cond) * fixed4(0, 0, 0, 1 - tex2D(_NoiseTex, i.uvNoise).x);
                col.w = clamp(col.w - abs(cos(_Time.y)), 0, 1);
                return col;
            }
            ENDCG
        }
    }
}
