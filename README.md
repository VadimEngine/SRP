Shader "Custom/SimpleTessellationSolidColor"
{
    Properties
    {
        _Tessellation ("Tessellation Factor", Range(1, 32)) = 4
        _Color ("Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        HLSLPROGRAM
        #pragma vertex vert
        #pragma hull hull
        #pragma domain domain
        #pragma fragment frag
        #pragma target 4.6

        // Tessellation factor
        float _Tessellation;

        // Color
        float4 _Color;

        struct appdata
        {
            float4 vertex : POSITION;
        };

        struct tessControlOutput
        {
            float4 pos : POSITION;
        };

        // Hull (Tessellation Control) Shader
        [domain("tri")]
        [partitioning("integer")]
        [outputtopology("triangle_cw")]
        [patchconstantfunc("PatchConstantFunction")]
        [maxtessfactor(32)]
        tessControlOutput hull(appdata v)
        {
            tessControlOutput o;
            o.pos = v.vertex;
            return o;
        }

        // Patch Constant Function for Tessellation
        float PatchConstantFunction(float3 patch[3]) : SV_TessFactor
        {
            return _Tessellation;
        }

        // Domain (Tessellation Evaluation) Shader
        float4 domain(PatchConstantFunction In, float3 bary : SV_DomainLocation, const OutputPatch<tessControlOutput, 3> patch) : SV_Position
        {
            return bary.x * patch[0].pos + bary.y * patch[1].pos + bary.z * patch[2].pos;
        }

        // Vertex Shader
        float4 vert(appdata v) : SV_Position
        {
            return UnityObjectToClipPos(v.vertex);
        }

        // Fragment (Pixel) Shader
        float4 frag() : SV_Target
        {
            return _Color;
        }

        ENDHLSL
    }

    FallBack "Diffuse"
}
