import UIKit
import SnapKit
import CoreLocation
import MapKit

final class AltitudeTraceView: UIView {
    private let line = CAShapeLayer()
    private let fill = CAShapeLayer()
    private let glow = CAShapeLayer()
    private(set) var values: [Double] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        fill.fillColor = Palette.cyan.withAlphaComponent(0.08).cgColor
        line.fillColor = UIColor.clear.cgColor
        line.strokeColor = Palette.cyan.cgColor
        line.lineWidth = 2
        line.lineJoin = .round
        line.lineCap = .round
        glow.fillColor = UIColor.clear.cgColor
        glow.strokeColor = Palette.cyan.withAlphaComponent(0.35).cgColor
        glow.lineWidth = 5
        glow.lineCap = .round
        glow.shadowColor = Palette.cyan.cgColor
        glow.shadowOpacity = 0.7
        glow.shadowRadius = 8
        glow.shadowOffset = .zero
        layer.addSublayer(fill)
        layer.addSublayer(glow)
        layer.addSublayer(line)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func append(_ altitude: Double) {
        guard altitude.isFinite else { return }
        values.append(altitude)
        if values.count > 120 { values.removeFirst(values.count - 120) }
        setNeedsLayout()
    }

    func reset() {
        values.removeAll()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard values.count > 1, let minValue = values.min(), let maxValue = values.max() else {
            line.path = nil
            fill.path = nil
            glow.path = nil
            return
        }
        let range = max(8, maxValue - minValue)
        let path = UIBezierPath()
        for (index, value) in values.enumerated() {
            let x = bounds.width * CGFloat(index) / CGFloat(max(1, values.count - 1))
            let normalized = CGFloat((value - minValue) / range)
            let y = bounds.height - 8 - normalized * (bounds.height - 18)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        line.path = path.cgPath
        glow.path = path.cgPath
        let fillPath = UIBezierPath(cgPath: path.cgPath)
        fillPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
        fillPath.addLine(to: CGPoint(x: 0, y: bounds.height))
        fillPath.close()
        fill.path = fillPath.cgPath
    }
}

final class RouteMapView: UIView, MKMapViewDelegate {
    private let map = MKMapView()
    private var coordinates: [CLLocationCoordinate2D] = []
    private var follow = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        map.delegate = self
        map.showsUserLocation = true
        map.showsCompass = false
        map.showsScale = false
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.overrideUserInterfaceStyle = .dark
        let configuration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        configuration.pointOfInterestFilter = .excludingAll
        map.preferredConfiguration = configuration
        addSubview(map)
        map.snp.makeConstraints { $0.edges.equalToSuperview() }
        setDefaultRegion()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func append(_ coordinate: CLLocationCoordinate2D) {
        if let last = coordinates.last,
           abs(last.latitude - coordinate.latitude) < 0.00001,
           abs(last.longitude - coordinate.longitude) < 0.00001 {
            return
        }
        coordinates.append(coordinate)
        if coordinates.count > 2_000 {
            coordinates.removeFirst(coordinates.count - 2_000)
        }
        redraw()
        if follow, coordinates.count == 1 || coordinates.count % 4 == 0 {
            focusRoute(animated: true)
        }
    }

    func reset() {
        coordinates.removeAll()
        map.removeOverlays(map.overlays)
        follow = true
        setDefaultRegion()
    }

    private func redraw() {
        map.removeOverlays(map.overlays)
        guard coordinates.count > 1 else { return }
        let line = MKPolyline(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(line)
    }

    private func focusRoute(animated: Bool) {
        guard let first = coordinates.first else { return }
        if coordinates.count == 1 {
            map.setRegion(MKCoordinateRegion(center: first, latitudinalMeters: 1_200, longitudinalMeters: 1_200), animated: false)
            return
        }
        let line = MKPolyline(coordinates: coordinates, count: coordinates.count)
        map.setVisibleMapRect(line.boundingMapRect,
                              edgePadding: UIEdgeInsets(top: 34, left: 28, bottom: 34, right: 28),
                              animated: animated)
    }

    private func setDefaultRegion() {
        let chamonix = CLLocationCoordinate2D(latitude: 45.9237, longitude: 6.8694)
        map.setRegion(MKCoordinateRegion(center: chamonix, latitudinalMeters: 3_200, longitudinalMeters: 3_200), animated: false)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let line = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: line)
        renderer.strokeColor = Palette.lime
        renderer.lineWidth = 4
        renderer.lineCap = .round
        renderer.lineJoin = .round
        return renderer
    }
}

struct RunLap {
    let index: Int
    let duration: TimeInterval
    let distanceMeters: Double
    let verticalMeters: Double
    let topSpeedKPH: Double
}

final class RunTrackerViewController: BaseViewController {
    private enum TrackerState {
        case idle
        case running
        case paused
        case finished
    }

