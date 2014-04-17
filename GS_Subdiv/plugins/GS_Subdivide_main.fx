float4x4 tW : WORLD;
float4x4 tVP : VIEWPROJECTION;
float4x4 tWVP : WORLDVIEWPROJECTION;

float Alpha <float uimin=0.0; float uimax=1.0;> = 1;


struct vsin
{
	float4 pos : POSITION;
	float3 Norm : NORMAL;
	float4 uv : TEXCOORD0;
};

struct VertexOut
{
    float3 PosL : POSITION;
	float3 NormalL : NORMAL;
	float2 Tex : TEXCOORD0;
};

struct GeoOut
{
	float4 PosH : SV_POSITION;
	float3 PosW : POSITION;
	float3 NormalW : NORMAL;
	float2 Tex : TEXCOORD;
	float FogLerp : FOG;
};

void Subdivide(VertexOut inVerts[3], out VertexOut outVerts[6])
{
	
	VertexOut m[3];// =  (VertexOut)(0,0,0) ;
	//m[0] = (VertexOut)(0.0);
	//m[1] = (VertexOut)(0.0);
	//m[2] = (VertexOut)(0.0);
	
	//compute edge midpoints
	m[0].PosL = 0.5* ( inVerts[0].PosL + inVerts[1].PosL);
	m[1].PosL = 0.5* ( inVerts[1].PosL + inVerts[2].PosL);
	m[2].PosL = 0.5* ( inVerts[2].PosL + inVerts[0].PosL); 
	
	//project onto unit sphere//normalizemidpoints 
//m[0].PosL = normalize( m[0].PosL);
	//m[1].PosL = normalize( m[1].PosL);
	//m[2].PosL = normalize( m[2].PosL);
	
	//derive normals 
	m[0].NormalL = m[0].PosL;
	m[1].NormalL = m[1].PosL;
	m[2].NormalL = m[2].PosL;
	
	//interpolate texCd 
	m[0].Tex = 0.5 *( inVerts[0].Tex + inVerts[1].Tex );
	m[1].Tex = 0.5 *( inVerts[1].Tex + inVerts[2].Tex );
	m[2].Tex = 0.5 *( inVerts[2].Tex + inVerts[0].Tex );
	
	outVerts[0] = inVerts[0];
	outVerts[1] = m[0];
	outVerts[2] = m[2];
	outVerts[3] = m[1];
	outVerts[4] = inVerts[2];
	outVerts[5] = inVerts[1];
	
};

void OutputSubdivision( VertexOut v[6],inout TriangleStream<GeoOut>triStream )
{
	GeoOut gout[6];
	for(int y ; y < 5; y++)
	{
		gout[y] = (GeoOut)(0.0);
	}
	
	[unroll]
	for( int i =0; i< 6; i++)
	{
		//worldSpace
		gout[i].PosW = mul(float4(v[i].PosL, 1.0), tW).xyz;
		gout[i].NormalW = mul( v[i].NormalL , tW ).xyz;
		
		//HOMOgeneous ClipSpace
		gout[i].PosH = mul( float4(v[i].PosL,1.0) , tWVP);
		gout[i].Tex = v[i].Tex;
	}
	
	[unroll]
	for(int j = 0; j<5; ++j)
	{
		triStream.Append( gout[j] );
	}
	triStream.RestartStrip();
	
	//triStream.Append( gout[1] );
	//triStream.Append( gout[5] );
	//triStream.Append( gout[3] );
}

float eps : EPSILON = 0.000001f;

VertexOut VS(vsin input)
{
	VertexOut output;
	output.PosL = input.pos;
	output.Tex = input.uv;
	output.NormalL = input.Norm;

    return output;
}

[maxvertexcount(8)]
void GS( triangle VertexOut gin[3] , inout TriangleStream<GeoOut> triStream )
{
	VertexOut v[6];
	Subdivide(gin, v);
	OutputSubdivision(v, triStream);
}

float4 PS(GeoOut input): SV_Target
{
    return 1.0;//float4(input.color.xyz*0.5+0.5,1);
}

technique10 Render
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}





