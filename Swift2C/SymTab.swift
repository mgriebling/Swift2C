//
//  SymTab.swift
//  Taste
//
//  Created by Michael Griebling on 8Aug2017.
//  Copyright © 2017 Solinst Canada. All rights reserved.
//

import Foundation

public class Obj {

    var name = ""            /* name of the object */
    var type : OType = .undef /* type of the object (undef for procs) */
    var next : Obj? = nil    /* to next object in same scope */
    
    var kind = 0
    var adr  = 0             /* address in memory or start of proc */
    var level = 0            /* nesting level of declaration */
    
    var locals : Obj? = nil  /* to locally declared objects */
    var nextAdr = 0          /* next free address in this scope */
}

public enum OType: Equatable {
    
    public static func == (lhs: OType, rhs: OType) -> Bool {
        return lhs.order == rhs.order
    }
    
    case undef
    case integer(Int)
    case double(Double)
    case boolean(Bool)
    case string(String)
    case character(Character)
    case any(Any)
    
    public var isNumber: Bool {
        switch self {
        case .integer(_): return true
        case .double(_): return true
        default: return false
        }
    }
    
    private var order: Int {
        switch self {
        case .undef: return 0
        case .integer(_): return 1
        case .double(_): return 2
        case .boolean(_): return 3
        case .string(_): return 4
        case .character(_): return 5
        case .any(_): return 6
        }
    }
}

public class SymbolTable {
    
    // object kinds
    let variable = 0; let constant = 1; let proc = 2; let scope = 3
    
    var undefObj = Obj()        /* object node for erroneous symbols */
    var curLevel = -1           /* nesting level of current scope */
    var topScope : Obj? = nil   /* topmost procedure scope */
    
    var parser : Parser
    
    public init (_ parser: Parser) {
        self.parser = parser
        undefObj.name = "undef"; undefObj.type = .undef; undefObj.kind = variable
    }
    
    public func OpenScope() {
        let scop = Obj()
        scop.name = ""; scop.kind = scope
        scop.next = topScope; topScope = scop
        curLevel += 1
    }
    
    public func CloseScope() {
        topScope = topScope?.next
        curLevel -= 1
    }
    
    public func NewObj (_ name: String, _ kind: Int, _ type: OType) -> Obj {
        let obj = Obj()
        var last : Obj?
        obj.name = name; obj.type = type; obj.kind = kind
        obj.level = curLevel
        
        var p = topScope?.locals
        while p != nil {
            if p!.name == name { parser.SemErr("name declared twice") }
            last = p; p = p?.next
        }
        if last == nil { topScope?.locals = obj }
        else { last?.next = obj }
        if kind == variable {
            obj.adr = topScope!.nextAdr
            topScope!.nextAdr += 1
        }
        return obj
    }
    
    public func Find(_ name: String) -> Obj {
        var scope = topScope
        while scope != nil {
            var obj = scope!.locals
            while obj != nil {
                if obj!.name == name { return obj! }
                obj = obj!.next
            }
            scope = scope!.next
        }
        parser.SemErr(name + " is undeclared")
        return undefObj
    }

}
