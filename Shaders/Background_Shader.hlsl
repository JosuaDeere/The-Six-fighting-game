struct MATERIAL
{
	float4	vDiffuse,        
			vAmbient,        
			vSpecular,       
			vEmissive; 
	float	fPower;

};

cbuffer Params
{
	matrix	mWV, 
			mWVP, 
			Trans;
	MATERIAL Material; 
};


struct VS_INPUT 
{
	float4 Position	: POSITION; 
	float4 Normal	: NORMAL0; 
	float2 TexCoord : TEXCOORD; 
 
};

struct PS_INPUT 
{
	float4 Position		: SV_POSITION; 
	float4 Normal		: NORMAL0; 
	float2 TexCoord		: TEXCOORD; 

};

Texture2D<float4> Texture	: register ( t0 ); 
Texture2D<float4> Bump		: register ( t1 ); 

SamplerState Sampler		: register ( s0 ); 
SamplerState SamplerBump	: register ( s1 ); 


/*float4 Specular_and_Diffuse_Gain ( float4 N, float4 Q, float4 V, float4 vTempColor, int it )
{
	float4 vColor = vTempColor; 

	float4	L		= mul ( Lights [ it ].vDirection, mView ), 
			P		= mul ( Lights [ it ].vPosition, mView ),
			H, Ls; 
	float	d				= distance ( Q, P ), 
			fAttenuation	= 1 / dot ( Lights [ it ].vAttenuation, 
										float4 ( 1, d, d * d, 0 ) ); 

	switch ( Lights [ it ].LightTypeAndSwitches.x ) //LightType  
	{
	case 0: //Directional
		{
			H = normalize ( V - L ); 
			float ISpecular = pow ( max ( 0, dot ( H, N ) ), Material.fPower ); 
			vColor += ISpecular * Lights [ it ].vSpecular * Material.vSpecular; 


			float ILambert = max ( 0, -dot ( N, L ) ); 
			////Diffuse
			vColor += ILambert * Lights [ it ].vDiffuse * Material.vDiffuse;
		
		}
		break;
	case 2:	//Puntual
	case 1: //Point 
		{
			if ( d > Lights [ it ].LightPowerAndRange.y )
				break; 

			float ISpot = 1.0f; 

			if ( Lights [ it ].LightTypeAndSwitches.x == 2 ) 
			{
				Ls	= mul ( Lights [ it ].vDirection,mView );
				ISpot = pow( max(0, dot( L, Ls ) ), Lights [ it ].LightPowerAndRange.x );
			}

			L = normalize ( Q - P );

			H = normalize ( V - L );
			float ISpecular = pow ( max ( 0, dot ( H, N )), Material.fPower );
			vColor += ISpot * ISpecular * fAttenuation * Lights [ it ].vSpecular * Material.vSpecular;

			float ILambert = max( 0, -dot( N, L ) );
			vColor += ISpot * ILambert * fAttenuation * Lights [ it ].vDiffuse * Material.vDiffuse;
		
		}
		break; 
	}

	return vColor; 
}*/

PS_INPUT VSMain ( VS_INPUT Input )
{
	float4	N = normalize ( mul ( Input.Normal, mWV ) );
	uint SizeX, SizeY, dLevels ; 

	Texture.GetDimensions ( 0, SizeX, SizeY, dLevels ); 
 
	uint2 Coord =	uint2( Input.TexCoord.x * 512, Input.TexCoord.y * 512 );
					float Deformation = length ( float3 ( Texture [ Coord ].rgb ) ); 
	float4	Position = mul ( Input.Position, Trans ) + 0 * Deformation * normalize ( Input.Normal );	
			Position.w = 1; 
	//Transformation; 
	//float4 vTangent = normalize ( mul ( Input.vTangent, mWV ) ); 
	//float4 vBinormal = normalize ( mul ( Input.vBinormal, mWV ) ); 

	PS_INPUT Output; 
	Output.Position	= mul ( Position, mWVP ); // mul ( Q, mProj )

	Output.Normal	= N;
	Output.TexCoord = Input.TexCoord; 
	
	return Output; 
}


float4 PSMain ( PS_INPUT Input ) : SV_TARGET
{
	float4	vColor = Texture.Sample ( Sampler, Input.TexCoord ); 

	//
	//float4 vNormalSample = Bump.Sample ( SamplerBump, Input.TexCoord ) * float4 ( 2,2,1,0) - float4 ( 1,1,0,0); 
	//float4 vNormal = float4 (	dot ( Input.A, vNormalSample), 
	//							dot ( Input.B, vNormalSample),
	//							dot ( Input.C, vNormalSample), 0 ); 
	//vNormal = vNormal + ( Input.Normal + vNormalSample.x * Input.A + vNormalSample.y * Input.B * 50 ); 

	return vColor; 
}
