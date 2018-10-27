import Foundation
import QuartzCore


public final class TileMap: Node<CALayer>, ZIndexed, Activatable, Movable {
    /// The index of the tile map on the z axis. 0 = implicit index.
    public var zIndex = 0 { didSet { layer.zPosition = Metric(zIndex) } }
    /// The position (center-point) of the tile map within its scene.
    public var position = Point() { didSet { positionDidChange() } }

    private let spriteSheet: SpriteSheet
    private let map: Map
    private let textureScale: Int?

    // MARK: - Initializer
    public init(spriteSheet: SpriteSheet, map: Map, textureScale: Int? = nil) {
        self.spriteSheet = spriteSheet
        self.map = map
        self.textureScale = textureScale

        super.init(layer: Layer())
    }

    // MARK: - Activatable

    internal func activate(in game: Game) {
        addSublayers(using: game.scene.textureManager)
    }

    internal func deactivate() {
    }

    // MARK: - Private

    private func addSublayers(using textureManager: TextureManager) {
        for (tileIndex, tileCoordinate) in map.tiles.enumerated() {
            guard let tileCoordinate = tileCoordinate else { continue }

            let frame = spriteSheet.frame(at: tileCoordinate)

            guard let loadedTexture = textureManager.load(frame.texture, namePrefix: nil, scale: textureScale) else {
                continue
            }

            let y = tileIndex / map.width
            let x = tileIndex - y * map.width
            let tileLayer = CALayer()

            tileLayer.contents = loadedTexture.image
            tileLayer.contentsRect = frame.contentRect
            tileLayer.anchorPoint = Point(x: 0, y: 0)
            tileLayer.bounds.size.width = loadedTexture.size.width * frame.contentRect.width
            tileLayer.bounds.size.height = loadedTexture.size.height * frame.contentRect.height
            tileLayer.position.x = Metric(x) * tileLayer.bounds.size.width

            #if os(macOS)
            let mapHeight = tileLayer.bounds.size.height * Metric(map.height)
            tileLayer.position.y = mapHeight - Metric(y) * (tileLayer.bounds.size.height - 1)
            #else
            tileLayer.position.y = Metric(y) * tileLayer.bounds.size.height
            #endif

            layer.addSublayer(tileLayer)
        }

        if let tileLayer = layer.sublayers?.first {
            let tileLayerSize = tileLayer.bounds.size
            layer.bounds.size.width = Metric(map.width) * tileLayerSize.width
            layer.bounds.size.height = Metric(map.height) * tileLayerSize.height
        }
    }

    private func positionDidChange() {
        layer.position = position
    }
}

public extension TileMap {
    struct Map {
        /// The width of the map expressed as the number of sprites.
        public var width: Int
        /// The height of the map expressed as the number of sprites.
        public var height: Int
        /// The coordinate in the sprite sheet to use to get the sprite for each tile in the map.
        /// The map is filled starting in the top left corner.
        public var tiles: [Coordinate?]

        public init(width: Int, height: Int, tiles: [Coordinate?] = []) {
            self.width = width
            self.height = height
            self.tiles = tiles
        }
    }
}
