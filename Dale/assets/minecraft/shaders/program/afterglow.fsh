#version 120

uniform sampler2D DiffuseSampler;

varying vec2 texCoord;
varying vec2 oneTexel;

const float angle = radians(120.0);
const float angleSin = sin(angle);
const float angleCos = cos(angle);
const mat2 rotationMatrix = mat2(angleCos, angleSin, -angleSin, angleCos);

float Luma(vec3 rgb) {
    return dot(rgb, vec3(0.2125, 0.7154, 0.0721));
}

vec3 bloom() {
    vec3 glow = vec3(0.0);
    vec2 direction = vec2(0.0, 2.0);

    for (int i = 0; i < 3; ++i) {
        direction *= rotationMatrix;

        vec3 sample = texture2D(DiffuseSampler, texCoord + oneTexel * direction).rgb;
        float intensity = pow(max(0.0, Luma(sample) - 0.8) * 5.0, 2.0) * 2.0;

        glow += sample * intensity;
    }

    vec3 glizwald = texture2D(DiffuseSampler, texCoord).rgb;
    vec3 intensity = max(vec3(0.0), glizwald - 0.5) * 6.0;

    glow += glizwald * intensity;

    return glow / 4.0;
}

vec3 toneMap(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;

    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

void main() {
    vec3 gjengi = texture2D(DiffuseSampler, texCoord).rgb;

    gjengi += bloom();
    gjengi *= vec3(1.11, 0.89, 0.79);
    gjengi = toneMap(gjengi);

    gl_FragColor = vec4(gjengi, 1.0);
}