
/*
	Mezclador de marcos de salida.
	Permite aplicar un terminado básico a un trazo
	de entrada. 
*/

cbuffer PARAMS
{	
	float4 vMergeFactors; 
	float4 vColorMask;
	float4 vColorFactor;
	float4 vColorOffset;
	float4 vEffectParameters;
};

struct VS_INPUT
{
	float4 Pos:POSITION;
	float2 TexCoord:TEXCOORD;
};
struct PS_INPUT
{
	float4 Pos:SV_Position;
	float2 TexCoord:TEXCOORD;
};

PS_INPUT VSMain(VS_INPUT Input)
{
	PS_INPUT Output;
	Output.Pos=Input.Pos;
	Output.TexCoord=Input.TexCoord;
	return Output;
}
Texture2D<float4> TexInput:register(t0);
SamplerState Sampler:register(s0);

float4 PSMain(PS_INPUT Input):SV_Target
{	

	float4 Color= TexInput.Sample(Sampler,Input.TexCoord);

	int n = (int)(vEffectParameters.x*100);
	float fScaleFactor = vEffectParameters.y ;	

	for (int i = 0; i < n; i++)
	{
		Color += TexInput.Sample(Sampler,(Input.TexCoord*fScaleFactor)+((1.0f-fScaleFactor)*0.5f));
		fScaleFactor += vEffectParameters.z;		
	}		

	Color = Color*vEffectParameters.w;
	float4 BW;
	BW.rgb=sqrt(dot(Color.rgb,Color.rgb)*0.33333f)*vColorMask.rgb;
	float4 Blend=Color*(1-vMergeFactors.x)+BW*vMergeFactors.x;
	Blend*=vColorFactor;
	Blend+=vColorOffset;
	Blend.a=vMergeFactors.y;
	return Blend;
}