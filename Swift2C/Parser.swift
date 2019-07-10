/*-------------------------------------------------------------------------
    Compiler Generator Coco/R,
    Copyright (c) 1990, 2004 Hanspeter Moessenboeck, University of Linz
    extended by M. Loeberbauer & A. Woess, Univ. of Linz
    with improvements by Pat Terry, Rhodes University
    Swift port by Michael Griebling, 2015-2017

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2, or (at your option) any
    later version.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

    As an exception, it is allowed to write an extension of Coco/R that is
    used as a plugin in non-free software.

    If not otherwise stated, any source code generated by Coco/R (other than
    Coco/R itself) does not fall under the GNU General Public License.

    NOTE: The code below has been automatically generated from the
    Parser.frame, Scanner.frame and Coco.atg files.  DO NOT EDIT HERE.
-------------------------------------------------------------------------*/

import Foundation



public class Parser {
	public let _EOF = 0
	public let _ident = 1
	public let _hexNumber = 2
	public let _decNumber = 3
	public let _octalInt = 4
	public let _hexInt = 5
	public let _binInt = 6
	public let _decInt = 7
	public let _string = 8
	public let _char = 9
	public let _class = 10
	public let _func = 14
	public let _Int = 17
	public let _Bool = 18
	public let _Double = 19
	public let _String = 20
	public let _Character = 21
	public let _Any = 22
	public let _var = 23
	public let _let = 24
	public let _if = 26
	public let _else = 27
	public let _while = 28
	public let _repeat = 29
	public let _case = 30
	public let _default = 31
	public let _switch = 32
	public let _read = 34
	public let _print = 35
	public let _true = 36
	public let _false = 37
	public let maxT = 52

	static let _T = true
	static let _x = false
	static let minErrDist = 2
	let minErrDist : Int = Parser.minErrDist

	public var scanner: Scanner
	public var errors: Errors

	public var t: Token             // last recognized token
	public var la: Token            // lookahead token
	var errDist = Parser.minErrDist

	let variable = 0; let constant = 1; let proc = 2; let scope = 3
	
	public var tab : SymbolTable!
	public var gen : CodeGenerator!
	
	/*--------------------------------------------------------------------------*/
	
	


    public init(scanner: Scanner) {
        self.scanner = scanner
        errors = Errors()
        t = Token()
        la = t
    }
    
    func SynErr (_ n: Int) {
        if errDist >= minErrDist { errors.SynErr(la.line, col: la.col, n: n) }
        errDist = 0
    }
    
    public func SemErr (_ msg: String) {
        if errDist >= minErrDist { errors.SemErr(t.line, col: t.col, s: msg) }
        errDist = 0
    }

	func Get () {
		while true {
            t = la
            la = scanner.Scan()
            if la.kind <= maxT { errDist += 1; break }

			la = t
		}
	}
	
    func Expect (_ n: Int) {
        if la.kind == n { Get() } else { SynErr(n) }
    }
    
    func StartOf (_ s: Int) -> Bool {
        return set(s, la.kind)
    }
    
    func ExpectWeak (_ n: Int, _ follow: Int) {
        if la.kind == n {
			Get()
		} else {
            SynErr(n)
            while !StartOf(follow) { Get() }
        }
    }
    
    func WeakSeparator(_ n: Int, _ syFol: Int, _ repFol: Int) -> Bool {
        var kind = la.kind
        if kind == n { Get(); return true }
        else if StartOf(repFol) { return false }
        else {
            SynErr(n)
            while !(set(syFol, kind) || set(repFol, kind) || set(0, kind)) {
                Get()
                kind = la.kind
            }
            return StartOf(syFol)
        }
    }

	func Swift2C() {
		Expect(_class)
		Expect(_ident)
		tab.OpenScope() 
		Expect(11 /* "{" */)
		while la.kind == _func || la.kind == _var || la.kind == _let {
			if la.kind == _var || la.kind == _let {
				VarDecl()
				if la.kind == 12 /* ";" */ {
					Get()
				}
			} else {
				ProcDecl()
			}
		}
		Expect(13 /* "}" */)
		tab.CloseScope()
		if gen.progStart == -1 { SemErr("main function never defined") }
		
	}

	func VarDecl() {
		var obj: Obj! = nil; var name = ""; var type = OType.undef; var kind = variable 
		if la.kind == _var {
			Get()
		} else if la.kind == _let {
			Get()
			kind = constant 
		} else { SynErr(53) }
		Expect(_ident)
		name = t.val 
		Expect(25 /* ":" */)
		Type(&type)
		obj = tab.NewObj(name, kind, type)
		gen.Emit(obj) 
	}

