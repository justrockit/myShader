
using System;
namespace UnityEngine.Rendering.Universal
{

    [Serializable, VolumeComponentMenuForRenderPipeline("FSY_Post-processing/RayMarchingCloud", typeof(UniversalRenderPipeline))]
    public class RayMarchingCloudSetting : VolumeComponent, IPostProcessComponent
    {

      
        public ColorParameter tint = new ColorParameter(Color.white, false, false, true);

        /// <inheritdoc/>
        public bool IsActive() =>true;

        /// <inheritdoc/>
        public bool IsTileCompatible() => false;

        Material material;
        const string shaderName = "Fsy/PP/Cloud";

        public override void Setup()
        {
            if (material == null)
            {
                //使用CoreUtils.CreateEngineMaterial来从Shader创建材质
                //CreateEngineMaterial：使用提供的着色器路径创建材质。hideFlags将被设置为 HideFlags.HideAndDontSave。
                material = CoreUtils.CreateEngineMaterial(shaderName);
            }
        }
    }
}