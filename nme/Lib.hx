package nme;

class Lib
{
   static public var FULLSCREEN = 0x0001;
   static public var BORDERLESS = 0x0002;
   static public var RESIZABLE  = 0x0004;
   static public var HARDWARE   = 0x0008;
   static public var VSYNC      = 0x0010;

   static var nmeMainFrame: Dynamic = null;
   static var nmeCurrent: nme.display.MovieClip = null;
   static var nmeStage: nme.display.Stage = null;

	public static var initWidth(default,null):Int;
	public static var initHeight(default,null):Int;

   public static var stage(nmeGetStage,null): nme.display.Stage;
   public static var current(nmeGetCurrent,null): nme.display.MovieClip;


   public static function create(inOnLoaded:Void->Void,inWidth:Int, inHeight:Int,
                      inFrameRate:Float = 60.0,  inColour:Int = 0xffffff,
                      inFlags:Int = 0x0f, inTitle:String = "NME", inIcon : String="")
   {
	   initWidth = inWidth;
	   initHeight = inHeight;
      var create_main_frame = nme.Loader.load("nme_create_main_frame",-1);
      create_main_frame(
        function(inFrameHandle:Dynamic) {
            #if android try { #end
            nmeMainFrame = inFrameHandle;
            var stage_handle = nme_get_frame_stage(nmeMainFrame);
            nme.Lib.nmeStage = new nme.display.Stage(stage_handle,inWidth,inHeight);
            nme.Lib.nmeStage.frameRate = inFrameRate;
            nme.Lib.nmeStage.opaqueBackground = inColour;
            nme.Lib.nmeStage.onQuit = close;
            inOnLoaded();
            #if android } catch (e:Dynamic) { trace("ERROR: " +  e); } #end
        },
        inWidth,inHeight,inFlags,inTitle,inIcon );
   }


   public static function createManagedStage(inWidth:Int, inHeight:Int)
   {
	   initWidth = inWidth;
	   initHeight = inHeight;
      nmeStage = new nme.display.ManagedStage(inWidth,inHeight);
      return nmeStage;
   }


   static function nmeGetStage()
   {
      if (nmeStage==null)
         throw("Error : stage can't be accessed until init is called");
      return nmeStage;
   }

   // Be careful not to blow precision, since storing ms since 1970 can overflow...
   static public function getTimer() : Int
   {
      return Std.int(nme.Timer.stamp() * 1000.0);
   }


   public static function close()
   {
      var close = nme.Loader.load("nme_close",0);
      close();
   }


   static function nmeGetCurrent() : nme.display.MovieClip
   {
      if (nmeCurrent==null)
      {
         nmeCurrent = new nme.display.MovieClip();
         stage.addChild(nmeCurrent);
      }
      return nmeCurrent;
   }


   #if neko
   static function __init__()
   {
       var init = neko.Lib.load("nekoapi","neko_api_init",1);
       init(function(s) return new String(s) );
   }
   #end
   static var nme_get_frame_stage = nme.Loader.load("nme_get_frame_stage",1);

}

