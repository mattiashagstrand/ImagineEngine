/**
 *  Imagine Engine
 *  Copyright (c) John Sundell 2017
 *  See LICENSE file for license
 */

import Foundation
import CoreGraphics

public final class Shape {
    private static let halfPi = Metric.pi * 0.5

    /// Smallest rectangle that contains the whole shape.
    public private(set) lazy var boundingBox: Rect = type.calculateBoundingBox()

    private let type: ShapeType

    public convenience init(circleAt center: Point, withRadius radius: Metric) {
        self.init(type: .circle(center: center, radius: radius))
    }

    public convenience init(rectangleAtX x: Metric, y: Metric, width: Metric, height: Metric) {
        let upperLeft = Point(x: x, y: y)
        let upperRight = Point(x: x + width, y: y)
        let lowerRight = Point(x: x + width, y: y + height)
        let lowerLeft = Point(x: x, y: y + height)

        self.init(type: .path(vertices: [upperLeft, upperRight, lowerRight, lowerLeft],
                              isRectangular: true,
                              rotation: 0))
    }

    public convenience init(rectangle: Rect) {
        let upperLeft = Point(x: rectangle.minX, y: rectangle.minY)
        let upperRight = Point(x: rectangle.maxX, y: rectangle.minY)
        let lowerRight = Point(x: rectangle.maxX, y: rectangle.maxY)
        let lowerLeft = Point(x: rectangle.minX, y: rectangle.maxY)

        self.init(type: .path(vertices: [upperLeft, upperRight, lowerRight, lowerLeft],
                              isRectangular: true,
                              rotation: 0))
    }

    /// Creates a polygon with the specified vertices specified in clockwise order.
    /// NOTE: The polygon must be convex.
    public convenience init(vertices: [Point]) {
        self.init(type: .path(vertices: vertices, isRectangular: false, rotation: 0))
    }

    private init(type: ShapeType) {
        self.type = type
    }

    public func asPath() -> Path {
        switch type {
        case .circle:
            return Path(ellipseIn: boundingBox, transform: nil)

        case let .path(vertices, _, _):
            let path = MutablePath()
            guard vertices.count >= 2 else {
                return path
            }

            path.move(to: vertices[0])
            for vertex in vertices.dropFirst() {
                path.addLine(to: vertex)
            }
            path.closeSubpath()

            return path
        }
    }

    public func rotated(by rotation: Metric) -> Shape {
        return Shape(type: type.rotated(by: rotation))
    }

    public func moved(byX x: Metric, y: Metric) -> Shape {
        return Shape(type: type.translated(byX: x, y: y))
    }

    public func intersects(_ otherShape: Shape) -> Bool {
        switch (self.type, otherShape.type) {
        case let (.path(_, true, rotation), .path(_, true, otherRotation)):
            // Optimize for the special case when testing to axis aligned rectangles
            if isAxisAligned(with: rotation) && isAxisAligned(with: otherRotation) {
                return boundingBox.intersects(otherShape.boundingBox)
            }

        default:
            break
        }

        return type.intersects(otherShape.type)
    }

    private func isAxisAligned(with rotation: Metric) -> Bool {
        // 0.01 means a 1 point error for a rectangle side of length 100 points
        // This is a reasonable trade-off between performance and precision
        return abs(rotation.truncatingRemainder(dividingBy: Shape.halfPi)) < 0.01
    }
}

extension Shape: Equatable {
    public static func ==(lhs: Shape, rhs: Shape) -> Bool {
        return lhs.type == rhs.type
    }
}

private enum ShapeType {
    case circle(center: Point, radius: Metric)
    case path(vertices: [Point], isRectangular: Bool, rotation: Metric)

