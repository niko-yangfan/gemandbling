Shader "Unlit/gem"
{
	Properties
	{
		_Color("Gem COlor", Color)=(1,1,1,1)
		_Emission("_Emission", Color)=(0,0,0,0)
		_RefractTex("RefractCube", Cube)="white"{}
		_EnvLightTex("Evn lighting", Cube)="black"{}
		_EnvTex("Env Texture", Cube)="white"{}
		_DispersionTex("Dispersion Tex", Cube)="red"{}
		_SpecularPower("Specular Power&Dispersion Power", Vector)=(8,1,0.25,0)
		_ReflectStrength("Reflect Strength", float)=0.17
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase"}
	
	
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			
			};

			struct v2f
			{
				float2 noiseUV:TEXCOORD0;
				float3 normal:TEXCOORD1;
				float3 view:TEXCOORD2;
				float4 vertex : SV_POSITION;
			};

			float4 _Color;
			float4 _Emission;
			samplerCUBE _RefractTex;
			samplerCUBE _EnvLightTex;
			samplerCUBE _DispersionTex;
			samplerCUBE _EnvTex;
			float3 _SpecularPower;
			float _ReflectStrength;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.noiseUV = dot(v.normal, float3(1,1,1));
				o.normal = normalize( mul((float3x3)unity_ObjectToWorld, v.normal) );
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.view = normalize(_WorldSpaceCameraPos.xyz - worldPos);
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float4 result = float4(0,0,0,1);
				float3 normal = normalize(i.normal);
				float3 viewVector = normalize(i.view);
				float3 refractVector = refract(-viewVector, normal, 1/2.4f);
				float3 reflectVector = reflect(-viewVector, normal);
				
				float3 refractColor = texCUBE(_EnvTex, refractVector)*_Color.xyz*0.3f;
				refractColor += texCUBE(_RefractTex, reflectVector)*_Color.xyz;
				refractColor += _Emission.xyz;
				refractColor = pow(refractColor, 2.2f);
				
				result.xyz = refractColor;		

				return result;
			}

			float4 frag2 (v2f i) : SV_Target
			{
				float4 result = float4(0,0,0,1);
				float3 normal = normalize(i.normal);
				float3 viewVector = normalize(i.view);
				float3 refractVector = refract(-viewVector, normal, 1/2.4f);
				
				float3 refractColor = texCUBE(_RefractTex, refractVector)*_Color.xyz;
				refractColor += _Emission.xyz;
				refractColor = pow(refractColor, 2.2f);
				
				result.xyz = refractColor;		
				//
				float3 reflectVector = reflect(-viewVector, normal);
				//
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float RL = saturate(dot(reflectVector, lightDir));
				float3 specularColor = _SpecularPower.y*pow(RL, _SpecularPower.x)*_LightColor0.xyz;
				//
				float3 envColor = texCUBE(_EnvLightTex, reflectVector);
				float3 reflectColor = texCUBE(_EnvTex, reflectVector);
				float3 dispersion = texCUBE(_DispersionTex, reflectVector);
				
				float fresnel = pow(1-saturate(dot(normal, -viewVector)), 2.0f);
				envColor = lerp(envColor, dispersion*envColor, _SpecularPower.z);
				envColor = fresnel * envColor;
				
				result.xyz += envColor*reflectColor*_ReflectStrength;
				
				result.xyz += saturate(specularColor);
				if(IsGammaSpace())
				{
					result.xyz = pow(result.xyz, 1/2.2);
				}
				return result;
			}
		ENDCG
		
		Pass
		{
			Cull Front
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma target 2.0
			ENDCG
		}
		Pass
		{
			ZWrite on
			Blend one one
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag2
			#pragma multi_compile_fwdbase
			#pragma target 2.0
			ENDCG
		}
	}
}
