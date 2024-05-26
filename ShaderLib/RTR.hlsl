#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Version.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Deprecated.hlsl"


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
float  MicrofacetSpecularBRDF(float roughness,half3 N_WS,half3 V_WS,half3 L_WS,float3 F0)
{
 // half
float H=normalize(V_WS+L_WS);
float NoV=dot(N_WS,V_WS);
float NoH=dot(N_WS,H_WS);
float NoL=dot(N_WS,L_WS);
float bottom=4*NoV*NoL;
float G=SmithGGX(roughness,NoV,NoL);
float F=FresnelSchlick(roughness, NoV, NoL);
}
//非金属 
float  MicrofacetSpecularBRDF(float roughness,half3 N_WS,half3 V_WS,half3 L_WS,float F0)
{
 // half
float H=normalize(V_WS+L_WS);
float NoV=dot(N_WS,V_WS);
float NoH=dot(N_WS,H_WS);
float NoL=dot(N_WS,L_WS);
float VoH=dot(N_WS,H);
float bottom=4*NoV*NoL;
float G=SmithGGX(roughness,NoV,NoL);
float F=FresnelSchlick(F0, NoV, NoL);
}



//------------------------------------------------------