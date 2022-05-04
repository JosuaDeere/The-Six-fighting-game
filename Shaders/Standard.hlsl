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
	float4 Position:SV_POSITION;
	float4 Normal:NORMAL;
	float4 Color:COLOR;
	float2 TexCoord:TEXCOORD;
};

Texture2D<float4> Texture	: register(T0);
Texture2D<float4> TIridicent: register(T1);
SamplerState Sampler		: register(S0);
SamplerState SIridicent		: register(S1);


PS_INPUT VSMain(VS_INPUT Input)
{
	float4 Q,L,LS,N,V,H,P,No;
	float4 vColor;
	vColor=Material.vEmissive;
	vColor+=Material.vAmbient*vAmbientLight;
	
	N = normalize( mul(Input.Normal, mWV) );
	//Q = mul( Input.Position, mWV );
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
				//Specular
				H = normalize(V-L);
				float ISpecular=pow( max(0, dot(H,N)), Material.fPower );
				vColor += ISpecular*Lights[i].vSpecular*Material.vSpecular;
			}
			break;
		case 1: //POINT
			{
				P = mul( Lights[i].vPosition,mView );				
				float d = distance( Q, P );
				if(d>Lights[i].LightPowerAndRange.y)
					break;

				L = normalize ( Q-P );
				float ILambert = max( 0,-dot(N,L) );
				float fAttenuation = 1/dot( Lights[i].vAttenuation,float4(1,d,d*d,0) );
				//Difusse
				vColor+=ILambert*fAttenuation*Lights[i].vDiffuse*Material.vDiffuse;
				//Specular
				H = normalize(V-L);
				float ISpecular=pow( max(0, dot(H,N)), Material.fPower );
				vColor+=ISpecular*fAttenuation*Lights[i].vSpecular*Material.vSpecular;
			}
			break;
		case 2: //SPOT
			{
				P = mul ( Lights[i].vPosition,mView );	
				LS = mul( Lights[i].vDirection,mView );
				float d = distance( Q, P );
				if(d>Lights[i].LightPowerAndRange.y)
					break;

				L = normalize ( Q-P );
				float ISpot = pow( max(0, dot(L, LS)),Lights[i].LightPowerAndRange.x);
				float ILambert = max( 0,-dot(N,L) );
				float fAttenuation = 1/dot( Lights[i].vAttenuation,float4(1,d,d*d,0) );
				//Difusse
				vColor+=ISpot*ILambert*fAttenuation*Lights[i].vDiffuse*Material.vDiffuse;
				//Specular
				H = normalize(V-L);
				float ISpecular=pow( max(0, dot(H,N)), Material.fPower );
				vColor+=ISpot*ISpecular*fAttenuation*Lights[i].vSpecular*Material.vSpecular;

			}
			break;
		}

	}
	PS_INPUT Output;
	Output.Position = mul( Input.Position,mWVP ); //mul(Q,mProj)
	//Output.Position = mul( Position,mWVP ); //mul(Q,mProj)
	Output.Normal = N;
	Output.Color=vColor;
	Output.TexCoord=Input.TexCoord;
	return Output;
};

float4 PSMain(PS_INPUT Input):SV_Target
{
	return Input.Color*( TIridicent.Sample(SIridicent,Input.TexCoord) );
	//return Input.Color;
};