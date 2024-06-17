using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

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
        RenderTargetHandle m_CloudAttachment;
        RTHandle destination;
        //RenderTargetHandle m_CameraDepthAttachment;
        //RenderTargetHandle m_AfterPostProcessColor;

        public RayMarchingCloudSetting m_CustomFirstBlitSetting = new RayMarchingCloudSetting();

        public override void Create()
        {
            m_ScriptablePass = new URayMarchingCloudPass(m_CustomFirstBlitSetting.renderPassEvent);

            m_CameraColorAttachment.Init("_CameraColorTexture");
            m_CloudAttachment.Init("CloudAttachment");
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
                m_ScriptablePass.Setup(cameraTargetDescriptor, m_CameraColorAttachment, m_CustomFirstBlitSetting.BlitMaterial, m_CloudAttachment);
                renderer.EnqueuePass(m_ScriptablePass);
            }
        }
    }

    public class URayMarchingCloudPass : ScriptableRenderPass
    {
        const string m_ProfilerTag = "RayMarchingCloud(射线步进体积云)";
        RTHandle m_Source;
        RTHandle destination;
        Color baseColor;
        Material m_BlitMaterial;
        TextureDimension m_TargetDimension;
        RayMarchingCloudSetting m_rayMarchingCloudSetting;
        public URayMarchingCloudPass(RenderPassEvent evt)

        {
           // m_BlitMaterial = blitMaterial;
            renderPassEvent = evt;
          
        }

        /// <summary>
        /// Configure the pass
        /// </summary>
        /// <param name="baseDescriptor"></param>
        /// <param name="colorHandle"></param>
        public void Setup(RenderTextureDescriptor baseDescriptor, RenderTargetHandle colorHandle, Material BlitMaterial, RenderTargetHandle _destination)
        {
           // m_Source = colorHandle;
            if (m_Source?.nameID != colorHandle.Identifier())
                m_Source = RTHandles.Alloc(colorHandle.Identifier());

            if (destination?.nameID != _destination.Identifier())
                destination = RTHandles.Alloc(_destination.Identifier());
            
            m_BlitMaterial = BlitMaterial;

            m_TargetDimension = baseDescriptor.dimension;
        }

        /// <inheritdoc/>
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //   RenderTargetIdentifier cameraTarget = (cameraData.targetTexture != null) ? new RenderTargetIdentifier(cameraData.targetTexture) : BuiltinRenderTextureType.CameraTarget;
            var stack = VolumeManager.instance.stack;
        
            m_rayMarchingCloudSetting = stack.GetComponent<RayMarchingCloudSetting>();
            baseColor = m_rayMarchingCloudSetting.tint.value;
       

            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            if(m_BlitMaterial)
             render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }


        public void render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var material = m_BlitMaterial;

            //  UpdateMotionBlurMatrices(ref material, cameraData.camera, cameraData.xr);

            // material.SetFloat("_Intensity", m_MotionBlur.intensity.value);
            //  material.SetFloat("_Clamp", m_MotionBlur.clamp.value);

            // PostProcessUtils.SetSourceSize(cmd, m_Descriptor);
            ref CameraData cameraData = ref renderingData.cameraData;
            ref ScriptableRenderer renderer = ref cameraData.renderer;
            //  RTHandle source = renderer.cameraColorTargetHandle ;
            material.SetColor("_BaseColor", baseColor);
         //   cmd.Blit(m_Source, destination);
           // Blitter.BlitCameraTexture(cmd, m_Source, destination, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, material,0);
         //   Blitter.BlitCameraTexture(cmd, destination, m_Source);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            destination?.Release();
        }
        public void Dispose()
        {
          
        }


    }
}
