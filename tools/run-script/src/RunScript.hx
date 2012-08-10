import neko.zip.Writer;
import haxe.io.Eof;
import haxe.Http;
import haxe.io.Path;
import neko.Lib;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


class RunScript {
	
	
	private static var isLinux:Bool;
	private static var isMac:Bool;
	private static var isWindows:Bool;
	private static var nmeDirectory:String;
	
	
	private static function build (targets:Array<String> = null):Void {
		
		if (targets == null) {
			
			targets = [ "tools" ];
			
			if (isWindows) {
				
				targets.push ("windows");
				
			} else if (isLinux) {
				
				targets.push ("linux");
				
			} else if (isMac) {
				
				targets.push ("mac");
				
			}
			
		}
		
		for (target in targets) {
			
			if (target == "tools") {
				
				runCommand (nmeDirectory + "/tools/command-line", "haxe", [ "CommandLine.hxml" ]);
				
			} else if (target == "clean") {
				
				var directories = [ nmeDirectory + "/project/obj" ];
				var files = [ nmeDirectory + "/project/all_objs", nmeDirectory + "/project/vc100.pdb" ];
				
				for (directory in directories) {
					
					removeDirectory (directory);
					
				}
				
				for (file in files) {
					
					if (FileSystem.exists (file)) {
						
						FileSystem.deleteFile (file);
						
					}
					
				}
				
			} else {
				
				if (target == "all") {
					
					if (isWindows) {
						
						buildLibrary ("windows");
						buildLibrary ("android");
						buildLibrary ("blackberry");
						buildLibrary ("webos");
						
					} else if (isLinux) {
						
						buildLibrary ("linux");
						buildLibrary ("android");
						buildLibrary ("blackberry");
						buildLibrary ("webos");
						
					} else if (isMac) {
						
						buildLibrary ("mac");
						buildLibrary ("ios");
						buildLibrary ("android");
						buildLibrary ("blackberry");
						buildLibrary ("webos");
						
					}
					
				} else {
					
					buildLibrary (target);
					
				}
				
			}
			
		}
		
	}
	
	
	static private function buildLibrary (target:String):Void {
		
		if (!FileSystem.exists (nmeDirectory + "/../sdl-static")) {
			
			error ("You must have \"sdl-static\" checked out next to NME to build libraries");
			return;
			
		}
		
		var projectDirectory = nmeDirectory + "/project";
		
		// The -Ddebug directive creates a debug build of the library, but the -Dfulldebug directive
		// will create a debug library using the ".debug" suffix on the file name, so both the release
		// and debug libraries can exist in the same directory
		
		switch (target) {
			
			case "android":
				
				mkdir (nmeDirectory + "/ndll/Android");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid", "-DHXCPP_ARMV7", "-DHXCPP_ARM7" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dandroid", "-DHXCPP_ARMV7", "-DHXCPP_ARM7", "-Dfulldebug" ]);
			
			case "blackberry":
				
