import SwiftUI

@main
struct VideoPlayerApp: App {
  var body: some Scene {
    WindowGroup {
      ZStack(alignment: .bottomLeading) {
        VideoCarousel(viewModel: VideoCarouselViewModel())
      }
    }
  }
}
