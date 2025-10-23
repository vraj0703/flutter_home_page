import 'package:three_dart/three_dart.dart' as three;

final GodRaysShader = {
  'uniforms': {
    'lightPosition': three.Vector2(0.5, 0.5),
    'exposure': 0.6,
    'decay': 0.95,
    'density': 0.96,
    'weight': 0.4,
    'clampMax': 0.99,
  },
  'vertexShader': r'''    varying vec2 vUv;   
              void main() {      
                vUv = uv;      
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);    
              }  
      ''',
  'fragmentShader': r'''    varying vec2 vUv;    
              uniform sampler2D tDiffuse;    
              uniform vec2 lightPosition;    
              uniform float exposure;    
              uniform float decay;    
              uniform float density;    
              uniform float weight;    
              uniform float clampMax;    
              const int SAMPLES = 60;    
              void main() {      
                      vec2 texCoord = vUv;      
                      vec2 deltaTexCoord = texCoord - lightPosition;      
                      deltaTexCoord *= 1.0 / float(SAMPLES) * density;      
                      float illuminationDecay = 1.0;      
                      vec4 color = vec4(0.0);      
                      for (int i = 0; i < SAMPLES; i++) {        
                            texCoord -= deltaTexCoord;        
                            vec4 texel = texture2D(tDiffuse, texCoord);        
                            texel *= illuminationDecay * weight;        
                            color += texel;        
                            illuminationDecay *= decay;      
                      }      
                      gl_FragColor = clamp(color * exposure, 0.0, clampMax);    
              }  
          ''',
};
