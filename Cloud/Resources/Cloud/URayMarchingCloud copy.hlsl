// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


//  #define lightStep 8
//  #define CameraStep 32

// #define MaskNoiseSpeedScale 0.4
// #define ShapeNoiseSpeedScale 0.4

// // 将不占空间的材质相关变量放在CBUFFER中，为了兼容SRP Batcher
// CBUFFER_START(UnityPerMaterial)
// float4 _BaseMap_ST;
// half4 _BaseColor;
// float4 _SourceTex_TexelSize;
// float3 _BoundMin;
// float3 _BoundMax;
// float3 _Noise3DScale;//噪声图缩放比
// float3 _Noise3DOffSet;//噪声图偏移值
// float3 _FractalNoise3DScale;//分形噪声图缩放比
// float3 _FractalNoise3DOffSet;//分形噪声图偏移值
// float _DensityScale;
// float _Attenuation;//摩尔消光系数 越大越透
// float _LightPower;//光照散射强度控制参数
// float _LightAttenuation;//光照的摩尔消光系数 越大越透
// float3 _Transmissivity;//透射比 控制RGB波长对透射影响的不同
// float4 _HgPhase;//相位函数 常量参数 用来描述云雾得性质，为0时代表各向同性
// float3 _MainLight;
// float3 _EdgeSoftnessThreshold;
// float4 _MoveSpeed;
// float3 _TopColor;
// float3 _BottomColor;
// float2 _ColorOffSet;
// CBUFFER_END


          


// // 材质单独声明，使用DX11风格的新采样方法
// TEXTURE2D (_BaseMap);
// SAMPLER(sampler_BaseMap);

// TEXTURE2D (_MaskNoise);
// SAMPLER(sampler_MaskNoise);

// TEXTURE2D (_ShapeNoise);
// SAMPLER(sampler_ShapeNoise);

// TEXTURE2D (_WeatherMap);
// SAMPLER(sampler_WeatherMap);

// TEXTURE2D_X(_SourceTex);
// SAMPLER(sampler_SourceTex);
// sampler3D _Noise3D;
// sampler3D _FractalNoise3D;//分形噪声，优化云朵边缘
// //计算采样各地点深度值得到改点的世界坐标

// /*
// 关于 UNITY_REVERSED_Z z值是否取反的处理，因为远近视口不一样，从近->远用1->0，更好的均匀分步
//     UNITY_REVERSED_Z 是一种改变深度缓冲管理方式的技术，它颠倒了Z值的表示方式。在Reversed-Z中，近裁剪面的Z值较大（在DirectX中为1.0），而远裁剪面的Z值较小（在DirectX中为0.0）。这种方式的目的是使深度缓冲中的值在View Space下对应的平面更加均匀分布，从而减少Z-Fighting（深度冲突）现象，并提高渲染精度。
// */
// float3 GetWorldPosition(float3 positionCS)
//  { 
//         //float2 UV = positionCS.xy / _ScaledScreenParams.xy;
//         //#if UNITY_REVERSED_Z
//         //real depth = SampleSceneDepth(UV);
//         //#else
//         //real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
//         //#endif
//         //return ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);
//     float2 uv=positionCS.xy/_ScaledScreenParams.xy;

//     #if UNITY_REVERSED_Z 
//     float depth =SampleSceneDepth(uv);
//     #else
//     float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
//     #endif
//     // edit 下述 =  return ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);; 转到NDC 再转到world
//     float4 ndc=float4(uv.x*2-1,uv.y*2-1,depth,1);
//     #if UNITY_UV_STARTS_AT_TOP
//     ndc.y = -ndc.y;
//     #endif
//     float4 worldpos=mul(UNITY_MATRIX_I_VP,ndc);
//     worldpos=worldpos/worldpos.w;
//     //edit end
//     return  worldpos.xyz;
//  }



//  //施利克相位函数 模拟米氏散射
// float SchlickFunction(float costha,float g)
// {
//   float k=1.55*g-0.53*g*g*g;
//   return (1-k*k)/(4*PI*(1-k*costha)*(1-k*costha));

// }
// //亨利格林斯坦函数 模拟米氏散射  costha：光线和视线夹角 逆光方向上的散射光强度较大
// float HgPhaseFunction(float costha,float g)
// {
//     float g2 = g * g;
//     return (1 - g2)/(4*PI * pow(1 + g2 - 2 * g * costha, 1.5));
// }

// float hg(float a, float g) 
// {
//                 float g2 = g * g;
//                 return (1 - g2) / (4 * 3.1415 * pow(1 + g2 - 2 * g * (a), 1.5));
//             }
//  float phase(float a) 
//  {
//                 float blend = .5;
//                 float hgBlend = hg(a, _HgPhase.x) * (1 - blend) + hg(a, -_HgPhase.y) * blend;
//                 return _HgPhase.z + hgBlend * _HgPhase.w;
//             }


