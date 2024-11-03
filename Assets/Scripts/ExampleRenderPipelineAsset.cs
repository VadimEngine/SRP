using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;

public class ExampleRenderPipelineInstance : RenderPipeline
{
    private ExampleRenderPipelineAsset renderPipelineAsset;
    private ComputeShader rayTracingShader;
    private RenderTexture rayTracingResult;

    // New structured buffer for sphere data
    private ComputeBuffer sphereCenterBuffer;
    private ComputeBuffer sphereRadiusBuffer;
    private ComputeBuffer sphereColorBuffer ;

    private Material rayTracingMaterial;

    public ExampleRenderPipelineInstance(ExampleRenderPipelineAsset asset)
    {
        Application.targetFrameRate = 60;
        renderPipelineAsset = asset;
        rayTracingShader = renderPipelineAsset.rayTracingShader;

        rayTracingResult = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat)
        {
            enableRandomWrite = true
        };
        rayTracingResult.Create();

        // Create a material with a shader that supports alpha
        Shader shader = Shader.Find("Hidden/RayTracingAlphaBlit");
        rayTracingMaterial = new Material(shader);
    }

    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        foreach (Camera camera in cameras)
        {
            ExecuteRayTracingPass(context, camera);  // Perform ray-tracing calculations
            // Set up the command buffer
            var cmd = new CommandBuffer();

            // First, draw the skybox if available
            context.SetupCameraProperties(camera);
            if (camera.clearFlags == CameraClearFlags.Skybox && RenderSettings.skybox != null)
            {
                // Only clear once with skybox color/background if the skybox is present
                cmd.ClearRenderTarget(true, true, Color.black);
                context.ExecuteCommandBuffer(cmd);
                cmd.Release();

                context.DrawSkybox(camera); // Draw the skybox here
            }
            else
            {
                // Clear to black or designated background color if no skybox
                cmd.ClearRenderTarget(true, true, Color.black);
                context.ExecuteCommandBuffer(cmd);
                cmd.Release();
            }

            // Set up culling
            camera.TryGetCullingParameters(out var cullingParameters);
            var cullingResults = context.Cull(ref cullingParameters);

            // Draw any additional opaque geometry if needed
            ShaderTagId shaderTagId = new ShaderTagId("ExampleLightModeTag");
            var sortingSettings = new SortingSettings(camera);
            var drawingSettings = new DrawingSettings(shaderTagId, sortingSettings);
            var filteringSettings = FilteringSettings.defaultValue;

            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

            // Now overlay the ray-tracing result without clearing again
            DrawRayTracingResult(context, camera);

            // Submit all commands
            context.Submit();
        }
    }

    private void ExecuteRayTracingPass(ScriptableRenderContext context, Camera camera)
    {
        if (rayTracingShader == null) return;

        int kernelHandle = rayTracingShader.FindKernel("CSMain");
        rayTracingShader.SetTexture(kernelHandle, "resultTexture", rayTracingResult);

        rayTracingShader.SetInt("textureWidth", rayTracingResult.width);
        rayTracingShader.SetInt("textureHeight", rayTracingResult.height);

        // Example sphere data
        Vector3[] sphereCenters = { new Vector3(0, 0, 5), new Vector3(3, 0, 5) };

        float[] sphereRadii = { 1.0f, 1.5f };
        Color[] sphereColors = { Color.red, Color.blue }; // Example colors for the spheres

        sphereCenterBuffer = new ComputeBuffer(sphereCenters.Length, sizeof(float) * 3);
        sphereRadiusBuffer = new ComputeBuffer(sphereRadii.Length, sizeof(float));
        sphereColorBuffer = new ComputeBuffer(sphereColors.Length, sizeof(float) * 3);

        sphereCenterBuffer.SetData(sphereCenters);
        sphereRadiusBuffer.SetData(sphereRadii);
        sphereColorBuffer.SetData(sphereColors.Select(c => new Vector3(c.r, c.g, c.b)).ToArray());

        rayTracingShader.SetBuffer(kernelHandle, "sphereCenters", sphereCenterBuffer);
        rayTracingShader.SetBuffer(kernelHandle, "sphereRadii", sphereRadiusBuffer);
        rayTracingShader.SetBuffer(kernelHandle, "sphereColors", sphereColorBuffer); // Set the color buffer
        rayTracingShader.SetInt("sphereCount", sphereCenters.Length);

        // Get and set the camera view matrix
        Matrix4x4 viewMatrix = camera.worldToCameraMatrix;
        rayTracingShader.SetMatrix("viewMatrix", viewMatrix);

        // Optionally, set the light direction as before
        rayTracingShader.SetVector("lightDirection", new Vector3(0, 0, -1).normalized);

        int threadGroupsX = Mathf.CeilToInt(rayTracingResult.width / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(rayTracingResult.height / 8.0f);
        rayTracingShader.Dispatch(kernelHandle, threadGroupsX, threadGroupsY, 1);
    }

    private void DrawRayTracingResult(ScriptableRenderContext context, Camera camera)
    {
        var cmd = new CommandBuffer { name = "Draw Ray Tracing Result" };

        // Set blending mode for transparency
        cmd.SetRenderTarget(BuiltinRenderTextureType.CameraTarget);
        cmd.SetGlobalTexture("_MainTex", rayTracingResult);
        
        cmd.Blit(rayTracingResult, BuiltinRenderTextureType.CameraTarget, rayTracingMaterial);
        context.ExecuteCommandBuffer(cmd);
        cmd.Release();
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        rayTracingResult.Release();

        if (sphereCenterBuffer != null)
            sphereCenterBuffer.Release();
        if (sphereRadiusBuffer != null)
            sphereRadiusBuffer.Release();
        if (sphereColorBuffer != null)
            sphereColorBuffer.Release();
    }
}