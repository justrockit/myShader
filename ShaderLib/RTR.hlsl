#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Version.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Deprecated.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


 struct MInputData
  {
    float3 positionWS;//着色点世界坐标系
    half3 normalWS ;//法线世界坐标系
    half3 viewDirectionWS;//相机世界坐标系
    float4  shadowCoord;//阴影贴图的采样坐标，用于采样阴影贴图
    half4  shadowMask;//阴影遮罩
    half3  bakedGI;//采样动/静态光照贴图，得到的该点烘焙的全局光照值
  };

  struct MBRDFData
  {
    half roughness;//粗糙度值 用于计算DGF
    half3 diffuse;//漫反射值
   // half3 albedo;//反射率
    half3 specular;//镜面反射值 和diffuse要能量守恒
                
  };

  /*总的颜色等于所有光照颜色加起来*/
  struct MLightingData
{
    half3 giColor;//光照到的点全局光照颜色
    half3 mainLightColor;//光照到的点主光照颜色
    half3 additionalLightsColor;//光照到的点副光照颜色和
  //  half3 vertexLightingColor;
    half3 emissionColor;//光照到的点的自发光颜色
};

 /*RealtimeLights.hlsl*/
//  struct Light
//{
//    half3   direction;
//    half3   color;
//    float   distanceAttenuation; // full-float precision required on some platforms
//    half    shadowAttenuation;
//    uint    layerMask;
//};

 /*SurfaceData.hlsl*/
//struct SurfaceData
//{
//    half3 albedo;
//    half3 specular;
//    half  metallic;
//    half  smoothness;
//    half3 normalTS;
//    half3 emission;
//    half  occlusion;
//    half  alpha;
//    half  clearCoatMask;
//    half  clearCoatSmoothness;
//};

/*Lighting.hlsl*/
//struct LightingData
//{
//    half3 giColor;
//    half3 mainLightColor;
//    half3 additionalLightsColor;
//    half3 vertexLightingColor;
//    half3 emissionColor;
//};

//---------------------------------------------------
// 微表面模型
//---------------------------------------------------
/*
各向同性 GGX
*/
float  IsotropyGGX(float roughness,float NoH)
{
  float alpha=roughness*roughness;
  float  alpha2=alpha*alpha;
  float bottom= (NoH*alpha2-NoH)*NoH+1.0;
  return INV_PI* SafeDiv(alpha2,bottom);
}

float SchlickGGX(float roughness,float NoV)
{
     float k= (roughness+1)*(roughness+1)/8;
     return NoV/(NoV*(1-k)+k);
}


float SmithGGX(float roughness,float NoV,float NoL)
{
return  SchlickGGX(roughness,NoV)* SchlickGGX(roughness,NoL);
}
//导体（金属）和绝缘体（电解质，非金属）。其中非金属具有单色/灰色镜面反射颜色。而金属具有彩色的镜面反射颜色。即非金属的F0是一个float。而金属的F0是一个float3
float FresnelSchlick(float F0, float VoH)
{
    return F0+(1.0-F0)*pow((1.0-max(VoH ,0.0)),5.0);
}

float3 FresnelSchlick(float3 F0, float VoH)
{
    return F0+(1.0-F0)*pow((1.0-max(VoH ,0.0)),5.0);
}

//金属
float3  MicrofacetSpecularBRDF( MBRDFData data,half3 N_WS,half3 V_WS,half3 L_WS,float3 F0)
{
 // half
 half3 H_WS =normalize(V_WS+L_WS);
float NoV=dot(N_WS,V_WS);
float NoH=dot(N_WS,H_WS);
float NoL=dot(N_WS,L_WS);
float bottom=4*NoV*NoL;
float G=SmithGGX(data.roughness,NoV,NoL);
float3 F=FresnelSchlick(F0, NoV);
float D=IsotropyGGX(data.roughness,NoH);



return  F*G*D/bottom;


}
//非金属 
float  MicrofacetSpecularBRDF(MBRDFData data,half3 N_WS,half3 V_WS,half3 L_WS,float F0)
{
 // half
half3 H_WS =normalize(V_WS+L_WS);
float NoV=dot(N_WS,V_WS);
float NoH=dot(N_WS,H_WS);
float NoL=dot(N_WS,L_WS);
float VoH=dot(N_WS, H_WS);
float bottom=4*NoV*NoL;
float G=SmithGGX(data.roughness,NoV,NoL);
float F=FresnelSchlick(F0, NoV);
float D=IsotropyGGX(data.roughness,NoH);

return  F*G*D/bottom;
}




