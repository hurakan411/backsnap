import SwiftUI

// MARK: - Content View
/// メインナビゲーション管理
/// アプリ起動と同時に自動で録画を開始し、レビュー画面から戻ってきた際にも自動で録画を再開します。
/// SwiftUIのバグを回避するため、データの有無(item:)をトリガーにして画面遷移を制御します。

struct ContentView: View {
    @State private var settings = AppSettings()
    @State private var cameraService = CameraService()
    @State private var cameraRecorder = CameraRecorder()

    @State private var showSettings = false
    @State private var recordedVideo: RecordedVideo? // トリミング画面へ渡す動画データ (nilなら非表示)
    @State private var cameraReady = false
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            // メインカメラ画面
            CameraView(
                cameraService: cameraService,
                cameraRecorder: cameraRecorder,
                settings: settings,
                cameraReady: cameraReady,
                onBackSnap: { video in
                    print("[ContentView] 🔵 onBackSnapクロージャ受信: \(video.videoURL.lastPathComponent)")
                    // データを格納するだけで、自動的に fullScreenCover(item:) が起動します
                    recordedVideo = video
                },
                onSettings: {
                    showSettings = true
                }
            )
        }
        .ignoresSafeArea()
        .task {
            // アプリ起動直後にカメラを開始
            await initializeCamera()
            
            // 初回起動判定：オンボーディングが完了していない場合のみ表示
            if !settings.hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        // 【重要】状態の有無を直接バインドし、遷移バグと真っ暗画面を根本解決します
        .fullScreenCover(item: $recordedVideo) { video in
            let _ = print("[ContentView] 🔵 fullScreenCover(item:) 描画開始: \(video.videoURL.lastPathComponent)")
            ReviewView(
                video: video,
                cameraRecorder: cameraRecorder,
                settings: settings,
                onDismiss: {
                    print("[ContentView] 🔵 ReviewView.onDismiss 受信")
                    // recordedVideo を nil にすることで、自動的に画面が閉じます
                    recordedVideo = nil
                    
                    // 閉じるアニメーション（0.5秒）を待ってから、自動録画をクリーンに再開します
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("[ContentView] 🔵 録画再開を実行")
                        cameraRecorder.startRecording(cameraService: cameraService)
                    }
                }
            )
            .transition(.opacity)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(
                settings: settings,
                onDismiss: {
                    showSettings = false
                    applySettingsToCamera() // 設定画面を閉じたらカメラに即座に反映
                }
            )
            .transition(.opacity)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(
                isPresentedAsTutorial: false,
                onComplete: {
                    settings.completeOnboarding()
                    showOnboarding = false
                    
                    // 自動録画を必要に応じて開始
                    if !cameraRecorder.isRecording && cameraReady {
                        cameraRecorder.startRecording(cameraService: cameraService)
                    }
                }
            )
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Camera Initialization
    private func initializeCamera() async {
        #if targetEnvironment(simulator)
        print("[ContentView] 🖥 シミュレータ動作を検出しました。ダミー動画を準備します。")
        SimulatorDummyVideoGenerator.shared.generateDummyVideoIfNeeded()
        await MainActor.run {
            cameraReady = true
        }
        #else
        let authorized = await cameraService.checkPermissions()
        guard authorized else {
            print("[ContentView] カメラ権限が拒否されました")
            return
        }

        // デフォルト設定を読み込んで反映
        let initialRes: VideoResolution = (settings.defaultResolution == "4K") ? .uhd : .hd
        cameraService.activeResolution = initialRes
        cameraService.activeFPS = settings.defaultFPS

        await cameraService.configureSession()
        await cameraService.startSession()

        // セッション開始後にカメラ起動完了フラグを立てる
        await MainActor.run {
            cameraReady = true
        }
        #endif
    }

    // MARK: - Apply Settings
    private func applySettingsToCamera() {
        let targetRes: VideoResolution = (settings.defaultResolution == "4K") ? .uhd : .hd
        let targetFPS = settings.defaultFPS
        
        // 現在のカメラの解像度やFPSと異なる場合のみ更新
        if cameraService.activeResolution != targetRes {
            cameraService.setResolution(targetRes)
        }
        if cameraService.activeFPS != targetFPS {
            cameraService.setFPS(targetFPS)
        }
    }
}

#Preview {
    ContentView()
}