	func ProcDecl() {
		var name = ""; var obj: Obj! = nil; var adr: Int 
		Expect(_func)
		Expect(_ident)
		name = t.val; obj = tab.NewObj(name, proc, .undef); obj.adr = gen.pc
		if name == "Main" { gen.progStart = gen.pc }
		tab.OpenScope() 
		Expect(15 /* "(" */)
		Expect(16 /* ")" */)
		gen.Emit( .ENTER, 0 ); adr = gen.pc - 2 
		CodeBlock()
		gen.Emit( .LEAVE ); gen.Emit( .RET )
		gen.Patch(adr, tab.topScope!.nextAdr)
		tab.CloseScope() 
	}

	func CodeBlock() {
		Expect(11 /* "{" */)
		gen.Emit("{") 
		Statements()
		Expect(13 /* "}" */)
		gen.Emit("}") 
	}

	func Type(_ type: inout OType) {
		type = .undef 
		switch la.kind {
		case _Int: 
			Get()
			type = .integer(0) 
		case _Bool: 
			Get()
			type = .boolean(false) 
		case _Double: 
			Get()
			type = .double(0) 
		case _String: 
			Get()
			type = .string("") 
		case _Character: 
			Get()
			type = .character("\0") 
		case _Any: 
			Get()
			type = .any(0) 
		default: SynErr(54)
		}
	}

	func IfStat() {
		var obj: Obj! = nil 
		Expect(_if)
		gen.Emit("if (") 
		Expr(&obj)
		gen.Emit(")") 
		CodeBlock()
		while la.kind == _else {
			Get()
			if la.kind == _if {
				Get()
				gen.Emit("else if (") 
				Expr(&obj)
				gen.Emit(")") 
				CodeBlock()
			} else if la.kind == 11 /* "{" */ {
				gen.Emit("else") 
				CodeBlock()
			} else { SynErr(55) }
		}
	}

	func Expr(_ obj: inout Obj!) {
		var obj2: Obj! = nil; var op = Op.UNDEF 
		SimExpr(&obj)
		if StartOf(1) {
			RelOp(&op)
			SimExpr(&obj2)
			gen.BinExpr(obj, op, obj2) 
		}
	}

	func WhileStat() {
		var obj: Obj! = nil 
		Expect(_while)
		gen.Emit("while (") 
		Expr(&obj)
		gen.Emit(")") 
		CodeBlock()
	}

	func RepeatStat() {
		var obj: Obj! = nil 
		Expect(_repeat)
		gen.Emit("do") 
		CodeBlock()
		Expect(_while)
		gen.Emit("while (") 
		Expr(&obj)
		gen.Emit(")") 
	}

	func Pattern() {
		var obj: Obj! = nil 
		Expr(&obj)
	}

	func CaseLabel() {
		if la.kind == _case {
			Get()
			gen.Emit("case") 
			Pattern()
		} else if la.kind == _default {
			Get()
			gen.Emit("default") 
		} else { SynErr(56) }
		Expect(25 /* ":" */)
		gen.Emit(":") 
	}

	func SwitchCase() {
		CaseLabel()
		Statements()
	}

	func Statements() {
		while StartOf(2) {
			Stat()
			if la.kind == 12 /* ";" */ {
				Get()
			}
		}
	}

	func SwitchStat() {
		var obj : Obj? = nil 
		Expect(_switch)
		gen.Emit("switch") 
		Expr(&obj)
		Expect(11 /* "{" */)
		gen.Emit("{") 
		while la.kind == _case || la.kind == _default {
			SwitchCase()
		}
		Expect(13 /* "}" */)
		gen.Emit("}") 
	}

