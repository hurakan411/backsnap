import SwiftUI

// MARK: - Camera View (BackSnap Main Screen)
/// カメラプレビューをデバイスの画面全体（セーフエリア完全無視）に表示し、
/// iOS標準のビデオ録画画面を再現しています。

struct CameraView: View {
    let cameraService: CameraService
    let cameraRecorder: CameraRecorder
    let settings: AppSettings
    let cameraReady: Bool

    let onBackSnap: (RecordedVideo) -> Void
    let onSettings: () -> Void

    // MARK: - States
    @State private var baseZoomFactor: CGFloat = 1.0
    @State private var showLibrary = false // ローカルライブラリの表示フラグ
    
    // タップフォーカス表示用の状態
    @State private var focusPoint: CGPoint? = nil
    @State private var focusBoxScale: CGFloat = 1.0
    @State private var focusBoxOpacity: Double = 0.0

    var body: some View {
        GeometryReader { geometry in
            let topInset = geometry.safeAreaInsets.top

            ZStack {
                // MARK: 1. 背景
                Color.black.ignoresSafeArea(.all)

                // MARK: 2. カメラプレビュー (上部のセーフエリア「ノッチ」を無視せず、下端と横端だけを広げる)
                if cameraReady {
                    CameraPreviewView(
                        session: cameraService.captureSession,
                        zoomFactor: cameraService.zoomFactor
                    )
                    .ignoresSafeArea(edges: [.bottom, .horizontal]) // 上部（ノッチ）はセーフエリア内に収める
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { event in
                                let location = event.location
                                // カメラのフォーカス＆露出を調整
                                cameraService.focus(at: location, in: geometry.size)
                                // 黄色のフォーカスインジケーターを起動
                                triggerFocusIndicator(at: location)
                            }
                    )
                }

                // 黄色のフォーカスインジケーター (iOS純正カメラのデザインを再現)
                if let point = focusPoint, focusBoxOpacity > 0 {
                    ZStack {
                        // 外枠の矩形
                        Rectangle()
                            .stroke(Color.yellow, lineWidth: 1.5)
                            .frame(width: 70, height: 70)
                        
                        // 上下のレティクル
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 1, height: 8)
                            .offset(y: -35)
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 1, height: 8)
                            .offset(y: 35)
                        
                        // 左右のレティクル
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 8, height: 1)
                            .offset(x: -35)
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 8, height: 1)
                            .offset(x: 35)
                    }
                    .position(point)
                    .scaleEffect(focusBoxScale)
                    .opacity(focusBoxOpacity)
                }

                // MARK: 3. 上部コントロール（アイコンの位置をしっかりと下げ、サイズを統一）
                VStack {
                    HStack {
                        // 左：解像度 & FPS 切り替えボタン
                        HStack(spacing: 10) {
                            // 解像度メニュー
                            Menu {
                                Button {
                                    HapticFeedback.light()
                                    cameraService.setResolution(.hd)
                                } label: {
                                    HStack {
                                        Text("HD (1080p)")
                                        if cameraService.activeResolution == .hd {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                Button {
                                    HapticFeedback.light()
                                    cameraService.setResolution(.uhd)
                                } label: {
                                    HStack {
                                        Text("4K (2160p)")
                                        if cameraService.activeResolution == .uhd {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                Text(cameraService.activeResolution.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }

                            // フレームレートメニュー
                            Menu {
                                Button {
                                    HapticFeedback.light()
                                    cameraService.setFPS(30)
                                } label: {
                                    HStack {
                                        Text("30 fps")
                                        if cameraService.activeFPS == 30 {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                Button {
                                    HapticFeedback.light()
                                    cameraService.setFPS(60)
                                } label: {
                                    HStack {
                                        Text("60 fps")
                                        if cameraService.activeFPS == 60 {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                Text("\(cameraService.activeFPS)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                        }

                        Spacer()

                        // 右：フラッシュ & 設定
                        HStack(spacing: 10) {
                            Button {
                                HapticFeedback.light()
                                cameraService.toggleTorch()
                            } label: {
                                Image(systemName: cameraService.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(cameraService.isTorchOn ? .yellow : .white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }

                            Button {
                                HapticFeedback.light()
                                onSettings()
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    // 各アイコンの位置を下に下げる
                    .padding(.top, topInset + 90)

                    Spacer()
                }

                // MARK: 4. 録画中の上部中央タイマー
                if cameraRecorder.isRecording {
                    VStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text(TimeInterval(cameraRecorder.recordedSeconds).preciseTimecodeString)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(.top, topInset + 90)

                        Spacer()
                    }
                }

                // MARK: 5. 下部コントロール
                VStack {
                    Spacer()

                    // ズームインジケーター
                    Button {
                        toggleZoom()
                    } label: {
                        Text(String(format: "%.1fx", cameraService.zoomFactor))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.yellow)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.yellow, lineWidth: 1.5)
                            )
                    }
                    .padding(.bottom, 20)

                    // シャッターボタン行
                    HStack {
                        // 左：写真フォルダ（ローカルライブラリ表示）
                        Button {
                            HapticFeedback.light()
                            showLibrary = true
                        } label: {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 48, height: 48)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 30)

                        // 中央：シャッターボタン (SNAP)
                        BackSnapButton(
                            isReady: cameraRecorder.isReadyToStop,
                            isRecording: cameraRecorder.isRecording
                        ) {
                            performBackSnap()
                        }

                        // 右：インカメラ/アウトカメラ切り替え
                        Button {
                            HapticFeedback.light()
                            cameraService.switchCamera()
                        } label: {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 30)
                    }
                    .padding(.bottom, 30)
                }
            }
            .ignoresSafeArea(edges: [.bottom, .horizontal]) // 上部ノッチ部分は黒帯にする
        }
        .statusBarHidden(true)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    let newZoom = baseZoomFactor * value
                    cameraService.setZoomFactor(newZoom)
                }
                .onEnded { _ in
                    baseZoomFactor = cameraService.zoomFactor
                }
        )
        .onAppear {
            baseZoomFactor = cameraService.zoomFactor
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !cameraRecorder.isRecording && cameraReady {
                    cameraRecorder.startRecording(cameraService: cameraService)
                }
            }
        }
        .onDisappear {
            cameraRecorder.stopRecording()
        }
        .onChange(of: cameraReady) { _, ready in
            if ready {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if !cameraRecorder.isRecording {
                        cameraRecorder.startRecording(cameraService: cameraService)
                    }
                }
            }
        }
        // ローカルライブラリ画面（LibraryView）のシート表示
        .sheet(isPresented: $showLibrary) {
            LibraryView()
        }
    }

    // MARK: - Actions
    private func performBackSnap() {
        print("[CameraView] 🔴 SNAPボタンがタップされました")
        if let video = cameraRecorder.stopRecordingAndCaptureImmediate() {
            print("[CameraView] 🔴 録画停止＆ビデオ取得成功: \(video.videoURL.lastPathComponent), 秒数: \(video.totalDuration)")
            onBackSnap(video)
        } else {
            print("[CameraView] 🔴 録画停止失敗")
        }
    }

    private func toggleZoom() {
        HapticFeedback.light()
        let current = cameraService.zoomFactor
        let next: CGFloat
        if current < 1.0 {
            next = 1.0
        } else if current < 2.0 {
            next = 2.0
        } else if current < 5.0 {
            next = 5.0
        } else {
            next = 0.5
        }
        cameraService.setZoomFactor(next)
    }
    
    // タップフォーカスのインジケーター表示用アニメーション
    private func triggerFocusIndicator(at location: CGPoint) {
        HapticFeedback.light()
        focusPoint = location
        focusBoxScale = 1.6
        focusBoxOpacity = 1.0
        
        // タップした瞬間にバネのように縮小してピントを合わせる演出
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            focusBoxScale = 1.0
        }
        
        // 1.2秒後に自然にフェードアウト
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                focusBoxOpacity = 0.0
            }
        }
    }
}
