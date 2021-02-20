#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D CloudsDepthSampler;

varying vec2 texCoord;

vec3 diffuse() {
    vec3 diffusion = texture2D(DiffuseSampler, texCoord + vec2(0.0, 0.001953125)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.0, 0.00390625)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.001381068, 0.001381068)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.002762136, 0.002762136)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.001953125, 0.0)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.00390625, 0.0)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.001381068, -0.001381068)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.002762136, -0.002762136)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.0, -0.001953125)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.0, -0.00390625)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.001381068, -0.001381068)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.002762136, -0.002762136)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.001953125, 0.0)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.00390625, 0.0)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.001381068, 0.001381068)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.002762136, 0.002762136)).rgb;
    
    return diffusion / 16.0;
}

void main() {
    float diffuseDepth = texture2D(DiffuseDepthSampler, texCoord).r;
    float translucentDepth = texture2D(TranslucentDepthSampler, texCoord).r;
    float cloudsDepth = texture2D(CloudsDepthSampler, texCoord).r;
    float blurDepth = min(translucentDepth, cloudsDepth);
    float blurValue = diffuseDepth - blurDepth;
    vec3 gjengi = texture2D(DiffuseSampler, texCoord).rgb;

    if (blurValue > 0.0) {
        float depth = smoothstep(blurDepth, 1.0, blurDepth + blurValue);
        gjengi = mix(gjengi, diffuse(), depth);
    }

    gl_FragColor = vec4(gjengi, 1.0);
    gl_FragDepth = diffuseDepth;
}