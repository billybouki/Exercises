//@author: vux
//@help: template for standard shaders
//@tags: template
//@credits: 

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;

Texture2D texNorm <string uiname="Texturenorm";>;

SamplerState SampleNorm 
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Wrap;
    AddressV = Wrap;
};


Texture2D TexPos <string uiname="TexturePoint";>;

SamplerState SamplePos 
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Wrap;
    AddressV = Wrap;
};

//parameters
float SampleRadius <string uiname="Sample Radius";> = 1.5;
float Intensity <string uiname="Intensity";> = 0.75;
float Scale <string uiname="Scale";> = 0.75;
float Bias <string uiname="Bias";> = 0.75;
float SelfOcclusion <string uiname="Self Occlusion";> = 0.75;
float2 ScreenSize <string uiname="Screen Size";> = 1;
float2 InvScreenSize <string uiname="Inverse Screen Size";> = 1;


struct vs2ps
{
    float4 position: SV_POSITION;
    float2 uv: TEXCOORD0;
};

vs2ps VS(
    float4 position  : POSITION
    )
{
    //declare output struct
    vs2ps Out;

    //transform position
    Out.position = float4(sign(position.xy), 0.0f, 1.0f);

    //transform texturecoordinates
    Out.uv = position.xy * float2(1,-1) + 0.5f;

    Out.position.x -= InvScreenSize.x;
    Out.position.y += InvScreenSize.y;

    return Out;
}


float3 getPosition(in float2 uv)
{
  return TexPos.SampleLevel(SamplePos,float4(uv,0,0),1.0).xyz;
}
float3 getNormal(in float2 uv)
{
  return normalize(texNorm.Sample(SampleNorm, uv).xyz * 2.0f - 1.0f);
}

float getRandom(in float2 uv)
{
  return ((frac(uv.x * (ScreenSize.x/2.0))*0.25)+(frac(uv.y*(ScreenSize.y/2.0))*0.5));
}

float doAmbientOcclusion(in float2 tcoord,in float2 uv, in float3 p, in float3 cnorm)
{
  float3 diff = getPosition(tcoord + uv) - p;
  const float3 v = normalize(diff);
  const float  d = length(diff)*Scale;
  return max(0.0-SelfOcclusion,dot(cnorm,v)-Bias)*(1.0/(1.0+d*d))*Intensity;
}


float4 PS(vs2ps In): SV_Target
{
      const float3 vec[14] = {float3(1,1,-1),float3(1,-1,-1),
                         float3(1,1,1),float3(1,-1,1),
                         float3(-1,1,-1),float3(-1,-1,-1),
                         float3(-1,1,1),float3(-1,-1,1),

                         float3(1,0,0),float3(-1,0,0),
                         float3(0,1,0),float3(0,-1,0),
                         float3(0,0,1),float3(0,0,-1),
                       };

  float4 o = float4(0.0,0.0,0.0,1.0);
  float3 p = getPosition(In.uv);
  float3 n = getNormal(In.uv);
  float rand = getRandom(In.uv);

  float ao = 0.0;
  float rad = SampleRadius/p.z;
  //**SSAO Calculation**//

  for (int j = 0; j < 14; ++j)
  {
    float4 coord = mul(float4(vec[j]*rad*rand,1.0),tWVP);
    coord.y = ScreenSize.y-coord.y;
    ao += doAmbientOcclusion(In.uv,coord*InvScreenSize*1000.0, p, n );
  }
  ao/=8;
  ao+=SelfOcclusion;

  o.rgb = ao;
  //**END**//
  return o;
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




