#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D CloudsDepthSampler;

varying vec2 texCoord;

const float angle = radians(60.0);
const float angleSin = sin(angle);
const float angleCos = cos(angle);
const mat2 rotationMatrix = mat2(angleCos, angleSin, -angleSin, angleCos);

vec4 blur() {
    vec2 tapOffset = vec2(0.0, 1.0 / 1024.0);
    vec4 color = vec4(0.0);

    for (float i = 0.0; i < 6.0; ++i) {
        for (float j = 0.0; j < 6.0; ++j) {
            color += texture2D(DiffuseSampler, texCoord + (tapOffset * (j + 1.0)));
        }

        tapOffset = rotationMatrix * tapOffset;
    }

    color /= 36.0;
    
    return color;
}

void main() {
    float diffuseDepth = texture2D(DiffuseDepthSampler, texCoord).r;
    float translucentDepth = texture2D(TranslucentDepthSampler, texCoord).r;
    float cloudsDepth = texture2D(CloudsDepthSampler, texCoord).r;
    float blurDepth = min(translucentDepth, cloudsDepth);
    float blurValue = diffuseDepth - blurDepth;
    vec4 color = texture2D(DiffuseSampler, texCoord);

    if (blurValue > 0.0) {
        float depth = smoothstep(blurDepth, 1.0, blurDepth + blurValue);
        color = mix(color, blur(), depth);
    }

    gl_FragColor = color;
    gl_FragDepth = diffuseDepth;
}
