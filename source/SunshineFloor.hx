package;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.utils.Assets;
import flixel.FlxG;
import openfl.Lib;

import openfl.display3D.Context3DWrapMode;
import openfl.display3D.Context3DTextureFilter;
class SunshineStageShader extends FlxShader {
    @:glFragmentSource('#pragma header
      #define EPSILON 0.001

      #define MAX_STEPS 255
      #define MAX_DIST 100.0

      float sdBox( vec3 p, vec3 b )
      {
        vec3 q = abs(p) - b;
        return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
      }

      uniform float floorX;
      uniform float floorY;
      uniform float camX;
      uniform bool lightsOn;
      uniform float camY;
      uniform float zoom;
      uniform sampler2D floorTex;

      float sdSphere( vec3 p, float s )
      {
        return length(p)-s;
      }

      float sdCappedCylinder( vec3 p, float h, float r )
      {
        vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
        return min(max(d.x,d.y),0.0) + length(max(d,0.0));
      }

      vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
          vec2 xy = fragCoord - size / 2.0;
          float z = size.y / tan(radians(fieldOfView) / 2.0);
          return normalize(vec3(xy, -z));
      }

      float intersectSDF(float distA, float distB) {
          return max(distA, distB);
      }

      float unionSDF(float distA, float distB) {
          return min(distA, distB);
      }

      float differenceSDF(float distA, float distB) {
          return max(distA, -distB);
      }

      float sceneSDF(vec3 samplePoint) {
        float baseY = floorY/10. + 8.;
        float baseX = floorX/10.;
          float flor = sdBox(vec3(baseX, baseY, 0.)-samplePoint, vec3(100., 3., 100.));
          return flor;
          //return differenceSDF(, sdSphere(vec3(0.0, -4 + , 0.0)-samplePoint, 2.));
      }

      vec3 getNormal(vec3 p) {
          return normalize(vec3(
              sceneSDF(vec3(p.x+EPSILON,p.y,p.z))-sceneSDF(vec3(p.x-EPSILON,p.y,p.z)),
              sceneSDF(vec3(p.x,p.y+EPSILON,p.z))-sceneSDF(vec3(p.x,p.y-EPSILON,p.z)),
              sceneSDF(vec3(p.x,p.y,p.z+EPSILON))-sceneSDF(vec3(p.x,p.y,p.z-EPSILON))
          ));
      }

      float getDist(vec3 eye, vec3 dir, float start, float end){
          float depth = start;
          for ( int i = 0; i < MAX_STEPS; i++){
              float dist = sceneSDF(eye + depth * dir);
              if(dist < EPSILON){
                  return depth;
              }
              depth += dist;
              if(depth>=end)return end;
          }
          return end;
      }
      /**
       * Lighting contribution of a single point light source via Phong illumination.
       *
       * The vec3 returned is the RGB color of the light\'s contribution.
       *
       * k_a: Ambient color
       * k_d: Diffuse color
       * k_s: Specular color
       * alpha: Shininess coefficient
       * p: position of point being lit
       * eye: the position of the camera
       * lightPos: the position of the light
       * lightIntensity: color/intensity of the light
       *
       * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
       */
      vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,
                                vec3 lightPos, vec3 lightIntensity) {
          vec3 N = getNormal(p);
          vec3 L = normalize(lightPos - p);
          vec3 V = normalize(eye - p);
          vec3 R = normalize(reflect(-L, N));

          float dotLN = dot(L, N);
          float dotRV = dot(R, V);

          if (dotLN < 0.0) {
              // Light not visible from this point on the surface
              return vec3(0.0, 0.0, 0.0);
          }

          if (dotRV < 0.0) {
              // Light reflection in opposite direction as viewer, apply only diffuse
              // component
              return lightIntensity * (k_d * dotLN);
          }
          return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
      }

      /**
       * Lighting via Phong illumination.
       *
       * The vec3 returned is the RGB color of that point after lighting is applied.
       * k_a: Ambient color
       * k_d: Diffuse color
       * k_s: Specular color
       * alpha: Shininess coefficient
       * p: position of point being lit
       * eye: the position of the camera
       *
       * See https://en.wikipedia.org/wiki/Phong_reflection_model#Description
       */
      vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye) {
          const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
          vec3 color = ambientLight * k_a;

          if(lightsOn){
            vec3 light1Pos = vec3(floorX/10., floorY/10. + 16.5, 0.0);
            vec3 light1Intensity = vec3(2.25, 2.25, 2.25);

            color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                          light1Pos,
                                          light1Intensity);
          }

          return color;
      }


      void main()
      {
          // Normalized pixel coordinates (from 0 to 1)
          vec2 uv = openfl_TextureCoordv;

          if(uv.x<0. || uv.x>1. || uv.y<0. || uv.y>1.){
            gl_FragColor = vec4(0,0,0,0);
            return;
          }

          vec2 fragCoord = uv * openfl_TextureSize.xy;

          vec3 col = vec3(0.);
          vec3 origin = vec3(camX/10., camY/10. + 14., 20.);
          vec3 dir = rayDirection(45.0 * (1.0/zoom), openfl_TextureSize.xy, fragCoord);
          float dist = getDist(origin, dir, 0.0, MAX_DIST);
          if(dist < MAX_DIST - EPSILON){
              vec3 p = origin + dist * dir;

              vec3 K_a = vec3(-1., -1, -1.);
              vec3 K_d = vec3(1., 1., 1.);
              vec3 K_s = vec3(0.0, 0.0, 0.0);
              float shininess = 1.0;

              vec3 color = phongIllumination(K_a, K_d, K_s, shininess, p, origin);

              vec3 n = getNormal(p);
              uv = p.xz / 4.;



              gl_FragColor = flixel_texture2D(floorTex, uv) * vec4(color, 1.0);
              return;

          }

          // Output to screen
          gl_FragColor = vec4(0.);
      }
    ')
    public function new(){
      super();
      camX.value = [0];
      floorX.value = [0];
      camY.value = [0];
      floorY.value = [0];
      zoom.value = [1];
      lightsOn.value=[true];

      floorTex.input = Paths.image("sunshineFloor").bitmap;
      floorTex.wrap = REPEAT;
      floorTex.filter = NEAREST;
    }
}


class SunshineFloor extends FlxSprite {
  public var daShader:SunshineStageShader;

  public var camOffX:Float = 0;
  public var camOffY:Float = 0;

  public function new(daX:Float, daY:Float){
    daShader = new SunshineStageShader();
    super();
    scrollFactor.set(0, 0);
    if(PlayState.currentRatio == '4:3')
      makeGraphic(FlxG.camera.width, FlxG.camera.height + 100, 0x00000000);
    else
      makeGraphic(FlxG.camera.width, FlxG.camera.height, 0x00000000);

    shader = daShader;

    flipY = true;
    daShader.floorX.value[0] = daX;
    daShader.floorY.value[0] = daY;
    x = (FlxG.camera.width - width) / 2;
    y = (FlxG.camera.height - height) / 2;
  }

  override public function update(elapsed:Float){
    daShader.camX.value[0] = daShader.floorX.value[0] + camOffX;
    daShader.camY.value[0] = daShader.floorY.value[0] + camOffY;
    daShader.zoom.value[0] = camera.zoom;
    scale.x = 1/camera.zoom;
    scale.y = 1/camera.zoom;
    super.update(elapsed);
  }

}
