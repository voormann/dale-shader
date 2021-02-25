#version 120

attribute vec4 Position;

uniform mat4 ProjMat;

varying vec2 texCoord;
varying vec2 offCoord[12];

void main() {
    vec4 outPos = ProjMat * vec4(Position.xy, 0.0, 1.0);
    
    gl_Position = vec4(outPos.xy, 0.2, 1.0);

    texCoord = outPos.xy * 0.5 + 0.5;

    offCoord[0] = texCoord + vec2(0.0, 0.0009765625);
    offCoord[1] = texCoord + vec2(0.0, 0.001953125);
    offCoord[2] = texCoord + vec2(-0.000845728, 0.0004882812);
    offCoord[3] = texCoord + vec2(-0.001691456, 0.0009765624);
    offCoord[4] = texCoord + vec2(-0.0008457279, -0.0004882814);
    offCoord[5] = texCoord + vec2(-0.001691456, -0.0009765627);
    offCoord[6] = texCoord + vec2(1.551271e-10, -0.0009765626);
    offCoord[7] = texCoord + vec2(3.102542e-10, -0.001953125);
    offCoord[8] = texCoord + vec2(0.0008457282, -0.0004882811);
    offCoord[9] = texCoord + vec2(0.001691456, -0.0009765623);
    offCoord[10] = texCoord + vec2(0.0008457279, 0.0004882815);
    offCoord[11] = texCoord + vec2(0.001691456, 0.0009765631);
}
