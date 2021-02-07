#version 120 //mojang uses v110 by default

attribute vec4 Position;

uniform mat4 ProjMat;
uniform vec2 OutSize;
varying vec2 texCoord;
varying vec4 posPos;
uniform vec2 InSize;

varying vec2 oneTexel;

void main() {
    vec4 outPos = ProjMat * vec4(Position.xy, 0.0, 1.0);
    gl_Position = vec4(outPos.xy, 0.2, 1.0);
    texCoord = Position.xy / OutSize;

    posPos.xy = texCoord.xy;
    posPos.zw = texCoord.xy - (1.0/OutSize * vec2(0.5 + 0.25));
    oneTexel = 1.0 / InSize;
}
