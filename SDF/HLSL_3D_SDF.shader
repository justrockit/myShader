Shader "Unlit/HlslUnlit"
{
    Properties
    {
        _BaseMap("MainTex", 2D) = "White" { }
        _BaseColor("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _OffSet("OffSet",float)=1
        _EdgeColor ("EdgeColor", Color) = (0, 0, 0, 1)

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

            // 将不占空间的材质相关变量放在CBUFFER中，为了兼容SRP Batcher
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
            CBUFFER_END

            // 材质单独声明，使用DX11风格的新采样方法
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv        : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv[9]        : TEXCOORD0;
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

            float _OffSet;
            half4 _EdgeColor;
            //亮度计算
              half luminance(half4 color) {
                return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
                }

              //Sobel算子求卷积
             half3 Sobel(Varyings input)
             {
                half Gx[9]={
                -1,0,1,
                -2,0,2,
                -1,0,1
         
                };
                half   Gy[9]={
                -1,-2,-1,
                0,0,0,
                1,2,1
                };
                half GxSum=0;
                half GySum=0;
                for(int i=0;i<9;i++)
                    {
                      GxSum=GxSum+luminance(SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap,input.uv[i]));
                      GySum=GySum+ luminance(SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap,input.uv[i]));
                    }
                    
                    half edge = 1 - abs(GxSum) - abs(GySum); //绝对值代替开根号求模，节省开销
                 //half edge = 1 - pow(GxSum*GySum + GySum*GySum, 0.5);

                 return edge;

         }

                // 顶点着色器
                Varyings vert(Attributes input)
                {
                    // GetVertexPositionInputs方法根据使用情况自动生成各个坐标系下的定点信息
                    const VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                    Varyings output;
                     output.uv[0] = TRANSFORM_TEX(input.uv+_OffSet*float2(-1,1), _BaseMap);
                     output.uv[1] = TRANSFORM_TEX(input.uv+_OffSet*float2(0,1), _BaseMap);
                     output.uv[2] = TRANSFORM_TEX(input.uv+_OffSet*float2(1,1), _BaseMap);
                     output.uv[3] = TRANSFORM_TEX(input.uv+_OffSet*float2(-1,0), _BaseMap);
                     output.uv[4] = TRANSFORM_TEX(input.uv, _BaseMap);
                     output.uv[5] = TRANSFORM_TEX(input.uv+_OffSet*float2(1,0), _BaseMap);
                     output.uv[6] = TRANSFORM_TEX(input.uv+_OffSet*float2(-1,-1), _BaseMap);
                     output.uv[7] = TRANSFORM_TEX(input.uv+_OffSet*float2(0,-1), _BaseMap);
                     output.uv[8] = TRANSFORM_TEX(input.uv+_OffSet*float2(1,-1), _BaseMap);

                    output.positionCS = vertexInput.positionCS;
                    return output;
                }


                // 片段着色器
                half4 frag(Varyings input) : SV_Target
                {
                 half  edge=Sobel(input);
                 if(edge>0.5)
                    edge=1;
                 else
                   edge=0;

                  half4 realcolor=_BaseColor;
                  realcolor= lerp(realcolor,_EdgeColor,edge);

                 return realcolor;
                }
            
            ENDHLSL
        



    }




}}