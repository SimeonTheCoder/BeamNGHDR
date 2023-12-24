#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "Beam.fxh"

uniform bool t <source="key"; keycode=0x54; toggle=true;>;
uniform bool v <source="key"; keycode=0x56; toggle=true;>;

uniform bool k <source="key"; keycode=0x4B; toggle=true;>;

uniform float timer < source = "timer"; >;

uniform float thickness <
	ui_type = "drag";
	ui_label = "Thickness";
	ui_tooltip = "Set the desired thickness.";
> = 0;

uniform float denoise <
	ui_type = "drag";
	ui_label = "Denoise strength";
	ui_tooltip = "Set the desired denoise strength.";
> = 1;

uniform float softness <
	ui_type = "drag";
	ui_label = "Ambient softness";
	ui_tooltip = "Set the desiredambient softness";
> = 1;

uniform float light_strength <
	ui_type = "drag";
	ui_label = "Light strength";
	ui_tooltip = "Set the desired light strength.";
> = .6;

uniform float bouce_light_stength <
	ui_type = "drag";
	ui_label = "Bounce light strength";
	ui_tooltip = "Set the desired bounce light strength.";
> = 1;

uniform float shadows_stength <
	ui_type = "drag";
	ui_label = "Shadows strength";
	ui_tooltip = "Set the desired shadow strength.";
> = 1;

uniform float norm_comp <
	ui_type = "drag";
	ui_label = "Normal Compensation";
	ui_tooltip = "Set the procedural normal compensation.";
> = 0;

uniform float vegetation_transparency <
	ui_type = "drag";
	ui_label = "Vegetation transparency";
	ui_tooltip = "Set the desired vegetation transparency.";
> = .5;

uniform float2 light_dir <
	ui_type = "drag";
	ui_label = "Light direction";
	ui_tooltip = "Set the desired light direction.";
> = float2(0, 1);

uniform bool method <
	ui_type = "check";
	ui_label = "Multiply";
	ui_tooltip = "Set method to multiply";
> = false;

uniform bool snow <
	ui_type = "check";
	ui_label = "Snow";
	ui_tooltip = "Makes eveyrhint snowy.";
> = false;

uniform bool thunder <
	ui_type = "check";
	ui_label = "Thunder";
	ui_tooltip = "Makes eveyrhint thunder-y.";
> = false;

uniform float snow_amount <
	ui_type = "drag";
	ui_label = "Snow amount";
	ui_tooltip = "Set the desired snow amount.";
> = 1;

float VegetationMask(float3 color) {
	float vegetationMask = color.g - color.r * 0.5 - color.b * 0.5;
	vegetationMask *= 10;
	vegetationMask -= 0.9;

	vegetationMask = max(0, min(1, vegetationMask));

	vegetationMask *= 1000;

	vegetationMask = max(0, min(1, vegetationMask));

	return vegetationMask;
}

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

float3 CombineNormals(float3 normalGeometry, float3 normalTexture, float factor) {
    normalTexture = normalTexture * 2.0 - 1.0;
	normalGeometry = normalGeometry * 2.0 - 1.0;

    float3 combinedNormal = normalize(normalize(normalGeometry) + normalize(normalTexture));
    
    return combinedNormal * 0.5 + 0.5;
}

float3 GenNormals(float2 texcoord, float factor) {
	float e = Edge(texcoord);

	float3 res = float3(0,0,0);

	float a = Edge(texcoord + float2(1 / 100.0, 0));
	float b = Edge(texcoord + float2(0, 1 / 100.0));

	res = float3(e-a, e-b, 0);

	return CombineNormals(Normal(texcoord), normalize(float3(res.x, res.y, 1)) * 0.5 + 0.5, factor);
}

float3 CalculateLight(float2 uv, float depth, float2 light_dir, float3 skyColor, float3 normal) {
	float smallestDepthDiff = 10;
	float3 collColor = float3(0,0,0);

	for(int i = 0; i < 10; i ++) {
		float x = uv.x - i / 230.0 * light_dir.x;
		float y = uv.y - i / 230.0 * light_dir.y;

		float curr = Depth(float2(x, y));
		float3 col = tex2D(ReShade::BackBuffer, float2(x, y)).rgb;

		float diff = curr - depth.x;

		if(diff < thickness) {
			smallestDepthDiff = diff;
			collColor = col;
		}
	}

	if(smallestDepthDiff < thickness) {
		//return (vegetation_transparency * VegetationMask(collColor)) * collColor * 1.5;

		collColor = collColor / (1 - collColor);
		collColor -= 1;
		collColor = min(1, max(0, collColor));
		
		return lerp(collColor * bouce_light_stength, lerp(1, dot((normal - 0.5) * 2, float3(0,1,0)), 0.5) * collColor * bouce_light_stength, norm_comp);
		//return collColor * bouce_light_stength;
	}

	return lerp(skyColor, lerp(skyColor, (dot((normal - 0.5) * 2, float3(0,1,0))) * skyColor, 0.5), norm_comp);
}

