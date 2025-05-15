Shader "ColorBlit"
{
        SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZWrite Off Cull Off
        Pass
        {
            Name "ColorBlitPass"
            Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"} 
            ZWrite Off
            ZTest Always
            Cull Off 

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // The Blit.hlsl file provides the vertex shader (Vert),
            // input structure (Attributes) and output strucutre (Varyings)
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Assets/Shaders/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS                    //接受阴影
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE            //产生阴影
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _SHADOWS_SOFT                         //软阴影
            #pragma vertex Vert
            #pragma fragment frag

            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);


            float _FogDensity;
            float _RayVisibility;
            float _StepSize;
            float _DitherSize;

            float getDepth(float2 uv)
            {
                // Sample the depth from the Camera depth texture.
            #if UNITY_REVERSED_Z
                real depth = SampleSceneDepth(uv);
            #else
                // Adjust Z to match NDC for OpenGL ([-1, 1])
                real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
            #endif
                return depth;
            }

            #define exp(x) pow(2.718281828459045, x)
            float3 applyFog( in float3  col,   // color of pixel
               in float t,     // distance to point
               in float3  rd,    // camera to point
               in float3  lig )  // sun direction
            {
                float fogAmount = 1.0 - exp(-t*_FogDensity);
                float sunAmount = max( dot(rd, lig), 0.0 );
                float3  fogColor  = lerp( float3(0.5,0.6,0.7), // blue
                                    float3(1.0,0.9,0.7), // yellow
                                    pow(sunAmount,8.0) );
                return lerp( col, fogColor, fogAmount );
            }

            half4 frag (Varyings input) : SV_Target
            {
                float2 UV = input.texcoord;
                float4 color = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, input.texcoord);
                float fragDepth = getDepth(UV);
                float4 clipPos = float4(input.positionCS.xy, 0, 1.0);
                float3 worldPos = ComputeWorldSpacePosition(UV, fragDepth, UNITY_MATRIX_I_VP);
                Light light = GetMainLight(TransformWorldToShadowCoord(worldPos));

                // ray marching to get volumetric effect
                float3 ro = _WorldSpaceCameraPos;
                float3 rd = normalize(worldPos - ro);

                float atten = 1.0;
                float step = _StepSize;
                float maxDepth = min(100, LinearEyeDepth(fragDepth,_ZBufferParams));
                float dthr = dither(UV) * _DitherSize;
                float3 fog = applyFog(color.rgb, min(30, LinearEyeDepth(fragDepth, _ZBufferParams)), rd, light.direction);
                for (float i = 0; i < maxDepth; i += step + dthr)
                {
                    float3 p = ro + rd * i;
                    float lightAtten = MainLightRealtimeShadow(TransformWorldToShadowCoord(p));
                    atten += lightAtten < 0.90 ? -_RayVisibility : 0;
                }
                return half4(lerp(color, fog, saturate(atten)), 1.0);
            }
            ENDHLSL
        }
    }
}