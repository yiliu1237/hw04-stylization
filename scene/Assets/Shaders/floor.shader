Shader "Custom/Floor"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}  
        [Toggle(_RANDOMHEIGHT)] _RandH ("Random Height", Float) = 1
        [Header(Tess)][Space]
     
        [KeywordEnum(integer, fractional_even, fractional_odd)]_Partitioning ("Partitioning Mode", Float) = 2
        [KeywordEnum(triangle_cw, triangle_ccw)]_Outputtopology ("Outputtopology Mode", Float) = 0
        [IntRange]_EdgeFactor ("EdgeFactor", Range(1,20)) = 20
        _TessMinDist ("TessMinDist", Range(0,100)) = 30.0
        _FadeDist ("FadeDist", Range(1,500)) = 200.0
        _HeightScale ("HeightScale", Range(1,50)) = 10.0
        _LandSpread ("LandSpread", Range(0.01, 0.3)) = 0.1
    }
    SubShader
    {
        Cull Off
        HLSLINCLUDE
        #include "Assets/Shaders/GrassCommon.hlsl"
        PatchTess PatchConstant (InputPatch<VertexOut,3> patch, uint patchID : SV_PrimitiveID){ 
            PatchTess o;
            float3 cameraPosWS = GetCameraPositionWS();
            real3 triVectexFactors = GetDistanceBasedTessFactor(patch[0].positionWS, patch[1].positionWS, patch[2].positionWS, cameraPosWS, _TessMinDist, _TessMinDist + _FadeDist);

            float4 tessFactors = _EdgeFactor * CalcTriTessFactorsFromEdgeTessFactors(triVectexFactors);
            o.edgeFactor[0] = max(1.0, tessFactors.x);
            o.edgeFactor[1] = max(1.0, tessFactors.y);
            o.edgeFactor[2] = max(1.0, tessFactors.z);

            o.insideFactor  = max(1.0, tessFactors.w);
            return o;
        }

        [domain("tri")]   
        #if _PARTITIONING_INTEGER
        [partitioning("integer")] 
        #elif _PARTITIONING_FRACTIONAL_EVEN
        [partitioning("fractional_even")] 
        #elif _PARTITIONING_FRACTIONAL_ODD
        [partitioning("fractional_odd")]    
        #endif 

        #if _OUTPUTTOPOLOGY_TRIANGLE_CW
        [outputtopology("triangle_cw")] 
        #elif _OUTPUTTOPOLOGY_TRIANGLE_CCW
        [outputtopology("triangle_ccw")] 
        #endif

        [patchconstantfunc("PatchConstant")] 
        [outputcontrolpoints(3)]                 
        [maxtessfactor(64.0f)]                 
        HullOut DistanceBasedTessControlPoint (InputPatch<VertexOut,3> patch,uint id : SV_OutputControlPointID){  
            HullOut o;
            o.positionWS = patch[id].positionWS;
            o.texcoord = patch[id].texcoord; 
            o.normal = patch[id].normal;
            return o;
        }

        // Terrain tesselation domain shader, tessellation based on distance
        [domain("tri")]   
        DomainOut DistanceBasedTessDomain_Terrain (PatchTess tessFactors, const OutputPatch<HullOut,3> patch, float3 bary : SV_DOMAINLOCATION)
        {  
            float3 positionWS = patch[0].positionWS * bary.x + patch[1].positionWS * bary.y + patch[2].positionWS * bary.z; 
            float2 texcoord   = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
            float2 xz = positionWS.xz * _LandSpread;
        #ifdef _RANDOMHEIGHT
            float heightScale = _HeightScale;
            float height = h(xz, heightScale);
            positionWS.y += height;
            float heightR = h(float2(xz.x + 0.01 * _LandSpread, xz.y), heightScale);
            float heightU = h(float2(xz.x, xz.y + 0.01 * _LandSpread), heightScale);
            float3 normal = normalize(cross(float3(0, heightU - height, 0.01), float3(0.01, heightR - height, 0)));
        #else
            float3 normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
        #endif
            DomainOut output;
            output.positionCS = TransformWorldToHClip(positionWS);
            output.texcoord = texcoord;
            output.positionWS = positionWS;
            output.normal = normal;

            return output; 
        }

        half4 DistanceBasedTessFrag_Terrain(DomainOut input) : SV_Target{   
            half3 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.positionWS.xz / (10.0 * _BaseMap_ST.xy) + _BaseMap_ST.zw).rgb;
            Light light = GetMainLight(TransformWorldToShadowCoord(input.positionWS));
            return half4(color * light.color * light.distanceAttenuation * light.shadowAttenuation, 1.0)*0.3; 
        }
        ENDHLSL

        pass 
        {
            Name "Terrain"
            Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" "Queue"="Geometry"}
            HLSLPROGRAM
            #pragma target 4.6 
            #pragma vertex DistanceBasedTessVert
            #pragma fragment DistanceBasedTessFrag_Terrain 
            #pragma hull DistanceBasedTessControlPoint
            #pragma domain DistanceBasedTessDomain_Terrain
            #pragma multi_compile _PARTITIONING_INTEGER _PARTITIONING_FRACTIONAL_EVEN _PARTITIONING_FRACTIONAL_ODD 
            #pragma multi_compile _OUTPUTTOPOLOGY_TRIANGLE_CW _OUTPUTTOPOLOGY_TRIANGLE_CCW 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影
            ENDHLSL
        }

        Pass
        { 
            Name "Terrain ShadowCaster"
            Tags { "LightMode" = "ShadowCaster"}
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 4.6 
            #pragma vertex DistanceBasedTessVert
            #pragma fragment ShadowCasterFragment
            #pragma hull DistanceBasedTessControlPoint
            #pragma domain DistanceBasedTessDomain_Terrain
            #pragma multi_compile _PARTITIONING_INTEGER _PARTITIONING_FRACTIONAL_EVEN _PARTITIONING_FRACTIONAL_ODD 
            #pragma multi_compile _OUTPUTTOPOLOGY_TRIANGLE_CW _OUTPUTTOPOLOGY_TRIANGLE_CCW 
            
            half4 ShadowCasterFragment(DomainOut input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
