
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
                //ʹ��CoreUtils.CreateEngineMaterial����Shader��������
                //CreateEngineMaterial��ʹ���ṩ����ɫ��·���������ʡ�hideFlags��������Ϊ HideFlags.HideAndDontSave��
                material = CoreUtils.CreateEngineMaterial(shaderName);
            }
        }
    }
}