	func Stat() {
		var obj2 : Obj!; var obj: Obj! 
		switch la.kind {
		case _ident: 
			Get()
			obj = tab.Find(t.val); gen.Emit(obj) 
			if la.kind == 33 /* "=" */ {
				Get()
				if obj.kind != variable { SemErr("cannot assign to procedure") }
				gen.Emit(" = ")  
				Expr(&obj2)
				if obj2.type != obj.type { SemErr("incompatible types") } 
			} else if la.kind == 15 /* "(" */ {
				Get()
				Expect(16 /* ")" */)
				if obj.kind != proc { SemErr("object is not a procedure") }
				gen.Emit("()") 
			} else { SynErr(57) }
		case _if: 
			IfStat()
		case _while: 
			WhileStat()
		case _repeat: 
			RepeatStat()
		case _switch: 
			SwitchStat()
		case _read: 
			Get()
			Expect(15 /* "(" */)
			Expect(_ident)
			Expect(16 /* ")" */)
			if !obj.type.isNumber { SemErr("numeric type expected") }
			gen.Emit( .READ )
			if obj.level == 0 { gen.Emit( .STOG, obj.adr ) }
			else { gen.Emit( .STO, obj.adr ) } 
		case _print: 
			Get()
			Expect(15 /* "(" */)
			Expr(&obj)
			Expect(16 /* ")" */)
			if !obj.type.isNumber { SemErr("numeric type expected") }
			gen.Emit( .WRITE ) 
		case _var, _let: 
			VarDecl()
		default: SynErr(58)
		}
	}

	func SimExpr(_ obj: inout Obj!) {
		var obj2: Obj! = nil; var op = Op.UNDEF 
		Term(&obj)
		while la.kind == 38 /* "-" */ || la.kind == 44 /* "+" */ || la.kind == 45 /* "|" */ {
			AddOp(&op)
			Term(&obj2)
			gen.BinExpr(obj, op, obj2) 
		}
	}

	func RelOp(_ op: inout Op) {
		op = .EQU 
		switch la.kind {
		case 46 /* "==" */: 
			Get()
		case 47 /* "<" */: 
			Get()
			op = .LSS 
		case 48 /* ">" */: 
			Get()
			op = .GTR 
		case 49 /* ">=" */: 
			Get()
			op = .GTE 
		case 50 /* "<=" */: 
			Get()
			op = .LTE 
		case 51 /* "!=" */: 
			Get()
			op = .NEQ 
		default: SynErr(59)
		}
	}

	func Term(_ obj: inout Obj!) {
		var obj2: Obj! = nil; var op = Op.UNDEF 
		Factor(&obj)
		while StartOf(3) {
			MulOp(&op)
			Factor(&obj2)
			gen.BinExpr(obj, op, obj2) 
		}
	}

	func AddOp(_ op: inout Op) {
		op = .ADD 
		if la.kind == 44 /* "+" */ {
			Get()
		} else if la.kind == 38 /* "-" */ {
			Get()
			op = .SUB 
		} else if la.kind == 45 /* "|" */ {
			Get()
			op = .OR 
		} else { SynErr(60) }
	}

	func Factor(_ obj: inout Obj!) {
		obj = nil 
		switch la.kind {
		case _ident: 
			Get()
			obj = tab.Find(t.val); gen.Emit(obj) 
		case _true: 
			Get()
			obj = gen.BoolCon(true) 
		case _false: 
			Get()
			obj = gen.BoolCon(false) 
		case _decInt: 
			Get()
			obj = gen.IntCon(t.val, 10) 
		case _binInt: 
			Get()
			obj = gen.IntCon(t.val, 2) 
		case _hexInt: 
			Get()
			obj = gen.IntCon(t.val, 16) 
		case _octalInt: 
			Get()
			obj = gen.IntCon(t.val, 8) 
		case _hexNumber: 
			Get()
			obj = gen.DoubleCon(t.val, 16) 
		case _decNumber: 
			Get()
			obj = gen.DoubleCon(t.val) 
		case _char: 
			Get()
			obj = gen.CharCon(t.val) 
		case _string: 
			Get()
			obj = gen.StringCon(t.val) 
		case 38 /* "-" */: 
			Get()
			Factor(&obj)
			obj = gen.UnaryExpr(Op.SUB, obj) 
		case 39 /* "~" */: 
			Get()
			Factor(&obj)
			obj = gen.UnaryExpr(Op.NOT, obj) 
		case 15 /* "(" */: 
			Get()
			obj = nil 
			if StartOf(4) {
				Expr(&obj)
			}
			Expect(16 /* ")" */)
		default: SynErr(61)
		}
	}

	func MulOp(_ op: inout Op) {
		op = .MUL 
		if la.kind == 40 /* "*" */ {
			Get()
		} else if la.kind == 41 /* "/" */ {
			Get()
			op = .DIV 
		} else if la.kind == 42 /* "%" */ {
			Get()
			op = .REM 
		} else if la.kind == 43 /* "&" */ {
			Get()
			op = .AND 
		} else { SynErr(62) }
	}



    public func Parse() {
        la = Token()
        la.val = ""
        Get()
		Swift2C()
		Expect(_EOF)

	}

