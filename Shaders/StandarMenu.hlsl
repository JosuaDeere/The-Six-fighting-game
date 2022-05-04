cbuffer PARAMS
{
	matrix mWorld;
	matrix mView;
	matrix mProj;
	matrix mWV;
	matrix mWVP;	
};


struct VS_INPUT
{
	float4 Position:POSITION;
	float2 TexCoord:TEXCOORD;
};

struct PS_INPUT
{
	float4 Position	:SV_POSITION;
	float2 TexCoord	:TEXCOORD;
};


PS_INPUT VSMain(VS_INPUT Input)
{
	PS_INPUT Output;

	
	Output.TexCoord=Input.TexCoord;
	Output.Position= mul( Input.Position,mWVP );

	return Output;

};


Texture2D<float4> Texture	: register(t0);
SamplerState Sampler		: register(s0);


float4 PSMain(PS_INPUT Input):SV_TARGET
{
	float4 vcolor = Texture.Sample ( Sampler, Input.TexCoord ); 
	return vcolor;
};