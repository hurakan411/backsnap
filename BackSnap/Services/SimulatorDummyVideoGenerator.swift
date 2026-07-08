#if targetEnvironment(simulator)
import Foundation
import AVFoundation
import CoreVideo
import UIKit

// MARK: - Simulator Dummy Video Generator
/// シミュレータ上にカメラデバイスが存在しないため、自動的にグラデーションが変化するダミーの動画ファイルをプログラムで生成し、
/// シミュレータ環境でのトリミングや保存の動作確認を可能にします。

final class SimulatorDummyVideoGenerator {
    static let shared = SimulatorDummyVideoGenerator()
    
    var dummyVideoURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("simulator_dummy.mov")
    }
    
    /// シミュレータ用のダミー動画ファイルを非同期で生成 (存在しない場合のみ)
    func generateDummyVideoIfNeeded() {
        let path = dummyVideoURL.path
        if FileManager.default.fileExists(atPath: path) {
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? UInt64) ?? 0
            if fileSize > 1024 {
                print("[Simulator] 🎬 ダミー動画ファイルは既に存在します")
                return
            }
        }
        
        print("[Simulator] 🎬 ダミー動画の生成を開始します...")
        
        let width = 720
        let height = 1280
        let durationSeconds: Double = 60.0 // 60秒分の動画を生成
        let fps = 30
        
        // 既存の破損ファイルをクリーンアップ
        try? FileManager.default.removeItem(at: dummyVideoURL)
        
        guard let writer = try? AVAssetWriter(outputURL: dummyVideoURL, fileType: .mov) else {
            print("[Simulator] ⚠️ AVAssetWriterの初期化失敗")
            return
        }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: attributes
        )
        
        writer.add(videoInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        let totalFrames = Int(durationSeconds * Double(fps))
        var frameCount = 0
        
        videoInput.requestMediaDataWhenReady(on: DispatchQueue(label: "dummy-video-generator")) {
            while videoInput.isReadyForMoreMediaData {
                if frameCount >= totalFrames {
                    videoInput.markAsFinished()
                    writer.finishWriting {
                        print("[Simulator] ✅ ダミー動画の生成が完了しました: \(path)")
                    }
                    break
                }
                
                let presentationTime = CMTime(value: CMTimeValue(frameCount), timescale: CMTimeScale(fps))
                
                if let buffer = self.createPixelBuffer(width: width, height: height, frameIndex: frameCount, totalFrames: totalFrames) {
                    adaptor.append(buffer, withPresentationTime: presentationTime)
                }
                
                frameCount += 1
            }
        }
    }
    
    private func createPixelBuffer(width: Int, height: Int, frameIndex: Int, totalFrames: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            nil,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        if let context = context {
            // 背景を描画 (フレームインデックスに応じてカラフルにグラデーション変化)
            let progress = CGFloat(frameIndex) / CGFloat(totalFrames)
            context.setFillColor(red: progress, green: 1.0 - progress, blue: 0.5, alpha: 1.0)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            
            // 動く白い正方形を描画
            context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            let boxY = CGFloat(height) * progress
            context.fill(CGRect(x: CGFloat(width / 2 - 100), y: boxY - 100, width: 200, height: 200))
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        return buffer
    }
}
#endif
