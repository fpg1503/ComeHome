import Foundation

final class AudioFriendlyLayout: OrthogonalLayout {
    override func renderAsString(_ grid: Grid) -> String {
        var string = ""

        for _ in 0..<columns {
            string += "TTTTT"
        }
        string += "\n"

        for _ in 0..<columns {
            string += "XXXXX"
        }
        string += "\n"

        for row in 0..<rows {
            var bottom = "" //????
            var bottom2 = ""
            var bottom3 = ""
            var bottom4 = ""

            for column in 0..<columns {
                let loc = GridLocation(row: row, column: column)
                let cell = grid.at(loc) as! OrthogonalCell

                if column == 0 {
                    string += "TX"
                }

                if cell.gridLocation.column == 0 && cell.gridLocation.row == rows - 1 {
                    string += "S"
                } else if cell.gridLocation.column == columns - 1 && cell.gridLocation.row == 0 {
                    string += "G"
                } else {
                    string += "L"
                }

                if column < columns - 1 {
                    string += cell.isLinkedWith(cell.east) ? "LLLL" : "XTTX"
                } else {
                    string += "XT"
                }

                let leftSeparator = column == 0 ? "TX" : "LL"
                let rightSeparator = column == columns - 1 ? "XT" : "LL"
                // X Flooding will take care of XXXXX -> TXXXXT

                bottom += cell.isLinkedWith(cell.south) ? "\(leftSeparator)L\(rightSeparator)" : "XXXXX"
                bottom2 += cell.isLinkedWith(cell.south) ? "\(leftSeparator)L\(rightSeparator)" : "TTTTT"
                bottom3 += cell.isLinkedWith(cell.south) ? "\(leftSeparator)L\(rightSeparator)" : "TTTTT"
                bottom4 += cell.isLinkedWith(cell.south) ? "\(leftSeparator)L\(rightSeparator)" : "XXXXX"
            }

            if row < rows - 1 {
                string += "\n" + [bottom, bottom2, bottom3, bottom4].joined(separator: "\n") + "\n"
            } else {
                string += "\n" + Array(repeating: "X", count: 5 * rows) + "\n" + Array(repeating: "T", count: 5 * rows) + "\n"
            }
        }

        let xFlooded = xFlood(string)

        print(xFlooded + "\n" == string)

        return xFlooded
    }

    /// Returns the string after adding X to all soroundings of a T
    private func xFlood(_ string: String) -> String {
        let lines = string
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }

        var yXMatrix = lines.map { $0.map(String.init) }
        //Since I'm just flooding it's ok to have inverted axis

        let numColumns = yXMatrix.first?.count ?? 0
        let numRows = yXMatrix.count

        let die = "T"
        let warning = "X"

        for (y, line) in yXMatrix.enumerated() {
            for (x, char) in line.enumerated() {
                guard char == die else { continue }

                // North
                if y - 1 >= 0, yXMatrix[y-1][x] != die {
                    yXMatrix[y-1][x] = warning
                }

                // East
                if x + 1 < numColumns, yXMatrix[y][x+1] != die {
                    yXMatrix[y][x+1] = warning
                }

                // West
                if x - 1 >= 0, yXMatrix[y][x-1] != die {
                    yXMatrix[y][x-1] = warning
                }

                // South
                if y + 1 < numRows, yXMatrix[y+1][x] != die {
                    yXMatrix[y+1][x] = warning
                }
            }
        }

        let rebuiltString = yXMatrix.map { $0.joined() }.joined(separator: "\n")

        return rebuiltString
    }
}
