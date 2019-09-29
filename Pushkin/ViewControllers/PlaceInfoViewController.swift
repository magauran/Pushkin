//
//  PlaceInfoViewController.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/29/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import UIKit
import SwiftRichString

final class PlaceInfoViewController: UIViewController {
    private var pictureContainer = UIStackView()
    private var mapContainer = UIStackView()

    private let headerStyle = Style {
        $0.font = UIFont.boldSystemFont(ofSize: 24)
        $0.minimumLineHeight = 24
        $0.maximumLineHeight = 24
    }

    private let descriptionStyle = Style {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.minimumLineHeight = 16
        $0.maximumLineHeight = 16
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    private func setupUI() {
        self.view.backgroundColor = .white

        let scrollView = UIScrollView()
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let containerView = UIView()
        scrollView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        containerView.addSubview(self.pictureContainer)
        containerView.addSubview(self.mapContainer)

        self.setupPictureContainer()
        self.setupMapContainer()

        self.pictureContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-40)
        }

        self.mapContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).offset(-30)
            make.top.equalTo(self.pictureContainer.snp.bottom).offset(50)
            make.height.equalTo(self.pictureContainer)
        }
    }

    private func setupPictureContainer() {
        let pictureImageView = UIImageView()
        let pictureImage = UIImage(named: "picture")
        pictureImageView.image = pictureImage
        pictureImageView.contentMode = .scaleAspectFit

        let pictureTitleLabel = UILabel()
        pictureTitleLabel.attributedText = "Вы смотрите на".set(style: self.headerStyle)

        let pictureDescriptionLabel = UILabel()
        pictureDescriptionLabel.attributedText = "«Голубые танцовщицы» — пастель французского художника-импрессиониста Эдгара Дега, созданная в 1897 году.".set(style: self.descriptionStyle)
        pictureDescriptionLabel.numberOfLines = 0

        self.pictureContainer.addArrangedSubview(pictureImageView)
        self.pictureContainer.addArrangedSubview(pictureTitleLabel)
        self.pictureContainer.addArrangedSubview(pictureDescriptionLabel)

        self.pictureContainer.axis = .vertical
        self.pictureContainer.alignment = .center
        self.pictureContainer.distribution = .fill
        self.pictureContainer.spacing = 8

        pictureImageView.snp.makeConstraints { make in
            make.height.equalTo(300)
        }
    }

    private func setupMapContainer() {
        let mapImageView = UIImageView()
        let mapImage = UIImage(named: "map")
        mapImageView.image = mapImage
        mapImageView.contentMode = .scaleAspectFit

        let mapTitleLabel = UILabel()
        mapTitleLabel.attributedText = "Вы находитесь здесь".set(style: self.headerStyle)

        let mapDescriptionLabel = UILabel()
        mapDescriptionLabel.attributedText = "Галерея искусства стран Европы и Америки XIX–XX веков, Этаж 2, Зал 10".set(style: self.descriptionStyle)
        mapDescriptionLabel.numberOfLines = 0

        self.mapContainer.addArrangedSubview(mapImageView)
        self.mapContainer.addArrangedSubview(mapTitleLabel)
        self.mapContainer.addArrangedSubview(mapDescriptionLabel)

        self.mapContainer.axis = .vertical
        self.mapContainer.alignment = .center
        self.mapContainer.distribution = .fill
        self.mapContainer.spacing = 8

        mapImageView.snp.makeConstraints { make in
            make.height.equalTo(300)
        }
    }
}
