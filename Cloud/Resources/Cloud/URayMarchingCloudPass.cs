using System.Collections;
using System.Collections.Generic;
using UnityEngine;


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
            public BoolParameter isDualColorSpace = new BoolParameter(false);
            public bool IsActive() => BlitMaterial != null;
        }

        URayMarchingCloudPass m_ScriptablePass;
        RenderTargetHandle m_CameraColorAttachment;
        //RenderTargetHandle m_CameraDepthAttachment;
        //RenderTargetHandle m_AfterPostProcessColor;

        public RayMarchingCloudSetting m_CustomFirstBlitSetting = new RayMarchingCloudSetting();

        public override void Create()
        {
            m_ScriptablePass = new URayMarchingCloudPass(m_CustomFirstBlitSetting.renderPassEvent, m_CustomFirstBlitSetting.BlitMaterial, m_CustomFirstBlitSetting.isDualColorSpace.value);
            //    m_CameraColorAttachment.name="_CameraColorTexture";
            m_CameraColorAttachment.Init("_CameraColorTexture");
            //m_AfterPostProcessColor.Init("_AfterPostProcessTexture");

        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.postProcessEnabled)
            {
                //  var dest = RenderTargetHandle.CameraTarget;
                ref CameraData cameraData = ref renderingData.cameraData;
                //bool createDepthTexture = cameraData.requiresDepthTexture;
                // var m_ActiveCameraDepthAttachment = (createDepthTexture) ? m_CameraDepthAttachment : RenderTargetHandle.CameraTarget;

                RenderTextureDescriptor cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;
                m_ScriptablePass.Setup(cameraTargetDescriptor, m_CameraColorAttachment);
                renderer.EnqueuePass(m_ScriptablePass);
            }




        }


    }

    public class URayMarchingCloudPass : ScriptableRenderPass
    {
        const string m_ProfilerTag = "RayMarchingCloud(射线步进体积云)";
        RTHandle m_Source;
        Material m_BlitMaterial;
        TextureDimension m_TargetDimension;
        bool isDualColorSpace;
        public URayMarchingCloudPass(RenderPassEvent evt, Material blitMaterial, bool isDualColorSpace)

        {
            m_BlitMaterial = blitMaterial;
            renderPassEvent = evt;
            this.isDualColorSpace = isDualColorSpace;
        }

        /// <summary>
        /// Configure the pass
        /// </summary>
        /// <param name="baseDescriptor"></param>
        /// <param name="colorHandle"></param>
        public void Setup(RenderTextureDescriptor baseDescriptor, RenderTargetHandle colorHandle)
        {
           // m_Source = colorHandle;
            if (m_Source?.nameID != colorHandle.Identifier())
                m_Source = RTHandles.Alloc(colorHandle.Identifier());
            m_TargetDimension = baseDescriptor.dimension;
        }

        /// <inheritdoc/>
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
         //   RenderTargetIdentifier cameraTarget = (cameraData.targetTexture != null) ? new RenderTargetIdentifier(cameraData.targetTexture) : BuiltinRenderTextureType.CameraTarget;

            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);

            if (isDualColorSpace)
                cmd.SetGlobalFloat(CustomFirstBlitPP.isInUICamera, 1);
            else
                cmd.SetGlobalFloat(CustomFirstBlitPP.isInUICamera, 0);

     

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public void Dispose()
        {
          
        }


    }
}
