//@author: vux
//@help: template for standard shaders
//@tags: template
//@credits: 

Texture2D texture2d <string uiname="Texture";>;

SamplerState linearSampler 
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;
float4x4 tVP: VIEWPROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;
float4x4 tWV: WORLDVIEW;

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;
	float3 norm : NORMAL;

};

struct vs2ps
{
   float4 PosWVP : SV_POSITION;
   float2 uv : TEXCOORD0;
   float3 camera_position : TEXCOORD1;
   float3 camera_normal   : TEXCOORD2;
};

vs2ps VS(VS_IN input)
{
    vs2ps output = (vs2ps) 0;
    output.PosWVP  = mul(input.PosO,mul(tW,tVP));
    output.uv = input.TexCd.xy;
	output.camera_position = mul(input.PosO, tWV).xyz;
	output.camera_normal = mul(float4(input.norm,1.0), tWV).xyz;
    return output;
}

struct col2
{
    float4 c1 : COLOR0;
    float4 c2 : COLOR1;
    float4 c3 : COLOR2;
};

float4 PS(vs2ps In): SV_Target
{
    col2 c;
	

    c.c3.rgba = 1.0;

    float depth = length(In.camera_position.xyz);
    float3 norm = normalize(In.camera_normal);
    norm.z *= 1.0;
    c.c1 = float4(norm * 0.5f + 0.5f, depth);

    c.c2.xyz = In.camera_position;
    c.c2.w   = 1.0f;

    c.c3.rgb = texture2d.Sample(linearSampler, In.uv).rgb;

    return float4(c.c1.xy,0.0,c.c1.w);//float4(c.x,c.y,c.z,1.0);
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




