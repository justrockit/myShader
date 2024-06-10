Shader "Fsy/Base/PBR"
{
    Properties
    {
        _BaseMap("MainTex", 2D) = "White" { }

       _NormalMap("NormalMap", 2D) = "White" { }

        _BaseColor("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)

        _Specular("Specular", Float)=1.0
        _Albedo("Albedo", Float) = 1.0
        _Smoothness("Smoothness", Float) = 1.0
        _Emission("Emission", Vector) = (1.0, 1.0, 1.0)
        _F0("F0", Float) = 1.0
    }
    SubShader
    {       
        Tags
        {
            "RanderPipline" = "UniversalPipeline"
            "RanderType" = "Opaque"
        }

        HLSLINCLUDE

         
             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../ShaderLib/RTR.hlsl"
            

           
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                float _Specular;
                float _Albedo;
                float _Smoothness;
                float _F0;
                float3 _Emission;

            CBUFFER_END

     
            TEXTURE2D (_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            


            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS:      NORMAL;
                float3 tangent:      TANGENT;
                float2 uv         : TEXCOORD0;
             
                
              
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float4 shadowCoord : TEXCOORD2;
                float3 tangentT : TEXCOORD3;
                float3 tangentB : TEXCOORD4;
                float3 tangentN : TEXCOORD5;
                float3 viewDirectionWS:TEXCOORD6;
       
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
                     VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                    Varyings output;
                    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                    output.positionCS = vertexInput.positionCS; 
                    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                    //法线的处理方式是采样法线贴图,获得物体的法线坐标,切线，副切线，将其从切线空间转到世界坐标
                    output.tangentT = real3(1.0, 0.0, 0.0);
                    output.tangentB = real3(0.0, 1.0, 0.0);
                    output.tangentN = TransformObjectToWorldNormal(input.normalOS);
                    output.viewDirectionWS = GetWorldSpaceViewDir(output.positionWS);
                    output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);//获得着色点在阴影贴图中的点
                    return output;
                }
           


                    // 片段着色器
                    half4 frag(Varyings input) : SV_Target
                {
                     half4 basemap=   SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);


                    MInputData inputdata;
                    inputdata. positionWS= input.positionWS;

                    //法线的处理方式是采样法线贴图,获得物体的法线坐标,切线，副切线，将其从切线空间转到世界坐标
                    inputdata.normalWS = mul(UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv)), half3x3(input.tangentT, input.tangentB, input.tangentN));
                    inputdata.viewDirectionWS= input.viewDirectionWS;
                    inputdata.shadowCoord= input.shadowCoord;
                    inputdata.shadowMask= half4(1, 1, 1, 1);
                 //   half3 bakedGI;
                


                    float3 specular = _Specular;
                    float3 albedo= basemap.rgb;
                    float smoothness = _Smoothness;
                    float3 emission = _Emission;
                    float F0 = _F0;

                    float3 pbr=   MUniversalFragmentPBR(inputdata,specular, albedo, smoothness, emission, F0);

                    return half4(pbr, basemap.a);


                }
            
            ENDHLSL
        }
    }
}