
using System;
namespace UnityEngine.Rendering.Universal
{

    [Serializable, VolumeComponentMenuForRenderPipeline("FSY_Post-processing/RayMarchingCloud", typeof(UniversalRenderPipeline))]
    public class RayMarchingCloudSetting : VolumeComponent, IPostProcessComponent
    {

       // public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;

        public ColorParameter tint = new ColorParameter(Color.white, false, false, true);
        public Vector3Parameter BoundMin = new Vector3Parameter(-Vector3.one);

        public Vector3Parameter BoundMax = new Vector3Parameter(Vector3.one);
        

        public Texture3DParameter Noise3D = new Texture3DParameter(null);

   
        public Vector3Parameter Noise3DScale = new Vector3Parameter(Vector3.zero);

        public Vector3Parameter Noise3DOffSet = new Vector3Parameter(Vector3.zero);

        public Texture3DParameter FractalNoise3D = new Texture3DParameter(null);

        public Vector3Parameter FractalNoise3DScale = new Vector3Parameter(Vector3.zero);

        public Vector3Parameter FractalNoise3DOffSet = new Vector3Parameter(Vector3.zero);

        //摩尔消光的衰减系数
        public FloatParameter Attenuation = new FloatParameter(1);

        //光照造成的颜色强度
        public FloatParameter LightPower = new FloatParameter(1);

        //光照路径上的摩尔消光的衰减系数
        public FloatParameter LightAttenuation = new FloatParameter(1);

        //光照颜色的RGB透射比，用来模拟更真实的散射颜色，红光波长长和蓝光波长短，散射出来的能量不一样
        public Vector3Parameter Sigma = new Vector3Parameter(Vector3.one);

        //相位函数 常量参数 用来描述云雾得性质，为0时代表各向同性 ,x:双瓣相位函数G0 或单个相位函数G  ，y:双瓣相位函数G1 , z:双瓣相位函数插值w
        //x,y范围 -0.99到0.99 w 默认0.5
        public Vector3Parameter HgPhase = new Vector3Parameter(Vector3.one);


        //相位函数 常量参数 用来描述云雾得性质，为0时代表各向同性
        //public ClampedFloatParameter HgPhaseG0 = new ClampedFloatParameter( 0, - 0.99f,0.99f);
        //public ClampedFloatParameter HgPhaseG1 = new ClampedFloatParameter(0, -0.99f, 0.99f);
        //public FloatParameter HgPhase_W = new FloatParameter(0);
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