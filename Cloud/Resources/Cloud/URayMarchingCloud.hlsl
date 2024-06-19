#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"



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
    half3 color=0;
    half3 color2=0.025;
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
dstToBox：从射线起点到长方体包围盒表面的最短距离。
dstInsideBox：射线在长方体内部穿过的距离。
*/
 float2  RayMarchingBoundary(float3 minPos,float3 maxPos,float3 rayOrigin,float3 rayDir)
 {
       //射线到两点的距离长度比较,得出远近
      float3 minT=(minPos-rayOrigin)/rayDir;
      float3 maxT=(maxPos-rayOrigin)/rayDir;
      float3 frontT=min(minT,maxT);
      float3 backT= max(minT,maxT);
      //AABB 原理 frontT的最大值小于backT的最小值，则射线与盒子相交
       float maxfront=max(frontT.x,max(frontT,y,frontT.z));//得到
       float minback=min(backT.x,min(backT,y,backT.z));
      float dstToBox=max(maxfront,0);//小于0说明在物体内发射
      float dstInsideBox=max(0,minback-dstToBox);//minback-dstToBox 大于0说明在物体内部通过
      return  float2(dstToBox,dstInsideBox);
 }

