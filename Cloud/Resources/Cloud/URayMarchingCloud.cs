using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using static Unity.VisualScripting.Member;
using static UnityEngine.Rendering.Universal.Internal.URayMarchingCloud;

namespace UnityEngine.Rendering.Universal.Internal
{


    public class URayMarchingCloud : ScriptableRendererFeature
    {

        public static readonly int isInUICamera = Shader.PropertyToID("_IsInUICamera");
        [System.Serializable]
        public class RayMarchingCloudSetting
        {
            public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
            public Material BlitMaterial;

        }

        URayMarchingCloudPass m_ScriptablePass;
        RenderTargetHandle m_CameraColorAttachment;
        RTHandle destination;

        public RayMarchingCloudSetting m_CustomFirstBlitSetting = new RayMarchingCloudSetting();

        public override void Create()
        {
            m_ScriptablePass = new URayMarchingCloudPass(m_CustomFirstBlitSetting.renderPassEvent);

            m_CameraColorAttachment.Init("_CameraColorTexture");
            var m_MagentaTexture = new Texture2D(1, 1, GraphicsFormat.R8G8B8A8_SRGB, TextureCreationFlags.None) { name = "Cloud" };
            m_MagentaTexture.SetPixel(0, 0, Color.magenta);
            m_MagentaTexture.Apply();
            destination = RTHandles.Alloc(m_MagentaTexture);

        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.postProcessEnabled)
            {
                ref CameraData cameraData = ref renderingData.cameraData;

                RenderTextureDescriptor cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;
                m_ScriptablePass.Setup(cameraTargetDescriptor, m_CameraColorAttachment, m_CustomFirstBlitSetting.BlitMaterial);
                renderer.EnqueuePass(m_ScriptablePass);
            }
        }
    }

    public class URayMarchingCloudPass : ScriptableRenderPass
    {
        const string m_ProfilerTag = "RayMarchingCloud(射线步进体积云)";
        RTHandle m_Source;

        Color baseColor;
        Material m_BlitMaterial;
        TextureDimension m_TargetDimension;
        RenderTextureDescriptor m_Descriptor;
        RayMarchingCloudSetting m_rayMarchingCloudSetting;
        public static readonly int _RayMarchingCloud = Shader.PropertyToID("_RayMarchingCloud");
        RTHandle destination;
        RenderTargetIdentifier destinationBuffer;
        RenderTargetIdentifier cameraColorTarget;
        public URayMarchingCloudPass(RenderPassEvent evt)

        {
            renderPassEvent = evt;
        }


        public void Setup(RenderTextureDescriptor baseDescriptor, RenderTargetHandle colorHandle, Material BlitMaterial)
        {

            m_BlitMaterial = BlitMaterial;
            m_Descriptor = baseDescriptor;
            m_TargetDimension = baseDescriptor.dimension;
        }

        /// <inheritdoc/>
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var stack = VolumeManager.instance.stack;
            m_rayMarchingCloudSetting = stack.GetComponent<RayMarchingCloudSetting>();
            baseColor = m_rayMarchingCloudSetting.tint.value;

            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            if (m_BlitMaterial)
                render(cmd, ref renderingData);


            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }


        public void render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var material = m_BlitMaterial;

            ref CameraData cameraData = ref renderingData.cameraData;
            ref ScriptableRenderer renderer = ref cameraData.renderer;
            material.SetColor("_BaseColor", baseColor);
            material.SetVector("_BoundMin", m_rayMarchingCloudSetting.BoundMin.value);
            material.SetVector("_BoundMax", m_rayMarchingCloudSetting.BoundMax.value);
            material.SetVector("_Noise3DOffSet", m_rayMarchingCloudSetting.Noise3DOffSet.value);
            material.SetVector("_Noise3DScale", m_rayMarchingCloudSetting.Noise3DScale.value / 100);
            material.SetTexture("_Noise3D", m_rayMarchingCloudSetting.Noise3D.value);

            material.SetVector("_MoveSpeed", m_rayMarchingCloudSetting.MoveSpeed.value);
            material.SetTexture("_FractalNoise3D", m_rayMarchingCloudSetting.FractalNoise3D.value);
            material.SetVector("_FractalNoise3DOffSet", m_rayMarchingCloudSetting.FractalNoise3DOffSet.value);
            material.SetVector("_FractalNoise3DScale", m_rayMarchingCloudSetting.FractalNoise3DScale.value / 100);
            material.SetFloat("_DensityScale", m_rayMarchingCloudSetting.DensityScale.value);
            material.SetVector("_EdgeSoftnessThreshold", m_rayMarchingCloudSetting.EdgeSoftnessThreshold.value);

            material.SetTexture("_WeatherMap", m_rayMarchingCloudSetting.WeatherMap.value);
            material.SetTexture("_BlueNoise", m_rayMarchingCloudSetting.BlueNoise.value);
            material.SetTexture("_MaskNoise", m_rayMarchingCloudSetting.MaskNoise.value);


            material.SetFloat("_Attenuation", m_rayMarchingCloudSetting.Attenuation.value);
            material.SetFloat("_LightPower", m_rayMarchingCloudSetting.LightPower.value);
            material.SetFloat("_LightAttenuation", m_rayMarchingCloudSetting.LightAttenuation.value);
            material.SetVector("_Transmissivity", m_rayMarchingCloudSetting.Sigma.value);
            material.SetVector("_HgPhase", m_rayMarchingCloudSetting.HgPhase.value);
            material.SetVector("_ShapeNoiseWeights", m_rayMarchingCloudSetting.ShapeNoiseWeights.value);
            material.SetVector("_TopColor", m_rayMarchingCloudSetting.TopColor.value);
            material.SetVector("_BottomColor", m_rayMarchingCloudSetting.BottomColor.value);
            material.SetVector("_ColorOffSet", m_rayMarchingCloudSetting.ColorOffSet.value);
            material.SetFloat("_heightWeights", m_rayMarchingCloudSetting.heightWeights.value);

            material.SetFloat("_detailWeights", m_rayMarchingCloudSetting.detailWeights.value);
            material.SetFloat("_detailNoiseWeight", m_rayMarchingCloudSetting.detailNoiseWeight.value);
            material.SetFloat("_densityOffset", m_rayMarchingCloudSetting.densityOffset.value);



            m_rayMarchingCloudSetting.GetBound(material);

            cameraColorTarget = renderingData.cameraData.renderer.cameraColorTarget;
            //   m_Source = renderer.cameraColorTargetHandle;
            RenderTextureDescriptor temporaryTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            temporaryTargetDescriptor.depthBufferBits = 0;
            cmd.GetTemporaryRT(_RayMarchingCloud, temporaryTargetDescriptor, FilterMode.Bilinear);
            destinationBuffer = new RenderTargetIdentifier(_RayMarchingCloud);
            //if (destination == null)
            //{
            //    RenderingUtils.ReAllocateIfNeeded(ref destination, GetCompatibleDescriptor(), FilterMode.Bilinear, TextureWrapMode.Clamp, name: "_RayMarchingCloud");

            //}
            material.SetTexture("_MainTex", renderer.cameraColorTargetHandle);
            //Blitter.BlitCameraTexture(cmd, m_Source, destination, material,0);
            //   cmd.Blit(m_Source.nameID, destination.nameID, material, 0);
            //Blitter.BlitCameraTexture(cmd, destination, m_Source, material, 0)
            //   cmd.Blit(destination.nameID, m_Source.nameID, material, 0);

            cmd.BlitFullscreenTriangle(cmd, cameraColorTarget, destinationBuffer);
            cmd.BlitFullscreenTriangle(cmd, destinationBuffer, cameraColorTarget, material);
        }




        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            destination?.Release();
        }
        public void Dispose()
        {
            destination?.Release();
        }













        RenderTextureDescriptor GetCompatibleDescriptor()
     => GetCompatibleDescriptor(m_Descriptor.width, m_Descriptor.height, m_Descriptor.graphicsFormat);

        RenderTextureDescriptor GetCompatibleDescriptor(int width, int height, GraphicsFormat format, DepthBits depthBufferBits = DepthBits.None)
            => GetCompatibleDescriptor(m_Descriptor, width, height, format, depthBufferBits);

        internal static RenderTextureDescriptor GetCompatibleDescriptor(RenderTextureDescriptor desc, int width, int height, GraphicsFormat format, DepthBits depthBufferBits = DepthBits.None)
        {
            desc.depthBufferBits = (int)depthBufferBits;
            desc.msaaSamples = 1;
            desc.width = width;
            desc.height = height;
            desc.graphicsFormat = format;
            return desc;
        }

    }
}
