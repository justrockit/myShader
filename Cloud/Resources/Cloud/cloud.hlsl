/////////////////////////////////////////////////  SIGGRAPH 2023 Nubis 3 ProtoType Code //////////////////////////////////////////////////////////////

// SDF压缩算法

RGB565Color gConvertScalarToDXT1Endpoint_RoundDown(float inScalar, rcVec3 inUnpackDot)

{

    // gDXT1_5BitChannelValues and gDXT1_6BitChannelValues are lookup tables holding the exact value of each of the 32 R/B levels, and 64 G levels.

    int index_r = sFindLowerBoundIndex(gDXT1_5BitChannelValues, inScalar / inUnpackDot.mX);

    float val_r = gDXT1_5BitChannelValues[index_r] * inUnpackDot.mX;

    float residual_after_r = inScalar - val_r;

 

    float query_g = residual_after_r / inUnpackDot.mY;

    int index_g = sFindLowerBoundIndex(gDXT1_6BitChannelValues, query_g);

    float val_g = gDXT1_6BitChannelValues[index_g] * inUnpackDot.mY;

    float residual_after_g = residual_after_r - val_g;

 

    float query_b = residual_after_g / inUnpackDot.mZ;

    int index_b = sFindLowerBoundIndex(gDXT1_5BitChannelValues, query_b);

 

    return gCreate565Color(index_r, index_g, index_b);

}

 

// Modeling NVDF's

// BC6 压缩，RGB, 分辨率为512 * 512 * 64】, 1 Byte / Texel，16.777Mb

// R: Dimentional Profile

// G: Detail Type

// B: Density Scale

Texture3D VoxelCloudModelingDataTexture;

SamplerState VoxelDataSampler;

 

// Field Data NVDF

// DXT1/BC1压缩,分辨率为512 * 512 * 64, 距离范围从-256m~4096m重新钳制到0~1

Texture3D EncodedScalarTexture;

SamplerState BilinearSampler;

 

// Detail Noise

// 4通道RGBA体积纹理，分辨率128 * 128 * 128，未压缩尺寸为 2Bytes/Texel

// R：Low Freq "Curl-Alligator", G:High Freq "Curl-Alligator", B:Low Freq "Alligator", A: High Freq "Alligator"

Texture3D Cloud3DNoiseTextureC;

SamplerState Cloud3DNoiseSamplerC;

 

// 云密度建模需要的 Struct

struct VoxelCloudModelingData

{

    float mDimensionalProfile;

    float mDetailType;

    float mDensityScale;

}

 

// 云密度采样使用的 Struct

struct VoxelCloudDensitySamples

{

    float mProfile; // 大型密度场，也叫轮廓样本

    float mFull;    // 细节密度场，也叫完整样本

}

 

// 云的射线步进结构

struct CloudRenderingRaymarchInfo

{

    float mDistance;       // 光线行进距离

    float mCloudDistance;  // 到体素云表面的距离

    float mStepSize;       // 步进步幅

}

 

 

#define ValueRemapFuncionDef(DATA_TYPE) \

    DATA_TYPE ValueRemap(DATA_TYPE inValue, DATA_TYPE inOldMin, DATA_TYPE inOldMax, DATA_TYPE inMin, DATA_TYPE inMax) \

    { \

        DATA_TYPE old_min_max_range = (inOldMax - inOldMin); \

        DATA_TYPE clamped_normalized = saturate((inValue - inOldMin) / old_min_max_range); \

        return inMin + (clamped_normalized*(inMax - inMin)); \

    }

 

ValueRemapFuncionDef(float)

ValueRemapFuncionDef(float2)

ValueRemapFuncionDef(float3)

ValueRemapFuncionDef(float4)

 

 

float ValueErosion(float inValue, float inOldMin)

{

    // derrived from Set-Range, this function uses the oldMin to erode or inflate the input value. - inValues inflate while + inValues erode

    float old_min_max_range = (1.0 - inOldMin);

    float clamped_normalized = saturate((inValue - inOldMin) / old_min_max_range);

    return (clamped_normalized);

}

 

float GetFractionFromValue(float inValue, float inMin, float inMax)

{

    return saturate((inValue - inMin) / (inMax - inMin));

}

 

float GetVoxelCloudDistance(float3 inSampePosition)

{

    // Decompress BC1

    // 通过减少频繁访问的体素数据的内存瓶颈，与未压缩的纹理相比可以节省 10-30%

    float3 sampled_color = EncodedScalarTexture.Sample(BilinearSampler, uv).rgb;

    float result = dot(sampled_color, float3(1.0, 0.03529415, 0.00069204));

}

 

VoxelCloudModelingData GetVoxelCloudModelingData(float3 inSampePosition, float inMipLevel)