    private let manager = CLLocationManager()
    private var state: TrackerState = .idle
    private var timer: Timer?
    private var elapsed: TimeInterval = 0
    private var segmentStart: Date?
    private var startedAt: Date?
    private var lastLocation: CLLocation?
    private var lastAltitude: Double?
    private var distanceMeters: Double = 0
    private var verticalMeters: Double = 0
    private var topSpeedKPH: Double = 0
    private var currentSpeedKPH: Double = 0
    private var lapTopSpeedKPH: Double = 0
    private var pendingStart = false
    private var lastSavedRun: RunRecord?
    private var didPost = false

    private var lapStartElapsed: TimeInterval = 0
    private var lapStartDistance: Double = 0
    private var lapStartVertical: Double = 0
    private var laps: [RunLap] = []

    private let timerLabel = UILabel(text: "00:00", font: SkesteFont.mono(58, weight: .light), color: Palette.text)
    private let metricVertical = UILabel(text: "0", font: SkesteFont.display(31), color: Palette.text)
    private let metricDistance = UILabel(text: "0", font: SkesteFont.display(31), color: Palette.text)
    private let metricSpeed = UILabel(text: "0", font: SkesteFont.display(31), color: Palette.text)
    private let liveSpeedLabel = UILabel(text: "NOW 0 KM/H", font: SkesteFont.demibold(7), color: Palette.cyan)
    private let gpsLabel = UILabel(text: "SEARCHING FOR SIGNAL", font: SkesteFont.demibold(8), color: Palette.amber)
    private let statusTitle = UILabel(text: "READY WHEN YOU ARE", font: SkesteFont.demibold(8), color: Palette.muted)
    private let trace = AltitudeTraceView()
    private let routeMap = RouteMapView()
    private let mainButton = GradientButton(title: "START RUN", icon: "play.fill", colors: SkesteGradient.lime, height: 54)
    private let lapButton = GhostButton(title: "MARK LAP", icon: "flag.fill", height: 44, tint: Palette.cyan, borderColor: Palette.cyan.withAlphaComponent(0.25))
    private let finishButton = GhostButton(title: "FINISH RUN", icon: "stop.fill", height: 48, tint: Palette.danger, borderColor: Palette.danger.withAlphaComponent(0.25))
    private let contentStack = UIStackView()
    private let scrollView = UIScrollView()

    private let recapCard = UIView()
    private let recapResort = UILabel(text: nil, font: SkesteFont.demibold(8), color: Palette.muted)
    private let recapVertical = UILabel(text: nil, font: SkesteFont.display(42), color: Palette.lime)
    private let recapDistance = UILabel(text: nil, font: SkesteFont.display(17), color: Palette.text)
    private let recapTime = UILabel(text: nil, font: SkesteFont.display(17), color: Palette.text)
    private let recapSpeed = UILabel(text: nil, font: SkesteFont.display(17), color: Palette.text)
    private let postButton = GhostButton(title: "POST TO FEED", icon: "paperplane.fill", height: 44, tint: Palette.magenta, borderColor: Palette.magenta.withAlphaComponent(0.25))
    private let splitsCard = UIView()
    private let splitsStack = UIStackView()
    private let recentStack = UIStackView()

    override func setupView() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 3
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
        buildHeader()
        buildContent()
        rebuildRecentRuns()
        updateInterface()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || navigationController?.isBeingDismissed == true {
            stopEverything()
        }
    }

    deinit {
        timer?.invalidate()
        manager.stopUpdatingLocation()
    }