// //Beers Powder Function 比 比尔朗博定律的 exp(-a*d)来的更为真实   a：摩尔消光系数 d 浓度
// float3 BeerPowder(float3 d, float a)
// {
//     return exp(-d * a) * (1 - exp(-d* 2 * a));
// }

// //动态的云层采样
//  float sampleDynamicDensity(float3 position)
//  {
//     // float3 realpos=position*_Noise3DScale+_Noise3DOffSet;
//     //  float  density=tex3D(_Noise3D,realpos).r;
//     //  return  density;

//      /* 范围盒边缘衰减 */
//      float x_dis=min(_EdgeSoftnessThreshold.x, min(position.x - _BoundMin.x, _BoundMax.x - position.x));
//      float y_dis=min(_EdgeSoftnessThreshold.y, min(position.y - _BoundMin.y, _BoundMax.y - position.y));
//      float z_dis=min(_EdgeSoftnessThreshold.z, min(position.z - _BoundMin.z, _BoundMax.z - position.z));
//     float softness=(x_dis/_EdgeSoftnessThreshold.x)*(y_dis/_EdgeSoftnessThreshold.y)*(z_dis/_EdgeSoftnessThreshold.z) ;
//     /* 范围盒边缘衰减 */


//     //云朵层整体位移（形变）速度速度
//     float speedShape=_MoveSpeed.x*_Time.y;
//      //云朵细节形变速度
//     float speedDetail=_MoveSpeed.y*_Time.y;
//     //得到体积云中心
//     float3 center=(_BoundMax+_BoundMin)/2;
//     //得到体积云长宽高
//     float3 size = _BoundMax - _BoundMin;

//     //获得_Noise3D的采样坐标 ，缩放加有 timer控制的位移 就是前面基础方法的realpos
//     float3 samplingUVW=position*_Noise3DScale+speedShape*_Noise3DOffSet;
//    //获得_FractalNoise3D的采样坐标 ，缩放加有 timer控制的位移 就是前面基础方法的realpos2
//     float3 samplingFractalUVW=position*_FractalNoise3DScale+speedShape*_FractalNoise3DOffSet;

//     //采样
//       // material.SetTexture("_WeatherMap", m_rayMarchingCloudSetting.WeatherMap.value);
//        // material.SetTexture("_ShapeNoise", m_rayMarchingCloudSetting.ShapeNoise.value);
//         // material.SetTexture("_MaskNoise", m_rayMarchingCloudSetting.MaskNoise.value);
//         //整个云朵上该点的uv值 xz平面 ，等于将size.x size.z 归一化到（1，1）,且（0，0）在右下角;
//         //用来采样2d贴图
//         float2 uv= (size.xz*0.5+(position.xz-center.xz));
//         uv=float2(uv.x/size.x,uv.y/size.z);
//          //用来采样mask贴图
//         float3 mask=  SAMPLE_TEXTURE2D(_MaskNoise, sampler_MaskNoise, (uv+samplingUVW.xy*MaskNoiseSpeedScale));
//         float3 weather=  SAMPLE_TEXTURE2D(_WeatherMap, sampler_WeatherMap, (uv+samplingUVW.xy*ShapeNoiseSpeedScale));

//         float  density=tex3D(_Noise3D,samplingUVW+mask.r*_MoveSpeed.z*0.1).r;
//         float  density2=tex3D(_FractalNoise3D,samplingFractalUVW+density*_MoveSpeed.w*0.2).r;

//         return  max(0,density-density2)*_DensityScale*softness*softness ;
//  }


//  float sampleDensityWithFractalNoise(float3 position)
//  {
//      float3 realpos=position*_Noise3DScale+_Noise3DOffSet;
//      float  density=tex3D(_Noise3D,realpos).r;

//      float3 realpos2=position*_FractalNoise3DScale+_FractalNoise3DOffSet;
//      float  density2=tex3D(_FractalNoise3D,realpos2).r;
// /* 范围盒边缘衰减 */
//      float x_dis=min(_EdgeSoftnessThreshold.x, min(position.x - _BoundMin.x, _BoundMax.x - position.x));
//      float y_dis=min(_EdgeSoftnessThreshold.y, min(position.y - _BoundMin.y, _BoundMax.y - position.y));
//      float z_dis=min(_EdgeSoftnessThreshold.z, min(position.z - _BoundMin.z, _BoundMax.z - position.z));
//       float softness=(x_dis/_EdgeSoftnessThreshold.x)*(y_dis/_EdgeSoftnessThreshold.y)*(z_dis/_EdgeSoftnessThreshold.z) ;
//      return  max(0,density-density2)*_DensityScale*softness*softness ;
//  }


