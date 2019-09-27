//
//  SpeechView.swift
//  Pushkin
//
//  Created by Alexey Salangin on 9/27/19.
//  Copyright © 2019 Alexey Salangin. All rights reserved.
//

import UIKit
import SwiftSiriWaveformView

final class SpeechView: UIView {
    private var timer: Timer?
    private var change: CGFloat = 0.01
    private var hue = 0
    private let siriWave = SwiftSiriWaveformView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.siriWave.backgroundColor = .white
        self.siriWave.primaryLineWidth = 5
        self.siriWave.secondaryLineWidth = 1.5
        self.siriWave.numberOfWaves = 15
        self.siriWave.idleAmplitude = 0.3
        self.addSubview(siriWave)

        self.siriWave.snp.makeConstraints { make in
            make.top.equalTo(self.snp.top)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
            make.left.equalTo(-10)
            make.right.equalTo(10)
        }
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            if self.siriWave.amplitude <= self.siriWave.idleAmplitude || self.siriWave.amplitude > 1 {
                self.change *= -1.0
            }
            self.siriWave.amplitude += self.change
            self.siriWave.waveColor = UIColor(hue: (CGFloat(self.hue % 1000)) / 1000, saturation: 1, brightness: 1, alpha: 1)
            self.hue += 1
        })

        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        self.timer?.invalidate()
        self.timer = nil
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
