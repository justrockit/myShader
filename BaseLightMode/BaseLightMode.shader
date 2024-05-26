Shader "Unlit/BaseLightMode"
{
    Properties
    {
        _BaseMap("MainTex", 2D) = "White" { }
        _BaseColor("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)
        // [Header(漫反射系数)][Space(6)]
        _DiffuseValue("Diffuse",Color)=  (1.0, 1.0, 1.0, 1.0)

         // [Header(镜面反射系数)][Space(6)]
       //  _SpecularValue("Specular",Color)= (1.0, 1.0, 1.0, 1.0)
         _SpecularRange("SpecularRange",Range(0,100))=1//高光约束
         _SpecularScaleRange("SpecularScaleRange",Range(0,100))=1
        [Header(BandedLighting)][Space(6)]
        _Color1("Color1",Color)=  (1.0, 1.0, 1.0, 1.0)
          _Color2("Color2",Color)=  (1.0, 1.0, 1.0, 1.0)
            _Color3("Color3",Color)=  (1.0, 1.0, 1.0, 1.0)
               _BandedStep("BandedStep",Range(0,100))=1
        

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

            // 引入Core.hlsl头文件，替换UnityCG中的cginc
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            // 将不占空间的材质相关变量放在CBUFFER中，为了兼容SRP Batcher
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half4 _DiffuseValue;
               // half4 _SpecularValue;
                half  _SpecularRange;
                  half  _SpecularScaleRange;
                   half4 _Color1;
                    half4 _Color2;
                     half4 _Color3;
                   half _BandedStep;
            CBUFFER_END

            // 材质单独声明，使用DX11风格的新采样方法
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float3 worldnormal:NORMAL;
                float3 positionWS : TEXCOORD1;
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

                // 顶点着色器
                Varyings vert(Attributes input)
                {
                    // GetVertexPositionInputs方法根据使用情况自动生成各个坐标系下的定点信息
                    const VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                    Varyings output;
                    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                    output.positionCS = vertexInput.positionCS;
                    output.positionWS=vertexInput.positionWS;
                    // mul(UNITY_MATRIX_M,float4(input.normal,1.0));
                    output.worldnormal=normalize( TransformObjectToWorldNormal(input.normal));
                    return output;
                }

//float4 _MainLightPosition;
//half4 _MainLightColor;
                //
                // 片段着色器
                half4 frag(Varyings input) : SV_Target
                {
                return 1;
               // //多光源兰伯特模型
               ////regin
               // half4 Emissive= SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
               // half4 mainLight=_MainLightColor*max(0,dot(_MainLightPosition-input.positionWS,input.worldnormal)) ;    
               // half4  finalcolor=Emissive*mainLight;
               // int count=  _AdditionalLightsCount;
               // for(int i=0;i<count;i++)
               // {
               //  Light L =  GetAdditionalLight(i,input.positionWS);
               //  finalcolor.xyz=finalcolor.xyz + Emissive.xyz*L.color*L.distanceAttenuation*max(0,dot( L.direction,input.worldnormal));
               // }
               // return finalcolor;
               // //endregin

               ////多光源半兰伯特模型
               ////regin
               // half4 Emissive= SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
               // half4 mainLight=_MainLightColor*max(0, pow(dot(input.worldnormal,_MainLightPosition-input.positionWS)*0.5+0.5,2) ) ;    
               // half4  finalcolor=Emissive*mainLight;
               // int count=  _AdditionalLightsCount;
               // for(int i=0;i<count;i++)
               // {
               //  Light L =  GetAdditionalLight(i,input.positionWS);
               //  finalcolor.xyz=finalcolor.xyz + Emissive.xyz*L.color*L.distanceAttenuation *max(0,pow(dot(input.worldnormal, L.direction)*0.5+0.5,2));
               // }
               // return finalcolor;
               // //endregin

               // //多光源 Phong模型  环境光+漫反射+高光  Ambient Diffuse SPECULAR    光照Phong模型用来模拟高光效果，它认为 从物体表面反射出的光线中包括 粗糙表面的漫反射与光滑表面高光 两部分。
               ////regin
               // half4  Emissive= SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
               // float3 worldNormal= input.worldnormal;
               // float3 worldMainLight=normalize(_MainLightPosition-input.positionWS) ;
               // float3  worldView= GetWorldSpaceViewDir(input.positionWS);

               // // 环境光
               // half3  _Ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
               //  // 漫反射
               // half3  _Diffuse=_MainLightColor.rgb*_DiffuseValue.rgb *saturate(pow(dot(worldNormal,worldMainLight)*0.5+0.5,2));
               // //高光 镜面反射 可以用reflect（）
               //// float3 specularArrow=normalize(-worldMainLight.xyz - 2*worldNormal*dot(worldNormal,-worldMainLight.xyz));  
               // float3 specularArrow=reflect(-worldMainLight.xyz,worldNormal);
                
               // //_SpecularRange 越大，pow值越小，高光越收敛
               // half3 _Specular= _MainLightColor.rgb * pow(saturate(dot(worldView,specularArrow)),_SpecularRange)*_SpecularScaleRange;
               // int count=  _AdditionalLightsCount;
               // for(int i=0;i<count;i++)
               // {
               //  Light L =  GetAdditionalLight(i,input.positionWS);
               // _Diffuse= _Diffuse+ L.color.rgb*L.distanceAttenuation*_DiffuseValue.xyz*saturate(pow(dot(worldNormal, L.direction)*0.5+0.5,2));

               // // float3 subSpecularArrow=normalize(-L.direction.xyz- 2*worldNormal*dot(worldNormal,-L.direction.xyz));
               //  float3 subSpecularArrow=reflect(-L.direction.xyz,worldNormal);
               // _Specular=_Specular+L.color.rgb*L.distanceAttenuation*pow(saturate(dot(subSpecularArrow,worldView)),_SpecularRange)*_SpecularScaleRange;
               // }
               // half3  finalcolor= Emissive.xyz*(_Specular+_Diffuse+_Ambient);
               // return half4 (finalcolor,Emissive.a);
               //  //return  finalcolor;
               // //endregin

               ////Banded Lighting 这个方法更像一个Trick而不是一个光照模型。基本原理就是对NdotL做条状化处理，卡通渲染效果的二分卡边原理与此类似。
               ////regin

               // half4  Emissive= SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
               // float3 worldNormal= input.worldnormal;
               // float3 worldMainLight=normalize(_MainLightPosition-input.positionWS) ;
                

               // half  _DiffuseV=dot(worldNormal,worldMainLight)*0.5+0.5;
              
               // half interpolationValue=  floor(_DiffuseV*_BandedStep)/_BandedStep;
               // half3 c1=lerp(_Color1,_Color2,interpolationValue);
               // half3 c2=lerp(_Color2,_Color3,interpolationValue);
               // half3 final=smoothstep(c1,c2,interpolationValue);
               // return half4 (final*Emissive,Emissive.a);
               //  //return  finalcolor;
               ////endregin

               //次表面散射

                }
            
            ENDHLSL
        }
    }
}