//   float2  RayMarchingBoundaryWithInside(float3 minPos,float3 maxPos,half3 rayOrigin,half3 rayDir)
//  {
//        //射线到两点的距离向量投影到单位方向向量上比较,得出远近
//       float3 minT=(minPos-rayOrigin)*rayDir;
//       float3 maxT=(maxPos-rayOrigin)*rayDir;
//       float3 frontT=min(minT,maxT);
//       float3 backT= max(minT,maxT);
//       //AABB 原理 frontT的最大值小于backT的最小值，则射线与盒子相交
//       //x,y,z分量的意义是射线在各自分量上移动几个单位接触到矩形的其中一个面

//       float dstA=max(frontT.x,max(frontT.y,frontT.z));//得到
//       float dstB=min(backT.x,min( backT.y,backT.z));


//       float x1=max(0,backT.x);
//       float y1=max(0,backT.y);
//       float z1=max(0,backT.z);
//        dstB=min(x1,min(y1,z1));
//       float dstToBox=max(dstA,0);//小于0说明在物体内发射 ，dstToBox*rayDir才是真实距离 

//       float dstInsideBox=max(0,dstB-dstToBox);//minback-dstToBox 大于0说明在物体内部通过
//       return  float2(dstToBox,dstInsideBox);
//  }

// // //TODO 模棱两可
//  float2  RayMarchingBoundary(float3 minPos,float3 maxPos,half3 rayOrigin,half3 rayDir)
//  {
//        //射线到两点的距离向量投影到单位方向向量上比较,得出远近
//       float3 minT=(minPos-rayOrigin)/rayDir;
//       float3 maxT=(maxPos-rayOrigin)/rayDir;
//       float3 frontT=min(minT,maxT);
//       float3 backT= max(minT,maxT);
//       //AABB 原理 frontT的最大值小于backT的最小值，则射线与盒子相交
//       //x,y,z分量的意义是射线在各自分量上移动几个单位接触到矩形的其中一个面
//       float dstA=max(frontT.x,max(frontT.y,frontT.z));//得到
//       float dstB=min(backT.x,min(backT.y,backT.z));

//       float dstToBox=max(dstA,0);//小于0说明在物体内发射 ，dstToBox*rayDir才是真实距离 

//       float dstInsideBox=max(0,dstB-dstToBox);//minback-dstToBox 大于0说明在物体内部通过
//       return  float2(dstToBox,dstInsideBox);
//  }


   

//  float sampleDensity(float3 position)
//  {
//     float3 realpos=position*_Noise3DScale+_Noise3DOffSet;
//      float  density=tex3D(_Noise3D,realpos).r;
//      return  density;
//  }

//  //计算该点的云朵浓度，这个不用计算遮挡的影响，因为如果这个点被遮挡住，就不会有光照给相机计算
// //相机到点射线上的每个采样点都得算一遍，是个积分过程
//  float  RayMarchingLight(float3 position)
//  {
//     //光照方向位置
//    float3 lightpos=_MainLightPosition.xyz;
//    //计算方向单位向量
//   // float3 rayDir=normalize(position-lightpos);
//    //计算距离参数
//    /*********** TODO:这里的给传入的方向反向了一下是因为，rayBoxDst的计算是要从目标点到体积，而采样时，则是反过来，从position出发到主光源*/

//    float2 data=RayMarchingBoundary(_BoundMin,_BoundMax,position,lightpos);
//    float dstInsideBox=data.y;
//    int stepnum=lightStep;//步数
//    float steplength=dstInsideBox/stepnum;
//    float3 steplengthvector=steplength*lightpos;
//    half totalDensity=0;
   
//     for(int i=0;i<stepnum;i++)
//     {
//         position+=steplengthvector;
//         totalDensity+= max(0, sampleDynamicDensity(position)*steplength);
       
//     }
//      return  totalDensity;
//  }


 
//   float3  RayMarchingLightWithColor(float3 position)
//  {
//     //光照方向位置
//    float3 lightpos=_MainLightPosition.xyz;
//    //计算方向单位向量
//   // float3 rayDir=normalize(position-lightpos);
//    //计算距离参数
//    /*********** TODO:这里的给传入的方向反向了一下是因为，rayBoxDst的计算是要从目标点到体积，而采样时，则是反过来，从position出发到主光源*/

//    float2 data=RayMarchingBoundary(_BoundMin,_BoundMax,position,lightpos);
//    float dstInsideBox=data.y;
//    int stepnum=lightStep;//步数
//    float steplength=dstInsideBox/stepnum;
//    float3 steplengthvector=steplength*lightpos;
//    half totalDensity=0;
   
//     for(int i=0;i<stepnum;i++)
//     {
//         position+=steplengthvector;
//         totalDensity+= max(0, sampleDynamicDensity(position)*steplength);
       
