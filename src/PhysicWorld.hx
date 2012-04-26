package;
	
	//ActionScript 3.0 Classes
		import flash.display.MovieClip;

	//Class definition	
		class PhysicWorld extends MovieClip{
			
			//------------------------------------
			//  CLASS PROPERTIES	
			//------------------------------------
				
					//We define the public properties
						public var steps:Int;
						public var draw:Bool;
						public var debug:Bool;
						public var floor : Float;
						public var size : phx.Vector;
						public var dt:Float;
						public var niter:Int;
						public var world : phx.World;
					
					//We define the private properties
						private var stopped:Bool;
						private var recalStep:Bool;
						private var curbf : Int;
						private var frame : Int;
						private var broadphases : Array<phx.col.BroadPhase>;
			
				
			//------------------------------------
			//  CLASS CONSTRUCTOR	
			//------------------------------------
					
					//We define the constructor for the class
						public function new(){
							super();
							dt = 1;
							steps = 3;
							niter = 20;
							draw = true;
							debug = false;
							stopped = false;
							recalStep = false;
							floor = 580;		
							size = new phx.Vector(600,600);
							var refToScope = this;
							broadphases = new Array();
							broadphases.push(new phx.col.SortedList());
							broadphases.push(new phx.col.Quantize(6));
							broadphases.push(new phx.col.BruteForce());
							world = new phx.World(new phx.col.AABB(-2000,-2000,2000,2000),broadphases[curbf]);
							flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
							flash.Lib.current.stage.addEventListener( flash.events.Event.ENTER_FRAME, function(_) refToScope.updatingPhysics() );
							flash.Lib.current.stage.addEventListener( flash.events.MouseEvent.MOUSE_DOWN, function(_)  refToScope.fireBlock(refToScope.root.mouseX, refToScope.root.mouseY) );
							flash.Lib.current.stage.addEventListener( flash.events.KeyboardEvent.KEY_DOWN, function(e:flash.events.KeyboardEvent) refToScope.onKeyDown(e.keyCode) );
						}
			
			
		//------------------------------------
		// PRIVATE CLASS METHODS	
		//------------------------------------

					//Public helper method which will either create a static or freeform convex polygon instancess	
						public function addConvexPolygon(_static:Bool, _x:Int, _y:Int, _nverts:Int, _radius:Float, _rotation:Float,  ?_material, ?_properties ) {
							var shape = createConvexPolygon(_x, _y, _nverts, _radius, _rotation, _material);
							if(_static){ world.addStaticShape(shape);
							}else{ addBody(_x, _y, shape, _properties); }
						}
				
					//Public helper method which will either create a static or freeform box instance	
						public function addPolygon(_static:Bool, _x:Int, _y:Int, _nverts:Int, _radius:Float, _rotation:Float,  ?_material, ?_properties ) {
							var boxShape = phx.Shape.makeBox(10,10 ,_x, _y, _material);
							var shape = createPolygon(_x, _y, boxShape);
							if(_static){ world.addStaticShape(shape);
							}else{ addBody(_x, _y, shape, _properties); }
						}
					
					
					//Public helper method which will either create a static or freeform box instance	
							public function addBox(_static:Bool,_x:Int, _y:Int, _width:Int, _height:Int, ?_material, ?_properties ) {
								var shape = phx.Shape.makeBox(_width,_height ,_x, _y, _material);
								if(_static){ world.addStaticShape(shape);
								}else{ addBody(_x, _y, shape, _properties); }
							}
						
						
					//Adds Physics Body'sto the current world
						public function addBody( x, y, shape, ?properties ) {
							var b = new phx.Body(x,y);
							b.addShape(shape);
							if( properties != null ) b.properties = properties;
							world.addBody(b);
							return b;
						}
						
				//Generates a random number 
						public function randomNumber( min : Float, max : Float ) {
							return Math.round(Math.random() * (max - min + 1)) + min;
						}
				
				
				
		//------------------------------------
		// PRIVATE CLASS METHODS	
		//------------------------------------	
					
				//Public helper method which will either create a static or freeform box instance	
					private function createConvexPolygon( _x:Int, _y:Int, nverts : Int, radius : Float, rotation : Float, ?mat ) {
						var vl = new Array();
						for( i in 0...nverts ) {
							var angle = ( -2 * Math.PI * i ) / nverts;
							angle += rotation;
							vl.push( new phx.Vector(radius * Math.cos(angle), radius * Math.sin(angle)) );
						}
						return new phx.Polygon( vl, new phx.Vector(_x,_y), mat );
					}
					
					
				//Public helper method which will either create a static or freeform box instance	
					private function createPolygon( _x:Int, _y:Int, shape:phx.Polygon ) {
						var vl = new Array();
						var v = shape.verts;
						while( v != null ) { vl.push(v); v = v.next; }
						return new phx.Polygon( vl, new phx.Vector(_x,_y), shape.material );
					}
				
				
				//Handles firing block when the user presses the mouse button
					private function fireBlock( mouseX : Float, mouseY : Float ) {
						var width = root.stage.stageWidth;
						var height = root.stage.stageHeight;
						var pos = new phx.Vector(width,height);
						pos.x += 100;
						pos.y /= 3;
						var v = new phx.Vector( mouseX - pos.x, mouseY - pos.y );
						var k = 15 / v.length();
						v.x *= k;
						v.y *= k;
						var b = new phx.Body(0,0);
						b.set(pos,0,v,2);
						b.addShape( phx.Shape.makeBox(20,20,new phx.Material(0.0, 1, 5)) );
						world.addBody(b);
					}
				
					
			//Handles updating the phyiscs instance			
					private function updatingPhysics() {
							for( i in 0...steps ) { try { world.step( dt/steps, niter ); } catch( e : Dynamic ) { throw e; } }
							if( recalStep ) world.step(0,1);
							this.graphics.clear(); 
							var physicDraw = new phx.FlashDraw(this.graphics);		
							if( debug ) {
								physicDraw.boundingBox.line = 0x000000;
								physicDraw.contact.line = 0xFF0000;
								physicDraw.sleepingContact.line = 0xFF00FF;
								physicDraw.drawCircleRotation = true;
							}
							if( draw ) physicDraw.drawWorld(world);	
					}
			
			//Handles the required keyboard events
					private function onKeyDown( code : Int ) {
						switch( code ) {
							case 32:
								debug = !debug;
							case 66: 
								curbf = (curbf + 1) % broadphases.length;
								world.setBroadPhase(broadphases[curbf]);
							case 68: 
								draw = !draw;
						}
					}
		
		}
