#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"

#define pi   3.1415926535897932384626433832795
#define pi2  6.2831853071795864769252867665590

varying vec2 vScreenPos;

float SampleRadius = 1.0;
float ShadowScalar = 1.3;
float DepthThreshold = 0.0025;
float ShadowContrast = 0.8;
int NumSamples = 40;


void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vScreenPos = GetScreenPosPreDiv(gl_Position);
}

#ifdef COMPILEPS

precision highp float;

uniform float cSampleRadius;
uniform float cSigma; 
uniform float cEps; 
uniform float cBeta;

float randAngle()
{
  uint x = uint(gl_FragCoord.x);
  uint y = uint(gl_FragCoord.y);
  uint result = 30u * x ^ y + 10u * x * y;
  return float(result);
}

//计算翰墨采样点的帮助函数
float BitOrderInverse(uint bits)
{
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u | (bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u | (bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u | (bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u | (bits & 0xFF00FF00u) >> 8u);

    float bits_f = float(bits);
    return bits_f * 2.3283064365386963e-10;
}

//用于计算翰墨采样点，用于实现蒙特卡洛积分近似
vec2 HammerseSample(uint i, uint N)
{
    float i_f = float(i);
    float N_f = float(N); 
    float radicalVector = BitOrderInverse(i);
    return vec2(i_f/N_f, radicalVector);
}

#endif

void PS()
{
  float AO = 0.0;
  vec3 Pos = texture2D(sDiffMap, vScreenPos).rgb;
  vec3 vPos = (vec4(Pos, 1.0) * cView).xyz;
  float depth = texture2D(sDiffMap, vScreenPos).a;
  vec3 Normal = normalize(texture2D(sNormalMap, vScreenPos).rgb * 2.0 - 1.0);
  float PerspectiveRadius = (SampleRadius / -vPos.z);

  const float Beta = 0.005; 
  const float Eps = 0.003; 
  const float Sigma = 0.09;

  for (int i = 0; i < NumSamples; ++i)
  {
      vec2 randomPoint = HammerseSample(uint(i), uint(NumSamples)) * vec2(pi, pi2);
      randomPoint.y += randAngle();
      vec2 offset= vec2(cos(randomPoint.y), sin(randomPoint.y)) * PerspectiveRadius * cos(randomPoint.x);
      vec2 SampleOffset = vScreenPos + offset;


      vec3 posOffset = texture2D(sDiffMap, SampleOffset).xyz;
      vec3 ViewDir = posOffset - Pos;

      float Heaveside = step(sqrt(dot(ViewDir, ViewDir)), SampleRadius);
      float EdgeError = step(0.0, SampleOffset.x) * step(0.0, 1.0 - SampleOffset.x) *
                    step(0.0, SampleOffset.y) * step(0.0, 1.0 - SampleOffset.y);

      AO += (max(0.0, (dot(ViewDir,Normal) - Beta)  * Heaveside * EdgeError) / (dot(ViewDir,ViewDir) + Eps));
  }

  AO = max(0.0, 1.0 - 2.0 * Sigma / float(NumSamples) * AO);

  if(depth > 0.99)
  {
    AO = 1.0;
  }

  gl_FragColor = vec4(AO, AO, AO, 1.0);
}

