Shader "Unlit/M_BaseUlit"
{
    Properties
    {
        [Header(Base)][Space(6)]
        [MainTexture]_BaseMap ("Texture", 2D) = "white" {}
        [MainColor] _BaseColor ("BaseColor",Color)=(0,0,0,1)
    }
    SubShader
    {
        Tags { 
          "RanderPipline" = "UniversalPipeline"
            "RanderType" = "Opaque"
        }
       
           HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
             #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
            CBUFFER_END
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);

            ENDHLSL
        Pass
        {
         Name "ForwardUnlit"
            Tags {"LightMode" = "UniversalForward"}
            HLSLPROGRAM
             #pragma only_renderers gles gles3 glcore d3d11
             #pragma target 2.0
             #pragma multi_compile_instancing

             #pragma vertex vert
             #pragma fragment frag
         
            #include "./M_H_BaseUlit.hlsl"
            ENDHLSL
        }
    }
}
