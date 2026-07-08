import Foundation
import AVFoundation
import Observation
import UIKit

// MARK: - Video Resolution Enum
enum VideoResolution: String {
    case hd = "HD"
    case uhd = "4K"
}

// MARK: - Camera Service
/// AVFoundation カメラ制御サービス（シミュレータ対応版）
/// 実機では AVCaptureMovieFileOutput による録画を行い、
/// シミュレータではハードウェア初期化によるフリーズを防ぐため、処理を自動でバイパスします。

@Observable
final class CameraService: NSObject {
    // MARK: - Properties
    let captureSession = AVCaptureSession()
    private(set) var isSessionRunning = false
    private(set) var currentCameraPosition: AVCaptureDevice.Position = .back
    private(set) var isAuthorized = false
    var zoomFactor: CGFloat = 1.0

    // 解像度とフレームレートの状態
    var activeResolution: VideoResolution = .hd
    var activeFPS: Int = 30
    
    // ライト（トーチ）制御の状態
    var isTorchOn = false

    #if !targetEnvironment(simulator)
    /// ムービー出力 (実機のみ)
    let movieOutput = AVCaptureMovieFileOutput()
    #endif
    
    /// 現在のセッションでアクティブなビデオ入力デバイス
    var activeDevice: AVCaptureDevice? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return (captureSession.inputs.first(where: { input in
            guard let deviceInput = input as? AVCaptureDeviceInput else { return false }
            return deviceInput.device.hasMediaType(.video)
        }) as? AVCaptureDeviceInput)?.device
        #endif
    }

    /// セッション設定キュー
    private let sessionQueue = DispatchQueue(label: "com.backsnap.camera.session")

    // MARK: - Authorization
    func checkPermissions() async -> Bool {
        #if targetEnvironment(simulator)
        await MainActor.run {
            self.isAuthorized = true
        }
        return true
        #else
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        var videoGranted = videoStatus == .authorized
        var audioGranted = audioStatus == .authorized

        if videoStatus == .notDetermined {
            videoGranted = await AVCaptureDevice.requestAccess(for: .video)
        }
        if audioStatus == .notDetermined {
            audioGranted = await AVCaptureDevice.requestAccess(for: .audio)
        }

        let authorized = videoGranted && audioGranted
        await MainActor.run {
            self.isAuthorized = authorized
        }
        return authorized
        #endif
    }

    // MARK: - Session Configuration
    func configureSession() async {
        #if targetEnvironment(simulator)
        print("[CameraService] 🖥 (Simulator) セッション設定をスキップ")
        #else
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume()
                    return
                }

                self.captureSession.beginConfiguration()

                // 解像度 (Session Preset) の設定
                let preset: AVCaptureSession.Preset = (self.activeResolution == .hd) ? .hd1920x1080 : .hd4K3840x2160
                if self.captureSession.canSetSessionPreset(preset) {
                    self.captureSession.sessionPreset = preset
                } else {
                    self.captureSession.sessionPreset = .hd1920x1080
                }

                // 既存の入出力をクリア
                for input in self.captureSession.inputs {
                    self.captureSession.removeInput(input)
                }
                for output in self.captureSession.outputs {
                    self.captureSession.removeOutput(output)
                }

                // ビデオ入力 (超広角0.5xに対応するため、トリプル/デュアル広角を優先探索)
                let deviceTypes: [AVCaptureDevice.DeviceType] = [
                    .builtInTripleCamera,
                    .builtInDualWideCamera,
                    .builtInWideAngleCamera
                ]
                let discoverySession = AVCaptureDevice.DiscoverySession(
                    deviceTypes: deviceTypes,
                    mediaType: .video,
                    position: self.currentCameraPosition
                )
                
                if let camera = discoverySession.devices.first {
                    if let input = try? AVCaptureDeviceInput(device: camera),
                       self.captureSession.canAddInput(input) {
                        self.captureSession.addInput(input)
                        print("[CameraService] ✅ ビデオ入力追加: \(camera.localizedName)")
                        
                        // 高画質化 (オートフォーカス、自動露出、自動ホワイトバランス、HDR)
                        self.setupHighQualitySettings(device: camera)
                        
                        // 初期フレームレートを適用
                        self.applyFPSToDevice(device: camera, fps: self.activeFPS)
                    }
                }

                // マイク（オーディオ）入力の追加
                if let audioDevice = AVCaptureDevice.default(for: .audio) {
                    if let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
                       self.captureSession.canAddInput(audioInput) {
                        self.captureSession.addInput(audioInput)
                        print("[CameraService] ✅ オーディオ入力追加")
                    } else {
                        print("[CameraService] ⚠️ オーディオ入力を追加できませんでした")
                    }
                }

                // ムービー出力
                if self.captureSession.canAddOutput(self.movieOutput) {
                    self.captureSession.addOutput(self.movieOutput)
                    print("[CameraService] ✅ ムービー出力追加")
                }

                // コネクションの画質と手ぶれ補正を設定
                self.configureMovieOutputConnection()

                self.captureSession.commitConfiguration()
                print("[CameraService] ✅ セッション設定完了: 解像度=\(self.activeResolution.rawValue), FPS=\(self.activeFPS)")
                
                // 【重要】初期ズームを明示的に1.0x（マルチカメラなら内部2.0倍）に設定し、画角のズレを防ぐ
                self.setZoomFactor(1.0)
                
                continuation.resume()
            }
        }
        #endif
    }

    func startSession() {
        #if targetEnvironment(simulator)
        self.isSessionRunning = true
        print("[CameraService] 🖥 (Simulator) ダミーセッション開始")
        #else
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = true
                print("[CameraService] ✅ セッション開始")
            }
        }
        #endif
    }

    // MARK: - Configure Connection settings (Stabilization & Codec)
    /// ムービー出力のコネクションに対して、HEVCコーデックや高度な手ブレ補正を適用します（セッション再構成のたびに呼ぶ必要があります）
    private func configureMovieOutputConnection() {
        #if !targetEnvironment(simulator)
        guard let connection = self.movieOutput.connection(with: .video) else {
            print("[CameraService] ⚠️ ビデオコネクションが見つかりません。設定をスキップします。")
            return
        }
        
        // 1. 映画級の超強力なビデオ手ぶれ補正を優先適用（映像のブレを完全に抑えシャープにします）
        if connection.isVideoStabilizationSupported {
            // 現在の入力カメラデバイスのアクティブなフォーマットからサポート状況を取得する
            if let activeInput = self.captureSession.inputs.first(where: {
                ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.video) == true
            }) as? AVCaptureDeviceInput {
                let format = activeInput.device.activeFormat
                
                if format.isVideoStabilizationModeSupported(.cinematicExtended) {
                    connection.preferredVideoStabilizationMode = .cinematicExtended
                    print("[CameraService] ✨ ビデオ手ぶれ補正(.cinematicExtended)を適用")
                } else if format.isVideoStabilizationModeSupported(.cinematic) {
                    connection.preferredVideoStabilizationMode = .cinematic
                    print("[CameraService] ✨ ビデオ手ぶれ補正(.cinematic)を適用")
                } else {
                    connection.preferredVideoStabilizationMode = .auto
                    print("[CameraService] ✨ ビデオ手ぶれ補正(.auto)を適用")
                }
            } else {
                connection.preferredVideoStabilizationMode = .auto
                print("[CameraService] ✨ ビデオ手ぶれ補正(.auto)を適用（デバイスが見つからないため）")
            }
        }
        
        // 2. 高画質な HEVC (H.265) コーデックを明示的に適用（ザラつきのない滑らかな画質にします）
        if self.movieOutput.availableVideoCodecTypes.contains(.hevc) {
            let settings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc
            ]
            self.movieOutput.setOutputSettings(settings, for: connection)
            print("[CameraService] ✨ 高画質な HEVC (H.265) コーデックを接続に設定しました")
        }
        #endif
    }

    func stopSession() {
        #if targetEnvironment(simulator)
        self.isSessionRunning = false
        self.isTorchOn = false
        print("[CameraService] 🖥 (Simulator) ダミーセッション停止")
        #else
        sessionQueue.async { [weak self] in
            guard let self else { return }
            // セッション停止前にトーチを消灯
            if let device = self.activeDevice, device.hasTorch, device.torchMode == .on {
                try? device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            }
            guard self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
                self.isTorchOn = false
            }
        }
        #endif
    }

    // MARK: - Camera Switching
    func switchCamera() {
        #if targetEnvironment(simulator)
        self.currentCameraPosition = (self.currentCameraPosition == .back) ? .front : .back
        self.isTorchOn = false
        print("[CameraService] 🖥 (Simulator) カメラ切り替え: \(self.currentCameraPosition == .back ? "背面" : "前面")")
        #else
        sessionQueue.async { [weak self] in
            guard let self else { return }
            // 切り替え前にトーチを一旦消灯
            if let device = self.activeDevice, device.hasTorch, device.torchMode == .on {
                try? device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            }
            DispatchQueue.main.async {
                self.isTorchOn = false
            }
            self.currentCameraPosition = (self.currentCameraPosition == .back) ? .front : .back

            self.captureSession.beginConfiguration()

            // 既存のビデオ入力を削除
            if let currentInput = self.captureSession.inputs.first(where: {
                ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.video) == true
            }) {
                self.captureSession.removeInput(currentInput)
            }

            let deviceTypes: [AVCaptureDevice.DeviceType] = [
                .builtInTripleCamera,
                .builtInDualWideCamera,
                .builtInWideAngleCamera
            ]
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: self.currentCameraPosition
            )

            if let camera = discoverySession.devices.first,
               let input = try? AVCaptureDeviceInput(device: camera),
               self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                
                // 切り替え後も高画質化を適用
                self.setupHighQualitySettings(device: camera)
                
                self.applyFPSToDevice(device: camera, fps: self.activeFPS)
            }

            // 【重要】カメラ切り替えで新しく作成されたコネクションに高画質設定を再適用
            self.configureMovieOutputConnection()
            
            // 【重要】切り替え後に初期ズームを再適用してズレを防ぐ
            self.setZoomFactor(1.0)

            self.captureSession.commitConfiguration()
        }
        #endif
    }

    // MARK: - Torch Control
    func toggleTorch() {
        #if targetEnvironment(simulator)
        isTorchOn.toggle()
        print("[CameraService] 🖥 (Simulator) トーチ切り替え: \(isTorchOn ? "オン" : "オフ")")
        #else
        guard let device = activeDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                isTorchOn = false
            } else {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                isTorchOn = true
            }
            device.unlockForConfiguration()
        } catch {
            print("[CameraService] 🔦 トーチの切り替えに失敗: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - Zoom Control
    func setZoomFactor(_ factor: CGFloat) {
        #if !targetEnvironment(simulator)
        sessionQueue.async { [weak self] in
            guard let self else { return }
            // 現在のビデオインプットを取得
            guard let input = self.captureSession.inputs.first(where: {
                ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.video) == true
            }) as? AVCaptureDeviceInput else { return }
            
            let device = input.device
            
            // 超広角(0.5x)を含む統合デバイスであるかを判定
            let isMultiCamera = device.deviceType == .builtInTripleCamera || device.deviceType == .builtInDualWideCamera
            
            // 画面上の表示倍率(factor)をデバイス内部のビデオズーム倍率に変換
            let targetDeviceZoom = isMultiCamera ? (factor * 2.0) : factor
            
            // デバイスが許容する範囲内で安全にクランプ
            let minZoom = device.minAvailableVideoZoomFactor
            let maxZoom = min(device.maxAvailableVideoZoomFactor, 20.0)
            let clampedDeviceZoom = max(minZoom, min(targetDeviceZoom, maxZoom))
            
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() } // どんなエラーがあっても確実にロックを解除
                
                device.videoZoomFactor = clampedDeviceZoom
                
                DispatchQueue.main.async {
                    self.zoomFactor = isMultiCamera ? (clampedDeviceZoom / 2.0) : clampedDeviceZoom
                }
            } catch {
                print("[CameraService] ⚠️ ズーム設定失敗: \(error.localizedDescription)")
            }
        }
        #else
        // シミュレータ時は 0.5x〜10.0x の範囲で自由に設定可能
        let clamped = max(0.5, min(factor, 10.0))
        self.zoomFactor = clamped
        #endif
    }

    // MARK: - Dynamic Configuration (Resolution / FPS)
    func setResolution(_ resolution: VideoResolution) {
        setVideoConfiguration(resolution: resolution, fps: activeFPS)
    }

    func setFPS(_ fps: Int) {
        setVideoConfiguration(resolution: activeResolution, fps: fps)
    }

    private func setVideoConfiguration(resolution: VideoResolution, fps: Int) {
        #if !targetEnvironment(simulator)
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.captureSession.beginConfiguration()

            // 1. 解像度プリセットの適用
            let preset: AVCaptureSession.Preset = (resolution == .hd) ? .hd1920x1080 : .hd4K3840x2160
            if self.captureSession.canSetSessionPreset(preset) {
                self.captureSession.sessionPreset = preset
            }

            // 2. フレームレート (FPS) の適用
            if let input = self.captureSession.inputs.first(where: {
                ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.video) == true
            }) as? AVCaptureDeviceInput {
                self.applyFPSToDevice(device: input.device, fps: fps)
            }

            // 【重要】解像度やFPS設定変更によるコネクション再構成時にも高画質設定を再適用
            self.configureMovieOutputConnection()

            self.captureSession.commitConfiguration()
            print("[CameraService] ⚙️ 動的設定変更: 解像度=\(resolution.rawValue), FPS=\(fps)")

            DispatchQueue.main.async {
                self.activeResolution = resolution
                self.activeFPS = fps
            }
        }
        #else
        self.activeResolution = resolution
        self.activeFPS = fps
        #endif
    }

    // MARK: - Quality Configuration Helper Methods
    private func setupHighQualitySettings(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            // 1. 連続オートフォーカスの有効化 (ピントの自動調整)
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

            // 2. 連続自動露出の有効化 (明るさの自動調整)
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }

            // 3. 連続自動ホワイトバランスの有効化 (色味の自動調整)
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }

            // 4. 自動ビデオHDR (High Dynamic Range) の有効化 (白飛びや黒潰れを防ぎ精細化)
            if device.activeFormat.isVideoHDRSupported {
                if !device.automaticallyAdjustsVideoHDREnabled {
                    device.automaticallyAdjustsVideoHDREnabled = true
                }
                print("[CameraService] ✨ 自動ビデオHDRを有効化しました (システム自動制御)")
            }
        } catch {
            print("[CameraService] ⚠️ デバイスの初期画質設定失敗: \(error.localizedDescription)")
        }
    }

    private func applyFPSToDevice(device: AVCaptureDevice, fps: Int) {
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            let duration = CMTimeMake(value: 1, timescale: Int32(fps))
            
            // 指定FPSが現在のフォーマットでサポートされているか確認
            let supportsFPS = device.activeFormat.videoSupportedFrameRateRanges.contains { range in
                range.minFrameRate <= Double(fps) && Double(fps) <= range.maxFrameRate
            }

            if supportsFPS {
                device.activeVideoMinFrameDuration = duration
                device.activeVideoMaxFrameDuration = duration
                print("[CameraService] 🎯 FPSを設定しました: \(fps)")
            } else {
                // 30fpsをフォールバックに設定
                let fallbackDuration = CMTimeMake(value: 1, timescale: 30)
                device.activeVideoMinFrameDuration = fallbackDuration
                device.activeVideoMaxFrameDuration = fallbackDuration
                print("[CameraService] ⚠️ 指定FPS(\(fps))は非対応です。30fpsを設定しました。")
            }
        } catch {
            print("[CameraService] ⚠️ デバイスのフレームレート設定失敗: \(error)")
        }
    }

    /// 指定された画面上の座標にタップフォーカスと自動露出を適用
    func focus(at point: CGPoint, in size: CGSize) {
        #if !targetEnvironment(simulator)
        guard let device = activeDevice else {
            print("[CameraService] ⚠️ アクティブなビデオデバイスが見つかりません")
            return
        }
        
        // 画面の座標系からカメラセンサーの座標系（0.0 〜 1.0）へマッピングを変換
        // ポートレートかつ背面カメラ基準
        var devicePoint = CGPoint(x: point.y / size.height, y: 1.0 - (point.x / size.width))
        
        // 前面カメラ（インカメラ）の場合は左右反転を考慮
        if currentCameraPosition == .front {
            devicePoint.y = point.x / size.width
        }
        
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            
            // フォーカスポイント (ピント) の設定
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                device.focusPointOfInterest = devicePoint
                device.focusMode = .autoFocus
            }
            
            // 2. 露出ポイント (明るさ) の設定
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                device.exposurePointOfInterest = devicePoint
                device.exposureMode = .autoExpose
            }
            
            // ホワイトバランスも追従させたい場合は continuousAutoWhiteBalance を維持
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            print("[CameraService] 🎯 タップフォーカスを適用しました: センサー座標 \(devicePoint)")
        } catch {
            print("[CameraService] ⚠️ タップフォーカスの適用に失敗: \(error.localizedDescription)")
        }
        #else
        print("[CameraService] 🖥 (Simulator) タップフォーカス模擬: \(point)")
        #endif
    }
}
