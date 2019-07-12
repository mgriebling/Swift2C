//
//  CodeGen.swift
//  Taste
//
//  Created by Michael Griebling on 8Aug2017.
//  Copyright © 2017 Solinst Canada. All rights reserved.
//

import Foundation

/* opcodes */
public enum Op : Int {
    case ADD, SUB, MUL, DIV, OR, AND, NOT, REM, EQU, LSS, GTR, LTE, GTE, NEQ, NEG, LOAD, LOADG,
    STO, STOG, CONST, CALL, RET, ENTER, LEAVE, JMP, FJMP, READ, WRITE,
    UNDEF
}

extension OType : CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .boolean(_): return "bool"
        case .integer(_): return "int"
        case .double(_): return "double"
        case .string(_): return "char *"
        case .character(_): return "char"
        case .any(_): return "void *"
        case .undef: return "undefined"
        }
    }
}

public class CodeGenerator {
    
    var ccode = ""             /* output code */
    
    public func Emit(_ op: Op) {
        Emit(" ")
        switch op {
        case .ADD: Emit("+")
        case .AND: Emit("&")
        case .DIV: Emit("/")
        case .GTE: Emit(">=")
        case .GTR: Emit(">")
        case .LSS: Emit("<")
        case .LTE: Emit("<=")
        case .NEQ: Emit("!=")
        case .EQU: Emit("==")
        default: break
        }
        Emit(" ")
    }
    
    public func Emit(_ o1: Obj, _ op: Op, _ o2: Obj) {
        Emit(o1); Emit(op); Emit(o2)
    }
    
    public func Emit(_ op: Op, _ o: Obj) {
        Emit(op); Emit(o)
    }
    
    public func Emit(_ s: String) {
        print(s, terminator:"") // print(s, terminator:"", to:&ccode)
    }
    
    public func Ln() {
        print("")  // print("", to:&ccode)
    }
    
    public func Emit(value v: OType) {
        switch v {
        case .boolean(let b): Emit("\(b)")
        case .integer(let i): Emit("\(i)")
        case .double(let x): Emit("\(x)")
        case .string(let s): Emit("\"\(s)\"")
        case .character(let c): Emit("\"\(c)\"")
        default: break
        }
    }
    
    public func Emit(type v: OType) {
        Emit("\(v) ")
    }
    
    public func Emit(_ o: Obj) {
        switch o.kind {
        case .constant: Emit(value: o.type)
        case .proc: Emit(o.name)
        case .variable: Emit(o.name)
        default: break
        }
    }

}
