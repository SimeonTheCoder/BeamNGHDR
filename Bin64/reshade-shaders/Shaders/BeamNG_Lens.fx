#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform float distance <
	ui_type = "drag";
	ui_label = "Distance";
	ui_tooltip = "Set the desired eye distance.";
> = 0.033 / 2.0;

float3 CustomPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	texcoord *= float2(2, 1);
	texcoord -= float2(1, 0);

	float depth = tex2D(ReShade::DepthBuffer, texcoord);

	depth = pow(depth, 0.5);
	//depth *= 2;
	//depth -= 1;
	//depth = lerp(depth, log(depth), .3);
	//depth = 1 - depth;
	depth = max(0, min(1, depth));

    float2 vec = texcoord;

    float distance_factor = distance;

    //vec.x -= depth * distance_factor; // offset left image
    float3 colorA = tex2D(ReShade::BackBuffer, vec).rgb;
	colorA *= (vec.x < 0 || vec.x > 1) ? float3(0,0,0) : float3(1,1,1);

	texcoord += float2(1, 0);

	depth = tex2D(ReShade::DepthBuffer, texcoord);

	depth = pow(depth, 0.5);
	//depth *= 2;
	//depth -= 1;
	//depth = lerp(depth, log(depth), .3);
	//depth = 1 - depth;
	depth = max(0, min(1, depth));

	vec = texcoord;

    vec.x -= depth * distance_factor; // offset right image
    float3 colorB = tex2D(ReShade::BackBuffer, vec).rgb;
	colorB *= (vec.x > 1) ? float3(0,0,0) : float3(1,1,1);

	//return depth;
    return colorA + colorB * (length(colorA) > 0 ? 0 : 1);
}

technique BeamLens
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CustomPass;
	}
}
