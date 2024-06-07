Shader "Test/GlowingSword"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Point1 ("Point 1", Vector) = (0,0,0,1)
        _Point2 ("Point 2", Vector) = (0,1,0,0)
        _TestFloatMin ("Test Float Min", Float) = 0.0
        _TestFloatMax ("Test Float Max", Float) = .14
        _Offset ("Offset", Float) = 0.0
        _TimeScale ("Time Scale", Float) = 2.0
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
                float vertexDistance : TEXCOORD1;
            };
            
            sampler2D _MainTex;
            fixed3 _Color;
            float4 _Point1;
            float4 _Point2;
            float _TestFloatMin;
            float _TestFloatMax;
            float _TimeScale;
            float _Offset;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertexDistance = length(cross((v.vertex - _Point1).xyz, (v.vertex - _Point2).xyz)) / length((_Point2 - _Point1).xyz);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // Sample the texture
                // float cond = step(_TestFloat, i.vertexDistance);
                fixed4 Color = lerp(fixed4(_Color, 0.), fixed4(1., 1., 1., 1.), (1 - smoothstep(0., lerp(_TestFloatMin, _TestFloatMax, abs(sin(_Time.y * _TimeScale))), i.vertexDistance + _Offset).xxxx));
                
                // Return the sampled color
                return Color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
