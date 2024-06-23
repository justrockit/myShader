#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

// 将不占空间的材质相关变量放在CBUFFER中，为了兼容SRP Batcher
CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
float4 _SourceTex_TexelSize;
float3 _Noise3DScale;
float3 _Noise3DOffSet;
float _Attenuation;//吸光率 越大越透
float _LightPower;
float _LightAttenuation;

CBUFFER_END

// 材质单独声明，使用DX11风格的新采样方法
TEXTURE2D (_BaseMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D_X(_SourceTex);
SAMPLER(sampler_SourceTex);
sampler3D _Noise3D;


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

 //射线步进的测试代码 从相机位置往计算出来的点按步数前进
half RayMarchingTest(float3 orgin,float3 RayDir )
 {
    half color=0;
    half color2=0.025;
    float steplength=0.3;//步长
    int stepnum=128;//步数
    float Range=10;
    float3 steplengthdir=RayDir*steplength;
    float3 curPos=orgin;
     for(int i=0;i<stepnum;i++)
     {
            curPos=curPos+steplengthdir;
           if(curPos.x>-Range &&curPos.x<Range && curPos.y>-Range &&curPos.y<Range  && curPos.z>-Range &&curPos.z<Range)
           {
             color=color+color2;
           }
     }

  return color;
 }

 
//用两点锁定一个矩形，然后得出射线线段

/*
这段代码是一个用于计算射线与长方体包围盒（Axis-Aligned Bounding Box, AABB）相交情况的函数。
给定一个长方体的最小和最大边界点（boundsMin 和 boundsMax），
以及射线的起点（rayOrigin）和方向（rayDir），该函数计算出两个关键距离：
dstToBox： 并不是最短距离，
而是射线从原点出发到首次与边界框相交点（如果存在）的参数值。这个参数值可以用于在射线追踪或光线投射算法中沿射线方向前进到相交点，
并计算相交点的具体位置。如果要计算实际的三维空间距离，你需要将这个参数值与射线的方向向量相乘，即 rayDir * dstToBox。
但是，在射线与边界框的相交检测中，我们通常只关心参数值，因为它足够我们确定射线与边界框的相交情况，并决定是否需要进一步处理。
dstInsideBox：射线在长方体内部穿过的距离的参数值  rayDir * dstInsideBox 才是真实距离


！！！！！！(minPos - rayOrigin) / rayDir 
在射线与轴对齐边界框（AABB）的相交测试中有着非常重要的意义。这个表达式用于计算从射线原点（rayOrigin）到边界框的最小顶点（minPos）的向量在射线方向（rayDir）上的参数值。
具体来说，这个表达式的计算过程可以分为两步：
计算方向向量：minPos - rayOrigin 计算了一个从射线原点到边界框最小顶点的向量。这个向量描述了从射线原点到边界框最小顶点的位置和方向。
投影到射线方向：将上述计算得到的方向向量除以射线方向向量 rayDir，即 (minPos - rayOrigin) / rayDir，这个过程实际上是计算了从射线原点到边界框最小顶点的向量在射线方向上的投影长度（或者说，是在射线方向上的“距离”或“参数值”）。这个投影长度（或参数值）可以告诉我们沿着射线方向前进多远会首次接触到边界框。
如果 rayDir 是一个单位向量（即长度为1的向量），那么这个投影长度就直接是射线原点到边界框最小顶点的距离在射线方向上的分量。如果 rayDir 不是单位向量，那么结果将是这个距离与 rayDir 长度的比值，但无论如何，它都表示了沿着射线方向前进多远会首次接触到边界框。
在射线追踪、光线投射等图形学应用中，这种计算方式非常常见，因为它允许我们快速地确定射线与场景中物体的相交情况，从而决定如何渲染场景中的物体。

*/
//TODO 模棱两可
 float2  RayMarchingBoundary(float3 minPos,float3 maxPos,float3 rayOrigin,float3 rayDir)
 {
       //射线到两点的距离向量投影到单位方向向量上比较,得出远近
      float3 minT=(minPos-rayOrigin)/rayDir;
      float3 maxT=(maxPos-rayOrigin)/rayDir;
      float3 frontT=min(minT,maxT);
      float3 backT= max(minT,maxT);
      //AABB 原理 frontT的最大值小于backT的最小值，则射线与盒子相交
      //x,y,z分量的意义是射线在各自分量上移动几个单位接触到矩形的其中一个面
      float maxfront=max(frontT.x,max(frontT.y,frontT.z));//得到
      float minback=min(backT.x,min(backT.y,backT.z));
      float dstToBox=max(maxfront,0);//小于0说明在物体内发射 ，dstToBox*rayDir才是真实距离 

      float dstInsideBox=max(0,minback-dstToBox);//minback-dstToBox 大于0说明在物体内部通过
      return  float2(dstToBox,dstInsideBox);
 }

 float sampleDensity(float3 position)
 {
    float3 realpos=position*_Noise3DScale+_Noise3DOffSet;
     float  density=tex3D(_Noise3D,realpos).r;
     return  density;
 }


 #define lightStep 8

 #define CameraStep 32
 //带 摩尔消光，带3d噪声图,带射线步进aabb的云朵
 float RayMarchingWithBoundary(float3 minPos,float3 maxPos,float3 rayOrigin,float3 rayDir,float3 positionWS)
 {
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
    int stepnum=64;//步数
    //步长=长度/步数
    float steplength=dstInsideBox/stepnum;
    float3 steplengthvector=steplength*rayDir;

    half color=0;
    //浓度 ,和步长关联上，这样不会因为步数造成稀薄
    //half color2=0.1*steplength;
    float3 curPos=firstpoint;
    float cursteplength=0;
    for(int i=0;i<stepnum;i++)
    {
        if(cursteplength<finalDst)
        {  
            color=color+steplength * sampleDensity(curPos);
           
        }else
        {
            break;
        }
        curPos=curPos+steplengthvector;
        cursteplength=cursteplength+steplength;
    }
     return  exp(-_Attenuation*color);
 }

 //计算该点的云朵浓度，这个不用计算遮挡的影响，因为如果这个点被遮挡住，就不会有光照给相机计算
//相机到点射线上的每个采样点都得算一遍，是个积分过程
 float  RayMarchingLight(float3 position,float3 minPos,float3 maxPos)
 {
    //光照方向位置
   float3 lightpos=_MainLightPosition.xyz;
   //计算方向单位向量
  // float3 rayDir=normalize(position-lightpos);
   //计算距离参数
   /*********** TODO:这里的给传入的方向反向了一下是因为，rayBoxDst的计算是要从目标点到体积，而采样时，则是反过来，从position出发到主光源*/

   float2 data=RayMarchingBoundary(minPos,maxPos,position,1/lightpos);
   float dstToBox=data.x;
   float dstInsideBox=data.y;
   int stepnum=lightStep;//步数
   float steplength=dstInsideBox/stepnum;
   float3 steplengthvector=steplength*lightpos;
   half totalDensity=0;
   
    for(int i=0;i<stepnum;i++)
    {
        totalDensity=totalDensity+steplength * max(0, sampleDensity(position));
        position=position+steplengthvector;
    }
     return  totalDensity;
 }


 //带 摩尔消光，带3d噪声图,带射线步进aabb 带光照计算的云朵
float3 RayMarchingWithBoundaryWithLight(float3 minPos,float3 maxPos,float3 rayOrigin,float3 rayDir,float3 positionWS,float4 sourceColor)
 {
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
    half totalLightDensity=0;//光照到每个点的浓度

    //浓度 ,和步长关联上，这样不会因为步数造成稀薄
    //half color2=0.1*steplength;
    float3 curPos=firstpoint;
    float cursteplength=0;
    for(int i=0;i<stepnum;i++)
    {
        if(cursteplength<finalDst)
        {  
            half curDensity=  steplength * sampleDensity(curPos);//当前点浓度值 采样获得
            totalDensity=totalDensity+curDensity;//浓度值累加
            half LightDensity=RayMarchingLight(curPos,minPos,maxPos);//当前点到光照距离上的浓度和
            totalLightDensity=totalLightDensity+exp(- (LightDensity*_LightAttenuation+totalDensity*_Attenuation))*curDensity;//每个点到光照距离上的浓度和累加（光纤到点衰减一次，点到相机再一次）
             curPos=curPos+steplengthvector;
              cursteplength=cursteplength+steplength;
            continue;
        }
         break;
       
    }

    //现在拥有了光照的衰减系数
    //可以把光照到相机的颜色计算出来
    float3 cloudcolor= _MainLightColor*totalLightDensity*_BaseColor.xyz*_LightPower;
     float3  albedo=sourceColor.xyz*exp(-_Attenuation*totalDensity)+cloudcolor;

     return albedo  ;
 }
 

