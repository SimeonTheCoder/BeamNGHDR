#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "Beam.fxh"

float3 CustomPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float3 depth = tex2D(ReShade::DepthBuffer, texcoord).rgb;

	depth = pow(depth, 0.1);
	depth = 1 - depth;
	depth = max(0, min(1, depth));

	if(depth.x > 0.99) discard;

	float3 light = float3(0,0,0);

	float w = 0;

	for(int i = -5; i < 5; i ++) {
		for(int j = -5; j < 5; j ++) {
			float currDepth = tex2D(ReShade::DepthBuffer, texcoord + float2(i / 1200.0, j / 1200.0)).rgb;

			currDepth = pow(currDepth, 0.1);
			currDepth = 1 - currDepth;
			currDepth = max(0, min(1, currDepth));

			if(abs(depth.x - currDepth) < 0.01) {
				light += tex2D(Common::LightBuffer, texcoord + float2(i / 1200.0, j / 1200.0)).rgb;
				w += 1;
			}
		}
	}

	light /= w;
	light += 0.6;

	float3 copy = color;
	copy = copy / (1 - copy);
	copy += copy * light * 1.3;
	copy *= 0.6;
	copy = copy / (1 + copy);

	//float3 ave = tex2D(Common::LightBuffer, texcoord).rgb;

	//return light;
	return copy;
	//return lerp(color, color * light, 0.5);
	//return lerp(color + light * 0.1, color * light + color * 0.2, 0.5);
}

technique BeamDenoise
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CustomPass;
	}
}