//------------------------------------------------------



//---------------------------------------------------
// Lighting计算
//---------------------------------------------------

MBRDFData getBRDFData(float3 specular,float3 albedo,float smoothness)
{

 MBRDFData  BRDF;
 BRDF.roughness= 1.0 - smoothness;//粗糙度等于 1-光泽度
 BRDF.specular=specular;
 BRDF.diffuse=albedo*(float3(1.0,1.0,1.0)-specular);
 //BRDF.albedo = albedo;

 return  BRDF;

}

//直接光照
float3 LightingPhysicallyBased(MBRDFData data, Light light,half3 N_WS,half3 V_WS,float F0)
{
//颜色方向衰减系数
float3  lightColor=light.color;
float3  lightDirection=light.direction;
float  distanceAttenuation=light.distanceAttenuation;
//单位立体角在单位面积上接受到得辐射通量， rendering equation的 光照项*cos(thata)项 
float3 radiance=lightColor*saturate(dot(N_WS,N_WS))*distanceAttenuation;

// 乘上brdf值 ,参考 cook公式
//漫反射
  half3 brdf = data.diffuse;
 //TODO:镜面反射值
 half3 specular = data.specular* MicrofacetSpecularBRDF(data, N_WS, V_WS, lightDirection, F0);
 //相加
 brdf = brdf + specular;

return radiance*brdf;
}

//环境光照


//间接光照？二次弹射

//------------------------------------------------------



//汇总 

/*
完整的 PBR lighting...  UniversalFragmentPBR流程
1.条件定义：根据_SPECULARHIGHLIGHTS_OFF宏定义，设置布尔值specularHighlightsOff以控制是否计算镜面高光。

2.BRDF数据初始化：通过InitializeBRDFData函数根据surfaceData初始化BRDF（双向反射分布函数）数据，包括材质的粗糙度、金属度、颜色等属性。

3.调试颜色覆盖：在调试模式下，检查是否需要使用特定的调试颜色覆盖最终输出，如法线、深度或光照贴图等。

4.清漆层计算：如果有清漆层效果，通过CreateClearCoatBRDFData计算相关的BRDF数据。

5.阴影遮罩与环境光遮蔽：计算阴影遮罩和环境光遮蔽因子，用于后续光照计算中的阴影和间接光照模拟。 
注：这里的AO不是SSAO ???

6.光照层匹配与混合光照：检查主光源是否与模型的渲染层匹配，并混合实时光照和烘焙光照（GI）。

7.全局光照计算：计算全局光照（GI）对表面的贡献，考虑BRDF、清漆层、环境遮蔽等因素。

8.主光源光照计算：如果主光源影响到当前模型，计算其对表面的光照贡献，包括考虑镜面高光是否开启。

9.附加光源处理：遍历并计算所有附加光源（如点光源、聚光灯）对表面的光照贡献，同样考虑镜面高光和光源层匹配。

10.顶点光照：如果启用了顶点光照，则将顶点光照贡献累加到最终颜色中。

11.最终颜色计算：综合所有光照贡献和材质的透明度，计算并返回最终像素颜色。
*/


float3 MUniversalFragmentPBR(MInputData inputdata,float3 specular,float3 albedo,float smoothness,float3 emission,float F0)
{


/*
from: AmbientOcclusion.hlsl
use:暂时不知道为啥计算光照时要乘一个ao的衰减值
*/
AmbientOcclusionFactor aoFactor;
aoFactor.indirectAmbientOcclusion=1;
aoFactor.directAmbientOcclusion=1;

/*
from: RealtimeLights.hlsl
use:获取主光源
*/
 Light mainLight= GetMainLight(inputdata.shadowCoord, inputdata.positionWS, inputdata.shadowMask);
 /*
from: BRDF.hlsl  类似 InitializeBRDFData
use:获取BRDF所需参数
*/ 
MBRDFData  BRDF= getBRDFData(specular,albedo,smoothness);

  /*
use:初始化改点各种光照的数据 
*/ 
 MLightingData mLightingData;
 mLightingData.emissionColor= emission;
 //mLightingData.giColor= emission;
 mLightingData.mainLightColor= mainLight.color;
 //mLightingData.additionalLightsColor= emission;

/*
use:计算光照  暂时计算主副光源，对baked GI 学习后添加
*/ 
 mLightingData.mainLightColor = LightingPhysicallyBased(BRDF, mainLight, inputdata.normalWS, inputdata.viewDirectionWS,F0);

 /*
use:TODO其他光照
*/


 return float3(mLightingData.mainLightColor);


} 