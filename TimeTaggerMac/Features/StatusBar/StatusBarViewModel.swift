import Foundation
import Combine

@MainActor
final class StatusBarViewModel: ObservableObject {
    @Published var statusText: String = "–"
    @Published var activeRecord: TimeRecord?

    private var timerCancellable: AnyCancellable?

    func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.updateStatusText() }
    }

    func stopTimer() {
        timerCancellable = nil
    }

    func setActiveRecord(_ record: TimeRecord?) {
        activeRecord = record
        updateStatusText()
        record != nil ? startTimer() : stopTimer()
    }

    private func updateStatusText() {
        guard let record = activeRecord else {
            statusText = "–"
            return
        }
        let elapsed = Int(Date().timeIntervalSince1970) - record.t1
        let h = elapsed / 3600
        let m = (elapsed % 3600) / 60
        let s = elapsed % 60
        let time = h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
        let tagLabel = record.tags.first ?? "–"
        statusText = "\(tagLabel) \(time)"
    }
}
