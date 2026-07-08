import XCTest
@testable import FolioReaderKit

class FolioReaderListDeleteActionTests: XCTestCase {

    func testDeleteLastRowInOnlySection_returnsDeleteSection() {
        let action = folioReaderListDeleteAction(
            isOnlyRowInSection: true,
            indexPath: IndexPath(row: 0, section: 0)
        )

        guard case .deleteSection(let section) = action else {
            XCTFail("Expected .deleteSection, got \(action)")
            return
        }
        XCTAssertEqual(section, 0)
    }

    func testDeleteNonLastRow_returnsDeleteRow() {
        let indexPath = IndexPath(row: 1, section: 0)
        let action = folioReaderListDeleteAction(
            isOnlyRowInSection: false,
            indexPath: indexPath
        )

        guard case .deleteRow(let row) = action else {
            XCTFail("Expected .deleteRow, got \(action)")
            return
        }
        XCTAssertEqual(row, indexPath)
    }

    func testDeleteLastRowInMiddleSection_returnsDeleteSection() {
        let indexPath = IndexPath(row: 0, section: 1)
        let action = folioReaderListDeleteAction(
            isOnlyRowInSection: true,
            indexPath: indexPath
        )

        guard case .deleteSection(let section) = action else {
            XCTFail("Expected .deleteSection, got \(action)")
            return
        }
        XCTAssertEqual(section, 1)
    }

    func testPreservesIndexPathInRowCase() {
        let indexPath = IndexPath(row: 3, section: 2)
        let action = folioReaderListDeleteAction(
            isOnlyRowInSection: false,
            indexPath: indexPath
        )

        guard case .deleteRow(let row) = action else {
            XCTFail("Expected .deleteRow, got \(action)")
            return
        }
        XCTAssertEqual(row.row, 3)
        XCTAssertEqual(row.section, 2)
    }
}
