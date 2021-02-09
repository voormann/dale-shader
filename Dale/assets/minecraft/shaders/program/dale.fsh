#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D ItemEntitySampler;
uniform sampler2D ItemEntityDepthSampler;
uniform sampler2D ParticlesSampler;
uniform sampler2D ParticlesDepthSampler;
uniform sampler2D WeatherSampler;
uniform sampler2D WeatherDepthSampler;
uniform sampler2D CloudsSampler;
uniform sampler2D CloudsDepthSampler;

uniform vec2 InSize;
varying vec2 texCoord;
varying vec2 oneTexel;

vec4 colorLayers[6];
float depthLayers[6];
int presentLayers = 0;

void tailor(vec4 color, float depth) {
    if (color.a == 0.0)
        return;

    colorLayers[presentLayers] = color;
    depthLayers[presentLayers] = depth;

    int j = presentLayers++;
    int i = j - 1;

    while (j > 0 && depthLayers[j] > depthLayers[i]) {
        float depthTemp = depthLayers[i];

        depthLayers[i] = depthLayers[j];
        depthLayers[j] = depthTemp;

        vec4 colorTemp = colorLayers[i];

        colorLayers[i] = colorLayers[j];
        colorLayers[j] = colorTemp;

        j = i--;
    }
}

vec3 blend(vec3 dst, vec4 src) {
    return (dst * (1.0 - src.a)) + src.rgb;
}

float Luma(vec4 rgba) {
    return dot(rgba.xyz, vec3(0.299, 0.587, 0.114));
}

vec4 antialias() {
    const float edgeSharpness = 4.0;
    const float edgeThreshold = 0.125;
    const float edgeThresholdMin = 0.06;
    const float subpixelremoval = 0.25;

    vec4 pos = vec4(texCoord - oneTexel, texCoord + oneTexel);  
    vec2 offset = vec2(0.33, 1.0) / InSize;
    float lumaNw = Luma(texture2D(DiffuseSampler, pos.xy));
    float lumaSw = Luma(texture2D(DiffuseSampler, pos.xw));
    float lumaNe = Luma(texture2D(DiffuseSampler, pos.zy)) + 1.0 / 64.0;
    float lumaSe = Luma(texture2D(DiffuseSampler, pos.zw));

    vec4 rgbyM = texture2D(DiffuseSampler, texCoord.xy);
    float lumaM = Luma(rgbyM);
    float lumaMaxNwSw = max(lumaNw, lumaSw);
    float lumaMinNwSw = min(lumaNw, lumaSw);
    float lumaMaxNeSe = max(lumaNe, lumaSe);
    float lumaMinNeSe = min(lumaNe, lumaSe);
    float lumaMax = max(lumaMaxNeSe, lumaMaxNwSw);
    float lumaMin = min(lumaMinNeSe, lumaMinNwSw);
    float lumaMaxScaled = lumaMax * edgeThreshold;
    float lumaMinM = min(lumaMin, lumaM);
    float lumaMaxScaledClamped = max(edgeThresholdMin, lumaMaxScaled);
    float lumaMaxM = max(lumaMax, lumaM);
    float dirSwMinusNe = lumaSw - lumaNe;
    float lumaMaxSubMinM = lumaMaxM - lumaMinM;
    float dirSeMinusNw = lumaSe - lumaNw;

    if(lumaMaxSubMinM < lumaMaxScaledClamped)
        return rgbyM;

    vec2 dir = vec2(dirSwMinusNe + dirSeMinusNw, dirSwMinusNe - dirSeMinusNw);
    vec2 dir1 = normalize(dir.xy);
    vec4 rgbyN1 = texture2D(DiffuseSampler, texCoord.xy - dir1 * offset.xx);
    vec4 rgbyP1 = texture2D(DiffuseSampler, texCoord.xy + dir1 * offset.xx);
    float dirAbsMinTimesC = min(abs(dir1.x), abs(dir1.y)) * edgeSharpness;
    vec2 dir2 = clamp(dir1.xy / dirAbsMinTimesC, -2.0, 2.0);
    vec4 rgbyN2 = texture2D(DiffuseSampler, texCoord.xy - dir2 * offset.yy);
    vec4 rgbyP2 = texture2D(DiffuseSampler, texCoord.xy + dir2 * offset.yy);
    vec4 rgbyA = rgbyN1 + rgbyP1;
    vec4 rgbyB = ((rgbyN2 + rgbyP2) * subpixelremoval) + (rgbyA * subpixelremoval);

    if(Luma(rgbyB) < lumaMin || Luma(rgbyB) > lumaMax)
        rgbyB.xyz = rgbyA.xyz * 0.5;

    return rgbyB; 
}

vec3 bloom() {
    vec3 scalingValues = vec3(1.25, 1.5, 1.35);

    if (texture2D(DiffuseDepthSampler, texCoord).x < (1.0 - 1.0 / 32.0 / 32.0))
        scalingValues = vec3(2.5, 2.25, 0.8);

    vec3 blur = vec3(0.0);
    float tw = 0.0;

    for (float i = 0.0; i < 17.0; i++) {
        vec4 offsets = vec4(oneTexel.x, oneTexel.y, i - 8.0, 0.0);         
        float dist = abs(i - 8.0) / 8.0;
        float weight = (exp(-(dist * dist) / 0.28));
        vec3 bsample = texture2D(DiffuseSampler, texCoord.xy + scalingValues.x * offsets.xy * offsets.zw).rgb * scalingValues.y;
             bsample += texture2D(DiffuseSampler, texCoord.xy + 1.25 * offsets.xy * offsets.wz).rgb * 2.0;

        blur += bsample * weight;
        tw += weight;
    }

    blur /= tw;
    blur = max(vec3(0.0), blur - scalingValues.z);

    vec3 bleed = blur * pow(length(blur) * 2.0, 2.8) * 2.0;

    return (bleed + blur * 1.15) * 0.0005;
}

vec3 tonemap(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;

    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

void main() {
    colorLayers[0] = vec4(texture2D(DiffuseSampler, texCoord).rgb, 1.0);
    depthLayers[0] = texture2D(DiffuseDepthSampler, texCoord).r;
    presentLayers = 1;

    tailor(texture2D(TranslucentSampler, texCoord), texture2D(TranslucentDepthSampler, texCoord).r);
    tailor(texture2D(ItemEntitySampler, texCoord), texture2D(ItemEntityDepthSampler, texCoord).r);
    tailor(texture2D(ParticlesSampler, texCoord), texture2D(ParticlesDepthSampler, texCoord).r);
    tailor(texture2D(WeatherSampler, texCoord), texture2D(WeatherDepthSampler, texCoord).r);
    tailor(texture2D(CloudsSampler, texCoord), texture2D(CloudsDepthSampler, texCoord).r);

    vec4 gjengi = colorLayers[0];

    gjengi.rgb = antialias().rgb;

    for (int i = 1; i < presentLayers; ++i) {
        gjengi.rgb = blend(gjengi.rgb, colorLayers[i]);
    }

    gjengi.rgb += bloom();
    gjengi.rgb *= vec3(1.11, 0.89, 0.79);
    gjengi.rgb = tonemap(gjengi.rgb);

    gl_FragColor = vec4(gjengi.rgb, 1.0);
}
