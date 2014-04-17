//@author: colorsound
//@help: 
//@tags:
//@credits: www.rastertek.com

Texture2D depthMapTexture <string uiname="depthMapTexture";>;

SamplerState SamClamp 
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

SamplerState SamWrap 
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};
 
    float4x4 tW : WORLD;
	float4x4 tVP : VIEWPROJECTION;
    float4x4 tV : VIEW;
	float4x4 tWVP: WORLDVIEWPROJECTION;
 
	float4 ambientColor <bool color=true;String uiname="ambientColor";> = { 0.15f, 0.15f, 0.15f, 1.0f };
    float4 diffuseColor <bool color=true;String uiname="diffuseColor";> = { 1.0f, 1.0f, 1.0f, 1.0f };

    matrix lightViewMatrix;
    matrix lightProjectionMatrix;

    float3 lightPosition;

	float bias = 0.001f;

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
    float3 lightPos          : TEXCOORD2;
};



// Vertex Shader
////////////////////////////////////////////////////////////////////////////////



PixelInputType MultiShadow_VS(VertexInputType input)
{
    PixelInputType output;
	
	float4 worldPosition;

 // Change the position vector to be 4 units for proper matrix calculations.
    input.position.w = 1.0f;
	
    output.position = mul(input.position,tWVP);
   
	// Store the texture coordinates for the pixel shader.
	output.uv = input.uv;
  
	// Calculate the normal vector against the world matrix only.
    output.normal = normalize(mul(input.normal,(float3x3)tW));

    // Calculate the position of the vertice as viewed by the light source.
    output.lightViewPosition = mul(input.position,tW);
    output.lightViewPosition = mul(output.lightViewPosition, lightViewMatrix);
    output.lightViewPosition = mul(output.lightViewPosition, lightProjectionMatrix);

	 // Calculate the position of the vertex in the world.
    worldPosition = mul(input.position, tW);
	
    // Determine the light position based on the position of the light and the position of the vertex in the world.
    output.lightPos = normalize(lightPosition.xyz - worldPosition.xyz);

    return output;
}

float shadow( float4 lightViewPosition){
	float sha = 0;
    float2 projectTexCoord;

	 // Calculate the projected texture coordinates.
    projectTexCoord.x =  lightViewPosition.x / lightViewPosition.w / 2.0f + 0.5f;
    projectTexCoord.y = -lightViewPosition.y / lightViewPosition.w / 2.0f + 0.5f;

    // Determine if the projected coordinates are in the 0 to 1 range.  If so then this pixel is in the view of the light.
    if((saturate(projectTexCoord.x) == projectTexCoord.x) && (saturate(projectTexCoord.y) == projectTexCoord.y))
    {
        float depthValue = depthMapTexture.Sample(SamClamp, projectTexCoord).r;
        float lightDepthValue = (lightViewPosition.z / lightViewPosition.w) - bias;     
        if(lightDepthValue < depthValue)
        {sha = 1;} 
    	else {sha = 0;}
    }
    return saturate(sha);
}

//Pixel Shader
////////////////////////////////////////////////////////////////////////////////
float4 MultiShadow_PS(PixelInputType input) : SV_TARGET
{
    float sha = shadow(input.lightViewPosition);
    float2 projectTexCoord;
	
	/*
	 // Calculate the projected texture coordinates.
    projectTexCoord.x =  input.lightViewPosition.x / input.lightViewPosition.w / 2.0f + 0.5f;
    projectTexCoord.y = -input.lightViewPosition.y / input.lightViewPosition.w / 2.0f + 0.5f;

    // Determine if the projected coordinates are in the 0 to 1 range.  If so then this pixel is in the view of the light.
    if((saturate(projectTexCoord.x) == projectTexCoord.x) && (saturate(projectTexCoord.y) == projectTexCoord.y))
    {
        float depthValue = depthMapTexture.Sample(SamClamp, projectTexCoord).r;
        float lightDepthValue = (input.lightViewPosition.z / input.lightViewPosition.w) - bias;     
        if(lightDepthValue < depthValue)
        {sha = 1;} 
    	else {sha = 0;}
    }*/
    return sha;
}





technique10 MultiShadow
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, MultiShadow_VS() ) );
		SetPixelShader( CompileShader( ps_4_0, MultiShadow_PS() ) );
	}
}