#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"

varying vec2 vScreenPos;

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vScreenPos = GetScreenPosPreDiv(gl_Position);
}

void PS()
{
	#ifdef AO
		float AOFactor = texture2D(sNormalMap, vScreenPos).r;
		vec4 color = texture2D(sDiffMap, vScreenPos);
        gl_FragColor = vec4(color.rgb * AOFactor, color.a);
        gl_FragColor = texture2D(sDiffMap, vScreenPos);
    #else
    	gl_FragColor = texture2D(sDiffMap, vScreenPos);
    #endif
}

