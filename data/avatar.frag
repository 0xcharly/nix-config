// Based off @XorDev work: https://x.com/xordev/status/1894105806267711499

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 r = u_resolution.xy;
    vec2 p = (fragCoord.xy * 2. - r) / r.y;

    float side = p.x - p.y;
    float d = max(abs(side), 0.001) * sign(side);

    // Softening radius.
    float curve = length(p) - 0.4 + 0.01 / d;

    float thickness = 0.015;
    float blueThickness = 0.035;

    float blueMask = smoothstep(-0.02, 0.5, -side);
    float localThickness = mix(thickness, blueThickness, blueMask);
    float o = 0.125 / (abs(curve) + localThickness);
    o = pow(o, mix(1.0, 0.8, blueMask));

    vec3 colTopLeft     = vec3(0xE1, 0x71, 0x00) / 255.0;
    vec3 colBottomRight = vec3(0x15, 0x5D, 0xFC) / 255.0;
    vec3 colSeam        = vec3(0x7f, 0x22, 0xFE) / 255.0;

    float s = smoothstep(-0.25, 0.25, side);
    vec3 baseCol = mix(colBottomRight, colTopLeft, s);

    baseCol *= 0.75; // Tone down brightness.

    // Animate hue shift
    baseCol += 0.05 * sin(vec3(2, 2, 2) + u_time);

    float seamWidth = 3.75; // smaller = wider
    float merge = exp(-abs(side) * seamWidth);


    // Animate seam
    merge = exp(-abs(side + 0.05 * sin(u_time)) * 4.0);

    vec3 col = baseCol * o;
    col = mix(col, colSeam * o, merge);
    col += colSeam * merge * 0.25;

    fragColor = vec4(col, 1.0);
}

void main()
{
    mainImage(gl_FragColor, gl_FragCoord.xy);
}