//     }

// //     float3 _TopColor;
// // float3 _BottomColor;
// // float2 _ColorOffSet;
// float3 cloudColor=lerp(_TopColor,_BaseColor,saturate(totalDensity*_ColorOffSet.x));
// cloudColor=lerp( _BottomColor,_BaseColor,saturate(pow(totalDensity*_ColorOffSet.y,3)));

//      return  cloudColor;
//  }




//  float Remap()
//  {


//  }

























//  //第一步
//  //射线步进的测试代码 从相机位置往计算出来的点按步数前进
// half RayMarchingTest(float3 orgin,float3 RayDir )
//  {
//     half color=0;
//     half color2=0.025;
//     float steplength=0.3;//步长
//     int stepnum=128;//步数
//     float Range=10;
//     float3 steplengthdir=RayDir*steplength;
//     float3 curPos=orgin;
//      for(int i=0;i<stepnum;i++)
//      {
//             curPos=curPos+steplengthdir;
//            if(curPos.x>-Range &&curPos.x<Range && curPos.y>-Range &&curPos.y<Range  && curPos.z>-Range &&curPos.z<Range)
//            {
//              color=color+color2;
//            }
//      }

//   return color;
//  }

 
// //用两点锁定一个矩形，然后得出射线线段

// /*
// 这段代码是一个用于计算射线与长方体包围盒（Axis-Aligned Bounding Box, AABB）相交情况的函数。
// 给定一个长方体的最小和最大边界点（boundsMin 和 boundsMax），
// 以及射线的起点（rayOrigin）和方向（rayDir），该函数计算出两个关键距离：
// dstToBox： 并不是最短距离，
// 而是射线从原点出发到首次与边界框相交点（如果存在）的参数值。这个参数值可以用于在射线追踪或光线投射算法中沿射线方向前进到相交点，
// 并计算相交点的具体位置。如果要计算实际的三维空间距离，你需要将这个参数值与射线的方向向量相乘，即 rayDir * dstToBox。
// 但是，在射线与边界框的相交检测中，我们通常只关心参数值，因为它足够我们确定射线与边界框的相交情况，并决定是否需要进一步处理。
// dstInsideBox：射线在长方体内部穿过的距离的参数值  rayDir * dstInsideBox 才是真实距离


// ！！！！！！(minPos - rayOrigin) / rayDir 
// 在射线与轴对齐边界框（AABB）的相交测试中有着非常重要的意义。这个表达式用于计算从射线原点（rayOrigin）到边界框的最小顶点（minPos）的向量在射线方向（rayDir）上的参数值。
// 具体来说，这个表达式的计算过程可以分为两步：
// 计算方向向量：minPos - rayOrigin 计算了一个从射线原点到边界框最小顶点的向量。这个向量描述了从射线原点到边界框最小顶点的位置和方向。
// 投影到射线方向：将上述计算得到的方向向量除以射线方向向量 rayDir，即 (minPos - rayOrigin) / rayDir，这个过程实际上是计算了从射线原点到边界框最小顶点的向量在射线方向上的投影长度（或者说，是在射线方向上的“距离”或“参数值”）。这个投影长度（或参数值）可以告诉我们沿着射线方向前进多远会首次接触到边界框。
// 如果 rayDir 是一个单位向量（即长度为1的向量），那么这个投影长度就直接是射线原点到边界框最小顶点的距离在射线方向上的分量。如果 rayDir 不是单位向量，那么结果将是这个距离与 rayDir 长度的比值，但无论如何，它都表示了沿着射线方向前进多远会首次接触到边界框。
// 在射线追踪、光线投射等图形学应用中，这种计算方式非常常见，因为它允许我们快速地确定射线与场景中物体的相交情况，从而决定如何渲染场景中的物体。
// */






//  //第二步
//  //带 摩尔消光，带3d噪声图,带射线步进aabb的云朵
//  float RayMarchingWithBoundary(float3 minPos,float3 maxPos,float3 rayOrigin,float3 rayDir,float3 positionWS)
//  {
//     //先得到相机到障碍物的距离
//     float dstobj=length(positionWS-rayOrigin);
//     //再得到相机到云朵最近距离 和 在云朵内部长度
//     float2 data=RayMarchingBoundary(minPos,maxPos,rayOrigin,rayDir);
//     float dstToBox=data.x;
//     float dstInsideBox=data.y;
//     //再得出真实计算云朵参数的长度,如果dstobj<dstToBox,说明完全被阻挡
//     float finalDst=min(dstInsideBox,dstobj-dstToBox);
//     //开始计算
//     //初始出发点，从矩形接触点开始
//     float3 firstpoint=rayOrigin+dstToBox*rayDir;
//     int stepnum=64;//步数
//     //步长=长度/步数
//     float steplength=dstInsideBox/stepnum;
//     float3 steplengthvector=steplength*rayDir;

