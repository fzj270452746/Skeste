import UIKit
import SnapKit

final class LabSlider: UIView {
    private let titleLabel = UILabel(text: nil, font: SkesteFont.demibold(8), color: Palette.muted)
    private let valueLabel = UILabel(text: nil, font: SkesteFont.display(25), color: Palette.text)
    private let slider = UISlider()
    private let minimumLabel = UILabel(text: nil, font: SkesteFont.mono(7, weight: .medium), color: Palette.muted)
    private let maximumLabel = UILabel(text: nil, font: SkesteFont.mono(7, weight: .medium), color: Palette.muted)
    private(set) var value: Double
    private let minimum: Double
    private let maximum: Double
    private let formatter: (Double) -> String
    var onChange: ((Double) -> Void)?

    init(title: String, value: Double, range: ClosedRange<Double>, formatter: @escaping (Double) -> String, tint: UIColor = Palette.cyan) {
        self.value = value
        self.minimum = range.lowerBound
        self.maximum = range.upperBound
        self.formatter = formatter
        super.init(frame: .zero)
        titleLabel.text = title.uppercased()
        titleLabel.tracked(1.4)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
        }
        valueLabel.text = formatter(value)
        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.trailing.top.equalToSuperview()
            make.centerY.equalTo(titleLabel)
        }

        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
        slider.minimumTrackTintColor = tint
        slider.maximumTrackTintColor = Palette.hairline
        slider.thumbTintColor = Palette.text
        slider.addTarget(self, action: #selector(changed), for: .valueChanged)
        addSubview(slider)
        slider.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(7)
        }

        minimumLabel.text = formatter(range.lowerBound)
        addSubview(minimumLabel)
        minimumLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(2)
            make.top.equalTo(slider.snp.bottom).offset(1)
            make.bottom.equalToSuperview()
        }
        maximumLabel.text = formatter(range.upperBound)
        maximumLabel.textAlignment = .right
        addSubview(maximumLabel)
        maximumLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-2)
            make.centerY.equalTo(minimumLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func changed() {
        value = Double(slider.value)
        valueLabel.text = formatter(value)
        onChange?(value)
        SkesteHaptics.light()
    }

    func setValue(_ newValue: Double, notify: Bool) {
        value = min(max(newValue, minimum), maximum)
        slider.value = Float(value)
        valueLabel.text = formatter(value)
        if notify { onChange?(value) }
    }
}

final class LabInfoRow: UIView {
    private let titleLabel: UILabel
    private let valueLabel: UILabel

    init(title: String, value: String) {
        titleLabel = UILabel(text: title, font: SkesteFont.demibold(8), color: Palette.muted)
        valueLabel = UILabel(text: value, font: SkesteFont.medium(12), color: Palette.text, lines: 0)
        super.init(frame: .zero)
        titleLabel.tracked(1.1)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.equalTo(92)
        }
        valueLabel.textAlignment = .right
        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            make.trailing.top.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValue(_ value: String) {
        valueLabel.text = value
    }
}

final class LabHeader {
    static func add(to controller: UIViewController, title: String, trailingSymbol: String? = nil, trailingAction: (() -> Void)? = nil) -> UIButton? {
        let back = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        back.addAction(UIAction { _ in controller.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        controller.view.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(controller.view.safeAreaLayoutGuide.snp.top).offset(8)
        }
        let label = UILabel(text: title, font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.6)
        controller.view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(back)
        }
        guard let trailingSymbol else { return nil }
        let button = SkesteControls.iconButton(symbol: trailingSymbol, diameter: 40)
        if let trailingAction {
            button.addAction(UIAction { _ in trailingAction() }, for: .touchUpInside)
        }
        controller.view.addSubview(button)
        button.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.centerY.equalTo(back)
        }
        return button
    }

    static func addScroll(to controller: UIViewController) -> (UIScrollView, UIStackView) {
        let scroll = UIScrollView()
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        controller.view.addSubview(scroll)
        scroll.snp.makeConstraints { make in
            make.top.equalTo(controller.view.safeAreaLayoutGuide.snp.top).offset(60)
            make.leading.trailing.bottom.equalToSuperview()
        }
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        scroll.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-36)
            make.width.equalTo(scroll.snp.width).offset(-AppLayout.screenPadding * 2)
        }
        return (scroll, stack)
    }
}

final class LabCard: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGlass(cornerRadius: 14, borderAlpha: 0.10, fill: Palette.glass)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
