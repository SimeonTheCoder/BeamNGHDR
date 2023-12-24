#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform float strength <
	ui_type = "drag";
	ui_label = "Effect strength";
	ui_tooltip = "Set the desired effect strength.";
> = 0.5;

uniform float exposure <
	ui_type = "drag";
	ui_label = "Exposure";
	ui_tooltip = "Set the desired sky exposure.";
> = 1;

uniform bool thunder <
	ui_type = "check";
	ui_label = "Thunder";
	ui_tooltip = "Makes eveyrhint thunder-y.";
> = false;

uniform bool k <source="key"; keycode=0x4B; toggle=true;>;

uniform float timer < source = "timer"; >;

float rand(float2 uv)
{
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}

float3 CustomPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 skyColor = float3(119 / 255.0, 142 / 255.0, 181 / 255.0);
	// int samplesCount = 0;

	// for(int i = 0; i < 5; i ++) {
	// 	for(int j = 0; j < 5; j ++) {
	// 		float2 uv = float2(i / 5.0, j / 5.0);

	// 		float3 currDepth = tex2D(ReShade::DepthBuffer, uv).rgb;

	// 		currDepth = pow(currDepth, 0.1);
	// 		currDepth = 1 - currDepth;
	// 		currDepth = max(0, min(1, currDepth));

	// 		if(currDepth.x > 0.95) {
	// 			samplesCount ++;

	// 			skyColor += tex2D(ReShade::BackBuffer, uv).rgb;
	// 		}
	// 	}
	// }

	// skyColor = skyColor / samplesCount;
	// skyColor *= 0.5;

	// skyColor = lerp(texcoord.y, skyColor, 0.5);

	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 original = color;

	float3 depth = tex2D(ReShade::DepthBuffer, texcoord).rgb;

	depth = pow(depth, 0.1);
	depth = 1 - depth;
	depth = max(0, min(1, depth));

	if(depth.x < 0.99) discard;

	float luminance = length(color);

	if(luminance >= 0.5) {
		color = 1 - 2 * (1 - color) * (1 - skyColor);
	}else{
		color = 2 * color * skyColor;
	}

	if (thunder || k){
		return lerp(length(lerp(original, color, strength)) - 1, float3(0.4,0.4,0.4), 1 - length(lerp(original, color, strength)) + 1) + (max(0, rand(float2(0, (timer-2)/10000000.0)) - 0.99) * 100);
	}else{
		return lerp(original, color, strength) * exposure;
	}
}

technique BeamSky
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CustomPass;
	}
}
