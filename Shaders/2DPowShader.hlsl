//shader limpio solo hace transiciones basicas
//#include "Common.hlsl"
struct LIGHT
{
	uint4		LightTypeAndSwitches;

	float4		vPosition,
		vDirection,
		vDiffuse,
		vSpecular,
		vAmbient,
		vAttenuation,
		LightPowerAndRange;
};

struct MATERIAL
{
	float4   vDiffuse;        /* Diffuse color RGBA */
	float4   vAmbient;        /* Ambient color RGB */
	float4   vSpecular;       /* Specular 'shininess' */
	float4   vEmissive;       /* Emissive color RGB */
	float      fPower;
};

cbuffer Params
{
	matrix				mWorld,
		mView,
		mProj,
		mWV,
		mWVP;
	float4				vAmbientLight;
	LIGHT				Lights[8];
	float4				vTime;
	float4 vIriPowerOffset;
	float4 vActiveLights;
	float4 vXPosYPosInTexture;
	float4	vFlagsForGFX_SSPower;
	MATERIAL			Material;
}

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

Texture2D<float4>	Texture:		register	(t0);
Texture2D<float4>	IriTex:			register	(t1);
Texture2D<float4>	OtherTex:		register	(t2);

SamplerState		Sampler:		register	(s0);
SamplerState		IriSamp:		register	(s1);
SamplerState		OtherSamp:		register	(s2);


float ILambert(float4 N,float4 L)
{
	return max(0,-dot(N,L));
}

float4 LightingDiffuseDirectional(float4 N,float4 L,float4 ColorDiffuse)
{
	return ILambert(N,L)*ColorDiffuse;
} 

float4 LightingSpecularDirectional(float PowerSpecular,float4 V,float4 N,float4 L,float4 ColorSpecular)
{	
	float4 H=normalize(V-L);
		return  pow(max(0,dot(N,H)),PowerSpecular)*ColorSpecular;
}


PS_INPUT VSMain(VS_INPUT Input)
{
	float4 N,P,Q,L,H,V,No;//Normal, LightPosition,VertexPosition,LightDirection,Halfway,View 
	float4 vColor;
	static float time = 0;
	vColor =	Material.vEmissive;
	vColor +=	Material.vAmbient*vAmbientLight;
	No	=	normalize(Input.Normal);
	N	=	normalize(mul(Input.Normal,mWV));
	Q	=	mul(Input.Position,mWV);
	V	=	float4(0,0,0,1) - Q;

	for(int i=0;i<8;i++)
	{
		if(Lights[i].LightTypeAndSwitches.y & 0x1)
		{
			L	=	mul(Lights[i].vDirection,mView);
			vColor += Lights[i].vAmbient	*	Material.vAmbient;
		}
	}

	PS_INPUT Output;
	Output.Position		=	mul(Input.Position,mWVP);
	Output.Normal		=	N;
	Output.Color		=	vColor;
	Output.TexCoord		=	Input.TexCoord;

	return Output;
};


float4 PSMain(PS_INPUT Input):SV_Target
{
	//crar nuevo vector con las texturas y modificarlas

	float4	N	=	normalize(Input.Normal);

	float2	textnewCord;
	float4 vColor= (Texture.Sample(Sampler,Input.TexCoord)) * Input.Color;
	return vColor;

	if(3==vTime.z)
	{
		if(vTime.y >0)
		{
			textnewCord = float2((Input.TexCoord.x*-0.5)+abs(sin(vTime.x))/2,abs(sin(Input.TexCoord.y+(sin(vTime.x)*0.1))));
		}else
		{
			textnewCord = float2((Input.TexCoord.x*0.5)+abs(sin(vTime.x))/2,abs(sin(Input.TexCoord.y+(sin(vTime.x)*0.1))));
		}
		vColor = Input.Color*(Texture.Sample(Sampler,textnewCord));
	}

		float4	V	=	float4(0,0,0,1) - mul(Input.Position,mWV);
		float4  Q	=	mul(Input.Position,mWV);
		float4	L	,P	,H	,Ls;
	for(int i=0;i<8;i++)
	{
		if(Lights[i].LightTypeAndSwitches.y & 0x1)
		{
			L		=	mul(Lights[i].vDirection,mView);
			switch(Lights[i].LightTypeAndSwitches.x)
			{
			case 0://Directional
				{
					//Diffusa
					vColor	+=	LightingDiffuseDirectional(N,L,Lights[i].vDiffuse)*Material.vDiffuse;
					//Especular
					vColor	+=	LightingSpecularDirectional(Material.fPower,V,N,L,Lights[i].vSpecular)*Material.vSpecular;
				}
				break;
			default:
				{
					float d = dot(L,L);
					float fAttenuation=1/dot(Lights[i].vAttenuation, float4(1,d,d*d,0));
					vColor	+=	fAttenuation * LightingDiffuseDirectional(N,L,Lights[i].vDiffuse)*Material.vDiffuse;

					L		=	normalize(mul(Input.Position,mWV)-mul (Lights[i].vPosition, mView));
					vColor	+=	LightingSpecularDirectional(Material.fPower,V,N,L,Lights[i].vSpecular)*Material.vSpecular;

				}break;
			}
		}
	}

	if(3==vTime.z)
	{
		float offset = dot(float4(0,0.5,0,0),N)*abs(sin(vTime.x));
		float4 vIridescent = IriTex.Sample(IriSamp, float2(offset, 0));
		vColor += vColor*(offset+vIridescent);
		vColor.a *= IriTex.Sample(IriSamp, Input.TexCoord);
	}else if(1==vTime.z)
	{
		float offset = dot(float4(-0.20,-0.20,0,0),N)*abs(sin(vTime.x));
		float4 vIridescent = IriTex.Sample(IriSamp, float2(offset, 0));
		vColor += vColor*(offset+vIridescent);
		vColor.a *= IriTex.Sample(IriSamp, Input.TexCoord);
	}else
	{
		float offset = dot(float4(-0.20,-0.20,1,0),N)*abs(sin(vTime.x));
		float4 vIridescent = IriTex.Sample(IriSamp, float2(offset, 0));
		vColor += vColor*(offset+vIridescent);
		vColor.a *= IriTex.Sample(IriSamp, Input.TexCoord);
	}
	


	return vColor;
};