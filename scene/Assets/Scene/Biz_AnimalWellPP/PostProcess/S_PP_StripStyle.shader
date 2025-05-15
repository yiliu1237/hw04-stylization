Shader "PostProcess/StripStyle"
{
    Properties
    {
        _StripTint_EdgeColor("StripTint_EdgeColor", Color) = (0.5028281, 0.1205845, 0.572327, 0)
        _StripTint_MidColor("StripTint_MidColor", Color) = (0.05345905, 0.5064465, 1, 0)
        Strip_RollSpeed("Strip_RollSpeed", Float) = 5
        _Strip_Width("Strip_Width", Range(0, 1)) = 0.65
        _Strip_Opacity("Strip_Opacity", Float) = 0.37
        _Strip_Color1("Strip_Color1", Color) = (1, 0, 0, 0)
        _Strip_Color0("Strip_Color0", Color) = (0.8836478, 0.926985, 1, 0)
        _Strip_Count("Strip_Count", Float) = 80
        _PixelSize("PixelSize", Float) = 1
        _RimSpecular_Smooth("RimSpecular_Smooth", Range(0, 0.5)) = 0.1
        _RimSpecular_Threshold("RimSpecular_Threshold", Range(0, 1)) = 0.44
        _RimSpecular_Color("RimSpecular_Color", Color) = (1, 0.3679244, 0.8707018, 0)
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            // RenderType: <None>
            // Queue: <None>
            // DisableBatching: <None>
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalFullscreenSubTarget"
        }



        Pass
        {
            Name "DrawProcedural"
        
        // Render State
        Cull Off
        Blend Off
        ZTest Off
        ZWrite Off

        
        // Debug
        // <None>


        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag
        // #pragma enable_d3d11_debug_symbols
        
        /* WARNING: $splice Could not find named fragment 'DotsInstancingOptions' */
        /* WARNING: $splice Could not find named fragment 'HybridV1InjectedBuiltinProperties' */
        
        // Keywords
        #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
        // GraphKeywords: <None>
        
        #define FULLSCREEN_SHADERGRAPH
        
        // Defines
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_VERTEXID
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD1
        
        // Force depth texture because we need it for almost every nodes
        // TODO: dependency system that triggers this define from position or view direction usage
        #define REQUIRE_DEPTH_TEXTURE
        #define REQUIRE_NORMAL_TEXTURE
        
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DRAWPROCEDURAL
        #define REQUIRE_OPAQUE_TEXTURE
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.shadergraph/Editor/Generation/Targets/Fullscreen/Includes/FullscreenShaderPass.cs.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
             uint vertexID : VERTEXID_SEMANTIC;
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float4 ScreenPosition;
             float2 NDCPosition;
             float2 PixelPosition;
             float3 TimeParameters;
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
             float4 texCoord1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
        };
        struct VertexDescriptionInputs
        {
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0 : INTERP0;
             float4 texCoord1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.texCoord0.xyzw = input.texCoord0;
            output.texCoord1.xyzw = input.texCoord1;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.texCoord0.xyzw;
            output.texCoord1 = input.texCoord1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float _Strip_Width;
        float _Strip_Count;
        float4 _Strip_Color1;
        float4 _Strip_Color0;
        float _Strip_Opacity;
        float _PixelSize;
        float4 _RimSpecular_Color;
        float _RimSpecular_Smooth;
        float _RimSpecular_Threshold;
        float Strip_RollSpeed;
        float4 _StripTint_MidColor;
        float4 _StripTint_EdgeColor;
        CBUFFER_END
        
        
        // Object and Global properties
        float _FlipY;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // Graph Functions
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Divide_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A / B;
        }
        
        void Unity_Floor_float2(float2 In, out float2 Out)
        {
            Out = floor(In);
        }
        
        void Unity_ChannelMask_RedGreen_float4 (float4 In, out float4 Out)
        {
            Out = float4(In.r, In.g, 0, 0);
        }
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        float3 Unity_Universal_SampleBuffer_NormalWorldSpace_float(float2 uv)
        {
            return SHADERGRAPH_SAMPLE_SCENE_NORMAL(uv);
        }
        
        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void MainLightDirection_float(out float3 Direction)
        {
            #if SHADERGRAPH_PREVIEW
            Direction = half3(-0.5, -0.5, 0);
            #else
            Direction = SHADERGRAPH_MAIN_LIGHT_DIRECTION();
            #endif
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_SceneColor_float(float4 UV, out float3 Out)
        {
            Out = SHADERGRAPH_SAMPLE_SCENE_COLOR(UV.xy);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_Fraction_float(float In, out float Out)
        {
            Out = frac(In);
        }
        
        void Unity_Step_float(float Edge, float In, out float Out)
        {
            Out = step(Edge, In);
        }
        
        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }
        
        // unity-custom-func-begin
        void Lerp3Color_float(float3 color1, float3 color2, float3 color3, float a, out float3 res){
            float3 lerp0 = lerp(color1, color2, saturate(a * 2));
            
            float3 lerp1 = lerp(lerp0, color3, saturate(a * 2 - 1));
            
            
            res = lerp1;
        }
        // unity-custom-func-end
        
        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        // GraphVertex: <None>
        
        // Custom interpolators, pre surface
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreSurface' */
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _Property_a21f5cb648d7454dbf971dc1d64e6df2_Out_0_Float = _RimSpecular_Threshold;
            float _Property_754594d730094b8e823fed750f32351a_Out_0_Float = _RimSpecular_Smooth;
            float _Add_b9daa183bfdc414fa2549bed88ae9653_Out_2_Float;
            Unity_Add_float(_Property_a21f5cb648d7454dbf971dc1d64e6df2_Out_0_Float, _Property_754594d730094b8e823fed750f32351a_Out_0_Float, _Add_b9daa183bfdc414fa2549bed88ae9653_Out_2_Float);
            float2 _Vector2_7d896c06c5e74647b69018d0c136900c_Out_0_Vector2 = float2(_ScreenParams.x, _ScreenParams.y);
            float _Property_a746ee9fefb64dfba7f2f088edb57668_Out_0_Float = _PixelSize;
            float2 _Divide_81880d2fc5be4b3c95f2bc08b787dac6_Out_2_Vector2;
            Unity_Divide_float2(_Vector2_7d896c06c5e74647b69018d0c136900c_Out_0_Vector2, (_Property_a746ee9fefb64dfba7f2f088edb57668_Out_0_Float.xx), _Divide_81880d2fc5be4b3c95f2bc08b787dac6_Out_2_Vector2);
            float2 _Floor_ce8308b3cd5b4554bd5bb4788bbbbb82_Out_1_Vector2;
            Unity_Floor_float2(_Divide_81880d2fc5be4b3c95f2bc08b787dac6_Out_2_Vector2, _Floor_ce8308b3cd5b4554bd5bb4788bbbbb82_Out_1_Vector2);
            float4 _ScreenPosition_4f3dbf2b096d4227b80570b79a58df74_Out_0_Vector4 = float4(IN.NDCPosition.xy, 0, 0);
            float4 _ChannelMask_a9bb80b099c147aaa67e657d6166af90_Out_1_Vector4;
            Unity_ChannelMask_RedGreen_float4 (_ScreenPosition_4f3dbf2b096d4227b80570b79a58df74_Out_0_Vector4, _ChannelMask_a9bb80b099c147aaa67e657d6166af90_Out_1_Vector4);
            float2 _Multiply_35e43059dd764f59b8f54b3e37604417_Out_2_Vector2;
            Unity_Multiply_float2_float2(_Floor_ce8308b3cd5b4554bd5bb4788bbbbb82_Out_1_Vector2, (_ChannelMask_a9bb80b099c147aaa67e657d6166af90_Out_1_Vector4.xy), _Multiply_35e43059dd764f59b8f54b3e37604417_Out_2_Vector2);
            float2 _Floor_d261b52c1dbf45818ad7fc31b98cdbb1_Out_1_Vector2;
            Unity_Floor_float2(_Multiply_35e43059dd764f59b8f54b3e37604417_Out_2_Vector2, _Floor_d261b52c1dbf45818ad7fc31b98cdbb1_Out_1_Vector2);
            float _Float_8fa512e39dcd47e6a6bede9d5396fe62_Out_0_Float = 0.5;
            float2 _Add_1f4bddb2021d4491941be7176d6a16f7_Out_2_Vector2;
            Unity_Add_float2(_Floor_d261b52c1dbf45818ad7fc31b98cdbb1_Out_1_Vector2, (_Float_8fa512e39dcd47e6a6bede9d5396fe62_Out_0_Float.xx), _Add_1f4bddb2021d4491941be7176d6a16f7_Out_2_Vector2);
            float2 _Divide_1a101e035c9c4100a1aca7e055d5c8dc_Out_2_Vector2;
            Unity_Divide_float2(_Add_1f4bddb2021d4491941be7176d6a16f7_Out_2_Vector2, _Floor_ce8308b3cd5b4554bd5bb4788bbbbb82_Out_1_Vector2, _Divide_1a101e035c9c4100a1aca7e055d5c8dc_Out_2_Vector2);
            float3 _URPSampleBuffer_21080ec62eac4d82bc547dea4c4365ba_Output_2_Vector3 = Unity_Universal_SampleBuffer_NormalWorldSpace_float((float4(_Divide_1a101e035c9c4100a1aca7e055d5c8dc_Out_2_Vector2, 0.0, 1.0)).xy);
            float _DotProduct_0521e1c9fa624303bf856035b383adc2_Out_2_Float;
            Unity_DotProduct_float3(IN.WorldSpaceViewDirection, _URPSampleBuffer_21080ec62eac4d82bc547dea4c4365ba_Output_2_Vector3, _DotProduct_0521e1c9fa624303bf856035b383adc2_Out_2_Float);
            float _OneMinus_47c2f4962ff7471b8a6ab37daea43d61_Out_1_Float;
            Unity_OneMinus_float(_DotProduct_0521e1c9fa624303bf856035b383adc2_Out_2_Float, _OneMinus_47c2f4962ff7471b8a6ab37daea43d61_Out_1_Float);
            float _Saturate_f96ce320a29e4b7398cbdefcf7cae183_Out_1_Float;
            Unity_Saturate_float(_OneMinus_47c2f4962ff7471b8a6ab37daea43d61_Out_1_Float, _Saturate_f96ce320a29e4b7398cbdefcf7cae183_Out_1_Float);
            float3 _MainLightDirection_a5d6386cb9e3444fadc9a3458f3648df_Direction_0_Vector3;
            MainLightDirection_float(_MainLightDirection_a5d6386cb9e3444fadc9a3458f3648df_Direction_0_Vector3);
            float3 _Multiply_c4771fb7aad44e27b61b31f21a920ca3_Out_2_Vector3;
            Unity_Multiply_float3_float3(_MainLightDirection_a5d6386cb9e3444fadc9a3458f3648df_Direction_0_Vector3, float3(-1, -1, -1), _Multiply_c4771fb7aad44e27b61b31f21a920ca3_Out_2_Vector3);
            float _DotProduct_e156249b30be4535bb4ea93321c29c8f_Out_2_Float;
            Unity_DotProduct_float3(_Multiply_c4771fb7aad44e27b61b31f21a920ca3_Out_2_Vector3, _URPSampleBuffer_21080ec62eac4d82bc547dea4c4365ba_Output_2_Vector3, _DotProduct_e156249b30be4535bb4ea93321c29c8f_Out_2_Float);
            float _Saturate_719c0687bb0247c88379173967bfd3de_Out_1_Float;
            Unity_Saturate_float(_DotProduct_e156249b30be4535bb4ea93321c29c8f_Out_2_Float, _Saturate_719c0687bb0247c88379173967bfd3de_Out_1_Float);
            float _Multiply_79e22826d0f44ed7834d306522c3bc9d_Out_2_Float;
            Unity_Multiply_float_float(_Saturate_f96ce320a29e4b7398cbdefcf7cae183_Out_1_Float, _Saturate_719c0687bb0247c88379173967bfd3de_Out_1_Float, _Multiply_79e22826d0f44ed7834d306522c3bc9d_Out_2_Float);
            float _Smoothstep_919cbb49d77c41608d08df7091fc3a9a_Out_3_Float;
            Unity_Smoothstep_float(_Property_a21f5cb648d7454dbf971dc1d64e6df2_Out_0_Float, _Add_b9daa183bfdc414fa2549bed88ae9653_Out_2_Float, _Multiply_79e22826d0f44ed7834d306522c3bc9d_Out_2_Float, _Smoothstep_919cbb49d77c41608d08df7091fc3a9a_Out_3_Float);
            float4 _Property_3616eb3d089d4c078c29d9014de06b04_Out_0_Vector4 = _RimSpecular_Color;
            float4 _Multiply_3c8a7ec4511d497b8022d70229e4c003_Out_2_Vector4;
            Unity_Multiply_float4_float4((_Smoothstep_919cbb49d77c41608d08df7091fc3a9a_Out_3_Float.xxxx), _Property_3616eb3d089d4c078c29d9014de06b04_Out_0_Vector4, _Multiply_3c8a7ec4511d497b8022d70229e4c003_Out_2_Vector4);
            float3 _SceneColor_9fa895d443cd4f75937aefcf0541824f_Out_1_Vector3;
            Unity_SceneColor_float((float4(_Divide_1a101e035c9c4100a1aca7e055d5c8dc_Out_2_Vector2, 0.0, 1.0)), _SceneColor_9fa895d443cd4f75937aefcf0541824f_Out_1_Vector3);
            float3 _Add_db4e089dcdac42b5958ca09b966f3d37_Out_2_Vector3;
            Unity_Add_float3((_Multiply_3c8a7ec4511d497b8022d70229e4c003_Out_2_Vector4.xyz), _SceneColor_9fa895d443cd4f75937aefcf0541824f_Out_1_Vector3, _Add_db4e089dcdac42b5958ca09b966f3d37_Out_2_Vector3);
            float4 _Property_2fdf8602c5554e0c936dfce65db76da9_Out_0_Vector4 = _Strip_Color0;
            float4 _Property_4f618932163d41a990705f5a71e41f60_Out_0_Vector4 = _Strip_Color1;
            float _Property_ad3774d2594848c0a3a7713a4c2c0936_Out_0_Float = _Strip_Width;
            float _Float_774a58fb654e4fc6a933982955bc7a58_Out_0_Float = _Property_ad3774d2594848c0a3a7713a4c2c0936_Out_0_Float;
            float4 _ScreenPosition_1b9224dec662470ebc239c01139f523b_Out_0_Vector4 = float4(IN.NDCPosition.xy, 0, 0);
            float _Swizzle_3b2ecf4ffff74ba5b31da466e60f6a70_Out_1_Float = _ScreenPosition_1b9224dec662470ebc239c01139f523b_Out_0_Vector4.y;
            float _Property_4aa17006e5314e58ad20907c00021e4a_Out_0_Float = Strip_RollSpeed;
            float _Multiply_d0bc335bcad94f2a8fd77e18ceaf5ee3_Out_2_Float;
            Unity_Multiply_float_float(_Property_4aa17006e5314e58ad20907c00021e4a_Out_0_Float, 0.01, _Multiply_d0bc335bcad94f2a8fd77e18ceaf5ee3_Out_2_Float);
            float _Multiply_e876087813b844a68bd211c1e9fb6823_Out_2_Float;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Multiply_d0bc335bcad94f2a8fd77e18ceaf5ee3_Out_2_Float, _Multiply_e876087813b844a68bd211c1e9fb6823_Out_2_Float);
            float _Add_57d171c6b8dd4222aaefd5163e71c5bd_Out_2_Float;
            Unity_Add_float(_Swizzle_3b2ecf4ffff74ba5b31da466e60f6a70_Out_1_Float, _Multiply_e876087813b844a68bd211c1e9fb6823_Out_2_Float, _Add_57d171c6b8dd4222aaefd5163e71c5bd_Out_2_Float);
            float _Fraction_9d451f02d74b4ce88355dd255137a5fa_Out_1_Float;
            Unity_Fraction_float(_Add_57d171c6b8dd4222aaefd5163e71c5bd_Out_2_Float, _Fraction_9d451f02d74b4ce88355dd255137a5fa_Out_1_Float);
            float _Property_6752ce85ca7f44f6bc1f73147e3b7438_Out_0_Float = _Strip_Count;
            float _Float_c56c22f902de4f619c0bf5af3c77f773_Out_0_Float = _Property_6752ce85ca7f44f6bc1f73147e3b7438_Out_0_Float;
            float _Multiply_9feb12d7c35d4dc8903876bacfea9988_Out_2_Float;
            Unity_Multiply_float_float(_Fraction_9d451f02d74b4ce88355dd255137a5fa_Out_1_Float, _Float_c56c22f902de4f619c0bf5af3c77f773_Out_0_Float, _Multiply_9feb12d7c35d4dc8903876bacfea9988_Out_2_Float);
            float _Fraction_f46915db6b204b00afd4f5bdb536e803_Out_1_Float;
            Unity_Fraction_float(_Multiply_9feb12d7c35d4dc8903876bacfea9988_Out_2_Float, _Fraction_f46915db6b204b00afd4f5bdb536e803_Out_1_Float);
            float _Step_2915494ac90041cdb6d11dd595aa4bed_Out_2_Float;
            Unity_Step_float(_Float_774a58fb654e4fc6a933982955bc7a58_Out_0_Float, _Fraction_f46915db6b204b00afd4f5bdb536e803_Out_1_Float, _Step_2915494ac90041cdb6d11dd595aa4bed_Out_2_Float);
            float4 _Lerp_fa678a7ff69e49df9729d7e77bbafd13_Out_3_Vector4;
            Unity_Lerp_float4(_Property_2fdf8602c5554e0c936dfce65db76da9_Out_0_Vector4, _Property_4f618932163d41a990705f5a71e41f60_Out_0_Vector4, (_Step_2915494ac90041cdb6d11dd595aa4bed_Out_2_Float.xxxx), _Lerp_fa678a7ff69e49df9729d7e77bbafd13_Out_3_Vector4);
            float4 _Property_eb940b75c2f041f4bd6fc0cab0637a58_Out_0_Vector4 = _StripTint_EdgeColor;
            float4 _Property_924d5e0256f4471aac8fe74a82ca9164_Out_0_Vector4 = _StripTint_MidColor;
            float3 _Lerp3ColorCustomFunction_afcbeae46463473a86846aa74d940b8c_res_4_Vector3;
            Lerp3Color_float((_Property_eb940b75c2f041f4bd6fc0cab0637a58_Out_0_Vector4.xyz), (_Property_924d5e0256f4471aac8fe74a82ca9164_Out_0_Vector4.xyz), (_Property_eb940b75c2f041f4bd6fc0cab0637a58_Out_0_Vector4.xyz), _Fraction_9d451f02d74b4ce88355dd255137a5fa_Out_1_Float, _Lerp3ColorCustomFunction_afcbeae46463473a86846aa74d940b8c_res_4_Vector3);
            float3 _Multiply_dcd4fe58eb1146e0b05f4908789d0180_Out_2_Vector3;
            Unity_Multiply_float3_float3((_Lerp_fa678a7ff69e49df9729d7e77bbafd13_Out_3_Vector4.xyz), _Lerp3ColorCustomFunction_afcbeae46463473a86846aa74d940b8c_res_4_Vector3, _Multiply_dcd4fe58eb1146e0b05f4908789d0180_Out_2_Vector3);
            float _Property_806e15bae9ce42509dd08e46b888865b_Out_0_Float = _Strip_Opacity;
            float3 _Lerp_7bbeea05e07e4dd1bd3a2c856fc56c03_Out_3_Vector3;
            Unity_Lerp_float3(_Add_db4e089dcdac42b5958ca09b966f3d37_Out_2_Vector3, _Multiply_dcd4fe58eb1146e0b05f4908789d0180_Out_2_Vector3, (_Property_806e15bae9ce42509dd08e46b888865b_Out_0_Float.xxx), _Lerp_7bbeea05e07e4dd1bd3a2c856fc56c03_Out_3_Vector3);
            surface.BaseColor = _Lerp_7bbeea05e07e4dd1bd3a2c856fc56c03_Out_3_Vector3;
            surface.Alpha = 1;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
            float3 normalWS = SHADERGRAPH_SAMPLE_SCENE_NORMAL(input.texCoord0.xy);
            float4 tangentWS = float4(0, 1, 0, 0); // We can't access the tangent in screen space
        
        
        
        
            float3 viewDirWS = normalize(input.texCoord1.xyz);
            float linearDepth = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(input.texCoord0.xy), _ZBufferParams);
            float3 cameraForward = -UNITY_MATRIX_V[2].xyz;
            float camearDistance = linearDepth / dot(viewDirWS, cameraForward);
            float3 positionWS = viewDirWS * camearDistance + GetCameraPositionWS();
        
            output.WorldSpaceViewDirection = normalize(viewDirWS);
        
            output.WorldSpacePosition = positionWS;
            output.ScreenPosition = float4(input.texCoord0.xy, 0, 1);
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
            output.NDCPosition = input.texCoord0.xy;
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.shadergraph/Editor/Generation/Targets/Fullscreen/Includes/FullscreenCommon.hlsl"
        #include "Packages/com.unity.shadergraph/Editor/Generation/Targets/Fullscreen/Includes/FullscreenDrawProcedural.hlsl"
        
        ENDHLSL
        }
        Pass
        {
            Name "Blit"
        
        // Render State
        Cull Off
        Blend Off
        ZTest Off
        ZWrite Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag
        // #pragma enable_d3d11_debug_symbols
        
        /* WARNING: $splice Could not find named fragment 'DotsInstancingOptions' */
        /* WARNING: $splice Could not find named fragment 'HybridV1InjectedBuiltinProperties' */
        
        // Keywords
        #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
        // GraphKeywords: <None>
        
        #define FULLSCREEN_SHADERGRAPH
        
        // Defines
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_VERTEXID
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD1
        
        // Force depth texture because we need it for almost every nodes
        // TODO: dependency system that triggers this define from position or view direction usage
        #define REQUIRE_DEPTH_TEXTURE
        #define REQUIRE_NORMAL_TEXTURE
        
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_BLIT
        #define REQUIRE_OPAQUE_TEXTURE
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.shadergraph/Editor/Generation/Targets/Fullscreen/Includes/FullscreenShaderPass.cs.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
             uint vertexID : VERTEXID_SEMANTIC;
             float3 positionOS : POSITION;
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpaceViewDirection;
             float3 WorldSpacePosition;
             float4 ScreenPosition;
             float2 NDCPosition;
             float2 PixelPosition;
             float3 TimeParameters;
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
             float4 texCoord1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
        };
        struct VertexDescriptionInputs
        {
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0 : INTERP0;
             float4 texCoord1 : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.texCoord0.xyzw = input.texCoord0;
            output.texCoord1.xyzw = input.texCoord1;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.texCoord0.xyzw;
            output.texCoord1 = input.texCoord1.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float _Strip_Width;
        float _Strip_Count;
        float4 _Strip_Color1;
        float4 _Strip_Color0;
        float _Strip_Opacity;
        float _PixelSize;
        float4 _RimSpecular_Color;
        float _RimSpecular_Smooth;
        float _RimSpecular_Threshold;
        float Strip_RollSpeed;
        float4 _StripTint_MidColor;
        float4 _StripTint_EdgeColor;
        CBUFFER_END
        
        
        // Object and Global properties
        float _FlipY;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // Graph Functions
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Divide_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A / B;
        }
        
        void Unity_Floor_float2(float2 In, out float2 Out)
        {
            Out = floor(In);
        }
        
        void Unity_ChannelMask_RedGreen_float4 (float4 In, out float4 Out)
        {
            Out = float4(In.r, In.g, 0, 0);
        }
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        float3 Unity_Universal_SampleBuffer_NormalWorldSpace_float(float2 uv)
        {
            return SHADERGRAPH_SAMPLE_SCENE_NORMAL(uv);
        }
        
        void Unity_DotProduct_float3(float3 A, float3 B, out float Out)
        {
            Out = dot(A, B);
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }
        
        void MainLightDirection_float(out float3 Direction)
        {
            #if SHADERGRAPH_PREVIEW
            Direction = half3(-0.5, -0.5, 0);
            #else
            Direction = SHADERGRAPH_MAIN_LIGHT_DIRECTION();
            #endif
        }
        
        void Unity_Multiply_float3_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_SceneColor_float(float4 UV, out float3 Out)
        {
            Out = SHADERGRAPH_SAMPLE_SCENE_COLOR(UV.xy);
        }
        
        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }
        
        void Unity_Fraction_float(float In, out float Out)
        {
            Out = frac(In);
        }
        
        void Unity_Step_float(float Edge, float In, out float Out)
        {
            Out = step(Edge, In);
        }
        
        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }
        
        // unity-custom-func-begin
        void Lerp3Color_float(float3 color1, float3 color2, float3 color3, float a, out float3 res){
            float3 lerp0 = lerp(color1, color2, saturate(a * 2));
            
            float3 lerp1 = lerp(lerp0, color3, saturate(a * 2 - 1));
            
            
            res = lerp1;
        }
        // unity-custom-func-end
        
        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        // GraphVertex: <None>
        
        // Custom interpolators, pre surface
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreSurface' */
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _Property_a21f5cb648d7454dbf971dc1d64e6df2_Out_0_Float = _RimSpecular_Threshold;
            float _Property_754594d730094b8e823fed750f32351a_Out_0_Float = _RimSpecular_Smooth;
            float _Add_b9daa183bfdc414fa2549bed88ae9653_Out_2_Float;
            Unity_Add_float(_Property_a21f5cb648d7454dbf971dc1d64e6df2_Out_0_Float, _Property_754594d730094b8e823fed750f32351a_Out_0_Float, _Add_b9daa183bfdc414fa2549bed88ae9653_Out_2_Float);
            float2 _Vector2_7d896c06c5e74647b69018d0c136900c_Out_0_Vector2 = float2(_ScreenParams.x, _ScreenParams.y);
            float _Property_a746ee9fefb64dfba7f2f088edb57668_Out_0_Float = _PixelSize;
            float2 _Divide_81880d2fc5be4b3c95f2bc08b787dac6_Out_2_Vector2;
            Unity_Divide_float2(_Vector2_7d896c06c5e74647b69018d0c136900c_Out_0_Vector2, (_Property_a746ee9fefb64dfba7f2f088edb57668_Out_0_Float.xx), _Divide_81880d2fc5be4b3c95f2bc08b787dac6_Out_2_Vector2);
            float2 _Floor_ce8308b3cd5b4554bd5bb4788bbbbb82_Out_1_Vector2;
            Unity_Floor_float2(_Divide_81880d2fc5be4b3c95f2bc08b787dac6_Out_2_Vector2, _Floor_ce8308b3cd5b4554bd5bb4788bbbbb82_Out_1_Vector2);
            float4 _ScreenPosition_4f3dbf2b096d4227b80570b79a58df74_Out_0_Vector4 = float4(IN.NDCPosition.xy, 0, 0);
            float4 _ChannelMask_a9bb80b099c147aaa67e657d6166af90_Out_1_Vector4;
            Unity_ChannelMask_RedGreen_float4 (_ScreenPosition_4f3dbf2b096d4227b80570b79a58df74_Out_0_Vector4, _ChannelMask_a9bb80b099c147aaa67e657d6166af90_Out_1_Vector4);
            float2 _Multiply_35e43059dd764f59b8f54b3e37604417_Out_2_Vector2;
            Unity_Multiply_float2_float2(_Floor_ce8308b3cd5b4554bd5bb4788bbbbb82_Out_1_Vector2, (_ChannelMask_a9bb80b099c147aaa67e657d6166af90_Out_1_Vector4.xy), _Multiply_35e43059dd764f59b8f54b3e37604417_Out_2_Vector2);
            float2 _Floor_d261b52c1dbf45818ad7fc31b98cdbb1_Out_1_Vector2;
            Unity_Floor_float2(_Multiply_35e43059dd764f59b8f54b3e37604417_Out_2_Vector2, _Floor_d261b52c1dbf45818ad7fc31b98cdbb1_Out_1_Vector2);
            float _Float_8fa512e39dcd47e6a6bede9d5396fe62_Out_0_Float = 0.5;
            float2 _Add_1f4bddb2021d4491941be7176d6a16f7_Out_2_Vector2;
            Unity_Add_float2(_Floor_d261b52c1dbf45818ad7fc31b98cdbb1_Out_1_Vector2, (_Float_8fa512e39dcd47e6a6bede9d5396fe62_Out_0_Float.xx), _Add_1f4bddb2021d4491941be7176d6a16f7_Out_2_Vector2);
            float2 _Divide_1a101e035c9c4100a1aca7e055d5c8dc_Out_2_Vector2;
            Unity_Divide_float2(_Add_1f4bddb2021d4491941be7176d6a16f7_Out_2_Vector2, _Floor_ce8308b3cd5b4554bd5bb4788bbbbb82_Out_1_Vector2, _Divide_1a101e035c9c4100a1aca7e055d5c8dc_Out_2_Vector2);
            float3 _URPSampleBuffer_21080ec62eac4d82bc547dea4c4365ba_Output_2_Vector3 = Unity_Universal_SampleBuffer_NormalWorldSpace_float((float4(_Divide_1a101e035c9c4100a1aca7e055d5c8dc_Out_2_Vector2, 0.0, 1.0)).xy);
            float _DotProduct_0521e1c9fa624303bf856035b383adc2_Out_2_Float;
            Unity_DotProduct_float3(IN.WorldSpaceViewDirection, _URPSampleBuffer_21080ec62eac4d82bc547dea4c4365ba_Output_2_Vector3, _DotProduct_0521e1c9fa624303bf856035b383adc2_Out_2_Float);
            float _OneMinus_47c2f4962ff7471b8a6ab37daea43d61_Out_1_Float;
            Unity_OneMinus_float(_DotProduct_0521e1c9fa624303bf856035b383adc2_Out_2_Float, _OneMinus_47c2f4962ff7471b8a6ab37daea43d61_Out_1_Float);
            float _Saturate_f96ce320a29e4b7398cbdefcf7cae183_Out_1_Float;
            Unity_Saturate_float(_OneMinus_47c2f4962ff7471b8a6ab37daea43d61_Out_1_Float, _Saturate_f96ce320a29e4b7398cbdefcf7cae183_Out_1_Float);
            float3 _MainLightDirection_a5d6386cb9e3444fadc9a3458f3648df_Direction_0_Vector3;
            MainLightDirection_float(_MainLightDirection_a5d6386cb9e3444fadc9a3458f3648df_Direction_0_Vector3);
            float3 _Multiply_c4771fb7aad44e27b61b31f21a920ca3_Out_2_Vector3;
            Unity_Multiply_float3_float3(_MainLightDirection_a5d6386cb9e3444fadc9a3458f3648df_Direction_0_Vector3, float3(-1, -1, -1), _Multiply_c4771fb7aad44e27b61b31f21a920ca3_Out_2_Vector3);
            float _DotProduct_e156249b30be4535bb4ea93321c29c8f_Out_2_Float;
            Unity_DotProduct_float3(_Multiply_c4771fb7aad44e27b61b31f21a920ca3_Out_2_Vector3, _URPSampleBuffer_21080ec62eac4d82bc547dea4c4365ba_Output_2_Vector3, _DotProduct_e156249b30be4535bb4ea93321c29c8f_Out_2_Float);
            float _Saturate_719c0687bb0247c88379173967bfd3de_Out_1_Float;
            Unity_Saturate_float(_DotProduct_e156249b30be4535bb4ea93321c29c8f_Out_2_Float, _Saturate_719c0687bb0247c88379173967bfd3de_Out_1_Float);
            float _Multiply_79e22826d0f44ed7834d306522c3bc9d_Out_2_Float;
            Unity_Multiply_float_float(_Saturate_f96ce320a29e4b7398cbdefcf7cae183_Out_1_Float, _Saturate_719c0687bb0247c88379173967bfd3de_Out_1_Float, _Multiply_79e22826d0f44ed7834d306522c3bc9d_Out_2_Float);
            float _Smoothstep_919cbb49d77c41608d08df7091fc3a9a_Out_3_Float;
            Unity_Smoothstep_float(_Property_a21f5cb648d7454dbf971dc1d64e6df2_Out_0_Float, _Add_b9daa183bfdc414fa2549bed88ae9653_Out_2_Float, _Multiply_79e22826d0f44ed7834d306522c3bc9d_Out_2_Float, _Smoothstep_919cbb49d77c41608d08df7091fc3a9a_Out_3_Float);
            float4 _Property_3616eb3d089d4c078c29d9014de06b04_Out_0_Vector4 = _RimSpecular_Color;
            float4 _Multiply_3c8a7ec4511d497b8022d70229e4c003_Out_2_Vector4;
            Unity_Multiply_float4_float4((_Smoothstep_919cbb49d77c41608d08df7091fc3a9a_Out_3_Float.xxxx), _Property_3616eb3d089d4c078c29d9014de06b04_Out_0_Vector4, _Multiply_3c8a7ec4511d497b8022d70229e4c003_Out_2_Vector4);
            float3 _SceneColor_9fa895d443cd4f75937aefcf0541824f_Out_1_Vector3;
            Unity_SceneColor_float((float4(_Divide_1a101e035c9c4100a1aca7e055d5c8dc_Out_2_Vector2, 0.0, 1.0)), _SceneColor_9fa895d443cd4f75937aefcf0541824f_Out_1_Vector3);
            float3 _Add_db4e089dcdac42b5958ca09b966f3d37_Out_2_Vector3;
            Unity_Add_float3((_Multiply_3c8a7ec4511d497b8022d70229e4c003_Out_2_Vector4.xyz), _SceneColor_9fa895d443cd4f75937aefcf0541824f_Out_1_Vector3, _Add_db4e089dcdac42b5958ca09b966f3d37_Out_2_Vector3);
            float4 _Property_2fdf8602c5554e0c936dfce65db76da9_Out_0_Vector4 = _Strip_Color0;
            float4 _Property_4f618932163d41a990705f5a71e41f60_Out_0_Vector4 = _Strip_Color1;
            float _Property_ad3774d2594848c0a3a7713a4c2c0936_Out_0_Float = _Strip_Width;
            float _Float_774a58fb654e4fc6a933982955bc7a58_Out_0_Float = _Property_ad3774d2594848c0a3a7713a4c2c0936_Out_0_Float;
            float4 _ScreenPosition_1b9224dec662470ebc239c01139f523b_Out_0_Vector4 = float4(IN.NDCPosition.xy, 0, 0);
            float _Swizzle_3b2ecf4ffff74ba5b31da466e60f6a70_Out_1_Float = _ScreenPosition_1b9224dec662470ebc239c01139f523b_Out_0_Vector4.y;
            float _Property_4aa17006e5314e58ad20907c00021e4a_Out_0_Float = Strip_RollSpeed;
            float _Multiply_d0bc335bcad94f2a8fd77e18ceaf5ee3_Out_2_Float;
            Unity_Multiply_float_float(_Property_4aa17006e5314e58ad20907c00021e4a_Out_0_Float, 0.01, _Multiply_d0bc335bcad94f2a8fd77e18ceaf5ee3_Out_2_Float);
            float _Multiply_e876087813b844a68bd211c1e9fb6823_Out_2_Float;
            Unity_Multiply_float_float(IN.TimeParameters.x, _Multiply_d0bc335bcad94f2a8fd77e18ceaf5ee3_Out_2_Float, _Multiply_e876087813b844a68bd211c1e9fb6823_Out_2_Float);
            float _Add_57d171c6b8dd4222aaefd5163e71c5bd_Out_2_Float;
            Unity_Add_float(_Swizzle_3b2ecf4ffff74ba5b31da466e60f6a70_Out_1_Float, _Multiply_e876087813b844a68bd211c1e9fb6823_Out_2_Float, _Add_57d171c6b8dd4222aaefd5163e71c5bd_Out_2_Float);
            float _Fraction_9d451f02d74b4ce88355dd255137a5fa_Out_1_Float;
            Unity_Fraction_float(_Add_57d171c6b8dd4222aaefd5163e71c5bd_Out_2_Float, _Fraction_9d451f02d74b4ce88355dd255137a5fa_Out_1_Float);
            float _Property_6752ce85ca7f44f6bc1f73147e3b7438_Out_0_Float = _Strip_Count;
            float _Float_c56c22f902de4f619c0bf5af3c77f773_Out_0_Float = _Property_6752ce85ca7f44f6bc1f73147e3b7438_Out_0_Float;
            float _Multiply_9feb12d7c35d4dc8903876bacfea9988_Out_2_Float;
            Unity_Multiply_float_float(_Fraction_9d451f02d74b4ce88355dd255137a5fa_Out_1_Float, _Float_c56c22f902de4f619c0bf5af3c77f773_Out_0_Float, _Multiply_9feb12d7c35d4dc8903876bacfea9988_Out_2_Float);
            float _Fraction_f46915db6b204b00afd4f5bdb536e803_Out_1_Float;
            Unity_Fraction_float(_Multiply_9feb12d7c35d4dc8903876bacfea9988_Out_2_Float, _Fraction_f46915db6b204b00afd4f5bdb536e803_Out_1_Float);
            float _Step_2915494ac90041cdb6d11dd595aa4bed_Out_2_Float;
            Unity_Step_float(_Float_774a58fb654e4fc6a933982955bc7a58_Out_0_Float, _Fraction_f46915db6b204b00afd4f5bdb536e803_Out_1_Float, _Step_2915494ac90041cdb6d11dd595aa4bed_Out_2_Float);
            float4 _Lerp_fa678a7ff69e49df9729d7e77bbafd13_Out_3_Vector4;
            Unity_Lerp_float4(_Property_2fdf8602c5554e0c936dfce65db76da9_Out_0_Vector4, _Property_4f618932163d41a990705f5a71e41f60_Out_0_Vector4, (_Step_2915494ac90041cdb6d11dd595aa4bed_Out_2_Float.xxxx), _Lerp_fa678a7ff69e49df9729d7e77bbafd13_Out_3_Vector4);
            float4 _Property_eb940b75c2f041f4bd6fc0cab0637a58_Out_0_Vector4 = _StripTint_EdgeColor;
            float4 _Property_924d5e0256f4471aac8fe74a82ca9164_Out_0_Vector4 = _StripTint_MidColor;
            float3 _Lerp3ColorCustomFunction_afcbeae46463473a86846aa74d940b8c_res_4_Vector3;
            Lerp3Color_float((_Property_eb940b75c2f041f4bd6fc0cab0637a58_Out_0_Vector4.xyz), (_Property_924d5e0256f4471aac8fe74a82ca9164_Out_0_Vector4.xyz), (_Property_eb940b75c2f041f4bd6fc0cab0637a58_Out_0_Vector4.xyz), _Fraction_9d451f02d74b4ce88355dd255137a5fa_Out_1_Float, _Lerp3ColorCustomFunction_afcbeae46463473a86846aa74d940b8c_res_4_Vector3);
            float3 _Multiply_dcd4fe58eb1146e0b05f4908789d0180_Out_2_Vector3;
            Unity_Multiply_float3_float3((_Lerp_fa678a7ff69e49df9729d7e77bbafd13_Out_3_Vector4.xyz), _Lerp3ColorCustomFunction_afcbeae46463473a86846aa74d940b8c_res_4_Vector3, _Multiply_dcd4fe58eb1146e0b05f4908789d0180_Out_2_Vector3);
            float _Property_806e15bae9ce42509dd08e46b888865b_Out_0_Float = _Strip_Opacity;
            float3 _Lerp_7bbeea05e07e4dd1bd3a2c856fc56c03_Out_3_Vector3;
            Unity_Lerp_float3(_Add_db4e089dcdac42b5958ca09b966f3d37_Out_2_Vector3, _Multiply_dcd4fe58eb1146e0b05f4908789d0180_Out_2_Vector3, (_Property_806e15bae9ce42509dd08e46b888865b_Out_0_Float.xxx), _Lerp_7bbeea05e07e4dd1bd3a2c856fc56c03_Out_3_Vector3);
            surface.BaseColor = _Lerp_7bbeea05e07e4dd1bd3a2c856fc56c03_Out_3_Vector3;
            surface.Alpha = 1;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
            float3 normalWS = SHADERGRAPH_SAMPLE_SCENE_NORMAL(input.texCoord0.xy);
            float4 tangentWS = float4(0, 1, 0, 0); // We can't access the tangent in screen space
        
        
        
        
            float3 viewDirWS = normalize(input.texCoord1.xyz);
            float linearDepth = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(input.texCoord0.xy), _ZBufferParams);
            float3 cameraForward = -UNITY_MATRIX_V[2].xyz;
            float camearDistance = linearDepth / dot(viewDirWS, cameraForward);
            float3 positionWS = viewDirWS * camearDistance + GetCameraPositionWS();
        
            output.WorldSpaceViewDirection = normalize(viewDirWS);
        
            output.WorldSpacePosition = positionWS;
            output.ScreenPosition = float4(input.texCoord0.xy, 0, 1);
            output.TimeParameters = _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
            output.NDCPosition = input.texCoord0.xy;
        
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.shadergraph/Editor/Generation/Targets/Fullscreen/Includes/FullscreenCommon.hlsl"
        #include "Packages/com.unity.shadergraph/Editor/Generation/Targets/Fullscreen/Includes/FullscreenBlit.hlsl"
        
        ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.Fullscreen.ShaderGraph.FullscreenShaderGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}