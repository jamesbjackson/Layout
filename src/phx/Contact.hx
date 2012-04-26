/*
 * Copyright (c) 2008, Nicolas Cannasse
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package phx;

class Contact {

	public var px:Float;	// contact point
	public var py:Float;
	public var nx:Float;	// contact normal
	public var ny:Float;
	public var dist:Float;	// contact penetration distance

	// cache prestep values
	public var r1x:Float;
	public var r1y:Float;
	public var r2x:Float;
	public var r2y:Float;
	public var r1nx:Float;
	public var r1ny:Float;
	public var r2nx:Float;
	public var r2ny:Float;
	public var nMass:Float;
	public var tMass:Float;
	public var bounce:Float;

	// persistant contact infomation
	public var jnAcc:Float;
	public var jtAcc:Float;
	public var jBias:Float;
	public var bias:Float;

	public var hash:Int;
	public var updated:Bool;
	public var next:Contact;

	public function new() {
	}

}
