#version 120

uniform sampler2D DiffuseSampler;

varying vec2 texCoord;
varying vec2 oneTexel;
uniform vec2 InSize;

const float fxaa_span_max = 16.0;
const float fxaa_reduce_mul = 0.03125;
const float fxaa_reduce_min = 0.0078125;
const float grain = 0.5 / 255.0;

vec3 fxaa() {
    vec3 rgbNW = texture2D( DiffuseSampler, texCoord + ( vec2( +0.0, +1.0 ) * oneTexel ) ).rgb;
    vec3 rgbNE = texture2D( DiffuseSampler, texCoord + ( vec2( +1.0, +0.0 ) * oneTexel ) ).rgb;
    vec3 rgbSW = texture2D( DiffuseSampler, texCoord + ( vec2( -1.0, +0.0 ) * oneTexel ) ).rgb;
    vec3 rgbSE = texture2D( DiffuseSampler, texCoord + ( vec2( +0.0, -1.0 ) * oneTexel ) ).rgb;
    vec3 rgbM  = texture2D( DiffuseSampler, texCoord ).rgb;

    const vec3 luma = vec3( 0.299, 0.587, 0.114 );
    float lumaNW = dot( rgbNW, luma );
    float lumaNE = dot( rgbNE, luma );
    float lumaSW = dot( rgbSW, luma );
    float lumaSE = dot( rgbSE, luma );
    float lumaM  = dot( rgbM, luma );

    float lumaMin = min( lumaM, min( min( lumaNW, lumaNE ), min( lumaSW, lumaSE ) ) );
    float lumaMax = max( lumaM, max( max( lumaNW, lumaNE ), max( lumaSW, lumaSE ) ) );

    vec2 dir;
    dir.x = -( ( lumaNW + lumaNE ) - ( lumaSW + lumaSE ) );
    dir.y =  ( ( lumaNW + lumaSW ) - ( lumaNE + lumaSE ) );

    float dirReduce = max( ( lumaNW + lumaNE + lumaSW + lumaSE ) * fxaa_reduce_mul, fxaa_reduce_min );

    float rcpDirMin = 1.0 / ( min( abs( dir.x ), abs( dir.y ) ) + dirReduce );

    dir = min( vec2( fxaa_span_max,  fxaa_span_max ),
    max( vec2( -fxaa_span_max, -fxaa_span_max ), dir * rcpDirMin ) ) * oneTexel;

    vec2 dir2 = dir * 0.5;
    vec3 rgbA = 0.5 * ( texture2D( DiffuseSampler, texCoord.xy + ( dir * -0.23333333 ) ).xyz + texture2D( DiffuseSampler, texCoord.xy + ( dir * 0.16666666 ) ).xyz);
    vec3 rgbB = ( rgbA * 0.5 ) + ( 0.25 * ( texture2D( DiffuseSampler, texCoord.xy - dir2 ).xyz + texture2D( DiffuseSampler, texCoord.xy + dir2 ).xyz ) );
    float lumaB = dot( rgbB, luma );

    if ( ( lumaB < lumaMin ) || ( lumaB > lumaMax ) ) {
        return rgbA;
    }

    return rgbB;
}

float Luma(vec4 rgba) {
    return dot(rgba.xyz, vec3(0.299, 0.587, 0.114));
}

vec4 fxaa2() {
    float edgeSharpness = 8.0;          // Edge sharpness: 8.0 (sharp, default) - 2.0 (soft)
    float edgeThreshold = 0.125;        // Edge threshold: 0.125 (softer, def) - 0.25 (sharper)
    float edgeThresholdMin = 0.04;      // 0.06 (faster, dark alias), 0.05 (def), 0.04 (slower, less dark alias)  
    float subpixelremoval = 0.25;       // 0.0 off, 0.25 default

    vec4 pos = vec4(texCoord - oneTexel, texCoord + oneTexel);  
    vec2 offset = vec2(0.33, 1.0) / InSize;
    float lumaNw = Luma(texture2D(DiffuseSampler, pos.xy));
    float lumaSw = Luma(texture2D(DiffuseSampler, pos.xw));
    float lumaNe = Luma(texture2D(DiffuseSampler, pos.zy)) + 1.0 / 64.0;
    float lumaSe = Luma(texture2D(DiffuseSampler, pos.zw));

    vec4 rgbyM = texture2D(DiffuseSampler, texCoord.st);
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
    vec4 rgbyN1 = texture2D(DiffuseSampler, texCoord.st - dir1 * offset.xx);
    vec4 rgbyP1 = texture2D(DiffuseSampler, texCoord.st + dir1 * offset.xx);
    float dirAbsMinTimesC = min(abs(dir1.x), abs(dir1.y)) * edgeSharpness;
    vec2 dir2 = clamp(dir1.xy / dirAbsMinTimesC, -2.0, 2.0);
    vec4 rgbyN2 = texture2D(DiffuseSampler, texCoord.st - dir2 * offset.yy);
    vec4 rgbyP2 = texture2D(DiffuseSampler, texCoord.st + dir2 * offset.yy);
    vec4 rgbyA = rgbyN1 + rgbyP1;
    vec4 rgbyB = ((rgbyN2 + rgbyP2) * subpixelremoval) + (rgbyA * subpixelremoval);

    if(Luma(rgbyB) < lumaMin || Luma(rgbyB) > lumaMax)
        rgbyB.xyz = rgbyA.xyz * 0.5;

    return rgbyB; 
}

float vignette() {
    return 1.0 - smoothstep(0.1, 1.4, length(texCoord - vec2(0.5, 0.5)));
}

float random(vec2 coords) {
    return fract(sin(dot(coords.xy, vec2(12.9898,78.233))) * 43758.5453);
}
float vignette2()
{
    vec2 uv = texCoord * (vec2(1.0) - texCoord.yx);
    float vig = (uv.x * uv.y) * 1.4;
    return clamp(pow(abs(vig), 0.1), 0.0, 1.0);
}

void main() {
    vec3 gjengi = fxaa2().rgb;

    gjengi *= vignette();
    gjengi += mix(-grain, grain, random(texCoord));

    gl_FragColor = vec4(gjengi, 1.0);
}
