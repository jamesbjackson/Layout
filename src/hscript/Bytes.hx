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
package hscript;
import hscript.Expr;

class Bytes {

	var bin : haxe.io.Bytes;
	var bout : haxe.io.BytesBuffer;
	var pin : Int;
	var hstrings : Hash<Int>;
	var strings : Array<String>;
	var nstrings : Int;

	function new( ?bin ) {
		this.bin = bin;
		pin = 0;
		bout = new haxe.io.BytesBuffer();
		hstrings = new Hash();
		strings = [null];
		nstrings = 1;
	}

	function doEncodeString( v : String ) {
		var vid = hstrings.get(v);
		if( vid == null ) {
			if( nstrings == 256 ) {
				hstrings = new Hash();
				nstrings = 1;
			}
			hstrings.set(v,nstrings);
			bout.addByte(0);
			var vb = haxe.io.Bytes.ofString(v);
			bout.addByte(vb.length);
			bout.add(vb);
			nstrings++;
		} else
			bout.addByte(vid);
	}

	function doDecodeString() {
		var id = bin.get(pin++);
		if( id == 0 ) {
			var len = bin.get(pin);
			var str = bin.readString(pin+1,len);
			pin += len + 1;
			if( strings.length == 255 )
				strings = [null];
			strings.push(str);
			return str;
		}
		return strings[id];
	}

	function doEncodeConst( c : Const ) {
		switch( c ) {
		case CInt(v):
			if( v >= 0 && v <= 255 ) {
				bout.addByte(0);
				bout.addByte(v);
			} else {
				bout.addByte(1);
				bout.addByte(v & 0xFF);
				bout.addByte((v >> 8) & 0xFF);
				bout.addByte((v >> 16) & 0xFF);
				bout.addByte(v >>> 24);
			}
		case CInt32(v):
			bout.addByte(4);
			var mid = haxe.Int32.toInt(haxe.Int32.and(v,haxe.Int32.ofInt(0xFFFFFF)));
			bout.addByte(mid & 0xFF);
			bout.addByte((mid >> 8) & 0xFF);
			bout.addByte(mid >> 16);
			bout.addByte(haxe.Int32.toInt(haxe.Int32.ushr(v,24)));
		case CFloat(f):
			bout.addByte(2);
			doEncodeString(Std.string(f));
		case CString(s):
			bout.addByte(3);
			doEncodeString(s);
		}
	}

	function doDecodeConst() {
		return switch( bin.get(pin++) ) {
		case 0:
			CInt(bin.get(pin++));
		case 1:
			var i = bin.get(pin) | (bin.get(pin+1) << 8) | (bin.get(pin+2) << 16) | (bin.get(pin+3) << 24);
			pin += 4;
			CInt(i);
		case 2:
			CFloat( Std.parseFloat(doDecodeString()) );
		case 3:
			CString( doDecodeString() );
		case 4:
			var i = bin.get(pin) | (bin.get(pin+1) << 8) | (bin.get(pin+2) << 16);
			var j = bin.get(pin+3);
			pin += 4;
			CInt32(haxe.Int32.or(haxe.Int32.ofInt(i),haxe.Int32.shl(haxe.Int32.ofInt(j),24)));
		default:
			throw "Invalid code "+bin.get(pin-1);
		}
	}

