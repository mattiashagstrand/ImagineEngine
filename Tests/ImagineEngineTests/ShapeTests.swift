/**
 *  Imagine Engine
 *  Copyright (c) John Sundell 2017
 *  See LICENSE file for license
 */

import Foundation
import XCTest
@testable import ImagineEngine

final class ShapeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCircleMovedBy() {
        let circle = Shape(circleAt: .zero, withRadius: 50)

        XCTAssertEqual(circle.moved(byX: 10, y: -20), Shape(circleAt: Point(x: 10, y: -20), withRadius: 50))
    }

    func testRectangleMovedBy() {
        let rectangle = Shape(rectangleAtX: 0, y: 0, width: 100, height: 50)

        XCTAssertEqual(rectangle.moved(byX: 10, y: -20), Shape(rectangleAtX: 10, y: -20, width: 100, height: 50))
    }

    func testCircleRotatedBy() {
        let circle = Shape(circleAt: .zero, withRadius: 50)

        XCTAssertEqual(circle.rotated(by: 3), circle)
    }

    func testRectangleRotatedBy() {
        let rectangle = Shape(rectangleAtX: -50, y: -25, width: 100, height: 50)

        let sinRotation = sin(Metric.pi * 0.5)
        let rotatedRectangle = Shape(vertices: [
            Point(x: sinRotation * -25, y: sinRotation * -50),
            Point(x: sinRotation * -25, y: sinRotation * 50),
            Point(x: sinRotation * 25, y: sinRotation * 50),
            Point(x: sinRotation * 25, y: sinRotation * -50)])

        XCTAssertEqual(rectangle.rotated(by: Metric.pi * 0.5), rotatedRectangle)
    }

    func testCircleCircleIntersection() {
        let circle = Shape(circleAt: .zero, withRadius: 50)
        let otherCircle = Shape(circleAt: Point(x: 150, y: 0), withRadius: 50)

        XCTAssertFalse(circle.intersects(otherCircle))

        // Circles touching
        XCTAssertTrue(circle.moved(byX: 50, y: 0).intersects(otherCircle))

        // Circles at the same position
        XCTAssertTrue(circle.moved(byX: 150, y: 0).intersects(otherCircle))

        // Circles overlap diagonally
        XCTAssertTrue(circle.moved(byX: 100, y: 50).intersects(otherCircle))
    }

    func testCircleRectangleIntersection() {
        let circle = Shape(circleAt: .zero, withRadius: 50)
        let rectangle = Shape(rectangleAtX: -50, y: -25, width: 100, height: 50)

        // Not overlapping on x axis
        XCTAssertFalse(rectangle.intersects(circle.moved(byX: 101, y: 20)))
        XCTAssertFalse(rectangle.intersects(circle.moved(byX: -101, y: 20)))

        // Not overlapping on y axis
        XCTAssertFalse(rectangle.intersects(circle.moved(byX: 20, y: 76)))
        XCTAssertFalse(rectangle.intersects(circle.moved(byX: 20, y: -76)))

        // Overlapping on x axis
        XCTAssertTrue(rectangle.intersects(circle.moved(byX: 99, y: 20)))
        XCTAssertTrue(rectangle.intersects(circle.moved(byX: -99, y: 20)))

        // Overlapping on y axis
        XCTAssertTrue(rectangle.intersects(circle.moved(byX: 20, y: 74)))
        XCTAssertTrue(rectangle.intersects(circle.moved(byX: 20, y: -74)))

        // Not overlapping, circle 45 degrees from corner
        XCTAssertFalse(rectangle.intersects(circle.moved(byX: 86, y: -61)))

        // Overlapping, circle 45 degrees from corner
        XCTAssertTrue(rectangle.intersects(circle.moved(byX: 85, y: -60)))

        // Small circle inside rectangle
        XCTAssertTrue(rectangle.intersects(Shape(circleAt: .zero, withRadius: 5)))

        // Small rectangle inside circle
        XCTAssertTrue(circle.intersects(Shape(rectangleAtX: -5, y: -3, width: 10, height: 6)))

        // Small circle intersects rectange edge
        XCTAssertTrue(rectangle.intersects(Shape(circleAt: Point(x: 52, y: 0), withRadius: 10)))
    }

    func testRectangleRectangleIntersection() {
        let rectangle = Shape(rectangleAtX: -50, y: -25, width: 100, height: 50)
        let otherRectangle = Shape(rectangleAtX: -50, y: -25, width: 100, height: 50)

        // Not overlapping on x axis
        XCTAssertFalse(rectangle.intersects(otherRectangle.moved(byX: 150, y: 0)))

        // Not overlapping on y axis
        XCTAssertFalse(rectangle.intersects(otherRectangle.moved(byX: 0, y: -60)))

        // Overlapping without rotation
        XCTAssertTrue(rectangle.intersects(otherRectangle.moved(byX: 90, y: 0)))

        // Overlapping without rotation, switch side along x axis
        XCTAssertTrue(rectangle.intersects(otherRectangle.moved(byX: -90, y: 0)))

        // Overlapping without rotation, same x, different y
        XCTAssertTrue(rectangle.intersects(otherRectangle.moved(byX: 0, y: 40)))

        // Not overlapping with rotation, other rectange to the right
        XCTAssertFalse(rectangle.intersects(otherRectangle.rotated(by: Metric.pi * 0.25).moved(byX: 105, y: 0)))

        // Overlapping with rotation of right rectangle
        XCTAssertTrue(rectangle.intersects(otherRectangle.rotated(by: Metric.pi * 0.25).moved(byX: 103, y: 0)))

        // Overlapping with rotation of left rectangle
        XCTAssertTrue(rectangle.rotated(by: Metric.pi * 0.25).intersects(otherRectangle.moved(byX: 103, y: 0)))

        // Overlapping with rotated rectangle below
        XCTAssertTrue(rectangle.intersects(otherRectangle.rotated(by: Metric.pi * 0.25).moved(byX: 0, y: 28)))
    }
}
