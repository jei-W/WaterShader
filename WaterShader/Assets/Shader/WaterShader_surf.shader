Shader "Custom/WaterShader_surf"
{
    Properties
    {
		_BumpMap ("Normal", 2D) = "bump" {}
		_Cube ("Cube", Cube) = "" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

		GrabPass{}

        CGPROGRAM
        #pragma surface surf WaterSpecular vertex:vert

        sampler2D _BumpMap;
		samplerCUBE _Cube;
		sampler2D _GrabTexture;

		half _SPMulti;

        struct Input
        {
            float2 uv_BumpMap;
			float3 worldRefl;
			float3 viewDir;
			float4 screenPos;
			INTERNAL_DATA
        };

		void vert (inout appdata_full v)
		{
			// 물결의 움직임은 x축, y축의 움직임의 평균값이다
			float movement = sin( abs(v.texcoord.x * 2 -1) * 20 + _Time.y ) * 0.2;
			movement += sin( abs(v.texcoord.y * 2 -1) * 20 + + _Time.y ) * 0.2;
			v.vertex.y = movement / 2;
		}

        void surf (Input IN, inout SurfaceOutput o)
        {
            float3 normal1 = UnpackNormal( tex2D(_BumpMap, IN.uv_BumpMap + float2(_Time.x * 0.17, 0) ) );
            float3 normal2 = UnpackNormal( tex2D(_BumpMap, IN.uv_BumpMap + float2(0, _Time.x * 0.17) ) );
			o.Normal = (normal1 + normal2) / 2;

			//반사에는 큐브맵을 이용하여 주변 환경이 반사되는 것처럼 보이게 한다
			float3 reflection = texCUBE(_Cube, WorldReflectionVector(IN, o.Normal));

			//grabPass를 이용해 물이 투명한 것처럼 보인다
			float3 screenUV = IN.screenPos.rgb / IN.screenPos.a;
			fixed4 refraction = tex2D(_GrabTexture, screenUV.xy + o.Normal.xy * 0.05);

			//물은 수직에서 봤을 떄 가장 투명하다
			float ndotv = abs( dot(o.Normal, IN.viewDir) );
			ndotv = pow( ndotv, 1.2);
			
			o.Emission = (ndotv * refraction) + reflection * 0.4;
			o.Alpha = 1;
        }

		half4 LightingWaterSpecular (SurfaceOutput s, float3 lightDir, float3 viewDir, float atten)
		{
			half4 result;
			float spec = dot( normalize(lightDir + viewDir) , s.Normal);
			spec = saturate(spec);
			spec = pow(spec, 150);

			float ndotv = abs( dot(s.Normal, viewDir) );
			ndotv = pow(1 - ndotv, 5);

			result.rgb = spec + ndotv;
			result.a = s.Alpha; // 알파 값에 spec을 더함으로써 스펙큘러부분이 투명해지지않게 한다

			return result;
		}

        ENDCG
    }
    FallBack "Legasy Shader/Transparent/vertexlit"
}
