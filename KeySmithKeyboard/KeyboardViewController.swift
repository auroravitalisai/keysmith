import UIKit

class KeyboardViewController: UIInputViewController {

    private var strengthButtons: [UIButton] = []
    private var passwordLabel: UILabel!
    private var containerView: UIView!
    private var selectedStrength: PasswordStrength = .strong

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        generateAndDisplay()
    }

    private func setupUI() {
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 260)
        ])

        // Password display with refined styling
        passwordLabel = UILabel()
        passwordLabel.translatesAutoresizingMaskIntoConstraints = false
        passwordLabel.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
        passwordLabel.textAlignment = .center
        passwordLabel.numberOfLines = 2
        passwordLabel.adjustsFontSizeToFitWidth = true
        passwordLabel.minimumScaleFactor = 0.6
        passwordLabel.textColor = .label
        passwordLabel.backgroundColor = .tertiarySystemBackground
        passwordLabel.layer.cornerRadius = 16
        passwordLabel.clipsToBounds = true
        containerView.addSubview(passwordLabel)

        NSLayoutConstraint.activate([
            passwordLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            passwordLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            passwordLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            passwordLabel.heightAnchor.constraint(equalToConstant: 50),
        ])

        // Strength buttons
        let strengthStack = UIStackView()
        strengthStack.translatesAutoresizingMaskIntoConstraints = false
        strengthStack.axis = .horizontal
        strengthStack.distribution = .fillEqually
        strengthStack.spacing = 6
        containerView.addSubview(strengthStack)

        NSLayoutConstraint.activate([
            strengthStack.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor, constant: 10),
            strengthStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            strengthStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            strengthStack.heightAnchor.constraint(equalToConstant: 36),
        ])

        for strength in PasswordStrength.allCases {
            let btn = UIButton(type: .system)
            btn.setTitle(strength.rawValue, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            btn.layer.cornerRadius = 10
            btn.clipsToBounds = true
            btn.tag = PasswordStrength.allCases.firstIndex(of: strength)!
            btn.addTarget(self, action: #selector(strengthTapped(_:)), for: .touchUpInside)
            strengthStack.addArrangedSubview(btn)
            strengthButtons.append(btn)
        }

        // Action buttons
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
            actionStack.heightAnchor.constraint(equalToConstant: 44),
        ])

        let generateBtn = makeActionButton(title: "Generate", icon: "arrow.triangle.2.circlepath", color: .tintColor)
        generateBtn.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
        actionStack.addArrangedSubview(generateBtn)

        let insertBtn = makeActionButton(title: "Insert", icon: "text.insert", color: .systemGreen)
        insertBtn.addTarget(self, action: #selector(insertTapped), for: .touchUpInside)
        actionStack.addArrangedSubview(insertBtn)

        let copyBtn = makeActionButton(title: "Copy", icon: "doc.on.doc", color: .systemOrange)
        copyBtn.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        actionStack.addArrangedSubview(copyBtn)

        // Length controls
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
            lengthStack.heightAnchor.constraint(equalToConstant: 36),
        ])

        let minusBtn = UIButton(type: .system)
        minusBtn.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        minusBtn.tintColor = .secondaryLabel
        minusBtn.addTarget(self, action: #selector(decreaseLength), for: .touchUpInside)
        lengthStack.addArrangedSubview(minusBtn)

        let lengthLabel = UILabel()
        lengthLabel.tag = 999
        lengthLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        lengthLabel.textAlignment = .center
        lengthLabel.textColor = .label
        lengthStack.addArrangedSubview(lengthLabel)

        let plusBtn = UIButton(type: .system)
        plusBtn.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        plusBtn.tintColor = .secondaryLabel
        plusBtn.addTarget(self, action: #selector(increaseLength), for: .touchUpInside)
        lengthStack.addArrangedSubview(plusBtn)

        // Bottom row
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
            bottomStack.heightAnchor.constraint(equalToConstant: 36),
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
        deleteBtn.tintColor = .label
        deleteBtn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteBtn.widthAnchor.constraint(equalToConstant: 44).isActive = true
        bottomStack.addArrangedSubview(deleteBtn)

        updateStrengthButtons()
    }

    private func makeActionButton(title: String, icon: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 4
        config.cornerStyle = .large
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }
        btn.configuration = config
        return btn
    }

    private var currentLength: Int = 20

    // MARK: - Actions

    @objc private func strengthTapped(_ sender: UIButton) {
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
        flashButton(title: "Inserted!")
    }

    @objc private func copyTapped() {
        guard let text = passwordLabel.text, !text.isEmpty else { return }
        UIPasteboard.general.setItems(
            [[UIPasteboard.typeAutomatic: text]],
            options: [.expirationDate: Date().addingTimeInterval(30)]
        )
        flashButton(title: "Copied!")
    }

    @objc private func deleteTapped() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func decreaseLength() {
        if currentLength > 4 {
            currentLength -= 1
            generateAndDisplay()
        }
    }

    @objc private func increaseLength() {
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

        passwordLabel.text = password
        updateLengthLabel()
    }

    private func updateStrengthButtons() {
        for (i, btn) in strengthButtons.enumerated() {
            let isSelected = i == PasswordStrength.allCases.firstIndex(of: selectedStrength)
            btn.backgroundColor = isSelected ? .tintColor : .tertiarySystemBackground
            btn.setTitleColor(isSelected ? .white : .label, for: .normal)
        }
    }

    private func updateLengthLabel() {
        if let label = containerView.viewWithTag(999) as? UILabel {
            label.text = "Length: \(currentLength)"
        }
    }

    private func flashButton(title: String) {
        let flash = UILabel()
        flash.text = title
        flash.font = .systemFont(ofSize: 14, weight: .bold)
        flash.textColor = .systemGreen
        flash.textAlignment = .center
        flash.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(flash)
        flash.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        flash.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true

        UIView.animate(withDuration: 0.8, animations: {
            flash.alpha = 0
            flash.transform = CGAffineTransform(translationX: 0, y: -20)
        }) { _ in
            flash.removeFromSuperview()
        }
    }
}
