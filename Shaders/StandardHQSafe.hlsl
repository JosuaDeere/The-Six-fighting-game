#include "Common.hlsl"
//struct LIGHT
//{
//	uint4  LightTypeAndSwitches;
//	float4 vPosition;
//	float4 vDirection;
//	float4 vDiffuse;
//	float4 vSpecular;
//	float4 vAmbient;
//	float4 vAttenuation;	
//	float4 LightPowerAndRange;
//};
//
//struct MATERIAL
//{
//	float4 vDiffuse;        /* Diffuse color RGBA */
//	float4 vAmbient;        /* Ambient color RGB */
//	float4 vSpecular;       /* Specular 'shininess' */
//	float4 vEmissive;       /* Emissive color RGB */
//	float  fPower;
//};

cbuffer Params
{
	matrix mWorld;
	matrix mView;
	matrix mProj;
	matrix mWV;
	matrix mWVP;
	float4 vAmbientLight;
	LIGHT Lights[8];
	float4 vTime;
	float4 vIriPowerOffset;
	float4 vActiveLights;
	float4 vXPosYPosInTexture;
	float4	vFlagsForGFX_SSPower;
	MATERIAL Material;
};

struct VS_INPUT
{
	float4 Position:POSITION;
	float4 Normal:NORMAL;
	float2 TexCoord:TEXCOORD;
};

struct PS_INPUT
{
	float4 Position	:SV_POSITION;
	float4 Q		:POSITION;	
	float4 Normal	:NORMAL0;	
	float4 V		:NORMAL1;	
	float4 Diffuse	:COLOR;
	float2 TexCoord	:TEXCOORD;
};

Texture2D<float4> Texture	: register(T0);
Texture2D<float4> TIridicent: register(T1);
Texture2D<float4> TMapping	: register(T2);

SamplerState Sampler		: register(S0);
SamplerState SIridicent		: register(S1);
SamplerState SMapping		: register(S2);

PS_INPUT VSMain(VS_INPUT Input)
{
	//N=normalize(Input.Normal);
	//N=mul(N,mWV);
	
	float4 Q,L,LS,N,V,H,P,No;
	float4 vColor;	
	vColor=Material.vEmissive;
	vColor+=Material.vAmbient*vAmbientLight;	
	
	N = normalize( mul(Input.Normal, mWV) );	

	uint SizeX;
	uint SizeY;
	uint nLevels;
	Texture.GetDimensions(0,SizeX,SizeY,nLevels);
	No= normalize(Input.Normal);

	uint2 Coord=uint2(Input.TexCoord.x*SizeX+100*sin(vTime.x),Input.TexCoord.y*SizeY);
	float Deformation=length( float3(Texture[Coord].rgb) );
	//float4 Position=Input.Position+0.2*Texture[Coord];
	float4 Position=Input.Position+0.1*Deformation*No;
	//float4 Position=Input.Position;

	Position.w=1;
	Q = mul( Position, mWV );
	V = normalize( float4(0,0,0,1)-Q );	
	
	for( int i=0; i<8; i++ )
	{
		if( !Lights[i].LightTypeAndSwitches.y & 0x1) //Si está encendida
			continue;

		L = mul( Lights[i].vDirection, mView );
		vColor += Lights[i].vAmbient*Material.vAmbient;
		switch( Lights[i].LightTypeAndSwitches.x ) //LightType
		{
		case 0: //DIRECTIONAL
			{
				float ILambert=max( 0,-dot(N,L) );
				//Ambiental
				vColor += ILambert*Lights[i].vDiffuse*Material.vDiffuse;
			}
			break;
		case 1: //POINT
			{
				if( vActiveLights.x )
					break;
				P = mul( Lights[i].vPosition,mView );				
				float d = distance( Q, P );
				if(d>Lights[i].LightPowerAndRange.y)
					break;

				L = normalize ( Q-P );
				float ILambert = max( 0,-dot(N,L) );
				float fAttenuation = 1/dot( Lights[i].vAttenuation,float4(1,d,d*d,0) );
				//Difusse
				vColor+=ILambert*fAttenuation*Lights[i].vDiffuse*Material.vDiffuse;
			}
			break;
		case 2: //SPOT
			{
				if( vActiveLights.x )
					break;
				P	= mul ( Lights[i].vPosition,mView );
				LS	= mul ( Lights[i].vDirection,mView );
				float d = distance( Q, P );
				if(d>Lights[i].LightPowerAndRange.y)
					break;

				L = normalize ( Q-P );
				float ISpot = pow( max(0, dot(L, LS)),Lights[i].LightPowerAndRange.x);
				float ILambert = max( 0,-dot(N,L) );
				float fAttenuation = 1/dot( Lights[i].vAttenuation,float4(1,d,d*d,0) );
				//Difusse
				vColor+=ISpot*ILambert*fAttenuation*Lights[i].vDiffuse*Material.vDiffuse;
			}
			break;
		}
	}
	PS_INPUT Output;
	Output.Position = mul( Input.Position,mWVP ); //mul(Q,mProj)
	Output.Q=Q;
	Output.V=V;	
	//Output.Position = mul( Position,mWVP ); //mul(Q,mProj)
	
	//N=normalize(Input.Normal);
	//N=mul(N,mWV);
	Output.Normal = N;
	Output.Diffuse=vColor;
	Output.TexCoord=Input.TexCoord;
	return Output;
};