{

    VoxelCloudModelingData modeling_data;

    float3 Modeling_NVDF = VoxelCloudModelingDataTexture.SampleLOD(VoxelDataSampler, inSampePosition, inMipLevel).rgb;

    modeling_data.mDimensionalProfile = Modeling_NVDF.r;

    modeling_data.mDetailType = Modeling_NVDF.g;

    modeling_data.mDensityScale = Modeling_NVDF.b;

 

    return modeling_data;

}

 

float GetVoxelCloudMipLevel(CloudRenderingRaymarchInfo inRaymarchInfo, float inMipLevel)

{

    // Apply Distance based Mip Offset

    float mipmap_level = cUseVoxelFineDetailMipMaps ? log2(1.0 + abs(inRaymarchInfo.mDistance * cVoxelFineDetailMipMapDistanceScale)) + inMipLevel : inMipLevel;

    return mipmap_level;

}

 

float GetUprezzedVoxelCloudDensity(CloudRenderingRaymarchInfo inRaymarchInfo, float3 inSamplePosition, float inDimensionalProfile, float inType, float inDensityScale, float inMipLevel, bool inHFDetails)

{

    // Step1-Apply wind offset ：注意只有水平偏移

    inSamplePosition -= float3(cCloudWindOffset.x, cCloudWindOffset.y, 0.0) * voxel_cloud_animation_speed;

 

    // Step2-Sample noise ：注意MipLevel层级随距离而增加，根据Andrew的说法有效控制Mip层级能节省大概15%的性能

    float mipmap_level = GetVoxelCloudMipLevel(inRaymarchInfo, inMipLevel);

    // 4通道RGBA体积纹理，分辨率128 * 128 * 128，未压缩尺寸为 2Bytes/Texel

    // R：Low Freq "Curl-Alligator", G:High Freq "Curl-Alligator", B:Low Freq "Alligator", A: High Freq "Alligator"

    float4 noise = Cloud3DNoiseTextureC.SampleLOD(Cloud3DNoiseSamplerC, inSamplePosition * 0.01, mipmap_level);

 

    // Step3-Define Detail Erosion ：一个观察规律是高度密度区域需要较高频细节，低密度区需要较低频细节

    // 由于DimensionalProfile【准确得说是mProfile】已经包含了云从表面到内部的密度梯度变化【密度逐渐增大】

 

    // 定义wispy噪声

    float wispy_noise = lerp(noise.r, noise.g, inDimensionalProfile);

 

    // 定义billowy噪声

    float billowy_type_gradient = pow(inDimensionalProfile, 0.25);

    float billowy_noise = lerp(noise.b * 0.3, noise.a * 0.3, billowy_type_gradient);

 

    // 定义High Noise composite - blend to wispy as the density scale decreases.

    float noise_composite = lerp(wispy_noise, billowy_noise, inType);

 

    // 是否启用超高频细节

    if(inHFDetails)

    {

        // 使用采样获得的高频噪声调制出更高频的噪声，以弥补从云体上表面飞过摄像机非常靠近云时细节信息的缺乏

        float hhf_wisps = 1.0 - pow(abs(abs(noise.g * 2.0 - 1.0) * 2.0 - 1.0), 4.0);

        float hhf_billows = pow(abs(abs(noise.a * 2.0 - 1.0) * 2.0 - 1.0), 2.0);

        float hhf_noise = saturate(lerp(hhf_wisps, hhf_billows, inType));

        float hhf_noise_distance_range_blender = ValueRemap(inRaymarchInfo.mDistance, 50.0, 150.0, 0.9, 1.0); // 50，150的单位是m

        noise_composite = lerp(hhf_noise, noise_composite, hhf_noise_distance_range_blender);

    }

 

    // 组合噪声

    float uprezzed_density = ValueErosion(inDimensionalProfile, noise_composite);

    float powered_density_scale = pow(saturate(inDensityScale), 4.0);

    uprezzed_density *= powered_density_scale;

 

    // 这一行是一个技巧性做法，这样的power操作可以使得低密度区进一步锐化呈现更清晰的结果

    uprezzed_density = pow(uprezzed_density, lerp(0.3, 0.6, max(EPSILON, powered_density_scale)));

 

    if(inHFDetails)

    {

        float distance_range_blender = GetFractionFromValue(inRaymarchInfo.mDistance, 50.0, 150.0);

        uprezzed_density = pow(uprezzed_density, lerp(0.5, 1.0, distance_range_blender)) * lerp(0.666, 1.0, distance_range_blender);

    }

 

    // 返回带有软边缘的最终噪声

    return uprezzed_density;

}

 

VoxelCloudDensitySamples GetVoxelCloudDensitySamples(CloudRenderingRaymarchInfo inRaymarchInfo, float3 inSamplePosition, float inMipLevel, bool inHFDetails)

