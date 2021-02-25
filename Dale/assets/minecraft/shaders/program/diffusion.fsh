#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D CloudsDepthSampler;

varying vec2 texCoord;

vec3 diffuse() {
    vec3 diffusion = texture2D(DiffuseSampler, texCoord + vec2(0.0, 0.0009765625)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.0, 0.001953125)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.000845728, 0.0004882812)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.001691456, 0.0009765624)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.0008457279, -0.0004882814)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.001691456, -0.0009765627)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(1.551271e-10, -0.0009765626)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(3.102542e-10, -0.001953125)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.0008457282, -0.0004882811)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.001691456, -0.0009765623)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.0008457279, 0.0004882815)).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.001691456, 0.0009765631)).rgb;
    
    return diffusion / 12.0;
}

void main() {
    float diffuseDepth = texture2D(DiffuseDepthSampler, texCoord).r;
    float translucentDepth = texture2D(TranslucentDepthSampler, texCoord).r;
    float cloudsDepth = texture2D(CloudsDepthSampler, texCoord).r;
    float threshold = diffuseDepth - min(translucentDepth, cloudsDepth);
    vec3 gjengi = threshold > 0.0 ? diffuse() : texture2D(DiffuseSampler, texCoord).rgb;

    gl_FragColor = vec4(gjengi, 1.0);
    gl_FragDepth = diffuseDepth;
}