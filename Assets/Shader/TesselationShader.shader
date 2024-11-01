Shader "Tessellation Dents and Raises Sample" {
    Properties {
        _Tess ("Tessellation", Range(1, 32)) = 4
        _Color ("Color", Color) = (1, 1, 1, 1) // Color property
        _WireColor ("Wire Color", Color) = (1, 0, 0, 1) // Wireframe color property
        _WaveHeight ("Wave Height", Float) = 0.5 // Height of the dents/raises
        _WaveFrequency ("Wave Frequency", Float) = 3.0 // Frequency of the wave pattern
    }

    SubShader {
        Tags { "LightMode" = "ExampleLightModeTag"}
        LOD 300

        // Base Pass for Tessellation
        CGPROGRAM
        #pragma surface surf Lambert tessellate:tessFixed
        #pragma target 4.6

        struct appdata {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0; // Add UV coordinates for noise
        };

        struct Input {
            float2 uv_MainTex;
        };

        float _Tess;
        float4 _Color;
        float _WaveHeight;
        float _WaveFrequency;

        // Function to create wave pattern
        float CreateWave(float2 uv) {
            return sin(uv.x * _WaveFrequency) * cos(uv.y * _WaveFrequency) * _WaveHeight;
        }

        // Tessellation Function
        float4 tessFixed() {
            return float4(_Tess, _Tess, _Tess, _Tess);
        }

        void surf(Input IN, inout SurfaceOutput o) {
            o.Albedo = _Color.rgb; // Use color property
            o.Alpha = _Color.a; // Alpha from color
        }

        ENDCG

        // Wireframe Pass
        Pass {
            Name "Wireframe"
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            ZTest LEqual
            Cull Front

            HLSLPROGRAM
            #pragma vertex WireframeVertexShader
            #pragma fragment WireframeFragmentShader
            #pragma geometry WireframeGeometryShader

            #include "UnityCG.cginc"

            struct appdata_t {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0; // Add UV coordinates
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 color : COLOR;
            };

            // Uniforms
            float4 _WireColor;
            float _WaveHeight; // Declare the wave height
            float _WaveFrequency; // Declare the wave frequency

            // Function to create wave pattern (accessible in the wireframe pass)
            float CreateWave(float2 uv) {
                return sin(uv.x * _WaveFrequency) * cos(uv.y * _WaveFrequency) * _WaveHeight;
            }

            // Vertex Shader for Wireframe Pass
            v2f WireframeVertexShader(appdata_t v) {
                v2f o;
                // Calculate the height offset using the wave function
                float offset = CreateWave(v.uv);
                v.vertex.y += offset; // Modify the vertex position for dents/raises
                o.pos = UnityObjectToClipPos(v.vertex); // Convert to clip space
                o.color = _WireColor; // Set wireframe color
                return o;
            }

            [maxvertexcount(6)]
            void WireframeGeometryShader(triangle v2f input[3], inout LineStream<v2f> lineStream) {
                // Output line segments
                for (int i = 0; i < 3; i++) {
                    int next = (i + 1) % 3;
                    lineStream.Append(input[i]); // Start vertex
                    lineStream.Append(input[next]); // End vertex
                }
            }

            float4 WireframeFragmentShader(v2f i) : SV_Target {
                return i.color; // Return the wireframe color
            }
            ENDHLSL
        }
    }

    FallBack "Diffuse"
}
