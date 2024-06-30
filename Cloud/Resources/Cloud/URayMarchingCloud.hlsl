#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


#define lightStep 8
#define CameraStep 32
#define MaskNoiseSpeedScale 0.4
#define ShapeNoiseSpeedScale 0.4
// 将不占空间的材质相关变量放在CBUFFER中，为了兼容SRP Batcher
CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
float4 _SourceTex_TexelSize;
float3 _BoundMin;
float3 _BoundMax;
float3 _Noise3DScale;//噪声图缩放比
float3 _Noise3DOffSet;//噪声图偏移值
float3 _FractalNoise3DScale;//分形噪声图缩放比
float3 _FractalNoise3DOffSet;//分形噪声图偏移值
float _DensityScale;
float _Attenuation;//摩尔消光系数 越大越透
float _LightPower;//光照散射强度控制参数
float _LightAttenuation;//光照的摩尔消光系数 越大越透
float3 _Transmissivity;//透射比 控制RGB波长对透射影响的不同
float4 _HgPhase;//相位函数 常量参数 用来描述云雾得性质，为0时代表各向同性
float3 _MainLight;
float3 _EdgeSoftnessThreshold;
float4 _MoveSpeed;
float3 _TopColor;
float3 _BottomColor;
float2 _ColorOffSet;
float _heightWeights;
CBUFFER_END


          


