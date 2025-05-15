// This Unity shader reconstructs the world space positions for pixels using a depth
// texture and screen space UV coordinates. The shader draws a checkerboard pattern
// on a mesh to visualize the positions.
Shader "Custom/Caustics"
{
    Properties
    { 
        _Opacity("Caustic Opacity", Range(0, 1)) = 0.5
        _CausticScale("Caustic Scale", Range(0, 1)) = 0.5
        _CausticSpeed("Caustic Speed", Range(0, 1)) = 0.5
        _CausticAtten("Distance Fade", Range(0, 4)) = 2
        _Color("Caustic Color", Color) = (1, 1, 1, 1)
    }

    // The SubShader block containing the Shader code.
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags { "RenderType" = "Trasparent" "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent+1"}
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Front
        ZWrite Off
        ZTest Off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

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

            float _Opacity;
            float _CausticScale;
            float _CausticSpeed;
            float _CausticAtten;
            half4 _Color;
            float noise3D(float3 p)
            {
	            return frac(sin(dot(p ,float3(12.9898,78.233,126.7378))) * 43758.5453)*2.0-1.0;
            }

            float3 grad(float3 p)
            {
	            return float3(noise3D(p*1.00), noise3D(p*1.12), noise3D(p*1.23));
            }

            float perlin3D(float3 q)
            {
                float3 f = frac(q);
                float3 p = floor(q);
                f = f*f*(3.0-2.0*f);

	            float p0	= dot(grad(p), q-p);
	            float x 	= dot(grad(p+float3(1.0,0.0,0.0)), q-(p+float3(1.0,0.0,0.0)));
	            float y 	= dot(grad(p+float3(0.0,1.0,0.0)), q-(p+float3(0.0,1.0,0.0)));
	            float z 	= dot(grad(p+float3(0.0,0.0,1.0)), q-(p+float3(0.0,0.0,1.0)));
	            float xy	= dot(grad(p+float3(1.0,1.0,0.0)), q-(p+float3(1.0,1.0,0.0)));
	            float xz	= dot(grad(p+float3(1.0,0.0,1.0)), q-(p+float3(1.0,0.0,1.0)));
	            float yz	= dot(grad(p+float3(0.0,1.0,1.0)), q-(p+float3(0.0,1.0,1.0)));
	            float xyz	= dot(grad(p+1.0), q-(p+1.0));
	
                return lerp(	lerp(	lerp(p0, x, 	 f.x), 
                    	            lerp(y, 	xy,  f.x), 	f.y), 
               	            lerp(	lerp(z, 	xz,	 f.x), 
                    	            lerp(yz, xyz, f.x), 	f.y), 	f.z);
            }

            float2 worldToSphere(float3 p, float3 center, out float d)
            {
                float2 res = 0;
                d = distance(p, center);
                float3 dir = normalize(p - center);
                res.y = acos(dot(float3(0, dir.y, 0), float3(0, 1, 0))) / 3.14159265358979;
                res.x = (atan(dir.x/dir.z) / 6.28318530717959 + 1) / 2.0;
                return res;
            }

            // A simple water caustic effect.
            // David Hoskins.
            // License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

            // Inspired by akohdr's "Fluid Fields"
            // https://www.shadertoy.com/view/XsVSDm

            #define F length(.5-frac(v*

            void getCaustics(out float4 k, float3 p)
            {
                k = 1;
                k.xyz = p*(2.)/2e2 + _Time.y * 0.1 * _CausticSpeed;
                k.xyz += perlin3D(k.xyz + _Time.y * 0.2 * _CausticSpeed);
                float3 v = mul(k.xyz, float3x3(-2,-1,2, 3,-2,1, 1,2,2));
                // float3 v = k.xyz;
                float layer1 = length(.5-frac((v + 114.514) * 0.5));
                float layer2 = length(.5-frac((v + 1919.810) * 0.4));
                float layer3 = length(.5-frac((v + 3378.45818) * 0.3));
                k = pow(min(min(layer1,layer2),layer3), 7.)*25.;
                // k = k == 1 ? 1 : 1 - pow(2, -10 * k);
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                OUT.obj = IN.positionOS.xyz;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 color = 0;
                float2 UV = IN.positionHCS.xy / _ScaledScreenParams.xy;

                // Sample the depth from the Camera depth texture.
                #if UNITY_REVERSED_Z
                    real depth = SampleSceneDepth(UV);
                #else
                    // Adjust Z to match NDC for OpenGL ([-1, 1])
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif

                // Reconstruct the world space positions.
                float3 worldPos = ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);
                float3 objPos = mul(unity_WorldToObject, float4(worldPos, 1.0)).xyz;
                float d = 0;
                float2 pp = worldToSphere(objPos, float3(0, 0, 0), d);

                // caustics
                float4 caustics = 0;
                getCaustics(caustics, worldPos * 800 * _CausticScale);
                clip(0.5 - abs(objPos));

                caustics.w *= _Opacity * 0.4;

                // attenuate by distance
                caustics.w *= 1.0 / pow(distance(worldPos, _WorldSpaceCameraPos), _CausticAtten);
                caustics.w = clamp(caustics.w, 0, 0.1);

                // caustics.w = smoothstep(_CausticAtten * 0.1, 0.2, caustics.w);
                return caustics * _Color;
            }
            ENDHLSL
        }
    }
}