import UIKit
import SnapKit

final class SnowDeskViewController: BaseViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let selectorScroll = UIScrollView()
    private let selectorRow = UIStackView()
    private var selectorButtons: [UIButton] = []
    private var displayedResorts: [SnowResort] = []
    private var selectedIndex: Int = 0
    private var usesFahrenheit = LabPrefs.shared.usesFahrenheit
    private let unitButton = UIButton(type: .system)
    private let starButton = SkesteControls.iconButton(symbol: "star", diameter: 40)
    private let store = SnowReportStore.shared
    private var lastContentSignature = ""

    private var selectedResortKey: String {
        guard selectedIndex < displayedResorts.count else { return SnowLibrary.resorts[0].name }
        return SnowLibrary.resort(named: displayedResorts[selectedIndex].name)?.name
            ?? displayedResorts[selectedIndex].name
    }

    private func currentSnapshot() -> SnowResort {
        store.resort(named: selectedResortKey)
    }

    override func setupView() {
        displayedResorts = orderedResorts()
        selectedIndex = initialIndex()
        usesFahrenheit = LabPrefs.shared.usesFahrenheit
        buildHeader()
        buildScroll()
        buildSelector()
        rebuildSelectorButtons()
        updateSelector()
        updateStar()
        rebuildContent()
        store.refreshIfNeeded(named: selectedResortKey)
    }

    override func refreshView() {
        let signature = contentSignature()
        if signature != lastContentSignature {
            rebuildContent()
            lastContentSignature = signature
        }
        store.refreshIfNeeded(named: selectedResortKey)
    }

    override func snowDidChange(resortName: String?) {
        guard isViewLoaded, view.window != nil else { return }
        guard resortName == nil || resortName == selectedResortKey else { return }
        let offset = scrollView.contentOffset
        rebuildContent()
        view.layoutIfNeeded()
        let maxY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: min(offset.y, maxY)), animated: false)
    }

    private func contentSignature() -> String {
        let resort = currentSnapshot()
        let stamp = resort.reportUpdatedAt?.timeIntervalSince1970 ?? 0
        return "\(resort.name)-\(resort.reportSource.rawValue)-\(stamp)-\(usesFahrenheit)"
    }

    #if DEBUG
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard ProcessInfo.processInfo.arguments.contains("-snowDeskBottom") else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self else { return }
            let bottom = max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height)
            self.scrollView.setContentOffset(CGPoint(x: 0, y: bottom), animated: false)
        }
    }
    #endif

    private func buildHeader() {
        let header = UIView()
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.equalToSuperview().inset(AppLayout.screenPadding)
            make.height.equalTo(40)
        }

        let back = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        header.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }

        let label = UILabel(text: "RIDGE LAB  /  SNOW DESK", font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.6)
        header.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        unitButton.setTitle(usesFahrenheit ? "°F" : "°C", for: .normal)
        unitButton.setTitleColor(Palette.cyan, for: .normal)
        unitButton.titleLabel?.font = SkesteFont.mono(11, weight: .bold)
        unitButton.backgroundColor = Palette.glass
        unitButton.layer.cornerRadius = 12
        unitButton.layer.cornerCurve = .continuous
        unitButton.layer.borderWidth = 1
        unitButton.layer.borderColor = Palette.hairline.cgColor
        unitButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.usesFahrenheit.toggle()
            LabPrefs.shared.usesFahrenheit = self.usesFahrenheit
            self.unitButton.setTitle(self.usesFahrenheit ? "°F" : "°C", for: .normal)
            self.rebuildContent()
            SkesteHaptics.light()
        }, for: .touchUpInside)
        header.addSubview(unitButton)
        unitButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }

        starButton.addAction(UIAction { [weak self] _ in self?.toggleFavorite() }, for: .touchUpInside)
        header.addSubview(starButton)
        starButton.snp.makeConstraints { make in
            make.trailing.equalTo(unitButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
    }

    private func buildScroll() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        let refresh = UIRefreshControl()
        refresh.tintColor = Palette.cyan
        refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        scrollView.refreshControl = refresh
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(60)
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-40)
            make.width.equalTo(scrollView.snp.width).offset(-AppLayout.screenPadding * 2)
        }
    }

    @objc private func refreshPulled() {
        let key = selectedResortKey
        Task { [weak self] in
            guard let self else { return }
            let ok = await self.store.refresh(named: key, force: true)
            self.scrollView.refreshControl?.endRefreshing()
            guard self.selectedResortKey == key else { return }
            if !ok {
                let notice = self.store.status(for: key).notice ?? "Live weather is unavailable. Showing saved data."
                self.showToast(notice, style: .error)
            }
            self.rebuildContent()
        }
    }

    private func buildSelector() {
        selectorScroll.showsHorizontalScrollIndicator = false
        selectorScroll.contentInsetAdjustmentBehavior = .never
        selectorRow.axis = .horizontal
        selectorRow.spacing = 7
        selectorScroll.addSubview(selectorRow)
        selectorRow.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(selectorScroll.snp.height)
        }
        contentStack.addArrangedSubview(selectorScroll)
        selectorScroll.snp.makeConstraints { $0.height.equalTo(33) }
        contentStack.setCustomSpacing(18, after: selectorScroll)
    }

    private func rebuildSelectorButtons() {
        displayedResorts = orderedResorts()
        selectorRow.arrangedSubviews.forEach {
            selectorRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        selectorButtons.removeAll()
        for (index, resort) in displayedResorts.enumerated() {
            let favorite = LabPrefs.shared.isFavorite(resort.name)
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.title = (favorite ? "★ " : "") + resort.name.uppercased()
            configuration.baseForegroundColor = Palette.secondary
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 13, bottom: 0, trailing: 13)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = SkesteFont.demibold(9)
                return outgoing
            }
            button.configuration = configuration
            button.layer.cornerRadius = 16
            button.layer.borderWidth = 1
            button.tag = index
            button.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.selectedIndex = index
                self.updateSelector()
                self.updateStar()
                self.rebuildContent()
                self.scrollView.setContentOffset(.zero, animated: true)
                self.store.refreshIfNeeded(named: self.selectedResortKey)
                SkesteHaptics.light()
            }, for: .touchUpInside)
            selectorRow.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.height.equalTo(33)
                make.width.greaterThanOrEqualTo(64)
            }
            selectorButtons.append(button)
        }
    }

    private func updateSelector() {
        for (index, button) in selectorButtons.enumerated() {
            let selected = index == selectedIndex
            button.backgroundColor = selected ? Palette.lime : Palette.glass
            button.configuration?.baseForegroundColor = selected ? UIColor(hex: "0A0A0B") : Palette.secondary
            button.layer.borderColor = selected ? Palette.lime.cgColor : Palette.hairline.cgColor
        }
    }

    private func updateStar() {
        guard selectedIndex < displayedResorts.count else { return }
        let isFavorite = LabPrefs.shared.isFavorite(displayedResorts[selectedIndex].name)
        starButton.setImage(UIImage(systemName: isFavorite ? "star.fill" : "star",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)), for: .normal)
        starButton.tintColor = isFavorite ? Palette.amber : Palette.secondary
    }

    private func toggleFavorite() {
        guard selectedIndex < displayedResorts.count else { return }
        let name = displayedResorts[selectedIndex].name
        LabPrefs.shared.toggleFavorite(name)
        rebuildSelectorButtons()
        if let index = displayedResorts.firstIndex(where: { $0.name == name }) {
            selectedIndex = index
        }
        updateSelector()
        updateStar()
        SkesteHaptics.light()
        showToast(LabPrefs.shared.isFavorite(name) ? "\(name) pinned to your resorts." : "\(name) unpinned.", style: .info)
    }

    private func orderedResorts() -> [SnowResort] {
        let all = store.resorts
        let favorites = LabPrefs.shared.favoriteResorts
        let pinned = all.filter { favorites.contains($0.name) }
        let rest = all.filter { !favorites.contains($0.name) }
        return pinned + rest
    }

    private func initialIndex() -> Int {
        guard let name = SKDataStore.shared.currentUser?.homeResort,
              let index = displayedResorts.firstIndex(where: { resort in
                  resort.name.lowercased() == SnowLibrary.canonicalName(name).lowercased()
              }) else {
            return 0
        }
        return index
    }

    private func rebuildContent() {
        while contentStack.arrangedSubviews.count > 1 {
            if let last = contentStack.arrangedSubviews.last {
                contentStack.removeArrangedSubview(last)
                last.removeFromSuperview()
            }
        }

        let selectedName = selectedIndex < displayedResorts.count ? displayedResorts[selectedIndex].name : nil
        displayedResorts = orderedResorts()
        if let selectedName, let index = displayedResorts.firstIndex(where: { $0.name == selectedName }) {
            selectedIndex = index
        } else if selectedIndex >= displayedResorts.count {
            selectedIndex = 0
        }
        guard selectedIndex < displayedResorts.count else { return }
        let resort = currentSnapshot()

        let status: String
        switch resort.reportSource {
        case .live:
            status = "LIVE \(timeLabel(resort.reportUpdatedAt)) LOCAL"
        case .cached:
            status = "LAST LIVE \(timeLabel(resort.reportUpdatedAt)) LOCAL"
        case .sample:
            status = "SAMPLE DATA"
        }
        let kickerText = "TODAY'S FIELD BRIEF  ·  \(status)" + (resort.reportSource.isWeatherKitData ? "  ·  APPLE WEATHER" : "")
        let kicker = UILabel(text: kickerText, font: SkesteFont.demibold(8), color: resort.reportSource == .sample ? Palette.amber : Palette.secondary)
        kicker.tracked(1.6)
        contentStack.addArrangedSubview(kicker)
        contentStack.setCustomSpacing(4, after: kicker)

        let title = UILabel(text: resort.name.uppercased() + ".", font: SkesteFont.display(32), color: Palette.text)
        title.richTracking(-0.8)
        contentStack.addArrangedSubview(title)
        contentStack.setCustomSpacing(3, after: title)

        let region = UILabel(text: resort.region, font: SkesteFont.medium(10), color: Palette.muted)
        contentStack.addArrangedSubview(region)
        contentStack.setCustomSpacing(16, after: region)

        buildHero(resort)
        buildBestWindow(resort)
        buildMetrics(resort)
        buildAvalanche(resort)
        buildHistory(resort)
        buildMountainProfile(resort)
        buildTimeline(resort)
        buildOutlook(resort)
        buildFieldNote(resort)
        buildShare(resort)
        lastContentSignature = contentSignature()
    }

    private func buildHero(_ resort: SnowResort) {
        let card = UIView()
        card.applyGlass(cornerRadius: 18, borderAlpha: 0.14, fill: Palette.glass)
        let topo = TopoLinesView()
        topo.lineColor = Palette.cyan.withAlphaComponent(0.08)
        card.addSubview(topo)
        topo.snp.makeConstraints { $0.edges.equalToSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let top = UIStackView()
        top.axis = .horizontal
        top.alignment = .top
        top.spacing = 10
        stack.addArrangedSubview(top)
        stack.setCustomSpacing(12, after: top)

        let tempBlock = UIStackView()
        tempBlock.axis = .vertical
        tempBlock.spacing = -6
        let temp = UILabel(text: tempString(resort.tempC, withDegree: true), font: SkesteFont.display(68), color: Palette.text)
        temp.richTracking(-2)
        tempBlock.addArrangedSubview(temp)
        let tempLabel = UILabel(text: "AIR TEMPERATURE", font: SkesteFont.demibold(7), color: Palette.muted)
        tempLabel.tracked(1.2)
        tempBlock.addArrangedSubview(tempLabel)
        top.addArrangedSubview(tempBlock)

        let condition = UIStackView()
        condition.axis = .vertical
        condition.alignment = .trailing
        condition.spacing = 4
        let icon = UIImageView(image: UIImage(systemName: resort.conditionSymbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)))
        icon.tintColor = resort.freshCM > 20 ? Palette.ice : Palette.amber
        condition.addArrangedSubview(icon)
        let conditionLabel = UILabel(text: resort.conditionHeadline, font: SkesteFont.demibold(8), color: Palette.secondary)
        conditionLabel.tracked(1.2)
        condition.addArrangedSubview(conditionLabel)
        let level = SkesteTagLabel(text: "L\(resort.avalancheLevel) · REF",
                                   tint: avalancheColor(resort.avalancheLevel),
                                   fill: avalancheColor(resort.avalancheLevel).withAlphaComponent(0.14))
        condition.addArrangedSubview(level)
        top.addArrangedSubview(condition)

        let metrics = UIStackView()
        metrics.axis = .horizontal
        metrics.distribution = .fillEqually
        metrics.spacing = 8
        let snowLabel = resort.reportSource.isWeatherKitData ? "SNOW TODAY" : "FRESH / 24H"
        metrics.addArrangedSubview(metric("\(resort.freshCM) cm", snowLabel, Palette.ice))
        let freezingLabel = resort.reportSource.isWeatherKitData ? "FREEZING LVL (EST.)" : "FREEZING LEVEL"
        metrics.addArrangedSubview(metric("\(resort.freezingLevelM) m", freezingLabel, Palette.text))
        metrics.addArrangedSubview(metric("\(resort.humidity)%", "HUMIDITY", Palette.violet))
        stack.addArrangedSubview(metrics)

        contentStack.addArrangedSubview(card)
        contentStack.setCustomSpacing(10, after: card)
    }

    private func buildBestWindow(_ resort: SnowResort) {
        let card = UIView()
        card.applyGlass(cornerRadius: 16, borderAlpha: 0.08, fill: Palette.glass)
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }

        let iconHost = UIView()
        iconHost.backgroundColor = Palette.cyan.withAlphaComponent(0.12)
        iconHost.layer.cornerRadius = 14
        iconHost.snp.makeConstraints { $0.width.height.equalTo(40) }
        let icon = UIImageView(image: UIImage(systemName: "sun.max.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)))
        icon.tintColor = Palette.cyan
        iconHost.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(22) }
        stack.addArrangedSubview(iconHost)

        let text = UIStackView()
        text.axis = .vertical
        text.spacing = 0
        let kicker = UILabel(text: "BEST WINDOW", font: SkesteFont.demibold(7), color: Palette.cyan)
        kicker.tracked(1.2)
        text.addArrangedSubview(kicker)
        let window = UILabel(text: resort.bestWindow.label, font: SkesteFont.display(22), color: Palette.text)
        window.richTracking(-0.3)
        text.addArrangedSubview(window)
        let detail = UILabel(text: resort.bestWindow.detail, font: SkesteFont.medium(9), color: Palette.secondary)
        text.addArrangedSubview(detail)
        stack.addArrangedSubview(text)

        contentStack.addArrangedSubview(card)
        contentStack.setCustomSpacing(10, after: card)
    }

    private func buildMetrics(_ resort: SnowResort) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        contentStack.addArrangedSubview(row)
        contentStack.setCustomSpacing(10, after: row)
        let snowLineLabel = resort.reportSource.isWeatherKitData ? "SNOW LINE (EST.)" : "SNOW LINE"
        let metrics: [(String, String, UIColor)] = [
            ("\(resort.windKPH)", "WIND KM/H", Palette.text),
            ("\(resort.visibilityKM) KM", "VISIBILITY", Palette.text),
            ("\(resort.snowLineM) m", snowLineLabel, Palette.mint)
        ]
        for item in metrics {
            let card = UIView()
            card.applyGlass(cornerRadius: 18, borderAlpha: 0.08, fill: Palette.glass)
            let value = UILabel(text: item.0, font: SkesteFont.display(25), color: item.2)
            value.textAlignment = .center
            card.addSubview(value)
            value.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(11)
            }
            let label = UILabel(text: item.1, font: SkesteFont.demibold(7), color: Palette.muted)
            label.tracked(1.0)
            label.textAlignment = .center
            card.addSubview(label)
            label.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(value.snp.bottom).offset(0)
                make.bottom.equalToSuperview().offset(-10)
            }
            row.addArrangedSubview(card)
        }
    }

    private func buildAvalanche(_ resort: SnowResort) {
        let card = UIView()
        card.applyGlass(cornerRadius: 20, borderAlpha: 0.08, fill: Palette.glass)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }

        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)))
        icon.tintColor = avalancheColor(resort.avalancheLevel)
        icon.snp.makeConstraints { $0.width.height.equalTo(18) }
        header.addArrangedSubview(icon)
        let title = UILabel(text: "AVALANCHE · \(avalancheLabel(resort.avalancheLevel)) · REF", font: SkesteFont.demibold(9), color: avalancheColor(resort.avalancheLevel))
        title.tracked(1.1)
        header.addArrangedSubview(title)
        let spacer = UIView()
        header.addArrangedSubview(spacer)
        let open = SkesteControls.textButton("TERRAIN →", tint: Palette.secondary, size: 8)
        open.addAction(UIAction { [weak self] _ in
            let source = resort.reportSource == .live ? "live forecast" : (resort.reportSource == .cached ? "saved forecast" : "sample data")
            let credit = resort.reportSource.isWeatherKitData ? " · Apple Weather" : ""
            self?.push(TerrainCheckViewController(input: TerrainInput.from(resort: resort),
                                                   sourceNote: "\(resort.name) · L\(resort.avalancheLevel) · \(resort.freshCM) cm \(source)\(credit)"))
        }, for: .touchUpInside)
        header.addArrangedSubview(open)
        stack.addArrangedSubview(header)
        stack.setCustomSpacing(10, after: header)

        let meter = LabLevelMeterView()
        meter.setLevel(resort.avalancheLevel)
        stack.addArrangedSubview(meter)
        stack.setCustomSpacing(6, after: meter)

        let levelCaption = UILabel(text: "L\(resort.avalancheLevel) · REFERENCE VALUE — NOT A LIVE BULLETIN", font: SkesteFont.demibold(7), color: Palette.muted)
        levelCaption.tracked(1.0)
        stack.addArrangedSubview(levelCaption)
        stack.setCustomSpacing(10, after: levelCaption)

        let noteText: String
        if resort.reportSource.isWeatherKitData {
            noteText = "Avalanche danger levels are reference values, not a live bulletin. Check your local avalanche forecast before you go."
        } else {
            noteText = "\(resort.note)\n\nReference value only — check your local avalanche bulletin before you go."
        }
        let note = UILabel(text: noteText, font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
        note.lineSpacing(3)
        stack.addArrangedSubview(note)
        contentStack.addArrangedSubview(card)
        contentStack.setCustomSpacing(18, after: card)
    }

    private func buildHistory(_ resort: SnowResort) {
        let isLive = resort.reportSource.isWeatherKitData
        let heading = SectionHeadingView(kicker: isLive ? "Read the forecast" : "Read the trend",
                                         title: isLive ? "7-DAY SNOWFALL" : "7-DAY SNOW",
                                         actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(10, after: heading)

        if isLive, resort.days.isEmpty {
            let empty = UIView()
            empty.applyGlass(cornerRadius: 16, borderAlpha: 0.08, fill: Palette.glass)
            let label = UILabel(text: "No daily snowfall forecast is available for this point.", font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
            empty.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
            contentStack.addArrangedSubview(empty)
            contentStack.setCustomSpacing(16, after: empty)
            return
        }

        let card = LabCard()
        contentStack.addArrangedSubview(card)
        contentStack.setCustomSpacing(16, after: card)
        let chart = LabHistoryChartView()
        if isLive {
            let days = Array(resort.days.prefix(7))
            let labels = days.map { $0.day == "TOMORROW" ? "TOMRW" : $0.day }
            chart.freshLegend = "SNOW"
            chart.setData(base: [], fresh: days.map(\.freshCM), labels: labels, showsBase: false)
        } else {
            let labels = ["D-6", "D-5", "D-4", "D-3", "D-2", "YEST", "TODAY"]
            chart.setData(base: resort.baseHistoryCM, fresh: resort.freshHistoryCM, labels: labels)
        }
        card.addSubview(chart)
        chart.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(166)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    private func buildMountainProfile(_ resort: SnowResort) {
        let isLive = resort.reportSource.isWeatherKitData
        let heading = SectionHeadingView(kicker: isLive ? "Forecast point" : "Above the base",
                                         title: "MOUNTAIN PROFILE",
                                         actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(10, after: heading)

        let card = LabCard()
        contentStack.addArrangedSubview(card)
        contentStack.setCustomSpacing(16, after: card)

        var items: [LabInfoRow] = []
        if isLive {
            items = [
                LabInfoRow(title: "FORECAST POINT", value: "\(resort.elevationM) m"),
                LabInfoRow(title: "SNOW LINE (EST.)", value: "\(resort.snowLineM) m"),
                LabInfoRow(title: "FREEZING LEVEL (EST.)", value: "\(resort.freezingLevelM) m"),
                LabInfoRow(title: "WIND", value: "\(resort.windKPH) km/h"),
                LabInfoRow(title: "GUSTS", value: "\(resort.windGustKPH ?? resort.windKPH) km/h"),
                LabInfoRow(title: "HUMIDITY", value: "\(resort.humidity)%"),
                LabInfoRow(title: "CLOUD COVER", value: "\(resort.cloudCoverPercent ?? 0)%")
            ]
        } else {
            items = [
                LabInfoRow(title: "SNOW LINE", value: "\(resort.snowLineM) m"),
                LabInfoRow(title: "FREEZING LEVEL", value: "\(resort.freezingLevelM) m"),
                LabInfoRow(title: "WIND MID", value: "\(resort.windMidKPH) km/h"),
                LabInfoRow(title: "WIND UPPER", value: "\(resort.windTopKPH) km/h"),
                LabInfoRow(title: "HUMIDITY", value: "\(resort.humidity)%")
            ]
        }
        let rows = UIStackView(arrangedSubviews: items)
        rows.axis = .vertical
        rows.spacing = 9
        card.addSubview(rows)
        rows.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }

    private func buildTimeline(_ resort: SnowResort) {
        let heading = SectionHeadingView(kicker: "Read the day", title: "THE WINDOW", actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(10, after: heading)
        guard !resort.hours.isEmpty else {
            let empty = UIView()
            empty.applyGlass(cornerRadius: 16, borderAlpha: 0.08, fill: Palette.glass)
            let label = UILabel(text: "No hourly forecast available for this point.", font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
            empty.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
            contentStack.addArrangedSubview(empty)
            contentStack.setCustomSpacing(20, after: empty)
            return
        }
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        scroll.addSubview(row)
        row.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(scroll.snp.height)
        }
        for hour in resort.hours {
            let card = UIView()
            card.applyGlass(cornerRadius: 17, borderAlpha: 0.08, fill: Palette.glass)
            let time = UILabel(text: hour.time, font: SkesteFont.mono(8, weight: .bold), color: Palette.muted)
            time.textAlignment = .center
            card.addSubview(time)
            time.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(9)
            }
            let icon = UIImageView(image: UIImage(systemName: hour.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)))
            icon.tintColor = hour.snowChance > 45 ? Palette.ice : (hour.symbol.contains("sun") ? Palette.amber : Palette.secondary)
            card.addSubview(icon)
            icon.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(time.snp.bottom).offset(8)
                make.width.height.equalTo(22)
            }
            let temp = UILabel(text: tempString(hour.tempC), font: SkesteFont.display(19), color: Palette.text)
            temp.textAlignment = .center
            card.addSubview(temp)
            temp.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(icon.snp.bottom).offset(5)
            }
            let chance = UILabel(text: "\(hour.snowChance)%", font: SkesteFont.demibold(7), color: Palette.cyan)
            chance.textAlignment = .center
            card.addSubview(chance)
            chance.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(temp.snp.bottom).offset(1)
                make.bottom.equalToSuperview().offset(-8)
            }
            card.snp.makeConstraints { $0.width.equalTo(76) }
            row.addArrangedSubview(card)
        }
        contentStack.addArrangedSubview(scroll)
        scroll.snp.makeConstraints { $0.height.equalTo(128) }
        contentStack.setCustomSpacing(20, after: scroll)
    }

    private func buildOutlook(_ resort: SnowResort) {
        let heading = SectionHeadingView(kicker: "Next moves", title: "3-DAY OUTLOOK", actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(10, after: heading)
        guard !resort.days.isEmpty else {
            let empty = UIView()
            empty.applyGlass(cornerRadius: 16, borderAlpha: 0.08, fill: Palette.glass)
            let label = UILabel(text: "No daily outlook is available for this point.", font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
            empty.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
            contentStack.addArrangedSubview(empty)
            contentStack.setCustomSpacing(20, after: empty)
            return
        }
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 7
        contentStack.addArrangedSubview(stack)
        contentStack.setCustomSpacing(20, after: stack)
        for day in resort.days.prefix(3) {
            let row = UIView()
            row.applyGlass(cornerRadius: 17, borderAlpha: 0.08, fill: Palette.glass)
            let dayLabel = UILabel(text: day.day, font: SkesteFont.demibold(8), color: Palette.secondary)
            dayLabel.tracked(1.2)
            row.addSubview(dayLabel)
            dayLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(13)
                make.centerY.equalToSuperview()
                make.width.equalTo(76)
            }
            let icon = UIImageView(image: UIImage(systemName: day.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)))
            icon.tintColor = day.symbol.contains("sun") ? Palette.amber : Palette.ice
            row.addSubview(icon)
            icon.snp.makeConstraints { make in
                make.leading.equalTo(dayLabel.snp.trailing).offset(4)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(18)
            }
            let condition = UILabel(text: day.condition, font: SkesteFont.medium(11), color: Palette.text)
            row.addSubview(condition)
            condition.snp.makeConstraints { make in
                make.leading.equalTo(icon.snp.trailing).offset(8)
                make.centerY.equalToSuperview()
            }
            let snow = UILabel(text: "\(day.freshCM)cm", font: SkesteFont.demibold(10), color: day.freshCM > 0 ? Palette.ice : Palette.muted)
            row.addSubview(snow)
            snow.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-14)
                make.centerY.equalToSuperview()
            }
            let temp = UILabel(text: "\(tempString(day.highC)) / \(tempString(day.lowC))", font: SkesteFont.mono(8, weight: .medium), color: Palette.secondary)
            row.addSubview(temp)
            temp.snp.makeConstraints { make in
                make.trailing.equalTo(snow.snp.leading).offset(-12)
                make.centerY.equalToSuperview()
            }
            row.snp.makeConstraints { $0.height.equalTo(54) }
            stack.addArrangedSubview(row)
        }
    }

    private func buildFieldNote(_ resort: SnowResort) {
        let note = UIView()
        note.applyGlass(cornerRadius: 20, borderAlpha: 0.09, fill: Palette.glass)
        let bar = AccentLineView()
        bar.setColors([Palette.cyan, Palette.cyan])
        note.addSubview(bar)
        bar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 0))
            make.width.equalTo(2)
        }
        let body: String
        if resort.reportSource.isWeatherKitData {
            body = resort.conditionsNote ?? "Forecast data from Apple Weather. Avalanche level is a reference only."
        } else {
            body = "Read the report, then read the snow. A forecast is a starting point, not a decision."
        }
        let label = UILabel(text: "RIDGE NOTE  ·  \(body)", font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
        label.lineSpacing(3)
        note.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalTo(bar.snp.trailing).offset(10)
            make.trailing.top.bottom.equalToSuperview().inset(UIEdgeInsets(top: 13, left: 0, bottom: 13, right: 14))
        }
        contentStack.addArrangedSubview(note)
        contentStack.setCustomSpacing(resort.reportSource.isWeatherKitData ? 8 : 12, after: note)

        if resort.reportSource.isWeatherKitData {
            let credit = UIButton(type: .system)
            credit.contentHorizontalAlignment = .left
            let creditText = store.attribution?.legalText ?? "Weather data by Apple Weather"
            credit.setTitle("\(creditText)  ↗", for: .normal)
            credit.setTitleColor(Palette.cyan, for: .normal)
            credit.titleLabel?.font = SkesteFont.medium(10)
            credit.addAction(UIAction { [weak self] _ in
                let urlString = self?.store.attribution?.legalPageURLString
                    ?? "https://weatherkit.apple.com/attribution"
                if let url = URL(string: urlString) { self?.presentWebLink(url) }
            }, for: .touchUpInside)
            contentStack.addArrangedSubview(credit)
            contentStack.setCustomSpacing(12, after: credit)
        }
    }

    private func buildShare(_ resort: SnowResort) {
        let share = GhostButton(title: "SHARE THIS REPORT", icon: "square.and.arrow.up", height: 46, tint: Palette.cyan, borderColor: Palette.cyan.withAlphaComponent(0.25))
        share.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let weather = resort.reportSource.isWeatherKitData
                ? "\(resort.freshCM) cm forecast today · wind \(resort.windKPH) km/h · weather by Apple Weather"
                : "\(resort.freshCM) cm fresh / 24h · wind \(resort.windKPH) km/h"
            let text = "\(resort.name) · \(resort.tempC)°C · \(weather) · avalanche L\(resort.avalancheLevel) \(avalancheLabel(resort.avalancheLevel).lowercased()) (reference only). Best window \(resort.bestWindow.label). — Skeste Ridge Lab"
            LabShare.present(items: [text], from: self)
            SkesteHaptics.light()
        }, for: .touchUpInside)
        contentStack.addArrangedSubview(share)
    }

    private func metric(_ value: String, _ label: String, _ color: UIColor) -> UIStackView {
        let valueLabel = UILabel(text: value, font: SkesteFont.display(20), color: color)
        let labelLabel = UILabel(text: label, font: SkesteFont.demibold(7), color: Palette.muted)
        labelLabel.tracked(1.0)
        let stack = UIStackView(arrangedSubviews: [valueLabel, labelLabel])
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }

    private func avalancheColor(_ level: Int) -> UIColor {
        switch level {
        case 1: return Palette.lime
        case 2: return Palette.mint
        case 3: return Palette.amber
        case 4: return Palette.danger
        default: return UIColor(hex: "FF2D55")
        }
    }

    private func avalancheLabel(_ level: Int) -> String {
        switch level {
        case 1: return "LOW"
        case 2: return "MODERATE"
        case 3: return "CONSIDERABLE"
        case 4: return "HIGH"
        default: return "EXTREME"
        }
    }

    private func tempString(_ celsius: Int, withDegree: Bool = false) -> String {
        if usesFahrenheit {
            let f = Int(round(Double(celsius) * 9 / 5 + 32))
            return "\(f)°"
        }
        return "\(celsius)°"
    }

    private func timeLabel(_ date: Date?) -> String {
        guard let date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = currentSnapshot().timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
