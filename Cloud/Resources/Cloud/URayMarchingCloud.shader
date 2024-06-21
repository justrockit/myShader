Shader "Fsy/PP/Cloud"
{
    Properties
    {
        _BaseMap("MainTex", 2D) = "White" { }
        _BaseColor("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)

        _Noise3DScale("Noise3DScale",Vector)=(1,1,1)
        _Noise3DOffSet("Noise3DOffSet",Vector)=(0,0,0)
        _Noise3D("Noise3D",3D)="White" { }

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
                     float3 worldPosition = GetWorldPosition(input.positionCS);//用深度图获得世界坐标
                     float3 rayDir = normalize(worldPosition - _WorldSpaceCameraPos.xyz);
                    // return half4(rayDir, 0);
                     VertexPositionInputs vPInput=GetVertexPositionInputs(input.positionOS);
                      
                     //float3  RayDir=normalize( GetCameraPositionWS()- vPInput.positionWS);                  
                     half4  SourceColor= SAMPLE_TEXTURE2D_X(_SourceTex, sampler_SourceTex, input.uv);
                     half raydata=   RayMarchingWithBoundary(float3(-10,-10,-10),float3(10,10,10),_WorldSpaceCameraPos.xyz,rayDir,worldPosition);
                     
                     return SourceColor+raydata;
                }
            
            ENDHLSL
        }
    }
}