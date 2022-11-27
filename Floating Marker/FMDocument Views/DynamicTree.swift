//
//  DynamicTree.swift
//  DynamicTree
//
//  Created by John Pratt on 12/31/18.
//  Copyright © 2018 Noctivagous, Inc. All rights reserved.
//

//
//  DynamicTree.swift
//  Mojumbo
//
//  Created by Benzi on 10/12/16.
//

// Swift port of the Box2D implemention of a dynamic balancing AABB tree
// https://github.com/erincatto/Box2D/blob/master/Box2D/Box2D/Collision/b2DynamicTree.h
// https://github.com/erincatto/Box2D/blob/master/Box2D/Box2D/Collision/b2DynamicTree.cpp
// Also read: http://box2d.org/2014/08/balancing-dynamic-trees/
import Foundation
import CoreGraphics
import Cocoa


extension CGRect {
    var perimeter: CGFloat {
        return 2 * (width + height)
    }
}

struct DynamicTreeNode<T> {
    
    // fattened aabb
    var aabb = CGRect.zero
    var originalAABB = CGRect.zero
    
    // user data
    var item: T? = nil
    
    var parent = -1
    var next = -1
    
    var child1 = -1
    var child2 = -1
    
    // leaf = 0, free node = -1
    var height = -1
    
    var isLeaf: Bool { return child1 == -1 }
    
    init() {}
    
}

public struct DynamicTree<T> {
    
    public let fattenFactor: CGFloat = 2.0
    public let displacementFactor: CGFloat = 8.0
    
    var root = -1
    var nodes = [DynamicTreeNode<T>].init(repeating: DynamicTreeNode<T>(), count: 1)
    
    var freeList = 0
    var insertionCount = 0
    
    
    public init() {
        for i in 0..<nodes.count-1 {
            nodes[i].next = i + 1
            nodes[i].height = -1
        }
        nodes[nodes.count-1].next = -1
        nodes[nodes.count-1].height = -1
    }
    
    public mutating func clear() {
        root = -1
        freeList = 0
        insertionCount = 0
        for i in 0..<nodes.count-1 {
            nodes[i].next = i + 1
            nodes[i].height = -1
            nodes[i].item = nil
        }
        nodes[nodes.count-1].next = -1
        nodes[nodes.count-1].height = -1
        nodes[nodes.count-1].item = nil
    }
    
    func fatten(_ aabb: CGRect) -> CGRect {
        return aabb.insetBy(dx: -fattenFactor, dy: -fattenFactor)
    }
    
    func unfatten(_ aabb: CGRect) -> CGRect {
        return aabb.insetBy(dx: fattenFactor, dy: fattenFactor)
    }
    
    
    public mutating func createProxy(aabb: CGRect, item: T) -> Int {
        
        let index = allocateNode()
        
        nodes[index].aabb = fatten(aabb)
        nodes[index].originalAABB = aabb
        nodes[index].item = item
        nodes[index].height = 0
        
        insertLeaf(index)
        //print("nodes.count: \(nodes.count)")
        return index
    }
    
    public mutating func destroyProxy(index: Int) {
        assert(0 <= index && index < nodes.count)
        assert(nodes[index].isLeaf, "proxy is not a leaf node")
        removeLeaf(index)
        freeNode(index)
    }
    
    public mutating func moveProxy(index: Int, aabb: CGRect, displacement d: CGPoint = CGPoint.zero) -> Bool {
        
        assert(0 <= index && index < nodes.count)
        assert(nodes[index].isLeaf, "proxy is not a leaf node")
        
        nodes[index].originalAABB = aabb
        
        if nodes[index].aabb.contains(aabb) {
            return false
        }
        
        removeLeaf(index)
        
        // Extend AABB
        
        var b = fatten(aabb)
        
        // Predict AABB displacement
        //let d = d.multiply(displacementFactor)
        
        let dX = d.x * displacementFactor
        let dY = d.y * displacementFactor
        
        let d = CGPoint(x: dX, y: dY)
        
        if d.x < 0 {
            b.origin.x += d.x
            b.size.width -= d.x
        }
        else {
            b.size.width += d.x
        }
        if d.y < 0 {
            b.origin.y += d.y
            b.size.height -= d.y
        }
        else {
            b.size.height += d.y
        }
        
        nodes[index].aabb = b
        
        
        insertLeaf(index)
        
        return true
    }
    
