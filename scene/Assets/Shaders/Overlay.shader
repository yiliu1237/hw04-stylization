// This Unity shader reconstructs the world space positions for pixels using a depth
// texture and screen space UV coordinates. The shader draws a checkerboard pattern
// on a mesh to visualize the positions.
Shader "Custom/Overlay"
{
    Properties
    { 
        _Color1("Color 1", Color) = (1, 1, 1, 1)
        _Color2("Color 2", Color) = (1, 1, 1, 1)
        _Map1("Map 1", 2D) = "white" {}
        _Map2("Map 2", 2D) = "white" {}
    }

    // The SubShader block containing the Shader code.
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent+1"}
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Assets/Shaders/Common.hlsl"
            CBUFFER_START(UnityPerMaterial)
            float4 _Color1;
            float4 _Color2;
            CBUFFER_END

            TEXTURE2D(_Map1);
            SAMPLER(sampler_Map1);
            TEXTURE2D(_Map2);
            SAMPLER(sampler_Map2);

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 obj : TEXCOORD2;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.obj = IN.positionOS.xyz;
                return OUT;
            }

            float LinearEyeDepth(float depth)
            {
                return 1.0 / (_ProjectionParams.z * depth + _ProjectionParams.w);
            }

            float Linear01Depth(float depth)
        {
            float linearDepth = LinearEyeDepth(depth);
            return linearDepth / _ProjectionParams.y;
        }
        
            half4 frag(Varyings IN) : SV_Target
            {
                float2 UV = IN.positionHCS.xy / _ScaledScreenParams.xy;

                half3 normal1 = SAMPLE_TEXTURE2D(_Map1, sampler_Map1, IN.uv).xyz;
                half3 normal2 = SAMPLE_TEXTURE2D(_Map2, sampler_Map2, IN.uv).xyz;
                half3 depth = Linear01Depth(SampleSceneDepth(UV), _ZBufferParams);
                return half4(depth, 1.0); 
                return half4(linearLight(normal1, normal2), 1.0);
                return half4(linearLight(_Color1.rgb, _Color2.rgb), 1.0);
                return 0;
            }
            ENDHLSL
        }
    }
}