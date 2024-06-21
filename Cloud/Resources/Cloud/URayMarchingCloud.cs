using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using static Unity.VisualScripting.Member;

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
      //  RenderTargetHandle m_CloudAttachment;
        RTHandle destination;
        //RenderTargetHandle m_CameraDepthAttachment;
        //RenderTargetHandle m_AfterPostProcessColor;

        public RayMarchingCloudSetting m_CustomFirstBlitSetting = new RayMarchingCloudSetting();

        public override void Create()
        {
            m_ScriptablePass = new URayMarchingCloudPass(m_CustomFirstBlitSetting.renderPassEvent);

            m_CameraColorAttachment.Init("_CameraColorTexture");
          //  m_CloudAttachment.Init("CloudAttachment");
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
        RTHandle destination= RTHandles.Alloc(_RayMarchingCloud);
        Color baseColor;
        Material m_BlitMaterial;
        TextureDimension m_TargetDimension;
        RenderTextureDescriptor m_Descriptor;
        RayMarchingCloudSetting m_rayMarchingCloudSetting;
        public static readonly int _RayMarchingCloud = Shader.PropertyToID("_RayMarchingCloud");
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
        public void Setup(RenderTextureDescriptor baseDescriptor, RenderTargetHandle colorHandle, Material BlitMaterial)
        {
           // m_Source = colorHandle;
            if (m_Source?.nameID != colorHandle.Identifier())
                m_Source = RTHandles.Alloc(colorHandle.Identifier());

            //if (destination?.nameID != _destination.Identifier())
            //    destination = RTHandles.Alloc(_destination.Identifier());
            
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
            if(m_BlitMaterial)
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
            material.SetVector("_Noise3DOffSet", m_rayMarchingCloudSetting.Noise3DOffSet.value);
            material.SetVector("_Noise3DScale", m_rayMarchingCloudSetting.Noise3DScale.value);
            material.SetTexture("_Noise3D", m_rayMarchingCloudSetting.Noise3D.value);

            m_Source = renderer.cameraColorTargetHandle;
            cmd.GetTemporaryRT(_RayMarchingCloud, GetCompatibleDescriptor(), FilterMode.Bilinear);
        //    destination = _RayMarchingCloud;
            Blitter.BlitCameraTexture(cmd, m_Source, destination, material,0);
            //Blitter.BlitCameraTexture(cmd, destination, m_Source, material, 0);
           cmd.Blit(destination.nameID, m_Source.nameID, material, 0);
        }

        // 相机初始化时执行
        //public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        //{
        //    var descriptor = renderingData.cameraData.cameraTargetDescriptor;
        //    descriptor.msaaSamples = 1;
        //    descriptor.depthBufferBits = 0;
        //    // 分配临时纹理
        //  //  RenderingUtils.ReAllocateIfNeeded(ref destination, descriptor, name: "rayMarchingCloud");
         
        //}
    

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