//     half color=0;
//     //浓度 ,和步长关联上，这样不会因为步数造成稀薄
//     //half color2=0.1*steplength;
//     float3 curPos=firstpoint;
//     float cursteplength=0;
//     for(int i=0;i<stepnum;i++)
//     {
//         if(cursteplength<finalDst)
//         {  
//             color=color+steplength * sampleDensity(curPos);
           
//         }else
//         {
//             break;
//         }
//         curPos=curPos+steplengthvector;
//         cursteplength=cursteplength+steplength;
//     }
//      return  exp(-_Attenuation*color);
//  }








// //第三步
//  //带 摩尔消光，带3d噪声图,带射线步进aabb 带光照计算的云朵
// float3 RayMarchingWithBoundaryWithLight(float3 rayOrigin,float3 rayDir,float3 positionWS,float4 sourceColor)
//  {
//       float3 minPos=_BoundMin;
//     float3 maxPos=_BoundMax;
//     //先得到相机到障碍物的距离
//     float dstobj=length(positionWS-rayOrigin);
//     //再得到相机到云朵最近距离 和 在云朵内部长度
//     float2 data=RayMarchingBoundary(minPos,maxPos,rayOrigin,rayDir);
//     float dstToBox=data.x;
//     float dstInsideBox=data.y;
//     //再得出真实计算云朵参数的长度,如果dstobj<dstToBox,说明完全被阻挡
//     float finalDst=min(dstInsideBox,dstobj-dstToBox);
//     //开始计算
//     //初始出发点，从矩形接触点开始
//     float3 firstpoint=rayOrigin+dstToBox*rayDir;
//     int stepnum=CameraStep;//步数
//     //步长=长度/步数
//     float steplength=dstInsideBox/stepnum;
//     float3 steplengthvector=steplength*rayDir;

//     half totalDensity=0;//相机到点的浓度
//     half totalLightDensity=0;//光照到每个点的浓度

//     //浓度 ,和步长关联上，这样不会因为步数造成稀薄
//     //half color2=0.1*steplength;
//     float3 curPos=firstpoint;
//     float cursteplength=0;
//     for(int i=0;i<stepnum;i++)
//     {
//         if(cursteplength<finalDst)
//         {  
//             half curDensity=  steplength * sampleDensity(curPos);//当前点浓度值 采样获得
//             totalDensity=totalDensity+curDensity;//浓度值累加
//             half LightDensity=RayMarchingLight(curPos);//当前点到光照距离上的浓度和
//             totalLightDensity=totalLightDensity+exp(- (LightDensity*_LightAttenuation+totalDensity*_Attenuation))*curDensity;//每个点到光照距离上的浓度和累加（光纤到点衰减一次，点到相机再一次）
//             curPos=curPos+steplengthvector;
//             cursteplength=cursteplength+steplength;
//             continue;
//         }
//          break;
       
//     }

//     //现在拥有了光照的衰减系数
//     //可以把光照到相机的颜色计算出来
//     float3 cloudcolor= _MainLightColor*totalLightDensity*_BaseColor.xyz*_LightPower;
//      float3  albedo=sourceColor.xyz*exp(-_Attenuation*totalDensity)+cloudcolor;

//      return albedo  ;
//  }





//  //第四步
//  //带 摩尔消光，带3d噪声图,带射线步进aabb 带光照计算 带透射比 带相位函数  的云朵
// float3 RayMarchingWithBoundaryWithLightMoreCorrect(float3 rayOrigin,float3 rayDir,float3 positionWS,float4 sourceColor)
//  {

//     float3 minPos=_BoundMin;
//     float3 maxPos=_BoundMax;

//     //先得到相机到障碍物的距离
//     float dstobj=length(positionWS-rayOrigin);
//     //再得到相机到云朵最近距离 和 在云朵内部长度
//     float2 data=RayMarchingBoundary(minPos,maxPos,rayOrigin,rayDir);
//     float dstToBox=data.x;
//     float dstInsideBox=data.y;
//     //再得出真实计算云朵参数的长度,如果dstobj<dstToBox,说明完全被阻挡
//     float finalDst=min(dstInsideBox,dstobj-dstToBox);
//     //开始计算
//     //初始出发点，从矩形接触点开始
//     float3 firstpoint=rayOrigin+dstToBox*rayDir;
//     int stepnum=CameraStep;//步数
//     //步长=长度/步数
//     float steplength=dstInsideBox/stepnum;
//     float3 steplengthvector=steplength*rayDir;

//     half totalDensity=0;//相机到点的浓度
//     half3 totalLightDensity= half3(0,0,0);//光照到每个点的浓度

