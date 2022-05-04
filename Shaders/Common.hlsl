struct LIGHT
{
	uint4  LightTypeAndSwitches;
	float4 vPosition;
	float4 vDirection;
	float4 vDiffuse;
	float4 vSpecular;
	float4 vAmbient;
	float4 vAttenuation;	
	float4 LightPowerAndRange;
};

struct MATERIAL
{
	float4 vDiffuse;        /* Diffuse color RGBA */
	float4 vAmbient;        /* Ambient color RGB */
	float4 vSpecular;       /* Specular 'shininess' */
	float4 vEmissive;       /* Emissive color RGB */
	float  fPower;
};

cbuffer GenericParams:register(b1)
{
	matrix GenmWorld;
	matrix GenmView;
	matrix GenmProj;
	matrix GenmWV;
	matrix GenmWVP;
	//Nótese que ya no es necesario mandarlucesn mas que en la pelea
};

//normal, Q


//float4 () : SV_TARGET
//{
//	return float4(1.0f, 1.0f, 1.0f, 1.0f);
//}