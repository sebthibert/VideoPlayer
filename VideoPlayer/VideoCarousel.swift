import AVKit
import SwiftUI

let apiVideos = [
  VideoPlayerManager.Video(url: "https://asset1.cxnmarksandspencer.com/is/content/mands/SD_01_T49_4378_HB_X_EC_20", title: "Wow", description: "Check this out", cta: "Now"),
  VideoPlayerManager.Video(url: "https://asset1.cxnmarksandspencer.com/is/content/mands/PL_05_T80_8019M_ZZ_X_EC_20", title: "Oi", description: "This looks juicy", cta: "Go"),
  VideoPlayerManager.Video(url: "https://asset1.cxnmarksandspencer.com/is/content/mands/SD_01_T57_6013_XA_X_EC_20", title: "Hmm", description: "Fancy it do ya?", cta: "Come on"),
]

struct VideoPlayerManager {
  static let videos = apiVideos.compactMap { $0 }

  static func initialItems() -> [AVPlayerItem] {
    videos
      .map { $0.url }
      .map(AVPlayerItem.init)
  }

  static func video(for index: Int) -> Video {
    videos[videos.count - index]
  }
}

extension VideoPlayerManager {
  struct Video {
    let url: URL
    let title: String
    let description: String
    let cta: String

    init?(
      url: String,
      title: String,
      description: String,
      cta: String
    ) {
      guard let url = URL(string: url) else {
        return nil
      }
      self.url = url
      self.title = title
      self.description = description
      self.cta = cta
    }
  }
}

final class VideoCarouselViewModel: ObservableObject {
  private var token: NSKeyValueObservation?
  @Published var videoIndex = VideoPlayerManager.initialItems().count

  func setup(player: AVQueuePlayer) {
    addVideosToQueue(player: player)
    observe(player: player)
  }

  func swipeForward(player: AVQueuePlayer) {
    player.advanceToNextItem()
  }

  func swipeBackward(player: AVQueuePlayer) {
    let numberOfVideosToDrop = VideoPlayerManager.initialItems().count - 1
    (1...numberOfVideosToDrop)
      .reversed()
      .map { $0 - 1 }
      .forEach { index in
        resetVideosIfOnLastVideo(numberOfVideosLeft: player.items().count, player: player)
        player.remove(player.items()[index])
      }
  }

  private func observe(player: AVQueuePlayer) {
    token = player.observe(\.currentItem) { [weak self] player, _ in
      guard let self = self else {
        return
      }
      let numberOfVideosLeft = player.items().count
      self.resetVideosIfOnLastVideo(numberOfVideosLeft: numberOfVideosLeft, player: player)
      withAnimation {
        self.videoIndex = numberOfVideosLeft
      }
    }
  }

  private func resetVideosIfOnLastVideo(numberOfVideosLeft: Int, player: AVQueuePlayer) {
    if numberOfVideosLeft == 1 {
      addVideosToQueue(player: player)
    }
  }

  private func addVideosToQueue(player: AVQueuePlayer) {
    VideoPlayerManager
      .initialItems()
      .forEach { player.insert($0, after: player.items().last) }
  }
}

struct VideoCarousel: View {
  private let avPlayer = AVQueuePlayer()

  @ObservedObject var viewModel: VideoCarouselViewModel
  @State var isDragging = false

  init(viewModel: VideoCarouselViewModel) {
    self.viewModel = viewModel
    viewModel.setup(player: avPlayer)
    avPlayer.rate = 3
  }

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      VideoPlayer(player: avPlayer)
        .aspectRatio(1 / 1.3, contentMode: .fit)
        .disabled(true)
        .contentShape(Rectangle())
        .gesture(DragGesture()
          .onChanged { gesture in
            let translation = gesture.translation.width
            guard abs(translation) > 50, isDragging == false else {
              return
            }
            isDragging = true
            if translation < 0 {
              viewModel.swipeForward(player: avPlayer)
            } else {
              viewModel.swipeBackward(player: avPlayer)
            }
          }
          .onEnded { _ in
            isDragging = false
          }
        )
//        .onTapGesture { avPlayer.advanceToNextItem() }
        .overlay(Rectangle().opacity(0.2))
      VideoOverlay(videoIndex: viewModel.videoIndex)
        .padding()
    }

  }
}

struct VideoOverlay: View {
  let videoIndex: Int

  var body: some View {
    let content = VideoPlayerManager.video(for: videoIndex)
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text(content.title)
          .font(.largeTitle.bold())
        Text(content.description)
          .font(.title2.bold())
      }
      Button(content.cta) {

      }
      .font(.title2.bold())
      .frame(minWidth: 100, minHeight: 48)
      .foregroundColor(.white)
      .padding(.vertical, 8)
      .padding(.horizontal, 16)
      .background(Color.black)
      VideoOverlayPageIndicator(videoIndex: videoIndex)
        .padding(.horizontal)
    }
    .foregroundColor(.white)
  }
}

struct VideoOverlayPageIndicator: View {
  let videoIndex: Int

  var body: some View {
    HStack(spacing: 0) {
      let range = (1...VideoPlayerManager.initialItems().count).reversed()
      ForEach(range, id: \.self) { number in
        Rectangle()
          .foregroundColor(number == videoIndex ? .black : .black.opacity(0.2))
      }
    }
    .frame(height: 3)
  }
}
