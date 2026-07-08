import SwiftUI
import Photos
import AVFoundation
import AVKit

// MARK: - Library View (カメラロールの動画一覧)
/// デバイスの写真ライブラリ（カメラロール）から動画を取得して一覧表示。
/// タップすると同一シート内でプッシュ遷移して大きく再生。
// MARK: - PHFetchResult Wrapper for Lazy Loading
/// PHFetchResult を SwiftUI で効率的かつ怠惰（Lazy）に読み込むためのラッパー
struct PHFetchResultCollection: RandomAccessCollection {
    let fetchResult: PHFetchResult<PHAsset>

    var startIndex: Int { 0 }
    var endIndex: Int { fetchResult.count }

    func index(after i: Int) -> Int { i + 1 }
    func index(before i: Int) -> Int { i - 1 }

    subscript(position: Int) -> PHAsset {
        fetchResult.object(at: position)
    }
}

struct LibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var fetchResult: PHFetchResult<PHAsset>? = nil
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                switch authorizationStatus {
                case .authorized, .limited:
                    if let result = fetchResult, result.count > 0 {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 3),
                                GridItem(.flexible(), spacing: 3),
                                GridItem(.flexible(), spacing: 3)
                            ], spacing: 3) {
                                ForEach(PHFetchResultCollection(fetchResult: result), id: \.localIdentifier) { asset in
                                    NavigationLink(destination: LibraryDetailView(asset: asset)) {
                                        LibraryGridItem(asset: asset)
                                    }
                                }
                            }
                        }
                    } else if fetchResult != nil {
                        VStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "video.slash.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text(L10n.tr(.libraryNoVideos))
                                .font(AppTheme.Typography.body)
                                .foregroundColor(.gray)
                        }
                    } else {
                        ProgressView()
                            .tint(.gray)
                    }
                case .denied, .restricted:
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text(L10n.tr(.libraryNoAccess))
                            .font(AppTheme.Typography.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        Text(L10n.tr(.libraryAllowAccess))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                default:
                    ProgressView()
                        .tint(.gray)
                }
            }
            .navigationTitle(L10n.tr(.libraryTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticFeedback.light()
                        dismiss()
                    } label: {
                        Text(L10n.tr(.libraryClose))
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                requestAccessAndLoad()
            }
        }
        .preferredColorScheme(.light)
    }

    private func requestAccessAndLoad() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    self.authorizationStatus = newStatus
                    if newStatus == .authorized || newStatus == .limited {
                        loadVideos()
                    }
                }
            }
        } else if status == .authorized || status == .limited {
            loadVideos()
        }
    }

    private func loadVideos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        // ビデオに加えて画像（Photo）もアセット一覧に読み込むように条件を拡張
        fetchOptions.predicate = NSPredicate(
            format: "mediaType == %d OR mediaType == %d",
            PHAssetMediaType.video.rawValue,
            PHAssetMediaType.image.rawValue
        )

        let result = PHAsset.fetchAssets(with: fetchOptions)
        DispatchQueue.main.async {
            self.fetchResult = result
        }
    }
}

// MARK: - Library Grid Item (サムネイル + 再生時間)
struct LibraryGridItem: View {
    let asset: PHAsset
    @State private var thumbnail: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // サムネイル (アスペクト比を維持しつつ正方形に綺麗にクロップ)
            Color.clear
                .aspectRatio(1, contentMode: .fill)
                .overlay(
                    Group {
                        if let thumbnail = thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    ProgressView().tint(.gray)
                                )
                        }
                    }
                )
                .clipped()

            // 動画の場合のみ長さを表示
            if asset.mediaType == .video {
                Text(formatDuration(asset.duration))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(3)
                    .padding(4)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        let size = CGSize(width: 200, height: 200)
        manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Library Detail View (同一ウィンドウ内で遷移して大きく再生/静止画表示)
struct LibraryDetailView: View {
    let asset: PHAsset
    @State private var playerItem: AVPlayerItem?
    @State private var player: AVPlayer?
    @State private var uiImage: UIImage? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if asset.mediaType == .video {
                if let player = player {
                    VideoPlayerControllerView(player: player)
                        .ignoresSafeArea()
                } else {
                    ProgressView(L10n.tr(.libraryLoading))
                        .tint(.white)
                        .foregroundColor(.white)
                }
            } else {
                if let uiImage = uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                } else {
                    ProgressView(L10n.tr(.libraryLoading))
                        .tint(.white)
                        .foregroundColor(.white)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if asset.mediaType == .video {
                loadVideo()
            } else {
                loadImage()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func loadVideo() {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
            DispatchQueue.main.async {
                if let item = item {
                    let avPlayer = AVPlayer(playerItem: item)
                    self.player = avPlayer
                    avPlayer.play()
                }
            }
        }
    }

    private func loadImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) { image, _ in
            DispatchQueue.main.async {
                self.uiImage = image
            }
        }
    }
}

// MARK: - Video Player Controller (AVPlayerViewController ラッパー)
struct VideoPlayerControllerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}
