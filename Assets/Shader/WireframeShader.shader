Shader "Custom/WireframeShader" {
    SubShader {
        Tags { 
            "LightMode" = "Wireframe"
        }
        Pass {
            Cull Front // Render the back faces
            ZWrite Off // Disable depth writing
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc" // Include Unity's common shader functions

            struct appdata_t {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 pos : SV_POSITION;
            };

            v2f vert(appdata_t v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // Correctly calculate clip space position
                return o;
            }

            float4 frag(v2f i) : SV_Target {
                return float4(1, 1, 1, 1); // White color for wireframe
            }
            ENDHLSL
        }
    }
}
