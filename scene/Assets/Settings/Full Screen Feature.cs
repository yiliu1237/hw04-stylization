using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FullScreenFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class FullScreenPassSettings
    {
        public Shader m_Shader;
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        [Range(0.0f, 0.01f)]
        public float fogDensity = 1.2f;
        [Range(0.0f, 0.1f)]
        public float rayVisiblity = 0.02f;
        [Range(0.1f, 3.0f)]
        public float stepSize = 0.3f;
        [Range(2.0f, 10.0f)]
        public float ditherSize = 5.0f;
        public Color color = Color.white;
    }


    class ColorBlitPass : ScriptableRenderPass
    {
        FullScreenPassSettings m_Settings;
        ProfilingSampler m_ProfilingSampler = new ProfilingSampler("ColorBlit");
        Material m_Material;
        RTHandle m_CameraColorTarget;
        float m_Intensity;

        public ColorBlitPass(Material material, FullScreenPassSettings settings)
        {
            m_Settings = settings;
            m_Material = material;
            renderPassEvent = settings.renderPassEvent;
        }

        public void SetTarget(RTHandle colorHandle, float intensity)
        {
            m_CameraColorTarget = colorHandle;
            m_Intensity = intensity;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureTarget(m_CameraColorTarget);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cameraData = renderingData.cameraData;
            if (cameraData.camera.cameraType != CameraType.Game)
                return;

            if (m_Material == null)
                return;

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                m_Material.SetFloat("_FogDensity", m_Settings.fogDensity);
                m_Material.SetFloat("_RayVisibility", m_Settings.rayVisiblity);
                m_Material.SetFloat("_StepSize", m_Settings.stepSize);
                m_Material.SetFloat("_DitherSize", m_Settings.ditherSize);
                m_Material.SetVector("_AttenColor", new Vector4(m_Settings.color.r, m_Settings.color.g, m_Settings.color.b, m_Settings.color.a));
                // m_Material.SetTexture("_MainTex", m_CameraColorTarget);
                Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorTarget, m_Material, 0);
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            CommandBufferPool.Release(cmd);
        }
    }
    [SerializeField]
    FullScreenPassSettings m_Settings = new FullScreenPassSettings();
    // public Shader m_Shader;
    public float m_Intensity;

    Material m_Material;

    ColorBlitPass m_RenderPass = null;

    public override void AddRenderPasses(ScriptableRenderer renderer,
                                    ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
            renderer.EnqueuePass(m_RenderPass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer,
                                        in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            // Calling ConfigureInput with the ScriptableRenderPassInput.Color argument
            // ensures that the opaque texture is available to the Render Pass.
            m_RenderPass.ConfigureInput(ScriptableRenderPassInput.Color);
            m_RenderPass.SetTarget(renderer.cameraColorTargetHandle, m_Intensity);
        }
    }

    public override void Create()
    {
        m_Material = CoreUtils.CreateEngineMaterial(m_Settings.m_Shader);
        m_RenderPass = new ColorBlitPass(m_Material, m_Settings);
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(m_Material);
    }
}


