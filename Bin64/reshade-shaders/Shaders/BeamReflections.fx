#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform float norm_amount <
	ui_type = "drag";
	ui_label = "Snow amount";
	ui_tooltip = "Set the desired snow amount.";
> = 1;

uniform float rough_amount <
	ui_type = "drag";
	ui_label = "Set roughness";
	ui_tooltip = "Set the desired roughness value.";
> = 1;

uniform float depth_mul <
	ui_type = "drag";
	ui_label = "Depth multiplier";
	ui_tooltip = "Set the desired depth multiplier.";
> = 1;

uniform float2 offset <
	ui_type = "drag";
	ui_label = "Offset";
	ui_tooltip = "Set the desired snow amount.";
> = float2(0,0);

uniform int depth_correction <
	ui_type = "drag";
	ui_label = "Depth correction";
	ui_tooltip = "Depth correction.";
> = 0;

uniform bool proceduralNormals <
	ui_type = "check";
	ui_label = "Procedural Normals";
	ui_tooltip = "Set normal generation property.";
> = false;

uniform float windows_strength <
	ui_type = "drag";
	ui_label = "Windows mask strength";
	ui_tooltip = "Set the desired windows mask strength.";
> = 0;

uniform bool k <source="key"; keycode=0x4B; toggle=true;>;

float Depth(float2 uv) {
	float3 depth = tex2D(ReShade::DepthBuffer, uv).rgb;

	depth = pow(depth, 0.1);
	depth = 1 - depth;
	depth = max(0, min(1, depth));

	return depth;
}

float3 Normal(float2 texcoord) {
	float depth = Depth(texcoord);

	float depthCenter = Depth(texcoord);
	float depthRight = Depth(texcoord + float2(0.001, 0));
	float depthDown = Depth(texcoord + float2(0, -0.001));

	float3 normal;
	normal.x = depthCenter - depthRight;
	normal.y = depthCenter - depthDown;
	normal.z = 2.0 * 0.001;

	normal = normalize(normal) * 0.5 + 0.5;

	return float3(1 - normal.x, 1 - normal.y, normal.z);
}

float Edge(float2 uv) {
	float d = Depth(uv);

	float3 col = float3(0,0,0);
	
	float sum = 0;

	for(int i = -1; i < 1; i ++) {
		for(int j = -1; j < 1; j ++) {
			if(abs(Depth(uv + float2(i / 150.0, j / 150.0)) - d) <= 0.001) {
				col += tex2D(ReShade::BackBuffer, uv + float2(i / 150.0, j / 150.0)).rgb;
				sum += 1;
			}
		}
	}

	col /= sum;

	return length((tex2D(ReShade::BackBuffer, uv).rgb - col) + 0.5);
}

float3 CombineNormals(float3 normalGeometry, float3 normalTexture) {
    normalTexture = normalTexture * 2.0 - 1.0;
	normalGeometry = normalGeometry * 2.0 - 1.0;

    float3 combinedNormal = normalize(normalize(normalGeometry) + normalize(normalTexture));
    
    return combinedNormal * 0.5 + 0.5;
}

float3 GenNormals(float2 texcoord) {
	float e = Edge(texcoord);

	float3 res = float3(0,0,0);

	float a = Edge(texcoord + float2(1 / 100.0, 0));
	float b = Edge(texcoord + float2(0, 1 / 100.0));

	res = float3(e-a, e-b, 0);

	return CombineNormals(Normal(texcoord), normalize(float3(res.x, res.y, 1)) * 0.5 + 0.5);
}

float rand(float2 uv)
{
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}

float3 CustomPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float d = Depth(texcoord);

	if(d > 0.95) discard;

	//if(!k) discard;

	float3 normals;
	
	if(proceduralNormals) {
		normals = GenNormals(texcoord);
	}else{
		normals = Normal(texcoord);
	}

	float2 uv = float2(texcoord.x, texcoord.y * d * depth_mul) + (normals.xy - 0.5) * norm_amount + (normals.xy - 0.5) * norm_amount * (1 - d * 2) * depth_correction;
	
	float horizontal = abs(Normal(texcoord).r - 0.5) * 2 > 0.03 ? 1 : 0;

	uv = float2(lerp(uv.x, 1 - uv.x, horizontal), lerp(1 - uv.y, uv.y, horizontal));

	//return tex2D(ReShade::BackBuffer, texcoord + offset * (1 - Depth(texcoord) * 2));

	float3 color =  tex2D(ReShade::BackBuffer, texcoord);

	float blur = float3(0,0,0);

	int samples = 0;

	for(int i = -2; i < 2; i ++) {
		for(int j = -2; j < 2; j ++) {
			if(abs(d - Depth(texcoord + float2(i / 300.0, j / 300.0))) < 0.01) {
				blur += Edge(texcoord + float2(i / 300.0, j / 300.0));
				samples ++;
			}
		}
	}

	blur /= samples;

	float roughness = max(0, (1 - (abs(Edge(texcoord) - blur)) * 3) * 0.5) * color.b * rough_amount;
	float windowMask = min(1, max(0, (pow((color / length(color)).b, 2) - 0.45) * 200)) * 0.3;

	roughness += windowMask * windows_strength;

	roughness = max(0, min(1, roughness));

	//return blur;
	//return 1 - (abs(Edge(texcoord) - blur)) * 2;
	//return Edge(texcoord);
	
	//return windowMask;
	return tex2D(ReShade::BackBuffer, uv) * roughness + color * (1 - roughness);
	// float2 uv = texcoord + (normals.xy - 0.5) * norm_amount - (normals.xy - 0.5) * norm_amount * (1 - Depth(texcoord) * 2);

	//return float3(uv, 0);

	//return tex2D(ReShade::BackBuffer, texcoord + (normals.xy - 0.5) * norm_amount);

	//
	//return (dot(float3(0,1,0), normals) - 0.5) * norm_amount * float3(179 / 255.0, 202 / 255.0, 221 / 255.0) + tex2D(ReShade::BackBuffer, texcoord);
	//

	//return (dot(float3(0,1,0), normals) - 0.5)*3 * tex2D(ReShade::BackBuffer, texcoord + (normals.xy - 0.5) * 0.5);
	
	//return rand(texcoord);
	//return tex2D(ReShade::BackBuffer, texcoord + (normals.xy - 0.5) * 0.5 * Depth(texcoord)) * dot(float3(0,1,0), normals) * 0.2 + tex2D(ReShade::BackBuffer, texcoord);

	//return float3(0.5, 0.5, 1);
	//return (dot(float3(0,1,0), GenNormals(texcoord)) - 0.5)*1 + tex2D(ReShade::BackBuffer, texcoord);
	//return lerp(dot(float3(0,1,0), GenNormals(texcoord)) * tex2D(ReShade::BackBuffer, texcoord),tex2D(ReShade::BackBuffer, texcoord),0.5);
	//return dot(float3(1,0,0), GenNormals(texcoord)) * tex2D(ReShade::BackBuffer, texcoord);
}

technique BeamReflections
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CustomPass;
	}
}
