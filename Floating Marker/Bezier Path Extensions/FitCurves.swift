// FitCurves.swift - Calculate and generate a path that run through all the input points
//
// Created by Yusuke Onishi on 5/9/18.
// Copyright © 2018 LINE Corp. All rights reserved.
//
// -----------------------------------------------------------------------------
///
/// An Algorithm for Automatically Fitting Digitized Curves
/// by Philip J. Schneider
/// from "Graphics Gems", Academic Press, 1990
///
/// Swift port of `simplify` function in Paper.js
/// The Paper.js's implementation can be found here:
/// https://github.com/paperjs/paper.js/blob/master/src/path/PathFitter.js
///
/// The original implementation in C can be found here:
/// https://github.com/erich666/GraphicsGems/blob/master/gems/FitCurves.c
///
// -----------------------------------------------------------------------------

import CoreGraphics
import simd

/// Create a new `CGPath` that pass through all `points` with as fewer curves as possible.
///
/// - Parameters:
///   - points: An array of `CGPoint` that the path should be "fit" into.
///   - tolerance: The allowed maximum error when fitting the curves through the segment points. Default to 2.5
public extension CGPath {
    static func path(thatFits points: [CGPoint], tolerance: CGFloat = 1) -> CGPath {
        if points.count <= 2 {
            let path = CGMutablePath()
            if let point = points.first {
                path.move(to: point)
            }
            if let point = points.dropFirst().first {
                path.addLine(to: point)
            }
            return path
        }
        
        let vectors = points.map { simd_double2(x: Double($0.x), y: Double($0.y)) }
        let curves = _fitCurves(vectors[...], error: Double(tolerance))

        let path = CGMutablePath()
        path.move(to: .zero)
        for curve in curves {
            let points = curve.map { CGPoint(x: $0.x, y: $0.y) }
            if path.currentPoint != points[0] {
                path.move(to: points[0])
            }
            path.addCurve(to: points[3], control1: points[1], control2: points[2])
        }
        return path
    }
}

private func _fitCurves(_ points: ArraySlice<simd_double2>, error: Double) -> [[simd_double2]] {
    guard points.count > 1 else {
        return []
    }
    let tan1 = points[points.startIndex + 1] - points[points.startIndex]
    let tan2 = points[points.endIndex - 2] - points[points.endIndex - 1]
    return _fitCubic(points[0...], tan1, tan2, error)
}

private func _fitCubic(_ points: ArraySlice<simd_double2>, _ tan1: simd_double2, _ tan2: simd_double2, _ error: Double) -> [[simd_double2]] {
    let ntan1 = simd_length(tan1) > 0 ? simd_normalize(tan1) : tan1
    let ntan2 = simd_length(tan2) > 0 ? simd_normalize(tan2) : tan2

    // Use heuristic if region only has two points in it
    if points.count == 2, let pt1 = points.first, let pt2 = points.last {
        let dist = simd_distance(pt1, pt2) / 3
        return [[
            pt1,
            pt1 + (dist * ntan1),
            pt2 + (dist * ntan2),
            pt2
        ]]
    }

    /*  Parameterize points, and attempt to fit curve */
    var uPrime = _chordLengthParameterize(points)
    var maxError = max(error, error * error)
    var parametersInOrder = true
    var split = 0
    // Try 4 interations
    for _ in 0..<4 {
        let curve = _generateBezier(points, uPrime, tan1, tan2)
        //  Find max deviation of points to fitted curve
        let max = _findMaxError(points, curve, uPrime)
        if max.error < error && parametersInOrder {
            return [curve]
        }
        split = max.index
        // If error not too large, try reparameterization and iteration
        if max.error >= maxError {
            break
        }
        (uPrime, parametersInOrder) = _reparameterize(points, uPrime, curve)
        maxError = max.error
    }

    let tanCenter = points[split - 1] - points[split + 1]
    return _fitCubic(points[...split], tan1, tanCenter, error) + _fitCubic(points[split...], -tanCenter, tan2, error)
}