    private func buildHeader() {
        let back = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        back.addAction(UIAction { [weak self] _ in
            self?.leave()
        }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }
        let label = UILabel(text: "RIDGE LAB  /  RUN TRACKER", font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.6)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(back)
        }
    }

    private func buildContent() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(60)
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-34)
            make.width.equalTo(scrollView.snp.width).offset(-AppLayout.screenPadding * 2)
        }

        let kicker = UILabel(text: "GPS DESCENT LOG", font: SkesteFont.demibold(8), color: Palette.lime)
        kicker.tracked(1.8)
        contentStack.addArrangedSubview(kicker)
        contentStack.setCustomSpacing(4, after: kicker)
        let title = UILabel(text: "LOG THE\nDESCENT.", font: SkesteFont.display(32), color: Palette.text, lines: 2)
        title.richTracking(-0.7)
        contentStack.addArrangedSubview(title)
        contentStack.setCustomSpacing(6, after: title)
        let subtitle = UILabel(text: "Real distance, speed, and vertical from your phone. Route, splits, and a recap card you can share with your crew.", font: SkesteFont.body(12), color: Palette.secondary, lines: 0)
        subtitle.lineSpacing(3)
        contentStack.addArrangedSubview(subtitle)
        contentStack.setCustomSpacing(14, after: subtitle)

        buildMap()
        buildDial()
        buildMetrics()
        buildActions()
        buildRecap()
        buildSplits()
        buildRecent()
    }

    private func buildMap() {
        let card = UIView()
        card.applyGlass(cornerRadius: 18, borderAlpha: 0.10, fill: Palette.glass)
        routeMap.layer.cornerRadius = 18
        routeMap.layer.cornerCurve = .continuous
        card.addSubview(routeMap)
        routeMap.snp.makeConstraints { $0.edges.equalToSuperview() }

        let shade = UIView()
        shade.backgroundColor = UIColor(hex: "05030F").withAlphaComponent(0.16)
        shade.isUserInteractionEnabled = false
        card.addSubview(shade)
        shade.snp.makeConstraints { $0.edges.equalToSuperview() }

        let fadeLayer = CAGradientLayer()
        fadeLayer.colors = [UIColor.clear.cgColor, Palette.canvas.cgColor]
        fadeLayer.startPoint = CGPoint(x: 0.5, y: 0)
        fadeLayer.endPoint = CGPoint(x: 0.5, y: 1)
        let fadeView = UIView()
        fadeView.isUserInteractionEnabled = false
        fadeView.layer.addSublayer(fadeLayer)
        card.addSubview(fadeView)
        fadeView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(74)
        }
        DispatchQueue.main.async {
            fadeLayer.frame = fadeView.bounds
        }

        let badge = UIView()
        badge.backgroundColor = UIColor(hex: "05030F").withAlphaComponent(0.55)
        badge.layer.cornerRadius = 9
        badge.layer.cornerCurve = .continuous
        let dot = UIView()
        dot.backgroundColor = Palette.lime
        dot.layer.cornerRadius = 3
        dot.applyGlow(color: Palette.lime, radius: 5, opacity: 0.8)
        badge.addSubview(dot)
        dot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(9)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(6)
        }
        let label = UILabel(text: "LIVE ROUTE", font: SkesteFont.demibold(7), color: Palette.lime)
        label.tracked(1.1)
        badge.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalTo(dot.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-9)
            make.centerY.equalToSuperview()
        }
        card.addSubview(badge)
        badge.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(10)
            make.height.equalTo(24)
        }

        card.snp.makeConstraints { $0.height.equalTo(200) }
        contentStack.addArrangedSubview(card)
        contentStack.setCustomSpacing(10, after: card)
    }

    private func buildDial() {
        let dial = UIView()
        dial.applyGlass(cornerRadius: 18, borderAlpha: 0.11, fill: Palette.glass)
        let topo = TopoLinesView()
        topo.lineColor = Palette.cyan.withAlphaComponent(0.06)
        dial.addSubview(topo)
        topo.snp.makeConstraints { $0.edges.equalToSuperview() }

        statusTitle.textAlignment = .center
        dial.addSubview(statusTitle)
        statusTitle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(30)
        }
        timerLabel.textAlignment = .center
        timerLabel.letterSpacing(1)
        dial.addSubview(timerLabel)
        timerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(statusTitle.snp.bottom).offset(4)
        }
        let elapsedLabel = UILabel(text: "ELAPSED", font: SkesteFont.demibold(7), color: Palette.muted)
        elapsedLabel.tracked(1.6)
        elapsedLabel.textAlignment = .center
        dial.addSubview(elapsedLabel)
        elapsedLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(timerLabel.snp.bottom).offset(-4)
        }

        gpsLabel.textAlignment = .center
        dial.addSubview(gpsLabel)
        gpsLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(elapsedLabel.snp.bottom).offset(14)
        }
        let pulseDot = UIView()
        pulseDot.backgroundColor = Palette.amber
        pulseDot.layer.cornerRadius = 2.5
        dial.addSubview(pulseDot)
        pulseDot.snp.makeConstraints { make in
            make.trailing.equalTo(gpsLabel.snp.leading).offset(-6)
            make.centerY.equalTo(gpsLabel)
            make.width.height.equalTo(5)
        }

        liveSpeedLabel.tracked(1.1)
        liveSpeedLabel.textAlignment = .center
        dial.addSubview(liveSpeedLabel)
        liveSpeedLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(gpsLabel.snp.bottom).offset(5)
        }

        let traceLabel = UILabel(text: "ALTITUDE TRACE", font: SkesteFont.demibold(7), color: Palette.muted)
        traceLabel.tracked(1.2)
        dial.addSubview(traceLabel)
        dial.addSubview(trace)
        traceLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.bottom.equalTo(trace.snp.top).offset(-6)
        }
        trace.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(54)
            make.bottom.equalToSuperview().offset(-16)
        }
        dial.snp.makeConstraints { make in
            make.height.equalTo(306)
        }
        contentStack.addArrangedSubview(dial)
        contentStack.setCustomSpacing(10, after: dial)
    }

    private func buildMetrics() {
        let metrics = UIStackView()
        metrics.axis = .horizontal
        metrics.spacing = 8
        metrics.distribution = .fillEqually
        contentStack.addArrangedSubview(metrics)
        contentStack.setCustomSpacing(14, after: metrics)
        metrics.addArrangedSubview(metricCard(value: metricVertical, unit: "M", label: "VERTICAL"))
        metrics.addArrangedSubview(metricCard(value: metricDistance, unit: "M", label: "DISTANCE"))
        metrics.addArrangedSubview(metricCard(value: metricSpeed, unit: "KM/H", label: "TOP SPEED"))
    }

    private func buildActions() {
        mainButton.addAction(UIAction { [weak self] _ in self?.mainAction() }, for: .touchUpInside)
        contentStack.addArrangedSubview(mainButton)
        contentStack.setCustomSpacing(8, after: mainButton)

        lapButton.addAction(UIAction { [weak self] _ in self?.markLap() }, for: .touchUpInside)
        lapButton.isHidden = true
        contentStack.addArrangedSubview(lapButton)
        contentStack.setCustomSpacing(8, after: lapButton)

        finishButton.addAction(UIAction { [weak self] _ in self?.finishRun() }, for: .touchUpInside)
        finishButton.isHidden = true
        contentStack.addArrangedSubview(finishButton)
        contentStack.setCustomSpacing(14, after: finishButton)
    }

    private func buildRecap() {
        recapCard.isHidden = true
        recapCard.applyGlass(cornerRadius: 18, borderAlpha: 0.12, fill: Palette.glass)
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 0
        recapCard.addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let kickerRow = UIStackView()
        kickerRow.axis = .horizontal
        kickerRow.alignment = .center
        kickerRow.spacing = 8
        let kicker = UILabel(text: "RUN RECAP", font: SkesteFont.demibold(8), color: Palette.lime)
        kicker.tracked(1.6)
        kickerRow.addArrangedSubview(kicker)
        recapResort.textAlignment = .right
        recapResort.tracked(0.8)
        kickerRow.addArrangedSubview(recapResort)
        content.addArrangedSubview(kickerRow)
        content.setCustomSpacing(6, after: kickerRow)

        let verticalRow = UIStackView()
        verticalRow.axis = .horizontal
        verticalRow.alignment = .lastBaseline
        verticalRow.spacing = 5
        verticalRow.addArrangedSubview(recapVertical)
        let m = UILabel(text: "M VERTICAL", font: SkesteFont.demibold(8), color: Palette.cyan)
        m.tracked(1.0)
        verticalRow.addArrangedSubview(m)
        content.addArrangedSubview(verticalRow)
        content.setCustomSpacing(10, after: verticalRow)

        let stats = UIStackView()
        stats.axis = .horizontal
        stats.distribution = .fillEqually
        stats.spacing = 6
        stats.addArrangedSubview(recapStat(title: "DISTANCE", label: recapDistance))
        stats.addArrangedSubview(recapStat(title: "TIME", label: recapTime))
        stats.addArrangedSubview(recapStat(title: "TOP SPEED", label: recapSpeed))
        content.addArrangedSubview(stats)
        content.setCustomSpacing(12, after: stats)

        let buttons = UIStackView()
        buttons.axis = .horizontal
        buttons.spacing = 8
        buttons.distribution = .fillEqually
        let share = GhostButton(title: "SHARE RECAP", icon: "square.and.arrow.up", height: 44, tint: Palette.cyan, borderColor: Palette.cyan.withAlphaComponent(0.25))
        share.addAction(UIAction { [weak self] _ in self?.shareRecap() }, for: .touchUpInside)
        postButton.addAction(UIAction { [weak self] _ in self?.postRecap() }, for: .touchUpInside)
        buttons.addArrangedSubview(share)
        buttons.addArrangedSubview(postButton)
        content.addArrangedSubview(buttons)
        content.setCustomSpacing(10, after: buttons)

        let log = SkesteControls.textButton("VIEW SEASON LOG →", tint: Palette.secondary, size: 8)
        log.addAction(UIAction { [weak self] _ in self?.push(RunLogViewController()) }, for: .touchUpInside)
        content.addArrangedSubview(log)

        contentStack.addArrangedSubview(recapCard)
        contentStack.setCustomSpacing(14, after: recapCard)
    }

    private func buildSplits() {
        splitsCard.isHidden = true
        splitsCard.applyGlass(cornerRadius: 18, borderAlpha: 0.08, fill: Palette.glass)
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 0
        splitsCard.addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        let kicker = UILabel(text: "SPLITS", font: SkesteFont.demibold(8), color: Palette.cyan)
        kicker.tracked(1.4)
        header.addArrangedSubview(kicker)
        let spacer = UIView()
        header.addArrangedSubview(spacer)
        let countLabel = UILabel(text: nil, font: SkesteFont.mono(8, weight: .bold), color: Palette.muted)
        countLabel.tag = 301
        header.addArrangedSubview(countLabel)
        content.addArrangedSubview(header)
        content.setCustomSpacing(8, after: header)

        splitsStack.axis = .vertical
        splitsStack.spacing = 5
        content.addArrangedSubview(splitsStack)

        contentStack.addArrangedSubview(splitsCard)
        contentStack.setCustomSpacing(14, after: splitsCard)
    }

    private func buildRecent() {
        let heading = SectionHeadingView(kicker: "From your season", title: "RECENT RUNS", actionTitle: "VIEW ALL") { [weak self] in
            self?.push(RunLogViewController())
        }
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(10, after: heading)

        recentStack.axis = .vertical
        recentStack.spacing = 7
        contentStack.addArrangedSubview(recentStack)
        contentStack.setCustomSpacing(16, after: recentStack)

        let note = UILabel(text: "The tracker uses GPS only while you run. Keep the phone close, give the sky a clear view, and stop the run before you celebrate.", font: SkesteFont.body(10), color: Palette.muted, lines: 0)
        note.textAlignment = .center
        note.lineSpacing(2)
        contentStack.addArrangedSubview(note)
    }

    private func metricCard(value: UILabel, unit: String, label: String) -> UIView {
        let card = UIView()
        card.applyGlass(cornerRadius: 18, borderAlpha: 0.08, fill: Palette.glass)
        value.textAlignment = .center
        card.addSubview(value)
        value.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
        }
        let unitLabel = UILabel(text: unit, font: SkesteFont.demibold(7), color: Palette.cyan)
        unitLabel.tracked(0.8)
        unitLabel.textAlignment = .center
        card.addSubview(unitLabel)
        unitLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(value.snp.bottom).offset(-2)
        }
        let labelLabel = UILabel(text: label, font: SkesteFont.demibold(7), color: Palette.muted)
        labelLabel.tracked(1.0)
        labelLabel.textAlignment = .center
        card.addSubview(labelLabel)
        labelLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(unitLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-10)
        }
        return card
    }

    private func recapStat(title: String, label: UILabel) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        label.textAlignment = .center
        stack.addArrangedSubview(label)
        let caption = UILabel(text: title, font: SkesteFont.demibold(6.5), color: Palette.muted)
        caption.tracked(0.9)
        caption.textAlignment = .center
        stack.addArrangedSubview(caption)
        return stack
    }

    // MARK: - State

    private func mainAction() {
        switch state {
        case .idle:
            beginTracking()
        case .running:
            pauseTracking()
        case .paused:
            resumeTracking()
        case .finished:
            resetTracking()
        }
    }

    private func beginTracking() {
        switch manager.authorizationStatus {
        case .notDetermined:
            pendingStart = true
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startTracking()
        default:
            showConfirm(title: "Location access is off", message: "Skeste needs your location during a tracked run to measure distance, speed, and vertical descent.", confirmTitle: "Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    private func startTracking() {
        guard state == .idle || state == .finished else { return }
        resetMetrics()
        state = .running
        startedAt = Date()
        segmentStart = Date()
        elapsed = 0
        manager.startUpdatingLocation()
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        updateInterface()
        SkesteHaptics.medium()
    }

    private func pauseTracking() {
        guard state == .running else { return }
        if let segmentStart {
            elapsed += Date().timeIntervalSince(segmentStart)
        }
        segmentStart = nil
        timer?.invalidate()
        timer = nil
        manager.stopUpdatingLocation()
        currentSpeedKPH = 0
        updateMetrics()
        state = .paused
        updateInterface()
        SkesteHaptics.light()
    }

    private func resumeTracking() {
        guard state == .paused else { return }
        segmentStart = Date()
        manager.startUpdatingLocation()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
        if let timer { RunLoop.main.add(timer, forMode: .common) }
        state = .running
        updateInterface()
        SkesteHaptics.light()
    }

    private func finishRun() {
        guard state == .running || state == .paused else { return }
        if state == .running, let segmentStart {
            elapsed += Date().timeIntervalSince(segmentStart)
        }
        segmentStart = nil
        timer?.invalidate()
        timer = nil
        manager.stopUpdatingLocation()
        guard elapsed >= 3 else {
            state = .paused
            updateInterface()
            showToast("Track a little longer to save this run.", style: .error)
            return
        }
        state = .finished
        let run = RunRecord(
            id: "run_\(UUID().uuidString)",
            startedAt: startedAt ?? Date().addingTimeInterval(-elapsed),
            duration: elapsed,
            distanceMeters: distanceMeters,
            verticalMeters: verticalMeters,
            topSpeedKPH: topSpeedKPH,
            resort: SKDataStore.shared.currentUser?.homeResort ?? "The mountain"
        )
        SKDataStore.shared.saveRun(run)
        lastSavedRun = run
        didPost = false
        postButton.title = "POST TO FEED"
        currentSpeedKPH = 0
        updateMetrics()
        updateRecap(run)
        rebuildRecentRuns()
        rebuildSplits()
        updateInterface()
        SkesteHaptics.success()
        showToast("Descent saved to your season log.", style: .success)
    }

    private func resetTracking() {
        stopEverything()
        resetMetrics()
        state = .idle
        updateInterface()
    }

    private func stopEverything() {
        timer?.invalidate()
        timer = nil
        segmentStart = nil
        manager.stopUpdatingLocation()
    }

    private func resetMetrics() {
        elapsed = 0
        startedAt = nil
        lastLocation = nil
        lastAltitude = nil
        distanceMeters = 0
        verticalMeters = 0
        topSpeedKPH = 0
        currentSpeedKPH = 0
        lapTopSpeedKPH = 0
        laps.removeAll()
        lapStartElapsed = 0
        lapStartDistance = 0
        lapStartVertical = 0
        trace.reset()
        routeMap.reset()
        updateMetrics(elapsedNow: 0)
        timerLabel.text = "00:00"
        liveSpeedLabel.text = "NOW 0 KM/H"
        splitsCard.isHidden = true
        recapCard.isHidden = true
        rebuildSplits()
    }

    @objc private func timerTick() {
        let current = currentElapsed()
        timerLabel.text = timeString(current)
        updateMetrics(elapsedNow: current)
    }

    private func currentElapsed() -> TimeInterval {
        var current = elapsed
        if let segmentStart { current += Date().timeIntervalSince(segmentStart) }
        return current
    }

    private func updateMetrics(elapsedNow: TimeInterval? = nil) {
        let current = elapsedNow ?? currentElapsed()
        timerLabel.text = timeString(current)
        metricVertical.text = "\(Int(verticalMeters.rounded()))"
        metricDistance.text = "\(Int(distanceMeters.rounded()))"
        metricSpeed.text = String(format: "%.0f", topSpeedKPH)
        liveSpeedLabel.text = "NOW \(Int(currentSpeedKPH.rounded())) KM/H"
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func updateInterface() {
        switch state {
        case .idle:
            statusTitle.text = "READY WHEN YOU ARE"
            statusTitle.textColor = Palette.muted
            gpsLabel.text = "SEARCHING FOR SIGNAL"
            gpsLabel.textColor = Palette.amber
            mainButton.title = "START RUN"
            mainButton.setColors(SkesteGradient.lime)
            mainButton.isHidden = false
            lapButton.isHidden = true
            finishButton.isHidden = true
            recapCard.isHidden = true
            timerLabel.text = "00:00"
        case .running:
            statusTitle.text = "TRACKING YOUR DESCENT"
            statusTitle.textColor = Palette.lime
            gpsLabel.text = "GPS LOCKED  ·  RECORDING"
            gpsLabel.textColor = Palette.lime
            mainButton.title = "PAUSE RUN"
            mainButton.setColors([Palette.amber, Palette.magenta])
            mainButton.isHidden = false
            lapButton.isHidden = false
            finishButton.isHidden = false
            recapCard.isHidden = true
        case .paused:
            statusTitle.text = "RUN PAUSED"
            statusTitle.textColor = Palette.amber
            gpsLabel.text = "TAKE YOUR TIME"
            gpsLabel.textColor = Palette.amber
            mainButton.title = "RESUME RUN"
            mainButton.setColors(SkesteGradient.lime)
            mainButton.isHidden = false
            lapButton.isHidden = true
            finishButton.isHidden = false
            recapCard.isHidden = true
        case .finished:
            statusTitle.text = "DESCENT SAVED"
            statusTitle.textColor = Palette.lime
            gpsLabel.text = "NICE WORK  ·  LOGGED"
            gpsLabel.textColor = Palette.lime
            mainButton.title = "NEW RUN"
            mainButton.setColors(SkesteGradient.signature)
            mainButton.isHidden = false
            lapButton.isHidden = true
            finishButton.isHidden = true
            recapCard.isHidden = false
        }
    }

    // MARK: - Laps

    private func markLap() {
        guard state == .running else { return }
        let duration = currentElapsed() - lapStartElapsed
        guard duration >= 2 else {
            showToast("A lap needs a few seconds of skiing.", style: .error)
            return
        }
        let lap = RunLap(index: laps.count + 1,
                         duration: duration,
                         distanceMeters: max(0, distanceMeters - lapStartDistance),
                         verticalMeters: max(0, verticalMeters - lapStartVertical),
                         topSpeedKPH: lapTopSpeedKPH)
        laps.append(lap)
        lapStartElapsed = currentElapsed()
        lapStartDistance = distanceMeters
        lapStartVertical = verticalMeters
        lapTopSpeedKPH = 0
        rebuildSplits()
        SkesteHaptics.success()
        showToast("Lap \(lap.index) marked.", style: .success)
    }

    private func rebuildSplits() {
        splitsStack.arrangedSubviews.forEach {
            splitsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard !laps.isEmpty else {
            splitsCard.isHidden = true
            return
        }
        if state == .finished {
            splitsCard.isHidden = false
        }
        if let count = splitsCard.viewWithTag(301) as? UILabel {
            count.text = laps.count == 1 ? "1 LAP" : "\(laps.count) LAPS"
        }
        for lap in laps {
            let row = UIView()
            row.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            row.layer.cornerRadius = 9
            row.layer.cornerCurve = .continuous
            let name = UILabel(text: String(format: "LAP %02d", lap.index), font: SkesteFont.mono(8, weight: .bold), color: Palette.cyan)
            row.addSubview(name)
            name.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(9)
                make.centerY.equalToSuperview()
            }
            let detail = UILabel(text: "\(durationText(lap.duration)) · \(Int(lap.distanceMeters.rounded())) m · \(Int(lap.verticalMeters.rounded())) m down · \(Int(lap.topSpeedKPH.rounded())) km/h", font: SkesteFont.mono(8, weight: .medium), color: Palette.secondary)
            detail.textAlignment = .right
            row.addSubview(detail)
            detail.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-9)
                make.leading.equalTo(name.snp.trailing).offset(8)
                make.centerY.equalToSuperview()
            }
            row.snp.makeConstraints { $0.height.equalTo(28) }
            splitsStack.addArrangedSubview(row)
        }
    }

    private func durationText(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // MARK: - Recap

    private func updateRecap(_ run: RunRecord) {
        recapResort.text = run.resort.uppercased()
        recapVertical.text = "\(Int(run.verticalMeters.rounded()))"
        recapDistance.text = run.distanceMeters >= 1000 ? String(format: "%.1f km", run.distanceMeters / 1000) : "\(Int(run.distanceMeters.rounded())) m"
        recapTime.text = timeString(run.duration)
        recapSpeed.text = "\(Int(run.topSpeedKPH.rounded())) km/h"
    }

    private func shareRecap() {
        guard let run = lastSavedRun else { return }
        let caption = "\(Int(run.verticalMeters.rounded())) m of vertical at \(run.resort). \(Int(run.distanceMeters.rounded())) m · \(timeString(run.duration)) · \(Int(run.topSpeedKPH.rounded())) km/h. — Ridge Lab"
        LabShare.present(image: LabShareCard.run(run, resortName: run.resort), text: caption, from: self)
        SkesteHaptics.light()
    }

    private func postRecap() {
        guard let run = lastSavedRun, !didPost else { return }
        let caption = "Logged \(Int(run.verticalMeters.rounded())) m of vertical at \(run.resort). \(Int(run.distanceMeters.rounded())) m · \(timeString(run.duration)) · \(Int(run.topSpeedKPH.rounded())) km/h. Season total: \(Int(SKDataStore.shared.totalVertical.rounded())) m. — Ridge Lab"
        LabShare.postToFeed(caption: caption, tags: ["RidgeLab", run.resort, "Descent"], from: self) { [weak self] success in
            guard let self, success else { return }
            self.didPost = true
            self.postButton.title = "POSTED"
            SkesteHaptics.success()
        }
    }

    private func rebuildRecentRuns() {
        recentStack.arrangedSubviews.forEach {
            recentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let runs = Array(SKDataStore.shared.runs.prefix(3))
        guard !runs.isEmpty else {
            let empty = UILabel(text: "No runs yet. Your next descent starts here.", font: SkesteFont.body(11), color: Palette.muted, lines: 0)
            recentStack.addArrangedSubview(empty)
            return
        }
        for run in runs {
            let row = UIView()
            row.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            row.layer.cornerRadius = 11
            row.layer.cornerCurve = .continuous
            let name = UILabel(text: run.resort, font: SkesteFont.demibold(11), color: Palette.text)
            row.addSubview(name)
            name.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(10)
                make.top.equalToSuperview().offset(8)
            }
            let detail = UILabel(text: "\(Int(run.verticalMeters.rounded())) m · \(Int(run.distanceMeters.rounded())) m · \(Int(run.topSpeedKPH.rounded())) km/h", font: SkesteFont.mono(7.5, weight: .medium), color: Palette.secondary)
            row.addSubview(detail)
            detail.snp.makeConstraints { make in
                make.leading.equalTo(name)
                make.top.equalTo(name.snp.bottom).offset(1)
                make.bottom.equalToSuperview().offset(-8)
            }
            let day = UILabel(text: run.startedAt.skesteRelative.uppercased(), font: SkesteFont.demibold(7), color: Palette.muted)
            day.tracked(1.0)
            row.addSubview(day)
            day.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-10)
                make.centerY.equalToSuperview()
            }
            recentStack.addArrangedSubview(row)
        }
    }

    private func leave() {
        if state == .running || state == .paused {
            showConfirm(title: "End this run?", message: "Your current descent will be discarded if you leave now.", confirmTitle: "Leave run", destructive: true) {
                self.stopEverything()
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            stopEverything()
            navigationController?.popViewController(animated: true)
        }
    }
}

