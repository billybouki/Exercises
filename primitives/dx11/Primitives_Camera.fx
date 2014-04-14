#define EPSILON  0.001f
float4x4 tV : VIEW;
float4x4 tP : PROJECTION;
float4x4 tIVP : VIEWPROJECTIONINVERSE;
float4x4 tW : WORLD;
float4x4 tVP : VIEWPROJECTION;	

float3 light;


Texture2D texture2d <string uiname="Texture";>;
SamplerState linearSampler : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};


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
	rayto = mul(rayto,tIVP);
	output.raypos = rayfrom.xyz;
	output.raydir = normalize(rayto.xyz);
    
	return output;
} 



float radius;
float3 bo =float3 ( 1.0, 1.0, 1.0 );
float iGlobalTime;
float2 iResolution;
float2 iMouse;
// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// A list of usefull distance function to simple primitives, and an example on how to 
// do some interesting boolean operations, repetition and displacement.
//
// More info here: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm


float sdPlane( float3 p )
{
	return p.y;
}

float sdSphere( float3 p, float s )
{
    return length(p)-s;
}

float sdBox( float3 p, float3 b )
{
  float3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float udRoundBox( float3 p, float3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float sdTorus( float3 p, float2 t )
{
  float2 q = float2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdHexPrism( float3 p, float2 h )
{
    float3 q = abs(p);
    return max(q.z-h.y,max(q.x+q.y*0.57735,q.y*1.1547)-h.x);
}

float sdCapsule( float3 p, float3 a, float3 b, float r )
{
	float3 pa = p - a;
	float3 ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	
	return length( pa - ba*h ) - r;
}

float sdTriPrism( float3 p, float2 h )
{
    float3 q = abs(p);
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

float sdCylinder( float3 p, float2 h )
{
  return max( length(p.xz)-h.x, abs(p.y)-h.y );
}

float sdCone( in float3 p, in float3 c )
{
    float2 q = float2( length(p.xz), p.y );
	return max( max( dot(q,c.xy), p.y), -p.y-c.z );
}

float length2( float2 p )
{
	return sqrt( p.x*p.x + p.y*p.y );
}

float length6( float2 p )
{
	p = p*p*p; p = p*p;
	return pow( p.x + p.y, 1.0/6.0 );
}

float length8( float2 p )
{
	p = p*p; p = p*p; p = p*p;
	return pow( p.x + p.y, 1.0/8.0 );
}

float sdTorus82( float3 p, float2 t )
{
  float2 q = float2(length2(p.xz)-t.x,p.y);
  return length8(q)-t.y;
}

float sdTorus88( float3 p, float2 t )
{
  float2 q = float2(length8(p.xz)-t.x,p.y);
  return length8(q)-t.y;
}

float sdCylinder6( float3 p, float2 h )
{
  return max( length6(p.xz)-h.x, abs(p.y)-h.y );
}

//----------------------------------------------------------------------

float opS( float d1, float d2 )
{
    return max(-d2,d1);
}

float2 opU( float2 d1, float2 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}

float3 opRep( float3 p, float3 c )
{
    return fmod(p,c)-0.5*c;
}

float3 opTwist( float3 p )
{
    float  c = cos(10.0*p.y+10.0);
    float  s = sin(10.0*p.y+10.0);
    float2x2   m = float2x2(c,-s,s,c);
    return float3(mul(m,p.xz),p.y);
}

//----------------------------------------------------------------------

float2 map( in float3 pos )
{
    float2 res = opU( float2( sdPlane(     pos), 1.0 ), float2( sdSphere(   pos-float3( 0.0,0.25, 0.0), 0.25 ), 46.9 ) );
    res = opU( res, float2( sdBox(       pos-float3( 1.0,0.25, 0.0), float3(0.25,0.25,0.25) ), 3.0 ) );
    res = opU( res, float2( udRoundBox(  pos-float3( 1.0,0.25, 1.0), float3(0.15,0.15,0.15), 0.1 ), 41.0 ) );
	res = opU( res, float2( sdTorus(     pos-float3( 0.0,0.25, 1.0), float2(0.20,0.05) ), 25.0 ) );
    res = opU( res, float2( sdCapsule(   pos,float3(-1.3,0.20,-0.1), float3(-1.0,0.20,0.2), 0.1  ), 31.9 ) );
	res = opU( res, float2( sdTriPrism(  pos-float3(-1.0,0.25,-1.0), float2(0.25,0.05) ),43.5 ) );
	res = opU( res, float2( sdCylinder(  pos-float3( 1.0,0.30,-1.0), float2(0.1,0.2) ), 8.0 ) );
	res = opU( res, float2( sdCone(      pos-float3( 0.0,0.50,-1.0), float3(0.8,0.6,0.3) ), 55.0 ) );
	res = opU( res, float2( sdTorus82(   pos-float3( 0.0,0.25, 2.0), float2(0.20,0.05) ),50.0 ) );
	res = opU( res, float2( sdTorus88(   pos-float3(-1.0,0.25, 2.0), float2(0.20,0.05) ),43.0 ) );
	res = opU( res, float2( sdCylinder6( pos-float3( 1.0,0.30, 2.0), float2(0.1,0.2) ), 12.0 ) );
	res = opU( res, float2( sdHexPrism(  pos-float3(-1.0,0.20, 1.0), float2(0.25,0.05) ),17.0 ) );


    return res;
}


float2 castRay( in float3 ro, in float3 rd, in float maxd )
{
	float precis = 0.001;
    float h=precis*2.0;
    float t = 0.0;
    float m = -1.0;
    for( int i=0; i<60; i++ )
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
    for( int i=0; i<30; i++ )
    {
		if( t<maxt )
		{
        float h = map( ro + rd*t ).x;
        res = min( res, k*h/t );
        t += 0.02;
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




float3 render( in float3 ro, in float3 rd )
{ 
    float3 col = float3(0.0,0.0,0.0);
    float2 res = castRay(ro,rd,20.0);
    float t = res.x;
	float m = res.y;
    if( m>-0.5 )
    {
        float3 pos = ro + t*rd;
        float3 nor = calcNormal( pos );

		//col = vec3(0.6) + 0.4*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
		col = float3(0.6,0.6,0.6) + 0.4*sin( float3(0.05,0.08,0.10)*(m-1.0) );
		
        float ao = calcAO( pos, nor );

		float3 lig = normalize( light );
		float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(float3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);

		float sh = 1.0;
		if( dif>0.02 ) { sh = softshadow( pos, lig, 0.02, 10.0, 7.0 ); dif *= sh; }

		float3 brdf = float3(0.0,0.0,0.0);
		brdf += 0.20*amb*float3(0.10,0.11,0.13)*ao;
        brdf += 0.20*bac*float3(0.15,0.15,0.15)*ao;
        brdf += 1.20*dif*float3(1.00,0.90,0.70);

		float pp = clamp( dot( reflect(rd,nor), lig ), 0.0, 1.0 );
		float spe = sh*pow(pp,16.0);
		float fre = ao*pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );

		col = col*brdf + float3(1.0,1.0,1.0)*col*spe + 0.2*fre*(0.5+0.5*col);
		
	}

	col *= exp( -0.01*t*t );


	return float3( clamp(col,0.0,1.0) );
}

 
float4 PS_Forward(psInput input) : SV_Target
{
	
		 
	float time = 15.0 + iGlobalTime;

	float3 ro=input.raypos;
	float3 rd=input.raydir;

    float3 col = render( ro, rd );
	
/*	/////REFLECTINO///////////////////////////
	float4 col2;
	float4 ref2;
	
	tm = calcinter(inter,ref.xyz,obj,col2);
    inter = inter + ref.xyz*tm;
	
    col2 = calcshade ( inter,obj,col2, ref.xyz , ldir , ref2 );
	//////////////////////////////////////////*/


	return float4(col,1.0 );
}



technique10 Render
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Forward() ) );
	}
}




