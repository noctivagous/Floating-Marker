//
//  LRTBezierPathWrapper.swift
//  Swift VectorBoolean for iOS
//
//  Created by Leslie Titze on 2015-05-11.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.
//

import Cocoa



public class LRTBezierPathWrapper {

    private(set) public var elements: [PathElement]
    fileprivate var _bezierPath : NSBezierPath
    
  /*  private(set) public var elements: [PathElement]
  fileprivate var _bezierPath : NSBezierPath
*/
    
  var bezierPath : NSBezierPath {
    get {
      return _bezierPath
    }
  }

  public init(_ bezierPath:NSBezierPath) {
    elements = []
    _bezierPath = bezierPath
    createElementsFromCGPath()
  }

  func createElementsFromCGPath() {
    let cgPath = _bezierPath.cgPath

    cgPath.apply({
      (e : PathElement) -> Void in
      self.elements.append(e)
      /* Enable this to show that it actually works
      switch e {
      case let .Move(v):
        println("Move; value is \(v)")
      case .Line(let whee):
        println("Line: Whee is \(whee)")
      case .QuadCurve(let to, let via):
        println("QuadCurve: to \(to) via \(via)")
      case .CubicCurve(let to, let v1, let v2):
        println("CubicCurve: to \(to) via \(v1) and \(v2)")
      case let .Close:
        println("Close Subpath")
      default:
        println("Other")
      }
      */
    })
  }

}
