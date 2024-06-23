
using System;
namespace UnityEngine.Rendering.Universal
{

    [Serializable, VolumeComponentMenuForRenderPipeline("FSY_Post-processing/RayMarchingCloud", typeof(UniversalRenderPipeline))]
    public class RayMarchingCloudSetting : VolumeComponent, IPostProcessComponent
    {

       // public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;

        public ColorParameter tint = new ColorParameter(Color.white, false, false, true);

        public Texture3DParameter Noise3D = new Texture3DParameter(null);

        public Vector3Parameter Noise3DScale = new Vector3Parameter(Vector3.zero);

        public Vector3Parameter Noise3DOffSet = new Vector3Parameter(Vector3.zero);

        //摩尔消光的衰减系数
        public FloatParameter Attenuation = new FloatParameter(1);

        //光照造成的颜色强度
        public FloatParameter LightPower = new FloatParameter(1);

        //光照路径上的摩尔消光的衰减系数
        public FloatParameter LightAttenuation = new FloatParameter(1);
        /// <inheritdoc/>
        public bool IsActive() =>true;

        /// <inheritdoc/>
        public bool IsTileCompatible() => false;
        const string shaderName = "Fsy/PP/Cloud";

        //public override void Setup()
        //{
        //    if (material == null)
        //    {
        //        //使用CoreUtils.CreateEngineMaterial来从Shader创建材质
        //        //CreateEngineMaterial：使用提供的着色器路径创建材质。hideFlags将被设置为 HideFlags.HideAndDontSave。
        //        material = CoreUtils.CreateEngineMaterial(shaderName);
        //    }
        //}
    }
}