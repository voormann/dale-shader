#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;

varying vec2 texCoord;

const float angle = radians(60.0);
const float angleSin = sin(angle);
const float angleCos = cos(angle);
const mat2 rotationMatrix = mat2(angleCos, angleSin, -angleSin, angleCos);

float ssao(float rootDepth) {
    vec2 sampleOffset = vec2(0.0, 1.0 / 256.0);
    float dist = 1.0 - pow(rootDepth, 64.0);
    float occlusion = 0.0;

    for (float i = 0.0; i < 6.0; ++i) {
        for (float j = 1.0; j < 7.0; ++j) {
            float mul = dist * j;
            float sampleDepth = texture2D(DiffuseDepthSampler, texCoord + (sampleOffset * mul)).r;
            float rangeCheck = clamp(smoothstep( 0.0, 1.0, mul / abs(rootDepth - sampleDepth)), 0.0, 1.0);

            occlusion += sampleDepth >= rootDepth ? rangeCheck : 0.0;
        }

        sampleOffset = rotationMatrix * sampleOffset;
    }

    return occlusion / 36.0;
}

void main() {
    float depth = texture2D(DiffuseDepthSampler, texCoord).r;
    float ao = depth < 1.0 ? ssao(depth) : 1.0;
    vec3 gjengi = texture2D(DiffuseSampler, texCoord).rgb;
    
    gl_FragColor = vec4(mix(gjengi * 0.6, gjengi, clamp(smoothstep(0.0, 0.5, ao), 0.0, 1.0)), 1.0);
    gl_FragDepth = depth;
}