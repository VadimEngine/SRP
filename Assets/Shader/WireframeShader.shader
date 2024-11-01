Shader "Custom/WireframeShader"
{
    Properties
    {
        _Color ("Wire Color", Color) = (1,1,1,1)
        _WireThickness ("Wire Thickness", Float) = 1.0
    }
    SubShader
    {
        Tags { "LightMode" = "ExampleLightModeTag"}
        LOD 100

        Pass
        {
            Cull Front
            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom

            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 color : COLOR;
                float3 worldPos : TEXCOORD0; // Added world position for geometry calculations
            };

            // Uniforms
            float4 _Color;
            float _WireThickness;

            v2f vert(appdata_t v)
            {
                v2f o = (v2f)0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.color = _Color;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; // Convert to world position
                return o;
            }

            [maxvertexcount(6)]
            void geom(triangle v2f input[3], inout LineStream<v2f> lineStream)
            {
                // Draw lines between the vertices
                for (int i = 0; i < 3; i++)
                {
                    // Calculate the next vertex index, looping back to the first vertex
                    int next = (i + 1) % 3;

                    // Initialize 'o' with the first vertex's position and color
                    v2f o = (v2f)0;
                    o.color = input[i].color;

                    // Set the first vertex of the line
                    o.pos = input[i].pos;
                    lineStream.Append(o);

                    // Set the second vertex of the line
                    o.pos = input[next].pos;
                    lineStream.Append(o);
                }
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return i.color;
            }
            ENDHLSL
        }
    }
}
