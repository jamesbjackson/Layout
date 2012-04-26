	
package;
	
	//Global Classes
		import Type;
		import Reflect;
		import Lambda;
		import hscript.Expr;
		import hscript.Parser;
		import hscript.Interp;
		import hscript.Expr;

	//ActionScript 3.0 Classes
		import flash.display.DisplayObjectContainer;	
		import flash.display.DisplayObject;
		import flash.Boot;	
		
		
	//Class definition	
		class Layout {
				
					private static var ScriptKeyword:String = "Script";
					private static var DynamicKeyword:String = "Dynamic";
					private static var IdentiferAttribute:String = "id";
					private static var DefinitionAttribute:String = "ns";
					private static var ReservedAttributes:Array<String> = [ IdentiferAttribute, DefinitionAttribute ];

					//Apply method handles apply the xml to a desinated object
						public static function apply( _xml : Xml ,  ?_parent : Dynamic ){
							for(node in _xml.elements()) applyRecursively(node, _parent, getInstanceName(node) );
						}
					
					
					//Apply method handles apply the xml to a desinated object
							private static function applyRecursively( _xml : Xml ,  ?_parent : Dynamic, ?_parentInstanceName:String ){
									for(node in _xml.elements()) {
											
											//We firstly get the type of class which need's to be accessed
													//trace(node.nodeName + " : " + node.get(IdentiferAttribute) );
													var instance:Dynamic =  {};
													var instanceName:String = getInstanceName(node);
													var fullyQualifiedClassName:String = getFullyQualifiedClassNameFromXML(node);
											
											//We firstly determine if we are dealing with runtime scripting tag, which need's to be applied to the current element.
													if( fullyQualifiedClassName == ScriptKeyword){ 
														var scriptReturnValue:Dynamic = handleScripting(node, _parent);
														if(scriptReturnValue != null  && _parentInstanceName != null) Reflect.setField(_parent, _parentInstanceName, scriptReturnValue);
													}
											
											//We then determine if if the parent is actually a DisplayListContainer. Then we need check to see if the instance is actual 
											//already a child of the DisplayListContainer, if the instance does not already exist we then create a new instance and add 
											//as a child of the DisplayListContainer, We then finally apply all the xml attributes to the fields of the current instance
													else if( ( Std.is(_parent, DisplayObjectContainer) ||  Std.is(_parent, Boot) ) &&  instanceOfSuperClass(fullyQualifiedClassName, DisplayObject) ){ 
														instance = handleDisplayObject(instanceName, fullyQualifiedClassName, _parent);
														instance.name = instanceName;
														applyAttributesToClass(instance, node);
													}

											//We then deal class fields of classes, so firstly check to see if the current object has the requested field and then we 
											//set this field by creating instances of the core datatype of creating instances of more complex datatypes
													else if( Reflect.hasField(_parent, instanceName)  && isSingleElement(node) ){	
														
									 					//We then get the information about the field	
									 						var fieldInstance:Dynamic = Reflect.field(_parent, instanceName);
									 						var fieldValue:String = node.firstChild().nodeValue;
									 						var fieldType = Type.typeof(fieldInstance);
									 					
									 					//We then deal with the core data types, otherwise we are dealing with a more complex class
									 						if(fieldType == ValueType.TInt)	{ Reflect.setField(_parent, instanceName, Std.parseFloat(fieldValue)); }
									 						else if(fieldType == ValueType.TFloat)	{ Reflect.setField(_parent, instanceName, Std.parseFloat(fieldValue)); }
									 						else  if(fieldType == ValueType.TBool)	{ Reflect.setField(_parent, instanceName,  ((fieldValue == "true") ? true : false) ); }			
															else if( Std.is(fieldValue, String) )	{ Reflect.setField(_parent, instanceName, fieldValue); }
															else{ instance = createClassInstance(node, instanceName, fullyQualifiedClassName, _parent); }	
													}
								
											//We then next deal with if the instance is actually a dynamic type so we have then check if the parent is parent is also dynamic and 
											//then create a new dynamic element of the parent object so we can build complex data structures
													else if ( Std.is(_parent, Dynamic) ){
															
															//We then deal with dynamic datatypes due to there special behaviours
																if( fullyQualifiedClassName == DynamicKeyword){ 
																	if ( Std.is(_parent, Array) ){ _parent.push(instance); }
																	else { Reflect.setField(_parent, instanceName, instance); } 
																	applyAttributesToDynamic(instance, node);
																}
														
															//Otherwise we are dealing with a property of the dynamic instance
																else if( fullyQualifiedClassName != ScriptKeyword){ 
																	instance = createClassInstance(node, instanceName, fullyQualifiedClassName, _parent);
																}	
													}
													
											//We then apply to the next datatype recussively
													if(isSingleElement(node) == true) instance = _parent;
													applyRecursively(node, instance, instanceName);
									}
									
							}

					//Handles getting the fully qualified class name
							private static function getFullyQualifiedClassNameFromXML( _node:Xml ):String{
									var classType:String = _node.nodeName;
									var classNamespace:String = (_node.get( DefinitionAttribute ) != null) ? (_node.get( DefinitionAttribute ) + ".")  : "";
									return classNamespace + classType;
							}

					//Handles getting a the instance name of the instance
							private static function getInstanceName( _node:Xml ):String{
								return (_node.get( IdentiferAttribute ) != null) ? _node.get( IdentiferAttribute )  : null;
							}
					
					
					//Handles create new instance of classes
							private static function createInstanceOfClass( _className:String, _arguments:Array<Dynamic> ){
									return Type.createInstance( Type.resolveClass( _className ), _arguments );
							}
					
					//Handles determine if the class is of type of class is the same as another type
							private static function instanceOfSuperClass( _className:String, _superClass:Class<Dynamic> ):Bool{
									return Std.is( createEmptyInstanceOfClass(_className), _superClass);
							}
					
					//Handles creating an empty instance of a class
							private static function createEmptyInstanceOfClass( _className:String ):Dynamic{
									return Type.createEmptyInstance( Type.resolveClass(_className) );
							}
					
					//We then handle get the number of child elements in a xml node
						private static function getNumberOfElements(_node:Xml):Int{
							var counter:Int = 0;
							for(node in _node.elements()){ counter++; }
							return counter;
						}
					
					//We then handle get the number of child elements in a xml node
						private static function isSingleElement(_node:Xml):Bool{
							return (_node.firstChild() != null &&  getNumberOfElements(_node) == 0);
						}
					
					//Create complex class instances
					private static function createClassInstance(_node:Xml, _instanceName:String, _fullyQualifiedClassName:String, _parent:Dynamic):Dynamic{
							var arguments:Array<Dynamic> = new Array();
							if(isSingleElement(_node)) arguments.push(_node.firstChild().nodeValue);
							var instance:Dynamic = createInstanceOfClass(_fullyQualifiedClassName, arguments);
							if ( Std.is(_parent, Array) ){ _parent.push(instance); }
							else { Reflect.setField(_parent, _instanceName, instance); } 
							applyAttributesToClass(instance, _node);
							return instance;
						}
					
					//Handles getting class properties stored as attributes of the node
							private static function applyAttributesToClass(_instance:Dynamic ,_node:Xml){
									for(classField in _node.attributes()) {
											if(  Reflect.hasField(_instance, classField)){	
										 		var fieldInstance:Dynamic = Reflect.field(_instance, classField);
										 		var attributeValue:String = _node.get( classField );
										 		switch( Type.typeof(fieldInstance) ){
													case ValueType.TInt: Reflect.setField(_instance, classField, Std.parseFloat(attributeValue));
													case ValueType.TFloat: Reflect.setField(_instance, classField, Std.parseFloat(attributeValue));
													case ValueType.TBool: Reflect.setField(_instance, classField,  ((attributeValue == "true") ? true : false) );	
													default: Reflect.setField(_instance, classField, attributeValue);
												}
											}				
									}			
							}
					
					
					//Handles getting class properties stored as attributes of the node
							private static function applyAttributesToDynamic(_instance:Dynamic ,_node:Xml){
									for(classField in _node.attributes()) {
										 		if(classField != IdentiferAttribute && classField != DefinitionAttribute ){
										 			var fieldValue:String = Std.string( _node.get(classField)  );
										 			if(Std.is(fieldValue, Int))	{Reflect.setField(_instance, classField, Std.parseFloat(fieldValue)); }
									 				else if(Std.is(fieldValue, Float))	{ Reflect.setField(_instance, classField, Std.parseFloat(fieldValue)); }
									 				else if(fieldValue == "true" || fieldValue == "false") Reflect.setField(_instance, classField,  (fieldValue == "true") ?  true : false )
													else if( Std.is(fieldValue, String) )	{ Reflect.setField(_instance, classField, fieldValue); }
												}		
									}			
							}
							
							
					//We then handle scripting functionality
							private static function handleScripting(_node:Xml, _instance:Dynamic) : Dynamic{

							//We firstly correctly format the script
								var script : String = _node.firstChild().toString();
								script = script.split("<![CDATA[ ").join("");
								script = script.split("]]>").join("");
								script = script.split("\n").join("");
								script = script.split("\t").join("");
								script = script.split(";").join("; ");

							//We then parse andand interpt the script
								var parser = new hscript.Parser();
								var program = parser.parseString(script);
								var interp = new hscript.Interp();
		
							//We then setup the variables which are accessible via this 
								interp.variables.set( "root", flash.Lib.current );
								interp.variables.set( "new", createInstanceOfClass );
								interp.variables.set( "Std", Std );
								interp.variables.set( "Math", Math );
								interp.variables.set( "Type", Type );
								interp.variables.set( "Reflect", Reflect );
								interp.variables.set( "this", _instance );
								interp.variables.set( "trace", traceScript );
								return interp.execute(program); 	
							}		
						
					//Handles tracing output from a script tag
							private static function traceScript(_message:Dynamic){
								trace(_message);
							}	
							

					//Handles creating instances which belong to the display tree
							private static function handleDisplayObject( _instanceName:String, _className:String,  _parent :Dynamic ):Dynamic{
									
								//We create the local variables needed	
									var instance:Dynamic ={};
									var arguments:Array<Dynamic> = new Array();
										
								//We then deal with the ActionScript 3.0 Version	
								    instance = _parent.getChildByName(_instanceName);
									if(instance == null){
										instance = createInstanceOfClass( _className , arguments );
										if( Std.is(instance, DisplayObject) ){
											instance.name = _instanceName;
											_parent.addChild (instance);
										}
									}
									
								//We then return the instance	
									return instance;
							}

		}
