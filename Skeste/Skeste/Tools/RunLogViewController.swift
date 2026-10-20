import UIKit
import SnapKit

final class RunLogViewController: BaseViewController {
    private let contentStack = UIStackView()

    override func setupView() {
        _ = LabHeader.add(to: self, title: "RIDGE LAB  /  SEASON LOG")
        let (_, stack) = LabHeader.addScroll(to: self)
        contentStack.axis = .vertical
        contentStack.spacing = 0
        stack.addArrangedSubview(contentStack)

        buildHeader()
        buildBody()
        buildFooter()
    }

    override func refreshView() {
        guard isViewLoaded else { return }
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        buildHeader()
        buildBody()
        buildFooter()
    }

    private func buildHeader() {
        let kicker = UILabel(text: "EVERY DESCENT COUNTS", font: SkesteFont.demibold(8), color: Palette.lime)
        kicker.tracked(1.8)
        contentStack.addArrangedSubview(kicker)
        contentStack.setCustomSpacing(4, after: kicker)

        let title = UILabel(text: "YOUR\nSEASON.", font: SkesteFont.display(32), color: Palette.text, lines: 2)
        title.richTracking(-0.8)
        contentStack.addArrangedSubview(title)
        contentStack.setCustomSpacing(6, after: title)

        let subtitle = UILabel(text: "The vertical you earned, the lines you logged, and the days that made the winter. Saved from the Run Tracker and kept on this device.", font: SkesteFont.body(12), color: Palette.secondary, lines: 0)
        subtitle.lineSpacing(3)
        contentStack.addArrangedSubview(subtitle)
        contentStack.setCustomSpacing(18, after: subtitle)
    }

    private func buildBody() {
        let runs = AppStore.shared.runs
        guard !runs.isEmpty else {
            let empty = EmptyStateView(symbol: "figure.skiing.downhill",
                                       kicker: "The log is open",
                                       title: "NO DESCENTS YET",
                                       message: "Start a tracked run at the top and stop it at the bottom. Your vertical, distance, and top speed will land here.",
                                       actionTitle: "START A RUN") { [weak self] in
                self?.push(RunTrackerViewController())
            }
            contentStack.addArrangedSubview(empty)
            contentStack.setCustomSpacing(16, after: empty)
            return
        }

        buildSeasonCard(runs: runs)
        buildChart(runs: runs)
        buildRunList(runs: runs)
    }

    private func buildSeasonCard(runs: [RunRecord]) {
        let card = LabCard()
        contentStack.addArrangedSubview(card)
        contentStack.setCustomSpacing(14, after: card)

        let kicker = UILabel(text: seasonLabel(), font: SkesteFont.demibold(8), color: Palette.cyan)
        kicker.tracked(1.6)
        card.addSubview(kicker)
        kicker.snp.makeConstraints { $0.leading.top.equalToSuperview().offset(16) }

        let vertical = UILabel(text: "\(Int(AppStore.shared.totalVertical.rounded())) m", font: SkesteFont.display(44), color: Palette.text)
        vertical.richTracking(-1)
        card.addSubview(vertical)
        vertical.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(kicker.snp.bottom).offset(7)
        }
        let verticalCaption = UILabel(text: "TOTAL VERTICAL", font: SkesteFont.demibold(7), color: Palette.muted)
        verticalCaption.tracked(1.2)
        card.addSubview(verticalCaption)
        verticalCaption.snp.makeConstraints { make in
            make.leading.equalTo(vertical)
            make.top.equalTo(vertical.snp.bottom).offset(-4)
        }