//     //浓度 ,和步长关联上，这样不会因为步数造成稀薄
//     //half color2=0.1*steplength;
//     float3 curPos=firstpoint;
//     float cursteplength=0;


//     /* 基于亨利·格林斯坦相位函数模拟米氏散射，这个函数可以在循环外侧计算 */
// //   float costha=dot(rayDir,_MainLightPosition.xyz);
//   // float  HgPhaseValue=HgPhaseFunction(costha,_HgPhase.x);
     
// /* 双瓣相位函数  基于两个亨利·格林斯坦相位函数插值模拟米氏散射   */
// float _costheta = dot(rayDir, _MainLightPosition.xyz);
// float HgPhaseValue = lerp(
//     HgPhaseFunction(_costheta, _HgPhase.x), 
//     HgPhaseFunction(_costheta, _HgPhase.y), 
//     _HgPhase.z
// );
//     for(int i=0;i<stepnum;i++)
//     {
//         if(cursteplength<finalDst)
//         {  
//             half curDensity=  steplength * sampleDensity(curPos);//当前点浓度值 采样获得
//             totalDensity=totalDensity+curDensity;//浓度值累加
//             half LightDensity=RayMarchingLight(curPos);//当前点到光照距离上的浓度和
//             totalLightDensity=totalLightDensity+exp(- (LightDensity*_LightAttenuation+totalDensity*_Attenuation)*_Transmissivity )*_Transmissivity*curDensity*HgPhaseValue;//每个点到光照距离上的浓度和累加（光纤到点衰减一次，点到相机再一次）
//             curPos=curPos+steplengthvector;
//             cursteplength=cursteplength+steplength;
//             continue;
//         }
//          break;
       
//     }

//     //现在拥有了光照的衰减系数
//     //可以把光照到相机的颜色计算出来
//      float3 cloudcolor= _MainLightColor*totalLightDensity*_BaseColor.xyz*_LightPower;
//      float3  albedo=sourceColor.xyz*exp(-_Attenuation*totalDensity)+cloudcolor;

//      return albedo  ;
//  }
 




//   //第五步
//  //带 摩尔消光，带3d噪声图,带射线步进aabb 带光照计算 带透射比 带相位函数 带 Beers Powder Function  的云朵
// float3 RayMarchingWithBoundaryWithLightMoreMoreCorrect(float3 rayOrigin,float3 rayDir,float3 positionWS,float4 sourceColor)
//  {

//     float3 minPos=_BoundMin;
//     float3 maxPos=_BoundMax;
//     //先得到相机到障碍物的距离
//     float dstobj=length(positionWS-rayOrigin);
//     //再得到相机到云朵最近距离 和 在云朵内部长度
//     float2 data=RayMarchingBoundary(minPos,maxPos,rayOrigin,rayDir);
//     float dstToBox=data.x;
//     float dstInsideBox=data.y;
//     //再得出真实计算云朵参数的长度,如果dstobj<dstToBox,说明完全被阻挡
//     float finalDst=min(dstInsideBox,dstobj-dstToBox);
//     //开始计算
//     //初始出发点，从矩形接触点开始
//     float3 firstpoint=rayOrigin+dstToBox*rayDir;
//     int stepnum=CameraStep;//步数
//     //步长=长度/步数
//     float steplength=dstInsideBox/stepnum;
//     float3 steplengthvector=steplength*rayDir;

//     half totalDensity=0;//相机到点的浓度
//     half totalBeerDensity=1;//for循环里每次 相机到点的比尔朗博定律值的累乘

//     float3 totalLightDensity= half3(0,0,0);//光照到每个点的浓度

//     //浓度 ,和步长关联上，这样不会因为步数造成稀薄
//     //half color2=0.1*steplength;
//     float3 curPos=firstpoint;
//     float cursteplength=0;


//     /* 基于亨利·格林斯坦相位函数模拟米氏散射，这个函数可以在循环外侧计算 */
// //   float costha=dot(rayDir,_MainLightPosition.xyz);
//   // float  HgPhaseValue=HgPhaseFunction(costha,_HgPhase.x);
     
// /* 双瓣相位函数  基于两个亨利·格林斯坦相位函数插值模拟米氏散射   */

// float _costheta = dot(rayDir, _MainLightPosition.xyz);
// float HgPhaseValue = lerp(
//     HgPhaseFunction(_costheta, _HgPhase.x), 
//     HgPhaseFunction(_costheta, _HgPhase.y), 
//     _HgPhase.z
// );
//     for(int i=0;i<stepnum;i++)
//     {
//         if(cursteplength<finalDst)
//         {  
//             half curDensity=  steplength * sampleDensityWithFractalNoise(curPos);//当前点浓度值 采样获得
       
//             half LightDensity=RayMarchingLight(curPos);//当前点到光照距离上的浓度和

