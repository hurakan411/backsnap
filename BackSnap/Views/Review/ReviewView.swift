import SwiftUI

// MARK: - Review View (編集室 - モノトーン・手動編集特化版)
/// プレビュー動画を縦横比を維持したまま左右に余白を残して表示し、
/// 操作系UIを動画の上に重ねて配置するフローティングレイアウト。

enum EditMode: CaseIterable {
    case video
    case photo
    
    var displayName: String {
        switch self {
        case .video:
            return L10n.tr(.reviewModeVideo)
        case .photo:
            return L10n.tr(.reviewModePhoto)
        }
    }
}

struct ReviewView: View {
    let video: RecordedVideo
    let cameraRecorder: CameraRecorder
    let settings: AppSettings
    let onDismiss: () -> Void

    // MARK: - State
    @State private var waveformSamples: [Float] = []
    @State private var trimStart: TimeInterval = 0
    @State private var trimEnd: TimeInterval = 6
    @State private var currentTime: TimeInterval = 0
    @State private var isPlaying = false

    @State private var isSaving = false
    @State private var showSaveSuccess = false
    @State private var showShareSheet = false
    @State private var exportedURL: URL?
    @State private var activeVideoURL: URL? = nil
    
    @State private var editMode: EditMode = .video
    @State private var saveSuccessText: String = ""
    @State private var languageManager = LanguageManager.shared

    private let exporter = VideoExporter()

    var body: some View {
        GeometryReader { geometry in
            let topInset = geometry.safeAreaInsets.top

            ZStack(alignment: .bottom) {
                // 背景
                Color.black.ignoresSafeArea()

                // MARK: 1. 動画プレビュー（ノッチ回避のため下げる + 左右余白）
                let previewWidth = geometry.size.width - 24
                let previewHeight = previewWidth * (16 / 9)

                videoPreview
                    .frame(width: previewWidth, height: previewHeight)
                    // ノッチの下からしっかりと離して配置
                    .padding(.top, topInset + 30)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // MARK: 2. 戻るボタンはZStack自体へのoverlay（alignment: .topLeading）として配置するため、ここでは定義しません。

                // MARK: 3. 下部UIエリア（再生スライダー + 切り取りスライダー + ボタン）
                VStack(spacing: AppTheme.Spacing.md) {
                    // モード切り替えセレクター
                    modeSelector
                        .padding(.horizontal, AppTheme.Spacing.md)

                    // 再生時間スライダー
                    playbackSlider(geometry: geometry)
                        .padding(.horizontal, AppTheme.Spacing.md)

                    // 切り取り範囲スライダー (ビデオモードのみ表示)
                    if editMode == .video {
                        trimSlider(geometry: geometry)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer().frame(height: 4)

                    // 保存 & 共有ボタン
                    actionButtons
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom + 10 : 20)
                }
                .padding(.top, 20)
                .background(
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.75), Color.black.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // 保存完了トースト/HUD
                if showSaveSuccess {
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.neonCyan)
                        
                        Text(saveSuccessText)
                            .font(AppTheme.Typography.body)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(AppTheme.surface.opacity(0.9))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(AppTheme.neonCyan.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: AppTheme.neonCyan.opacity(0.2), radius: 10)
                    .transition(.scale.combined(with: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.35)) // 背景を暗くして視認性を高める
                    .ignoresSafeArea()
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .overlay(
                Button {
                    HapticFeedback.light()
                    onDismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                        Text(L10n.tr(.reviewBack))
                            .font(AppTheme.Typography.body)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.top, topInset + 4)
                .padding(.leading, AppTheme.Spacing.md),
                alignment: .topLeading
            )
        }
        .onAppear {
            print("[ReviewView] 🟢 ReviewView.onAppear が実行されました")
            // 遷移した時点で書き込みがすでに完了している場合は即適用
            if let finalized = cameraRecorder.finalizedVideoURL {
                print("[ReviewView] 🎥 既に書き込み完了済み: \(finalized.lastPathComponent)")
                activeVideoURL = finalized
            } else {
                print("[ReviewView] 🎥 動画書き込み完了をバックグラウンドで待機します")
                activeVideoURL = nil
            }
            trimStart = 0
            trimEnd = video.totalDuration
            currentTime = 0
            waveformSamples = Array(repeating: Float(0.25), count: 200)
            print("[ReviewView] 🟢 初期トリミング設定完了: 0〜\(video.totalDuration) 秒")
        }
        .onChange(of: cameraRecorder.finalizedVideoURL) { _, newValue in
            if let newValue {
                print("[ReviewView] 🎥 監視対象 (finalizedVideoURL) の変更検知 -> 確定URLを適用: \(newValue.lastPathComponent)")
                activeVideoURL = newValue
            }
        }
    }

    // MARK: - Video Preview
    private var videoPreview: some View {
        Group {
            if let url = activeVideoURL {
                VideoPlayerView(
                    url: url,
                    currentTime: $currentTime,
                    isPlaying: $isPlaying,
                    duration: video.totalDuration
                )
            } else {
                // ファイル書き込み（確定処理）完了までのローディング表示
                VStack(spacing: AppTheme.Spacing.md) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)
                    Text(L10n.tr(.reviewProcessing))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.inset)
            }
        }
        .aspectRatio(9/16, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .shadow(color: Color.white.opacity(0.1), radius: 6)
    }

