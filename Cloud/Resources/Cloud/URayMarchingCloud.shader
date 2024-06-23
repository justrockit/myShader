
Shader "Fsy/PP/Cloud"
{
    Properties
    {
        _BaseMap("MainTex", 2D) = "White" { }
        _BaseColor("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)

        _Noise3DScale("Noise3DScale",Vector)=(1,1,1)
        _Noise3DOffSet("Noise3DOffSet",Vector)=(0,0,0)
        _Noise3D("Noise3D",3D)="White" { }
        _Attenuation("Attenuation",Float)=1.0
    }

    SubShader
    {
        // URP的shader要在Tags中注明渲染管线是UniversalPipeline
        Tags
        {
            "RanderPipline" = "UniversalPipeline"
            "RanderType" = "Opaque"
        }

        HLSLINCLUDE
            #pragma exclude_renderers gles
            // 引入Core.hlsl头文件，替换UnityCG中的cginc
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "URayMarchingCloud.hlsl"
            
     
     
         //   sampler3D _Noise3D;
          
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                 float3 positionOS : TEXCOORD1;
            };

        ENDHLSL

        Pass
        {
            // 声明Pass名称，方便调用与识别
            Name "ForwardUnlit"
            Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM

                // 声明顶点/片段着色器对应的函数
                #pragma vertex vert
                #pragma fragment frag
          #pragma enable_d3d11_debug_symbols

                // 顶点着色器
                Varyings vert(Attributes input)
                {
                    // GetVertexPositionInputs方法根据使用情况自动生成各个坐标系下的定点信息
                    const VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                    Varyings output;
                    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                    output.positionCS = vertexInput.positionCS;
                    output.positionOS = input.positionOS.xyz;
                    return output;
                }

                // 片段着色器
                half4 frag(Varyings input) : SV_Target
                {
                
                     //region 这段计算RayMarchingWithBoundary 无光照用
                  //   float3 worldPosition = GetWorldPosition(input.positionCS);//用深度图获得世界坐标
                 //   float3 rayDir = normalize(worldPosition - _WorldSpaceCameraPos.xyz);
                   // VertexPositionInputs vPInput=GetVertexPositionInputs(input.positionOS);      
                   //  half4  SourceColor= SAMPLE_TEXTURE2D_X(_SourceTex, sampler_SourceTex, input.uv);
                   //  half raydata=   RayMarchingWithBoundary(float3(-10,-10,-10),float3(10,10,10),_WorldSpaceCameraPos.xyz,rayDir,worldPosition);
                   // return SourceColor*raydata;
                    //endregion
                    float3 worldPosition = GetWorldPosition(input.positionCS);//用深度图获得世界坐标
                   float3 rayDir = normalize(worldPosition - _WorldSpaceCameraPos.xyz);
                   VertexPositionInputs vPInput=GetVertexPositionInputs(input.positionOS);      
                    half4  SourceColor= SAMPLE_TEXTURE2D_X(_SourceTex, sampler_SourceTex, input.uv);
                     half3 finalcolor=   RayMarchingWithBoundaryWithLight(float3(-10,-10,-10),float3(10,10,10),_WorldSpaceCameraPos.xyz,rayDir,worldPosition,SourceColor);

                     return half4(finalcolor,1);
                }
            
            ENDHLSL
        }
    }
}


//Shader "Fsy/PP/Cloud"{
    
//    Properties{
//        // 着色器输入
//        _MainTex("Main Texture", 2D) = "white"{}
//    }
//    SubShader{
//        Tags{
//            "RenderPipeline" = "UniversalRenderPipeline"
//        }
//        pass{

//            Cull Off
//            ZTest Always
//            ZWrite Off
            
//            HLSLPROGRAM

//                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
//                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
//                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
                
//                #pragma vertex Vertex
//                #pragma fragment Pixel

               
            
               
        


//CBUFFER_START(UnityPerMaterial)
//float4 _BaseMap_ST;
//half4 _BaseColor;
//float4 _SourceTex_TexelSize;
//float3 _DensityNoise_Scale;
//float3 _DensityNoise_Offset;
//float _Absorption;//吸光率 越大越透
//float _LightPower;
//float _LightAbsorption;

//CBUFFER_END

//// 材质单独声明，使用DX11风格的新采样方法
//TEXTURE2D (_BaseMap);
//SAMPLER(sampler_BaseMap);

//TEXTURE2D_X(_SourceTex);
//SAMPLER(sampler_SourceTex);
//sampler3D _DensityNoiseTex;