    public func query(aabb: CGRect, callback:(T, CGRect)->Bool) {
        var stack = Stack<Int>()
        stack.push(root)
        while stack.items.count > 0 {
            let index = stack.pop()
            if index == -1 { continue }
            let node = nodes[index!]
            if node.aabb.intersects(aabb) {
                if node.isLeaf {
                    let stop = callback(node.item!, node.originalAABB)
                    if stop { return }
                }
                else {
                    stack.push(node.child1)
                    stack.push(node.child2)
                }
            }
        }
    }
    
    // NCTVGS
    public func queryToGetArray(aabb: CGRect)->[T] {
        var arrayToReturn : [T] = []
        var stack = Stack<Int>()
        stack.push(root)
        while stack.items.count > 0 {
            let index = stack.pop()
            if index == -1 { continue }
            let node = nodes[index!]
            if node.aabb.intersects(aabb) {
                if node.isLeaf {
                    
                    if let nodeItem = node.item
                    {
                        arrayToReturn.append(nodeItem)
                    }
                    
                    //let stop = callback(node.item!, node.originalAABB)
                    //if stop { return [] }
                }
                else {
                    stack.push(node.child1)
                    stack.push(node.child2)
                }
            }
        }
    
      return arrayToReturn
    }
    
    private mutating func allocateNode() -> Int {
        
        if freeList == -1 {
            
            let count = nodes.count
            nodes = nodes + [DynamicTreeNode<T>].init(repeating: DynamicTreeNode<T>(), count: count)
            for i in count..<nodes.count-1 {
                nodes[i].next = i+1
                nodes[i].height = -1
            }
            nodes[nodes.count-1].next = -1
            nodes[nodes.count-1].height = -1
            freeList = count
        }
        
        let index = freeList
        freeList = nodes[index].next
        nodes[index].parent = -1
        nodes[index].child1 = -1
        nodes[index].child2 = -1
        nodes[index].height = 0
        nodes[index].item = nil
        
        
        return index
    }
    
    private mutating func freeNode(_ index: Int) {
        assert(0 <= index && index < nodes.count)
        nodes[index].next = freeList
        nodes[index].height = -1
        nodes[index].item = nil
        
        // NCTVGS
        //print("nodes.count: \(nodes.count), freeList: \(freeList)")
        
        freeList = index
    
    }
    
    @inline(__always) mutating private func setChild1(of parent: Int, to child: Int) {
        nodes[parent].child1 = child
        nodes[child].parent = parent
    }
    
    @inline(__always) mutating private func setChild2(of parent: Int, to child: Int) {
        nodes[parent].child2 = child
        nodes[child].parent = parent
    }
    