    // MARK: - Playback Slider (再生位置シーク用)
    @ViewBuilder
    private func playbackSlider(geometry: GeometryProxy) -> some View {
        let sliderWidth = geometry.size.width - 32
        let currentPosFraction = currentTime / max(0.01, video.totalDuration)
        let handleX = sliderWidth * currentPosFraction
        
        VStack(spacing: 6) {
            HStack {
                Text(currentTime.timecodeString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                Text(video.totalDuration.timecodeString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            // 再生トラックライン
            ZStack(alignment: .leading) {
                // ベース背景ライン
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 4)
                
                // 再生済みのハイライト
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.neonCyan)
                    .frame(width: max(0, handleX), height: 4)
                
                // つまみ (ドラッグ可能な円形ハンドル)
                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .shadow(color: Color.black.opacity(0.3), radius: 2)
                    .offset(x: handleX - 7)
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isPlaying = false // シーク操作時は再生一時停止
                        let percentage = value.location.x / sliderWidth
                        let newTime = max(0, min(video.totalDuration, video.totalDuration * Double(percentage)))
                        currentTime = newTime
                        HapticFeedback.light()
                    }
            )
        }
    }

    // MARK: - Trim Slider (切り取り範囲設定用)
    @ViewBuilder
    private func trimSlider(geometry: GeometryProxy) -> some View {
        let sliderWidth = geometry.size.width - 32

        VStack(spacing: 6) {
            // トリミング区間の時間範囲と総秒数の表示
            HStack {
                Text(L10n.tr(.reviewTrimRange))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                let clipLength = trimEnd - trimStart
                Text("\(trimStart.preciseTimecodeString) 〜 \(trimEnd.preciseTimecodeString) (\(clipLength.preciseTimecodeString)秒)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(AppTheme.neonCyan)
            }

            // トリミング範囲スライダー
            ZStack(alignment: .leading) {
                // ベース背景
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 36)

                // 選択範囲の青ハイライト
                let startFraction = trimStart / max(0.01, video.totalDuration)
                let endFraction = trimEnd / max(0.01, video.totalDuration)
                let startX = sliderWidth * startFraction
                let selectedWidth = sliderWidth * (endFraction - startFraction)

                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.neonCyan.opacity(0.25), AppTheme.neonCyan.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(0, selectedWidth), height: 36)
                    .offset(x: startX)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(AppTheme.neonCyan.opacity(0.6), lineWidth: 1.5)
                            .frame(width: max(0, selectedWidth), height: 36)
                            .offset(x: startX)
                    )

                // 左ハンドル (trimStart)
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: Color.black.opacity(0.4), radius: 3)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.neonCyan, lineWidth: 2)
                    )
                    .offset(x: startX - 11)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newStart = max(0, min(trimEnd - 1, video.totalDuration * Double(value.location.x / sliderWidth)))
                                trimStart = newStart
                                HapticFeedback.light()
                            }
                    )

                // 右ハンドル (trimEnd)
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: Color.black.opacity(0.4), radius: 3)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.neonCyan, lineWidth: 2)
                    )
                    .offset(x: startX + selectedWidth - 11)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newEnd = max(trimStart + 1, min(video.totalDuration, video.totalDuration * Double(value.location.x / sliderWidth)))
                                trimEnd = newEnd
                                HapticFeedback.light()
                            }
                    )
            }
            .frame(height: 36)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Mode Selector (ビデオ/写真切り替えカスタムセグメント)
    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach(EditMode.allCases, id: \.self) { mode in
                Button {
                    HapticFeedback.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        editMode = mode
                    }
                } label: {
                    Text(mode.displayName)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(editMode == mode ? AppTheme.background : AppTheme.textPrimary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            Group {
                                if editMode == mode {
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                        .fill(AppTheme.neonCyan)
                                        .shadow(color: AppTheme.neonCyan.opacity(0.4), radius: 6)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // 保存ボタン
            Button {
                if editMode == .video {
                    saveClip()
                } else {
                    savePhoto()
                }
            } label: {
                Label(editMode == .video ? L10n.tr(.reviewSave) : L10n.tr(.reviewSavePhoto), systemImage: "square.and.arrow.down.fill")
                    .font(AppTheme.Typography.button)
                    .foregroundColor(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(Color.white)
                    )
            }
            .disabled(isSaving)

            // 共有ボタン
            Button {
                if editMode == .video {
                    shareClip()
                } else {
                    sharePhoto()
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Actions
    private func saveClip() {
        guard let sourceURL = activeVideoURL else {
            print("[ReviewView] ⚠️ 動画ファイルの書き込みが完了していないため保存できません")
            HapticFeedback.warning()
            return
        }
        guard !isSaving else { return }
        isSaving = true

        Task {
            if let url = await exporter.exportClip(
                from: sourceURL,
                startTime: trimStart,
                endTime: trimEnd
            ) {
                // 1. カメラロールに保存
                let success = await exporter.saveToPhotoLibrary(url: url)
                
                // 2. アプリ内のローカルライブラリ用 Documents フォルダにも保存
                _ = exporter.saveToLocalDocuments(url: url)
                
                await MainActor.run {
                    isSaving = false
                    if success {
                        saveSuccessText = L10n.tr(.reviewToastSaved)
                        HapticFeedback.success()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            showSaveSuccess = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSaveSuccess = false
                            }
                        }
                    } else {
                        HapticFeedback.error()
                    }
                }
            } else {
                await MainActor.run {
                    isSaving = false
                    HapticFeedback.error()
                }
            }
        }
    }

    private func shareClip() {
        guard let sourceURL = activeVideoURL else {
            print("[ReviewView] ⚠️ 動画ファイルの書き込みが完了していないため共有できません")
            HapticFeedback.warning()
            return
        }
        Task {
            // 切り取り設定の動画をエクスポートしてからSNS・LINE等に共有
            if let url = await exporter.exportClip(
                from: sourceURL,
                startTime: trimStart,
                endTime: trimEnd
            ) {
                await exporter.share(url: url)
            }
        }
    }

    private func savePhoto() {
        guard let sourceURL = activeVideoURL else {
            print("[ReviewView] ⚠️ 動画ファイルの書き込みが完了していないため写真を保存できません")
            HapticFeedback.warning()
            return
        }
        guard !isSaving else { return }
        isSaving = true

        Task {
            // 現在の再生時間（currentTime）でフレームを抽出
            if let image = await exporter.generateFrame(from: sourceURL, at: currentTime) {
                // 1. カメラロールに保存
                let success = await exporter.saveImageToPhotoLibrary(image: image)
                
                // 2. アプリ内のローカルライブラリ用 Documents フォルダにもJPEG画像として保存
                _ = exporter.saveImageToLocalDocuments(image: image)
                
                await MainActor.run {
                    isSaving = false
                    if success {
                        saveSuccessText = L10n.tr(.reviewToastSavedPhoto)
                        HapticFeedback.success()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            showSaveSuccess = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSaveSuccess = false
                            }
                        }
                    } else {
                        HapticFeedback.error()
                    }
                }
            } else {
                await MainActor.run {
                    isSaving = false
                    HapticFeedback.error()
                }
            }
        }
    }

    private func sharePhoto() {
        guard let sourceURL = activeVideoURL else {
            print("[ReviewView] ⚠️ 動画ファイルの書き込みが完了していないため写真を共有できません")
            HapticFeedback.warning()
            return
        }
        Task {
            if let image = await exporter.generateFrame(from: sourceURL, at: currentTime) {
                await exporter.share(image: image)
            }
        }
    }
}
