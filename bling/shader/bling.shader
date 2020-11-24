Shader "Unlit/bling"
{
    Properties
    {
		_gaincolor("diffuse", Color) = (0.5,0.5,0.5,1)
		_ShadowColor("Shadow Color", Color) = (0,0,0,1)
        _MainTex ("Texture", 2D) = "white" {}
	    //亮片重复度
	    _NoiseSize("Noise Size", Float) = 2
		_Speed("speed",Float) =1
	    _SparkleT("_SparkleT",Float) =1
        _SparkleColor("_SparkleColor",color) = (0.5,0.5,0.5,1)


		_hight("hight",2D) = "white"{}
		_hightscale("hightscale",range(-20,20))= 1

		_Gloss("gloss",range(0,1)) = 0.5
		_Specular("specular",range(0,1)) = 0.5
         //边缘光颜色强度范围
		_FNColor("FNColor", Color) = (0.17,0.36,0.81,0.0)
		_FNPower("FNPower", Range(0.6,36.0)) = 8.0
		_FNIntensity("FNIntensity ", Range(0.0,1.0)) = 1.0


		//控制亮片
		_DiffSpark("DiffSpark",range(0,200)) = 50
		_Spspark("Spspark",range(0,200)) = 50
        _fnspark("fnspark",range(0,200))  =1



    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
       

        Pass
        {
            CGPROGRAM
	        #pragma vertex vert
		    #pragma fragment frag
		    #include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float4 tangent : TANGENT;
			};

		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float4 posWorld : TEXCOORD1;
			float3 normalDir : TEXCOORD2;
			float3 lightDir : TEXCOORD3;
			float3 viewDir : TEXCOORD4;
			float3 lightDir_tangent : TEXCOORD5;
			float3 viewDir_tangent : TEXCOORD6;
		    LIGHTING_COORDS(7, 8)
			
				 };

            sampler2D _MainTex, _hight;
            float4 _MainTex_ST, _FNColor;
			float4 _gaincolor,_ShadowColor, _SparkleColor;
			float _hightscale, _Speed;
			float _Gloss, _Specular;
			float _FNPower, _FNIntensity, _NoiseSize, _SparkleT, _DiffSpark, _Spspark, _fnspark;

			inline float2 Tranfuv(v2f i, float Hightmu)
			{
				//偏移值图的r通道
				float height = tex2D(_hight, i.uv).r;
				//normalize view Dir 视角空间
				float3 viewDir = normalize(i.lightDir_tangent);
				//偏移值 = 切线空间的视线方向.xy  *height贴图的r通道  * heightscale * 控制系数
				float2 offset = i.lightDir_tangent.xy * height * _hightscale * Hightmu;
				return offset;
			}
			
            v2f vert (appdata v)
            {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
				o.lightDir = normalize(_WorldSpaceLightPos0.xyz);

				TANGENT_SPACE_ROTATION;
				o.lightDir_tangent = normalize(mul(rotation, ObjSpaceLightDir(v.vertex)));
				o.viewDir_tangent = normalize(mul(rotation, ObjSpaceViewDir(v.vertex)));
				TRANSFER_VERTEX_TO_FRAGMENT(o)
			    return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				 i.normalDir = normalize(i.normalDir);

			     //基础颜色
				 float attenuation = LIGHT_ATTENUATION(i);
			     float3 attenColor = attenuation * _LightColor0.xyz;
				 float NdotL = saturate(dot(i.normalDir, i.lightDir));
				 float3 directDiffuse = NdotL * attenColor;
				 float3 diffuseCol = lerp(_ShadowColor, _gaincolor, directDiffuse);
				 //高光计算

				 float specularPow = exp2((1 - _Gloss) * 10.0 + 1.0);
				 float3 specularColor = float4 (_Specular, _Specular, _Specular, 1);
				  //半角向量计算
				 float3 halfVector = normalize(i.lightDir + i.viewDir);
				 float3 directSpecular = pow(max(0, dot(halfVector, i.normalDir)), specularPow) * specularColor;
				 float3 specular = directSpecular * attenColor;

				 //勾边边缘光
				 float fn = 1.0 - max(0, dot(i.normalDir, i.viewDir));
				 float3 FNCol = _FNColor.rgb * pow(fn, _FNPower) * _FNIntensity;

				 //计算噪点图
				 float2 uvOffset = Tranfuv(i, 1);
				 float noise1 = tex2D(_MainTex, i.uv * _NoiseSize + float2 (0, _Time.x * _Speed) + uvOffset).r;
				 float noise2 = tex2D(_MainTex, i.uv * _NoiseSize * 1.4 + float2 (_Time.x * _Speed, 0)).r;
				 float sparkle1 = pow(noise1 * noise2 * 2, _SparkleT);

				 float3 sparkleCol1 = sparkle1 * (specular * _Spspark + directDiffuse * _DiffSpark + FNCol * _fnspark) * lerp(_SparkleColor, fixed3(1, 1, 1), 0.5);
				 
                 uvOffset = Tranfuv(i, 2);
				 noise1 = tex2D(_MainTex, i.uv * _NoiseSize + float2 (0.3, _Time.x * _Speed) + uvOffset).r;
				 noise2 = tex2D(_MainTex, i.uv * _NoiseSize * 1.4 + float2 (_Time.x * _Speed, 0.3)).r;
				 float sparkle2 = pow(noise1 * noise2 * 2, _SparkleT);

				 float3 sparkleCol2 = sparkle2 * (specular * _Spspark + directDiffuse * _DiffSpark + FNCol * _fnspark) * _SparkleColor;

				 uvOffset = Tranfuv(i, 3);
				 noise1 = tex2D(_MainTex, i.uv * _NoiseSize + float2 (0.6, _Time.x * _Speed) + uvOffset).r;
				 noise2 = tex2D(_MainTex, i.uv * _NoiseSize * 1.4 + float2 (_Time.x * _Speed, 0.6)).r;
				 float sparkle3 = pow(noise1 * noise2 * 2, _SparkleT);

				 float3 sparkleCol3 = sparkle3 * (specular * _Spspark + directDiffuse * _DiffSpark + FNCol * _fnspark) * 0.5 * _SparkleColor;

				 uvOffset = Tranfuv(i, 4);
				 noise1 = tex2D(_MainTex, i.uv * 15 + float2 (0.6, _Time.x * _Speed) + uvOffset).r;
				 noise2 = tex2D(_MainTex, i.uv * 15 * 1.4 + float2 (_Time.x * _Speed, 0.6)).r;
				 float sparkle4 = pow(noise1 * noise2 * 2, _SparkleT);

				 float3 sparkleCol4 = sparkle4 * (specular * _Spspark + directDiffuse * _DiffSpark + FNCol * 2.6) * 0.5 * _SparkleColor;



				 float4 finalCol = float4(diffuseCol + specular + FNCol + sparkleCol1 + sparkleCol2 + sparkleCol3 + sparkleCol4, 1);
			
             
      
                return finalCol;
            }
            ENDCG
        }
    }
}
