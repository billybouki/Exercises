//@author: bouksi
//@help: 
//@tags:
//@credits: www.rastertek.com

Texture2D depthMapTexture <string uiname="depthMapTexture";>;

float strength = 0.125;
 float2 offset  = float2( 1920.0 / 4.0, 1080.0 / 4.0 );
 float falloff  = 0.0000002;
 float rad = 0.006;
 float invSamples = 1.0;
/*
#define NUM_SAMPLES	10

// AO sampling directions 
static const float3 AO_SAMPLES[ NUM_SAMPLES ] = 
{
    float3(-0.010735935,  0.0164701800,  0.0062425877),
    float3(-0.065333690,  0.3647007000, -0.1374632100),
    float3(-0.653923500, -0.0167263880, -0.5300095700),
    float3( 0.409582850,  0.0052428036, -0.5591124000),
    float3(-0.146536600,  0.0989926700,  0.1557167900),
    float3(-0.441221120, -0.5458797000,  0.0491253200),
    float3( 0.037555660, -0.1096134500, -0.3304027300),
    float3( 0.019100213,  0.2965278300,  0.0662376660),
    float3( 0.876532300,  0.0112360040,  0.2826596200),
    float3( 0.292644350, -0.4079423800,  0.1596416700)
};*/
// Textures.
//
int NUM_SAMPLES = 20;

float3 AO_SAMPLES[20];


Texture2D tex0;    // Normal.xyz, z/w
Texture2D tex1;    // Random noise texture

SamplerState defss0 : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

SamplerState defss1 : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Wrap;
    AddressV = Wrap;
};
 
    float4x4 tW : WORLD;
	float4x4 tVP : VIEWPROJECTION;
    float4x4 tV : VIEW;
	float4x4 tWVP: WORLDVIEWPROJECTION;


struct VertexInputType //VS_IN
{
    float4 position : POSITION;
    float2 uv    : TEXCOORD0;
	float3 normal : NORMAL;
};


struct PixelInputType // vs2ps
{
    float4 position          : SV_POSITION;
    float2 uv                : TEXCOORD0;
	float3 normal            : NORMAL;
    float4 lightViewPosition : TEXCOORD1;
    
};

// Vertex Shader
////////////////////////////////////////////////////////////////////////////////
PixelInputType MultiShadow_VS(VertexInputType input)
{
    PixelInputType output;
	
	float4 worldPosition;
 // Change the position vector to be 4 units for proper matrix calculations.
    input.position.w = 1.0f;
	worldPosition = mul(input.position, tW);
    
	output.position = mul(input.position,tWVP);
	output.uv = input.uv;
    output.normal = normalize(mul(input.normal,(float3x3)tW));
   

    return output;
}



//Pixel Shader
////////////////////////////////////////////////////////////////////////////////
float4 MultiShadow_PS(PixelInputType input) : SV_TARGET
{
	float2 uv = input.uv;
    float4 col = float4 (0.5,0.3,0.5,1.0);//shadow(input.lightViewPosition);
	
	float3 fres = normalize( tex1.Sample( defss1, uv * offset ).xyz * 2.0 - 1.0 );
    float4 normal_depth = tex0.Sample( defss0, uv );

    float3 normal = normal_depth.xyz;
    float  depth  = normal_depth.w;

    float3 ep = float3( uv, depth );
    float bl = 0.0;
    float radD = rad / depth;

    float3 ray;
    float4 occFrag;
    float  depthDiff;

    for( int i = 0; i < NUM_SAMPLES; ++i )
    {
        ray = radD * reflect( AO_SAMPLES[i], fres );
        occFrag = tex0.Sample(defss0, ep.xy + sign(dot(ray, normal)) * ray.xy);

        depthDiff = depth - occFrag.a;

        bl += step( falloff, depthDiff ) * (1.0 - dot( occFrag.xyz, normal )) * 
              (1.0 - smoothstep( falloff, strength, depthDiff ));
    }

    float ao = 1.0 - bl * invSamples;
	
    return ao;
}





technique10 MultiShadow
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, MultiShadow_VS() ) );
		SetPixelShader( CompileShader( ps_4_0, MultiShadow_PS() ) );
	}
}