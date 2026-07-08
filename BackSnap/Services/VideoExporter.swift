import Foundation
import AVFoundation
import Photos
import UIKit

// MARK: - Video Exporter
/// 動画切り出し・保存・共有サービス
/// kikakusyo.md セクション7.3, 10 動画切り出しに準拠

final class VideoExporter {

    // MARK: - Export (Trim)
    /// 動画を指定範囲で切り出し
    func exportClip(
        from sourceURL: URL,
        startTime: TimeInterval,
        endTime: TimeInterval
    ) async -> URL? {
        let asset = AVURLAsset(url: sourceURL)

        // 【最適化】再圧縮を行わない「パススルー」モードにすることで、画質劣化ゼロで一瞬（0.1秒以下）で切り出しが完了します
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            print("[VideoExporter] ExportSession の作成に失敗")
            return nil
        }

        let outputURL = URL.temporaryVideoURL()
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov

        let start = CMTime(seconds: startTime, preferredTimescale: 600)
        let end = CMTime(seconds: endTime, preferredTimescale: 600)
        exportSession.timeRange = CMTimeRange(start: start, end: end)

        // Swift Concurrency の await export() は一部iOSバージョンでメインスレッドをブロックするバグがあるため、
        // 古典的な非同期コールバックをブリッジしてバックグラウンドスレッドで安全に実行します
        return await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    print("[VideoExporter] ✅ 動画の切り出しに成功しました: \(outputURL.lastPathComponent)")
                    continuation.resume(returning: outputURL)
                case .failed:
                    print("[VideoExporter] ❌ 書き出し失敗: \(String(describing: exportSession.error?.localizedDescription))")
                    continuation.resume(returning: nil)
                case .cancelled:
                    print("[VideoExporter] ⚠️ 書き出しキャンセル")
                    continuation.resume(returning: nil)
                default:
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - Save to Camera Roll
    /// 動画をカメラロールに保存
    func saveToPhotoLibrary(url: URL) async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        if status == .notDetermined {
            let granted = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard granted == .authorized || granted == .limited else { return false }
        } else if status != .authorized && status != .limited {
            return false
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.forAsset()
                    .addResource(with: .video, fileURL: url, options: nil)
            }
            return true
        } catch {
            print("[VideoExporter] 保存エラー: \(error)")
            return false
        }
    }

    // MARK: - Save to Local Documents
    /// アプリ内の Documents/Clips フォルダに複製保存（ローカルライブラリ用）
    func saveToLocalDocuments(url: URL) -> URL? {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let clipsDir = documentsDir.appendingPathComponent("Clips", isDirectory: true)
        
        try? fileManager.createDirectory(at: clipsDir, withIntermediateDirectories: true)
        
        let destinationURL = clipsDir.appendingPathComponent(url.lastPathComponent)
        try? fileManager.removeItem(at: destinationURL)
        do {
            try fileManager.copyItem(at: url, to: destinationURL)
            print("[VideoExporter] アプリ内ローカルライブラリに保存成功: \(destinationURL.path)")
            return destinationURL
        } catch {
            print("[VideoExporter] アプリ内ローカルライブラリへの保存失敗: \(error)")
            return nil
        }
    }

    // MARK: - Share
    /// 共有シートを表示
    @MainActor
    func share(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("[VideoExporter] ⚠️ UIWindowSceneまたはRootViewControllerが見つかりません")
            return
        }

        // iPad等でのクラッシュ・フリーズを防ぐため、安全な画面中央をポップオーバーの起点に設定
        activityVC.popoverPresentationController?.sourceView = rootVC.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(
            x: rootVC.view.bounds.midX,
            y: rootVC.view.bounds.midY,
            width: 0,
            height: 0
        )
        activityVC.popoverPresentationController?.permittedArrowDirections = []

        // すでに表示中のモーダル（ReviewViewなど）があれば、その最前面のVCから表示
        var presenter = rootVC
        while let presented = presenter.presentedViewController {
            presenter = presented
        }

        presenter.present(activityVC, animated: true)
    }

    // MARK: - Share Image
    /// 共有シートで画像を共有
    @MainActor
    func share(image: UIImage) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("[VideoExporter] ⚠️ UIWindowSceneまたはRootViewControllerが見つかりません")
            return
        }

        activityVC.popoverPresentationController?.sourceView = rootVC.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(
            x: rootVC.view.bounds.midX,
            y: rootVC.view.bounds.midY,
            width: 0,
            height: 0
        )
        activityVC.popoverPresentationController?.permittedArrowDirections = []

        var presenter = rootVC
        while let presented = presenter.presentedViewController {
            presenter = presented
        }

        presenter.present(activityVC, animated: true)
    }

    // MARK: - Frame Generation
    /// 動画から指定秒のフレーム（静止画）を最高画質で抽出
    func generateFrame(from sourceURL: URL, at time: TimeInterval) async -> UIImage? {
        let asset = AVURLAsset(url: sourceURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        // 品質優先のための設定
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.appliesPreferredTrackTransform = true // 縦横向きを自動で補正
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        do {
            let (cgImage, _) = try await imageGenerator.image(at: cmTime)
            return UIImage(cgImage: cgImage)
        } catch {
            print("[VideoExporter] ❌ 静止画の生成に失敗: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Save Image to Photo Library
    /// 静止画をカメラロールに保存
    func saveImageToPhotoLibrary(image: UIImage) async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        if status == .notDetermined {
            let granted = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            guard granted == .authorized || granted == .limited else { return false }
        } else if status != .authorized && status != .limited {
            return false
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            return true
        } catch {
            print("[VideoExporter] ❌ 静止画のカメラロール保存に失敗: \(error)")
            return false
        }
    }

    // MARK: - Save Image to Local Documents
    /// 静止画をアプリ内ライブラリ（Documents/Clips）フォルダに複製保存
    func saveImageToLocalDocuments(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.95) else { return nil }
        
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let clipsDir = documentsDir.appendingPathComponent("Clips", isDirectory: true)
        
        try? fileManager.createDirectory(at: clipsDir, withIntermediateDirectories: true)
        
        let destinationURL = clipsDir.appendingPathComponent("frame_\(UUID().uuidString).jpg")
        do {
            try data.write(to: destinationURL)
            print("[VideoExporter] アプリ内ローカルライブラリ（写真）に保存成功: \(destinationURL.lastPathComponent)")
            return destinationURL
        } catch {
            print("[VideoExporter] ⚠️ アプリ内ローカルライブラリ（写真）への書き込み失敗: \(error)")
            return nil
        }
    }

    // MARK: - Cleanup
    /// 一時ファイルの削除
    func cleanupTemporaryFiles() {
        let bufferDir = URL.ringBufferDirectory
        try? FileManager.default.removeItem(at: bufferDir)
        try? FileManager.default.createDirectory(at: bufferDir, withIntermediateDirectories: true)
    }
}
