#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform bool k <source="key"; keycode=0x4B; toggle=true;>;

uniform float density <
	ui_type = "drag";
	ui_label = "Fog density";
	ui_tooltip = "Set the desired fog density.";
> = 0.5;

uniform float falloff <
	ui_type = "drag";
	ui_label = "Fog falloff";
	ui_tooltip = "Set the desired fog falloff.";
> = 2;

uniform float height <
	ui_type = "drag";
	ui_label = "Fog height";
	ui_tooltip = "Set the desired fog height.";
> = 0;

uniform bool rain <
	ui_type = "check";
	ui_label = "Rain";
> = false;

float3 CustomPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 skyColor = float3(0,0,0);
	int samplesCount = 0;

	for(int i = 0; i < 5; i ++) {
		for(int j = 0; j < 5; j ++) {
			float2 uv = float2(i / 5.0, j / 5.0);

			float3 currDepth = tex2D(ReShade::DepthBuffer, uv).rgb;

			currDepth = pow(currDepth, 0.1);
			currDepth = 1 - currDepth;
			currDepth = max(0, min(1, currDepth));

			if(currDepth.x > 0.95) {
				samplesCount ++;

				skyColor += tex2D(ReShade::BackBuffer, uv).rgb;
			}
		}
	}

	if(samplesCount != 0) {
		skyColor = skyColor / samplesCount;
	}else{
		skyColor = float3(0, 0.3, 0.7);
	}

	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 depth = tex2D(ReShade::DepthBuffer, texcoord).rgb;

	depth = pow(depth, 0.1);
	depth = 1 - depth;
	depth = max(0, min(1, depth));

	depth = float3(depth.x, depth.x, depth.x);

	if(depth.x > 0.95) discard;

	//return texcoord.y - (1 - depth);

	float fac = max(0, texcoord.y - (1 - height) + 1 - 1 + depth * 2);
	fac = max(0, min(1, pow(fac, falloff)));

	//return fac;

	//return pow(depth, 3) * 3 * skyColor;

	//return pow(texcoord.y - (1 - height) + 1 - 1 + depth * 2, 10);
	if(rain || k) {
		return lerp(lerp(color, lerp(skyColor, color, (1 - density) * fac), min(1, fac)), pow(depth, 3) * 3 * skyColor, pow(depth, 3) * 4);
	}else{
		return lerp(color, lerp(skyColor, color, (1 - density) * fac), min(1, fac));
	}
}

technique BeamAtm
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CustomPass;
	}
}