    private mutating func insertLeaf(_ leaf: Int) {
        
        insertionCount += 1
        
        if root == -1 {
            root = leaf
            nodes[root].parent = -1
            return
        }
        
        // find the best sibling for this node
        let leafAABB = nodes[leaf].aabb
        var index = root
        while nodes[index].isLeaf == false {
            
            let child1 = nodes[index].child1
            let child2 = nodes[index].child2
            
            let area = nodes[index].aabb.perimeter
            
            let combinedAABB = nodes[index].aabb.union(leafAABB)
            let combinedArea = combinedAABB.perimeter
            
            let cost = 2 * combinedArea
            let inheritanceCost = 2 * (combinedArea - area)
            
            @inline(__always) func computeCost(of child: Int) -> CGFloat {
                if nodes[child].isLeaf {
                    let aabb = leafAABB.union(nodes[child].aabb)
                    return aabb.perimeter + inheritanceCost
                }
                let oldArea = nodes[child].aabb.perimeter
                let newArea = leafAABB.union(nodes[child].aabb).perimeter
                return newArea - oldArea + inheritanceCost
            }
            
            let cost1 = computeCost(of: child1)
            let cost2 = computeCost(of: child2)
            
            if cost < cost1 && cost < cost2 {
                break
            }
            
            if cost1 < cost2 {
                index = child1
            }
            else {
                index = child2
            }
            
        }
        
        let sibling = index
        
        let oldParent = nodes[sibling].parent
        let newParent = allocateNode()
        nodes[newParent].parent = oldParent
        nodes[newParent].item = nil
        nodes[newParent].aabb = leafAABB.union(nodes[sibling].aabb)
        nodes[newParent].height = nodes[sibling].height + 1
        
        if oldParent != -1 {
            
            // sibling is NOT the root
            
            if nodes[oldParent].child1 == sibling {
                nodes[oldParent].child1 = newParent
            }
            else {
                nodes[oldParent].child2 = newParent
            }
            
            setChild1(of: newParent, to: sibling)
            setChild2(of: newParent, to: leaf)
        }
        else {
            
            // sibling was the root
            
            setChild1(of: newParent, to: sibling)
            setChild2(of: newParent, to: leaf)
            
            root = newParent
        }
        
        // walk back up fixing heights and aabbs
        index = nodes[leaf].parent
        while index != -1 {
            index = balance(index)
            
            let child1 = nodes[index].child1
            let child2 = nodes[index].child2
            
            assert(child1 != -1, "found empty child")
            assert(child2 != -1, "found empty child")
            
            nodes[index].height = 1 + max(nodes[child1].height, nodes[child2].height)
            nodes[index].aabb = nodes[child1].aabb.union(nodes[child2].aabb)
            
            index = nodes[index].parent
        }
        
    }
    
