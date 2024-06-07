Shader "Test/Test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _RemoveBlackColor ("Remove Black Color", Float) = 0.1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha

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
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
            fixed3 _Color;
            float _RemoveBlackColor;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // Sample the texture
                fixed4 texColor = tex2D(_MainTex, i.uv);
                float cond = min(min(step(_RemoveBlackColor, texColor.r), step(_RemoveBlackColor, texColor.g)), step(_RemoveBlackColor, texColor.b)); 
                texColor = (cond * texColor + (1 - cond) * fixed4(1, 1, 1, 0)) * fixed4(_Color, 1);
                
                // Return the sampled color
                return texColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
