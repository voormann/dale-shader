#version 120

uniform sampler2D DiffuseSampler;
uniform vec2 InSize;

varying vec2 texCoord;
varying vec2 oneTexel;

const float edgeSharpness = 6.0; // Sharpness of FXAA
const float edgeThreshold = 0.25; // Threshold for FXAA to blur
const float edgeThresholdMin = 0.01; // Higher values increase performance but have more aliasing in darker areas
const float subpixelremoval = 0.25; // Highly recommended to keep this as it is
const float grain = 0.5 / 255.0;

float Luma(vec3 rgb) {
    return dot(rgb, vec3(0.299, 0.587, 0.114));
}

vec3 fxaa() {
    vec4 pos = vec4(texCoord - oneTexel, texCoord + oneTexel);
    vec2 offset = vec2(0.33, 1.0) / InSize;
    float lumaNw = Luma(texture2D(DiffuseSampler, pos.xy).rgb);
    float lumaSw = Luma(texture2D(DiffuseSampler, pos.xw).rgb);
    float lumaNe = Luma(texture2D(DiffuseSampler, pos.zy).rgb) + 1.0 / 64.0;
    float lumaSe = Luma(texture2D(DiffuseSampler, pos.zw).rgb);

    vec3 rgbyM = texture2D(DiffuseSampler, texCoord.st).rgb;
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
    float lumaMaxSubMinM = lumaMaxM - lumaMinM;

    if(lumaMaxSubMinM < lumaMaxScaledClamped)
        return rgbyM;

    float dirSwMinusNe = lumaSw - lumaNe;
    float dirSeMinusNw = lumaSe - lumaNw;
    vec2 dir = vec2(dirSwMinusNe + dirSeMinusNw, dirSwMinusNe - dirSeMinusNw);
    vec2 dir1 = normalize(dir.xy);
    vec3 rgbyN1 = texture2D(DiffuseSampler, texCoord.st - dir1 * offset.xx).rgb;
    vec3 rgbyP1 = texture2D(DiffuseSampler, texCoord.st + dir1 * offset.xx).rgb;
    float dirAbsMinTimesC = min(abs(dir1.x), abs(dir1.y)) * edgeSharpness;
    vec2 dir2 = clamp(dir1.xy / dirAbsMinTimesC, -2.0, 2.0);
    vec3 rgbyN2 = texture2D(DiffuseSampler, texCoord.st - dir2 * offset.yy).rgb;
    vec3 rgbyP2 = texture2D(DiffuseSampler, texCoord.st + dir2 * offset.yy).rgb;
    vec3 rgbyA = rgbyN1 + rgbyP1;
    vec3 rgbyB = ((rgbyN2 + rgbyP2) * subpixelremoval) + (rgbyA * subpixelremoval);

    if(Luma(rgbyB) < lumaMin || Luma(rgbyB) > lumaMax)
        rgbyB.xyz = rgbyA.xyz * 0.5;

    return rgbyB; 
}

float vignette() {
    return exp(dot(texCoord - 0.5, texCoord - 0.5) * -0.5);
}

float random(vec2 coords) {
    return fract(sin(dot(coords.xy, vec2(12.9898,78.233))) * 43758.5453);
}

void main() {
    vec3 gjengi = fxaa();

    gjengi *= vignette();
    gjengi += mix(-grain, grain, random(texCoord));

    gl_FragColor = vec4(gjengi, 1.0);
}
