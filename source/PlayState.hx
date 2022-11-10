package;

import flixel.graphics.FlxGraphic;
import scripts.*;
import scripts.FunkinLua;
#if desktop
import Discord.DiscordClient;
#end
import openfl.system.Capabilities;
import flixel.system.scaleModes.*;
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import openfl.filters.ShaderFilter;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import sys.thread.Thread;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import flixel.text.FlxText;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxSave;
import animateatlas.AtlasFrameMaker;
import Achievements;
import StageData;
import DialogueBoxPsych;
import Conductor.Rating;
import BGSprite.BGPerspectiveSprite;
import flixel.system.FlxAssets.FlxShader;

#if sys
import sys.FileSystem;
#end

using StringTools;

typedef LineData = {
	var character:String;
	var anim:String;
};

typedef PreloadResult = {
	var thread:Thread;
	var asset:String;
	@:optional var terminated:Bool;
}

typedef AssetPreload = {
	var path:String;
	@:optional var type:String;
	@:optional var library:String;
	@:optional var terminate:Bool;
}

class PlayState extends MusicBeatState
{
	public var whosTurn:String = '';
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
	public static var arrowSkin:String = '';
	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();

	//event variables
	#if (haxe >= "4.0.0")
	public var hscriptGlobals:Map<String, Dynamic> = new Map();
	#else
	public var hscriptGlobals:Map<String, Dynamic> = new Map<String, Dynamic>();
	#end

	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var extraMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var extraMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 3000;

	public var vocals:FlxSound;
	public var vocalsAlt:FlxSound;
	public var instAlt:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var playFields:FlxTypedGroup<PlayField>;
	@:isVar
	public var strumLineNotes(get, null):Array<StrumNote>;
	function get_strumLineNotes(){
		var notes:Array<StrumNote> = [];
		if(playFields!=null && playFields.length>0){
			for(field in playFields.members){
				for(sturm in field.members)
					notes.push(sturm);
				
			}
		}
		return notes;
	}
	public var opponentStrums:PlayField;
	public var playerStrums:PlayField;

	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var displayedHealth:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//EXESTAGESHITTT!!!!!!!!!!!1
	var uiEndless:Bool = false;
	var pillars2:BGSprite;
	var pillars1:BGSprite;

	var stardustBgPixel:FlxTiledSprite;
	var stardustFloorPixel:FlxTiledSprite;
	var stardustFurnace:FlxSprite;
	var hungryManJackTime:Int = 0;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled(default, set):Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camOverlay:FlxCamera; // shit that should go above all else and not get affected by camHUD changes, but still below camOther (pause menu, etc)
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var stageData:StageFile;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;

	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;

	var scoreTxtTween:FlxTween;

	var topBar:FlxSprite;
	var bottomBar:FlxSprite;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	public static var pixelSize:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Script shit
	public var hscriptExts = ["hx","hxs","hscript"];
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	public var funkyScripts:Array<FunkinScript> = [];
	public var hscriptArray:Array<FunkinHScript> = [];

	public var notetypeScripts:Map<String, FunkinScript> = []; // custom notetypes for scriptVer '1'
	public var eventScripts:Map<String, FunkinScript> = []; // custom events for scriptVer '1'

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var dodgeKeys:Dynamic;

	var precacheList:Map<String, String> = new Map<String, String>();

	//modifiers
	public static var currentRatio:String = '16:9';
	public var isFullscreen:Bool;

	// global exe shit (phantom notes etc)
	var dodgeCooldown:Float = 0;
	var dodgeTimer:Float = 0;
	var canDodge:Bool = false;
	var isDodging:Bool = false;
	var focusedChar:Character; // for cam x/y
	var pixelPerfectFilter:BitmapFilter;
	var gameFilters:Array<BitmapFilter> = [];
	var hudFilters:Array<BitmapFilter> = [];
	var phantomDrainTicker:Float = 0;
	var phantomDrain:Float = 0;
	var ringCount:Int = 0;
	var redVG:FlxSprite;
	var laserWarning:FlxSprite;
	var redVGSine:Float = 0;
	var flightPattern:String = '';
	var flightTimer:Float = 0; // Fleetwqy, Tails Doll
	var flightSpeed:Float = 1;

	// Starved
	var fearBar:FlxBar;
	var fearNo:Float = 0;
	var lastNoteNum:Int;
	var lastMissNum:Float;

	// Sunshine
	var dollShaderStage:SunshineFloor;
	var dollStage:BGSprite; // for low quality
	var vcrShader:VCRDistortionShader;
	// Chaos
	var dodgeHitbox:Float = 250;
	var laserDodges:Array<Float> = []; // just the times
	var chamberWall:FlxSprite;
	var chamberFloor:FlxSprite;
	var chamberRubble:FlxSprite;
	var chamberBeam:FlxSprite;
	var chamberBeamOn:FlxSprite;
	var chamberEmeralds:FlxSprite;
	var chamberSonic:FlxSprite;
	var chamberPebbles:FlxSprite;
	var chamberPorker:FlxSprite;
	// YCR
	var ycrStage:FlxTypedGroup<FlxSprite>;
	var greenHill:BGSprite;
	var pixelStageData:StageFile;

