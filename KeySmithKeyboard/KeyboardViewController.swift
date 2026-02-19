import UIKit

// MARK: - Brand Colors (UIKit mirror of Theme.swift)

private enum KeyboardTheme {
    static let navyDark  = UIColor(red: 0x12/255, green: 0x18/255, blue: 0x45/255, alpha: 1)
    static let navyMid   = UIColor(red: 0x23/255, green: 0x30/255, blue: 0x64/255, alpha: 1)
    static let gold      = UIColor(red: 0xF5/255, green: 0xB7/255, blue: 0x31/255, alpha: 1)
    static let success   = UIColor(red: 0x34/255, green: 0xD3/255, blue: 0x99/255, alpha: 1)
    static let warning   = UIColor(red: 0xFB/255, green: 0xBF/255, blue: 0x24/255, alpha: 1)
    static let danger    = UIColor(red: 0xF4/255, green: 0x3F/255, blue: 0x5E/255, alpha: 1)

    /// Adaptive background — navy in dark mode, system light otherwise
    static func backgroundColor(for traitCollection: UITraitCollection) -> UIColor {
        traitCollection.userInterfaceStyle == .dark ? navyDark : .systemBackground
    }

    /// Adaptive secondary background
    static func secondaryBackground(for traitCollection: UITraitCollection) -> UIColor {
        traitCollection.userInterfaceStyle == .dark ? navyMid : .secondarySystemBackground
    }

    /// Primary text
    static func primaryText(for traitCollection: UITraitCollection) -> UIColor {
        traitCollection.userInterfaceStyle == .dark ? .white : .label
    }

    /// Secondary text
    static func secondaryText(for traitCollection: UITraitCollection) -> UIColor {
        traitCollection.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.7) : .secondaryLabel
    }

    /// Glass border
    static func glassBorder(for traitCollection: UITraitCollection) -> UIColor {
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.black.withAlphaComponent(0.06)
    }
}

// MARK: - KeyboardViewController

class KeyboardViewController: UIInputViewController {

    private var strengthButtons: [UIButton] = []
    private var passwordLabel: UILabel!
    private var containerView: UIView!
    private var selectedStrength: PasswordStrength = .strong
    private var currentLength: Int = 20

    // Glass layers
    private var blurView: UIVisualEffectView!
    private var passwordCardBlur: UIVisualEffectView!

