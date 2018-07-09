#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"
#include "PostProcess.glsl"

varying vec2 vTexCoord;
varying vec2 vScreenPos;

#ifdef COMPILEPS
uniform vec2 cBlurDir;
uniform float cBlurRadius;
uniform float cBlurSigma;
uniform vec2 cBlurHInvSize;

#ifdef BILATERAL
float normpdf(float x, float sigma)
{
    return 0.39894 * exp(-0.5 * x * x / (sigma * sigma)) / sigma;
}

float normpdf3(vec3 v, float sigma)
{
    return 0.39894 * exp(-0.5 * dot(v,v) / (sigma * sigma))/sigma;
}
#endif
uniform float cAOSigma;
#endif

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vTexCoord = GetQuadTexCoord(gl_Position);
    vScreenPos = GetScreenPosPreDiv(gl_Position);
}

void PS()
{
    #ifdef BLUR3
        gl_FragColor = GaussianBlur(3, cBlurDir, cBlurHInvSize * cBlurRadius, cBlurSigma, sDiffMap, vTexCoord);
    #endif

    #ifdef BLUR5
        gl_FragColor = GaussianBlur(5, cBlurDir, cBlurHInvSize * cBlurRadius, cBlurSigma, sDiffMap, vTexCoord);
    #endif

    #ifdef BLUR7
        gl_FragColor = GaussianBlur(7, cBlurDir, cBlurHInvSize * cBlurRadius, cBlurSigma, sDiffMap, vTexCoord);
    #endif

    #ifdef BLUR9
        gl_FragColor = GaussianBlur(9, cBlurDir, cBlurHInvSize * cBlurRadius, cBlurSigma, sDiffMap, vTexCoord);
    #endif

    #ifdef BILATERAL
        #ifdef GL_ES
            precision mediump float;
        #endif

        #define SIGMA 10.0
        #define BSIGMA 0.1
        #define MSIZE 15

        float kernel[MSIZE];
        kernel[0] = 0.031225216;
        kernel[1] = 0.033322271;
        kernel[2] = 0.035206333;
        kernel[3] = 0.036826804;
        kernel[4] = 0.038138565;
        kernel[5] = 0.039104044;
        kernel[6] = 0.039695028;
        kernel[7] = 0.039894000;
        kernel[8] = 0.039695028;
        kernel[9] = 0.039104044;
        kernel[10] = 0.038138565;
        kernel[11] = 0.036826804;
        kernel[12] = 0.035206333;
        kernel[13] = 0.033322271;
        kernel[14] = 0.031225216;

        const int kSize = int(float(MSIZE-1) / 2.0);
        vec3 finalColor = vec3(0.0, 0.0, 0.0);
        float weight = 0.0;

        vec3 colorOffset = vec3(0.0, 0.0, 0.0);
        float factor;
        float BilateralWeight = 1.0/normpdf(0.0, BSIGMA);
        vec3 color = texture2D(sDiffMap, vScreenPos).rgb;
        for (int i=-kSize; i <= kSize; ++i)
        {
            for (int j=-kSize; j <= kSize; ++j)
            {
                colorOffset = texture2D(sDiffMap, vScreenPos + vec2(float(i),float(j)) * cGBufferInvSize.xy).rgb;
                factor = normpdf3(colorOffset - color, BSIGMA) * BilateralWeight * kernel[kSize+j] * kernel[kSize+i];
                weight += factor;
                finalColor += factor * colorOffset;
            }
        }

        vec3 ScaleFinalColor = finalColor / weight;
        
        #ifdef SCALELUMINANCE
            ScaleFinalColor.x = pow(ScaleFinalColor.x, cAOSigma);
            ScaleFinalColor.y = pow(ScaleFinalColor.y, cAOSigma);
            ScaleFinalColor.z = pow(ScaleFinalColor.z, cAOSigma);
        #endif
        
        gl_FragColor = vec4(ScaleFinalColor, 1.0);

    #endif
}
