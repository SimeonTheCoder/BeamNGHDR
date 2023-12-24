#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform float exposure <
	ui_type = "input";
	ui_label = "Exposure";
	ui_tooltip = "Set the desired exposure";
> = 1; 

float3 CustomPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb - 0.001;
	float3 orig = color;

	color = color / (1 - color);
	color /= 1.5;

	orig /= length(orig);
	orig *= length(color) - max(0,log(length(color)));

	return orig;
}

technique BeamHDR6
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CustomPass;
	}
}
