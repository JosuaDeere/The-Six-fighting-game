//Defautl SHADER

cbuffer Params 
{
	float4 vColorBase; 
	matrix mTransform; //Nota: DX11 Multiplica vector matrix, suponiendo matriz transpuesta por cuestiones de eficiencia.
	
	matrix  m_mWorld, 
			m_mView,
			m_mProj,
			m_mWV,   
			m_mWVP;
	/*** Variables luces***/
	float4  vPosition[ 4 ],
			vDirection[ 4 ],
			vDiffuse[ 4 ],
			vSpecular[ 4 ],
			vAmbient[ 4 ],
			vAttenuation[ 4 ];

	float4	fTLuces[ 4 ];
}; 

struct VS_INPUT
{
	float4 Pos : POSITION;
	float4 Nor : NORMAL;
	float2 Tex : TEXCOORD;
};

struct PS_INPUT
{
	float4 Pos: SV_Position; 
	float4 Col: COLOR;
	float2 Tex: TEXCOORD;
};

PS_INPUT VSMain(VS_INPUT Input)
{
	PS_INPUT Output;
	//float4 vN,vP,vQ,vL,vH,vV; //Normal, LightPosition,VertexPosition,LightDirection,Halfway,View
	
	float4	vNormal={0.0f, 0.0f, 0.0f, 1.0f},
			vLightPos={0.0f, 0.0f, 0.0f, 1.0f},
			vVertexPos={0.0f, 0.0f, 0.0f, 1.0f},
			vLightDir={0.0f, 0.0f, 0.0f, 1.0f},
			vHalfway={0.0f, 0.0f, 0.0f, 1.0f},
			vView={0.0f, 0.0f, 0.0f, 1.0f};

	float fILambert=0,fISpecular=0; //Factores de atenuación de iluminación
	vNormal= mul(Input.Nor, m_mWV); //Normal a Espacio de Vista
	vVertexPos= mul(Input.Pos, m_mWV); //Vertice a Espacio de Vista
	//vV= 0;
	vView= vView-vVertexPos;
	vView= normalize(vView);
	float4  vColorDiffuse, vColorSpecular;
	float4 vColor={1.0f, 0.1f, 0.1f, 1.0f};
	//float4 vColor={0.64f, 0.4f, 0.36f, 1.0f};

	for(float i=0.0f; i< 1.0f; i+=1.0f)
	{			

		vLightPos= mul(vPosition[i], m_mView);
		vLightDir= vVertexPos- vLightPos;

		float d=dot(vLightDir,vLightDir);
		d=sqrt(d);

		if( d>fTLuces[i].x)
			continue;

		vLightDir=mul(vLightDir, 1.0f/d);			
		float4 DistanceFactors={1,d,mul(d,d),0};
		float fAttenuation=(1.0f/ (dot(DistanceFactors,vAttenuation[i])));

		float4 vAtenuationCo	= { 1.0f, 1.0f, 1.0f, 0.0f };
		vAtenuationCo			= mul ( vDirection [i], m_mView);
		float fSpotAttenuation	= pow ( max ( 0, dot ( vLightDir, vAtenuationCo)), fTLuces[i].y);
		fAttenuation			= mul ( fAttenuation, fSpotAttenuation );
		
		if(fTLuces[i].z !=1.0f)
		{					
			fILambert=max(0,-dot(vNormal,vLightDir));
			float4			MaterialvDiffuse = {0.0f, 0.0f, 0.0f, 1.0f};
			vColorDiffuse=mul(vDiffuse[i],MaterialvDiffuse);
			vColorDiffuse= mul(vColorDiffuse,mul(fILambert, fAttenuation));				
			vColor = vColor + vColorDiffuse;
		}
		if(fTLuces[i].w !=1.0f)
		{				
			vHalfway= vView- vLightDir;
			vHalfway= normalize(vHalfway);
			float MaterialfPower=10.0f;
			float4 MaterialvSpecular={ 0.0f, 0.2f, 1.0f, 1.0f};
			fISpecular= pow(max(0,dot(vHalfway, vNormal)), MaterialfPower);
			vColorSpecular= mul(vSpecular[i], MaterialvSpecular);
			vColorSpecular= mul(vColorSpecular, mul(fISpecular,fAttenuation) );
			vColor= vColor + vColorSpecular;				
		}

	}				

	Output.Pos = mul( Input.Pos, m_mWVP);
	//Output.Col = vColor + vColorBase + cos ( 3.141592 * 180 / 180 );
	Output.Col = vColor + cos ( 3.141592 * 180 / 180 );
	//Output.Col = vColor + vColorBase;
	Output.Tex = Input.Tex + sin(3.1415) ;
	return Output;
}


float4 PSMain ( PS_INPUT Input ) : SV_Target
{
	return Input.Col;
}