	function doEncode( e : Expr ) {
		bout.addByte(Type.enumIndex(e));
		switch( e ) {
		case EConst(c):
			doEncodeConst(c);
		case EIdent(v):
			doEncodeString(v);
		case EVar(n,e):
			doEncodeString(n);
			if( e == null )
				bout.addByte(255);
			else
				doEncode(e);
		case EParent(e):
			doEncode(e);
		case EBlock(el):
			bout.addByte(el.length);
			for( e in el )
				doEncode(e);
		case EField(e,f):
			doEncode(e);
			doEncodeString(f);
		case EBinop(op,e1,e2):
			doEncodeString(op);
			doEncode(e1);
			doEncode(e2);
		case EUnop(op,prefix,e):
			doEncodeString(op);
			bout.addByte(prefix?1:0);
			doEncode(e);
		case ECall(e,el):
			doEncode(e);
			bout.addByte(el.length);
			for( e in el )
				doEncode(e);
		case EIf(cond,e1,e2):
			doEncode(cond);
			doEncode(e1);
			if( e2 == null )
				bout.addByte(255);
			else
				doEncode(e2);
		case EWhile(cond,e):
			doEncode(cond);
			doEncode(e);
		case EFor(v,it,e):
			doEncodeString(v);
			doEncode(it);
			doEncode(e);
		case EBreak, EContinue:
		case EFunction(params,e,name):
			bout.addByte(params.length);
			for( p in params )
				doEncodeString(p);
			doEncode(e);
			doEncodeString(name == null?"":name);
		case EReturn(e):
			if( e == null )
				bout.addByte(255);
			else
				doEncode(e);
		case EArray(e,index):
			doEncode(e);
			doEncode(index);
		case EArrayDecl(el):
			if( el.length >= 255 ) throw "assert";
			bout.addByte(el.length);
			for( e in el )
				doEncode(e);
		case ENew(cl,params):
			doEncodeString(cl);
			bout.addByte(params.length);
			for( e in params )
				doEncode(e);
		case EThrow(e):
			doEncode(e);
		case ETry(e,v,ecatch):
			doEncode(e);
			doEncodeString(v);
			doEncode(ecatch);
		case EObject(fl):
			bout.addByte(fl.length);
			for( f in fl ) {
				doEncodeString(f.name);
				doEncode(f.e);
			}
		}
	}

	function doDecode() {
		return switch( bin.get(pin++) ) {
		case 0:
			EConst( doDecodeConst() );
		case 1:
			EIdent( doDecodeString() );
		case 2:
			var v = doDecodeString();
			EVar(v,doDecode());
		case 3:
			EParent(doDecode());
		case 4:
			var a = new Array();
			for( i in 0...bin.get(pin++) )
				a.push(doDecode());
			EBlock(a);
		case 5:
			var e = doDecode();
			EField(e,doDecodeString());
		case 6:
			var op = doDecodeString();
			var e1 = doDecode();
			EBinop(op,e1,doDecode());
		case 7:
			var op = doDecodeString();
			var prefix = bin.get(pin++) != 0;
			EUnop(op,prefix,doDecode());
		case 8:
			var e = doDecode();
			var params = new Array();
			for( i in 0...bin.get(pin++) )
				params.push(doDecode());
			ECall(e,params);
		case 9:
			var cond = doDecode();
			var e1 = doDecode();
			EIf(cond,e1,doDecode());
		case 10:
			var cond = doDecode();
			EWhile(cond,doDecode());
		case 11:
			var v = doDecodeString();
			var it = doDecode();
			EFor(v,it,doDecode());
		case 12:
			EBreak;
		case 13:
			EContinue;
		case 14:
			var params = new Array();
			for( i in 0...bin.get(pin++) )
				params.push(doDecodeString());
			var e = doDecode();
			var name = doDecodeString();
			EFunction(params,e,(name == "") ? null: name);
		case 15:
			EReturn(doDecode());
		case 16:
			var e = doDecode();
			EArray(e,doDecode());
		case 17:
			var el = new Array();
			for( i in 0...bin.get(pin++) )
				el.push(doDecode());
			EArrayDecl(el);
		case 18:
			var cl = doDecodeString();
			var el = new Array();
			for( i in 0...bin.get(pin++) )
				el.push(doDecode());
			ENew(cl,el);
		case 19:
			EThrow(doDecode());
		case 20:
			var e = doDecode();
			var v = doDecodeString();
			ETry(e,v,doDecode());
		case 21:
			var fl = new Array();
			for( i in 0...bin.get(pin++) ) {
				var name = doDecodeString();
				var e = doDecode();
				fl.push({ name : name, e : e });
			}
			EObject(fl);
		case 255:
			null;
		default:
			throw "Invalid code "+bin.get(pin - 1);
		}
	}

	public static function encode( e : Expr ) : haxe.io.Bytes {
		var b = new Bytes();
		b.doEncode(e);
		return b.bout.getBytes();
	}

	public static function decode( bytes : haxe.io.Bytes ) : Expr {
		var b = new Bytes(bytes);
		return b.doDecode();
	}

}