float4 PSMain(PS_INPUT Input):SV_Target
{		
	float4 vColor=Input.Diffuse;
	float4 vSpecular=Material.vSpecular;
	float4 N=normalize(Input.Normal);

	float4 Q,V;
	V = normalize(Input.V);
	Q = Input.Q;
	
		
	
	for( int i=0; i<8; i++ )
	{
		if( !Lights[i].LightTypeAndSwitches.y & 0x1) //Si está encendida
			continue;

		if( vActiveLights.y )
			break;

		float4 L = mul( Lights[i].vDirection, mView );
		
		float4 H = normalize(V-L);
		float ISpecular=pow( max(0, dot(H,N)), Material.fPower );
		vColor += (ISpecular*Lights[i].vSpecular*vSpecular);
		/*switch( Lights[i].LightTypeAndSwitches.x ) //LightType
		{
		case 1:
			break;
		case 2:
			break;
		}*/
	}
	
	if( !vActiveLights.w )
	{

		vColor*= TMapping.Sample( SMapping,((Input.TexCoord)/8)+vXPosYPosInTexture.zy);
	}

	if( vActiveLights.z )
	{
		if( !vIriPowerOffset.w )
		{
			float x = dot(float4(0, 0, -1, 0), N);
			float4 vIridescent = TIridicent.Sample(SIridicent, float2(x+vIriPowerOffset.y, 0) )*vIriPowerOffset.x;
			vColor *= x+vIridescent;
			return vColor;
		}
		else
		{
			float Threshold=-dot(Input.Normal, float4(0,0,1,0));	
			if( Threshold > vIriPowerOffset.z )
			{
				float x = dot(float4(0, 0, -1, 0), N);
				float4 vIridescent = TIridicent.Sample(SIridicent, float2(x+vIriPowerOffset.y, 0) )*vIriPowerOffset.x;
				vColor *= x+vIridescent;
				return vColor;
				/*float x = dot(float4(0, 0, -1, 0), N);
				float4 vIridescent = TIridicent.Sample(SIridicent, float2(x, 0) );
				vColor *= x+vIridescent;
				return vColor;*/
			}
			else
			{
				float2 Reflect=N.xy*0.5;
				Reflect.y*=-1;
				Reflect+=float2(0.5,0.5);
				return Texture.Sample(Sampler,Reflect)+Input.Diffuse;
			}
		}
	}
	
	return vColor;
	//return temp;
	//return vColor*( Texture.Sample(Sampler,Input.TexCoord) );
	//return vColor;
};