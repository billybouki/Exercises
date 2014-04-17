float4x4 tW : WORLD;
float4x4 tVP : VIEWPROJECTION;

float Alpha <float uimin=0.0; float uimax=1.0;> = 1;
////Noise///////////////////
int iqIcoolfFunc3d2( in int n )
{
    n=(n<<13)^n;
    return (n*(n*n*15731+789221)+1376312589) & 0x7fffffff;
}

float iqCoolfFunc3d2( in int n )
{
    return float(iqIcoolfFunc3d2(n));
}

float n3f( in float3 p )
{
    int3 ip = int3(floor(p));
    float3 u = frac(p);
    u = u*u*(3.0-2.0*u);

    int n = ip.x + ip.y*57 + ip.z*113;

    float res = lerp(lerp(lerp(iqCoolfFunc3d2(n+(0+57*0+113*0)),
                            iqCoolfFunc3d2(n+(1+57*0+113*0)),u.x),
                        lerp(iqCoolfFunc3d2(n+(0+57*1+113*0)),
                            iqCoolfFunc3d2(n+(1+57*1+113*0)),u.x),u.y),
                    lerp(lerp(iqCoolfFunc3d2(n+(0+57*0+113*1)),
                            iqCoolfFunc3d2(n+(1+57*0+113*1)),u.x),
                        lerp(iqCoolfFunc3d2(n+(0+57*1+113*1)),
                            iqCoolfFunc3d2(n+(1+57*1+113*1)),u.x),u.y),u.z);

    return 1.0 - res*(1.0/1073741824.0);
}

struct vsin
{
	float4 pos : POSITION;
	float4 uv : TEXCOORD0;
};

struct vs2gs
{
    float4 pos : POSITION;
	float4 uv : TEXCOORD0;
};

struct gs2ps
{
    float4 pos: SV_POSITION;
    float4 color: COLOR0;
	float4 uv : TEXCOORD0;
};

vs2gs VS(vsin input)
{
	vs2gs output;
	output.pos = mul(input.pos,tW);
	output.uv = input.uv;

    return output;
}

float eps : EPSILON = 0.000001f;

[maxvertexcount(3)]
void GS(triangle vs2gs input[3], inout TriangleStream<gs2ps> gsout)
{
	gs2ps o;
	
	float3 f1 = input[1].pos.xyz - input[0].pos.xyz;
    float3 f2 = input[2].pos.xyz - input[0].pos.xyz;
    
	float3 norm = normalize(cross(f2, f1));
	
	float3 noise = float3(n3f((input[1].pos.xyz*10)+Alpha),n3f((input[0].pos.xyz+Alpha)*20),n3f(((f1+Alpha))*13.0)) * 3;
	o.color = float4(noise,1);

	
	o.pos = mul(input[0].pos,tVP);
	o.uv = input[0].uv;
	gsout.Append(o);
	
	o.pos = mul(input[1].pos,tVP);
	o.uv = input[1].uv;
	gsout.Append(o);
	
	o.pos = mul(input[2].pos,tVP);
	o.uv = input[2].uv;
	gsout.Append(o);
}

float4 PS(gs2ps input): SV_Target
{
    return float4(input.color.xyz*0.5+0.5,1);
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





