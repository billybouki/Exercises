
//This is the buffer from the renderer
//Renderer automatically assigns BACKBUFFER semantic

//RWStructuredBuffer<float4> rwbuffer : BACKBUFFER;
RWTexture2D<float4> Output : BACKBUFFER;
StructuredBuffer<float2> positions ;
StructuredBuffer<float2> positions2 ;

SamplerState mySampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

void Plot(int x, int y)
{
   Output[uint2(x, y)] = float4(1, 0, 1, 1);
}

void DrawLine(float2 start, float2 end)
{
    float dydx = (end.y - start.y) / (end.x - start.x);
    float y = start.y;
    for (int x = start.x; x <= end.x; x++) 
    {
        Plot(x, round(y));
        y = y + dydx;
    }
}


[numthreads(32, 1, 1)]
void CS( uint3 threadID : SV_DispatchThreadID)
{ 
	float2 pos = positions[threadID.x];
	float2 pos2 = positions2[threadID.x];
	//in the UAV, the color is just set based upon the thread ID.
	Output[threadID.xy] = float4( threadID.xy/512.0, 1.0 , 1.0);
	
	//if (threadID.x == 511 )
	//{
		DrawLine(pos*512,pos2*512);		
	//}
	
}

technique11 Process
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}







