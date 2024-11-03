Shader "Custom/Tessellation" {
    Properties {
        _Tess ("Tessellation", Range(1, 32)) = 4
        _Color ("Color", Color) = (1, 1, 1, 1) // Color property
        _WaveHeight ("Wave Height", Float) = 0.5 // Height of the dents/raises
        _WaveFrequency ("Wave Frequency", Float) = 3.0 // Frequency of the wave pattern
        _LightDir ("Light Direction", Vector) = (0, 1, 0, 0)  // Frequency of the wave pattern
        _Shininess ("Shininess", Float) = 20.0 // Height of the dents/raises
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 0)  // Frequency of the wave pattern
    }

    SubShader {
        Tags { "LightMode" = "ExampleLightModeTag"}
        pass {
            HLSLPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma geometry geom
            #pragma fragment frag

            struct VertexData {
                float4 position : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct GeometryData {
                float4 position : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct TessellationData {
                float4 position : INTERNALTESSPOS;
                float3 normal : NORMAL;
                float2 uv: TEXCOORD0;
            };

            struct TessellationFactors {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            /*
            Applying nointerpolation to attributes that don’t need interpolation, such as tessellation factors and uniforms, could slightly improve performance:
            */
            float _Tess;
            float4 _Color;
            float _WaveHeight;
            float _WaveFrequency;
            float4 _Time;
            float4 _LightDir;
            float _Shininess;
            float4 _SpecularColor; 

            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;

            TessellationData vert(VertexData v) {
                TessellationData p;
                p.position = v.position;
                p.normal = v.normal;
                p.uv = v.uv;
                return p;
            }
            
            /*
            Instead of hard-coding the tessellation level to _Tess, you can adjust it dynamically based on distance to the camera. For example:
            */
            TessellationFactors patchFunc(InputPatch<TessellationData, 3> patch) {
                TessellationFactors f;
                f.edge[0] = _Tess;
                f.edge[1] = _Tess;
                f.edge[2] = _Tess;
                f.inside = _Tess;
                return f;
            }

            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("integer")]
            [patchconstantfunc("patchFunc")]
            TessellationData hull(InputPatch<TessellationData, 3> patch, uint id: SV_OutputControlPointID) {
                return patch[id];
            }

            inline GeometryData vertexProgram(VertexData tessellated) {
                GeometryData toFrag;
                float4 worldPos = mul(unity_ObjectToWorld, tessellated.position);
                toFrag.position = mul(unity_MatrixVP, worldPos);
                toFrag.normal = tessellated.normal;
                toFrag.uv = tessellated.uv;
                return toFrag;
            }

            [domain("tri")]
            GeometryData domain(TessellationFactors factors, OutputPatch<TessellationData, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) {
                VertexData data;

                data.position = float4(
                    patch[0].position.xyz * barycentricCoordinates.x +
                    patch[1].position.xyz * barycentricCoordinates.y +
                    patch[2].position.xyz * barycentricCoordinates.z,
                    patch[0].position.w * barycentricCoordinates.x +
                    patch[1].position.w * barycentricCoordinates.y +
                    patch[2].position.w * barycentricCoordinates.z
                );

                data.uv = 
                    patch[0].uv * barycentricCoordinates.x +
                    patch[1].uv * barycentricCoordinates.y +
                    patch[2].uv * barycentricCoordinates.z;

                data.normal = 
                    patch[0].normal * barycentricCoordinates.x +
                    patch[1].normal * barycentricCoordinates.y +
                    patch[2].normal * barycentricCoordinates.z;

                return vertexProgram(data);
            }

            // function to create wave pattern
            float CreateWave(float2 uv) {
                return sin(uv.x * _WaveFrequency) * cos(uv.y * _WaveFrequency) * _WaveHeight;
            }

            float CreateWave_Time(float2 uv) {
                return sin(uv.x * _WaveFrequency + _Time.y) * cos(uv.y * _WaveFrequency + _Time.y) * _WaveHeight;
            }
            
            [maxvertexcount(3)]
            void geom(triangle GeometryData input[3], inout TriangleStream<GeometryData> triStream) {
                float3 adjustedPosition[3];
                float3 originalNormal;
                float3 adjustedNormal;
            
                // Calculate original positions and normal
                float3 edge1 = input[1].position.xyz - input[0].position.xyz;
                float3 edge2 = input[2].position.xyz - input[0].position.xyz;
                originalNormal = normalize(cross(edge1, edge2));
            
                // Calculate adjusted positions and store the adjusted normals
                for (int i = 0; i < 3; ++i) {
                    float offset = CreateWave(input[i].uv);
                    adjustedPosition[i] = input[i].position.xyz;
                    adjustedPosition[i].y += offset; // Apply displacement
                }
            
                // Calculate adjusted edges in counter-clockwise order
                edge1 = adjustedPosition[1] - adjustedPosition[0];
                edge2 = adjustedPosition[2] - adjustedPosition[0];
                adjustedNormal = normalize(cross(edge1, edge2));
            
                // Calculate the difference between adjusted and original normals
                float3 normalDiff = adjustedNormal - originalNormal;
            
                for (int i = 0; i < 3; ++i) {
                    GeometryData output;
                    output.position = float4(adjustedPosition[i], input[i].position.w);
                    
                    // Use the original normal and add the normal difference
                    output.normal = normalize(input[i].normal + normalDiff); 
                    output.uv = input[i].uv;
            
                    triStream.Append(output);
                }
            }
            
            float4 frag(GeometryData s) : SV_TARGET {
                // Calculate the view direction using the inverse of the view-projection matrix
                float4 clipPos = mul(unity_MatrixVP, s.position);
                float4 worldPos = mul(unity_ObjectToWorld, clipPos);
                float3 viewDir = normalize(worldPos.xyz); // Transforming the position to world space
            
                float3 lightDir = normalize(-_LightDir);
                float nDotL = max(dot(s.normal, lightDir), 0);
            
                // Ambient, diffuse, and specular calculations
                float3 ambient = 0.1 * _Color.rgb; // Adjust ambient factor as needed
                float3 diffuse = nDotL * _Color.rgb;
            
                // Calculate reflection vector for specular component
                float3 reflectDir = reflect(-lightDir, s.normal);
                float specularStrength = pow(max(dot(viewDir, reflectDir), 0), _Shininess); // Use shininess factor for specular highlights
                float3 specular = specularStrength * _SpecularColor.rgb;
            
                // Combine components
                float3 finalColor = ambient + diffuse + specular;
            
                return float4(finalColor, _Color.a);
            }
            ENDHLSL
        }
    }
}
