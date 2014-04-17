// SSAO Technique by ArKano22 of gamedev.net
// posted here: http://www.gamedev.net/community/forums/topic.asp?topic_id=556187&PageSize=25&WhichPage=1
// vvvv adaption by m4d

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;
float4x4 tWV: WORLDVIEW;

//texture
Texture2D tex <string uiname="Texture";>;

SamplerState dfs
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

//texture transformation marked with semantic TEXTUREMATRIX to achieve symmetric transformations
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 position  : POSITION;
    float2 uv : TEXCOORD0;
    float3 camera_position : TEXCOORD1;
    float3 camera_normal   : TEXCOORD2;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
vs2ps VS(
    float4 PosO  : POSITION,
    float3 normal : NORMAL0,
    float4 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position
    Out.position = mul(PosO, tWVP);
    
    //transform texturecoordinates
    Out.uv = TexCd;
    
    Out.camera_position = mul(PosO, tWV);

    Out.camera_normal = mul(normal, tWV);
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

struct col2
{
    float4 c1 : COLOR0;
    float4 c2 : COLOR1;
    float4 c3 : COLOR2;
};

col2 PS(vs2ps In)
{
    col2 c;

    c.c3.rgba = 1.0;

    float depth = length(In.camera_position.xyz);
    float3 norm = normalize(In.camera_normal);
    norm.z *= 1.0;
    c.c1 = float4(norm * 0.5f + 0.5f, depth);

    c.c2.xyz = In.camera_position;
    c.c2.w   = 1.0f;

    c.c3.rgb = tex.Sample(dfs, In.uv).rgb;

    return 1.0;
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSimpleShader
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_4_0 VS();
        PixelShader  = compile ps_4_0 PS();
    }
}
