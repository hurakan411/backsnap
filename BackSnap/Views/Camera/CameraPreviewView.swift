import SwiftUI
import AVFoundation

// MARK: - Camera Preview View
/// AVCaptureVideoPreviewLayer を SwiftUI に橋渡しする UIViewRepresentable
/// シミュレータ環境の時は、動的にサイズが変化するダミー背景を表示します。

struct CameraPreviewView: View {
    let session: AVCaptureSession
    let zoomFactor: CGFloat

    var body: some View {
        CameraPreviewRepresentable(session: session)
            .ignoresSafeArea(.all) // セーフエリアを無視
            #if targetEnvironment(simulator)
            .scaleEffect(zoomFactor) // シミュレータの時は描画スケールを変えてズームを表現
            .animation(.easeInOut(duration: 0.15), value: zoomFactor)
            #endif
    }
}

private struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.contentScaleFactor = UIScreen.main.scale // Retinaの解像度スケールを適用
        #if !targetEnvironment(simulator)
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.contentsScale = UIScreen.main.scale // カメラレイヤー自体のRetinaスケールを適用
        #else
        view.setupSimulatorPlaceholder()
        #endif
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        #if !targetEnvironment(simulator)
        uiView.previewLayer.session = session
        #endif
    }
}

/// カメラプレビュー用の UIView
class CameraPreviewUIView: UIView {
    #if targetEnvironment(simulator)
    private var simulatorGradientLayer: CAGradientLayer?
    private var simulatorLabel: UILabel?
    #endif

    #if !targetEnvironment(simulator)
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    #endif

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 実際のレイアウトサイズをコンソールに出力して特定
        print("[CameraPreviewView] 📐 layoutSubviews - bounds = \(bounds), frame = \(frame)")
        
        #if !targetEnvironment(simulator)
        previewLayer.frame = bounds
        previewLayer.contentsScale = UIScreen.main.scale // レイアウト更新時にもRetinaスケールを同期
        
        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            if let windowScene = window?.windowScene {
                switch windowScene.interfaceOrientation {
                case .portrait:
                    connection.videoOrientation = .portrait
                case .portraitUpsideDown:
                    connection.videoOrientation = .portraitUpsideDown
                case .landscapeLeft:
                    connection.videoOrientation = .landscapeLeft
                case .landscapeRight:
                    connection.videoOrientation = .landscapeRight
                default:
                    break
                }
            }
        }
        #else
        // シミュレータ実行時は、サイズ確定後にグラデーションとラベルを全画面にフィットさせる
        if let gradient = simulatorGradientLayer {
            gradient.frame = bounds
        }
        if let label = simulatorLabel {
            label.center = CGPoint(x: bounds.midX, y: bounds.midY)
        }
        #endif
    }
    
    #if targetEnvironment(simulator)
    func setupSimulatorPlaceholder() {
        // グラデーションの作成
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.darkGray.cgColor,
            UIColor.black.cgColor,
            UIColor.darkGray.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradientLayer)
        self.simulatorGradientLayer = gradientLayer
        
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = [
            UIColor.darkGray.cgColor,
            UIColor.black.cgColor,
            UIColor.darkGray.cgColor
        ]
        animation.toValue = [
            UIColor.black.cgColor,
            UIColor.darkGray.cgColor,
            UIColor.black.cgColor
        ]
        animation.duration = 4.0
        animation.repeatCount = .infinity
        animation.autoreverses = true
        gradientLayer.add(animation, forKey: "colorChange")
        
        // テキストラベルの作成
        let label = UILabel()
        label.text = "🖥 SIMULATOR CAMERA"
        label.textColor = .white.withAlphaComponent(0.4)
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 0, width: 300, height: 50)
        addSubview(label)
        self.simulatorLabel = label
    }
    #endif
}