        let counts = UIStackView()
        counts.axis = .horizontal
        counts.distribution = .fillEqually
        counts.spacing = 8
        card.addSubview(counts)
        counts.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(verticalCaption.snp.bottom).offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        let bestSpeed = runs.map(\.topSpeedKPH).max() ?? 0
        let longest = runs.map(\.distanceMeters).max() ?? 0
        let bestDay = bestDayVertical(runs)
        counts.addArrangedSubview(stat(value: "\(runs.count)", label: "RUNS", color: Palette.text))
        counts.addArrangedSubview(stat(value: "\(Int(bestSpeed.rounded()))", label: "TOP KM/H", color: Palette.lime))
        counts.addArrangedSubview(stat(value: distanceLabel(longest), label: "LONGEST", color: Palette.ice))
        counts.addArrangedSubview(stat(value: "\(Int(bestDay.rounded())) m", label: "BEST DAY", color: Palette.amber))
    }

    private func buildChart(runs: [RunRecord]) {
        let heading = SectionHeadingView(kicker: "The shape of the winter", title: "VERTICAL TIMELINE", actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(10, after: heading)

        let card = LabCard()
        contentStack.addArrangedSubview(card)
        contentStack.setCustomSpacing(20, after: card)

        let chart = LabBarChartView()
        chart.tint = Palette.lime
        let recent = Array(runs.prefix(10).reversed())
        chart.setValues(recent.map(\.verticalMeters), labels: recent.map { dayLabel($0.startedAt) })
        card.addSubview(chart)
        chart.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.top.equalToSuperview().offset(14)
            make.height.equalTo(128)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    private func buildRunList(runs: [RunRecord]) {
        let heading = SectionHeadingView(kicker: "Every line, one by one", title: "THE LOG", actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(10, after: heading)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        contentStack.addArrangedSubview(stack)
        contentStack.setCustomSpacing(16, after: stack)

        for run in runs {
            stack.addArrangedSubview(runRow(run))
        }
    }

    private func runRow(_ run: RunRecord) -> UIView {
        let card = LabCard()
        let day = UILabel(text: dayLabel(run.startedAt) + "  ·  " + timeLabel(run.startedAt), font: SkesteFont.demibold(8), color: Palette.muted)
        day.tracked(1.0)
        card.addSubview(day)
        day.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(14)
        }

        let resort = UILabel(text: run.resort, font: SkesteFont.demibold(13), color: Palette.text)
        card.addSubview(resort)
        resort.snp.makeConstraints { make in
            make.leading.equalTo(day)
            make.top.equalTo(day.snp.bottom).offset(2)
        }

        let vertical = UILabel(text: "\(Int(run.verticalMeters.rounded())) m", font: SkesteFont.display(26), color: Palette.lime)
        card.addSubview(vertical)
        vertical.snp.makeConstraints { make in
            make.leading.equalTo(day)
            make.top.equalTo(resort.snp.bottom).offset(3)
            make.bottom.equalToSuperview().offset(-14)
        }

        let meta = UILabel(text: "\(distanceLabel(run.distanceMeters))  ·  \(durationLabel(run.duration))  ·  \(Int(run.topSpeedKPH.rounded())) km/h", font: SkesteFont.mono(9, weight: .medium), color: Palette.secondary)
        card.addSubview(meta)
        meta.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalTo(resort)
        }

        let share = SkesteControls.iconButton(symbol: "square.and.arrow.up", diameter: 36, tint: Palette.cyan)
        share.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let caption = "\(Int(run.verticalMeters.rounded())) m of vertical at \(run.resort). \(distanceLabel(run.distanceMeters)) · \(durationLabel(run.duration)) · \(Int(run.topSpeedKPH.rounded())) km/h."
            LabShare.present(image: LabShareCard.run(run, resortName: run.resort), text: caption, from: self)
            SkesteHaptics.light()
        }, for: .touchUpInside)
        card.addSubview(share)
        share.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-12)
        }

        card.isAccessibilityElement = true
        card.accessibilityLabel = "\(run.resort), \(Int(run.verticalMeters.rounded())) meters, \(dayLabel(run.startedAt))"
        return card
    }

    private func buildFooter() {
        let note = UILabel(text: "Runs live on this device. Export a card to share the line with your circle.", font: SkesteFont.body(10), color: Palette.muted, lines: 0)
        note.textAlignment = .center
        note.lineSpacing(2)
        contentStack.addArrangedSubview(note)
    }

    private func stat(value: String, label: String, color: UIColor) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        let valueLabel = UILabel(text: value, font: SkesteFont.display(21), color: color)
        valueLabel.textAlignment = .center
        let labelLabel = UILabel(text: label, font: SkesteFont.demibold(6.5), color: Palette.muted)
        labelLabel.tracked(0.9)
        labelLabel.textAlignment = .center
        stack.addArrangedSubview(valueLabel)
        stack.addArrangedSubview(labelLabel)
        return stack
    }

    private func seasonLabel() -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        if month >= 7 {
            return "SEASON \(year)/\(String((year + 1) % 100).leftPadding(toLength: 2, withPad: "0"))"
        }
        return "SEASON \(year - 1)/\(String(year % 100).leftPadding(toLength: 2, withPad: "0"))"
    }

    private func bestDayVertical(_ runs: [RunRecord]) -> Double {
        let grouped = Dictionary(grouping: runs) { Calendar.current.startOfDay(for: $0.startedAt) }
        return grouped.map { $0.value.reduce(0) { $0 + $1.verticalMeters } }.max() ?? 0
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date).uppercased()
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func distanceLabel(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return "\(Int(meters.rounded())) m"
    }

    private func durationLabel(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private extension String {
    func leftPadding(toLength: Int, withPad character: String) -> String {
        let padding = max(0, toLength - count)
        return String(repeating: character, count: padding) + self
    }
}
