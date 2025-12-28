#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float rand(vec2 co, float seed){
    return fract(sin(dot(co.xy + seed ,vec2(12.9898,78.233))) * 43758.5453);
}

vec3 makeJupiter(vec2 uv)
{
    float time = uTime;
    float timeScale = .5;
    vec2 zoom = vec2(20.,5.5);
    vec2 offset = vec2(2.,1.);

    
    vec2 point = uv * zoom + offset;
    float p_x = float(point.x); 
    float p_y = float(point.y);
    
    float a_x = .2;
    float a_y = .3;
    
    for(int i=1; i<int(10); i++){
        float float_i = float(i); 
        point.x+=a_x*sin(float_i*point.y+time*timeScale);
        point.y+=a_y*cos(float_i*point.x+time*.2);
    }
        
    float r = cos(point.x+point.y+2.)*.5+.5;
    float g = sin(point.x+point.y+2.2)*.5+.5;
    float b = (sin(point.x+point.y+1.)+cos(point.x+point.y+1.5))*.5+.5;
    
    vec3 col = vec3(r,g,b);
    col += vec3(.5);

    return col;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 resolution = uResolution;

    vec2 texCoord = fragCoord.xy / resolution.xy;
    texCoord = vec2(texCoord.y,texCoord.x);
    vec2 position = ( fragCoord.xy / resolution.xy );
    
    vec2 center = resolution.xy / 2.;
    float dis = distance(center, fragCoord.xy);
    float radius = resolution.y / 3.;
    vec3 atmosphereColor = vec3(.7, .6, .5);
    
    if (dis < radius) {
        // Find planet coordinates
        vec2 posOnPlanet = (fragCoord.xy - (center - radius));
        vec2 planetCoord = posOnPlanet / (radius * 2.0);
        
        // Spherify it
        planetCoord = planetCoord * 2.0 - 1.0;
        float sphereDis = length(planetCoord);
        sphereDis = 1.0 - pow(1.0 - sphereDis, .6);
        planetCoord = normalize(planetCoord) * sphereDis;
        planetCoord = (planetCoord + 1.0) / 2.0;
        
        // Calculate light amounts
        float light = pow(planetCoord.x, 2.0*(cos(uTime*.1 +1.)+1.5));
        float lightAtmosphere = pow(planetCoord.x, 2.);
        
        // Apply light
        vec3 surfaceColor = makeJupiter(texCoord);
        surfaceColor *= light;
        
        // Atmosphere
        float fresnelIntensity = pow(dis / radius, 3.);
        vec3 fresnel = mix(surfaceColor, atmosphereColor, fresnelIntensity * lightAtmosphere);
        
        fragColor = vec4(fresnel.rgb, 1);
        fragColor *= texCoord.x * 2.;
    }
    else {
        // Render stars -- making them transparent since we have a different background mostly?
        // Actually the original shader draws a black background with stars.
        // Let's keep it transparent for `dis > radius` if we want to overlay it on our scene, 
        // OR we can keep the stars/atmosphere if it is intended to be the full background.
        // The user said "add this planet as the center piece", implying it might just be the planet.
        // However, the shader includes an "Atmosphere on top" effect for the outer glow.
        // Let's keep the atmosphere glow but maybe make the deep space part transparent? 
        // Or just port it as is.
        // The user request was "add this planet...", so maybe just the planet + aura.
        // The `scene.dart` already has a background.
        // If I keep the black background it might obscure the existing scene unless I put it behind?
        // But the scene.dart has other elements.
        // Let's try to make the "black" part transparent but keep the atmosphere glow.
        
        float starAmount = rand(fragCoord.xy, 0.0);
        vec4 background = vec4(0, 0, 0, 0); // Transparent background by default
        
        // Note: The original shader draws stars on a black background.
        // if (starAmount < .01) {
        // 	float intensity = starAmount * 1000.0 / 4.0;
        // 	intensity = clamp(intensity, .1, .3);
        // 	background = vec4(intensity, intensity, intensity, 1.0);
        // }
        // Let's skip the stars for now to integrate cleanly with existing background
        
        // Atmosphere on top
        float outter = distance(center, fragCoord.xy) / resolution.y;
        outter = 1.0 - outter;
        outter = clamp(outter, 0.5, 0.8);
        outter = (outter - .5) / .3;
        outter = pow(outter, 2.8);
        //outter *= texCoord.x * 1.5;
        
        // Add atmosphere on top
        // If outter is high, we want some color.
        // mix(background, atmosphere, outter)
        
        fragColor = background + vec4(atmosphereColor * outter, outter);
    }
}
