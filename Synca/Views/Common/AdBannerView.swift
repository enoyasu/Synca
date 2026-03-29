import SwiftUI
import UIKit

// MARK: - AdMob Banner View
// Google Mobile Ads SDK が追加されるまではプレースホルダーを表示
// SDK追加後: `pod 'Google-Mobile-Ads-SDK'` を Podfile に追加し
// GADBannerView を使用するよう実装を差し替えてください。

struct AdBannerView: View {
    let isHidden: Bool   // 課金ユーザーは非表示

    private let bannerHeight: CGFloat = 50

    var body: some View {
        if isHidden {
            EmptyView()
        } else {
            AdBannerContainer()
                .frame(maxWidth: .infinity)
                .frame(height: bannerHeight)
        }
    }
}

// MARK: - UIViewRepresentable Container
private struct AdBannerContainer: UIViewRepresentable {
    // AdMob App ID (仮): ca-app-pub-3940256099942544~1458002511
    // Unit  ID  (仮): ca-app-pub-3940256099942544/2934735716
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716"

    func makeUIView(context: Context) -> UIView {
        // 本番実装では GADBannerView をここで初期化・ロードする
        // 現在はプレースホルダー UIView を返す
        let placeholder = makePlaceholderBanner()
        return placeholder
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func makePlaceholderBanner() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 0.1, alpha: 0.9)

        let label = UILabel()
        label.text = "広告スペース (AdMob)"
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }
}

// MARK: - Preview
#Preview {
    VStack {
        AdBannerView(isHidden: false)
        Spacer()
        AdBannerView(isHidden: true)
    }
    .background(Color.black)
}