				mkdir (nmeDirectory + "/ndll/BlackBerry");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry", "-Dsimulator" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dblackberry", "-Dsimulator", "-Dfulldebug" ]);
			
			case "ios":
				
				mkdir (nmeDirectory + "/ndll/iPhone");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos", "-DHXCPP_ARMV7" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphoneos", "-DHXCPP_ARMV7", "-Dfulldebug" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphonesim" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Diphonesim", "-Dfulldebug" ]);
			
			case "linux":
				
				mkdir (nmeDirectory + "/ndll/Linux");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dfulldebug" ]);
				
				if (isRunning64 ()) {
					
					mkdir (nmeDirectory + "/ndll/Linux64");
					
					runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-DHXCPP_M64" ]);
					runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-DHXCPP_M64", "-Dfulldebug" ]);
					
				}
			
			case "mac":
				
				mkdir (nmeDirectory + "/ndll/Mac");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dfulldebug" ]);
			
			case "webos":
				
				mkdir (nmeDirectory + "/ndll/webOS");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dwebos" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dwebos", "-Dfulldebug" ]);
			
			case "windows":
				
				if (Sys.environment ().exists ("VS110COMNTOOLS")) {
					
					Lib.println ("Warning: Visual Studio 2012 is not supported. Trying Visual Studio 2010...");
					
					Sys.putEnv ("VS110COMNTOOLS", Sys.getEnv ("VS100COMNTOOLS"));
					
				}
				
				mkdir (nmeDirectory + "/ndll/Windows");
				
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml" ]);
				runCommand (projectDirectory, "haxelib", [ "run", "hxcpp", "Build.xml", "-Dfulldebug" ]);
			
		}
		
	}
	
	
	private static function downloadFile (remotePath:String, localPath:String) {
		
		var out = File.write (localPath, true);
		var progress = new Progress (out);
		var h = new Http (remotePath);
		
		h.onError = function (e) {
			progress.close();
			FileSystem.deleteFile (localPath);
			throw e;
		};
		
		h.customRequest (false, progress);
		
	}
	
	
	public static function error (message:String = "", e:Dynamic = null):Void {
		
		if (message != "") {
			
			if (nme_error_output == null) {
				
				try {
					
					nme_error_output = Lib.load ("nme", "nme_error_output", 1);
					
				} catch (e:Dynamic) {
					
					nme_error_output = Lib.println;
					
				}
				
			}
			
			try {
				
				nme_error_output ("Error: " + message + "\n");
				
			} catch (e:Dynamic) {}
			
		}
		
		if (e != null) {
			
			Lib.rethrow (e);
			
		}
		
		Sys.exit (1);
		
	}
	
	
	public static function getHaxelib (library:String):String {
		
		var proc = new Process ("haxelib", ["path", library ]);
		var result = "";
		
		try {
			
			while (true) {
				
				var line = proc.stdout.readLine ();
				
				if (line.substr (0,1) != "-") {
					
					result = line;
					break;
					
				}
				
			}
			
		} catch (e:Dynamic) { };
		
		proc.close();
		
		//Lib.println ("Found " + library + " at " + result );
		//trace("Found " + haxelib + " at " + srcDir );
		
		if (result == "") {
			
			throw ("Could not find haxelib path  " + library + " - perhaps you need to install it?");
			
		}
		
		return result;
		
	}
	
	
	public static function isRunning64 ():Bool {
		
		if (Sys.systemName () == "Linux") {
			
			var proc = new Process ("uname", [ "-m" ]);
			var result = "";
			
			try {
				
				while (true) {
					
					var line = proc.stdout.readLine ();
					
					if (line.substr (0,1) != "-") {
						
						result = line;
						break;
						
					}
					
				}
				
			} catch (e:Dynamic) { };
			
			proc.close();
			
			return result == "x86_64";
			
		} else {
			
			return false;
			
		}
		
	}
	
	
	public static function mkdir (directory:String):Void {
		
		directory = StringTools.replace (directory, "\\", "/");
		var total = "";
		
		if (directory.substr (0, 1) == "/") {
			
			total = "/";
			
		}
		
		var parts = directory.split("/");
		var oldPath = "";
		
		if (parts.length > 0 && parts[0].indexOf (":") > -1) {
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (parts[0] + "\\");
			parts.shift ();
			
		}
		
		for (part in parts) {
			
			if (part != "." && part != "") {
				
				if (total != "") {
					
					total += "/";
					
				}
				
				total += part;
				
				if (!FileSystem.exists (total)) {
					
					//print("mkdir " + total);
					
					FileSystem.createDirectory (total);
					
				}
				
			}
			
		}
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
	}
	
	
	private static function param (name:String, ?passwd:Bool):String {
		
		Sys.print (name + " : ");
		
		if (passwd) {
			var s = new StringBuf ();
			var c;
			while ((c = Sys.getChar(false)) != 13)
				s.addChar (c);
			Sys.print ("");
			return s.toString ();
		}
		
		try {
			
			return Sys.stdin ().readLine ();
			
		} catch (e:Eof) {
			
			return "";
			
		}
		
	}
	
	
	private static function removeDirectory (directory:String):Void {
		
		if (FileSystem.exists (directory)) {
			
			for (file in FileSystem.readDirectory (directory)) {
				
				var path = directory + "/" + file;
				
				if (FileSystem.isDirectory (path)) {
					
					removeDirectory (path);
					
				} else {
					
					FileSystem.deleteFile (path);
					
				}
				
			}
			
			FileSystem.deleteDirectory (directory);
			
		}
		
	}
	

	public static function runCommand (path:String, command:String, args:Array<String>):Int {
		
		var oldPath:String = "";
		
		if (path != "") {
			
			//Lib.println ("cd " + path);
			
			oldPath = Sys.getCwd ();
			Sys.setCwd (path);
			
		}
		
		//Lib.println (command + (args==null ? "": " " + args.join(" ")) );
		
		var result:Dynamic = Sys.command (command, args);
		
		//if (result == 0)
			//print("Ok.");
			
		
		if (oldPath != "") {
			
			Sys.setCwd (oldPath);
			
		}
		
		return result;
		
		//if (result != 0) {
			
			//throw ("Error running: " + command + " " + args.join (" ") + " [" + path + "]");
			
		//}
		
	}
	
	
	public static function main () {
		
		nmeDirectory = getHaxelib ("nme");
		
		if (new EReg ("window", "i").match (Sys.systemName ())) {
			
			isLinux = false;
			isMac = false;
			isWindows = true;
			
		} else if (new EReg ("linux", "i").match (Sys.systemName ())) {
			
			isLinux = true;
			isMac = false;
			isWindows = false;
			
		} else if (new EReg ("mac", "i").match (Sys.systemName ())) {
			
			isLinux = false;
			isMac = true;
			isWindows = false;
			
		}
		
		var args:Array <String> = Sys.args ();
		var command = args[0];
		
		if (command == "rebuild" || command == "release") {
			
			if (nmeDirectory.indexOf ("C:\\Motion-Twin") != -1 || nmeDirectory.indexOf ("/usr/lib/haxe/lib") != -1) {
				
				Sys.println ("This command can only be run from a development build of NME");
				return;
				
			}
			
			var targets:Array <String> = null;
			
			if (args.length > 2) {
				
				targets = args[1].split (",");
				
			}
			
			switch (command) {
				
				case "rebuild":
					
					build (targets);
				
				case "release":
					
					release (targets);
					
			}
			
		} else {
			
			if (!FileSystem.exists (nmeDirectory + "/tools/command-line/command-line.n")) {
				
				build ();
				
			}
			
			args.unshift ("tools/command-line/command-line.n");
			Sys.exit (runCommand (nmeDirectory, "neko", args));
			
		}
		
	}
	
	
	public static function recursiveZip (source:String, destination:String, ignore:Array <String> = null, subFolder:String = "", files:Array <Dynamic> = null) {
		
		if (files == null) {
			
			files = new Array <Dynamic> ();
			
		}
		
		for (file in FileSystem.readDirectory (source)) {
			
			var ignoreFile = false;
			
			if (ignore != null) {
				
				for (ignoreName in ignore) {
					
					if (file == ignoreName) {
						
						ignoreFile = true;
						
					}
					
				}
				
			}
			
			if (!ignoreFile) {
				
				var name = file;
				
				if (subFolder != "") {
					
					name = subFolder + "/" + file;
					
				}
				
				//var date = FileSystem.stat (directory + "/" + file).ctime;
				var date = Date.now ();
				var data = null;
				
				if (isWindows) {
					
					Sys.println ("Adding: " + name);
					
					var input = File.read (source + "/" + file, true);
					var data = input.readAll ();
					input.close ();
					
				}
				
				files.push ( { fileName: name, fileTime: date, data: data } );
				
				if (FileSystem.isDirectory (source + "/" + file)) {
					
					if (subFolder != "") {
						
						recursiveZip (source + "/" + file, null, ignore, subFolder + "/" + file, files);
						
					} else {
						
						recursiveZip (source + "/" + file, null, ignore, file, files);
						
					}
					
				}
				
			}
			
		}
		
		if (destination != null) {
			
			if (isWindows) {
				
				Sys.println ("Writing: " + destination);
				
				var output = File.write (destination, true);
				Writer.writeZip (output, files, 1);
				output.close ();
				
				Sys.println ("Done.");
				Sys.println ("");
				
			} else {
				
				var includeList = "";
				
				for (file in files) {
					
					includeList += source + file.fileName + "\n";
					
				}
				
				File.saveContent (destination + ".list", includeList);
				runCommand ("", "zip", [ "-r", destination, source, "-i@" + destination + ".list" ]);
				FileSystem.deleteFile (destination + ".list");
				
			}
			
		}
		
	}
	
	
	private static function release (targets:Array<String> = null):Void {
		
		if (targets == null) {
			
			targets = [ "zip" ];
			
		}
		
		for (target in targets) {
			
			switch (target) {
				
				case "upload":
					
					var user = param ("FTP username");
					var password = param ("FTP password", true);
					
					if (isWindows) {
						
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Windows/nme.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Windows/nme-debug.ndll" ]);
						
					} else if (isLinux) {
						
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Linux/nme.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Linux/nme-debug.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Linux64/nme.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Linux64/nme-debug.ndll" ]);
						
					} else if (isMac) {
						
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Mac/nme.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "Mac/nme-debug.ndll" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme.iphoneos.a" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme.iphoneos-v7.a" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme.iphonesim.a" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme-debug.iphoneos.a" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme-debug.iphoneos-v7.a" ]);
						runCommand (nmeDirectory, "tools/run-script/upload-build.sh", [ user, password, "iPhone/libnme-debug.iphonesim.a" ]);
						
					}
			
				case "download":
					
					if (!isWindows) {
					
						downloadFile ("http://www.haxenme.org/builds/ndll/Windows/nme.ndll", nmeDirectory + "/ndll/Windows/nme.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/Windows/nme-debug.ndll", nmeDirectory + "/ndll/Windows/nme-debug.ndll");
					
					}
					
					if (!isLinux) {
						
						downloadFile ("http://www.haxenme.org/builds/ndll/Linux/nme.ndll", nmeDirectory + "/ndll/Linux/nme.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/Linux/nme-debug.ndll", nmeDirectory + "/ndll/Linux/nme-debug.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/Linux64/nme.ndll", nmeDirectory + "/ndll/Linux64/nme.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/Linux64/nme-debug.ndll", nmeDirectory + "/ndll/Linux64/nme-debug.ndll");
						
					}
					
					if (!isMac) {
						
						downloadFile ("http://www.haxenme.org/builds/ndll/Mac/nme.ndll", nmeDirectory + "/ndll/Mac/nme.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/Mac/nme-debug.ndll", nmeDirectory + "/ndll/Mac/nme-debug.ndll");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme.iphoneos.a", nmeDirectory + "/ndll/iPhone/libnme.iphoneos.a");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme.iphoneos-v7.a", nmeDirectory + "/ndll/iPhone/libnme.iphoneos-v7.a");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme.iphonesim.a", nmeDirectory + "/ndll/iPhone/libnme.iphonesim.a");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme-debug.iphoneos.a", nmeDirectory + "/ndll/iPhone/libnme-debug.iphoneos.a");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme-debug.iphoneos-v7.a", nmeDirectory + "/ndll/iPhone/libnme-debug.iphoneos-v7.a");
						downloadFile ("http://www.haxenme.org/builds/ndll/iPhone/libnme-debug.iphonesim.a", nmeDirectory + "/ndll/iPhone/libnme-debug.iphonesim.a");
						
					}
					
				case "zip":
				
					recursiveZip (nmeDirectory, nmeDirectory + "../nme.zip",  [ "bin", "obj", "resources", ".git", ".svn", ".DS_Store" ]);
					
					if (target == "haxelib") {
						
						runCommand (nmeDirectory, "haxelib", [ "submit", "../nme.zip" ]);
						
					}
				
			}
			
		}
		
	}
	
	
	private static var nme_error_output;
	
	
}


class Progress extends haxe.io.Output {

	var o : haxe.io.Output;
	var cur : Int;
	var max : Int;
	var start : Float;

	public function new(o) {
		this.o = o;
		cur = 0;
		start = haxe.Timer.stamp();
	}

	function bytes(n) {
		cur += n;
		if( max == null )
			Lib.print(cur+" bytes\r");
		else
			Lib.print(cur+"/"+max+" ("+Std.int((cur*100.0)/max)+"%)\r");
	}

	public override function writeByte(c) {
		o.writeByte(c);
		bytes(1);
	}

	public override function writeBytes(s,p,l) {
		var r = o.writeBytes(s,p,l);
		bytes(r);
		return r;
	}

	public override function close() {
		super.close();
		o.close();
		var time = haxe.Timer.stamp() - start;
		var speed = (cur / time) / 1024;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;
		Lib.print("Download complete : " + cur + " bytes in " + time + "s (" + speed + "KB/s)\n");
	}

	public override function prepare(m) {
		max = m;
	}

}