// Use least-squares method to find Bezier control points for region.
private func _generateBezier(_ points: ArraySlice<simd_double2>, _ uPrime: [Double], _ tan1: simd_double2, _ tan2: simd_double2) -> [simd_double2] {
    guard let pt1 : SIMD2<Double> = points.first, let pt2 : SIMD2<Double> = points.last else {
        fatalError()
    }

    var x = simd_double2(repeating: 0)
    var c = simd_double2x2(0)

    let ntan1 = simd_length(tan1) > 0 ? simd_normalize(tan1) : tan1
    let ntan2 = simd_length(tan2) > 0 ? simd_normalize(tan2) : tan2

    for (p, u) in zip(points, uPrime) {
        let t = 1 - u
        // Cubic curve's binomial polynomial
        // t^3 + 3t^2u + 3tu^2 + u^3
        let b0 = t * t * t // t^3
        let b1 = 3 * t * t * u // 3t^2u
        let b2 = 3 * t * u * u // 3tu^2
        let b3 = u * u * u // u^3
        let tmp1 = p - (pt1 * (b0 + b1))
        let tmp2 = (pt2 * (b2 + b3))
        let tmp =  tmp1 - tmp2
        let a = simd_double2x2([ntan1 * b1, ntan2 * b2])
        c += simd_mul(a.transpose, a)
        x += simd_mul(tmp, a)
    }

    // Compute the determinants of C and X
    let detC = c.determinant
    var alpha1, alpha2: Double
    if abs(detC) > .ulpOfOne {
        // Kramer's rule
        let detC0X = simd_double2x2([c.columns.0, x]).determinant
        let detXC1 = simd_double2x2([x, c.columns.1]).determinant
        // Derive alpha values
        alpha1 = detXC1 / detC
        alpha2 = detC0X / detC
    } else {
        // Matrix is under-determined, try assuming alpha1 == alpha2
        let c0 = c.columns.0.x + c.columns.1.x
        let c1 = c.columns.0.y + c.columns.1.y
        alpha1 = abs(c0) > .ulpOfOne ? x.x / c0 : abs(c1) > .ulpOfOne ? x.y / c1 : 0
        alpha2 = alpha1
    }

    // If alpha negative, use the Wu/Barsky heuristic (see text)
    // (if alpha is 0, you get coincident control points that lead to
    // divide by zero in any subsequent NewtonRaphsonRootFind() call.
    let segLength = simd_distance(pt1, pt2)
    let eps = segLength * .ulpOfOne

    // Check if the found control points are in the right order when
    // projected onto the line through pt1 and pt2.
    let line = pt2 - pt1

    // Control points 1 and 2 are positioned an alpha distance out
    // on the tangent vectors, left and right, respectively
    let handle1 = ntan1 * alpha1
    let handle2 = ntan2 * alpha2

    if alpha1 < eps || alpha2 < eps || simd_dot(handle1, line) - simd_dot(handle2, line) > segLength * segLength {
        // fall back on standard (probably inaccurate) formula,
        // and subdivide further if needed.
        alpha1 = segLength / 3
        alpha2 = alpha1
    }

    // First and last control points of the Bezier curve are
    // positioned exactly at the first and last data points
    return [
        pt1,
        pt1 + ntan1 * alpha1,
        pt2 + ntan2 * alpha2,
        pt2
    ]
}

// Given set of points and their parameterization, try to find
// a better parameterization.
private func _reparameterize(_ points: ArraySlice<simd_double2>, _ u: [Double], _ curve: [simd_double2]) -> ([Double], Bool) {
    let uPrime = zip(points, u).map { _findRoot(curve, $0, $1) }
    // Detect if the new parameterization has reordered the points.
    // In that case, we would fit the points of the path in the wrong order.
    return (uPrime, !zip(uPrime, uPrime.dropFirst()).contains { $0 >= $1 })
}

private func _findRoot(_ curve: [simd_double2], _ point: simd_double2, _ u: Double) -> Double {
    let curve1 = zip(curve.dropFirst(), curve).map { ($0 - $1) * 3 }
    let curve2 = zip(curve1.dropFirst(), curve1).map { ($0 - $1) * 3 }
    let pt = _evaluate(curve, u)
    let pt1 = _evaluate(curve1, u)
    let pt2 = _evaluate(curve2, u)
    let diff = pt - point
    let df = simd_dot(pt1, pt1) + simd_dot(diff, pt2)
    return df == 0 ? u : u - simd_dot(diff, pt1) / df
}

// Evaluate a bezier curve at a particular parameter value
private func _evaluate(_ curve: [simd_double2], _ t: Double) -> simd_double2 {
    let degree = curve.count - 1
    var tmp = Array(curve)
    for i in 1...degree {
        for j in 0...degree - i {
            tmp[j] = (tmp[j] * (1 - t)) + (tmp[j + 1] * t)
        }
    }
    return tmp[0]
}

// Assign parameter values to digitized points
// using relative distances between points.
private func _chordLengthParameterize(_ points: ArraySlice<simd_double2>) -> [Double] {
    var cumulativeDistance = 0.0
    var u = [cumulativeDistance]
    for (p1, p2) in zip(points, points.dropFirst()) {
        cumulativeDistance += simd_distance(p1, p2)
        u.append(cumulativeDistance)
    }
    return u.map({ $0 / cumulativeDistance })
}

// Find the maximum squared distance of digitized points to fitted curve.
private func _findMaxError(_ points: ArraySlice<simd_double2>, _ curve: [simd_double2], _ u: [Double]) -> (error: Double, index: Int) {
    var index = (points.endIndex - points.startIndex) / 2
    var maxDist = 0.0

    for i in points.startIndex + 1..<points.endIndex - 1 {
        let p = _evaluate(curve, u[i - points.startIndex])
        let v = p - points[i]
        let dist = simd_length_squared(v)
        if dist >= maxDist {
            maxDist = dist
            index = i
        }
    }
    return (maxDist, index)
}
