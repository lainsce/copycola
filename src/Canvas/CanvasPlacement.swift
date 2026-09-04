import CoreGraphics

/// Pure placement logic shared by the canvas and its unit tests.
nonisolated enum CanvasPlacement {
    /// Finds the collision-free origin nearest a requested point on the selected layout.
    ///
    /// Grid uses regular square modules. Bloom uses center-out radial slots and falls back to a
    /// safe grid position if a finite canvas cannot fit the next ring. The x-axis is finite while
    /// the y-axis continues downward as far as needed.
    static func nearestFreePosition(
        for pointSize: CGSize,
        nearX: Double,
        nearY: Double,
        canvasWidth: Double,
        occupiedRects: [CGRect],
        minimumY: Double? = nil,
        style: CanvasGridStyle = .grid
    ) -> CGPoint {
        if style == .bloom {
            return nearestBloomPosition(
                for: pointSize,
                nearX: nearX,
                nearY: nearY,
                canvasWidth: canvasWidth,
                occupiedRects: occupiedRects,
                minimumY: minimumY
            )
        }

        let xPitch = Double(style.columnPitch)
        let yPitch = Double(style.rowPitch)
        let margin = Double(CanvasMetrics.canvasMargin)
        let rowOrigin = rowOrigin(for: minimumY, margin: margin)
        let width = Double(pointSize.width)
        let height = Double(pointSize.height)
        let clearanceInset = Double(style.collisionInset)

        let availableWidth = canvasWidth - 2 * margin
        guard width <= availableWidth + 0.5 else {
            // Every built-in card fits, but keep the fallback safe for future card sizes.
            return CGPoint(x: margin, y: rowOrigin)
        }

        // The column range is calculated without the row phase. Bloom's shifted rows then
        // discard whichever edge column would cross the fixed canvas bounds.
        let lastColumn = Int(floor((availableWidth - width + 0.5) / xPitch))
        let columns = Array(0...max(0, lastColumn))

        let requestedColumn = Int(((nearX - margin) / xPitch).rounded())
        let baseColumn = min(max(requestedColumn, 0), max(0, lastColumn))
        let requestedRow = Int(((nearY - rowOrigin) / yPitch).rounded())
        let baseRow = max(requestedRow, 0)

        let searchLimit = max(64, occupiedRects.count * 8 + 8)
        if let position = searchNearest(
            baseRow: baseRow,
            searchLimit: searchLimit,
            columns: columns,
            baseColumn: baseColumn,
            nearX: nearX,
            rowOrigin: rowOrigin,
            yPitch: yPitch,
            margin: margin,
            xPitch: xPitch,
            width: width,
            height: height,
            availableWidth: availableWidth,
            occupiedRects: occupiedRects,
            clearanceInset: clearanceInset,
            style: style
        ) {
            return position
        }

        // Fall back to a row below all occupied content. Since y is intentionally unbounded,
        // this loop always finds a free slot for the finite board.
        let rowBelowContent = rowBelowContent(
            occupiedRects,
            rowOrigin: rowOrigin,
            yPitch: yPitch,
            clearanceInset: clearanceInset
        )
        return fallbackPosition(
            startingRow: max(baseRow, rowBelowContent),
            columns: columns,
            baseColumn: baseColumn,
            nearX: nearX,
            rowOrigin: rowOrigin,
            yPitch: yPitch,
            margin: margin,
            xPitch: xPitch,
            width: width,
            height: height,
            availableWidth: availableWidth,
            occupiedRects: occupiedRects,
            clearanceInset: clearanceInset,
            style: style
        )
    }

    /// Finds the nearest free radial slot in Bloom's center-out ring sequence.
    /// When the finite canvas cannot fit another ring slot, the regular grid is
    /// used as a safe downward fallback rather than allowing a card off-canvas.
    private static func nearestBloomPosition(
        for pointSize: CGSize,
        nearX: Double,
        nearY: Double,
        canvasWidth: Double,
        occupiedRects: [CGRect],
        minimumY: Double?
    ) -> CGPoint {
        let margin = Double(CanvasMetrics.canvasMargin)
        let rowOrigin = max(margin, minimumY ?? margin)
        let width = Double(pointSize.width)
        let height = Double(pointSize.height)
        let availableWidth = canvasWidth - 2 * margin
        guard width <= availableWidth + 0.5 else {
            return CGPoint(x: margin, y: rowOrigin)
        }

        let requestedCenter = CGPoint(
            x: nearX + width / 2,
            y: nearY + height / 2
        )
        let candidateCount = max(occupiedRects.count + 24, 24)
        let slots = CanvasGridStyle.bloom.bloomSlotOrder(count: candidateCount)
        let candidates = slots.enumerated().compactMap { rank, slot -> (rank: Int, point: CGPoint, distance: Double)? in
            let origin = CanvasGridStyle.bloom.bloomOrigin(
                for: slot,
                cardSize: pointSize,
                rowOrigin: rowOrigin
            )
            let x = Double(origin.x)
            let y = Double(origin.y)
            guard x >= margin - 0.5,
                  x + width <= margin + availableWidth + 0.5,
                  y >= rowOrigin - 0.5,
                  isClear(
                    x,
                    y,
                    width: width,
                    height: height,
                    occupiedRects: occupiedRects,
                    clearanceInset: Double(CanvasMetrics.bloomCollisionInset)
                  ) else {
                return nil
            }

            let candidateCenter = CGPoint(x: x + width / 2, y: y + height / 2)
            let dx = Double(candidateCenter.x - requestedCenter.x)
            let dy = Double(candidateCenter.y - requestedCenter.y)
            return (rank, origin, dx * dx + dy * dy)
        }

        if let nearest = candidates.min(by: { lhs, rhs in
            if lhs.distance == rhs.distance { return lhs.rank < rhs.rank }
            return lhs.distance < rhs.distance
        }) {
            return nearest.point
        }

        return nearestFreePosition(
            for: pointSize,
            nearX: nearX,
            nearY: nearY,
            canvasWidth: canvasWidth,
            occupiedRects: occupiedRects,
            minimumY: minimumY,
            style: .grid
        )
    }

    private static func rowOrigin(for minimumY: Double?, margin: Double) -> Double {
        max(margin, minimumY ?? margin)
    }

    private static func rowBelowContent(
        _ occupiedRects: [CGRect],
        rowOrigin: Double,
        yPitch: Double,
        clearanceInset: Double
    ) -> Int {
        occupiedRects.map {
            Int(ceil(($0.maxY + clearanceInset - rowOrigin) / yPitch))
        }.max() ?? 0
    }

    private static func orderedColumns(
        _ columns: [Int],
        baseColumn: Int,
        nearX: Double,
        margin: Double,
        pitch: Double,
        offset: Double
    ) -> [Int] {
        columns.sorted { lhs, rhs in
            let lhsDistance = abs((margin + offset + pitch * Double(lhs)) - nearX)
            let rhsDistance = abs((margin + offset + pitch * Double(rhs)) - nearX)
            if lhsDistance == rhsDistance {
                return abs(lhs - baseColumn) < abs(rhs - baseColumn)
            }
            return lhsDistance < rhsDistance
        }
    }

    private static func searchNearest(
        baseRow: Int,
        searchLimit: Int,
        columns: [Int],
        baseColumn: Int,
        nearX: Double,
        rowOrigin: Double,
        yPitch: Double,
        margin: Double,
        xPitch: Double,
        width: Double,
        height: Double,
        availableWidth: Double,
        occupiedRects: [CGRect],
        clearanceInset: Double,
        style: CanvasGridStyle
    ) -> CGPoint? {
        for distance in 0...searchLimit {
            guard let position = searchRows(
                around: baseRow,
                distance: distance,
                columns: columns,
                baseColumn: baseColumn,
                nearX: nearX,
                rowOrigin: rowOrigin,
                yPitch: yPitch,
                margin: margin,
                xPitch: xPitch,
                width: width,
                height: height,
                availableWidth: availableWidth,
                occupiedRects: occupiedRects,
                clearanceInset: clearanceInset,
                style: style
            ) else {
                continue
            }
            return position
        }
        return nil
    }

    private static func searchRows(
        around baseRow: Int,
        distance: Int,
        columns: [Int],
        baseColumn: Int,
        nearX: Double,
        rowOrigin: Double,
        yPitch: Double,
        margin: Double,
        xPitch: Double,
        width: Double,
        height: Double,
        availableWidth: Double,
        occupiedRects: [CGRect],
        clearanceInset: Double,
        style: CanvasGridStyle
    ) -> CGPoint? {
        for row in rows(around: baseRow, distance: distance) {
            let rowOffset = Double(style.rowOffset(for: row))
            let rowColumns = orderedColumns(
                columns,
                baseColumn: baseColumn,
                nearX: nearX,
                margin: margin,
                pitch: xPitch,
                offset: rowOffset
            )
            if let position = searchColumns(
                row: row,
                columns: rowColumns,
                rowOffset: rowOffset,
                rowOrigin: rowOrigin,
                yPitch: yPitch,
                margin: margin,
                xPitch: xPitch,
                width: width,
                height: height,
                availableWidth: availableWidth,
                occupiedRects: occupiedRects,
                clearanceInset: clearanceInset
            ) {
                return position
            }
        }
        return nil
    }

    private static func searchColumns(
        row: Int,
        columns: [Int],
        rowOffset: Double,
        rowOrigin: Double,
        yPitch: Double,
        margin: Double,
        xPitch: Double,
        width: Double,
        height: Double,
        availableWidth: Double,
        occupiedRects: [CGRect],
        clearanceInset: Double
    ) -> CGPoint? {
        for column in columns {
            let candidateX = margin + rowOffset + xPitch * Double(column)
            let candidateY = rowOrigin + yPitch * Double(row)
            guard candidateX >= margin - 0.5,
                  candidateX + width <= margin + availableWidth + 0.5 else {
                continue
            }
            if isClear(
                candidateX,
                candidateY,
                width: width,
                height: height,
                occupiedRects: occupiedRects,
                clearanceInset: clearanceInset
            ) {
                return CGPoint(x: candidateX, y: candidateY)
            }
        }
        return nil
    }

    private static func rows(around baseRow: Int, distance: Int) -> [Int] {
        if distance == 0 { return [baseRow] }
        return [baseRow - distance, baseRow + distance].filter { $0 >= 0 }
    }

    private static func fallbackPosition(
        startingRow: Int,
        columns: [Int],
        baseColumn: Int,
        nearX: Double,
        rowOrigin: Double,
        yPitch: Double,
        margin: Double,
        xPitch: Double,
        width: Double,
        height: Double,
        availableWidth: Double,
        occupiedRects: [CGRect],
        clearanceInset: Double,
        style: CanvasGridStyle
    ) -> CGPoint {
        var row = startingRow
        while true {
            let rowOffset = Double(style.rowOffset(for: row))
            let rowColumns = orderedColumns(
                columns,
                baseColumn: baseColumn,
                nearX: nearX,
                margin: margin,
                pitch: xPitch,
                offset: rowOffset
            )
            if let position = searchColumns(
                row: row,
                columns: rowColumns,
                rowOffset: rowOffset,
                rowOrigin: rowOrigin,
                yPitch: yPitch,
                margin: margin,
                xPitch: xPitch,
                width: width,
                height: height,
                availableWidth: availableWidth,
                occupiedRects: occupiedRects,
                clearanceInset: clearanceInset
            ) {
                return position
            }
            row += 1
        }
    }

    private static func isClear(
        _ x: Double,
        _ y: Double,
        width: Double,
        height: Double,
        occupiedRects: [CGRect],
        clearanceInset: Double
    ) -> Bool {
        let candidate = CGRect(
            x: x - clearanceInset,
            y: y - clearanceInset,
            width: width + 2 * clearanceInset,
            height: height + 2 * clearanceInset
        )
        return !occupiedRects.contains(where: candidate.intersects)
    }
}
