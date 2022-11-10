package;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;

class PerspectiveSprite extends FlxSkewedSprite {
  override public function update(elapsed:Float){
    var camera = cameras[0]==null?FlxG.camera:cameras[0];
    //skew.x = (x - scrollX) / 40;
    // TODO: make proper perspective shit
    // maybe shaders or somethin? maybe use raymarching or some shit idfk
    super.update(elapsed);
  }
}
