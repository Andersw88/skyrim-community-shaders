#ifdef __INTELLISENSE__
	#define VERTICAL
	#define VR
#endif

RWTexture2D<float4> OcclusionRW : register(u0);

SamplerState LinearSampler : register(s0);

Texture2D<float4> DepthTexture : register(t0);

cbuffer PerFrame : register(b0)
{
	float2 BufferDim;
	float2 RcpBufferDim;
	float4x4 ProjMatrix[2];
	float4x4 InvProjMatrix[2];
	float4x4 ViewMatrix[2];
	float4x4 InvViewMatrix[2];
	float4 DynamicRes;
	float4 InvDirLightDirectionVS[2];
	float4 CameraData[2];
	float ShadowDistance;
	uint MaxSamples;
	float FarDistanceScale;
	float FarThicknessScale;
	float FarHardness;
	float NearDistance;
	float NearThickness;
	float NearHardness;
	float BlurRadius;
	float BlurDropoff;
	bool Enabled;
};

float3 WorldToView(float3 x, bool is_position = true, uint a_eyeIndex = 0)
{
	float4 newPosition = float4(x, (float)is_position);
	return mul(ViewMatrix[a_eyeIndex], newPosition).xyz;
}

float2 ConvertToStereoUV(float2 uv, uint a_eyeIndex)
{
// #ifdef VR
	// convert [0,1] to eye specific [0,.5] and [.5, 1] dependent on a_eyeIndex
	uv.x = (uv.x + (float)a_eyeIndex) / 2;
	// if(a_eyeIndex == 0)
	// {
	// uv.x = uv.x / 2;
	// }
	// else 
	// {
	// 	// uv.x = uv.x / 4;
	// 	uv.x = 10;
	// }
// // #endif
// 	uv.x = 10;
	return uv;
}

float2 ConvertFromStereoUV(float2 uv, uint a_eyeIndex)
{
#ifdef VR
	// convert [0,.5] to [0, 1] and [.5, 1] to [0,1]
	uv.x = 2 * uv.x - (float)a_eyeIndex;
#endif
	return uv;
}


// Get a raw depth from the depth buffer. [0,1] in uv space
float GetDepth(float2 uv, uint a_eyeIndex)
{
	// uv = ConvertToStereoUV(uv, a_eyeIndex);
	// uv = ConvertToStereoUV(uv, a_eyeIndex);
	uv = ConvertToStereoUV(uv, a_eyeIndex);
	// return DepthTexture.Load(int3(uv * BufferDim, 0));
	return DepthTexture.SampleLevel(LinearSampler, uv * DynamicRes.xy, 0).r;
}

float GetScreenDepth(float depth, uint a_eyeIndex)
{
	// return (CameraData[a_eyeIndex].w / (-depth * CameraData[a_eyeIndex].z + CameraData[a_eyeIndex].x));
	return (CameraData[a_eyeIndex].w / (-depth * CameraData[a_eyeIndex].z + CameraData[a_eyeIndex].x));
}




// // Get a raw depth from the depth buffer.
float GetDepth2(float2 uv)
{
	return DepthTexture.SampleLevel(LinearSampler, uv * DynamicRes.xy, 0).r;
}

// Inverse project UV + raw depth into the view space.
float3 InverseProjectUVZ(float2 uv, float z, uint a_eyeIndex)
{
	// cp.x = (cp.x + (float)a_eyeIndex) / 2;
    uv.y = 1 - uv.y;
    // uv.x *= 2;
    float4 cp = float4(uv * 2 - 1, z, 1);
    // float4 cp = float4(uv * 2, z, 1);
    // float4 cp = float4(uv * 2, z, 1);
    float4 vp = mul(InvProjMatrix[a_eyeIndex], cp);
    // float4 vp = mul(InvProjMatrix[a_eyeIndex], uv);
    // float4 vp = mul(cp, InvProjMatrix[a_eyeIndex]);
    return vp.xyz / vp.w;
}

float GetScreenDepth(float2 uv, uint a_eyeIndex)
{
	float depth = GetDepth(uv, a_eyeIndex);
	// return InverseProjectUVZ(uv, depth, a_eyeIndex).x;
	return GetScreenDepth(depth, a_eyeIndex);
}



float3 InverseProjectUV(float2 uv, uint a_eyeIndex)
{
	float depth = GetDepth(uv, a_eyeIndex);
	// return depth;
    // return InverseProjectUVZ(uv, GetDepth(uv), a_eyeIndex);
    return InverseProjectUVZ(uv, depth, a_eyeIndex);
}

// float2 ViewToUV(float3 x, bool is_position, uint a_eyeIndex)
// {
//     float4 uv = mul(ProjMatrix[a_eyeIndex], float4(x, (float) is_position));
//     return (uv.xy / uv.w) * float2(0.5f, -0.5f) + 0.5f;
// }


float2 ViewToUV(float3 x, bool is_position = true, uint a_eyeIndex = 0)
{
	float4 newPosition = float4(x, (float)is_position);
	float4 uv = mul(ProjMatrix[a_eyeIndex], newPosition);
	// return (uv.xy / uv.w) * float2(1.0f, -0.5f) + 0.5f;
	// float2 uv2 = (uv.xy / uv.w) * float2(0.5f, -0.5f) + 0.5f;
	return (uv.xy / uv.w) * float2(0.5f, -0.5f) + 0.5f;
}