//            //每个点到光照距离上的浓度和累加（光纤到点衰减一次，点到相机再一次）
//             float3 beervalue=  BeerPowder(LightDensity*_LightAttenuation*_Transmissivity,6);
//             float3  energy =beervalue*_Transmissivity*curDensity*HgPhaseValue;
        
           
//             //https://www.ea.com/frostbite/news/physically-based-sky-atmosphere-and-cloud-rendering
//             //加入多次散射衰减
//               float3 attenuation=_LightAttenuation*_Transmissivity;
//               energy=(energy-energy*BeerPowder(attenuation*LightDensity,6))/attenuation;

//             totalLightDensity+=energy *totalBeerDensity;
//             totalBeerDensity*= exp(-curDensity*_Attenuation);
//               if (totalBeerDensity < 0.01)
//              break;
        
//             curPos+=steplengthvector;
//             cursteplength+=steplength;
//             continue;
//         }
//          break;
       
//     }

//     //现在拥有了光照的衰减系数
//     //可以把光照到相机的颜色计算出来
//      float3 cloudcolor= _MainLightColor*totalLightDensity*_BaseColor.xyz*_LightPower;
//      float3  albedo=sourceColor.xyz*totalBeerDensity+cloudcolor;
//      return albedo ;
//  }
 



// //  float sampleDensityWithFractalNoise(float3 position)
// //  {
// //      float3 realpos=position*_Noise3DScale+_Noise3DOffSet;
// //      float  density=tex3D(_Noise3D,realpos).r;

// //      float3 realpos2=position*_FractalNoise3DScale+_FractalNoise3DOffSet;
// //      float  density2=tex3D(_FractalNoise3D,realpos2).r;

// //      return  max(0,density-density2)*_DensityScale*softness*softness ;
// //  }

//    //第六步
//  /*带 摩尔消光，
//  带3d噪声图,
//  带射线步进aabb 
//  带光照计算 带透射比 
//  带相位函数 
//  带 Beers Powder Function
//  带 移动
//  带 云朵轮廓 整体形状noise的

//   的云朵

//  */

// float3 RayMarchingWithBoundaryWithLightWithDynamic(float3 rayOrigin,float3 rayDir,float3 positionWS,float4 sourceColor)
//  {

//     float3 minPos=_BoundMin;
//     float3 maxPos=_BoundMax;
//     //先得到相机到障碍物的距离
//     float dstobj=length(positionWS-rayOrigin);
//     //再得到相机到云朵最近距离 和 在云朵内部长度
//     float2 data=RayMarchingBoundary(minPos,maxPos,rayOrigin,rayDir);
//     float dstToBox=data.x;
//     float dstInsideBox=data.y;
//     //再得出真实计算云朵参数的长度,如果dstobj<dstToBox,说明完全被阻挡
//     float finalDst=min(dstInsideBox,dstobj-dstToBox);
//     //开始计算
//     //初始出发点，从矩形接触点开始
//     float3 firstpoint=rayOrigin+dstToBox*rayDir;
//     int stepnum=CameraStep;//步数
//     //步长=长度/步数
//     float steplength=dstInsideBox/stepnum;
//     float3 steplengthvector=steplength*rayDir;
//     half totalDensity=0;//相机到点的浓度
//     half totalBeerDensity=1;//for循环里每次 相机到点的比尔朗博定律值的累乘
//     float3 totalLightDensity= half3(0,0,0);//光照到每个点的浓度
//     //浓度 ,和步长关联上，这样不会因为步数造成稀薄
//     //half color2=0.1*steplength;
//     float3 curPos=firstpoint;
//     float cursteplength=0;   
// /* 双瓣相位函数  基于两个亨利·格林斯坦相位函数插值模拟米氏散射   */
//     float _costheta = dot(rayDir, _MainLightPosition.xyz);
//     float HgPhaseValue= phase(_costheta);
//     // float HgPhaseValue = lerp(
//     //     HgPhaseFunction(_costheta, _HgPhase.x), 
//     //     HgPhaseFunction(_costheta, _HgPhase.y), 
//     //     _HgPhase.z
//     // );
//     for(int i=0;i<stepnum;i++)
//     {
//         if(cursteplength<finalDst)
//         {  
//             half curDensity=  steplength * sampleDynamicDensity(curPos);//当前点浓度值 采样获得
//             half3 LightDensity=RayMarchingLightWithColor(curPos);//当前点到光照距离上的浓度和
//            //每个点到光照距离上的浓度和累加（光纤到点衰减一次，点到相机再一次）
//             float3 beervalue=  exp(-LightDensity*_LightAttenuation*_Transmissivity);
//             float3  energy =beervalue*_Transmissivity*curDensity*HgPhaseValue;
//             //https://www.ea.com/frostbite/news/physically-based-sky-atmosphere-and-cloud-rendering
//             //加入多次散射衰减
//              //float3 attenuation=_LightAttenuation*_Transmissivity;
//            //  energy=(energy-energy*BeerPowder(attenuation*LightDensity,6))/attenuation;
//             totalLightDensity+=energy *totalBeerDensity;
//             totalBeerDensity*= exp(-curDensity*_Attenuation);
//             if (totalBeerDensity < 0.01)
//             break;
//             curPos+=steplengthvector;
//             cursteplength+=steplength;
//             continue;
//         }
//          break;
       
