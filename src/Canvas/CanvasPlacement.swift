import CoreGraphics

/// Pure placement logic shared by the canvas and its unit tests.
nonisolated enum CanvasPlacement {
    /// Finds the grid-aligned, collision-free origin nearest a requested point.
    ///
    /// The x-axis is finite: cards stay inside the one-dot margins around the four-column
    /// canvas. Both axes use the card module lattice; the y-axis has no upper bound and rows are
    /// searched until a free one is found.
    static func nearestFreePosition(
        for pointSize: CGSize,
        nearX: Double,
        nearY: Double,
        canvasWidth: Double,
        occupiedRects: [CGRect],
        minimumY: Double? = nil
    ) -> CGPoint {
        let unit = Double(CanvasMetrics.gridUnit)
        let xPitch = Double(CanvasMetrics.module)
        let margin = Double(CanvasMetrics.canvasMargin)
        let yPitch = Double(CanvasMetrics.module)
        let rowOrigin = rowOrigin(for: minimumY, margin: margin)
        let width = Double(pointSize.width)
        let height = Double(pointSize.height)

        let availableWidth = canvasWidth - 2 * margin
        guard width <= availableWidth + 0.5 else {
            // Every built-in card fits, but keep the fallback safe for future card sizes.
            return CGPoint(x: margin, y: margin)
        }

        let lastColumn = Int(floor((availableWidth - width + 0.5) / xPitch))
        let columns = Array(0...max(0, lastColumn))

        let requestedColumn = Int(((nearX - margin) / xPitch).rounded())
        let baseColumn = min(max(requestedColumn, 0), max(0, lastColumn))
        let requestedRow = Int(((nearY - rowOrigin) / yPitch).rounded())
        let baseRow = max(requestedRow, 0)

        let columnsByDistance = orderedColumns(
            columns,
            baseColumn: baseColumn,
            nearX: nearX,
            margin: margin,
            pitch: xPitch
        )
        let searchLimit = max(64, occupiedRects.count * 8 + 8)
        if let position = searchNearest(
            baseRow: baseRow,
            searchLimit: searchLimit,
            columns: columnsByDistance,
            rowOrigin: rowOrigin,
            yPitch: yPitch,
            margin: margin,
            xPitch: xPitch,
            width: width,
            height: height,
            occupiedRects: occupiedRects,
            unit: unit
        ) {
            return position
        }

        // Fall back to a row below all occupied content. Since y is intentionally unbounded,
        // this loop always finds a free slot for the finite board.
        let rowBelowContent = rowBelowContent(
            occupiedRects,
            rowOrigin: rowOrigin,
            yPitch: yPitch,
            unit: unit
        )
        return fallbackPosition(
            startingRow: max(baseRow, rowBelowContent),
            columns: columnsByDistance,
            rowOrigin: rowOrigin,
            yPitch: yPitch,
            margin: margin,
            xPitch: xPitch,
            width: width,
            height: height,
            occupiedRects: occupiedRects,
            unit: unit
        )
    }

    private static func rowOrigin(for minimumY: Double?, margin: Double) -> Double {
        max(margin, minimumY ?? margin)
    }

    private static func rowBelowContent(
        _ occupiedRects: [CGRect],
        rowOrigin: Double,
        yPitch: Double,
        unit: Double
    ) -> Int {
        occupiedRects.map {
            Int(ceil(($0.maxY + unit - 1 - rowOrigin) / yPitch))
        }.max() ?? 0
    }

    private static func orderedColumns(
        _ columns: [Int],
        baseColumn: Int,
        nearX: Double,
        margin: Double,
        pitch: Double
    ) -> [Int] {
        columns.sorted { lhs, rhs in
            let lhsDistance = abs((margin + pitch * Double(lhs)) - nearX)
            let rhsDistance = abs((margin + pitch * Double(rhs)) - nearX)
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
        rowOrigin: Double,
        yPitch: Double,
        margin: Double,
        xPitch: Double,
        width: Double,
        height: Double,
        occupiedRects: [CGRect],
        unit: Double
    ) -> CGPoint? {
        for distance in 0...searchLimit {
            guard let position = searchRows(
                around: baseRow,
                distance: distance,
                columns: columns,
                rowOrigin: rowOrigin,
                yPitch: yPitch,
                margin: margin,
                xPitch: xPitch,
                width: width,
                height: height,
                occupiedRects: occupiedRects,
                unit: unit
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
        rowOrigin: Double,
        yPitch: Double,
        margin: Double,
        xPitch: Double,
        width: Double,
        height: Double,
        occupiedRects: [CGRect],
        unit: Double
    ) -> CGPoint? {
        for row in rows(around: baseRow, distance: distance) {
            if let position = searchColumns(
                row: row,
                columns: columns,
                rowOrigin: rowOrigin,
                yPitch: yPitch,
                margin: margin,
                xPitch: xPitch,
                width: width,
                height: height,
                occupiedRects: occupiedRects,
                unit: unit
            ) {
                return position
            }
        }
        return nil
    }

    private static func searchColumns(
        row: Int,
        columns: [Int],
        rowOrigin: Double,
        yPitch: Double,
        margin: Double,
        xPitch: Double,
        width: Double,
        height: Double,
        occupiedRects: [CGRect],
        unit: Double
    ) -> CGPoint? {
        for column in columns {
            let candidateX = margin + xPitch * Double(column)
            let candidateY = rowOrigin + yPitch * Double(row)
            if isClear(
                candidateX,
                candidateY,
                width: width,
                height: height,
                occupiedRects: occupiedRects,
                unit: unit
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
        rowOrigin: Double,
        yPitch: Double,
        margin: Double,
        xPitch: Double,
        width: Double,
        height: Double,
        occupiedRects: [CGRect],
        unit: Double
    ) -> CGPoint {
        var row = startingRow
        while true {
            for column in columns {
                let candidateX = margin + xPitch * Double(column)
                let candidateY = rowOrigin + yPitch * Double(row)
                if isClear(
                    candidateX,
                    candidateY,
                    width: width,
                    height: height,
                    occupiedRects: occupiedRects,
                    unit: unit
                ) {
                    return CGPoint(x: candidateX, y: candidateY)
                }
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
        unit: Double
    ) -> Bool {
        // Inflate by just under one dot so a candidate exactly one dot away still clears.
        let inset = unit - 1
        let candidate = CGRect(
            x: x - inset,
            y: y - inset,
            width: width + 2 * inset,
            height: height + 2 * inset
        )
        return !occupiedRects.contains(where: candidate.intersects)
    }
}