//                struct vertexInput{
//                    float4 vertex: POSITION;
//                    float2 uv: TEXCOORD0;
//                };
//                struct vertexOutput{
//                    float4 pos: SV_POSITION;
//                    float2 uv: TEXCOORD0;
//                };



//                float2 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 rayDir){
                
//                    float3 t0 = (boundsMin - rayOrigin) / rayDir;
//                    float3 t1 = (boundsMax - rayOrigin) / rayDir;
//                    float3 tmin = min(t0, t1);
//                    float3 tmax = max(t0, t1);

//                    float dstA = max(max(tmin.x, tmin.y), tmin.z);
//                    float dstB = min(tmax.x, min(tmax.y, tmax.z));

//                    float dstToBox = max(0, dstA);
//                    float dstInsideBox = max(0, dstB - dstToBox);
//                    return float2(dstToBox, dstInsideBox);
//                }

//                float sampleDensity(float3 position){

//                    float3 uvw = position * _DensityNoise_Scale + _DensityNoise_Offset;
//                    return tex3D(_DensityNoiseTex, uvw).r;
//                }
//                float LightPathDensity(float3 position, int stepCount){
                  

//                    // URP的主光源位置的定义名字换了一下
//                    float3 dirToLight = _MainLightPosition.xyz;
                    
     
//                    float dstInsideBox = rayBoxDst(float3(-10, -10, -10), float3(10, 10, 10), position, 1/dirToLight).y;
                    
//                    // 采样
//                    float stepSize = dstInsideBox / stepCount;
//                    float totalDensity = 0;
//                    float3 stepVec = dirToLight * stepSize;
//                    for(int i = 0; i < stepCount; i ++){
//                        position += stepVec;
//                        totalDensity += max(0, sampleDensity(position) * stepSize);
//                    }
//                    return totalDensity;
//                }

//                float3 GetWorldPosition(float3 positionHCS){
                   

//                    float2 UV = positionHCS.xy / _ScaledScreenParams.xy;
//                    #if UNITY_REVERSED_Z
//                        real depth = SampleSceneDepth(UV);
//                    #else
//                        real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
//                    #endif
//                    return ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);
//                }

//                vertexOutput Vertex(vertexInput v){

//                    vertexOutput o;
//                    o.pos = TransformObjectToHClip(v.vertex.xyz);
//                    o.uv = v.uv;
//                    return o;
//                }
//                half4 Pixel(vertexOutput IN): SV_TARGET{
                    
//                    // 采样主纹理
//                    half4 albedo =SAMPLE_TEXTURE2D_X(_SourceTex, sampler_SourceTex, IN.uv);

//                    // 重建世界坐标
//                    float3 worldPosition = GetWorldPosition(IN.pos);
//                    float3 rayPosition = _WorldSpaceCameraPos.xyz;
//                    float3 worldViewVector = worldPosition - rayPosition;
//                    float3 rayDir = normalize(worldViewVector);

//                    // 碰撞体积计算
//                    float2 rayBoxInfo = rayBoxDst(float3(-10, -10, -10), float3(10, 10, 10), rayPosition, rayDir);
//                    float dstToBox = rayBoxInfo.x;
//                    float dstInsideBox = rayBoxInfo.y;
//                    float dstToOpaque = length(worldViewVector);
//                    float dstLimit = min(dstToOpaque - dstToBox, dstInsideBox);

//                    // 浓度和光照强度采样
//                    int stepCount = 32;                                         // 采样的次数
//                    float stepSize = dstInsideBox / stepCount;                  // 步进的长度
//                    float3 stepVec = rayDir * stepSize;                         // 步进向量
//                    float3 currentPoint = rayPosition + dstToBox * rayDir;      // 采样起点
//                    float totalDensity = 0;
//                    float dstTravelled = 0;
//                    float lightIntensity = 0;
//                    for(int i = 0; i < stepCount; i ++){
//                        if(dstTravelled < dstLimit){
//                            float Dx = sampleDensity(currentPoint) * stepSize;
//                            totalDensity += Dx;
//                            float lightPathDensity = LightPathDensity(currentPoint, 8);
//                            lightIntensity += exp(-(lightPathDensity * _LightAbsorption + totalDensity * _Absorption)) * Dx;
                            
//                            currentPoint += stepVec;
//                            dstTravelled += stepSize;
//                            continue;
//                        }
//                        break;
//                    }
//                    float3 cloudColor = _MainLightColor.xyz * lightIntensity * _BaseColor.xyz * _LightPower;
//                    return half4(albedo * exp(-totalDensity * _Absorption) + cloudColor, 1);
//                }
//            ENDHLSL
//        }
//    }
//}