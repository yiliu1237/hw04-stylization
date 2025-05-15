Shader "Unlit/StripStyle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _Tint ("Tint", Color) = (1,1,1,1)
        [HDR] _RimSpecularColor ("Rim Specular Color", Color) = (1,1,1,1)
        _RimSpecularFalloff ("Rim Specular Falloff", Range(0, 20)) = 5
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline"}
        LOD 100

        Pass
        {
            Tags {"LightMode"="SRPDefaultUnlit"}

            Stencil
            {
                Ref 38
                Comp always
                Pass replace
            }


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 posOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float3 normalWS : NORMAL;
                float3 posWS : TEXCOORD1;
                float4 pos : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            float3 _RimSpecularColor;
            float3 _Tint;
            float _RimSpecularFalloff;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.pos = TransformObjectToHClip(IN.posOS.xyz);
                OUT.posWS = TransformObjectToWorld(IN.posOS.xyz);
                OUT.uv = IN.uv;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {   
                // pre 
                float3 viewDir = GetWorldSpaceNormalizeViewDir(IN.posWS);
                Light mainLight = GetMainLight();
                float3 diffuseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;

                float NoL_unclamped = dot(IN.normalWS, mainLight.direction);
                float NoL = saturate(NoL_unclamped);
                float wrap = 0.5f;
                float NoL_wrap = (NoL_unclamped + wrap) / (1+wrap);
                float NoV = dot(IN.normalWS, viewDir);

                // diffuse
                float3 diffuse = NoL_wrap * diffuseColor * _Tint;

                // rim specular
                float fre = pow(1-NoV, _RimSpecularFalloff);

                //float3 rim = fre * _RimSpecularColor * NoL;
                float3 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).rgb;
                float3 rim = fre * texColor * NoL * 280.0;
                
                half3 col = diffuse + rim;
                //half3 col = (diffuse + rim) * 3.0; // Or higher, 10.0 if subtle

                return half4(col, 1);
            }
            ENDHLSL
        }

        //Pass
        //{
        //    Tags { "Queue"="Transparent" "RenderType"="Transparent+10"}

        //    ZWrite On
        //    Cull Back

        //    HLSLPROGRAM
        //    #pragma vertex vert
        //    #pragma fragment frag

        //    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        //    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"

        //    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


        //    struct Attributes
        //    {
        //        float4 posOS : POSITION;
        //        float3 normalOS : NORMAL;
        //        float2 uv : TEXCOORD0;
        //    };

        //    struct Varyings
        //    {
        //        float2 uv : TEXCOORD0;
        //        float3 normalWS : NORMAL;
        //        float3 posWS : TEXCOORD1;
        //        float4 pos : SV_POSITION;
        //        float2 posSS : TEXCOORD2;
        //    };

        //    CBUFFER_START(UnityPerMaterial)
        //    float4 _MainTex_ST;
        //    CBUFFER_END

        //    TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
        //    TEXTURE2D(_CameraOpaqueTexture);    SAMPLER(sampler_CameraOpaqueTexture);


        //    float3 _RimSpecularColor;

        //    Varyings vert (Attributes IN)
        //    {
        //        Varyings OUT;
        //        OUT.pos = TransformObjectToHClip(IN.posOS);
        //        OUT.posWS = TransformObjectToWorld(IN.posOS.xyz);
        //        OUT.uv = IN.uv;
        //        OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
        //        OUT.posSS = ComputeScreenPos(OUT.pos);
        //        return OUT;
        //    }

        //    half4 frag (Varyings IN) : SV_Target
        //    {   
        //        //float2 uv_screen = IN.pos / _ScaledScreenParams.xy;
        //        float2 uv_screen = IN.posSS.xy / IN.pos.w;
        //        float3 sceneColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, uv_screen).rgb;

        //        float3 col = sceneColor;

        //        return half4(col, 1);
        //    }
            //ENDHLSL
        //}
    }
}
