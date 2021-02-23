#version 120

uniform sampler2D DiffuseSampler;

varying vec2 texCoord;
varying vec2 oneTexel;

vec3 bloom() {
    vec3 amplitude = vec3(1.4, 1.8, 0.7);
    vec3 blur = vec3(0.0);
    float yield = 0.0;

    for (float i = 0.0; i < 9.0; i++) {
        vec4 offsets = vec4(oneTexel.x, oneTexel.y, i - 4.0, 0.0);         
        float dist = abs(i - 4.0) / 4.0;
        float weight = (exp(-(dist * dist) / 0.28));
        vec3 sample = texture2D(DiffuseSampler, texCoord.st + amplitude.x * offsets.xy * offsets.zw).rgb * amplitude.y;
             sample += texture2D(DiffuseSampler, texCoord.st + 1.25 * offsets.xy * offsets.wz).rgb * 2.0;

        blur += sample * weight;
        yield += weight;
    }

    blur /= yield;
    blur = max(vec3(0.0), blur - amplitude.z);

    vec3 bleed = blur * pow(length(blur) * 2.0, 2.8) * 2.0;

    return (bleed + blur * 1.15) * 0.0005;
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