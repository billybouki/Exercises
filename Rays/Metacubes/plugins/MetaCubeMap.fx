 #define EPSILON  0.001f

float4x4 tIVP : VIEWPROJECTIONINVERSE;


float3 light;
int ITERATIONS;

TextureCube tex <string uiname="Texture";>;

SamplerState linearSampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

float3 lightCol = float3 (1.0,0.5,0.5);
float3 lightCol2 = float3 (0.5,0.5,1.0);
float3 fillLightColour = float3(0.5,0.5,1.0);
float3 fillLightDir= float3(0.0,1.0,0.0);

struct vsInput
{
    float4 pos	: POSITION;
	uint iv : SV_VertexID;
};

struct psInput
{
    float4 pos	: SV_POSITION;
	float3 raypos	: TEXCOORD0;
	float3 raydir	: TEXCOORD1;
};

psInput VS ( vsInput input )
{
    psInput output = (psInput)0;	
    output.pos = input.pos;
	
	float4 rayfrom = float4(input.pos.xy,0.0f,1.0f);
	float4 rayto = float4(input.pos.xy, 1.0f,1.0f);
	
	rayfrom = mul(rayfrom,tIVP);
	rayto   = mul(rayto,tIVP);
	output.raypos = rayfrom.xyz;
	output.raydir = normalize(rayto.xyz);
    
	return output;
} 


//----------------------------------------------------------------------

// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return lerp( b, a, h ) - k*h*(1.0-h);
}
float udRoundBox( float3 p, float3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

//----------------------------------------------------------------------

float3 scaudbox = float3 (1.0,1.0,1.0);
float softness = 0.5;
float kmin = 0.3;
float3 posmin[4];
float4x4 rotmin[4];
bool enviroment;

float2 map( in float3 pos )
{
	
	float rbox1 = udRoundBox ( mul ( float4(pos-posmin[0],1.0) , rotmin[0] ).xyz,scaudbox,softness);
	float rbox2 = udRoundBox ( mul ( float4(pos-posmin[1],1.0) , rotmin[1] ).xyz,scaudbox,softness);
	float rbox3 = udRoundBox ( mul ( float4(pos-posmin[2],1.0) , rotmin[2] ).xyz,scaudbox,softness);
	float rbox4 = udRoundBox ( mul ( float4(pos-posmin[3],1.0) , rotmin[3] ).xyz,scaudbox,softness);
	
	float resmin = smin(rbox1, rbox2, kmin);
	resmin = smin(resmin, rbox3, kmin);
	resmin = smin(resmin, rbox4, kmin);
	float2 res = float2( resmin, 6.0 ) ;
	
    return res;
}


float2 castRay( in float3 ro, in float3 rd, in float maxd )
{
	float precis = 0.001;
    float h=precis*2.0;
    float t = 0.0;
    float m = -1.0;
    for( int i=0; i<ITERATIONS; i++ )
    {
        if( abs(h)<precis||t>maxd ) continue;//break;
        t += h;
	    float2 res = map( ro+rd*t );
        h = res.x;
	    m = res.y;
    }

    if( t>maxd ) m=-1.0;
    return float2( t, m );
}


float softshadow( in float3 ro, in float3 rd, in float mint, in float maxt, in float k )
{
	float res = 1.0;
    float t = mint;
    for( int i=0; i<40; i++ )
    {
		if( t<maxt )
		{
		float3 pos = ro + rd*t;
		float d1 = (map(pos).x);
		//float d2 = sdSphere(pos-float3( light),rad/4.0);
        float h = d1;
        res = min( res, k*h/t );
        t += 0.03;
		}
    }
    return clamp( res, 0.0, 1.0 );

}

float3 calcNormal( in float3 pos )
{
	float3 eps = float3( 0.001, 0.0, 0.0 );
	float3 nor = float3(
	    map(pos+eps.xyy).x - map(pos-eps.xyy).x,
	    map(pos+eps.yxy).x - map(pos-eps.yxy).x,
	    map(pos+eps.yyx).x - map(pos-eps.yyx).x );
	return normalize(nor);
}

float calcAO( in float3 pos, in float3 nor )
{
	float totao = 0.0;
    float sca = 1.0;
    for( int aoi=0; aoi<5; aoi++ )
    {
        float hr = 0.01 + 0.05*float(aoi);
        float3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        totao += -(dd-hr)*sca;
        sca *= 0.75;
    }
    return clamp( 1.0 - 4.0*totao, 0.0, 1.0 );
}

float fre = 1.0;

float3 Shading( float3 pos, float3 norm, float3 visibility, float3 rd )
{
	float3 albedo = float3(1.,1.,1.);

	float3 l = lightCol*lerp(visibility,float3(1.0,1.0,1.0)*max(0.0,dot(norm,normalize(light))),.0);
	float3 fl = fillLightColour*(dot(norm,normalize(fillLightDir))*.5+.5);
	
	float3 view = normalize(-rd);
	float3 h = normalize(view+normalize(light));
	float specular = pow(max(0.0,dot(h,norm)),2000.0);
	
	float fresnel = pow( 1.0 - dot( view, norm ), 5.0 )*fre;
	fresnel = lerp( .01, 1.0, min(1.0,fresnel) );
	
	return float3( albedo*(l+fl)*(1-fresnel) + visibility*specular*32.0*lightCol );
}

float3 SkyColour( float3 rd )
{
	// hide cracks in cube map
	rd -= sign ( abs ( rd.xyz )- abs( rd.yzx ) ) *.01;

	//return mix( vec3(.2,.6,1), FogColour, abs(rd.y) );
	//float3 ldr = texCUBE( linearSampler, rd ).rgb;
	float3 ldr = tex.SampleLevel( linearSampler, rd,1.0);
	// fake hdr
	float3 hdr = 1.0/(1.2-ldr) - 1.0/1.2;
	
	return hdr;
}

float3 materialreflection(in float3 ro, in float3 rd)
{
	  float3 col = float3(0.0,0.0,0.0);
      float2 res = castRay(ro,rd,40.0);
      float t = res.x;
	  float m = res.y;
	  float3 inter = float3(0.0,0.0,0.0);
	  float3 ref= float3(0.0,0.0,0.0);
	  col = SkyColour(rd)*enviroment; 
	//if (m= 1.0) return float3(0.0,0.0,0.0);
	if (m == 6.0)
	{
		float3 pos = ro + t*rd;
		float3 nor = calcNormal( pos );
		float ao = calcAO( pos, nor );	
		float3 ldir = normalize(light - pos);
			//cast first ray
		float2 tm = castRay(ro,rd,20.0);
			//figure out where it intersects
		inter = ro + rd*tm.x;
			//find reflection vector
		float3 ref  = reflect(rd,nor);
			//cast ray from intersection point with direction = reflection
		tm = castRay(inter,ref,20.0);
			//find intersection of reflected ray
		inter = inter + ref*tm.x;	
		float3 col = float3( 0.0,0.0,0.0);//render(inter,ref);
		float fre = ao*pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
		
		col*= fre;
		col += SkyColour(nor)*fre;
		float3 SSS = float3(1.0,1.0,1.0);
    	col += Shading(ro,nor,SSS,rd);

		return col;
	}   else{return col;}
	
		    return float3(0.0,0.0,0.0);
}

//===========================================================================================
float4 PS_Forward(psInput input) : SV_Target
{
	float3 ro   = input.raypos;
	float3 rd   = input.raydir;

  	
	float3 col2 = materialreflection(ro,rd);

	return float4 (col2,1.0);
}



technique10 Render
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Forward() ) );
	}
}