extension RunTrackerViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard pendingStart else { return }
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            pendingStart = false
            startTracking()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            pendingStart = false
            showToast("Location access is needed to track a run.", style: .error)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard state == .running, let location = locations.last else { return }
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy < 60 else { return }
        gpsLabel.text = "GPS LOCKED  ·  RECORDING"
        gpsLabel.textColor = Palette.lime
        routeMap.append(location.coordinate)

        if let lastLocation {
            let delta = location.distance(from: lastLocation)
            if delta > 0, delta < 200 {
                distanceMeters += delta
                if location.speed > 0 {
                    currentSpeedKPH = location.speed * 3.6
                } else {
                    let interval = location.timestamp.timeIntervalSince(lastLocation.timestamp)
                    if interval > 0, interval < 20 {
                        currentSpeedKPH = (delta / interval) * 3.6
                    }
                }
                topSpeedKPH = max(topSpeedKPH, currentSpeedKPH)
                lapTopSpeedKPH = max(lapTopSpeedKPH, currentSpeedKPH)
            }
        }
        if let lastAltitude, location.verticalAccuracy >= 0, location.verticalAccuracy < 20 {
            let drop = lastAltitude - location.altitude
            if drop > 0.4, drop < 30 {
                verticalMeters += drop
            }
        }
        lastAltitude = location.altitude
        lastLocation = location
        trace.append(location.altitude)
        updateMetrics()
    }
}
