Shader "Fsy/PP/Cloud"
{
    Properties
    {
        _BaseMap("MainTex", 2D) = "White" { }
        _BaseColor("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)
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
            // 将不占空间的材质相关变量放在CBUFFER中，为了兼容SRP Batcher
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                 float4 _SourceTex_TexelSize;
            CBUFFER_END

            // 材质单独声明，使用DX11风格的新采样方法
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D_X(_SourceTex);
             SAMPLER(sampler_SourceTex);
          
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

                //计算采样各地点深度值得到改点的世界坐标
                float3 GetWorldPosition(float3 positionCS)
                {
                        /* get world space position from clip position */

                        //float2 UV = positionCS.xy / _ScaledScreenParams.xy;
                        //#if UNITY_REVERSED_Z
                        //real depth = SampleSceneDepth(UV);
                        //#else
                        //real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                        //#endif
                        //return ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);


                   float2 uv=positionCS.xy/_ScaledScreenParams.xy;
                   //关于 UNITY_REVERSED_Z z值是否取反的处理，因为远近视口不一样，从近->远用1->0，更好的均匀分步
                   /*
                     UNITY_REVERSED_Z 是一种改变深度缓冲管理方式的技术，它颠倒了Z值的表示方式。在Reversed-Z中，近裁剪面的Z值较大（在DirectX中为1.0），而远裁剪面的Z值较小（在DirectX中为0.0）。这种方式的目的是使深度缓冲中的值在View Space下对应的平面更加均匀分布，从而减少Z-Fighting（深度冲突）现象，并提高渲染精度。
                   */
                   #if UNITY_REVERSED_Z 
					float depth =SampleSceneDepth(uv);
				#else
					float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
				#endif
                  // ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP); 转到NDC 再转到world
                    float4 ndc=float4(uv.x*2-1,uv.y*2-1,depth,1);
                    #if UNITY_UV_STARTS_AT_TOP
    // Our world space, view space, screen space and NDC space are Y-up.
    // Our clip space is flipped upside-down due to poor legacy Unity design.
    // The flip is baked into the projection matrix, so we only have to flip
    // manually when going from CS to NDC and back.
    ndc.y = -ndc.y;
#endif
                    float4 worldpos=mul(UNITY_MATRIX_I_VP,ndc);
                    worldpos=worldpos/worldpos.w;
                 //   return ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);
                    return  worldpos.xyz;

                 }


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
                     float3 worldPosition = GetWorldPosition(input.positionCS);
                     float3 rayDir = normalize(worldPosition - _WorldSpaceCameraPos.xyz);
                     return half4(rayDir, 0);


                      VertexPositionInputs vPInput=GetVertexPositionInputs(input.positionOS);
                      //获得射线方向
                      float3  RayDir=normalize(vPInput.positionWS- GetCurrentViewPosition());
                     //float3  RayDir=normalize( GetCameraPositionWS()- vPInput.positionWS);


                   // half4  SourceColor= SAMPLE_TEXTURE2D_X(_SourceTex, sampler_SourceTex, input.uv);
                    return half4(RayDir,0);
                }
            
            ENDHLSL
        }
    }
}