// 材质单独声明，使用DX11风格的新采样方法
TEXTURE2D (_BaseMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D (_MaskNoise);
SAMPLER(sampler_MaskNoise);

TEXTURE2D (_ShapeNoise);
SAMPLER(sampler_ShapeNoise);

TEXTURE2D (_WeatherMap);
SAMPLER(sampler_WeatherMap);

TEXTURE2D_X(_SourceTex);
SAMPLER(sampler_SourceTex);
sampler3D _Noise3D;
sampler3D _FractalNoise3D;//分形噪声，优化云朵边缘
//计算采样各地点深度值得到改点的世界坐标

/*
关于 UNITY_REVERSED_Z z值是否取反的处理，因为远近视口不一样，从近->远用1->0，更好的均匀分步
    UNITY_REVERSED_Z 是一种改变深度缓冲管理方式的技术，它颠倒了Z值的表示方式。在Reversed-Z中，近裁剪面的Z值较大（在DirectX中为1.0），而远裁剪面的Z值较小（在DirectX中为0.0）。这种方式的目的是使深度缓冲中的值在View Space下对应的平面更加均匀分布，从而减少Z-Fighting（深度冲突）现象，并提高渲染精度。
*/
float3 GetWorldPosition(float3 positionCS)
 { 
        //float2 UV = positionCS.xy / _ScaledScreenParams.xy;
        //#if UNITY_REVERSED_Z
        //real depth = SampleSceneDepth(UV);
        //#else
        //real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
        //#endif
        //return ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);
    float2 uv=positionCS.xy/_ScaledScreenParams.xy;

    #if UNITY_REVERSED_Z 
    float depth =SampleSceneDepth(uv);
    #else
    float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
    #endif
    // edit 下述 =  return ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);; 转到NDC 再转到world
    float4 ndc=float4(uv.x*2-1,uv.y*2-1,depth,1);
    #if UNITY_UV_STARTS_AT_TOP
    ndc.y = -ndc.y;
    #endif
    float4 worldpos=mul(UNITY_MATRIX_I_VP,ndc);
    worldpos=worldpos/worldpos.w;
    //edit end
    return  worldpos.xyz;
 }



 //施利克相位函数 模拟米氏散射

float hg(float a, float g) 
{
                float g2 = g * g;
                return (1 - g2) / (4 * 3.1415 * pow(1 + g2 - 2 * g * (a), 1.5));
            }
 float phase(float a) 
 {
                float blend = .5;
                float hgBlend = hg(a, _HgPhase.x) * (1 - blend) + hg(a, -_HgPhase.y) * blend;
                return _HgPhase.z + hgBlend * _HgPhase.w;
            }


//Beers Powder Function 比 比尔朗博定律的 exp(-a*d)来的更为真实   a：摩尔消光系数 d 浓度
float3 BeerPowder(float3 d, float a)
{
    return exp(-d * a) * (1 - exp(-d* 2 * a));
}


//把cut_value 从[orgin_min,orgin_max]映射到[target_min,target_max]
 float Remap(float cut_value,float orgin_min,float orgin_max,float target_min,float target_max)
 {
    return  ((cut_value-orgin_min)/(orgin_max-orgin_min))*(target_max-target_min)+target_min;
 }
//动态的云层采样
 float sampleDynamicDensity(float3 position)
 {
    // float3 realpos=position*_Noise3DScale+_Noise3DOffSet;
    //  float  density=tex3D(_Noise3D,realpos).r;
    //  return  density;

     /* 范围盒边缘衰减 */
     float x_dis=min(_EdgeSoftnessThreshold.x, min(position.x - _BoundMin.x, _BoundMax.x - position.x));
     float y_dis=min(_EdgeSoftnessThreshold.y, min(position.y - _BoundMin.y, _BoundMax.y - position.y));
     float z_dis=min(_EdgeSoftnessThreshold.z, min(position.z - _BoundMin.z, _BoundMax.z - position.z));
    float softness=(x_dis/_EdgeSoftnessThreshold.x)*(y_dis/_EdgeSoftnessThreshold.y)*(z_dis/_EdgeSoftnessThreshold.z) ;
    /* 范围盒边缘衰减 */


    //云朵层整体位移（形变）速度速度
    float speedShape=_MoveSpeed.x*_Time.y;
     //云朵细节形变速度
    float speedDetail=_MoveSpeed.y*_Time.y;
    //得到体积云中心
    float3 center=(_BoundMax+_BoundMin)/2;
    //得到体积云长宽高
    float3 size = _BoundMax - _BoundMin;

    //获得_Noise3D的采样坐标 ，缩放加有 timer控制的位移 就是前面基础方法的realpos
    float3 samplingUVW=position*_Noise3DScale+speedShape*_Noise3DOffSet;
   //获得_FractalNoise3D的采样坐标 ，缩放加有 timer控制的位移 就是前面基础方法的realpos2
    float3 samplingFractalUVW=position*_FractalNoise3DScale+speedShape*_FractalNoise3DOffSet;

    //采样
        //整个云朵上该点的uv值 xz平面 ，等于将size.x size.z 归一化到（1，1）,且（0，0）在右下角;
        //用来采样2d贴图
        float2 uv= (size.xz*0.5+(position.xz-center.xz));
        uv=float2(uv.x/size.x,uv.y/size.z);
         //用来采样mask贴图
        float3 mask=  SAMPLE_TEXTURE2D(_MaskNoise, sampler_MaskNoise, (uv+samplingUVW.xy*MaskNoiseSpeedScale));
          //用来采样weather贴图 ,这是用来对梯度值进行重映射的，用于决定云层或体积密度在不同高度上的变化
        float3 weather=  SAMPLE_TEXTURE2D(_WeatherMap, sampler_WeatherMap, (uv+samplingUVW.xy*ShapeNoiseSpeedScale));


/*  云层或体积密度在不同高度上的变化*/
     float gmin=Remap(weather.x,0,1,0.1,0.6);
     float gmax=Remap(weather.x,0,1,gmin,0.9);
     float heightPercent=(position.y-_BoundMin.y)/size.y;
     float heightGradient = saturate(Remap(heightPercent, 0.0, gmin, 0, 1)) * saturate(Remap(heightPercent, 1, gmax, 0, 1));
     float heightGradient2 = saturate(Remap(heightPercent, 0.0, weather.r, 1, 0)) * saturate(Remap(heightPercent, 0.0, gmin, 0, 1));
    heightGradient = saturate(lerp(heightGradient, heightGradient2,_heightWeights));
    softness=softness*heightGradient;

 /* 云层或体积密度在不同高度上的变化*/

        float  density=tex3D(_Noise3D,samplingUVW+mask.r*_MoveSpeed.z*0.1).r;
        float  density2=tex3D(_FractalNoise3D,samplingFractalUVW+density*_MoveSpeed.w*0.2).r;

        return  max(0,density-density2)*_DensityScale*softness*softness ;
 }

// //TODO 模棱两可
 float2  RayMarchingBoundary(float3 minPos,float3 maxPos,half3 rayOrigin,half3 rayDir)
 {
       //射线到两点的距离向量投影到单位方向向量上比较,得出远近
      float3 minT=(minPos-rayOrigin)/rayDir;
      float3 maxT=(maxPos-rayOrigin)/rayDir;
      float3 frontT=min(minT,maxT);
      float3 backT= max(minT,maxT);
      //AABB 原理 frontT的最大值小于backT的最小值，则射线与盒子相交
      //x,y,z分量的意义是射线在各自分量上移动几个单位接触到矩形的其中一个面
      float dstA=max(frontT.x,max(frontT.y,frontT.z));//得到
      float dstB=min(backT.x,min(backT.y,backT.z));

      float dstToBox=max(dstA,0);//小于0说明在物体内发射 ，dstToBox*rayDir才是真实距离 

      float dstInsideBox=max(0,dstB-dstToBox);//minback-dstToBox 大于0说明在物体内部通过
      return  float2(dstToBox,dstInsideBox);
 }


   

 
  float3  RayMarchingLightWithColor(float3 position)
 {
    //光照方向位置
   float3 lightpos=_MainLightPosition.xyz;
   //计算方向单位向量
  // float3 rayDir=normalize(position-lightpos);
   //计算距离参数
   /*********** TODO:这里的给传入的方向反向了一下是因为，rayBoxDst的计算是要从目标点到体积，而采样时，则是反过来，从position出发到主光源*/

   float2 data=RayMarchingBoundary(_BoundMin,_BoundMax,position,lightpos);
   float dstInsideBox=data.y;
   int stepnum=lightStep;//步数
   float steplength=dstInsideBox/stepnum;
   float3 steplengthvector=steplength*lightpos;
   half totalDensity=0;
   [unroll(lightStep)]
    for(int i=0;i<stepnum;i++)
    {
        position+=steplengthvector;
        totalDensity+= max(0, sampleDynamicDensity(position));
       
    }
 float3 beervalue=  exp(-totalDensity*_LightAttenuation); 
float3 cloudColor=lerp(_TopColor,_MainLightColor,saturate(beervalue*_ColorOffSet.x));
cloudColor=lerp( _BottomColor,cloudColor,saturate(pow(beervalue*_ColorOffSet.y,3)));

 return  beervalue*cloudColor;
 }



   //第六步
 /*带 摩尔消光，
 带3d噪声图,
 带射线步进aabb 
 带光照计算 带透射比 
 带相位函数 
 带 Beers Powder Function
 带 移动
 带 云朵轮廓 整体形状noise的

  的云朵

 */

float3 RayMarchingWithBoundaryWithLightWithDynamic(float3 rayOrigin,float3 rayDir,float3 positionWS,float4 sourceColor)
 {

    float3 minPos=_BoundMin;
    float3 maxPos=_BoundMax;
    //先得到相机到障碍物的距离
    float dstobj=length(positionWS-rayOrigin);
    //再得到相机到云朵最近距离 和 在云朵内部长度
    float2 data=RayMarchingBoundary(minPos,maxPos,rayOrigin,rayDir);
    float dstToBox=data.x;
    float dstInsideBox=data.y;
    //再得出真实计算云朵参数的长度,如果dstobj<dstToBox,说明完全被阻挡
    float finalDst=min(dstInsideBox,dstobj-dstToBox);
    //开始计算
    //初始出发点，从矩形接触点开始
    float3 firstpoint=rayOrigin+dstToBox*rayDir;
    int stepnum=CameraStep;//步数
    //步长=长度/步数
    float steplength=dstInsideBox/stepnum;
    float3 steplengthvector=steplength*rayDir;
    half totalDensity=0;//相机到点的浓度
    float sumDensity=1;//for循环里每次 相机到点的比尔朗博定律值的累乘
    float3 lightEnergy=0;//光照到每个点的浓度
    float3 curPos=firstpoint;
    float cursteplength=0;   
    float _costheta = dot(rayDir, _MainLightPosition.xyz);
    float HgPhaseValue= phase(_costheta);
     [unroll(CameraStep)]
    for(int i=0;i<stepnum;i++)
    {
        if(cursteplength<finalDst)
        {  
            curPos+=steplengthvector;
            half density=  steplength * sampleDynamicDensity(curPos);//当前点浓度值 采样获得
            float3 LightDensity=RayMarchingLightWithColor(curPos);//当前点到光照距离上的浓度和
            //每个点到光照距离上的浓度和累加（光纤到点衰减一次，点到相机再一次）,这部分需要提到RayMarchingLightWithColor中计算
        //    float3 beervalue=  exp(-LightDensity*_LightAttenuation*_Transmissivity); 
        
            float3 energy =LightDensity*density*HgPhaseValue;
          
            lightEnergy+=energy *sumDensity;
            sumDensity*= exp(-density*_Attenuation);
            if (sumDensity < 0.01)
            break;
      
            cursteplength+=steplength;
            continue;
        }
         break;
       
    }
     float3 cloudcolor= lightEnergy*_LightPower;
     float3  albedo=sourceColor.xyz*sumDensity+cloudcolor;
     return albedo ;
 }


 