{

    // 初始化体素云密度模型结构体

    VoxelCloudModelingData modeling_data;

    // 初始化密度采样结构体

    VoxelCloudDensitySamples density_samples;

   

    // 获取包围盒内的采样位置，调用函数获取模型数据

    float3 sample_coord = (inSamplePosition - cVoxelCloudBoundsMin) / (cVoxelCloudBoundsMax - cVoxelCloudBoundsMin);

    modeling_data = GetVoxelCloudModelingData(sample_coord, inMipLevel);

 

    // Assign data

    float dimensional_profile = modeling_data[0];

    float type = modeling_data[1];

    float density_scale = modeling_data[2];

   

    // 如果剖面距离场数据大于0,则返回细节细节密度场

    // be visible in the reflections anyways.

    if (dimensional_profile > 0.0)

    {

        // 基于SDF的空间剖面 * 调制密度 = 最终大型密度

        density_samples.mProfile = dimensional_profile * density_scale;

 

        // 调用up-rez函数计算云的最终密度

        if(!cRenderDome)

            density_samples.mFull = GetUprezzedVoxelCloudDensity(inRaymarchInfo, inSamplePosition, dimensional_profile, type, density_scale, inMipLevel, inHFDetails)

                                    * ValueRemap(inRaymarchInfo.mDistance, 10.0, 120.0, 0.25, 1.0);

        else

            density_samples.mFull = density_samples.mProfile;

    }

    else        

    {

        density_samples.mFull = density_samples.mProfile = 0.0;

    }

 

    // Return result

    return density_samples;

}

 

// Raymarching结构

void RaymarchVoxelClouds(CloudRenderingGlobalInfo inGlobalInfo, float2 inRaySegment, inout CloudRenderingPixelData ioPixelData)

{

    // 初始化 raymarching 信息结构并设置到射线段开头的起始距离

    CloudRenderingRaymarchInfo raymarch_info;

    raymarch_info.mDistance = inRaySegment[0];

 

    // 主步进循环

    while(ioPixelData.mTransmittance > view_ray_transmittance_limit && raymarch_info.mDistance < min(inRaySegment[1], inGlobalInfo.mMaxDistance))

    {

        // 定位到摄像机方向上的云表面位置

        float3 sample_pos = inGlobalInfo.mCameraPosition.xyz + inGlobalInfo.mViewDirection * raymarch_info.mDistance;

        // 云体内使用自适应步幅（最小不小于1m）

        float adaptive_step_size = max( 1.0, max(sqrt(raymarch_info.mDistance), EPSILON) * 0.08);

        // 采样距离场，找到最近体素云表面距离

        raymarch_info.mCloudDistance = GetVoxelCloudDistance(sample_pos);

        // 取有符号距离和自适应步长中的最大值，这可以保证云体内时使用自适应步长来做为步进步幅

        raymarch_info.mStepSize = max(raymarch_info.mCloudDistance, adaptive_step_size);

        // 基于步长的抖动来减少摄像机方向上切片式伪影

        float jitter_distance = (raymarch_info.mDistance < 250.0 ? inGlobalInfo.mJitteredHash : inGlobalInfo.mStaticHash) * raymarch_info.mStepSize;

        sample_pos += inGlobalInfo.mViewDirection * jitter_distance;

 

        // 进入云内

        if (raymarch_info.mCloudDistance < 0.0)

        {

            // 获取采样数据

            VoxelCloudDensitySamples voxel_cloud_sample_data = GetVoxelCloudDensitySamples(raymarch_info, sample_pos, inMipLevel, inHFDetails);

            // 积分方程计算云照明

            // 前两个LightingPos采用传统向着光源的阴影射线步进，从第三个开始采样体素化光场中预计算的数据【256 * 256 * 32，分辨率是密度体素网格的1/8】

            IntegrateCloudSampleData(voxel_cloud_sample_data, inGlobalInfo, raymarch_info, ioPixelData, false);

        }

 

        // 移动至下一步

        raymarch_info.mDistance += raymarch_info.mStepSize;

    }

 

}

 

 

/////////////////////////////////////////////////   IntegrateCloudSampleData内的部分原型代码 //////////////////////////////////////////////////////////////

// 使用轮廓剖面做为散射概率场

ms_volume = dimensional_profile;

// 获取云景的距离场

cloud_distance = GetVoxelCloudDistance(inSamplePosition);

// 吸收与外散射评估，inSunLightSummedDensitySamples是预先计算的DensityToSun

ms_volume *= exp(-inSunLightSummedDensitySamples * Remap(sun_dot, 0.0, 0.9, 0.25, ValueRemap(cloud_distance, -128.0, 0.0, 0.05, 0.25)));

 

// 同2.5D云一样，也使用维度剖面来近似环境光

float ambient_scattering = pow(1.0 - dimensional_profile, 0.5);

// 朝向天光的环境光

float ambient_scattering = pow(1.0 - dimensional_profile, 0.5) * exp(-summed_ambient_density);

 

// 第二光源支持：主要是做为局部光源的点光源

float potential_energy = pow( 1.0 - (d1 / radius), 12.0);

float pseudo_attenuation = (1.0 - saturate(density * 5.0));

float glow_energy = potential_energy * pseudo_attenuation;

 

 