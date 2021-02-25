#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D CloudsDepthSampler;

varying vec2 texCoord;
varying vec2 offCoord[12];

vec3 diffuse() {
    vec3 diffusion = texture2D(DiffuseSampler, offCoord[0]).rgb;
    diffusion += texture2D(DiffuseSampler, offCoord[1]).rgb;
    diffusion += texture2D(DiffuseSampler, offCoord[2]).rgb;
    diffusion += texture2D(DiffuseSampler, offCoord[3]).rgb;
    diffusion += texture2D(DiffuseSampler, offCoord[4]).rgb;
    diffusion += texture2D(DiffuseSampler, offCoord[5]).rgb;
    diffusion += texture2D(DiffuseSampler, offCoord[6]).rgb;
    diffusion += texture2D(DiffuseSampler, offCoord[7]).rgb;
    diffusion += texture2D(DiffuseSampler, offCoord[8]).rgb;
    diffusion += texture2D(DiffuseSampler, offCoord[9]).rgb;
    diffusion += texture2D(DiffuseSampler, offCoord[10]).rgb;
    diffusion += texture2D(DiffuseSampler, offCoord[11]).rgb;

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