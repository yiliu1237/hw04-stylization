// This Unity shader reconstructs the world space positions for pixels using a depth
// texture and screen space UV coordinates. The shader draws a checkerboard pattern
// on a mesh to visualize the positions.
Shader "Custom/StyleizeSkybox"
{
    Properties
    { 
        [Header(Brush)][Space]
        _BrushNormalScale ("Brush Normal Scale", Range(0.5, 3.0)) = 1.5
        _BrushCube1 ("Brush Cube1", CUBE) = "white" {}

        [Toggle(_UseRamp)] _URamp ("Use Ramp", Float) = 1
        _ColorRamp ("Color Ramp", 2D) = "white" {}
        _VoronoiSize ("Voronoi Size", Range(1.0, 15.0)) = 5.0
        _Color ("Color", Color) = (1,1,1,1)
        _ColorTransition ("Color Transition", Range(0.01, 1)) = 0.5
        _FbmBrushFrequency ("Brush Frequency", Range(0.1, 10)) = 0.5
        _FbmBrushStrength ("Brush Strength", Range(0.1, 10)) = 1.0  
        _FactorFbm ("Factor Fbm", Range(0.01, 1)) = 0.5
        _FactorBrush ("Factor Brush", Range(0.01, 1)) = 0.5

        [Header(Rim)][Space]
        _RimThreshold ("Rim Threshold", Range(0.001, 0.03)) = 0.1
        _RimKernel ("Rim Kernel", Range(0.001, 0.1)) = 0.01
        _RimScale ("Rim Scale", Range(0.5, 3.0)) = 1.5
        [Toggle(_UseHalfLambert)] _UHLambert ("Use Half Lambert", Float) = 1

        [Header(Sun)][Space]
        _SunColor ("Sun Color", Color) = (1,1,1,1)
        _SunIntensity ("Sun Intensity", Range(0.1, 10)) = 1.0
        _InnerSize ("Sun Size", Range(0.97, 1)) = 0.1
        _Fade ("Fade", Range(0.001, 0.02)) = 0.01

        [Header(Wind)][Space]
        _WindDirection ("Wind Direction", Vector) = (1, 0, 0)
        _WindSpeed ("Wind Speed", Range(0.1, 1.0)) = 1.0
        _WindStrength ("Wind Strength", Range(0.2, 10.0)) = 0.1

        [Header(DayNight)][Space]
        _DayTime ("DayTime", Range(0.0, 1.0)) = 0.4
        _NightTime ("NightTime", Range(0.0, 1.0)) = 0.6
        _ElapseInterval ("ElapseInterval", Range(0.0, 1.0)) = 0.1
        _StarDensity ("Star Density", Range(1.0, 30)) = 1.0
        _StarSize ("Star Size", Range(0.01, 0.1)) = 0.2
        _StarColor ("Star Color", Color) = (1,1,1,1)
        _StarBlinkSpeed ("Star Blink Speed", Range(0.1, 10)) = 1.0
    }

    // The SubShader block containing the Shader code.
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        // Blend SrcAlpha OneMinusSrcAlpha
        // Cull Front
        // ZWrite Off
        // ZTest Off
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
        UsePass "Universal Render Pipeline/Lit/DepthNormals"
        
        ZWrite On

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Assets/Shaders/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        
        

        CBUFFER_START(UnityPerMaterial)
        float _BrushNormalScale;
        float4 _Color;
        float _VoronoiSize;
        float _FbmBrushFrequency;
        float _FbmBrushStrength;
        float _FactorFbm;
        float _FactorBrush;
        float _RimThreshold;
        float _RimKernel;
        float _RimScale;
        float _ColorTransition;
        float4 _SunColor;
        float _SunIntensity;
        float _InnerSize;
        float _Fade;
        float3 _WindDirection;
        float _WindSpeed;
        float _WindStrength;
        float _DayTime;
        float _NightTime;
        float _ElapseInterval;
        float _StarDensity;
        float _StarSize;
        float4 _StarColor;
        float _StarBlinkSpeed;
        CBUFFER_END


        TEXTURECUBE(_BrushCube1);
        SAMPLER(sampler_BrushCube1);
        TEXTURE2D(_ColorRamp);
        #define smp _Point_Clamp
        SAMPLER(smp);

        struct Attributes
        {
            float4 positionOS   : POSITION;
            float2 uv : TEXCOORD0;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
        };

        struct Varyings
        {
            float4 positionHCS  : SV_POSITION;
            float3 positionWS : TEXCOORD0;
            float3 positionOS : TEXCOORD1;
            float2 uv : TEXCOORD2;
            float3 normal : TEXCOORD3;
            float3 tangent : TEXCOORD4;
            float3 bitangent : TEXCOORD5;
        };

        Varyings vert(Attributes IN)
        {
            Varyings OUT;
            VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
            OUT.positionHCS = vertexInput.positionCS;
            OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
            OUT.positionOS = IN.positionOS.xyz;
            OUT.uv = IN.uv;
            
            VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normal, IN.tangent);
            OUT.normal = normalInput.normalWS;
            OUT.tangent = normalInput.tangentWS;
            OUT.bitangent = normalInput.bitangentWS;
            return OUT;
        }


        float getDepth(float2 uv)
        {
            // Sample the depth from the Camera depth texture.
        #if UNITY_REVERSED_Z
            real depth = SampleSceneDepth(uv);
        #else
            // Adjust Z to match NDC for OpenGL ([-1, 1])
            real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(uv));
        #endif
            return Linear01Depth(depth, _ZBufferParams);
        }

        #define POW5(x) ((x) * (x) * (x) * (x) * (x))
        #define NormalToUV(normal) float2(atan2(normal.z, normal.x) / 6.2831853 + 0.5, asin(normal.y) / 3.1415927 + 0.5)
        #define UVToNormal(uv) float3(cos((uv.y - 0.5) * 3.1416927) * cos(uv.x * 6.2831853 - 3.1416927), sin((uv.y - 0.5) * 3.1416927), cos((uv.y - 0.5) * 3.1416927) * sin(uv.x * 6.2831853 - 3.1416927))
        
        half4 frag(Varyings IN) : SV_Target
        {
            // main light
            Light light = GetMainLight();

            // screen uv
            float2 UV = IN.positionHCS.xy / _ScaledScreenParams.xy;
            float3x3 ltO = localToWorld(IN.positionOS);
            float3 normal = normalize(IN.positionWS);
            float3 V = normalize(_WorldSpaceCameraPos - IN.positionWS);

            // overlay blend brush normal
            float3 brushNormal1 = UnpackNormalScale(SAMPLE_TEXTURECUBE(_BrushCube1, sampler_BrushCube1, rotatePointAroundAxis(normalize(IN.positionOS), _WindDirection, _Time.y * _WindSpeed * 0.07)), _BrushNormalScale).xyz;
            brushNormal1 = mul(ltO, brushNormal1);
            float3 brushNormal2 = IN.positionOS;
            float3 brushNormal = overlay(brushNormal1 * 0.5 + 0.5, brushNormal2 * 0.5 + 0.5);

            float2 fbm = float2((fbm3D(normalize(IN.positionOS)* _FbmBrushFrequency) - 0.5) * _FbmBrushStrength ,(fbm3D(normalize(IN.positionOS) * _FbmBrushFrequency) - 0.5) * _FbmBrushStrength);
            fbm = fbm * fbm * fbm;
            float3 fbmNormal = mul(ltO, normalize(float3(fbm, 1.0)));

            // linear light blend normal
            normal = lerp(normal, fbmNormal, _FactorFbm);
            normal = lerp(normal, brushNormal * 2.0 - 1.0, _FactorBrush);

            // voronoi using distorted normal as input
            float3 voronoiNormal;
            float2 voronoi = voronoi3D(normal * _VoronoiSize , voronoiNormal);
            normal = normalize(voronoiNormal * 2.0 - 1.0);
            
            // depth based rim mask
            float fragDepth = getDepth(UV);
            float3 normalView = normalize(mul((UNITY_MATRIX_V), normal).xyz);

            float depth = getDepth(UV + normalView.xy * _RimKernel * (0.9 - 0.9 * fragDepth));
            float depthDiff = abs(fragDepth - depth);
            float rim = saturate(depthDiff / max(0.0001, _RimThreshold));
            rim = smoothstep(0.03, 1.0, rim) * _RimScale;
            // light contributions
            float3 lightContribution = 0;

            
            float lambert = dot(normalize(normal), float3(0, 1, 0));
        #ifdef _UseHalfLambert
            float hlambert = lambert * 0.5 + 0.5;
        #else
            float hlambert = saturate(lambert);
        #endif
            
        #ifdef _UseRamp
            float3 colorDay = SAMPLE_TEXTURE2D(_ColorRamp, smp, float2(hlambert, 0.9)).xyz;
            float3 colorDusk = SAMPLE_TEXTURE2D(_ColorRamp, smp, float2(hlambert, 0.5)).xyz;
            float3 colorNight = SAMPLE_TEXTURE2D(_ColorRamp, smp, float2(hlambert, 0.1)).xyz;
            float star = voronoi3D(normalize(IN.positionWS) * _StarDensity * 10, voronoiNormal).x;
            colorNight = lerp(colorNight, lerp(colorNight, _StarColor.rgb, _StarColor.a * (sin((hash31(voronoiNormal) + _Time.y * _StarBlinkSpeed) * PI * 2.0) * 0.5 + 0.5)), step(star, _StarSize));
            float timeOfDay = 0.5 - dot(float3(0, 1, 0), light.direction) * 0.5;
            float interval = _ElapseInterval / 2.0;
            float3 color = lerp(colorDay, colorDusk, smoothstep(_DayTime - interval, _DayTime + interval, timeOfDay));
            color = lerp(color, colorNight, smoothstep(_NightTime - interval, _NightTime + interval, timeOfDay));

        #else
            float3 color = _Color.rgb * (getGain(hlambert, _ColorTransition) * 0.8 + 0.2);
        #endif
            float3 lighting = light.color;
            lambert = dot(normalize(normal), light.direction) * 0.5 + 0.5;
            lambert = getBias(lambert, 0.002) * 0.3 + 0.7;
            lightContribution += lighting * (color) * lambert;

            // draw sun
            float sunAngle = dot(normalize(IN.positionWS), light.direction);
            UV = IN.positionHCS.xy / _ScaledScreenParams.y;
            if (sunAngle > _InnerSize)
            {
                return half4(_SunColor.rgb * _SunIntensity * 10.0, 1.0);
            } else if (sunAngle > _InnerSize - _Fade)
            {
                float t = 1.0 - saturate((sunAngle - (_InnerSize - _Fade)) / _Fade);
                t = smoothstep(0.2, 0.8, t);
                return half4(lerp(_SunColor.rgb * _SunIntensity * 10.0, lightContribution, t), 1.0);
            }

            return half4(lightContribution, 1.0);
        }
        ENDHLSL

        Pass
        {
            Name "Paint"
            Tags { "RenderType" = "Background" "RenderPipeline" = "UniversalPipeline" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _UseRamp
            #pragma shader_feature _UseHalfLambert
            ENDHLSL
        }

    }
}