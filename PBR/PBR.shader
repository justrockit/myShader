Shader "Unlit/HlslUnlit"
{
    Properties
    {
        _BaseMap("MainTex", 2D) = "White" { }
        _BaseColor("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)
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
             #include "../ShaderLib/RTR.hlsl"

           
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
            CBUFFER_END

     
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
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
                    return output;
                }

                // 片段着色器
                half4 frag(Varyings input) : SV_Target
                {
                    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;


                }
            
            ENDHLSL
        }
    }
}