import SwiftUI

// MARK: - Trim Handle View
/// ドラッグ可能なトリムハンドル
/// kikakusyo.md セクション7.3, 8.5 に準拠:
/// 「開始点・終了点ハンドル」「指に吸い付くように動く」

struct TrimHandleView: View {
    enum HandleType {
        case start
        case end
    }

    let type: HandleType
    let isActive: Bool

    private let handleWidth: CGFloat = 16
    private let handleHeight: CGFloat = 56

    var body: some View {
        ZStack {
            // ハンドル本体
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .frame(width: handleWidth, height: handleHeight)
                .overlay(
                    // グリップライン
                    VStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(AppTheme.background.opacity(0.5))
                                .frame(width: 8, height: 1.5)
                        }
                    }
                )
                .shadow(color: Color.white.opacity(isActive ? 0.8 : 0.4), radius: isActive ? 10 : 4)
                .scaleEffect(isActive ? 1.15 : 1.0)
                .animation(.spring(response: 0.2), value: isActive)

            // 方向インジケーター
            Image(systemName: type == .start ? "chevron.right" : "chevron.left")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(AppTheme.background)
                .offset(x: type == .start ? 1 : -1)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        HStack(spacing: 100) {
            TrimHandleView(type: .start, isActive: false)
            TrimHandleView(type: .end, isActive: true)
        }
    }
}