float rand(float2 uv)
{
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}

float3 CustomPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float veg = VegetationMask(color);

	float3 skyColor;

	if(t) {
		skyColor = float3(0,0,0);
		int samplesCount = 0;

		for(int i = 0; i < 5; i ++) {
			for(int j = 0; j < 5; j ++) {
				float2 uv = float2(i / 5.0, j / 5.0);

				float3 currDepth = Depth(uv);

				if(currDepth.x > 0.95) {
					samplesCount ++;

					skyColor += tex2D(ReShade::BackBuffer, uv).rgb;
				}
			}
		}

		if(samplesCount != 0) {
			skyColor = skyColor / samplesCount;
		}else{
			skyColor = float3(0, 0, 0);
		}
	}else{
		skyColor = float3(179 / 255.0, 202 / 255.0, 221 / 255.0);
	}


	float depth = Depth(texcoord);

	if(depth > 0.95) discard;

	float3 ave = float3(0, 0, 0);

	float samples = 0;

	for(int a = -2; a < 2; a ++) {
		for(int b = -1; b < 1; b ++) {
			float2 currUv = texcoord + float2(a / 600.0 * denoise, b / 600.0 * denoise);
			float3 normals = GenNormals(texcoord, 1);

			//if(abs(Depth(currUv) - depth) < 0.0005) {
				ave += CalculateLight(currUv, depth, (normals.xy - float2(0.5, 0.5)) * 2 * light_dir * float2(1, depth) + float2(a / 10.0 * softness, 0), skyColor, normals);

				samples += 1;
			//}

			//ave += CalculateLight(currUv, depth, (GenNormals(texcoord).xy - float2(0.5, 0.5)) * 2 * light_dir * float2(1, depth) + float2(a / 10.0 * softness, 0), skyColor) * max(0, min(1, (abs(Depth(currUv) - depth) < 0.03 ? 0 : 1)));
			//samples += (abs(Depth(currUv) - depth) < 0.03 ? 0 : 1);
			//samples ++;

			//ave += CalculateLight(texcoord + float2(-a / 600.0 * denoise, -b / 600.0 * denoise), depth, light_dir + float2(-a / 10.0 * softness, 0), skyColor);
		}
	}

	ave /= samples;

	float3 light = lerp(skyColor * ave * light_strength, length(skyColor * ave) * light_strength, 0.7) * color;

	return ave;

	// if(v) return ave;

	// if(snow) {
	// 	ave -= 1 - snow_amount;
	// 	ave = pow(ave, snow_amount);
	// 	ave = max(0, min(1, ave));
	// 	ave = 1 - ave;

	// 	ave /= 5;

	// 	return lerp(lerp(color, length(color), veg * snow_amount), length(color) + float3(.1,.1,.1), ave * 3);
	// }

	// if(thunder || k) {
	// 	return color + ave * skyColor * (light_strength + (max(0, rand(float2(0, timer/10000000.0)) - 0.99) * 100) * light_strength * 5);
	// }

	// //return VegetationMask(color);
	// //return ave;

	// if(shadows_stength != 0) {
	// 	ave = lerp((ave - 0.2) * shadows_stength, ave, min(1, max(0, ave - 0.2) * 5));
	// }

	// if(length(ave) < 0) {
	// 	ave *= shadows_stength;
	// }

	// if(!method) {
	// 	return color + ave * skyColor * light_strength;
	// } else {
	// 	//return lerp(color + ave * skyColor * light_strength, color * ave + color * light_strength, 0.5);

	// 	return lerp(color + ave * light_strength, color * ave + color * light_strength, 0.5);
	// }
	// //return lerp(color, light, ave);
}

technique BeamRT
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CustomPass;

		RenderTarget = Common::LightBufferTex;
	}
}
