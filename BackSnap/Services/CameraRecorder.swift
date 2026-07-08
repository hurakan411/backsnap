import SwiftUI
import AVFoundation

// MARK: - Camera Recorder
/// ビデオ録画管理サービス
/// 起動時からの自動録画開始、SNAPタップ時の即時停止＆ラグゼロ遷移を制御します。
/// シミュレータ環境を検知した場合は自動的にダミー映像をコピーし、Macシミュレータ上での動作テストを可能にします。

@Observable
final class CameraRecorder: NSObject, AVCaptureFileOutputRecordingDelegate {
    var isRecording = false
    var isReadyToStop = false
    var recordedSeconds: TimeInterval = 0
    
    /// 確定コピー（ファイナライズ）が完了した動画のパス（単一の真実のソースとしてReviewViewから監視されます）
    var finalizedVideoURL: URL? = nil

    private var cameraService: CameraService?
    private var currentVideoURL: URL?
    private var recordTimer: Timer?
    private var pendingStart = false // 録画再開時に前回の書き込み完了を待ってから開始するための予約フラグ

    /// 録画を開始
    func startRecording(cameraService: CameraService) {
        self.cameraService = cameraService
        self.finalizedVideoURL = nil // 新しい録画開始時にリセット
        
        #if targetEnvironment(simulator)
        // --- シミュレータ環境の動作 ---
        isRecording = true
        isReadyToStop = false
        recordedSeconds = 0
        
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("captured_\(UUID().uuidString).mov")
        self.currentVideoURL = fileURL
        
        // 画面操作中もタイマーが止まらないように .common モードで登録
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.recordedSeconds += 0.1
            if !self.isReadyToStop && self.recordedSeconds >= 1.0 {
                self.isReadyToStop = true
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.recordTimer = timer
        print("[CameraRecorder] 🖥 (Simulator) 自動録画開始: \(fileURL.lastPathComponent)")
        
        #else
        // --- 実機環境の動作 ---
        let movieOutput = cameraService.movieOutput
        
        // もし前回の録画ファイルの保存（ディスク書き出し）がまだ完了していない場合は、再開を予約する
        if movieOutput.isRecording {
            print("[CameraRecorder] ⚠️ 前回の録画書き出し処理が完了していないため、録画再開を予約します")
            pendingStart = true
            return
        }

        // 一時フォルダ直下にファイルを直接配置する
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("captured_\(UUID().uuidString).mov")
        self.currentVideoURL = fileURL

        isRecording = true
        isReadyToStop = false
        recordedSeconds = 0

        // 録画開始
        movieOutput.startRecording(to: fileURL, recordingDelegate: self)

        // ズームなどのUIジェスチャー中もタイマーを止めないように .common モードで登録
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.recordedSeconds += 0.1
            if !self.isReadyToStop && self.recordedSeconds >= 1.0 {
                self.isReadyToStop = true
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.recordTimer = timer
        print("[CameraRecorder] 🎬 自動録画開始: \(fileURL.lastPathComponent)")
        #endif
    }

    private var captureDuration: TimeInterval = 0

    /// 録画を即座に停止し、書き込み完了を待たずに動画URLとメタデータを即座に返す（ラグ0秒遷移用）
    func stopRecordingAndCaptureImmediate() -> RecordedVideo? {
        guard isRecording, let url = currentVideoURL else { return nil }
        
        isRecording = false
        isReadyToStop = false
        recordTimer?.invalidate()
        recordTimer = nil

        captureDuration = recordedSeconds
        recordedSeconds = 0

        #if targetEnvironment(simulator)
        // シミュレータ動作：事前自動生成された高精細ダミー動画を指定URLにコピーしてディスク出力を擬似シミュレート
        let dummyURL = SimulatorDummyVideoGenerator.shared.dummyVideoURL
        if FileManager.default.fileExists(atPath: dummyURL.path) {
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.copyItem(at: dummyURL, to: url)
            print("[CameraRecorder] 🖥 (Simulator) ダミー動画コピー成功: \(url.lastPathComponent)")
        }
        self.finalizedVideoURL = url // シミュレータ時は即時確定
        #else
        // 実機動作：物理カメラ録画停止指示
        cameraService?.movieOutput.stopRecording()
        #endif

        return RecordedVideo(
            videoURL: url,
            totalDuration: captureDuration,
            capturedAt: Date()
        )
    }

    /// 録画をキャンセル
    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        isReadyToStop = false
        recordTimer?.invalidate()
        recordTimer = nil
        pendingStart = false // キャンセル時は再開予約をクリア
        
        #if !targetEnvironment(simulator)
        cameraService?.movieOutput.stopRecording()
        #endif
        
        if let url = currentVideoURL {
            try? FileManager.default.removeItem(at: url)
        }
        currentVideoURL = nil
    }

    // MARK: - AVCaptureFileOutputRecordingDelegate (実機のみでコールバック)
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("[CameraRecorder] 🎬 AVCaptureFileOutput がディスク書き込みを開始しました")
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // 例外時や早期リターン時でも、このデリゲートを抜ける時に予約された録画再開があれば必ず開始する
        defer {
            if pendingStart, let service = self.cameraService {
                pendingStart = false
                print("[CameraRecorder] 🔄 予約されていた自動録画を開始します")
                DispatchQueue.main.async {
                    self.startRecording(cameraService: service)
                }
            }
        }

        // エラーが発生していても、書き込み自体が成功しているかを判定する（iOS公式準拠）
        var successfullyFinished = true
        if let error = error {
            print("[CameraRecorder] ⚠️ 録画ファイルの書き込み完了時に警告/エラーを検知: \(error.localizedDescription)")
            let nsError = error as NSError
            successfullyFinished = (nsError.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool) ?? false
        }
        
        guard successfullyFinished else {
            print("[CameraRecorder] ❌ 録画ファイルの保存に完全に失敗しました（再生不可）")
            NotificationCenter.default.post(name: .videoRecordingDidFail, object: nil, userInfo: ["url": outputFileURL])
            return
        }
        
        // 【重要】再生時間バグを回避するため、完全に書き込み終わったファイルを別のパスへ移動して確定（ファイナライズ）する
        let finalizedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("finalized_\(UUID().uuidString).mov")
        
        do {
            // moveItem はメタデータの書き換えのみなので 0.001秒で瞬時に終わります
            try FileManager.default.moveItem(at: outputFileURL, to: finalizedURL)
            print("[CameraRecorder] ✅ 録画ファイルを確定移動しました: \(finalizedURL.lastPathComponent)")
            
            // UIスレッドで状態を更新して ReviewView へ通知
            DispatchQueue.main.async {
                self.finalizedVideoURL = finalizedURL
            }
            
            // 完成通知も互換性のために残す
            NotificationCenter.default.post(
                name: .videoRecordingDidFinish,
                object: nil,
                userInfo: [
                    "url": outputFileURL,
                    "finalizedUrl": finalizedURL
                ]
            )
        } catch {
            print("[CameraRecorder] ⚠️ 確定移動失敗、元のURLを使用します: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.finalizedVideoURL = outputFileURL
            }
            
            NotificationCenter.default.post(
                name: .videoRecordingDidFinish,
                object: nil,
                userInfo: [
                    "url": outputFileURL,
                    "finalizedUrl": outputFileURL
                ]
            )
        }
    }
}

extension Notification.Name {
    static let videoRecordingDidFinish = Notification.Name("videoRecordingDidFinish")
    static let videoRecordingDidFail = Notification.Name("videoRecordingDidFail")
}

