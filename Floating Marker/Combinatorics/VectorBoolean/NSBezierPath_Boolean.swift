//
//  NSBezierPath_Boolean.swift
//  Swift VectorBoolean for iOS
//
//  Based on NSBezierPath+Boolean - Created by Andrew Finnell on 5/31/11.
//  Copyright 2011 Fortunate Bear, LLC. All rights reserved.
//
//  Created by Leslie Titze on 2015-05-19.
//  Copyright (c) 2015 Leslie Titze. All rights reserved.

import Cocoa


public extension NSBezierPath {

  // 15
  //- (NSBezierPath *) fb_union:(NSBezierPath *)path
  func fb_union(_ path: NSBezierPath) -> NSBezierPath {
    let thisGraph = FBBezierGraph(path: self)
    let otherGraph = FBBezierGraph(path: path)
    let resultGraph = thisGraph.unionWithBezierGraph(otherGraph)!
    let result = resultGraph.bezierPath
    result.fb_copyAttributesFrom(self)
    return result
  }

  // 24
  //- (NSBezierPath *) fb_intersect:(NSBezierPath *)path
  func fb_intersect(_ path: NSBezierPath) -> NSBezierPath {
    let thisGraph = FBBezierGraph(path: self)
    let otherGraph = FBBezierGraph(path: path)
    let result = thisGraph.intersectWithBezierGraph(otherGraph).bezierPath
    result.fb_copyAttributesFrom(self)
    return result
  }

  // 33
  //- (NSBezierPath *) fb_difference:(NSBezierPath *)path
  func fb_difference(_ path: NSBezierPath) -> NSBezierPath {
    let thisGraph = FBBezierGraph(path: self)
    let otherGraph = FBBezierGraph(path: path)
    let result = thisGraph.differenceWithBezierGraph(otherGraph).bezierPath
    result.fb_copyAttributesFrom(self)
    return result
  }

  // 42
  //- (NSBezierPath *) fb_xor:(NSBezierPath *)path
  func fb_xor(_ path: NSBezierPath) -> NSBezierPath {
    let thisGraph = FBBezierGraph(path: self)
    let otherGraph = FBBezierGraph(path: path)
    let result = thisGraph.xorWithBezierGraph(otherGraph).bezierPath
    result.fb_copyAttributesFrom(self)
    return result
  }

}