    fileprivate func calculateBoundingBox() -> Rect {
        switch self {
        case let .circle(center, radius):
            return Rect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

        case let .path(vertices, _, _):
            let xCoordinates = vertices.map { $0.x }
            let yCoordinates = vertices.map { $0.y }
            let minX = xCoordinates.min() ?? 0
            let maxX = xCoordinates.max() ?? 0
            let minY = yCoordinates.min() ?? 0
            let maxY = yCoordinates.max() ?? 0
            return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }

    /// Returns a new shape that is the reslut of rotating this shape around origin.
    fileprivate func rotated(by rotation: Metric) -> ShapeType {
        switch self {
        case .circle:
            return self

        case let .path(vertices, isRectangular, prevRotation):
            let rotatedVertices = vertices.map { self.rotate($0, by: rotation) }
            return .path(vertices: rotatedVertices, isRectangular: isRectangular, rotation: prevRotation + rotation)
        }
    }

    fileprivate func translated(byX x: Metric, y: Metric) -> ShapeType {
        switch self {
        case let .circle(center, radius):
            return .circle(center: Point(x: center.x + x, y: center.y + y), radius: radius)

        case let .path(vertices, isRectangular, rotation):
            let movedVertices = vertices.map { Point(x: $0.x + x, y: $0.y + y) }
            return .path(vertices: movedVertices, isRectangular: isRectangular, rotation: rotation)
        }
    }

    fileprivate func intersects(_ otherShapeType: ShapeType) -> Bool {
        switch (self, otherShapeType) {
        case let (.circle(center, radius), .circle(otherCenter, otherRadius)):
            return circlesIntersect(center: center, radius: radius, otherCenter: otherCenter, otherRadius: otherRadius)

        case let (.path(vertices, true, _), .circle(center, radius)):
            return rectangle(with: vertices, intersectsCircleAt: center, withRadius: radius)

        case let (.circle(center, radius), .path(vertices, true, _)):
            return rectangle(with: vertices, intersectsCircleAt: center, withRadius: radius)

        case let (.path(vertices, true, _), .path(otherVertices, true, _)):
            return rectangle(with: vertices, intersectsOtherRectangleWith: otherVertices)

        default:
            // TODO: handle non-rectangular polygons.
            return calculateBoundingBox().intersects(otherShapeType.calculateBoundingBox())
        }
    }

    // MARK: - Private

    private func rotate(_ point: Point, by rotation: Metric) -> Point {
        return Point(x: point.y * sin(rotation) - point.x * cos(rotation),
                     y: point.x * sin(rotation) + point.y * cos(rotation))
    }

    private func circlesIntersect(center: Point, radius: Metric, otherCenter: Point, otherRadius: Metric) -> Bool {
        let x = center.x - otherCenter.x
        let y = center.y - otherCenter.y
        let radiusSum = radius + otherRadius

        return x * x + y * y <= radiusSum * radiusSum
    }

    // TODO: Check if this method also works for non-rectangular polygons.
    private func rectangle(with vertices: [Point],
                           intersectsCircleAt circleCenter: Point,
                           withRadius radius: Metric) -> Bool {

        let radiusSquared = radius * radius

        // Use distance from circle center to edge to check if circle is intersecting edge.
        // See https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line for details.
        for edgeStartIndex in 0..<vertices.count {
            let edgeEndIndex = (edgeStartIndex < vertices.count - 1 ? edgeStartIndex + 1 : 0)
            let edgeStartToCircleCenter = Vector(dx: circleCenter.x - vertices[edgeStartIndex].x,
                                         dy: circleCenter.y - vertices[edgeStartIndex].y)

            // Check if circle is close enough to intersect vertex
            // Only check one of the vertices of the edge since each vertice is part of two edges
            if edgeStartToCircleCenter.lengthSquared() <= radiusSquared {
                return true
            }

            let edgeVector = Vector(dx: vertices[edgeEndIndex].x - vertices[edgeStartIndex].x,
                                     dy: vertices[edgeEndIndex].y - vertices[edgeStartIndex].y)
            let invertedEdgeVector = Vector(dx: vertices[edgeStartIndex].x - vertices[edgeEndIndex].x,
                                     dy: vertices[edgeStartIndex].y - vertices[edgeEndIndex].y)

            let edgeEndToCircleCenter = Vector(dx: circleCenter.x - vertices[edgeEndIndex].x,
                                               dy: circleCenter.y - vertices[edgeEndIndex].y)

            // Check that the circle center is between the edge vertices (when looking orthogonally towards the edge)
            guard edgeStartToCircleCenter.dotProduct(edgeVector) >= 0
                && edgeEndToCircleCenter.dotProduct(invertedEdgeVector) >= 0 else {
                continue
            }

            let edgeEndX: Metric = vertices[edgeEndIndex].x
            let edgeEndY: Metric = vertices[edgeEndIndex].y
            let edgeStartX: Metric = vertices[edgeStartIndex].x
            let edgeStartY: Metric = vertices[edgeStartIndex].y

            let temp1: Metric = (edgeEndY - edgeStartY) * circleCenter.x - (edgeEndX - edgeStartX) * circleCenter.y
            let temp2: Metric = temp1 + edgeEndX * edgeStartY - edgeEndY * edgeStartX
            let edgeLength = Vector(dx: edgeEndX - edgeStartX, dy: edgeEndY - edgeStartY).length()
            let circleCenterDistance: Metric = abs(temp2) / edgeLength

            if circleCenterDistance <= radius {
                return true
            }
        }

        // Check if circle center is inside all edges
        for vertexIndex in 0..<vertices.count {
            let nextVertexIndex = (vertexIndex < vertices.count - 1 ? vertexIndex + 1 : 0)
            let edgeNormal = Vector(dx: vertices[nextVertexIndex].x - vertices[vertexIndex].x,
                                    dy: vertices[nextVertexIndex].y - vertices[vertexIndex].y)
            let toCircleCenter = Vector(dx: circleCenter.x - vertices[nextVertexIndex].x,
                                        dy: circleCenter.y - vertices[nextVertexIndex].y)

            if toCircleCenter.dotProduct(edgeNormal) >= 0 {
                return false
            }
        }

        return true
    }

    private func rectangle(with vertices: [Point], intersectsOtherRectangleWith otherVertices: [Point]) -> Bool {
        // Uses The Separating Axis Theorem
        // Checks that all vertices of one polygon is in front of all edges of the other polygon

        if isAnyEdgeOfRectangle(for: vertices, inFrontOf: otherVertices) == true {
            return false
        }

        if isAnyEdgeOfRectangle(for: otherVertices, inFrontOf: vertices) == true {
            return false
        }

        return true
    }

    private func isAnyEdgeOfRectangle(for vertices: [Point], inFrontOf otherVertices: [Point]) -> Bool {
        precondition(vertices.count == 4, "Rectangles must have exactly 4 vertices")

        for edgeStartIndex in 0..<vertices.count {
            let prevVertexIndex = (edgeStartIndex > 0 ? edgeStartIndex - 1 : vertices.count - 1)

            let edgeNormal = Vector(dx: vertices[edgeStartIndex].x - vertices[prevVertexIndex].x,
                                    dy: vertices[edgeStartIndex].y - vertices[prevVertexIndex].y)

            var allOtherVerticesInFrontOfEdge = true
            for otherVertex in otherVertices {
                let toOtherVertexFromEdge = Vector(dx: otherVertex.x - vertices[edgeStartIndex].x,
                                                   dy: otherVertex.y - vertices[edgeStartIndex].y)

                if toOtherVertexFromEdge.dotProduct(edgeNormal) <= 0 {
                    allOtherVerticesInFrontOfEdge = false
                    break
                }
            }

            if allOtherVerticesInFrontOfEdge == true {
                return true
            }
        }

        return false
    }
}

extension ShapeType: Equatable {
    // Custom implementation of Equatable that considers two shapes to be equal
    // if they would look the same when drawn to the screen.
    static func ==(lhs: ShapeType, rhs: ShapeType) -> Bool {
        switch (lhs, rhs) {
        case let (.circle(center, radius), .circle(otherCenter, otherRadius)):
            return (center == otherCenter && radius == otherRadius)

        case let (.path(vertices, _, _), .path(otherVertices, _, _)):
            guard vertices.count == otherVertices.count else {
                return false
            }

            for index in 0..<vertices.count {
                if abs(vertices[index].x - otherVertices[index].x) > 0.00001 {
                    return false
                }
                if abs(vertices[index].y - otherVertices[index].y) > 0.00001 {
                    return false
                }
            }
            return true

        default:
            return false
        }
    }
}

private extension Vector {
    func lengthSquared() -> Metric {
        return dx * dx + dy * dy
    }

    func length() -> Metric {
        return sqrt(lengthSquared())
    }

    func dotProduct(_ vector: Vector) -> Metric {
        return dx * vector.dx + dy * vector.dy
    }
}
