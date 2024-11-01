// This defines a simple unlit Shader object that is compatible with a custom Scriptable Render Pipeline.
// It applies a hardcoded color, and demonstrates the use of the LightMode Pass tag.
// It is not compatible with SRP Batcher.

Shader "Examples/SimpleTextureShader"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1) // Define the color property
        _MainTex("Main Texture", 2D) = "white" {} // Define the texture property
    }

    SubShader
    {
        Pass
        {
            // The value of the LightMode Pass tag must match the ShaderTagId in ScriptableRenderContext.DrawRenderers
            Tags { "LightMode" = "ExampleLightModeTag"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            float4 _Color;
            sampler2D _MainTex; // Texture property

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes IN) {
                Varyings OUT;
                float4 worldPos = mul(unity_ObjectToWorld, IN.positionOS);
                OUT.positionCS = mul(unity_MatrixVP, worldPos);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_TARGET
            {
                float4 texColor = tex2D(_MainTex, IN.uv);
                return texColor * _Color;
            }
            ENDHLSL
        }
    }
}