package ;

//Required HX Classes	
	import Layout;
	import PhysicWorld;
		
//ActionScript 3.0 Classes
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.Boot;	
	typedef XMLloaderEvents = Event;

class Main {
	

	//Class fields	
		private var urlLoader:URLLoader;


	//Constructor for the class	
		public function new():Void{
			var urlRequest:URLRequest = new URLRequest("flash_layout.xml");
			urlLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, completeListener);
			urlLoader.load(urlRequest);
		}

	//completeListener method is called when the xml file is loaded
		private function completeListener( _event : Event ):Void{
			var xml:Xml = Xml.parse(urlLoader.data);
			var document:MovieClip = cast flash.Lib.current;
			Layout.apply(xml, document);
		}

	//Main entry point for the application
		public static function main(){
			var application:Main = new Main();
		}

}