    private mutating func removeLeaf(_ leaf: Int) {
        
        if leaf == root {
            root = -1
            return
        }
        
        let parent = nodes[leaf].parent
     
        // NCT
        guard parent > -1 else {
            //print("parent index less than zero")
            fatalError("parent index less than zero")
        }
        
        let grandParent = nodes[parent].parent
        
        // get sibling of leaf
        let sibling: Int
        if nodes[parent].child1 == leaf {
            sibling = nodes[parent].child2
        }
        else {
            sibling = nodes[parent].child1
        }
        
        if grandParent != -1 {
            // Destroy parent and connect sibling to grandParent.
            if nodes[grandParent].child1 == parent {
                nodes[grandParent].child1 = sibling
            }
            else {
                nodes[grandParent].child2 = sibling
            }
            nodes[sibling].parent = grandParent
            freeNode(parent)
            
            // Adjust ancestor bounds.
            var index = grandParent
            while index != -1 {
                index = balance(index)
                let child1 = nodes[index].child1
                let child2 = nodes[index].child2
                
                nodes[index].aabb = nodes[child1].aabb.union(nodes[child2].aabb)
                nodes[index].height = 1 + max(nodes[child1].height, nodes[child2].height)
                
                index = nodes[index].parent
            }
        }
        else {
            root = sibling
            nodes[sibling].parent = -1
            freeNode(parent)
        }
    }
    
    
    // Perform a left or right rotation if node A is imbalanced.
    // Returns the new root index.
    private mutating func balance(_ a: Int) -> Int {
        
        assert(a != -1)
        
        if nodes[a].isLeaf || nodes[a].height < 2 { return a }
        
        let b = nodes[a].child1
        let c = nodes[a].child2
        
        assert(0 <= b && b < nodes.count-1)
        assert(0 <= c && c < nodes.count-1)
        
        let balance = nodes[c].height - nodes[b].height
        
        // rotate c up
        if balance > 1 {
            let f = nodes[c].child1
            let g = nodes[c].child2
            
            assert(0 <= f && f < nodes.count-1)
            assert(0 <= g && g < nodes.count-1)
            
            // swap a and c
            nodes[c].child1 = a
            nodes[c].parent = nodes[a].parent
            nodes[a].parent = c
            
            // a's old parent should point to c
            let cParent = nodes[c].parent
            if cParent != -1 {
                if nodes[cParent].child1 == a {
                    nodes[cParent].child1 = c
                }
                else {
                    assert(nodes[cParent].child2 == a, "cParent does not have either 'a' has child")
                    nodes[cParent].child2 = c
                }
            }
            else {
                root = c
            }
            
            // rotate
            if nodes[f].height > nodes[g].height {
                nodes[c].child2 = f
                nodes[a].child2 = g
                nodes[g].parent = a
                
                nodes[a].aabb = nodes[b].aabb.union(nodes[g].aabb)
                nodes[c].aabb = nodes[a].aabb.union(nodes[f].aabb)
                
                nodes[a].height = 1 + max(nodes[b].height, nodes[g].height)
                nodes[c].height = 1 + max(nodes[a].height, nodes[f].height)
            }
            else {
                nodes[c].child2 = g
                nodes[a].child2 = f
                nodes[f].parent = a
                
                nodes[a].aabb = nodes[b].aabb.union(nodes[f].aabb)
                nodes[c].aabb = nodes[a].aabb.union(nodes[g].aabb)
                
                nodes[a].height = 1 + max(nodes[b].height, nodes[f].height)
                nodes[c].height = 1 + max(nodes[a].height, nodes[g].height)
            }
            return c
        }
        
        // rotate b up
        if balance < -1 {
            
            let d = nodes[b].child1
            let e = nodes[b].child2
            
            assert(0 <= d && d < nodes.count-1)
            assert(0 <= e && e < nodes.count-1)
            
            // swap a and b
            nodes[b].child1 = a
            nodes[b].parent = nodes[a].parent
            nodes[a].parent = b
            
            // a's old parent should point to b
            let bParent = nodes[b].parent
            if bParent != -1 {
                if nodes[bParent].child1 == a {
                    nodes[bParent].child1 = b
                }
                else {
                    assert(nodes[bParent].child2 == a, "b parent does not have a as child")
                    nodes[bParent].child2 = b
                }
            }
            else {
                root = b
            }
            
            // rotate
            if nodes[d].height > nodes[e].height {
                nodes[b].child2 = d
                nodes[a].child1 = e
                nodes[e].parent = a
                
                nodes[a].aabb = nodes[c].aabb.union(nodes[e].aabb)
                nodes[b].aabb = nodes[a].aabb.union(nodes[d].aabb)
                
                nodes[a].height = 1 + max(nodes[c].height, nodes[e].height)
                nodes[b].height = 1 + max(nodes[a].height, nodes[d].height)
            }
            else {
                nodes[b].child2 = e
                nodes[a].child1 = d
                nodes[d].parent = a
                
                nodes[a].aabb = nodes[c].aabb.union(nodes[d].aabb)
                nodes[b].aabb = nodes[a].aabb.union(nodes[e].aabb)
                
                nodes[a].height = 1 + max(nodes[c].height, nodes[d].height)
                nodes[b].height = 1 + max(nodes[a].height, nodes[e].height)
            }
            
            return b
            
        }
        
        return a
    }
    
    
}

//// MARK: --- -
#if DEBUG
public extension DynamicTree {
    
    func validateStructure(_ index: Int) {
        if index == -1 { return }
        
        if index == root {
            assert(nodes[index].parent == -1)
        }
        
        let child1 = nodes[index].child1
        let child2 = nodes[index].child2
        
        if nodes[index].isLeaf {
            assert(child1 == -1)
            assert(child2 == -1)
            assert(nodes[index].height == 0)
            return
        }
        
        assert(0 <= child1 && child1 < nodes.count)
        assert(0 <= child2 && child2 < nodes.count)
        
        assert(nodes[child1].parent == index)
        assert(nodes[child2].parent == index)
        
        validateStructure(child1)
        validateStructure(child2)
        
    }
    
