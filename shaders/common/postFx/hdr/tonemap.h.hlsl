#ifndef USE_OLD_TONEMAP
#define BNG_ACES_TONEMAP
#endif
#ifdef BNG_ACES_TONEMAP
#include "shaders/common/postfx/hdr/ACES.h.hlsl"
#endif

// http://de.slideshare.net/ozlael/hable-john-uncharted2-hdr-lighting
float3 TonemapOperatorUncharted2(float3 x)
{
   float A = 0.15;
   float B = 0.50;
   float C = 0.10;
   float D = 0.20;
   float E = 0.02;
   float F = 0.30;

   return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float3 Reinhard(float3 color) {
    return color / (1 + length(color));
}

float3 TonemapUncharted2(float3 color)
{
    const float exposure_adjustment = 1; //16;
    const float exposure_bias = 1.25; //2;

    color = max(color, 0) * exposure_adjustment;
    const float whiteScale = (1.0f / TonemapOperatorUncharted2(11.2f)).x;
    return saturate(TonemapOperatorUncharted2(exposure_bias * color) * whiteScale);
}

float3 tonemap(float3 rgb) {
#ifdef BNG_ACES_TONEMAP
    return Reinhard(rgb);
#else
   return Reinhard(rgb);
#endif
}