    // Haptic generators
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    override func viewDidLoad() {
        super.viewDidLoad()
        selectionFeedback.prepare()
        impactFeedback.prepare()
        setupUI()
        generateAndDisplay()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyAdaptiveColors()
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Root container
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 260),
        ])

        // Frosted glass background (UIKit equivalent of .glassEffect)
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        containerView.insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        // Subtle top shadow line
        let topHighlight = UIView()
        topHighlight.translatesAutoresizingMaskIntoConstraints = false
        topHighlight.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        containerView.addSubview(topHighlight)
        NSLayoutConstraint.activate([
            topHighlight.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topHighlight.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topHighlight.topAnchor.constraint(equalTo: containerView.topAnchor),
            topHighlight.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        // ── Password display card ──────────────────────────────
        let passwordCard = UIView()
        passwordCard.translatesAutoresizingMaskIntoConstraints = false
        passwordCard.layer.cornerRadius = 14
        passwordCard.clipsToBounds = true
        passwordCard.layer.borderWidth = 0.5
        containerView.addSubview(passwordCard)

        // Card blur background
        passwordCardBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        passwordCardBlur.translatesAutoresizingMaskIntoConstraints = false
        passwordCard.insertSubview(passwordCardBlur, at: 0)
        NSLayoutConstraint.activate([
            passwordCardBlur.leadingAnchor.constraint(equalTo: passwordCard.leadingAnchor),
            passwordCardBlur.trailingAnchor.constraint(equalTo: passwordCard.trailingAnchor),
            passwordCardBlur.topAnchor.constraint(equalTo: passwordCard.topAnchor),
            passwordCardBlur.bottomAnchor.constraint(equalTo: passwordCard.bottomAnchor),
        ])

        passwordLabel = UILabel()
        passwordLabel.translatesAutoresizingMaskIntoConstraints = false
        passwordLabel.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
        passwordLabel.textAlignment = .center
        passwordLabel.numberOfLines = 2
        passwordLabel.adjustsFontSizeToFitWidth = true
        passwordLabel.minimumScaleFactor = 0.5
        passwordCard.addSubview(passwordLabel)

        NSLayoutConstraint.activate([
            passwordCard.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            passwordCard.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            passwordCard.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            passwordCard.heightAnchor.constraint(equalToConstant: 52),

            passwordLabel.leadingAnchor.constraint(equalTo: passwordCard.leadingAnchor, constant: 12),
            passwordLabel.trailingAnchor.constraint(equalTo: passwordCard.trailingAnchor, constant: -12),
            passwordLabel.topAnchor.constraint(equalTo: passwordCard.topAnchor),
            passwordLabel.bottomAnchor.constraint(equalTo: passwordCard.bottomAnchor),
        ])

        // ── Strength selector ──────────────────────────────────
        let strengthStack = UIStackView()
        strengthStack.translatesAutoresizingMaskIntoConstraints = false
        strengthStack.axis = .horizontal
        strengthStack.distribution = .fillEqually
        strengthStack.spacing = 6
        containerView.addSubview(strengthStack)

        NSLayoutConstraint.activate([
            strengthStack.topAnchor.constraint(equalTo: passwordCard.bottomAnchor, constant: 10),
            strengthStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            strengthStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            strengthStack.heightAnchor.constraint(equalToConstant: 34),
        ])

        for (i, strength) in PasswordStrength.allCases.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(strength.shortLabel, for: .normal)
            if let descriptor = UIFont.systemFont(ofSize: 11, weight: .semibold).fontDescriptor.withDesign(.rounded) {
                btn.titleLabel?.font = UIFont(descriptor: descriptor, size: 11)
            } else {
                btn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
            }
            btn.layer.cornerRadius = 10
            btn.clipsToBounds = true
            btn.layer.borderWidth = 0.5
            btn.tag = i
            btn.addTarget(self, action: #selector(strengthTapped(_:)), for: .touchUpInside)
            btn.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
            btn.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            strengthStack.addArrangedSubview(btn)
            strengthButtons.append(btn)
        }

        // ── Action buttons ─────────────────────────────────────
        let actionStack = UIStackView()
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        actionStack.axis = .horizontal
        actionStack.distribution = .fillEqually
        actionStack.spacing = 8
        containerView.addSubview(actionStack)

        NSLayoutConstraint.activate([
            actionStack.topAnchor.constraint(equalTo: strengthStack.bottomAnchor, constant: 10),
            actionStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            actionStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            actionStack.heightAnchor.constraint(equalToConstant: 42),
        ])

        let generateBtn = makeGlassActionButton(title: "Generate", icon: "arrow.triangle.2.circlepath")
        generateBtn.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        generateBtn.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        generateBtn.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        actionStack.addArrangedSubview(generateBtn)

        let insertBtn = makeGlassActionButton(title: "Insert", icon: "text.insert")
        insertBtn.addTarget(self, action: #selector(insertTapped), for: .touchUpInside)
        insertBtn.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        insertBtn.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        actionStack.addArrangedSubview(insertBtn)

        let copyBtn = makeGlassActionButton(title: "Copy", icon: "doc.on.doc")
        copyBtn.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        copyBtn.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        copyBtn.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        actionStack.addArrangedSubview(copyBtn)

        // ── Length controls ────────────────────────────────────
        let lengthStack = UIStackView()
        lengthStack.translatesAutoresizingMaskIntoConstraints = false
        lengthStack.axis = .horizontal
        lengthStack.distribution = .fill
        lengthStack.spacing = 12
        lengthStack.alignment = .center
        containerView.addSubview(lengthStack)

        NSLayoutConstraint.activate([
            lengthStack.topAnchor.constraint(equalTo: actionStack.bottomAnchor, constant: 10),
            lengthStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            lengthStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            lengthStack.heightAnchor.constraint(equalToConstant: 34),
        ])

        let minusBtn = UIButton(type: .system)
        minusBtn.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        minusBtn.tintColor = KeyboardTheme.gold
        minusBtn.addTarget(self, action: #selector(decreaseLength), for: .touchUpInside)
        minusBtn.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        minusBtn.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        lengthStack.addArrangedSubview(minusBtn)

        let lengthLabel = UILabel()
        lengthLabel.tag = 999
        if let descriptor = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium).fontDescriptor.withDesign(.rounded) {
            lengthLabel.font = UIFont(descriptor: descriptor, size: 14)
        } else {
            lengthLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        }
        lengthLabel.textAlignment = .center
        lengthStack.addArrangedSubview(lengthLabel)

        let plusBtn = UIButton(type: .system)
        plusBtn.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        plusBtn.tintColor = KeyboardTheme.gold
        plusBtn.addTarget(self, action: #selector(increaseLength), for: .touchUpInside)
        plusBtn.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        plusBtn.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        lengthStack.addArrangedSubview(plusBtn)

        // ── Bottom row (globe + delete) ───────────────────────
        let bottomStack = UIStackView()
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        bottomStack.axis = .horizontal
        bottomStack.distribution = .fill
        bottomStack.spacing = 8
        containerView.addSubview(bottomStack)

        NSLayoutConstraint.activate([
            bottomStack.topAnchor.constraint(equalTo: lengthStack.bottomAnchor, constant: 10),
            bottomStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            bottomStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            bottomStack.heightAnchor.constraint(equalToConstant: 34),
        ])

        let nextKeyboardBtn = UIButton(type: .system)
        nextKeyboardBtn.setImage(UIImage(systemName: "globe"), for: .normal)
        nextKeyboardBtn.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        nextKeyboardBtn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        bottomStack.addArrangedSubview(nextKeyboardBtn)

        let spacer = UIView()
        bottomStack.addArrangedSubview(spacer)

        let deleteBtn = UIButton(type: .system)
        deleteBtn.setImage(UIImage(systemName: "delete.left"), for: .normal)
        deleteBtn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteBtn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        bottomStack.addArrangedSubview(deleteBtn)

        // Apply colors and update state
        applyAdaptiveColors()
        updateStrengthButtons()
    }

    // MARK: - Glass Action Button Factory

    private func makeGlassActionButton(title: String, icon: String) -> UIButton {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon)?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        )
        config.imagePadding = 4
        config.cornerStyle = .large
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.12)
        config.baseForegroundColor = KeyboardTheme.gold
        config.background.strokeColor = UIColor.white.withAlphaComponent(0.18)
        config.background.strokeWidth = 0.5
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            if let descriptor = UIFont.systemFont(ofSize: 12, weight: .semibold).fontDescriptor.withDesign(.rounded) {
                outgoing.font = UIFont(descriptor: descriptor, size: 12)
            } else {
                outgoing.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            }
            return outgoing
        }
        btn.configuration = config
        return btn
    }

    // MARK: - Adaptive Color Application

    private func applyAdaptiveColors() {
        let tc = traitCollection

        // Container background tint behind the blur
        containerView.backgroundColor = KeyboardTheme.backgroundColor(for: tc).withAlphaComponent(0.5)

        // Password label
        passwordLabel.textColor = KeyboardTheme.primaryText(for: tc)
        if let card = passwordLabel.superview {
            card.layer.borderColor = KeyboardTheme.glassBorder(for: tc).cgColor
            card.backgroundColor = KeyboardTheme.secondaryBackground(for: tc).withAlphaComponent(0.3)
        }

        // Length label
        if let label = containerView.viewWithTag(999) as? UILabel {
            label.textColor = KeyboardTheme.secondaryText(for: tc)
        }

        // Strength button borders
        updateStrengthButtons()
    }

    // MARK: - Button Animation (scale + haptic)

    @objc private func buttonTouchDown(_ sender: UIButton) {
        impactFeedback.impactOccurred()
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn, .allowUserInteraction]) {
            sender.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }
    }

    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 3, options: .allowUserInteraction) {
            sender.transform = .identity
        }
    }

    // MARK: - Actions

    @objc private func strengthTapped(_ sender: UIButton) {
        selectionFeedback.selectionChanged()
        selectedStrength = PasswordStrength.allCases[sender.tag]
        currentLength = selectedStrength.defaultLength
        updateStrengthButtons()
        generateAndDisplay()
    }

    @objc private func generateTapped() {
        generateAndDisplay()
    }

    @objc private func insertTapped() {
        guard let text = passwordLabel.text, !text.isEmpty else { return }
        textDocumentProxy.insertText(text)
        flashFeedback(title: "Inserted!", color: KeyboardTheme.success)
    }

    @objc private func copyTapped() {
        guard let text = passwordLabel.text, !text.isEmpty else { return }
        UIPasteboard.general.setItems(
            [[UIPasteboard.typeAutomatic: text]],
            options: [.expirationDate: Date().addingTimeInterval(30)]
        )
        flashFeedback(title: "Copied!", color: KeyboardTheme.gold)
    }

    @objc private func deleteTapped() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func decreaseLength() {
        selectionFeedback.selectionChanged()
        if currentLength > 4 {
            currentLength -= 1
            generateAndDisplay()
        }
    }

    @objc private func increaseLength() {
        selectionFeedback.selectionChanged()
        if currentLength < 64 {
            currentLength += 1
            generateAndDisplay()
        }
    }

    // MARK: - Helpers

    private func generateAndDisplay() {
        let password: String

        if selectedStrength == .passphrase {
            password = PasswordGenerator.generatePassphrase(wordCount: currentLength)
        } else {
            var options = PasswordOptions()
            options.length = currentLength

            switch selectedStrength {
            case .pin:
                options.includeUppercase = false
                options.includeLowercase = false
                options.includeNumbers = true
                options.includeSymbols = false
            case .basic:
                options.includeSymbols = false
            case .strong, .paranoid:
                break
            case .passphrase:
                break
            }

            password = PasswordGenerator.generate(options: options)
        }

        // Animate password change
        UIView.transition(with: passwordLabel, duration: 0.15, options: .transitionCrossDissolve) {
            self.passwordLabel.text = password
        }
        updateLengthLabel()
    }

    private func updateStrengthButtons() {
        let tc = traitCollection
        let borderColor = KeyboardTheme.glassBorder(for: tc)
        let isDark = tc.userInterfaceStyle == .dark

        for (i, btn) in strengthButtons.enumerated() {
            let isSelected = i == PasswordStrength.allCases.firstIndex(of: selectedStrength)
            if isSelected {
                btn.backgroundColor = KeyboardTheme.gold
                btn.setTitleColor(KeyboardTheme.navyDark, for: .normal)
                btn.layer.borderColor = KeyboardTheme.gold.cgColor
            } else {
                btn.backgroundColor = isDark
                    ? UIColor.white.withAlphaComponent(0.08)
                    : UIColor.black.withAlphaComponent(0.04)
                btn.setTitleColor(KeyboardTheme.primaryText(for: tc), for: .normal)
                btn.layer.borderColor = borderColor.cgColor
            }
        }
    }

    private func updateLengthLabel() {
        if let label = containerView.viewWithTag(999) as? UILabel {
            label.text = "Length: \(currentLength)"
        }
    }

    private func flashFeedback(title: String, color: UIColor) {
        let flash = UILabel()
        flash.text = title
        if let descriptor = UIFont.systemFont(ofSize: 14, weight: .bold).fontDescriptor.withDesign(.rounded) {
            flash.font = UIFont(descriptor: descriptor, size: 14)
        } else {
            flash.font = .systemFont(ofSize: 14, weight: .bold)
        }
        flash.textColor = color
        flash.textAlignment = .center
        flash.translatesAutoresizingMaskIntoConstraints = false
        flash.alpha = 1
        containerView.addSubview(flash)
        flash.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        flash.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true

        UIView.animate(withDuration: 0.7, delay: 0.1, options: .curveEaseOut, animations: {
            flash.alpha = 0
            flash.transform = CGAffineTransform(translationX: 0, y: -24).scaledBy(x: 1.1, y: 1.1)
        }) { _ in
            flash.removeFromSuperview()
        }
    }
}