	// requital
	var whisperStageData:StageFile;
	public var pico:Character = null; // requital
	var picoSection:Bool = false;
	// round-a-bount needle
	var vocalsMuted:Bool = false;
	public var dad2:Character;
	public var dad2Group:FlxSpriteGroup;
	var conkCreet:BGSprite;
	var needleBuildings:BGSprite;
	var needleMoutains:BGSprite;
	var needleSky:BGSprite;
	var needleRuins:BGSprite;
	var floaty2:Float = 0;
	var needleFg:FlxSprite;
	var darkthing:BGSprite;
	var healthtex:FlxText;
	var uiNeedle:Bool = false;
	var irlTxt:FlxText;
	public function set_cpuControlled(val:Bool){
		if(playFields!=null && playFields.members.length > 0){
			for(field in playFields.members){
				if(field.isPlayer)
					field.autoPlayed = val;
				
			}
		}
		return cpuControlled = val;
	}
	function buildStage(stageName:String){
		switch (stageName)
		{
			case 'requite':
				whisperStageData = StageData.getStageFile("requiteWhisper");
				pico = new Character(0, 0, SONG.gfVersion);
				startCharacterPos(pico);
				extraMap.set(SONG.gfVersion, pico);
			case 'chamber':
				//(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?animArray:Array<String> = null, ?loop:Bool = false)
				chamberWall = new FlxSprite(-2379.05, -1211.1);
				chamberWall.frames = Paths.getSparrowAtlas("Chamber/Wall","exe");
				chamberWall.animation.addByPrefix("idle","Wall instance 1");
				chamberWall.animation.play("idle", true);
				chamberWall.antialiasing=true;
				chamberWall.scrollFactor.set(1, 1);
				add(chamberWall);

				chamberFloor = new FlxSprite(-2349, 921.25);
				chamberFloor.frames = Paths.getSparrowAtlas("Chamber/Floor","exe");
				chamberFloor.animation.addByPrefix("blue","floor blue");
				chamberFloor.animation.addByPrefix("yellow","floor yellow");
				chamberFloor.animation.play("yellow", true);
				chamberFloor.antialiasing=true;
				chamberFloor.scrollFactor.set(1, 1);
				add(chamberFloor);

				chamberRubble = new FlxSprite(-2629.05, -1344.05);
				chamberRubble.frames = Paths.getSparrowAtlas("Chamber/FleetwayBGshit","exe");
				chamberRubble.animation.addByPrefix("blue","BGblue");
				chamberRubble.animation.addByPrefix("yellow","BGyellow");
				chamberRubble.animation.play("yellow", true);
				chamberRubble.antialiasing=true;
				chamberRubble.scrollFactor.set(1, 1);
				add(chamberRubble);

				chamberBeam = new FlxSprite(0, -1376.95 - 200);
				chamberBeam.frames = Paths.getSparrowAtlas("Chamber/Emerald Beam","exe");
				chamberBeam.animation.addByPrefix("idle","Emerald Beam instance 1");
				chamberBeam.animation.play("idle", true);
				chamberBeam.antialiasing=true;
				chamberBeam.scrollFactor.set(1, 1);
				chamberBeam.visible=false;
				add(chamberBeam);

				chamberBeamOn = new FlxSprite(-300, -1376.95 - 200);
				chamberBeamOn.frames = Paths.getSparrowAtlas("Chamber/Emerald Beam Charged","exe");
				chamberBeamOn.animation.addByPrefix("idle","Emerald Beam Charged instance 1");
				chamberBeamOn.animation.play("idle", true);
				chamberBeamOn.antialiasing=true;
				chamberBeamOn.scrollFactor.set(1, 1);
				add(chamberBeamOn);

				chamberEmeralds = new FlxSprite(326.6, -191.75);
				chamberEmeralds.frames = Paths.getSparrowAtlas("Chamber/Emeralds","exe");
				chamberEmeralds.animation.addByPrefix("idle","TheEmeralds instance 1");
				chamberEmeralds.animation.play("idle", true);
				chamberEmeralds.antialiasing=true;
				chamberEmeralds.scrollFactor.set(1, 1);
				add(chamberEmeralds);

				chamberSonic = new FlxSprite(-225.05, 463.9);
				chamberSonic.frames = Paths.getSparrowAtlas("Chamber/The Chamber","exe");
				chamberSonic.animation.addByPrefix("fall","Chamber Sonic Fall", 24, false);
				chamberSonic.animation.play("fall", true);
				chamberSonic.animation.curAnim.curFrame = chamberSonic.animation.curAnim.numFrames;
				chamberSonic.antialiasing=true;
				chamberSonic.scrollFactor.set(1, 1);

				chamberPebbles = new FlxSprite(-562.15 + 100, 1043.3);
				chamberPebbles.frames = Paths.getSparrowAtlas("Chamber/pebles","exe");
				chamberPebbles.animation.addByPrefix("blue","pebles instance 1");
				chamberPebbles.animation.addByPrefix("yellow","pebles instance 2");
				chamberPebbles.animation.play("yellow", true);
				chamberPebbles.antialiasing=true;
				chamberPebbles.scrollFactor.set(1, 1);
				add(chamberPebbles);

				chamberPorker = new FlxSprite(2880.15, -762.8);
				chamberPorker.frames = Paths.getSparrowAtlas('Chamber/Porker Lewis');
				chamberPorker.animation.addByPrefix('porkerbop', 'Porker FG');
				chamberPorker.scrollFactor.set(1.4, 1);
				chamberPorker.antialiasing = true;

			case 'ycrPixel':
				pixelStageData = StageData.getStageFile(stageName);
				var pixelSize = pixelStageData.pixel_size==null?pixelSize:pixelStageData.pixel_size;
				greenHill = new BGSprite('SonicP2/GreenHill', -428.5 + 50 + 700, -449.35 + 25 + 105 + 50, 1, 1);
				greenHill.antialiasing=false;
				greenHill.scale.set(8, 8);
				greenHill.pixelPerfectPosition = true;
				greenHill.x = CoolUtil.quantize(greenHill.x, pixelSize);
				greenHill.y = CoolUtil.quantize(greenHill.y, pixelSize);
				add(greenHill);
			case 'ycr':
				ycrStage = new FlxTypedGroup<FlxSprite>();
				var sky:BGSprite = new BGSprite('SonicP2/sky', -414, -440, 0.7, 0.7);
				ycrStage.add(sky);

				var trees:BGSprite = new BGSprite('SonicP2/backtrees', -290.55, -298.3, 0.8, 0.8);
				trees.scale.set(1.2, 1.2);
				ycrStage.add(trees);

				var trees2:BGSprite = new BGSprite('SonicP2/trees', -290.55, -298.3, 0.9, 0.9);
				trees2.scale.set(1.2, 1.2);
				ycrStage.add(trees2);

				var ground:BGSprite = new BGSprite('SonicP2/ground', -309.95, -240.2, 1, 1);
				ground.scale.set(1.2, 1.2);
				ycrStage.add(ground);

				add(ycrStage);
				buildStage("ycrPixel");
				greenHill.visible = false;
			case 'sonicStage':
				var SKY:BGSprite = new BGSprite('PolishedP1/SKY', -222, -16 + 150, 1.0, 1.0);
				add(SKY);

				var hills:BGSprite = new BGSprite('PolishedP1/HILLS', -264, -156 + 150, 1.0, 1.0);
				add(hills);

				var floor2:BGSprite = new BGSprite('PolishedP1/FLOOR2', -345, -289 + 170, 0.975, 0.975);
				add(floor2);

				var floor1:BGSprite = new BGSprite('PolishedP1/FLOOR1',-297, -246 + 150, 1.0, 1.0);
				add(floor1);

				var eggman:BGSprite = new BGSprite('PolishedP1/EGGMAN', -198, -219 + 150, 0.96, 1.0);
				add(eggman);

				var tails:BGSprite = new BGSprite('PolishedP1/TAIL', -199 - 150, -259 + 150, 0.98, 1.0);
				add(tails);

				var knuckles:BGSprite = new BGSprite('PolishedP1/KNUCKLE', 185 + 100, -350 + 150, 0.95, 1.0);
				add(knuckles);

				var tailsondastick:BGSprite = new BGSprite('PolishedP1/TailsSpikeAnimated', -100, 50, 1.0, 1.0, ['Tails Spike Animated instance 1'], true);
				tailsondastick.setGraphicSize(Std.int(tailsondastick.width * 1.2));
				tailsondastick.updateHitbox();
				add(tailsondastick);
			case 'DollStageLQ':
				changeAspectRatio('saturn');
				stageData = StageData.getStageFile(stageName + "LQ");
				setStageData(stageData);
				dollStage = new BGSprite("TailsBG", -370, -130, 0.91, 0.91);
				dollStage.active=true;
				dollStage.setGraphicSize(Std.int(dollStage.width * 1.2));
				add(dollStage);

				vcrShader = new VCRDistortionShader();
				vcrShader.iTime.value = [0];
				vcrShader.vignetteOn.value = [false];
				vcrShader.perspectiveOn.value = [true];
				if(ClientPrefs.flashing){
					vcrShader.distortionOn.value = [true];
					vcrShader.glitchModifier.value = [0.1];
				}
				vcrShader.vignetteMoving.value = [false];
				vcrShader.iResolution.value = [FlxG.width, FlxG.height];
				vcrShader.noiseTex.input = Paths.image("noise2").bitmap;

				var filter = new ShaderFilter(vcrShader);

				var noteStatic = new FlxSprite();
				noteStatic.frames = Paths.getSparrowAtlas("daSTAT");

				noteStatic.setGraphicSize(camHUD.width, camHUD.height);
				noteStatic.cameras = [camOverlay];
				noteStatic.screenCenter();
				noteStatic.animation.addByPrefix("static", "staticFLASH", 24);
				noteStatic.alpha = 0.1;
				noteStatic.animation.play("static", true);

				add(noteStatic);

				gameFilters.push(filter);
				hudFilters.push(filter);
				camHUD.setFilters(hudFilters);
				camOverlay.setFilters(hudFilters);
				camGame.setFilters(gameFilters);
			case 'DollStage':

				//changeAspectRatio('saturn');
				if(ClientPrefs.lowQuality){
					buildStage("DollStageLQ");
					return;
				}else{
					changeAspectRatio('saturn');
					trace(FlxG.width, FlxG.height);
					dollShaderStage = new SunshineFloor(-120, -150.6);
					if(currentRatio == '4:3'){
						dollShaderStage.screenCenter(XY);
						dollShaderStage.y += 100;
					}
					boyfriendGroup.scrollFactor.set(0.775, 0.775);
					dadGroup.scrollFactor.set(0.775, 0.775);
					add(dollShaderStage);

				}
				// TODO: check shader toggle idk
				vcrShader = new VCRDistortionShader();
				vcrShader.iTime.value = [0];
				vcrShader.vignetteOn.value = [false];
				vcrShader.perspectiveOn.value = [true];
				if(ClientPrefs.flashing){
					vcrShader.distortionOn.value = [true];
					vcrShader.glitchModifier.value = [0.1];
				}
				vcrShader.vignetteMoving.value = [false];
				vcrShader.iResolution.value = [FlxG.width, FlxG.height];
				vcrShader.noiseTex.input = Paths.image("noise2").bitmap;

				var filter = new ShaderFilter(vcrShader);

				var noteStatic = new FlxSprite();
				noteStatic.frames = Paths.getSparrowAtlas("daSTAT");

				noteStatic.setGraphicSize(camHUD.width, camHUD.height);
				noteStatic.cameras = [camOverlay];
				noteStatic.screenCenter();
				noteStatic.animation.addByPrefix("static", "staticFLASH", 24);
				noteStatic.alpha = 0.1;
				noteStatic.animation.play("static", true);

				add(noteStatic);

				gameFilters.push(filter);
				hudFilters.push(filter);
				camHUD.setFilters(hudFilters);
				camOverlay.setFilters(hudFilters);
				camGame.setFilters(gameFilters);
			case 'endlessForest': // lmao
				PlayState.SONG.splashSkin = 'noteSplashes';
				var SKY:BGSprite = new BGSprite('FunInfiniteStage/sonicFUNsky', -600, -200, 1.0, 1.0);
				add(SKY);

				var bush:BGSprite = new BGSprite('FunInfiniteStage/Bush 1', -42, 171, 1.0, 1.0);
				add(bush);

				pillars2 = new BGSprite('FunInfiniteStage/Majin Boppers Back', 182, -100, 1.0, 1.0, ['MajinBop2 instance 1']);
				add(pillars2);

				var bush2:BGSprite = new BGSprite('FunInfiniteStage/Bush2', 132, 354, 1.0, 1.0);
				add(bush2);

				pillars1 = new BGSprite('FunInfiniteStage/Majin Boppers Front', -169, -167, 1.0, 1.0, ['MajinBop1 instance 1']);
				add(pillars1);

				var floor:BGSprite = new BGSprite('FunInfiniteStage/floor BG', -340, 660, 1.0, 1.0);
				add(floor);

			case 'starved-pixel':
				isPixelStage = true;
				GameOverSubstate.characterName = 'bf-sonic-gameover';
				GameOverSubstate.deathSoundName = 'prey-death';
				GameOverSubstate.loopSoundName = 'prey-loop';
				GameOverSubstate.endSoundName = 'prey-retry';


				stardustBgPixel = new FlxTiledSprite(Paths.image('starved/stardustBg'), 4608, 2832, true, true);
				stardustBgPixel.scrollFactor.set(0.4, 0.4);
				/*stardustBgPixel.scale.x = 5;
				stardustBgPixel.scale.y = 5;*/
				//stardustBgPixel.y += 600;
				//stardustBgPixel.x += 1000;
				//stardustBgPixel.velocity.set(-2000, 0);

				stardustFloorPixel = new FlxTiledSprite(Paths.image('starved/stardustFloor'), 4608, 2832, true, true);
				//stardustFloorPixel.setGraphicSize(Std.int(pizzaHutStage.width * 1.5));

				stardustBgPixel.visible = false;
				stardustFloorPixel.visible = false;

				stardustFurnace = new FlxSprite(-500, 1450);
				stardustFurnace.frames = Paths.getSparrowAtlas('starved/Furnace_sheet');
				stardustFurnace.animation.addByPrefix('idle', 'Furnace idle', 24, true);
				stardustFurnace.animation.play('idle');
				stardustFurnace.scale.x = 6;
				stardustFurnace.scale.y = 6;
				stardustFurnace.antialiasing = false;
				stardustFurnace.visible = false;

				/*stardustFloorPixel.scale.x = 6;
				stardustFloorPixel.scale.y = 6;*/
				//stardustFloorPixel.y += 600;
				//stardustFloorPixel.x += 1000;
				//stardustFloorPixel.velocity.set(-2500, 0);
				stardustBgPixel.screenCenter();
				stardustFloorPixel.screenCenter();

				add(stardustBgPixel);
				add(stardustFurnace);
			case 'starvedLair':
				// fhjdslafhlsa dead hedgehogs

				/*———————————No hedgehogs?———————————
				⠀⣞⢽⢪⢣⢣⢣⢫⡺⡵⣝⡮⣗⢷⢽⢽⢽⣮⡷⡽⣜⣜⢮⢺⣜⢷⢽⢝⡽⣝
				⠸⡸⠜⠕⠕⠁⢁⢇⢏⢽⢺⣪⡳⡝⣎⣏⢯⢞⡿⣟⣷⣳⢯⡷⣽⢽⢯⣳⣫⠇
				⠀⠀⢀⢀⢄⢬⢪⡪⡎⣆⡈⠚⠜⠕⠇⠗⠝⢕⢯⢫⣞⣯⣿⣻⡽⣏⢗⣗⠏⠀
				⠀⠪⡪⡪⣪⢪⢺⢸⢢⢓⢆⢤⢀⠀⠀⠀⠀⠈⢊⢞⡾⣿⡯⣏⢮⠷⠁⠀⠀
				⠀⠀⠀⠈⠊⠆⡃⠕⢕⢇⢇⢇⢇⢇⢏⢎⢎⢆⢄⠀⢑⣽⣿⢝⠲⠉⠀⠀⠀⠀
				⠀⠀⠀⠀⠀⡿⠂⠠⠀⡇⢇⠕⢈⣀⠀⠁⠡⠣⡣⡫⣂⣿⠯⢪⠰⠂⠀⠀⠀⠀
				⠀⠀⠀⠀⡦⡙⡂⢀⢤⢣⠣⡈⣾⡃⠠⠄⠀⡄⢱⣌⣶⢏⢊⠂⠀⠀⠀⠀⠀⠀
				⠀⠀⠀⠀⢝⡲⣜⡮⡏⢎⢌⢂⠙⠢⠐⢀⢘⢵⣽⣿⡿⠁⠁⠀⠀⠀⠀⠀⠀⠀
				⠀⠀⠀⠀⠨⣺⡺⡕⡕⡱⡑⡆⡕⡅⡕⡜⡼⢽⡻⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				⠀⠀⠀⠀⣼⣳⣫⣾⣵⣗⡵⡱⡡⢣⢑⢕⢜⢕⡝⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				⠀⠀⠀⣴⣿⣾⣿⣿⣿⡿⡽⡑⢌⠪⡢⡣⣣⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				⠀⠀⠀⡟⡾⣿⢿⢿⢵⣽⣾⣼⣘⢸⢸⣞⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				⠀⠀⠀⠀⠁⠇⠡⠩⡫⢿⣝⡻⡮⣒⢽⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				—————————————————————————————*/

				GameOverSubstate.deathSoundName = 'starved-death';
				GameOverSubstate.loopSoundName = 'starved-loop';
				GameOverSubstate.endSoundName = 'starved-retry';
				GameOverSubstate.characterName = 'bf-starved-die';

				defaultCamZoom = 0.85;
				var burgerKingCities = new BGSprite('starved/city', -100, 0, 1, 0.9);
				burgerKingCities.setGraphicSize(Std.int(burgerKingCities.width * 1.5));
				add(burgerKingCities);

				var mcdonaldTowers = new BGSprite('starved/towers', -100, 0, 1, 0.9);
				mcdonaldTowers.setGraphicSize(Std.int(mcdonaldTowers.width * 1.5));
				add(mcdonaldTowers);

				var pizzaHutStage = new BGSprite('starved/stage', -100, 0, 1, 0.9);
				pizzaHutStage.setGraphicSize(Std.int(pizzaHutStage.width * 1.5));
				add(pizzaHutStage);

				// sonic died
				var deadHedgehog = new BGSprite('starved/sonicisfuckingdead', 0, 100, 1, 0.9);
				deadHedgehog.setGraphicSize(Std.int(deadHedgehog.width * 0.65));
				//deadHedgehog.isGore=true; // neb lole add this
				add(deadHedgehog);

				// hes still dead

				var wendysLight = new BGSprite('starved/light', 0, 0, 1, 0.9);
				wendysLight.setGraphicSize(Std.int(wendysLight.width * 1.2));

			case 'needle':
				/**
								READ HOODRATS YOU MONGALOIDS
				https://www.webtoons.com/en/challenge/hoodrats/list?title_no=694588
				https://www.webtoons.com/en/challenge/hoodrats/list?title_no=694588
				https://www.webtoons.com/en/challenge/hoodrats/list?title_no=694588
				https://www.webtoons.com/en/challenge/hoodrats/list?title_no=694588
				https://www.webtoons.com/en/challenge/hoodrats/list?title_no=694588
								READ IT, NOW!! !! !! !! !!
				**/

				GameOverSubstate.characterName = 'bf-needle-die';
				GameOverSubstate.loopSoundName = 'needlemouse-loop';
				GameOverSubstate.endSoundName = 'needlemouse-retry';

				needleSky = new BGSprite('needlemouse/sky', -725, -200, 0.7, 0.9);
				// needleSky.setGraphicSize(Std.int(needleSky.width * 0.9));
				add(needleSky);

				needleMoutains = new BGSprite('needlemouse/mountains', -700, -175, 0.8, 0.9);
				needleMoutains.setGraphicSize(Std.int(needleMoutains.width * 1.1));
				add(needleMoutains);

				needleRuins = new BGSprite('needlemouse/ruins', -775, -310, 1, 0.9);
				needleRuins.setGraphicSize(Std.int(needleRuins.width * 1.4));
				add(needleRuins);

				needleBuildings = new BGSprite('needlemouse/buildings', -1000, -100, 1, 0.9);
				// needleBuildings.setGraphicSize(Std.int(needleBuildings.width * 0.85));
				add(needleBuildings);

				conkCreet = new BGSprite('needlemouse/CONK_CREET', -775, -310, 1, 0.9);
				conkCreet.setGraphicSize(Std.int(conkCreet.width * 1.4));
				add(conkCreet);

				darkthing = new BGSprite('needlemouse/Black', 0, 0, 1, 0.9);
				darkthing.setGraphicSize(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3));
				darkthing.alpha = 0;
				add(darkthing);

				needleFg = new FlxSprite(-690, -80).loadGraphic(Paths.image("needlemouse/fg"));
				needleFg.setGraphicSize(Std.int(needleFg.width * 1.1));
				needleFg.scrollFactor.set(1, 0.9);
				darkthing.cameras = [camGame];
				//darkthing.blend = ADD;


				vcrShader = new VCRDistortionShader();
				vcrShader.iTime.value = [0];
				vcrShader.vignetteOn.value = [false];
				vcrShader.perspectiveOn.value = [true];
				if(ClientPrefs.flashing){
					vcrShader.distortionOn.value = [true];
					vcrShader.glitchModifier.value = [0.1];
				}
				vcrShader.vignetteMoving.value = [false];
				vcrShader.iResolution.value = [FlxG.width, FlxG.height];
				vcrShader.noiseTex.input = Paths.image("noise2").bitmap;

				var filter = new ShaderFilter(vcrShader);

				var noteStatic = new FlxSprite();
				noteStatic.frames = Paths.getSparrowAtlas("daSTAT");

				noteStatic.setGraphicSize(camHUD.width, camHUD.height);
				noteStatic.cameras = [camOverlay];
				noteStatic.screenCenter();
				noteStatic.animation.addByPrefix("static", "staticFLASH", 24);
				noteStatic.alpha = 0.1;
				noteStatic.animation.play("static", true);

				add(noteStatic);

				gameFilters.push(filter);
				hudFilters.push(filter);
				camHUD.setFilters(hudFilters);
				camOverlay.setFilters(hudFilters);
				camGame.setFilters(gameFilters);
				uiNeedle = true;

			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			case 'spooky': //Week 2
				if(!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -FlxG.width, -FlxG.height, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				CoolUtil.precacheSound('thunder_1');
				CoolUtil.precacheSound('thunder_2');

			case 'philly': //Week 3
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
				phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				add(phillyWindow);
				phillyWindow.alpha = 0;

				if(!ClientPrefs.lowQuality) {
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

			case 'limo': //Week 4
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!ClientPrefs.lowQuality) {
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					//PRECACHE SOUND
					CoolUtil.precacheSound('dancerdeath');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': //Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!ClientPrefs.lowQuality) {
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				CoolUtil.precacheSound('Lights_Shut_off');

			case 'mallEvil': //Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': //Week 6 - Senpai, Roses
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!ClientPrefs.lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!ClientPrefs.lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': //Week 6 - Thorns
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				/*if(!ClientPrefs.lowQuality) { //Does this even do something?
					var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
					var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
				}*/
				var posX = 400;
				var posY = 200;
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				} else {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}
		}
	}

