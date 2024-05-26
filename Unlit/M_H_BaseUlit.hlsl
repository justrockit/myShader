struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

struct v2f 
            {
                float2 uv : TEXCOORD0;           
                float4 vertex : SV_POSITION;
            };

//float4 TransformObjectToHClip(float3 mvertex)
//{
// mul(UNITY_MATRIX_VP,mul(UNITY_MATRIX_M,float4(mvertex,1.0)));
//}

v2f vert (appdata v)
    {
    v2f o;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    o.vertex = TransformObjectToHClip(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
    return o;
    }

float4 frag (v2f i) : SV_Target
    {
    
    float4 col = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv);
    col=col*_BaseColor;
   
    return col;
    }