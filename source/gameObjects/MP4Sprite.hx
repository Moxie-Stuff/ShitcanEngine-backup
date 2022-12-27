package gameObjects;

import flixel.FlxSprite;

/**
 * Compared to `MP4Handler`. This loads slower!!
 */
class MP4Sprite extends FlxSprite
{
	public var readyCallback:Void->Void;
	public var finishCallback:Void->Void;
	public var video:MP4Handler;
	public var volume:Float = 0;

	public function new(x:Float = 0, y:Float = 0, width:Float = 320, height:Float = 240, autoScale:Bool = true)
	{
		super(x, y);

		video = new MP4Handler(width, height, autoScale);
		video.alpha = 0;
		video.newVolume = volume;

		video.readyCallback = function()
		{
			loadGraphic(video.bitmapData);

			if (readyCallback != null)
				readyCallback();
		}

		video.finishCallback = function()
		{
			if (finishCallback != null){
				finishCallback();
				kill();
			}
			if(finishCallback == null)
				kill();
		};
	}

	/**
	 * Native video support for Flixel & OpenFL
	 * @param path Example: `your/video/here.mp4`
	 * @param repeat Repeat the video.
	 * @param pauseMusic Pause music until done video.
	 */
	public function playVideo(path:String, ?repeat:Bool = false, pauseMusic:Bool = false)
	{
		video.playVideo(path, repeat, pauseMusic);
	}

	public function pause()
	{
		video.pause();
	}

	public function resume()
	{
		video.resume();
	}
}
