//
//  ActionButtonsMessageCell.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/28/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import MessageKit
import SnapKit

final class ActionButtonsMessageCell: UICollectionViewCell {
    private var stackView: UIStackView?

    func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard case .custom(let model) = message.kind, let buttonsModels = model as? [ActionButtonModel] else { return }

        let buttons: [UIView] = buttonsModels.map { model in
            let button = UIButton()
            button.setTitle(model.displayTitle, for: .normal)
            button.titleLabel?.textAlignment = .left
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.5
            button.snp.makeConstraints { make in
                make.height.equalTo(40)
            }
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            button.layer.cornerRadius = 20
            button.layer.masksToBounds = true
            button.layer.backgroundColor = UIColor(red: 128.0 / 255.0, green: 164.0 / 255.0, blue: 194.0 / 255.0, alpha: 0.6).cgColor

            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

            let wrapper = UIView()
            wrapper.addSubview(button)
            button.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview()
                make.bottom.equalToSuperview()
//                make.right.lessThanOrEqualToSuperview()
                make.right.equalToSuperview()
            }

            button.onTap { [weak messagesCollectionView] in
                messagesCollectionView?.messageCellDelegate?.didTapActionButton(with: model.action)
            }

            return wrapper
        }

        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .vertical
        stack.spacing = 5
        self.stackView = stack

        self.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.left.equalTo(self.snp.left).offset(48)
            make.right.equalTo(self.snp.right).offset(-48)
            make.centerY.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.stackView?.removeFromSuperview()
        self.stackView = nil
    }
}