	function setStageData(stageData:StageFile){
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.pixel_size != null)
			pixelSize = stageData.pixel_size;
		else
			pixelSize = daPixelZoom;


		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		if(boyfriendGroup==null)
			boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if(dadGroup==null)
			dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}

		if(dad2Group==null)
			dad2Group = new FlxSpriteGroup(DAD_X, DAD_Y);
		else{
			dad2Group.x = DAD_X;
			dad2Group.y = DAD_Y;
		}

		if(gfGroup==null)
			gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}

	function returnCharacterPreload(characterName:String):Array<AssetPreload>{
		var char = Character.getCharacterFile(characterName);
		var name:String = 'icons/' + char.healthicon;
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char.healthicon; //Older versions of psych engine's support
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon

		return [
			{path: char.image}, // spritesheet
			{path: name} // icon
		];
	}

	override public function create()
	{

		pixelPerfectFilter = new ShaderFilter(new FlxShader());
		Paths.clearStoredMemory();

		isFullscreen = FlxG.fullscreen; // hehe.

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		dodgeKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('dodge'));

		//Ratings
		ratingsData.push(new Rating('sick')); //default rating

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOverlay = new FlxCamera();
		camOther = new FlxCamera();
		camOverlay.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOverlay);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame]; // why is this deprecated replacing this with setDefaultDrawTarget breaks everything -neb
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		arrowSkin = SONG.arrowSkin;

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		topBar = new FlxSprite(0, -170).makeGraphic(1280, 170, FlxColor.BLACK);
		bottomBar = new FlxSprite(0, 720).makeGraphic(1280, 170, FlxColor.BLACK);


		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = SONG.stage;
		//trace('stage is: ' + curStage);
		if(SONG.stage == null || SONG.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				default:
					curStage = 'stage';
			}
		}
		SONG.stage = curStage;

		stageData = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		setStageData(stageData); // TODO: maybe add a "extraStageDatas" for stuff like requital's whisper section, and the pixel section of YCR

		#if loadBenchmark
		var startLoadTime = Sys.time();
		#end

		if(ClientPrefs.multicoreLoading){ // should probably move all of this to its own preload class
			#if loadBenchmark
			var currentTime = Sys.time();
			trace("started preload at " + currentTime);
			#end
			var shitToLoad:Array<AssetPreload> = [
				{path: "sick"},
				{path: "good"},
				{path: "bad"},
				{path: "shit"},
				{path: "healthBar", library: "shared"},
				{path: "RedVG", library: "exe"},
				{path: "combo"}
			];
			for (number in 0...10)
				shitToLoad.push({path: 'num$number'});


			if(arrowSkin!=null && arrowSkin.trim()!='' && arrowSkin.length > 0){
				shitToLoad.push({
					path: arrowSkin
				});
			}

			if(SONG.splashSkin != null && SONG.splashSkin.length > 0){
				shitToLoad.push({
					path: SONG.splashSkin
				});
			}else{
				shitToLoad.push({
					path: "BloodSplash"
				});
			}

			shitToLoad.push({
				path: "NOTE_assets"
			});

			if(isPixelStage){
				for (number in 0...10)
					shitToLoad.push({path: 'pixelUI/num${number}-pixel', library: "shared"});

				shitToLoad.push({path: "pixelUI/sick-pixel", library: "shared"});
				shitToLoad.push({path: "pixelUI/good-pixel", library: "shared"});
				shitToLoad.push({path: "pixelUI/bad-pixel", library: "shared"});
				shitToLoad.push({path: "pixelUI/shit-pixel", library: "shared"});
				shitToLoad.push({path: "pixelUI/combo-pixel", library: "shared"});

				shitToLoad.push({
					path: "pixelUI/NOTE_assets",
					library: "shared",
				});
				if(ClientPrefs.noteSkin=='Quants'){
					shitToLoad.push({
						path: "pixelUI/QUANTNOTE_assets",
						library: "shared"
					});
				}
			}else{
				if(ClientPrefs.noteSkin=='Quants'){
					shitToLoad.push({
						path: "QUANTNOTE_assets"
					});
				}
			}


			if(ClientPrefs.timeBarType != 'Disabled'){
				shitToLoad.push({
					path: "timeBar",
					library: "shared"
				});
			}
			if(stageData.preloadStrings != null){
				var lib = stageData.directory.trim().length > 0?stageData.directory:null;
				for(i in stageData.preloadStrings)
					shitToLoad.push({path: i, library: lib });
			}

			if(stageData.preload != null){
				for(i in stageData.preload)
					shitToLoad.push(i);
			}

			var characters:Array<String> = [
				SONG.player1,
				SONG.player2
			];
			if(!stageData.hide_girlfriend){
				characters.push(SONG.gfVersion);
			}

			for(character in characters){
				for(data in returnCharacterPreload(character))
					shitToLoad.push(data);

			}

			for(event in getEvents()){
				for(data in preloadEvent(event)){ // preloads everythin for events
					if(!shitToLoad.contains(data))
						shitToLoad.push(data);
				}
			}

			shitToLoad.push({
				path: '${Paths.formatToSongPath(SONG.song)}/Inst',
				type: 'SONG'
			});

			if (SONG.needsVoices)
				shitToLoad.push({
					path: '${Paths.formatToSongPath(SONG.song)}/Voices',
					type: 'SONG'
				});

			switch(SONG.song.toLowerCase()){
				case 'round-a-bout':
					shitToLoad.push({
						path: '${Paths.formatToSongPath(SONG.song)}/InstAlt',
						type: 'SONG'
					});
					shitToLoad.push({
						path: '${Paths.formatToSongPath(SONG.song)}/VoicesAlt',
						type: 'SONG'
					});
			}

			// TODO: go through shitToLoad and clear it of repeats as to not waste time loadin shit that already exists
			for(shit in shitToLoad)
				trace(shit.path);


			var threadLimit:Int = ClientPrefs.loadingThreads; //Math.floor(Std.parseInt(Sys.getEnv("NUMBER_OF_PROCESSORS")));
			if(shitToLoad.length>0 && threadLimit > 1){
				// thanks shubs -neb
				for(shit in shitToLoad)
					if(shit.terminate)shit.terminate=false; // do not

				var count = shitToLoad.length;

				if(threadLimit > shitToLoad.length)threadLimit=shitToLoad.length; // only use as many as it needs

				var sprites:Array<FlxSprite> = [];
				var threads:Array<Thread> = [];

				var finished:Bool = false;
				trace("loading " + count + " items with " + threadLimit + " threads");
				var main = Thread.current();
				var loadIdx:Int = 0;
				for (i in 0...threadLimit) {
					var thread:Thread = Thread.create( () -> {
						while(true){
							var toLoad:Null<AssetPreload> = Thread.readMessage(true); // get the next thing that should be loaded
							if(toLoad!=null){
								if(toLoad.terminate==true)break;
								// just loads the graphic
								#if traceLoading
								trace("loading " + toLoad.path);
								#end
								switch(toLoad.type){
									case 'SOUND':
										Paths.returnSound("sounds", toLoad.path, toLoad.library);
										#if traceLoading
										trace("loaded " + toLoad);
										#end
									case 'MUSIC':
										Paths.returnSound("music", toLoad.path, toLoad.library);
										#if traceLoading
										trace("loaded " + toLoad);
										#end
									case 'SONG':
										Paths.returnSound("songs", toLoad.path, toLoad.library);
										#if traceLoading
										trace("loaded " + toLoad);
										#end
									default:
										#if traceLoading
										trace('grabbin da graphic ${toLoad.library}:${toLoad.path}');
										#end
										var graphic = Paths.returnGraphic(toLoad.path, toLoad.library, true);
										#if traceLoading
										trace(graphic);
										#end
										if(graphic!=null){
											var sprite = new FlxSprite().loadGraphic(graphic);
											sprite.alpha = 0.001;
											add(sprite);
											sprites.push(sprite);
											#if traceLoading
											trace("loaded " + toLoad, graphic, sprite);
											#end
										}#if traceLoading
										else
											trace("Could not load " + toLoad);

										#end
								}
								#if traceLoading
								trace("getting next asset");
								#end
								main.sendMessage({ // send message so that it can get the next thing to load
									thread: Thread.current(),
									asset: toLoad,
									terminated: false
								});
							}
						}
						main.sendMessage({ // send message so that it can get the next thing to load
							thread: Thread.current(),
							asset: '',
							terminated: true
						});
						return;
					});
					threads.push(thread);
				}
				for(thread in threads)
					thread.sendMessage(shitToLoad.pop()); // gives the thread the top thing to load

				while(loadIdx < count){
					var res:Null<PreloadResult> = Thread.readMessage(true); // whenever a thread loads its asset, it sends a message to get a new asset for it to load
					if(res!=null){
						if(res.terminated){
							if(threads.contains(res.thread)){
								threads.remove(res.thread); // so it wont have a message sent at the end
							}
						}else{
							loadIdx++;
							#if traceLoading
							trace("loaded " + loadIdx + " out of " + count);
							#end
							if(shitToLoad.length > 0)
								res.thread.sendMessage(shitToLoad.pop()); // gives the thread the next thing it should load
							else
								res.thread.sendMessage({path: '', library:'', terminate: true}); // terminate the thread

						}

					}
				};
				trace(loadIdx, count);
				var idx:Int = 0;
				for(t in threads){
					t.sendMessage({path: '', library: '', terminate: true}); // terminate all threads
					trace("terminating thread " + idx);
					idx++;
				}

				finished = true;
				#if loadBenchmark
				var finishedTime = Sys.time();
				trace("preloaded in " + (finishedTime - currentTime) + " (at " + finishedTime + ")");
				#else
				trace("preloaded");
				#end
				for(sprite in sprites)
					remove(sprite);
			}
		}
		buildStage(curStage);

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}


		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		switch (curStage)
		{
			case 'needle':
				add(gfGroup);
				add(dad2Group);
				add(dadGroup);
				add(boyfriendGroup);
			default:
				add(gfGroup);
				add(dadGroup);
				add(boyfriendGroup);
		}

		switch(curStage)
		{
			case 'spooky':
				add(halloweenWhite);
			case "endlessForest":
				add(new BGSprite('FunInfiniteStage/majin FG1', 1126, 903, 1.0, 1.0, ['majin front bopper1'], true));
				add(new BGSprite('FunInfiniteStage/majin FG2', -393, 871, 1.0, 1.0, ['majin front bopper2'], true));
			case "starved-pixel":
				add(stardustFloorPixel);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{	
					if(!filesPushed.contains(file)){
						if(file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else{
							for(ext in hscriptExts){
								if(file.endsWith('.$ext')){
									var script = FunkinHScript.fromFile(folder + file);
									hscriptArray.push(script);
									funkyScripts.push(script);
									filesPushed.push(file);
									break;
								}
							}
						}
					}
				}
			}
		}


		// STAGE SCRIPTS
		#if MODS_ALLOWED
			var doPush:Bool = false;
			var baseScriptFile:String = 'stages/' + curStage;
			var exts = [#if LUA_ALLOWED "lua" #end];
			for (e in hscriptExts)exts.push(e);
			for (ext in exts){
				if(doPush)break;
				var baseFile = '$baseScriptFile.$ext'; 
				var files = [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPreloadPath(baseFile)];
				for(file in files){
					if (FileSystem.exists(file))
					{
						if (ext == 'lua')
						{
							var script = new FunkinLua(file);
							luaArray.push(script);
							funkyScripts.push(script);
							doPush = true;
						}
						else
						{
							var script = FunkinHScript.fromFile(file);
							hscriptArray.push(script);
							funkyScripts.push(script);
							doPush = true;
						}
						if(doPush)break;
					}
				}
			}

		#end

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				default:
					gfVersion = 'gf';
			}

			switch(Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}
		if (curStage == 'needle')
			{
				dad2 = new Character(0, 0, 'Sarah');
				startCharacterPos(dad2, true);
				dad2Group.add(dad2);
			}


		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);
		dadMap.set(dad.curCharacter, dad);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}else{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		switch(curStage)
		{
			case 'limo':
				resetFastCar();
				insert(members.indexOf(gfGroup) - 1, fastCar);

			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				insert(members.indexOf(dadGroup) - 1, evilTrail);
			case 'chamber':
				insert(members.indexOf(boyfriendGroup) + 1, chamberSonic);
				insert(members.indexOf(boyfriendGroup) + 1, chamberPorker);
		}

		switch(curStage)
		{
			case 'requite':
				boyfriendGroup.add(pico);
			case 'needle':
				add(needleFg);

				dad2.alpha = 0;


				dad2Group.x -= 30;
				dad2Group.y -= 240;
				// TODO: unshitify needlemouse code



				//boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.9));
		}


		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			if(!uiEndless)
				timeTxt.text = SONG.song;
			else
				timeTxt.text = "Infinity";

		}

		if(uiNeedle)
			{
				irlTxt = new FlxText(900,600, 400, "", 46);
				irlTxt.setFormat(Paths.font("vcr.ttf"), 70, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				irlTxt.scrollFactor.set();
				irlTxt.alpha = 1;
				irlTxt.borderSize = 2;

				add(irlTxt);
			}

		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		playFields = new FlxTypedGroup<PlayField>();
		add(playFields);
		add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		if(uiNeedle)
			{
				timeBar.alpha = 1;
				timeTxt.x = 980;
				timeTxt.y = 10;
				timeTxt.size = 40;
				timeBar.visible = false;
				timeBarBG.visible = false;
			}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		if (dad.curCharacter == 'starved') // keep this in mind :shrug:
		{
			var fearUi = new FlxSprite().loadGraphic(Paths.image('fearbar'));
			fearUi.scrollFactor.set();
			fearUi.screenCenter();
			fearUi.x += 580;
			fearUi.y -= 50;

			var fearUiBg = new FlxSprite(fearUi.x, fearUi.y).loadGraphic(Paths.image('fearbarBG'));
			fearUiBg.scrollFactor.set();
			fearUiBg.screenCenter();
			fearUiBg.x += 580;
			fearUiBg.y -= 50;
			add(fearUiBg);

			fearBar = new FlxBar(fearUi.x + 30, fearUi.y + 5, BOTTOM_TO_TOP, 21, 275, this, 'fearNo', 0, 100);
			fearBar.scrollFactor.set();
			fearBar.visible = true;
			fearBar.numDivisions = 1000;
			fearBar.createFilledBar(0x00000000, 0xFFFF0000);

			add(fearBar);
			add(fearUi);

			fearUiBg.cameras = [camHUD];
			fearBar.cameras = [camHUD];
			fearUi.cameras = [camHUD];
		}

		// startCountdown();

		generateSong(SONG.song);

		/*
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				var lua:FunkinLua = new FunkinLua(luaToLoad);
				luaArray.push(lua);
				funkyScripts.push(lua);
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					var lua:FunkinLua = new FunkinLua(luaToLoad);
					luaArray.push(lua);
					funkyScripts.push(lua);
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				var lua:FunkinLua = new FunkinLua(luaToLoad);
				luaArray.push(lua);
				funkyScripts.push(lua);
			}
			#end
		}
		for (event in eventPushedMap.keys())
		{
			#if MODS_ALLOWED
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
					var lua:FunkinLua = new FunkinLua(luaToLoad);
					luaArray.push(lua);
					funkyScripts.push(lua);
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					var lua:FunkinLua = new FunkinLua(luaToLoad);
					luaArray.push(lua);
					funkyScripts.push(lua);
				}
			}
			#elseif sys
			var luaToLoad:String = Paths.getPreloadPath('custom_events/' + event + '.lua');
			if(OpenFlAssets.exists(luaToLoad))
			{
				var lua:FunkinLua = new FunkinLua(luaToLoad);
				luaArray.push(lua);
				funkyScripts.push(lua);
			}
			#end
		}
		#end*/
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		redVG = new FlxSprite().loadGraphic(Paths.image("RedVG", "exe"));
		redVG.setGraphicSize(FlxG.width, FlxG.height);
		redVG.updateHitbox();
		redVG.screenCenter(XY);
		redVG.visible=false;
		redVG.alpha = 0;
		add(redVG);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = camHUD.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * camHUD.height;
		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'displayedHealth', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();



		if(!uiNeedle)
			{
				scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
				scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				scoreTxt.scrollFactor.set();
				scoreTxt.borderSize = 1.25;
				scoreTxt.visible = !ClientPrefs.hideHud;
			}
		else
			{

				scoreTxt = new FlxText(-500, 0, FlxG.width, "", 36);
				scoreTxt.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				scoreTxt.scrollFactor.set();
				scoreTxt.borderSize = 1.25;
				scoreTxt.visible = !ClientPrefs.hideHud;

			}
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		playFields.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
		redVG.cameras = [camHUD];
		topBar.cameras = [camOther];
		bottomBar.cameras = [camOther];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + Paths.formatToSongPath(SONG.song) + '/' ));// using push instead of insert because these should run after everything else
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(!filesPushed.contains(file)){
						if(file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else{
							for(ext in hscriptExts){
								if(file.endsWith('.$ext')){
									var script = FunkinHScript.fromFile(folder + file);
									hscriptArray.push(script);
									funkyScripts.push(script);
									filesPushed.push(file);
									break;
								}
							}
						}
					}
				}
			}
		}

		var daSong:String = Paths.formatToSongPath(curSong);

		switch (daSong)
		{
			case 'chaos':
				skipCountdown = true;
				camHUD.alpha = 0;
				if(dad.curCharacter == 'fleetway'){
					dad.visible=false;
					dad.setPosition(600, 425);
					snapCamFollowToPos(900, 700);
					flightPattern = 'disabled';
				}
			case 'prey':
				skipCountdown = true;
			default:
				trace("wow");
		}

		if (!seenCutscene)
		{
			switch (daSong)
			{
				case 'chaos':
					if(curStage=='chamber' && dad.curCharacter == 'fleetway'){
						chamberSonic.animation.play("fall", true);
						chamberSonic.animation.curAnim.pause();
						chamberSonic.animation.curAnim.curFrame = 0;

						chamberBeam.visible = true;
						chamberBeamOn.visible = false;
						chamberFloor.animation.play("blue", true);
						chamberRubble.animation.play("blue", true);
						chamberPebbles.animation.play("blue", true);
						inCutscene = true;
						new FlxTimer().start(0.5, function(t:FlxTimer){
							new FlxTimer().start(1, function(t:FlxTimer)
							{
								FlxTween.tween(FlxG.camera, {zoom: 1.5}, 3, {ease: FlxEase.cubeOut});
								FlxG.sound.play(Paths.sound('robot', 'exe'));
								FlxG.camera.flash(FlxColor.RED, 0.2);
								new FlxTimer().start(1, function(tm:FlxTimer)
								{
									FlxG.sound.play(Paths.sound('sonic', 'exe'));
									chamberSonic.animation.curAnim.resume();
									chamberSonic.animation.curAnim.curFrame = 0;
									new FlxTimer().start(4, function(tmr:FlxTimer){
										startCountdown();
										FlxG.sound.play(Paths.sound('beam', 'exe'));
										FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.2, {ease: FlxEase.cubeOut});
										FlxG.camera.shake(0.02, 0.2);
										FlxG.camera.flash(FlxColor.WHITE, 0.2);
										chamberFloor.animation.play("yellow", true);
										chamberRubble.animation.play("yellow", true);
										chamberPebbles.animation.play("yellow", true);
										chamberBeam.visible = false;
										chamberBeamOn.visible = true;
									});
								});
							});
						});
					}else
						startCountdown();

				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);


				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnScripts('onCreatePost', []);

		super.create();

		Paths.clearUnusedMemory();

		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		#if loadBenchmark
		var endLoadTime = Sys.time();
		trace("fully loaded in " + (endLoadTime - startLoadTime));
		#end

		CustomFadeTransition.nextCamera = camOther;
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors() {
		if(callOnHScripts('reloadHealthBarColors', [healthBar])!= Globals.Function_Stop){
			if(curStage=='requite')
				healthBar.createFilledBar(FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]),
			FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
			else
				healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
		}
			

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) {
			doPush = true;
		}
		#end

		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			var lua:FunkinLua = new FunkinLua(luaFile);
			luaArray.push(lua);
			funkyScripts.push(lua);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartObjects.exists(tag))return modchartObjects.get(tag);
		if(modchartSprites.exists(tag))return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag))return modchartTexts.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
		#if sys
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);
			#if sys
			if(FileSystem.exists(fileName)) {
			#else
			if(OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;
			}
		}

		if(foundFile) {
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
				startAndEnd();
			}
			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
			startAndEnd();
		}
		#end
		startAndEnd();
	}

	function startAndEnd()
	{
		if(endingSong){
			endSong();
		}
		else{
			startCountdown();
		}
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', []);
		trace(ret);
		if(ret != Globals.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			//generateStaticArrows(0, skipArrowStartTween );
			//generateStaticArrows(1, skipArrowStartTween );
			
			playerStrums = new PlayField(ClientPrefs.middleScroll ? (FlxG.width / 2):(FlxG.width / 2 + (FlxG.width / 4)), strumLine.y, 4, boyfriend, true, cpuControlled);
			opponentStrums = new PlayField(ClientPrefs.middleScroll?(FlxG.width / 2):(FlxG.width/2 - (FlxG.width/4)), strumLine.y, 4, dad, false, true);
			if (!ClientPrefs.opponentStrums)
				opponentStrums.baseAlpha = 0;
			else if (ClientPrefs.middleScroll)
				opponentStrums.baseAlpha = 0.35;
			opponentStrums.offsetReceptors = ClientPrefs.middleScroll;

			playerStrums.noteHitCallback = goodNoteHit;
			opponentStrums.noteHitCallback = opponentNoteHit;

			callOnScripts('preReceptorGeneration', []); // can be used to change field properties just before the receptors get generated, so you dont have to re-generate them

			opponentStrums.generateReceptors();
			playerStrums.generateReceptors();
			
			playerStrums.fadeIn(isStoryMode || skipArrowStartTween);
			opponentStrums.fadeIn(isStoryMode || skipArrowStartTween);

			playFields.add(opponentStrums);
			playFields.add(playerStrums);
			callOnScripts('postReceptorGeneration', [isStoryMode || skipArrowStartTween]); // incase you wanna do anything JUST after

			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnScripts('onCountdownStarted', []);

			var swagCounter:Int = 0;


			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}
				if(pico!=null){
					if (tmr.loopsLeft % pico.danceEveryNumBeats == 0 && pico.animation.curAnim != null && !pico.animation.curAnim.name.startsWith('sing') && !pico.stunned)
					{
						pico.dance();
					}
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);

					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						add(countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha * note.playField.baseAlpha;
				});
			
				callOnScripts('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				if(modchartObjects.exists('note${daNote.ID}'))modchartObjects.remove('note${daNote.ID}');
				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				if(modchartObjects.exists('note${daNote.ID}'))modchartObjects.remove('note${daNote.ID}');
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}

		i = laserDodges.length - 1;
		while(i >= 0){
			var dodge = laserDodges[i];
			if(dodge - 350 < time)
				laserDodges.remove(dodge);

			--i;

		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		vocals.time = time;
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();

		if (instAlt != null)
		{
			FlxG.log.add("Hey google say bruh for me rq");
			vocalsAlt.play();
			instAlt.play();
		}


		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			if (instAlt != null) instAlt.pause();
			if (vocalsAlt != null) vocalsAlt.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	function shouldPush(event:EventNote){
		switch(event.event){
			case 'Light Control':
				return curStage.startsWith("DollStage");
			case 'Whisper':
				return curStage == 'requite';
			default:
				if (eventScripts.exists(event.event))
				{
					var eventScript:Dynamic = eventScripts.get(event.event);
					var returnVal:Any = true;
					trace(returnVal);
					if (eventScript.scriptType == 'lua')
					{
						returnVal = callScript(eventScript, "shouldPush", [event.value1, event.value2]); 
					}
					else
					{
						returnVal = callScript(eventScript, "shouldPush", [event]); 
					}
					var fuck:Bool = returnVal != false;
					trace(returnVal, returnVal != false, fuck);
					return returnVal != false;
				}
		}
		return true;
	}

	function checkGenesis(time:Float){
		var isPixel:Bool = false;
		for(idx in 0...eventNotes.length){ // SHOULD be sorted by time by now, so this should work fine
			var event = eventNotes[idx];
			if(event.strumTime <= time){
				if(event.event=='Genesis'){
					var value:Int = Std.parseInt(event.value1);
					if (Math.isNaN(value))
						value = 0;

					isPixel = value==0?true:(value==1?false:isPixel);
				}
			}else{
				break;
			}
		}

		return isPixel;
	}

	function checkMajin(time:Float){
		var check:Bool = false;
		for(idx in 0...eventNotes.length){ // SHOULD be sorted by time by now, so this should work fine
			var event = eventNotes[idx];
			if(event.strumTime <= time){
				if(event.event=='Endless Notes')
					check = true;
				else if(event.event=='Unendless Notes')
					check = false;

			}else
				break;

		}

		return check;
	}

	function getEvents(){
		var songData = SONG;
		var events:Array<EventNote> = [];
		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					if(!shouldPush(subEvent))continue;
					events.push(subEvent);
				}
			}
		// this is mainly to shut my syntax highlighting up
		#if MODS_ALLOWED
		}
		#else
		}
		#end

		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				if(!shouldPush(subEvent))continue;
				events.push(subEvent);
			}
		}


		return events;
	}

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		if (PlayState.SONG.song == 'Round-a-bout')
		{
			vocalsAlt = new FlxSound().loadEmbedded(Paths.voicesAlt(PlayState.SONG.song));
			instAlt = new FlxSound().loadEmbedded(Paths.instAlt(PlayState.SONG.song));
			FlxG.sound.list.add(vocalsAlt);
			FlxG.sound.list.add(instAlt);
		}

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		/*var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					if(!shouldPush(subEvent))continue;
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				if(!shouldPush(subEvent))continue;
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}*/

		// loads note types
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var type:Dynamic = songNotes[3];
				if(!Std.isOfType(type, String)) type = editors.ChartingState.noteTypeList[type];

				if (!noteTypeMap.exists(type)) {
					firstNotePush(type);
					noteTypeMap.set(type, true);
				}
			}
		}

		for (notetype in noteTypeMap.keys())
		{
			var doPush:Bool = false;
			var baseScriptFile:String = 'custom_notetypes/' + notetype;
			var exts = [#if LUA_ALLOWED "lua" #end];
			for (e in hscriptExts)
				exts.push(e);
			for (ext in exts)
			{
				if (doPush)
					break;
				var baseFile = '$baseScriptFile.$ext';
				var files = [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPreloadPath(baseFile)];
				for (file in files)
				{
					if (FileSystem.exists(file))
					{
						if (ext == 'lua')
						{
							var script = new FunkinLua(file, notetype);
							luaArray.push(script);
							funkyScripts.push(script);
							notetypeScripts.set(notetype, script);
							doPush = true;
						}
						else
						{
							var script = FunkinHScript.fromFile(file, notetype);
							hscriptArray.push(script);
							funkyScripts.push(script);
							notetypeScripts.set(notetype, script);
							doPush = true;
						}
						if (doPush)
							break;
					}
				}
			}
		}

		// loads events
		for(event in getEvents()){
			if (!eventPushedMap.exists(event.event))
			{
				eventPushedMap.set(event.event, true);
				firstEventPush(event);
			}
		}

		for (event in eventPushedMap.keys())
		{
			var doPush:Bool = false;
			var baseScriptFile:String = 'custom_events/' + event;
			var exts = [#if LUA_ALLOWED "lua" #end];
			for (e in hscriptExts)
				exts.push(e);
			for (ext in exts)
			{
				if (doPush)
					break;
				var baseFile = '$baseScriptFile.$ext';
				var files = [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPreloadPath(baseFile)];
				for (file in files)
				{
					if (FileSystem.exists(file))
					{
						if (ext == 'lua')
						{
							var script = new FunkinLua(file, event);
							luaArray.push(script);
							funkyScripts.push(script);
							trace("event script " + event);
							eventScripts.set(event, script);
							script.call("onLoad", []);
							doPush = true;
						}
						else
						{
							var script = FunkinHScript.fromFile(file, event);
							hscriptArray.push(script);
							funkyScripts.push(script);
							trace("event script " + event);
							eventScripts.set(event, script);
							script.call("onLoad", []);
							doPush = true;
						}
						if (doPush)
							break;
					}
				}
			}
		}
		
		for(subEvent in getEvents()){
			subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
			eventNotes.push(subEvent);
			eventPushed(subEvent);
		}
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}

		laserDodges.sort(laserSort);
		var lastBFNotes:Array<Note> = [null,null,null,null];
		var lastDadNotes:Array<Note> = [null,null,null,null];
		// Should populate these w/ nulls depending on keycount -neb
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var isGenesis = checkGenesis(daStrumTime); // this can 100% be improved and I will in the future -neb
				var pixelStage = isPixelStage;
				var skin = arrowSkin;

				var type:Dynamic = songNotes[3];
				if(!Std.isOfType(type, String)) type = editors.ChartingState.noteTypeList[type];

				if((isGenesis) && Note.defaultNotes.contains(type) && !pixelStage)isPixelStage=true;
				if((checkMajin(daStrumTime) || type == 'MajinNote') && ClientPrefs.noteSkin != 'Quants')
					PlayState.arrowSkin = 'Majin_Notes';


				// TODO: maybe make a checkNoteType n shit but idfk im lazy
				// or maybe make a "Transform Notes" event which'll make notes which don't change texture change into the specified one


				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				if(gottaHitNote){
					var lastBFNote = lastBFNotes[swagNote.noteData];
					if(lastBFNote!=null){
						if(Math.abs(swagNote.strumTime-lastBFNote.strumTime)<=3 ){
							swagNote.kill();
							continue;
						}
					}
					lastBFNotes[swagNote.noteData]=swagNote;
				}else{
					var lastDadNote = lastDadNotes[swagNote.noteData];
					if(lastDadNote!=null){
						if(Math.abs(swagNote.strumTime-lastDadNote.strumTime)<=3 ){
							swagNote.kill();
							continue;
						}
					}
					lastDadNotes[swagNote.noteData]=swagNote;
				}
				
				if(gf!=null)
					swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				else
					swagNote.extraNote = (section.gfSection && (songNotes[1]<4));

				swagNote.noteType = type;

				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				swagNote.ID = unspawnNotes.length;
				modchartObjects.set('note${swagNote.ID}', swagNote);
				unspawnNotes.push(swagNote);

				if(swagNote.noteScript != null && swagNote.noteScript.scriptType == 'lua'){
					callScript(swagNote.noteScript, 'setupNote', [
						unspawnNotes.indexOf(swagNote),
						Math.abs(swagNote.noteData),
						swagNote.noteType,
						swagNote.isSustainNote,
						swagNote.ID
					]);
				}

				var floorSus:Int = Math.round(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.extraNote = swagNote.extraNote;
						sustainNote.noteType = type;
						if(sustainNote==null || !sustainNote.alive)break;
						sustainNote.ID = unspawnNotes.length;
						modchartObjects.set('note${sustainNote.ID}', sustainNote);
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						if (sustainNote.noteScript != null && sustainNote.noteScript.scriptType == 'lua')
						{
							callScript(sustainNote.noteScript, 'setupNote', [
								unspawnNotes.indexOf(sustainNote),
								Math.abs(sustainNote.noteData),
								sustainNote.noteType,
								sustainNote.isSustainNote,
								sustainNote.ID
							]);
						}

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				arrowSkin = skin;

				if(isGenesis)isPixelStage = pixelStage;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

			}
			daBeats += 1;
		}
		lastDadNotes = null;
		lastBFNotes = null;

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		checkEventNote();
		generatedMusic = true;
	}

	// everything returned here gets preloaded by the preloader up-top ^
	function preloadEvent(event:EventNote):Array<AssetPreload>{
		var preload:Array<AssetPreload> = [];
		switch(event.event){
			case 'Fleetway Laser':
				preload.push({
					path: "spacebar_icon",
					library: "exe"
				});
				for(data in returnCharacterPreload('fleetwaylaser'))
					preload.push(data);

			case "Change Character":
				return returnCharacterPreload(event.value2);
			case 'Genesis':
				if(curStage == 'ycr'){
					var characters:Array<String> = [];
					var value:Int = Std.parseInt(event.value1);
					if (Math.isNaN(value))
						value = 0;
					switch (value)
					{
						case 0:
							characters = [
								"bfpickel",
								"gf-pixel",
								"pixelrunsonic"
							];
						case 1:
							// nothin, these should ALREADY be preloaded cus its just SONG.player1, etc
					}
					for(char in characters){
						for(data in returnCharacterPreload(char)){
							preload.push(data);
						}
					}
				}
			case 'Whisper':
				if(curStage == 'requite'){
					var characters:Array<String> = [];
					var value:Int = Std.parseInt(event.value1);
					if (Math.isNaN(value))
						value = 0;
					switch (value)
					{
						case 0:
							characters = [
								"requital-whisper",
								"bf-whisper",
								"pico-whisper"
							];
						case 1:
							// nothin, these should ALREADY be preloaded cus its just SONG.player1, etc
					}
					for(char in characters){
						for(data in returnCharacterPreload(char)){
							preload.push(data);
						}
					}
				}
		}
		return preload;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Fleetway Laser':
				addCharacterToList('fleetwaylaser', 1);
				canDodge = true;
			case 'Fleetway':
				addCharacterToList('fleetway', 1);
				//addCharacterToList('fleetway-anims2', 1);
				//addCharacterToList('fleetway-anims3', 1);
				//addCharacterToList('fleetlines', 1);
			case 'Whisper':
				if(curStage == 'requite' && event.value1 == '0'){
					addCharacterToList('requital-whisper', 1);
					addCharacterToList('bf-whisper', 0);

					var picer:Character = new Character(0, 0, 'pico-whisper');
					extraMap.set('pico-whisper', picer);
					boyfriendGroup.add(picer);
					startCharacterPos(picer);
					picer.alpha = 0.00001;
					if(!extraMap.exists(SONG.gfVersion)){
						if(pico.curCharacter == SONG.gfVersion){
							extraMap.set(SONG.gfVersion, pico);
						}else{
							var picer:Character = new Character(0, 0, SONG.gfVersion);
							extraMap.set(SONG.gfVersion, picer);
							boyfriendGroup.add(picer);
							startCharacterPos(picer);
							picer.alpha = 0.00001;
						}
					}
				}


			case 'Genesis':
				if(curStage == 'ycr'){
					var value:Int = Std.parseInt(event.value1);
					if (Math.isNaN(value))
						value = 0;
					switch (value)
					{
						case 0:
							addCharacterToList('bfpickel', 0);
							addCharacterToList('gf-pixel', 2);
							addCharacterToList('pixelrunsonic', 1);
						case 1:
							addCharacterToList(SONG.player1, 0);
							addCharacterToList(SONG.gfVersion, 2);
							addCharacterToList(SONG.player2, 1);
					}
				}
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				addCharacterToList(event.value2, charType);
			default:
				if (eventScripts.exists(event.event))
				{
					var eventScript:Dynamic = eventScripts.get(event.event);
					if (eventScript.scriptType == 'lua')
					{
						callScript(eventScript, "onPush",[event.value1, event.value2]); 
					}
					else
					{
						callScript(eventScript, "onPush", [event]); 
					}
				}

		}
	}

	function firstNotePush(type:String){
		switch(type){
			case 'Static Note':
				staticNoteMiss(true); // preloading
			default:
				if (notetypeScripts.exists(type))
				{
					var script:Dynamic = notetypeScripts.get(type);
					callScript(script, "onLoad", []);
				}
		}
	}

	function firstEventPush(event:EventNote){
		switch (event.event)
		{
			case 'Simple Jumpscare':
				simpleJumpscare(true); // preload popup jumpscare
			case 'Static Flash':
				flashStatic(true); // preload static
			case 'Jumpscare':
				fullJumpscare(true); // preload jumpscare
			case 'Fleetway Laser':
				laserWarning = new FlxSprite(0, 600);
				laserWarning.frames = Paths.getSparrowAtlas('spacebar_icon', 'exe');
				laserWarning.animation.addByPrefix('a', 'spacebar', 0, false);
				laserWarning.animation.play('a', true);
				laserWarning.animation.curAnim.curFrame = 2;
				laserWarning.scale.x = .5;
				laserWarning.scale.y = .5;
				laserWarning.screenCenter();
				laserWarning.x -= 60;
				laserWarning.cameras = [camHUD];
				laserWarning.visible = false;
				insert(members.indexOf(redVG) + 1, laserWarning);
			default:
				// should PROBABLY turn this into a function, callEventScript(eventNote, "func") or something, idk
				if (eventScripts.exists(event.event))
				{
					var eventScript:Dynamic = eventScripts.get(event.event);
					if (eventScript.scriptType == 'lua')
					{
						callScript(eventScript, "onLoad", [event.value1, event.value2]);
					}
					else
					{
						callScript(eventScript, "onLoad", [event]);
					}
				}
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2]);

		if (eventScripts.exists(event.event)){
			var eventScript:Dynamic = eventScripts.get(event.event);
			if(eventScript.scriptType == 'lua'){
				returnedValue = callScript(eventScript, "getOffset", [event.value1, event.value2]);
			}else{
				returnedValue = callScript(eventScript, "getOffset", [event]);
			}
		}
		if(returnedValue != 0)
			return returnedValue;

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
			case 'Fleetway Laser':
				var time = event.strumTime;
				laserDodges.push(time);
				return (13 * (1/24))* 1000; // because the laser for fleetway actually HITS at like frame 13 so offset it a bit
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function laserSort(Obj1:Float, Obj2:Float):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1, Obj2);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua

	function removeStatics(player:Int)
	{
		var isPlayer:Bool = player==1;
		for(field in playFields.members){
			if(field.isPlayer==isPlayer || player==-1){
				field.clearReceptors();
			}
		}
	}

	// player 0 is opponent player 1 is player. Set to -1 to affect both players

	function resetStrumPositions(player:Int, ?baseX:Float){
		if(!generatedMusic)return;

		var isPlayer:Bool = player == 1;
		for (field in playFields.members)
		{
			if (field.isPlayer == isPlayer || player == -1)
			{
				var x = field.baseX;
				if(baseX!=null)x = baseX;

				field.forEachAlive( function(strum:StrumNote){
					strum.x = x;
					strum.postAddedToGroup();
					if (field.offsetReceptors)
						field.doReceptorOffset(strum);
				});
			}
		}
		
	}
	function regenStaticArrows(player:Int){
		var isPlayer:Bool = player==1;
		for(field in playFields.members){
			if(field.isPlayer==isPlayer || player==-1){
				field.generateReceptors();
				field.fadeIn(true);
			}
		}
	}
	
	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				if (instAlt != null) instAlt.pause();
				if (vocalsAlt != null) vocalsAlt.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnScripts('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();

		if (instAlt != null) // note to self: This still sometimes get's stuttery because of it being unsycned.
		{
			instAlt.pause();
			instAlt.time = Conductor.songPosition;
			instAlt.play();
		}
		if (vocalsAlt != null)
		{
			vocalsAlt.pause();
			vocalsAlt.time = Conductor.songPosition;
			vocalsAlt.play();
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	var starvedSpeed:Float = 15;
	var camElapsed:Float = 0; // sunshine
	override public function update(elapsed:Float)
	{
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/
		floaty2 += 0.01;

		if (instAlt != null)
		{
			switch(PlayState.SONG.song) // if more songs end up having an alt inst and vocs
			{
				case "Round-a-bout":
					if(health < 1){
						if(vocalsMuted){
							vocals.volume = 0;
							vocalsAlt.volume = 0;
						}else{
							vocalsAlt.volume = 1 - health;
							vocals.volume = health;
						}
						instAlt.volume = 1 - health;
						FlxG.sound.music.volume = health;
					}else{
						if(vocalsMuted){
							vocals.volume = 0;
							vocalsAlt.volume = 0;
						}else{
							vocalsAlt.volume = 1;
							vocals.volume = 1;
						}
						instAlt.volume = 0;
						vocalsAlt.volume = 0;
						vocals.volume = 1;
						FlxG.sound.music.volume = 1;
					}


			}
		}

		if(curStage == 'needle')
		{
			dad2.y += Math.sin(floaty2) * 0.5;
		}
		callOnScripts('onUpdate', [elapsed]);

		if (currentRatio != '16:9') FlxG.fullscreen = false;

		switch (curStage)
		{
			default:
		}
		if(phantomDrainTicker > 0){
			var drain = phantomDrain * (elapsed/(1/120));
			// should make sure it never drains more than it should?
			// I think? idk I hate math
			// -Neb

			if(drain > phantomDrain * (phantomDrainTicker / (1/120)))
				drain = phantomDrain * (phantomDrainTicker / (1/120));
			phantomDrainTicker -= elapsed;

			if(phantomDrainTicker<=0){
				phantomDrainTicker=0;
				phantomDrain = 0;
			}
			health -= drain;
		}
		var targetSpeed:Float = 15;
		switch (hungryManJackTime)
		{
			case 1:
				targetSpeed = 35;
			case 2:
				targetSpeed = 50;
			default:
				targetSpeed = 25;
		}
		starvedSpeed = FlxMath.lerp(starvedSpeed, targetSpeed, 0.3*(elapsed/(1/60)));
		if (targetSpeed - starvedSpeed < 0.2)
		{
			starvedSpeed = targetSpeed;
		}
		if (curStage == 'starved-pixel')
		{
			stardustBgPixel.scrollX -= (starvedSpeed * stardustBgPixel.scrollFactor.x) * (elapsed/(1/120));
			stardustFloorPixel.scrollX -= starvedSpeed * (elapsed/(1/120));
		}

		var baseX = dadGroup.x + dad.positionArray[0];
		var baseY = dadGroup.y + dad.positionArray[1];

		var targetX:Float = baseX;
		var targetY:Float = baseY;
		var isFlying:Bool = dad.curCharacter.startsWith("tailsdoll") || dad.curCharacter.startsWith("fleetway");
		if(isFlying){
			flightTimer+= 0.03 * (elapsed/(1/120)) * flightSpeed;
			switch(flightPattern){
				case 'circle' | 'circling':
					targetX += Math.cos(flightTimer) * 140;
					targetY += Math.sin(flightTimer) * 100;
				case 'figure8':
					targetX += Math.sin(flightTimer) * 200;
					targetY += (Math.sin(flightTimer) * Math.cos(flightTimer)) * 200;
				case 'hover' | 'hovering':
					targetY += Math.sin(flightTimer) * 100;
				case 'disabled':
					targetX = dad.x;
					targetY = dad.y;

				default:
			}

			if(flightPattern!='disabled'){
				var lerpVal:Float = CoolUtil.boundTo(0.05 * (elapsed/(1/120)), 0, 1);
				dad.x = FlxMath.lerp(dad.x, targetX, lerpVal);
				dad.y = FlxMath.lerp(dad.y, targetY, lerpVal);
			}
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			if(curStage=='DollStage'){
				lerpVal = 0;
				camElapsed += elapsed;
				if(camElapsed >= 1/30){
					lerpVal = CoolUtil.boundTo(camElapsed * 2.4 * cameraSpeed, 0, 1);
					camElapsed = 0;
				}
			}
			var xOff:Float = 0;
			var yOff:Float = 0;
			var curSection:Int = Math.floor(curStep / 16);

			xOff = focusedChar.camOffX;
			yOff = focusedChar.camOffY;
			updateCamFollow();

			if(isFlying && focusedChar == dad){
				if(flightPattern!=''){
					xOff = 0;
					yOff = 0;
				}
			}

			if(dollShaderStage!=null && curStage == 'DollStage'){ // hard-coded to dollstage!!
				var daX:Float = xOff / 20;
				var daY:Float = yOff / 15;

				if(currentRatio == '4:3'){
					daY = yOff/20;
					if(focusedChar == boyfriend){
						daX += 25;
					}else{
						daX -= 32.5;
						daY -= 7;
					}
				}else{
					if(focusedChar == boyfriend){
						daX += 20;
					}else{
						daX -= 32.5;
						daY -= 7;
					}
				}

				if(focusedChar==dad){
					var diffX = dad.x - baseX;
					var diffY = dad.y - baseY;
					if(currentRatio == '4:3'){
						daX += diffX / 20;
						daY += diffY / 20;
					}else{
						daX += diffX / 20;
						daY += diffY / 15;
					}
				}


				daX *= (camGame.width / 1280);
				daY *= (camGame.height / 720);
				if(snap3DCamera){
					snap3DCamera = false;
					dollShaderStage.camOffX = daX;
					dollShaderStage.camOffY = -daY;
				}else{
					dollShaderStage.camOffX = FlxMath.lerp(dollShaderStage.camOffX, daX, lerpVal);
					dollShaderStage.camOffY = FlxMath.lerp(dollShaderStage.camOffY, -daY, lerpVal);
				}


			}else
				snap3DCamera = false;


			switch(currentRatio){
				case '4:3':
					yOff -= 120;


			}
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x+xOff, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y+yOff, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		if (dad.curCharacter == 'starved')
		{
			//gathers all notes and checks if they died

			if (lastMissNum < songMisses) fearNo += 11; // Putting a 1 to combat missed notes being removed

			lastNoteNum = notes.length + unspawnNotes.length;

			fearBar.filledCallback = function()
			{
				health = 0;
			}
			// this is such a shitcan method i really should come up with something better tbf
			if (fearNo >= 50 && fearNo < 59)
				health -= 0.1 * elapsed;
			else if (fearNo >= 60 && fearNo < 69)
				health -= 0.13 * elapsed;
			else if (fearNo >= 70 && fearNo < 79)
				health -= 0.17 * elapsed;
			else if (fearNo >= 80 && fearNo < 89)
				health -= 0.20 * elapsed;
			else if (fearNo >= 90 && fearNo < 99)
				health -= 0.35 * elapsed;

			if (health <= 0.01)
			{
				health = 0.01;
			}
			lastMissNum = songMisses; // silly
		}
		if(vcrShader!=null)
			vcrShader.iTime.value[0] = Conductor.songPosition / 1000;


		if(dodgeTimer > 0){
			dodgeTimer -= elapsed*1000;
			if(dodgeTimer<0)dodgeTimer=0;
		}
		if(dodgeCooldown > 0){
			dodgeCooldown -= elapsed*1000;
			if(dodgeCooldown<0)dodgeCooldown=0;
		}

		if(canDodge){
			if(laserDodges.length>0){
				var dodgeTime = laserDodges[0];
				var diff = dodgeTime - Conductor.songPosition;
				laserWarning.visible = diff <= 1250;
				if(laserWarning.visible)
					laserWarning.animation.curAnim.curFrame	= diff <= dodgeHitbox?0:2;

				if(diff<=0){
					if(dodgeTimer > 0 || cpuControlled){
						trace("DID A DODGE");
						if(dad.curCharacter != 'fleetwaylaser'){
							dad.animation.finishCallback = null;
							changeCharacter("fleetwaylaser",1);
							dad.playAnim("Laser Blast", true);
							dad.animation.finishCallback = function(anim:String){
								if(anim == "Laser Blast"){
									dad.animation.finishCallback = null;
									changeCharacter('fleetway', 1);
								}
							}
						}

						if(dad.animation.curAnim.name != 'Laser Blast')
							dad.playAnim("Laser Blast",true);

						dad.animation.curAnim.curFrame = 13;


						dodgeTimer = 0; // reset dodge timer
						dodgeCooldown = 0; // reset dodge cooldown
						boyfriend.playAnim("dodge", true);
						FlxG.camera.zoom += 0.15;
						camHUD.zoom += 0.3;
						boyfriend.animTimer = 0.75; // play the dodge anim for 0.75 seconds
					}else{
						trace("FLEETWAY GOT YOU");
						var oldAnim = boyfriend.animation.curAnim.name;
						boyfriend.playAnim("hurt",true);
						boyfriend.animTimer = 5;
						boyfriend.animation.finishCallback = function(anim:String){
							boyfriend.animation.finishCallback=null;
							if(anim=='hurt')boyfriend.animTimer = 0;
						}
						songScore -= 2000;
						combo = 0;
						songMisses++;
						if(boyfriend.curCharacter == 'bf-super' && oldAnim!='hurt') // if you are hurt then gl
							health -= 1.5;
						else
							health = -1000;
					}

					laserDodges.shift();
					if(laserDodges.length>0){ // clears out stacked dodges, etc
						while(laserDodges.length>0 && laserDodges[0] - Conductor.songPosition <= 5){
							trace(laserDodges[0]);
							laserDodges.shift();
						}
						trace(laserDodges[0]);

					}
				}
			}else{
				trace("dodging gone :)");
				canDodge = false;
				if(laserWarning!=null){
					laserWarning.visible=false;
					if(members.contains(laserWarning))
						remove(laserWarning); // its the last dodge, so we can safely discard it
				}

			}
		}

		displayedHealth = health;
		if(curStage == 'requite'){
			displayedHealth = 2 - health;
		}

		for(key in notetypeScripts.keys()){
			var script = notetypeScripts.get(key);
			script.call("update", [elapsed]);
		}

		for (key in eventScripts.keys())
		{
			var script = eventScripts.get(key);
			script.call("update", [elapsed]);
		}
		
		callOnHScripts('update', [elapsed]);
		super.update(elapsed);

		checkEventNote();

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);
		if(!uiNeedle)
		{
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
			if(ratingName != '?')
				scoreTxt.text += ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;
		}
		else
		{
			var time = DateTools.format(Date.now(), "%r");
			var months = DateTools.format(Date.now(), "%b");
			scoreTxt.text = 'Health: ' + Std.int(((health / 2) * 100)) + '%' +'\nScore: ' + songScore + '\nMisses: ' + songMisses + '\nRating: ' + ratingName + ' - ' + ratingFC + "\nAccuracy: " + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)';
			irlTxt.text =  Std.string(time) + '\n' + Std.string(months) + ' 1998';
		}

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if(redVG.visible){
			redVGSine += 2 * elapsed;
			redVG.alpha = Math.sin(redVGSine);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', []);
			if(ret != Globals.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 1 / 1000 chance for Gitaroo Man easter egg
				/*if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					cancelMusicFadeTween();
					MusicBeatState.switchState(new GitarooPause());
				}
				else {*/
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				if (instAlt != null) instAlt.pause();
				if (vocalsAlt != null) vocalsAlt.pause();
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				//}

				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		if(curStage == 'requite'){
			var x = iconP1.x;
			iconP1.flipX = true;
			iconP2.flipX = true;
			iconP1.x = iconP2.x;
			iconP2.x = x;
		}

		if (health > 2)
			health = 2;

		var percent = (health / 2) * 100;
		if (percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;




		if(uiNeedle)
		{
			iconP1.alpha = 0;
			iconP2.alpha = 0;
			healthBar.visible = false;
			healthBarBG.visible = false;
		}

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						if(!uiEndless){
							timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
						}else{
							songPercent = 1;
							timeTxt.text = 'Infinity';
						}
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1));
			camOverlay.zoom = camHUD.zoom;
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;//shit be werid on 4:3
			if(songSpeed < 1) time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				var doSpawn:Bool= true;
				if(dunceNote.noteScript != null && dunceNote.noteScript.scriptType == 'lua'){
					doSpawn = callScript(dunceNote.noteScript, "spawnNote", [dunceNote])!= Globals.Function_Stop;
				}
				if (doSpawn)
					doSpawn = callOnHScripts('onSpawnNote', [dunceNote]) != Globals.Function_Stop;
				if(doSpawn){
					if(dunceNote.desiredPlayfield!=null)
						dunceNote.desiredPlayfield.addNote(dunceNote);
					else if (dunceNote.parent != null && dunceNote.parent.playField!=null)
						dunceNote.parent.playField.addNote(dunceNote);
					else{
						for(field in playFields.members){
							if(field.isPlayer == dunceNote.mustPress){
								field.addNote(dunceNote);
								break;
							}
						}
					}
					if(dunceNote.playField==null){
						var deadNotes:Array<Note> = [dunceNote];
						for(note in dunceNote.tail)
							deadNotes.push(note);
						
						for(note in deadNotes){
							note.active = false;
							note.visible = false;
							note.ignoreNote = true;

							if (modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
							note.kill();
							unspawnNotes.remove(note);
							note.destroy();
						}
						break;
					}
					notes.insert(0, dunceNote);
					dunceNote.spawned=true;
					var index:Int = unspawnNotes.indexOf(dunceNote);
					unspawnNotes.splice(index, 1);
					callOnLuas('onSpawnNote', [
						notes.members.indexOf(dunceNote),
						dunceNote.noteData,
						dunceNote.noteType,
						dunceNote.isSustainNote,
						dunceNote.ID
					]);
					callOnHScripts('onSpawnNotePost', [dunceNote]);
					if (dunceNote.noteScript != null)
					{
						var script:Dynamic = dunceNote.noteScript;
						if (script.scriptType == 'lua')
						{
							callScript(script, 'postSpawnNote', [
								notes.members.indexOf(dunceNote),
								Math.abs(dunceNote.noteData),
								dunceNote.noteType,
								dunceNote.isSustainNote,
								dunceNote.ID
							]);
						}
						else
						{
							callScript(script, "postSpawnNote", [dunceNote]);
						}
					}
				}else{
					var deadNotes:Array<Note> = [dunceNote];
					for(note in dunceNote.tail)
						deadNotes.push(note);
					
					for(note in deadNotes){
						note.active = false;
						note.visible = false;
						note.ignoreNote = true;

						if (modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
						note.kill();
						unspawnNotes.remove(note);
						note.destroy();
					}
				}
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				}
			}

			if(feelingTheSunshine){
				sunshineFadeTimer += 0.025 * (elapsed/(1/120));
				if(sunshineFadeTimer>1)sunshineFadeTimer=1;
				if(sunshineFadeTimer > 0)
					camHUD.alpha = 1 - sunshineFadeTimer;
				else
					camHUD.alpha = 1;

			}else
				sunshineFadeTimer = 0;


			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var field = daNote.playField;

				var strumX:Float = field.members[daNote.noteData].x;
				var strumY:Float = field.members[daNote.noteData].y;
				var strumAngle:Float = field.members[daNote.noteData].angle;
				var strumDirection:Float = field.members[daNote.noteData].direction;
				var strumAlpha:Float = field.members[daNote.noteData].alpha;
				var strumScroll:Bool = field.members[daNote.noteData].downScroll;

				strumX += daNote.offsetX * (daNote.scale.x / daNote.baseScaleX);
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll) //Downscroll
				{
					//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
				}
				else //Upscroll
				{
					//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
				}

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle)
					daNote.angle = strumDirection - 90 + strumAngle;

				if(daNote.copyAlpha)
					daNote.alpha = strumAlpha;

				if(daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if(daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if(strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
							if(PlayState.isPixelStage) {
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							} else {
								daNote.y -= 19;
							}
						}
						daNote.y += (daNote.daWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				if(field.inControl && field.autoPlayed){
					if(!daNote.wasGoodHit && !daNote.ignoreNote){
						if(daNote.isSustainNote){
							if(daNote.canBeHit)
								field.noteHitCallback(daNote, field);
							
						}else{
							if(daNote.strumTime <= Conductor.songPosition)
								field.noteHitCallback(daNote, field);
							
						}
					}
					
				}

				var center:Float = strumY + daNote.daWidth / 2;
				if (field.members[daNote.noteData].sustainReduce
					&& daNote.isSustainNote
					&& (daNote.playField.playerControls || !daNote.ignoreNote) &&
					(!daNote.playField.playerControls || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					if (daNote.playField.playerControls && !field.autoPlayed && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					if(modchartObjects.exists('note${daNote.ID}'))modchartObjects.remove('note${daNote.ID}');
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', []);
			if(ret != Globals.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				if (instAlt != null) instAlt.stop();
				if (vocalsAlt != null) vocalsAlt.stop();
				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	function flashStatic(preloading:Bool=false, opaque:Bool = false, mute:Bool = false){
		var noteStatic = new FlxSprite();
		noteStatic.frames = Paths.getSparrowAtlas("daSTAT");

		noteStatic.setGraphicSize(camOther.width, camOther.height);
		noteStatic.cameras = [camOther];
		noteStatic.screenCenter();
		noteStatic.animation.addByPrefix("static", "staticFLASH", 24, false);

		if(preloading){
			CoolUtil.precacheSound("staticBUZZ");
			noteStatic.alpha = 0.01;
			new FlxTimer().start(0.1, function(tmr:FlxTimer){
				noteStatic.visible=false;
				noteStatic.alpha = 0;
				remove(noteStatic);
			});
		}else{
			if(opaque)
				noteStatic.alpha = 1;
			else
				noteStatic.alpha = FlxG.random.float(0.1, 0.5);

			if(!mute)FlxG.sound.play(Paths.sound("staticBUZZ"), 1);
			noteStatic.animation.finishCallback = function(name: String){
				noteStatic.visible=false;
				noteStatic.alpha = 0;
				remove(noteStatic);
			}
			noteStatic.animation.play("static", true);
		}


		add(noteStatic);
	}

	function fullJumpscare(preloading:Bool=false){
		var jump = new FlxSprite();
		jump.frames = Paths.getSparrowAtlas("sonicJUMPSCARE", "exe");
		jump.scale.x = 1.1;
		jump.scale.y = 1.1;
		jump.cameras = [camOther];
		jump.screenCenter();
		jump.y += 370;
		jump.animation.addByPrefix("jump", "sonicSPOOK", 24, false);

		if(preloading){
			CoolUtil.precacheSound("jumpscare");
			CoolUtil.precacheSound("datOneSound");
			jump.alpha = 0.01;
			new FlxTimer().start(0.1, function(tmr:FlxTimer){
				jump.visible=false;
				jump.alpha = 0;
				remove(jump);
			});
		}else{
			FlxG.sound.play(Paths.sound("jumpscare"), 1);
			FlxG.sound.play(Paths.sound("datOneSound"), 1);
			jump.animation.finishCallback = function(name: String){
				jump.visible=false;
				jump.alpha = 0;
				remove(jump);
			}
			jump.animation.play("jump", true);
		}


		add(jump);
	}

	function simpleJumpscare(preloading:Bool=false){
		var jump = new FlxSprite().loadGraphic(Paths.image("simplejump", "exe"));

		jump.setGraphicSize(FlxG.width, FlxG.height);
		jump.cameras = [camOther];
		jump.screenCenter();

		if(preloading){
			CoolUtil.precacheSound("XENOImageJumpscare");
			jump.alpha = 0.01;
		}else{
			FlxG.sound.play(Paths.sound("XENOImageJumpscare"), 1);
			FlxG.camera.shake(0.0025, 0.7);
			camOther.shake(0.0025, 0.7);
		}

		new FlxTimer().start(0.2, function(tmr:FlxTimer){
			jump.visible=false;
			jump.alpha = 0;
			remove(jump);
		});

		add(jump);



		flashStatic(preloading, false, true);
	}

	function changeCharacter(name:String, charType:Int){
		switch(charType) {
			case 0:
				if(boyfriend.curCharacter != name) {
					var shiftFocus:Bool = focusedChar==boyfriend;
					var oldChar = boyfriend;
					if(!boyfriendMap.exists(name)) {
						addCharacterToList(name, charType);
					}

					var lastAlpha:Float = boyfriend.alpha;
					boyfriend.alpha = 0.00001;
					boyfriend = boyfriendMap.get(name);
					boyfriend.alpha = lastAlpha;
					if(shiftFocus)focusedChar=boyfriend;
					iconP1.changeIcon(boyfriend.healthIcon);
					for(field in playFields.members){
						if(field.owner==oldChar)field.owner=boyfriend;
					}
				}
				setOnLuas('boyfriendName', boyfriend.curCharacter);

			case 1:
				if(dad.curCharacter != name) {
					var shiftFocus:Bool = focusedChar==dad;
					var oldChar = dad;
					if(!dadMap.exists(name)) {
						addCharacterToList(name, charType);
					}

					var wasGf:Bool = dad.curCharacter.startsWith('gf');
					var lastAlpha:Float = dad.alpha;
					dad.alpha = 0.00001;
					dad = dadMap.get(name);
					if(!dad.curCharacter.startsWith('gf')) {
						if(wasGf && gf != null) {
							gf.visible = true;
						}
					} else if(gf != null) {
						gf.visible = false;
					}
					if(shiftFocus)focusedChar=dad;
					dad.alpha = lastAlpha;
					iconP2.changeIcon(dad.healthIcon);
					for (field in playFields.members)
					{
						if (field.owner == oldChar)
							field.owner = dad;
					}
				}
				setOnLuas('dadName', dad.curCharacter);

			case 2:
				if(gf != null)
				{
					if(gf.curCharacter != name)
					{
						var shiftFocus:Bool = focusedChar==gf;
						var oldChar = gf;
						if(!gfMap.exists(name))
						{
							addCharacterToList(name, charType);
						}

						var lastAlpha:Float = gf.alpha;
						gf.alpha = 0.00001;
						gf = gfMap.get(name);
						gf.alpha = lastAlpha;
						if(shiftFocus)focusedChar=gf;
						for (field in playFields.members)
						{
							if (field.owner == oldChar)
								field.owner = gf;
						}
					}
					setOnLuas('gfName', gf.curCharacter);
				}
		}
		reloadHealthBarColors();
	}

	var snap3DCamera:Bool = false;
	var feelingTheSunshine:Bool = false;
	var sunshineFadeTimer:Float = 0;
	var fleetwayLineMap:Map<String, LineData> = [ // deprecated
		"step it up" => {character: "fleetway", anim: "step it up"},
		"laugh" => {character: "fleetway", anim: "laugh"},
		"youre finished" => {character: "fleetway", anim: "finished"},
		"grrr" => {character: "fleetway", anim: "grrr"},
		"what" => {character: "fleetway", anim: "what"},
		"scream" => {character: "fleetway", anim: "scream"},
		"growl" => {character: "fleetway", anim: "growl"},
		"right alt" => {character: "fleetway", anim: "singRIGHT-alt"},
		"shut up" => {character: "fleetway", anim: "shut up"},
		"too slow" => {character: "fleetway", anim: "tooslow"},
		"ill show you" => {character: "fleetway", anim: "showyou"},
		"how fast" => {character: "fleetway", anim: "how fast"}
	];

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Whisper':
				switch(value1){
					case '0':
						var name:String = 'pico-whisper';
						var shiftFocus:Bool = focusedChar==pico;
						if(pico.curCharacter != name) {
							var lastAlpha:Float = pico.alpha;
							pico.alpha = 0.00001;
							pico = extraMap.get(name);
							pico.alpha = lastAlpha;
						}
						if(shiftFocus)focusedChar=pico;
						changeCharacter('bf-whisper', 0);
						changeCharacter('requital-whisper', 1);
						setStageData(whisperStageData);
						pico.x = gfGroup.x;
						pico.y = gfGroup.y;
						startCharacterPos(pico);
					case '1':
						changeCharacter(SONG.player1, 0);
						changeCharacter(SONG.player2, 1);
						var name:String = SONG.gfVersion; // TODO: maybe change to SONG.player3?

						if(pico.curCharacter != name) {
							var lastAlpha:Float = pico.alpha;
							pico.alpha = 0.00001;
							pico = extraMap.get(name);
							pico.alpha = lastAlpha;
						}
						setStageData(stageData);
						pico.x = boyfriendGroup.x;
						pico.y = boyfriendGroup.y;
						startCharacterPos(pico);
				}
			case 'Change Focus':
				picoSection = false;
				focusedChar = null; // forces the focus to shift
				switch(value1.toLowerCase().trim()){
					case 'dad' | 'opponent':
						moveCamera(true);
					case 'pico':
						picoSection = true;
						moveCamera(false);
					default:
						moveCamera(false);
				}
			case 'Game Flash':
				var dur:Float = Std.parseFloat(value2);
				if(Math.isNaN(dur)) dur = 0.5;
				FlxG.camera.flash(FlxColor.fromString(value1), dur);
			case 'Fleetway Laser Sound' | 'Fleetway Charge Sound':
				FlxG.sound.play(Paths.sound("laser", "exe"), 0.3);
			case 'Play Sound':
				var vol:Float = Std.parseFloat(value2);
				if(Math.isNaN(vol)) vol = 0.5;
				FlxG.sound.play(Paths.sound(value1), vol);
			case 'Fleetway Laser':
				trace("eat this!");

				dad.animation.finishCallback = null;
				if(dad.curCharacter != 'fleetwaylaser')
					changeCharacter("fleetwaylaser",1);
				dad.playAnim("Laser Blast", true);
				dad.animation.finishCallback = function(anim:String){
					if(anim == "Laser Blast"){
						dad.animation.finishCallback = null;
						changeCharacter('fleetway', 1);
					}
				}
			case 'Fleetway':
				var line = value1.toLowerCase().trim();
				if(line=='end'){
					dad.animation.finishCallback = null;
					changeCharacter('fleetway', 1);
					dad.voicelining = false;
				}else{
					if(fleetwayLineMap.exists(line)){
						var data = fleetwayLineMap.get(line);
						dad.animation.finishCallback = null;
						if(dad.curCharacter != data.character)
							changeCharacter(data.character, 1);

						dad.playAnim(data.anim, true);
						dad.voicelining = true;
						if(line == 'how fast')
							FlxTween.tween(dad, {x: dadGroup.x + dad.positionArray[0], y: dadGroup.y + dad.positionArray[1] }, 2, {ease:FlxEase.cubeOut});

						if(value2 == 'autoend'){
							dad.animation.finishCallback = function(anim:String){
								if(anim == data.anim){
									dad.animation.finishCallback = null;
									dad.voicelining = false;
									changeCharacter('fleetway', 1);
								}
							}
						}
					}
				}
			case 'Flight Pattern':
				flightPattern = value1;
			case 'Flight Timer':
				var value:Float = Std.parseFloat(value1);
				if(Math.isNaN(value)) value = 0;
				flightTimer = value;
			case 'Flight Speed':
				var value:Float = Std.parseFloat(value1);
				if(Math.isNaN(value)) value = 1;
				flightSpeed = value;
			case 'Letterboxing':
				cinematicBars(value1=='1');
			case 'Light Control':
				var on = value1=='1';
				if(vcrShader!=null){
					vcrShader.vignetteOn.value = [!on];
					if(ClientPrefs.flashing)
						vcrShader.glitchModifier.value = [on?0.1:0.3];

					vcrShader.vignetteMoving.value = [!on];
				}
				if(dollShaderStage!=null){
					dollShaderStage.daShader.lightsOn.value[0] = on;
					boyfriendGroup.visible = on;
				}else{
					dollStage.visible = on;
					boyfriendGroup.visible = on;
				}
				if(on){
					moveCameraSection(Std.int(curStep / 16));
					snap3DCamera = true;
					switch(currentRatio){
						case '4:3':
							camFollowPos.setPosition(camFollow.x, camFollow.y - 120);
						default:
							camFollowPos.setPosition(camFollow.x, camFollow.y);
					}

				}
			case 'Red VG':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value)) value = 1;
				redVG.visible = value==1;
			case 'Static Flash':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value)) value = 0;
				flashStatic(false, value==1);
			case 'Simple Jumpscare':
				simpleJumpscare();
			case 'Jumpscare':
				fullJumpscare();
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case "Fleetway Intro":
				dad.visible = true;
				FlxTween.tween(dad, {y: dad.y - 500 }, 0.5, {ease:FlxEase.cubeOut});
			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					case 'pico':
						char = pico;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
							case 3: char = pico;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					if(value1=='micdrop')char.voicelining=true; // no comin back from this one fleetway
					char.specialAnim = true;
				}
				if(char.curCharacter == 'fleetway' && value1=='fastanim')
					FlxTween.tween(dad, {x: dadGroup.x + dad.positionArray[0], y: dadGroup.y + dad.positionArray[1] }, 2, {ease:FlxEase.cubeOut});


			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}
			case 'Unendless Notes':
				uiEndless = true;
				if(ClientPrefs.noteSkin != 'Quants'){
					PlayState.arrowSkin = SONG.arrowSkin;
					regenStaticArrows(-1);
				}
				reloadHealthBarColors();

				timeTxt.color = FlxColor.WHITE;
				timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
				timeBar.updateBar();

				scoreTxt.color = FlxColor.WHITE;
				iconP1.changeIcon(boyfriend.healthIcon);

			case 'Endless Notes':
				uiEndless = true;
				if(ClientPrefs.noteSkin != 'Quants'){
					PlayState.arrowSkin = 'Majin_Notes';
					regenStaticArrows(-1);
				}
				healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
				FlxColor.fromRGB(21, 43, 186));
				healthBar.updateBar();

				timeTxt.color = FlxColor.fromRGB(46, 13, 163);
				timeBar.createFilledBar(0x003D0BBD, 0xFF3D0BBD);
				timeBar.updateBar();

				scoreTxt.color = FlxColor.fromRGB(13, 18, 163);
				if(boyfriend.healthIcon == 'bf')
					iconP1.color = FlxColor.BLUE;


				//camHUD.alpha = 0;
			case 'Feel The Sunshine':
				var val:Float = Std.parseInt(value1);
				if(Math.isNaN(val)) val = 0;
				switch(val){
					case 1:
						sunshineFadeTimer = 1;
						feelingTheSunshine = true;
						for(strum in opponentStrums.members)
							strum.alpha = 0;

						resetStrumPositions(1, FlxG.width/2);

					case 2:
						sunshineFadeTimer = -0.2;
					case 3:
						sunshineFadeTimer = 0;
						for(strum in opponentStrums.members)
							strum.alpha = 1;

						resetStrumPositions(1);

						camHUD.alpha = 1;
						feelingTheSunshine = false;

				}
			case 'SPEEN':
				for(field in playFields.members){
					field.forEachAlive(function(toSpin:StrumNote){
						FlxTween.angle(toSpin, 0, 360, 0.2, {ease: FlxEase.quintOut});
					});
				}
			case 'Genesis':
				var val:Int = Std.parseInt(value1);
				if(Math.isNaN(val)) val = 0;
				if(curStage=='ycr'){
					switch (val)
					{
						case 0:
							changeAspectRatio("genesis");
							setStageData(pixelStageData);
							greenHill.visible=true;
							ycrStage.visible=false;
							changeCharacter('bfpickel', 0);
							changeCharacter('gf-pixel', 2);
							changeCharacter('pixelrunsonic', 1);

							boyfriend.pixelPerfectPosition = true;
							dad.pixelPerfectPosition = true;
							gf.pixelPerfectPosition = true;

							camGame.pixelPerfectRender = true;
							camHUD.pixelPerfectRender = true;

						case 1:
							changeAspectRatio("16:9");
							setStageData(stageData);
							greenHill.visible=false;
							ycrStage.visible=true;
							changeCharacter(SONG.player1, 0);
							changeCharacter(SONG.gfVersion, 2);
							changeCharacter(SONG.player2, 1);

							boyfriend.pixelPerfectPosition = false;
							dad.pixelPerfectPosition = false;
							gf.pixelPerfectPosition = false;

							camGame.pixelPerfectRender = false;
							camHUD.pixelPerfectRender = false;

					}
					moveCameraSection(Std.int(curStep / 16), true);
					updateCamFollow();
					switch(currentRatio){
						case '4:3':
							camFollowPos.setPosition(camFollow.x, camFollow.y - 120);
						default:
							camFollowPos.setPosition(camFollow.x, camFollow.y);
					}
				}else{
					switch (val)
					{
						case 0:
							isPixelStage=true;
						case 1:
							isPixelStage=false;
					}
				}
				regenStaticArrows(-1);


			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var curChar:Character = boyfriend;
				switch(charType){
					case 2:
						curChar = gf;
					case 1:
						curChar = dad;
					case 0:
						curChar = boyfriend;
				}

				var newCharacter:String = value2;
				var anim:String = '';
				var frame:Int = 0;
				if(newCharacter.startsWith(curChar.curCharacter) || curChar.curCharacter.startsWith(newCharacter)){
					if(curChar.animation!=null && curChar.animation.curAnim!=null){
						anim = curChar.animation.curAnim.name;
						frame = curChar.animation.curAnim.curFrame;
					}
				}

				changeCharacter(value2, charType);
				if(anim!=''){
					var char:Character = boyfriend;
					switch(charType){
						case 2:
							char = gf;
						case 1:
							char = dad;
						case 0:
							char = boyfriend;
					}

					if(char.animation.getByName(anim)!=null){
						char.playAnim(anim, true);
						char.animation.curAnim.curFrame = frame;
					}
				}

			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1) {
					Reflect.setProperty(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				} else {
					Reflect.setProperty(this, value1, value2);
				}
		}
		callOnScripts('onEvent', [eventName, value1, value2]);
		trace(eventName);
		if(eventScripts.exists(eventName))
			callScript(eventScripts.get(eventName), "onTrigger", [value1, value2]);

	}

	function moveCameraSection(?id:Int = 0, ?forced:Bool=false):Void {
		if(SONG.notes[id] == null) return;
		if(forced){
			whosTurn='';
			focusedChar=null;
		}
		if (gf != null && SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnScripts('onMoveCamera', ['gf']);
			focusedChar= gf;
			return;
		}

		if(pico!=null && SONG.notes[id].gfSection){
			if(whosTurn!='pico'){
				whosTurn = 'pico';
				picoSection = true;
				moveCamera(false);
				callOnScripts('onMoveCamera', ['pico']);
			}
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			if(whosTurn!='dad'){
				whosTurn = 'dad';
				picoSection=false;
				moveCamera(true);
				callOnScripts('onMoveCamera', ['dad']);
			}
		}
		else
		{
			if(whosTurn!='boyfriend'){
				whosTurn = 'boyfriend';
				moveCamera(false);
				callOnScripts('onMoveCamera', ['boyfriend']);
			}
		}
	}

	var cameraTwn:FlxTween;

	public function updateCamFollow(){
		if(isCameraOnForcedPos)return;
		if(focusedChar==dad){
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
		}else{
			camFollow.set(focusedChar.getMidpoint().x - 100, focusedChar.getMidpoint().y - 100);
			camFollow.x -= focusedChar.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += focusedChar.cameraPosition[1] + boyfriendCameraOffset[1];
		}
	}

	public function moveCamera(isDad:Bool)
	{
		trace(isDad?"focused on dad":"focused on bf");
		if(isDad)
		{
			if(focusedChar!=dad){
				focusedChar = dad;
				updateCamFollow();
			}
		}
		else
		{
			var char:Character = boyfriend;
			if(picoSection && pico!=null)char=pico;
			if(focusedChar!=char){
				focusedChar= char;
				updateCamFollow();

				if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
				{
					cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
						function (twn:FlxTween)
						{
							cameraTwn = null;
						}
					});
				}
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		switch(currentRatio){
			case '4:3':
				camFollowPos.setPosition(x, y - 120);
			default:
				camFollowPos.setPosition(x, y);
		}
		snap3DCamera = true;
	}

	//Any way to do this without using a different function? kinda dumb
	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		vocalsMuted = true;
		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if (instAlt != null){ instAlt.pause(); instAlt.volume = 0;}
		if (vocalsAlt != null){ vocalsAlt.pause(); vocalsAlt.volume = 0;}
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		#if LUA_ALLOWED
		var ret:Dynamic = callOnScripts('onEndSong', []);
		#else
		var ret:Dynamic = Globals.Function_Continue;
		#end

		if(ret != Globals.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					FlxG.sound.music.volume = 1;

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				FlxG.sound.music.volume = 1;
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			if(modchartObjects.exists('note${daNote.ID}'))modchartObjects.remove('note${daNote.ID}');
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showRating:Bool = true;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocalsMuted = false;
		vocals.volume = 1;
		if (vocalsAlt != null) vocalsAlt.volume = 1;
		var placement:String = Std.string(combo);

		var coolText:FlxObject = new FlxObject(0, 0);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff);
		var ratingNum:Int = 0;

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;

		if(daRating.noteSplash && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		var field:PlayField = note.playField;

		if(!practiceMode && !field.autoPlayed) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating();
			}

			if(ClientPrefs.scoreZoom)
			{
				if(scoreTxtTween != null) {
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtTween = null;
					}
				});
			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];


		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(playFields), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
				insert(members.indexOf(playFields), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);
		if(cpuControlled || paused || !startedCountdown)return;

		if(dodgeKeys.contains(eventKey) && canDodge && dodgeCooldown<=0){
			dodgeCooldown = 1500;
			dodgeTimer = dodgeHitbox;
			boyfriend.playAnim("dodge", true);
			boyfriend.animTimer = 0.25;
		}else if (key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				var pressNotes:Array<Note> = [];

				var ghostTapped:Bool = true;
				for(field in playFields.members){
					if (field.playerControls && field.inControl && !field.autoPlayed){
						var sortedNotesList:Array<Note> = field.getTapNotes(key);
						sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

						if (sortedNotesList.length > 0) {
							pressNotes.push(sortedNotesList[0]);
							field.noteHitCallback(sortedNotesList[0], field);
						}
					}
				}

				if(pressNotes.length==0){
					callOnScripts('onGhostTap', [key]);
					if (canMiss) {
						noteMissPress(key);
						callOnScripts('noteMissPress', [key]);
					}
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			for(field in playFields.members){
				if (field.inControl && !field.autoPlayed && field.playerControls){
					var spr:StrumNote = field.members[key];
					if(spr != null && spr.animation.curAnim.name != 'confirm')
					{
						spr.playAnim('pressed');
						spr.resetAnim = 0;
					}
				}
			}

			callOnScripts('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(startedCountdown && !paused && key > -1)
		{
			for(field in playFields.members){
				if (field.inControl && !field.autoPlayed && field.playerControls)
				{
					var spr:StrumNote = field.members[key];
					if (spr != null)
					{
						spr.playAnim('static');
						spr.resetAnim = 0;
					}
				}
			}
			callOnScripts('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if(!daNote.playField.autoPlayed && daNote.playField.inControl && daNote.playField.playerControls){
					if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit) {
						daNote.playField.noteHitCallback(daNote, daNote.playField);
					}
				}
			});

			if (controlHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function majinSaysFuck(numb:Int):Void
		{
			switch(numb)
			{
				case 4:
					var three:FlxSprite = new FlxSprite().loadGraphic(Paths.image('three', 'exe'));
					three.scrollFactor.set();
					three.updateHitbox();
					three.screenCenter();
					three.y -= 100;
					three.alpha = 0.5;
					three.cameras = [camOther];
					add(three);
					FlxTween.tween(three, {y: three.y + 100, alpha: 0, "scale.x": 1.05, "scale.y": 1.05}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeOut,
						onComplete: function(twn:FlxTween)
						{
							three.destroy();
						}
					});
				case 3:
					var two:FlxSprite = new FlxSprite().loadGraphic(Paths.image('two', 'exe'));
					two.scrollFactor.set();
					two.screenCenter();
					two.y -= 100;
					two.alpha = 0.5;
					two.cameras = [camOther];
					add(two);
					FlxTween.tween(two, {y: two.y + 100, alpha: 0, "scale.x": 1.05, "scale.y": 1.05}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeOut,
						onComplete: function(twn:FlxTween)
						{
							two.destroy();
						}
					});
				case 2:
					var one:FlxSprite = new FlxSprite().loadGraphic(Paths.image('one', 'exe'));
					one.scrollFactor.set();
					one.screenCenter();
					one.y -= 100;
					one.alpha = 0.5;
					one.cameras = [camOther];

					add(one);
					FlxTween.tween(one, {y: one.y + 100, alpha: 0, "scale.x": 1.05, "scale.y": 1.05}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeOut,
						onComplete: function(twn:FlxTween)
						{
							one.destroy();
						}
					});
				case 1:
					var gofun:FlxSprite = new FlxSprite().loadGraphic(Paths.image('gofun', 'exe'));
					gofun.scrollFactor.set();

					gofun.updateHitbox();

					gofun.screenCenter();
					gofun.y -= 100;
					gofun.alpha = 0.5;

					add(gofun);
					FlxTween.tween(gofun, {y: gofun.y + 100, alpha: 0, "scale.x": 1.05, "scale.y": 1.05}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							gofun.destroy();
						}
					});
			}

		}


	function staticNoteMiss(preloading:Bool=false){
		var noteStatic = new FlxSprite();
		noteStatic.frames = Paths.getSparrowAtlas("hitStatic");

		noteStatic.setGraphicSize(FlxG.width, FlxG.height);
		noteStatic.cameras = [camOther];
		noteStatic.screenCenter();
		noteStatic.animation.addByPrefix("static", "staticANIMATION", 24, false);

		if(preloading){
			CoolUtil.precacheSound("hitStatic1");
			noteStatic.alpha = 0.01;
			new FlxTimer().start(0.1, function(tmr:FlxTimer){
				noteStatic.visible=false;
				noteStatic.alpha = 0;
				remove(noteStatic);
			});
		}else{
			FlxG.sound.play(Paths.sound("hitStatic1"), 0.6);
			noteStatic.animation.finishCallback = function(name: String){
				noteStatic.visible=false;
				noteStatic.alpha = 0;
				remove(noteStatic);
			}
			noteStatic.animation.play("static", true);
		}

		add(noteStatic);
	}


	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.playField.playerControls && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				if(modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;


		switch(daNote.noteType){
			case 'Static Note':
				staticNoteMiss();
		}

		health -= daNote.missHealth * healthLoss;
		if(instakillOnMiss)
		{
			vocalsMuted = true;
			vocals.volume = 0;
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocalsMuted = true;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if(daNote.gfNote)char = gf;

		if((daNote.noteType == 'Pico Sing' || daNote.extraNote) && pico!=null)char=pico;

		if(char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			if(char.animTimer <= 0 && !char.voicelining){
				var daAlt = '';
				if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
				char.playAnim(animToPlay, true);
			}
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.ID]);
		callOnHScripts("noteMiss", [daNote]);

		if (daNote.noteScript!=null)
		{
			var script:Dynamic = daNote.noteScript;
			if (script.scriptType == 'lua')
			{
				callScript(script, 'noteMiss', [
					notes.members.indexOf(daNote),
					Math.abs(daNote.noteData),
					daNote.noteType,
					daNote.isSustainNote,
					daNote.ID
				]);
			}
			else
			{
				callScript(script, "noteMiss", [daNote]);
			}
		}
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.ghostTapping) return; //fuck it

		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocalsMuted = true;
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations) {
				if(boyfriend.animTimer <= 0 && !boyfriend.voicelining)
					boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			if(pico!=null){
				if(pico.hasMissAnimations) {
					if(pico.animTimer <= 0 && !pico.voicelining)
						pico.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
				}
			}
			vocalsMuted = true;
			vocals.volume = 0;
		}
		callOnScripts('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note, playfield:PlayField):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		var char:Character = playfield.owner;

		if(note.gfNote)
			char = gf;

		if((note.noteType == 'Pico Sing' || note.extraNote) && pico!=null)char=pico;


		if(note.noteType == 'Hey!' && char.animOffsets.exists('hey')) {
			char.playAnim('hey', true);
			char.specialAnim = true;
			char.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}
			}

			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if(char==dad){
				char.voicelining=false;
				if((char.curCharacter.startsWith("fleetway-anims") || char.curCharacter == 'fleetwaylaser' || char.curCharacter == 'fleetlines') && char.curCharacter != 'fleetway'){
					changeCharacter('fleetway', 1);
					char = dad;
				}
			}
			if(char.voicelining)char.voicelining=false;

			if (curStage == 'needle' && char.curCharacter == 'Needlemouse' )
			{
				dad2.playAnim(animToPlay + altAnim, true);
				dad2.holdTimer = 0;
			}
			if(char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (char.curCharacter == "starved")
		{
			if (!note.isSustainNote) fearNo += 0.2;
			else fearNo += 0.05;
		}

		if(char.curCharacter == 'ycr' || char.curCharacter == 'ycr-mad')
			FlxG.camera.shake(0.005, 0.50);

		if (SONG.needsVoices){
			vocalsMuted = false;
			vocals.volume = 1;
			if(vocalsAlt!=null)vocalsAlt.volume = 1;
		}

		if (playfield.autoPlayed) {
			var time:Float = 0.15;
			if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
				time += 0.15;
			}
			StrumPlayAnim(playfield, Std.int(Math.abs(note.noteData)) % 4, time, note);
		} else {
			playfield.forEach(function(spr:StrumNote)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.playAnim('confirm', true, note);
				}
			});
		}

		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, note.ID]);
		callOnHScripts("opponentNoteHit", [note]);
		if (note.noteScript != null)
		{
			var script:Dynamic = note.noteScript;
			if (script.scriptType == 'lua')
			{
			callScript(script, 'opponentNoteHit',
			[
				notes.members.indexOf(note),
				Math.abs(note.noteData),
				note.noteType,
				note.isSustainNote,
				note.ID
			]);
			}
			else
			{
				callScript(script, "opponentNoteHit", [note]); 
			}
		}
		if (!note.isSustainNote)
		{
			if(modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note, field:PlayField):Void
	{
		if (fearNo >= 0.1 && !note.isSustainNote) fearNo -= 0.1;
		else if (fearNo >= 0.1 && note.isSustainNote) fearNo -= 0.01;
		if (!note.wasGoodHit)
		{
			if(field.autoPlayed && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if (field.autoPlayed) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(field, Std.int(Math.abs(note.noteData)) % 4, time, note);
			} else {
				field.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true, note);
					}
				});
			}

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType) {
					case 'Phantom Note':
						phantomDrainTicker += 10;
						phantomDrain += 0.00025;
				}


				if(!note.noMissAnimation)
				{
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(field.owner.animation.getByName('hurt') != null) {
								field.owner.playAnim('hurt', true);
								field.owner.specialAnim = true;
							}
					}
				}


				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					if(modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if((note.noteType == 'Pico Sing' || note.extraNote))
				{
					if(pico != null)
					{
						pico.playAnim(animToPlay + daAlt, true);
						pico.holdTimer = 0;
					}
				}else if(note.gfNote)
				{
					if(gf != null)
					{
						gf.playAnim(animToPlay + daAlt, true);
						gf.holdTimer = 0;
					}
				}

				else if (field.owner.animTimer <= 0 && !field.owner.voicelining)
				{
					field.owner.playAnim(animToPlay + daAlt, true);
					field.owner.holdTimer = 0;
				}

				if(note.noteType == 'Hey!') {
					if (field.owner.animTimer <= 0 && !field.owner.voicelining){
						if(field.owner.animOffsets.exists('hey')) {
							field.owner.playAnim('hey', true);
							field.owner.specialAnim = true;
							field.owner.heyTimer = 0.6;
						}
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}
			note.wasGoodHit = true;
			vocalsMuted = false;
			vocals.volume = 1; // ay tf this for < CRYBIT YOU IDIOT ITS SO WHEN YOU MISS AND THEN HIT A NOTE/SUSTAIN IT DOESNT FUCKING STAY MUTED -neb
			if(vocalsAlt!=null)vocalsAlt.volume = 1;
			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus, note.ID]);
			callOnHScripts("goodNoteHit", [note]); // maybe have this above so you can interrupt goodNoteHit? idk we'll see
			if (note.noteScript!=null)
			{
				var script:Dynamic = note.noteScript;
				if (script.scriptType == 'lua')
				{
					callScript(script, 'goodNoteHit',
						[notes.members.indexOf(note), leData, leType, isSus, note.ID]); 
				}
				else
				{
					callScript(script, "goodNoteHit", [note]); 
				}
			}
			if (!note.isSustainNote)
			{
				if(modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = note.playField.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'BloodSplash';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt, note.playField);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (gf != null)
			{
				gf.playAnim('hairBlow');
				gf.specialAnim = true;
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		if(gf != null)
		{
			gf.danced = false; //Sets head to the correct position once the animation ends
			gf.playAnim('hairFall');
			gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if(gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for(script in funkyScripts){
			script.call("onDestroy", []);
			script.stop();
		}
		hscriptArray = [];
		funkyScripts = [];
		luaArray = [];
		notetypeScripts.clear();
		eventScripts.clear();
		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();


		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}
				switch(curSong.toLowerCase()){
					case "endless-og":
						switch(curStep){
							case 909:
								FlxTween.tween(camHUD, {alpha: 0}, 0.7, {ease: FlxEase.cubeInOut});

								inCutscene = true;
								camFollow.set(FlxG.width / 2 + 50, FlxG.height / 4 * 3 + 280);
								FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
								majinSaysFuck(4);

								trace("3");
							case 915:
								FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
								majinSaysFuck(3);

								trace("2");
							case 920:
								FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
								majinSaysFuck(2);

								trace("1");
							case 924:
								inCutscene = false;
								FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.7, {ease: FlxEase.cubeInOut});
								majinSaysFuck(1);

								FlxTween.tween(camHUD, {alpha: 1}, 0.7, {ease: FlxEase.cubeInOut});

								trace("GO!");
							}
					case "endless-us":
						switch(curStep){
							case 888:
								FlxTween.tween(camHUD, {alpha: 0}, 0.7, {ease: FlxEase.cubeInOut});

								inCutscene = true;
								camFollow.set(FlxG.width / 2 + 50, FlxG.height / 4 * 3 + 280);
								FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
								majinSaysFuck(4);

								trace("3");
							case 892:
								FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
								majinSaysFuck(3);

								trace("2");
							case 896:
								FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 0.7, {ease: FlxEase.cubeInOut});
								majinSaysFuck(2);

								trace("1");
							case 900:
								inCutscene = false;
								FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.7, {ease: FlxEase.cubeInOut});
								majinSaysFuck(1);

								FlxTween.tween(camHUD, {alpha: 1}, 0.7, {ease: FlxEase.cubeInOut});

								trace("GO!");
							}

			case 'prey':
				switch (curStep)
					// TODO: unhardcode
				{
					case 1:
						boyfriend.alpha = 0;
						camHUD.alpha = 0;
						FlxTween.tween(boyfriend, {alpha: 1}, 6);

					case 128:
						FlxG.camera.flash(FlxColor.WHITE, 2);
						FlxG.camera.zoom = 2;
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 1.5, {ease: FlxEase.circOut});
						stardustBgPixel.visible = true;
						stardustFloorPixel.visible = true;

					case 246:
						FlxTween.tween(dad, {x: -500}, 1.5, {ease: FlxEase.cubeInOut});
						FlxTween.tween(camHUD, {alpha: 1}, 1.2,{ease: FlxEase.cubeInOut});
						camZooming = true;
					case 512:
						FlxTween.tween(dad, {x: 580}, 5.9);
					case 1024:
						FlxTween.tween(dad, {x: -135}, 5.9);
					case 1280:
						FlxTween.tween(dad, {x: 580}, 5.9);
					case 1530:
						FlxTween.tween(camHUD, {alpha: 0}, 0.75,{ease: FlxEase.cubeInOut});
					case 1505:
						FlxTween.tween(dad, {x: -1500}, 5, {ease: FlxEase.cubeInOut});
						FlxTween.angle(dad, 0, -180, 5, {ease: FlxEase.cubeInOut});
					case 1542:
						dadGroup.visible = false;
					case 1545:
							cinematicBars(true);
							dad.x -= 500;
							dad.y += 100;
					case 1548:
						dadGroup.visible = true;
					case 1547:
						health = 1;
						boyfriend.playAnim("first dialogue");
						boyfriend.animation.finishCallback = function(slash:String)
						{
							hungryManJackTime = 2;
							if (dad.animation.curAnim.name == "first dialogue")
							{
								boyfriend.specialAnim = false;
							}
						}
						dad.playAnim("dialogue", true);
						dad.specialAnim = true;
						dad.animation.finishCallback = function(slash:String)
						{
							if (dad.animation.curAnim.name == "dialogue")
							{
								hungryManJackTime = 1;
								cinematicBars(false);
								dad.specialAnim = false;
							}
						}
					case 1570:
						FlxTween.tween(dad, {x: 1300}, 2.5,{ease: FlxEase.cubeInOut});
					case 1780:
						FlxTween.tween(camHUD, {alpha: 1}, 1.0);
					case 2432:
						FlxTween.tween(stardustFurnace, {x: 3000}, 7);
						stardustFurnace.visible = true;
					case 3328:
						FlxTween.tween(camHUD, {alpha: 0}, 1,{ease: FlxEase.cubeInOut});
						FlxTween.tween(dad, {x: -300}, 4,{ease: FlxEase.cubeInOut});
					case 3335:
						boyfriend.playAnim("dialogue peel");
						boyfriend.specialAnim = true;
					case 3367:
						FlxG.camera.flash(FlxColor.RED, 2);
						boyfriendGroup.visible = false;
						dadGroup.visible = false;
						stardustFurnace.visible = false;
						stardustBgPixel.visible = false;
						stardustFloorPixel.visible = false;
					case 3364:
						cinematicBars(true);
						var gotcha:FlxSprite = new FlxSprite(boyfriend.x + 1500, boyfriend.y + 505).loadGraphic(Paths.image('furnace_gotcha'));
						gotcha.setGraphicSize(Std.int(gotcha.width * 5));
						gotcha.antialiasing = false;
						gotcha.flipX = true;
						add(gotcha);
						FlxTween.tween(gotcha, {x: boyfriend.x + 500}, 0.2, {onComplete: function(yes:FlxTween)
						{
							remove(gotcha);
						}});
				}
			case 'round-a-bout':
				// TODO: unhardcode
					switch (curStep)
					{
						case 741:
							FlxTween.tween(darkthing, {alpha: 0.7}, 1.3, {ease: FlxEase.quadInOut});
							defaultCamZoom = 0.9;



						case 756:
							FlxTween.tween(dad2, {alpha: 1}, 1.3, {ease: FlxEase.quadInOut});
							FlxTween.tween(darkthing, {alpha: 0}, 1.3, {ease: FlxEase.quadInOut});
							defaultCamZoom = 0.6;
						case 962:
							FlxTween.tween(dad2, {alpha: 0}, 2.2, {ease: FlxEase.quadInOut});


						}
					}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;

	function cinematicBars(appear:Bool) //IF (TRUE) MOMENT?????
		{
			if (appear)
			{
				add(topBar);
				add(bottomBar);
				FlxTween.tween(topBar, {y: 0}, 0.5, {ease: FlxEase.quadOut});
				FlxTween.tween(bottomBar, {y: 550}, 0.5, {ease: FlxEase.quadOut});
			}
			else
			{
				FlxTween.tween(topBar, {y: -170}, 0.5, {ease: FlxEase.quadOut});
				FlxTween.tween(bottomBar, {y: 720}, 0.5, {ease: FlxEase.quadOut, onComplete: function(fuckme:FlxTween)
				{
					remove(topBar);
					remove(bottomBar);
				}});
			}
		}


	var lastSection:Int = -1;
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		var curSection = SONG.notes[Math.floor(curStep / 16)];
		if (curSection != null)
		{
			if (curSection.changeBPM)
			{
				Conductor.changeBPM(curSection.bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', curSection.mustHitSection);
			setOnLuas('altAnim', curSection.altAnim);
			setOnLuas('gfSection', curSection.gfSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
			setOnScripts("sectionNumber", Math.floor(curStep / 16));
			setOnHScripts("curSection", curSection);
			if (lastSection != Math.floor(curStep / 16))
			{
				lastSection = Math.floor(curStep / 16);
				callOnHScripts("sectionChanged", [curSection]);
				callOnLuas("sectionChanged", [Math.floor(curStep / 16)]);
			}
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015 * camZoomingMult;
			camHUD.zoom += 0.03 * camZoomingMult;
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}
		if(pico!=null){
			if (curBeat % pico.danceEveryNumBeats == 0 && pico.animation.curAnim != null && !pico.animation.curAnim.name.startsWith('sing') && !pico.stunned)
			{
				pico.dance();
			}
		}

		switch (curStage)
		{
			case 'chamber':
				chamberPorker.animation.play('porkerbop');
			case 'endlessForest':
					pillars1.dance(true);
					pillars2.dance(true);
			case 'school':
				if(!ClientPrefs.lowQuality) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality) {
					upperBoppers.dance(true);
				}

				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat); //DAWGG?????
		callOnScripts('onBeatHit', []);
	}

	public var closeLuas:Array<FunkinLua> = [];

	public function callOnScripts(event:String, args:Array<Dynamic>, ignoreStops:Bool = false, ?exclusions:Array<String>, ?scriptArray:Array<Dynamic>,
			?ignoreSpecialShit:Bool = true)
	{
		
		if (scriptArray == null)
			scriptArray = funkyScripts;
		if(exclusions==null)exclusions = [];
		var returnVal:Dynamic = Globals.Function_Continue;
		for (script in scriptArray)
		{
			if (exclusions.contains(script.scriptName)
				|| ignoreSpecialShit
				&& (notetypeScripts.exists(script.scriptName) || eventScripts.exists(script.scriptName) ) )
			{
				continue;
			}
			var ret:Dynamic = script.call(event, args);
			if (ret == Globals.Function_Halt)
			{
				ret = returnVal;
				if (!ignoreStops)
					return returnVal;
			};
			if (ret != Globals.Function_Continue && ret!=null)
				returnVal = ret;
		}
		if(returnVal==null)returnVal = Globals.Function_Continue;
		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, ?scriptArray:Array<Dynamic>)
	{
		if (scriptArray == null)
			scriptArray = funkyScripts;
		for (script in scriptArray)
		{
			script.set(variable, arg);
		}
	}

	public function callScript(script:Dynamic, event:String, args:Array<Dynamic>): Dynamic{
		if((script is FunkinScript)){
			return callOnScripts(event, args, true, [], [script], false);
		}else if((script is Array)){
			return callOnScripts(event, args, true, [], script, false);
		}else if((script is String)){
			var scripts:Array<FunkinScript> = [];
			for(scr in funkyScripts){
				if(scr.scriptName == script)
					scripts.push(scr);
			}
			return callOnScripts(event, args, true, [], scripts, false);
		}
		return Globals.Function_Continue;
	}
	

	public function callOnHScripts(event:String, args:Array<Dynamic>, ignoreStops = false, ?exclusions:Array<String>){
		return callOnScripts(event, args, ignoreStops, exclusions, hscriptArray);
	}
	
	public function setOnHScripts(variable:String, arg:Dynamic)
	{
		return setOnScripts(variable, arg, hscriptArray);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = false, ?exclusions:Array<String>){
		#if LUA_ALLOWED
		return callOnScripts(event, args, ignoreStops, exclusions, luaArray);
		#else
		return Globals.Function_Continue;
		#end
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		setOnScripts(variable, arg, luaArray);
		#end
	}

	function StrumPlayAnim(field:PlayField, id:Int, time:Float, ?note:Note) {
		var spr:StrumNote = field.members[id];

		if(spr != null) {
			spr.playAnim('confirm', true, note);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnScripts('onRecalculateRating', []);
		if(ret != Globals.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !ClientPrefs.imagesPersist) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	override public function switchTo(nextState: Dynamic){
		if(isPixelStage != stageData.isPixelStage)
			isPixelStage = stageData.isPixelStage;

		if(FlxG.sound.music!=null) // so if you leave and debug console comes up and you bring it down it wont replay the fuckin song and break EVERYTHING!!!
			FlxG.sound.music.onComplete=null;

		changeAspectRatio("16:9");

		return super.switchTo(nextState);
	}

	var curLight:Int = -1;
	var curLightEvent:Int = -1;

	function changeAspectRatio(ratio:String)
	{
		switch(ratio){
			case 'default':
				ratio = '16:9';
			case 'square' | 'genesis' | 'saturn':
				ratio = '4:3';
			default:
		}
		if(currentRatio == ratio)return;

		currentRatio = ratio;



		if (ratio != "16:9") isFullscreen = FlxG.fullscreen;

		FlxG.fullscreen = false; // idc why i did this but it works

		switch(ratio)
		{
			case '4:3':
				if(Capabilities.screenResolutionX >= 1280 && Capabilities.screenResolutionY >= 960){
					resetStrumPositions(-1);
					Lib.application.window.resizable = false;
					for(cam in FlxG.cameras.list) {cam.y = -120;}
					Lib.application.window.y -= 120;
					FlxG.resizeWindow(1280, 960);
				}else {
					currentRatio = '16:9';
					ratio = '16:9';
				}
			case '9:16':
				resetStrumPositions(-1);
				Lib.application.window.resizable = false;
				for(cam in FlxG.cameras.list) {cam.y = -120;}
				FlxG.resizeWindow(720, 1280); // 720p 4:3 resolution

			case '16:9':
				resetStrumPositions(-1);
				Lib.application.window.resizable = true;
				Lib.application.window.y += 120;
				//FlxG.scaleMode = new RatioScaleMode(false);
				//Lib.current.stage.stageWidth = 1280;
				//Lib.current.stage.stageHeight = 720;
				for(cam in FlxG.cameras.list) {cam.y = 0;}
				FlxG.resizeWindow(1280, 720);
				if (isFullscreen) FlxG.fullscreen = true;

			default:
				FlxG.log.error('${ratio} is not a valid aspect ratio');
				return;

		}
		FlxG.resizeGame(Lib.application.window.width, Lib.application.window.height);
		@:privateAccess
		FlxG.width = Lib.application.window.width;
		@:privateAccess
		FlxG.height = Lib.application.window.height;


		FlxG.log.add("Switched ratio to " + ratio);
		for(cam in FlxG.cameras.list){
			cam.width = Lib.application.window.width;
			cam.height = Lib.application.window.height;
		}

		Lib.application.window.x = Std.int(Capabilities.screenResolutionX / 2 - Lib.application.window.width / 2);
		Lib.application.window.y = Std.int(Capabilities.screenResolutionY / 2 - Lib.application.window.height / 2);

		if(healthBar!=null){
			trace(camHUD.width, camHUD.height);
			var y = camHUD.height * 0.89;
			if(ClientPrefs.downScroll) y = 0.11 * camHUD.height;
			scoreTxt.y = y + 36;
			y += 4;
			healthBar.y = y;
			iconP2.y = healthBar.y - 75;
			iconP1.y = healthBar.y - 75;
		}
	}
}
