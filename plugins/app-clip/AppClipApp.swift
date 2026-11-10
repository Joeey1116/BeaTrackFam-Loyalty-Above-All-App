import SwiftUI

/// Entry point for the BeaTrackFam App Clip (com.beatrackfaminc.BeaTrackFam).
///
/// The clip is a deliberately tiny, dependency-free SwiftUI app — it does NOT
/// embed React Native (the full app could never fit the 15 MB App Clip
/// limit). It shows a live snapshot of the storefront and hands the shopper
/// off to the full app (App Store overlay / deep link) or the website.
///
/// The clip is generated into ios/BeaTrackFamClip by the
/// `plugins/with-app-clip` config plugin on every `expo prebuild`; edit the
/// templates under `plugins/app-clip/`, never the generated copy.
@main
struct BeaTrackFamClipApp: App {
  @State private var invocationURL: URL?

  var body: some Scene {
    WindowGroup {
      ContentView(invocationURL: invocationURL)
        // App Clip invocation: the URL from the App Clip Code / NFC tag /
        // link that launched the clip (configured as an App Clip experience
        // in App Store Connect).
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
          if let url = activity.webpageURL {
            invocationURL = url
          }
        }
        .onOpenURL { url in
          invocationURL = url
        }
    }
  }
}
