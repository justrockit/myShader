
using System;
namespace UnityEngine.Rendering.Universal
{

    [Serializable, VolumeComponentMenuForRenderPipeline("FSY_Post-processing/RayMarchingCloud", typeof(UniversalRenderPipeline))]
    public class RayMarchingCloudSetting : VolumeComponent, IPostProcessComponent
    {

        // public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
        [Header("云朵形状控制")]

        [Tooltip("云朵 噪声的总体浓度控制")]
        public FloatParameter DensityScale = new FloatParameter(1);
        [Tooltip("云朵 噪声的浓度采样")]
        public Texture3DParameter Noise3D = new Texture3DParameter(null);
        public Vector3Parameter Noise3DScale = new Vector3Parameter(Vector3.zero);
        public Vector3Parameter Noise3DOffSet = new Vector3Parameter(Vector3.zero);
        [Tooltip("云朵 噪声的分形采样，用来对云朵的边缘进行浓度衰减 ")]
        public Texture3DParameter FractalNoise3D = new Texture3DParameter(null);
        public Vector3Parameter FractalNoise3DScale = new Vector3Parameter(Vector3.zero);
        public Vector3Parameter FractalNoise3DOffSet = new Vector3Parameter(Vector3.zero);
        [Tooltip("云朵AABB盒  最小点")]
        public Vector3Parameter BoundMin = new Vector3Parameter(-Vector3.one);
        [Tooltip("云朵AABB盒  最大点")]
        public Vector3Parameter BoundMax = new Vector3Parameter(Vector3.one);

        [Header("云朵颜色控制")]

        [Tooltip("云朵基础色")]
        public ColorParameter tint = new ColorParameter(Color.white, false, false, true);
        [Tooltip("相机到屏幕某点的摩尔消光的衰减系数")]
        public FloatParameter Attenuation = new FloatParameter(1);

        [Tooltip("光照路径（某点到主光源路径）上的摩尔消光的衰减系数")]
        public FloatParameter LightAttenuation = new FloatParameter(1);

        [Tooltip("光照造成的颜色强度,在计算的最终步控制云朵颜色强度")]
        public FloatParameter LightPower = new FloatParameter(1);
        [Tooltip("光照颜色的RGB透射比，用来模拟更真实的散射颜色，红光波长长和蓝光波长短，散射出来的能量不一样," +
            "即在体积云浓度较低的地方，使其可以呈现出蓝色，而浓度较高的地方，呈现出红色。")]
        public Vector3Parameter Sigma = new Vector3Parameter(Vector3.one);
        [Tooltip("相位函数 常量参数 用来描述云雾得性质，为0时代表各向同性 ,x:双瓣相位函数G0 或单个相位函数G  ，y:双瓣相位函数G1 , z:双瓣相位函数插值w  / x,y范围 -0.99到0.99 w 默认0.5" +
            "直观的来说，对于一块体积云来说，不同的角度观察得到的结果应该是不一样的" +
            "。比如说，如果是中午的时候，抬头仰望云朵，它应该显得更为透亮，这是因为一个光子打到另外一个粒子上，" +
            "它并不是平均的向周围各个方向散射的，微粒的大小不同会导致其散射的角度不同。" +
            "不过无论如何，站在不同角度对云观察的结果应该是不同的。")]
        public Vector3Parameter HgPhase = new Vector3Parameter(Vector3.one);
      

        public Vector3Parameter MainLight = new Vector3Parameter(Vector3.one);



  


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