    func validateMetrics(_ index: Int) {
        
        if index == -1 { return }
        
        let child1 = nodes[index].child1
        let child2 = nodes[index].child2
        
        if nodes[index].isLeaf {
            assert(child1 == -1)
            assert(child2 == -1)
            assert(nodes[index].height == 0)
            return
        }
        
        assert(0 <= child1 && child1 < nodes.count)
        assert(0 <= child2 && child2 < nodes.count)
        
        let h1 = nodes[child1].height
        let h2 = nodes[child2].height
        let height = 1 + max(h1, h2)
        
        assert(nodes[index].height == height, "node metrics height not valid")
        
        let aabb = nodes[child1].aabb.union(nodes[child2].aabb)
        assert(nodes[index].aabb == aabb, "node metrics aabb not combined")
        
        validateMetrics(child1)
        validateMetrics(child2)
        
    }
    
    func validate() -> Bool {
        
        if root == -1 {
            return true
        }
        
        validateStructure(root)
        print("structure valid")
        validateMetrics(root)
        print("metrics valid")
        
        var freeCount = 0
        var freeIndex = freeList
        while freeIndex != -1 {
            assert(0 <= freeIndex && freeIndex < nodes.count)
            freeIndex = nodes[freeIndex].next
            freeCount += 1
        }
        
        assert(freeCount < nodes.count, "more free nodes")
        printFreeList()
        
        let height = getHeight()
        let computedHeight = computeHeight()
        assert(height == computedHeight, "heights not in sync")
        print("height valid")
        
        return true
    }
    
    
    func getHeight() -> Int {
        if root == -1 { return 0 }
        return nodes[root].height
    }
    
    func computeHeight() -> Int {
        return computeHeight(root)
    }
    
    func computeHeight(_ index: Int) -> Int {
        assert(0 <= index && index < nodes.count)
        if nodes[index].isLeaf { return 0 }
        return 1 + max(computeHeight(nodes[index].child1), computeHeight(nodes[index].child2))
    }
    
    func dump() {
        if root == -1 {
            print("empty tree")
            return
        }
        var n = Stack<(Int,Int)>()
        n.push((0,root))
        while n.items.count > 0 {
            let (level, i) = n.pop()!
            let indent = String.init(repeating: "..", count: level)
            let t = nodes[i].item == nil ? "contains" : "\(nodes[i].item!)"
            print("\(indent) [node \(i)]=\(t)") // parent:\(nodes[i].parent) leaf:\(nodes[i].isLeaf)")
            if !nodes[i].isLeaf {
                n.push((level+1, nodes[i].child1))
                n.push((level+1, nodes[i].child2))
            }
        }
    }
    
    
    /*
    @available(iOS 10.0, *)
    func dumpImage() -> CGImage {
        
        if root == -1 {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height:200))
            return renderer.image { ctx in
                ctx.cgContext.setFillColor(UIColor.red.cgColor)
                ctx.cgContext.fill(CGRect(x:0, y:95, width: 200, height: 10))
                ctx.cgContext.fill(CGRect(x:95, y:9, width: 10, height: 200))
            }
        }
        let rootBounds = nodes[root].aabb
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: rootBounds.maxX, height:rootBounds.maxY))
        let image = renderer.image { ctx in
            
            ctx.cgContext.setShouldAntialias(false)
            // ctx.cgContext.scaleBy(x: 4, y: 4)
            // ctx.cgContext.setLineWidth(0.5)
            
            if root != -1 {
                var n = Stack<Int>()
                n.push(root)
                while n.items.count > 0 {
                    let i = n.pop()
                    if nodes[i].isLeaf {
                        let fattened = nodes[i].aabb
                        let actual = nodes[i].originalAABB
                        ctx.cgContext.setFillColor(UIColor.cyan.withAlphaComponent(0.5).cgColor)
                        ctx.cgContext.fill(actual)
                        ctx.cgContext.setStrokeColor(UIColor.red.cgColor)
                        ctx.cgContext.stroke(fattened)
                    }
                    else {
                        // ctx.cgContext.setStrokeColor(UIColor.yellow.cgColor)
                        // ctx.cgContext.stroke(nodes[i].aabb)
                        n.push(nodes[i].child1)
                        n.push(nodes[i].child2)
                    }
                }
            }
            // ctx.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.5).cgColor)
            // ctx.cgContext.fill(target)
        }
        return image
    }
    */
    
