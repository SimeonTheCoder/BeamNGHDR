#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform bool t <source="key"; keycode=0x54; toggle=true;>;
uniform bool v <source="key"; keycode=0x56; toggle=true;>;

uniform bool k <source="key"; keycode=0x4B; toggle=true;>;

uniform float timer < source = "timer"; >;

uniform float softness <
	ui_type = "drag";
	ui_label = "Ambient softness";
	ui_tooltip = "Set the desiredambient softness";
> = 1;

uniform float2 light_dir <
	ui_type = "drag";
	ui_label = "Light direction";
	ui_tooltip = "Set the desired light direction.";
> = float2(0, 1);

uniform bool enabled <
	ui_type = "check";
	ui_label = "Enabled";
	ui_tooltip = "Set enabled property.";
> = false;

float rand(float2 uv)
{
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}

float circle(float2 center, float2 uv, float radius, float2 scale) {
	uv -= center;
	uv *= float2(1.6 * scale.x, 0.9 * scale.y);

	float result = 1 - length(uv) - (1 - radius);

	return max(0, min(1, result * 10));
}

float puddle(float2 pos, float2 center, float rings_count, float scale, float2 sc) {
	float circles = 0;

	for(int i = rings_count; i > -1; i -= 2) {
		circles += circle(center, pos, i / 10.0 * scale, sc);
		circles -= circle(center, pos, (i - 1) / 10.0 * scale, sc);
	}

	return circles;
}

float3 CustomPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	if(!k && !enabled) discard;

	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float3 blurred = float3(0,0,0);

	for(int i = -5; i < 5; i ++) {
		for(int j = -5; j < 5; j ++) {
			blurred += tex2D(ReShade::BackBuffer, texcoord + float2(i / 600.0, j / 600.0)).rgb;
		}
	}

	blurred /= 100;

	float2 uv = texcoord;

	float circles = 0;
	float drops = 0;

	for(int i = 0; i < 21; i ++) {
		for(int j = 0; j < 6; j ++) {
			float noise = rand(float2(i, j + timer / 10000000.0));
			float noise2 = rand(float2(i, j));

			noise -= 0.9;
			noise *= 10;

			float circle = puddle(texcoord, float2(i / 20.0, j / 5.0), 1, noise / 2, float2(3, .3));

			noise = max(0, min(1, noise));

			circles += circle * noise;
		}
	}

	float3 dropImage = tex2D(ReShade::BackBuffer, texcoord + float2(drops / 100.0, drops / 100.0)).rgb;

	//return drops;

	//return dropImage;

	//return circles;
	//return blurred;
	return lerp(color, blurred * 0.55 + dropImage * 0.55, max(0, min(1, circles * 5)));
	//return puddle(texcoord, float2(0.5, 0.5), 5);
}

technique BeamRain
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CustomPass;
	}
}
