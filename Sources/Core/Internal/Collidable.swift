import Foundation

/// Protocol adopted by objects that can collide with other objects
internal protocol Collidable {
    func shapeForCollisionDetection() -> Shape
}
