namespace UnityEngine.Rendering.Universal.Internal
{


    public class CustomFirstBlitPP : ScriptableRendererFeature
    {

        public static readonly int isInUICamera = Shader.PropertyToID("_IsInUICamera");
        [System.Serializable]
        public class CustomFirstBlitSetting
        {
            public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
            public Material BlitMaterial;
            public BoolParameter isDualColorSpace = new BoolParameter(false);
            public bool IsActive() => BlitMaterial!=null;
        }

        CustomFisrtBlitPass m_ScriptablePass;
        RenderTargetHandle m_CameraColorAttachment;
        //RenderTargetHandle m_CameraDepthAttachment;
        //RenderTargetHandle m_AfterPostProcessColor;

        public CustomFirstBlitSetting m_CustomFirstBlitSetting = new CustomFirstBlitSetting();

        public override void Create()
        {
            m_ScriptablePass = new CustomFisrtBlitPass(m_CustomFirstBlitSetting.renderPassEvent, m_CustomFirstBlitSetting.BlitMaterial, m_CustomFirstBlitSetting.isDualColorSpace.value);
            m_CameraColorAttachment.Init("_CameraColorTexture");
            //m_CameraDepthAttachment.Init("_CameraDepthAttachment");
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

    public class CustomFisrtBlitPass : ScriptableRenderPass
    {
        const string m_ProfilerTag = "Custom Fisrt Blit Pass(LinearTosRGB)";
        RenderTargetHandle m_Source;
        Material m_BlitMaterial;
        TextureDimension m_TargetDimension;
        bool isDualColorSpace;
        public CustomFisrtBlitPass(RenderPassEvent evt, Material blitMaterial,bool isDualColorSpace)

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
            m_Source = colorHandle;
            m_TargetDimension = baseDescriptor.dimension;
        }

        /// <inheritdoc/>
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //if (m_BlitMaterial == null)
            //{
            //    Debug.LogErrorFormat("Missing {0}. {1} render pass will not execute. Check for missing reference in the renderer resources.", m_BlitMaterial, GetType().Name);
            //    return;
            //}

            //// Note: We need to get the cameraData.targetTexture as this will get the targetTexture of the camera stack.
            //// Overlay cameras need to output to the target described in the base camera while doing camera stack.
            //ref CameraData cameraData = ref renderingData.cameraData;
            //RenderTargetIdentifier cameraTarget = (cameraData.targetTexture != null) ? new RenderTargetIdentifier(cameraData.targetTexture) : BuiltinRenderTextureType.CameraTarget;

            //bool isSceneViewCamera = cameraData.isSceneViewCamera;

            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);

            // Use default blit for XR as we are not sure the UniversalRP blit handles stereo.
            // The blit will be reworked for stereo along the XRSDK work.
            //Material blitMaterial = (cameraData.isStereoEnabled) ? null : m_BlitMaterial;
            //cmd.SetGlobalTexture("_BlitTex", m_Source.Identifier());
            if(isDualColorSpace)
            cmd.SetGlobalFloat(CustomFirstBlitPP.isInUICamera, 1);
            else
            cmd.SetGlobalFloat(CustomFirstBlitPP.isInUICamera, 0);

            //if (cameraData.isStereoEnabled || isSceneViewCamera || cameraData.isDefaultViewport)
            //{
            //    // This set render target is necessary so we change the LOAD state to DontCare.
            //    cmd.SetRenderTarget(BuiltinRenderTextureType.CameraTarget,
            //        RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store,     // color
            //        RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare); // depth
            //    cmd.Blit(m_Source.Identifier(), cameraTarget, blitMaterial);
            //}
            //else
            //{
         
            //    //SetRenderTarget(
            //    //    cmd,
            //    //    cameraTarget,
            //    //    RenderBufferLoadAction.Load,
            //    //    RenderBufferStoreAction.Store,
            //    //    ClearFlag.None,
            //    //    Color.black,
            //    //    m_TargetDimension);

            //    CoreUtils.SetRenderTarget(cmd, cameraTarget, RenderBufferLoadAction.Load, RenderBufferStoreAction.Store, ClearFlag.None, Color.black);
            //    Camera camera = cameraData.camera;
            //    cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
            //    cmd.SetViewport(new Rect(0, 0, camera.pixelWidth, camera.pixelHeight));
            //    cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, blitMaterial);
            //    cmd.SetViewProjectionMatrices(camera.worldToCameraMatrix, camera.projectionMatrix);
            //}

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