    func treeDump(boundsRect:NSRect, ctx:NSGraphicsContext) {
        
        if root == -1 {
           
          //  ctx.cgContext.setFillColor(NSColor.cyan.withAlphaComponent(0.5).cgColor)
           // ctx.cgContext.fill(boundsRect)
        }
        else
        {
            ctx.cgContext.saveGState()
            ctx.cgContext.setShouldAntialias(false)
            // ctx.cgContext.scaleBy(x: 4, y: 4)
            // ctx.cgContext.setLineWidth(0.5)
            
            if root != -1 {
                var n = Stack<Int>()
                n.push(root)
                while n.items.count > 0 {
                    let i = n.pop()!
                    if nodes[i].isLeaf {
                        let fattened = nodes[i].aabb
                        let actual = nodes[i].originalAABB
                        ctx.cgContext.setFillColor(NSColor.cyan.withAlphaComponent(0.5).cgColor)
                        ctx.cgContext.fill(actual)
                        ctx.cgContext.setStrokeColor(NSColor.red.cgColor)
                        ctx.cgContext.stroke(fattened)
                        
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = .left
                        
                        let attrs = [NSAttributedString.Key.font: NSFont(name: "Menlo-Regular", size: 10)!, NSAttributedString.Key.paragraphStyle: paragraphStyle, NSAttributedString.Key.strokeColor : NSColor.white, NSAttributedString.Key.backgroundColor : NSColor.green.withAlphaComponent(0.4)]
                        if let itemx = nodes[i].item as? FMDrawable
                        {
                            let nodeText = "node: \(i) dI: \(itemx.drawingOrderIndex)"
                            let rect = NSRect(origin: actual.origin, size: CGSize(width: 230, height: 14))
                            nodeText.draw(with:rect, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
                        }
                        
                    }
                    else {
                        // ctx.cgContext.setStrokeColor(UIColor.yellow.cgColor)
                        // ctx.cgContext.stroke(nodes[i].aabb)
                        n.push(nodes[i].child1)
                        n.push(nodes[i].child2)
                    }
                }
            }
            ctx.cgContext.restoreGState()
        }
    
            // ctx.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.5).cgColor)
            // ctx.cgContext.fill(target)
     
        
        
    }
    
    
    func printFreeList() {
        var n = [Int]()
        var i = freeList
        if i == -1 {
            print("freelist: nothing is free")
            return
        }
        while i != -1 {
            n.append(i)
            i = nodes[i].next
        }
        print("freelist: \( n.map { "\($0)" }.joined(separator: " -> ") )")
    }
}
#endif


/*
 
 Last-in first-out stack (LIFO)
 Push and pop are O(1) operations.
 */
public struct Stack<T> {
    public var items = [T]()
    
    public var isEmpty: Bool {
        return items.isEmpty
    }
    
    public var count: Int {
        return items.count
    }
    
    public mutating func push(_ element: T) {
        items.append(element)
    }
    
    public mutating func pop() -> T? {
        return items.popLast()
    }
    
    public var top: T? {
        return items.last
    }
    
}

extension Stack: Sequence {
    public func makeIterator() -> AnyIterator<T> {
        var curr = self
        return AnyIterator {
            return curr.pop()
        }
    }
}