    func set (_ x: Int, _ y: Int) -> Bool { return Parser._set[x][y] }
    static let _set: [[Bool]] = [
		[_T,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x],
		[_x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_T,_T, _T,_T,_T,_T, _x,_x],
		[_x,_T,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_T, _T,_x,_T,_x, _T,_T,_x,_x, _T,_x,_T,_T, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x],
		[_x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _T,_T,_T,_T, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x],
		[_x,_T,_T,_T, _T,_T,_T,_T, _T,_T,_x,_x, _x,_x,_x,_T, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _T,_T,_T,_T, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x]

	]
} // end Parser


public class Errors {
    public var count = 0                                 // number of errors detected
    private let errorStream = Darwin.stderr              // error messages go to this stream
    public var errMsgFormat = "-- line %i col %i: %@"    // 0=line, 1=column, 2=text
    
    func Write(_ s: String) { fputs(s, errorStream) }
    func WriteLine(_ format: String, line: Int, col: Int, s: String) {
        let str = String(format: format, line, col, s)
        WriteLine(str)
    }
    func WriteLine(_ s: String) { Write(s + "\n") }
    
    public func SynErr (_ line: Int, col: Int, n: Int) {
        var s: String
        switch n {
		case 0: s = "EOF expected"
		case 1: s = "ident expected"
		case 2: s = "hexNumber expected"
		case 3: s = "decNumber expected"
		case 4: s = "octalInt expected"
		case 5: s = "hexInt expected"
		case 6: s = "binInt expected"
		case 7: s = "decInt expected"
		case 8: s = "string expected"
		case 9: s = "char expected"
		case 10: s = "\"class\" expected"
		case 11: s = "\"{\" expected"
		case 12: s = "\";\" expected"
		case 13: s = "\"}\" expected"
		case 14: s = "\"func\" expected"
		case 15: s = "\"(\" expected"
		case 16: s = "\")\" expected"
		case 17: s = "\"Int\" expected"
		case 18: s = "\"Bool\" expected"
		case 19: s = "\"Double\" expected"
		case 20: s = "\"String\" expected"
		case 21: s = "\"Character\" expected"
		case 22: s = "\"Any\" expected"
		case 23: s = "\"var\" expected"
		case 24: s = "\"let\" expected"
		case 25: s = "\":\" expected"
		case 26: s = "\"if\" expected"
		case 27: s = "\"else\" expected"
		case 28: s = "\"while\" expected"
		case 29: s = "\"repeat\" expected"
		case 30: s = "\"case\" expected"
		case 31: s = "\"default\" expected"
		case 32: s = "\"switch\" expected"
		case 33: s = "\"=\" expected"
		case 34: s = "\"read\" expected"
		case 35: s = "\"print\" expected"
		case 36: s = "\"true\" expected"
		case 37: s = "\"false\" expected"
		case 38: s = "\"-\" expected"
		case 39: s = "\"~\" expected"
		case 40: s = "\"*\" expected"
		case 41: s = "\"/\" expected"
		case 42: s = "\"%\" expected"
		case 43: s = "\"&\" expected"
		case 44: s = "\"+\" expected"
		case 45: s = "\"|\" expected"
		case 46: s = "\"==\" expected"
		case 47: s = "\"<\" expected"
		case 48: s = "\">\" expected"
		case 49: s = "\">=\" expected"
		case 50: s = "\"<=\" expected"
		case 51: s = "\"!=\" expected"
		case 52: s = "??? expected"
		case 53: s = "invalid VarDecl"
		case 54: s = "invalid Type"
		case 55: s = "invalid IfStat"
		case 56: s = "invalid CaseLabel"
		case 57: s = "invalid Stat"
		case 58: s = "invalid Stat"
		case 59: s = "invalid RelOp"
		case 60: s = "invalid AddOp"
		case 61: s = "invalid Factor"
		case 62: s = "invalid MulOp"

        default: s = "error \(n)"
        }
        WriteLine(errMsgFormat, line: line, col: col, s: s)
        count += 1
	}

    public func SemErr (_ line: Int, col: Int, s: String) {
        WriteLine(errMsgFormat, line: line, col: col, s: s);
        count += 1
    }
    
    public func SemErr (_ s: String) {
        WriteLine(s)
        count += 1
    }
    
    public func Warning (_ line: Int, col: Int, s: String) {
        WriteLine(errMsgFormat, line: line, col: col, s: s)
    }
    
    public func Warning(_ s: String) {
        WriteLine(s)
    }
} // Errors
