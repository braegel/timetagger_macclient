import XCTest
@testable import TimeTaggerMac

@MainActor
final class StatusBarViewModelTests: XCTestCase {
    var sut: StatusBarViewModel!

    override func setUp() {
        super.setUp()
        sut = StatusBarViewModel()
    }

    func test_initialStatusText_isDash() {
        XCTAssertEqual(sut.statusText, "–")
    }

    func test_setActiveRecord_nil_showsDash() {
        sut.setActiveRecord(nil)
        XCTAssertEqual(sut.statusText, "–")
    }

    func test_setActiveRecord_showsTagAndElapsed() {
        let t1 = Int(Date().timeIntervalSince1970) - 90
        let record = TimeRecord(key: "k1", t1: t1, t2: 0, ds: "#work")
        sut.setActiveRecord(record)
        XCTAssertTrue(sut.statusText.contains("#work"), "Expected tag in status: \(sut.statusText)")
        XCTAssertTrue(sut.statusText.contains("1:30") || sut.statusText.contains("0:01:30"),
                      "Expected elapsed time in status: \(sut.statusText)")
    }
}