//     }

//     //现在拥有了光照的衰减系数
//     //可以把光照到相机的颜色计算出来 ,_BaseColor不需要再算了 RayMarchingLightWithColor中已经计算进去
//      float3 cloudcolor= _MainLightColor*totalLightDensity*_LightPower;
//      float3  albedo=sourceColor.xyz*totalBeerDensity+cloudcolor;
//      return albedo ;
//  }

// // float3 RayMarchingWithBoundaryWithLightWithDynamic(float3 rayOrigin,float3 rayDir,float3 positionWS,float4 sourceColor)
// //  {

// //     float3 minPos=_BoundMin;
// //     float3 maxPos=_BoundMax;
// //     //先得到相机到障碍物的距离
// //     float dstobj=length(positionWS-rayOrigin);
// //     //再得到相机到云朵最近距离 和 在云朵内部长度
// //     float2 data=RayMarchingBoundary(minPos,maxPos,rayOrigin,rayDir);
// //     float dstToBox=data.x;
// //     float dstInsideBox=data.y;
// //     //再得出真实计算云朵参数的长度,如果dstobj<dstToBox,说明完全被阻挡
// //     float finalDst=min(dstInsideBox,dstobj-dstToBox);
// //     //开始计算
// //     //初始出发点，从矩形接触点开始
// //     float3 firstpoint=rayOrigin+dstToBox*rayDir;
// //     int stepnum=CameraStep;//步数
// //     //步长=长度/步数
// //     float steplength=dstInsideBox/stepnum;
// //     float3 steplengthvector=steplength*rayDir;
// //     half totalDensity=0;//相机到点的浓度
// //     half totalBeerDensity=1;//for循环里每次 相机到点的比尔朗博定律值的累乘
// //     float3 totalLightDensity= half3(0,0,0);//光照到每个点的浓度
// //     //浓度 ,和步长关联上，这样不会因为步数造成稀薄
// //     //half color2=0.1*steplength;
// //     float3 curPos=firstpoint;
// //     float cursteplength=0;   
// // /* 双瓣相位函数  基于两个亨利·格林斯坦相位函数插值模拟米氏散射   */
// //     float _costheta = dot(rayDir, _MainLightPosition.xyz);
// //     float HgPhaseValue= phase(_costheta);
// //     // float HgPhaseValue = lerp(
// //     //     HgPhaseFunction(_costheta, _HgPhase.x), 
// //     //     HgPhaseFunction(_costheta, _HgPhase.y), 
// //     //     _HgPhase.z
// //     // );
// //     for(int i=0;i<stepnum;i++)
// //     {
// //         if(cursteplength<finalDst)
// //         {  
// //             half curDensity=  steplength * sampleDynamicDensity(curPos);//当前点浓度值 采样获得
// //             if(curDensity>0)
// //             {
// //             curPos+=steplengthvector;
// //             half LightDensity=RayMarchingLight(curPos);//当前点到光照距离上的浓度和
// //             //每个点到光照距离上的浓度和累加（光纤到点衰减一次，点到相机再一次）
// //             float3 beervalue=  BeerPowder(LightDensity*_LightAttenuation*_Transmissivity,6);
// //             float3  energy =beervalue*_Transmissivity*curDensity*HgPhaseValue;
// //             totalLightDensity+=energy *totalBeerDensity;
// //             totalBeerDensity*= exp(-curDensity*_Attenuation);
// //             if (totalBeerDensity < 0.01)
// //             break;
// //             }
// //             //https://www.ea.com/frostbite/news/physically-based-sky-atmosphere-and-cloud-rendering
// //             //加入多次散射衰减
// //             // float3 attenuation=_LightAttenuation*_Transmissivity;
// //             //  energy=(energy-energy*BeerPowder(attenuation*LightDensity,6))/attenuation;     
// //         }
// //           cursteplength+=steplength;
// //     }

// //     //现在拥有了光照的衰减系数
// //     //可以把光照到相机的颜色计算出来
// //      float3 cloudcolor= _MainLightColor*totalLightDensity*_BaseColor.xyz*_LightPower;
// //      float3  albedo=sourceColor.xyz*totalBeerDensity+cloudcolor;
// //      return albedo ;
// //  }
 