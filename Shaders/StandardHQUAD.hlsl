#include "Common.hlsl"

//Esta clase funciona similar a BasiFrameMerger, pues se utilizar� para los men�s y cosas similares
//Que no tendr�n un movimiento de c�mara ni nada similar

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
	float4 Color=TexInput.Sample(Sampler,Input.TexCoord);

	return Color;//Solo sacar el color

	/*float4 BW;
	BW.rgb=sqrt(dot(Color.rgb,Color.rgb)*0.33333f)*vColorMask.rgb;
	float4 Blend=Color*(1-vMergeFactors.x)+BW*vMergeFactors.x;
	Blend*=vColorFactor;
	Blend+=vColorOffset;
	Blend.a=vMergeFactors.y;
	return Blend;*/
}