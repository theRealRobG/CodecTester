import AVFoundation

protocol CustomResourceLoaderDelegate: AnyObject {
    func customResourceLoader(
        _ resourceLoader: CustomResourceLoader,
        didRecordCodecSupport codecSupport: CodecSupportDecision
    )
}

public enum CodecSupportDecision {
    case fallback
    case preferred
}

class CustomResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    static let url = URL(string: "customcodec://example.com/mvp.m3u8")!
    static let fallbackPlaylistURL = URL(string: "customcodec://example.com/fallback.m3u8")!
    static let preferredPlaylistURL = URL(string: "customcodec://example.com/preferred.m3u8")!

    weak var delegate: CustomResourceLoaderDelegate?

    private let delegateQueue = DispatchQueue(label: "com.theRealRobG.CodecTester.CustomResourceLoader")
    private let fallbackCodecs: String
    private let preferredCodecs: String
    private var didRecordCodecSupport = false

    init(fallbackCodecs: String, preferredCodecs: String) {
        self.fallbackCodecs = fallbackCodecs
        self.preferredCodecs = preferredCodecs
    }

    func newAsset() -> AVURLAsset {
        let asset = AVURLAsset(url: Self.url)
        asset.resourceLoader.setDelegate(self, queue: delegateQueue)
        return asset
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        guard let url = loadingRequest.request.url else { return false }
        switch url {
        case Self.url:
            didRecordCodecSupport = false
            let manifest = fakeManifest(fallbackCodecs: fallbackCodecs, preferredCodecs: preferredCodecs)
            loadingRequest.dataRequest?.respond(with: manifest)
            loadingRequest.finishLoading()
            return true
        case Self.fallbackPlaylistURL:
            guard !didRecordCodecSupport else { return true } // Don't want to report to delegate twice
            didRecordCodecSupport = true
            delegate?.customResourceLoader(self, didRecordCodecSupport: .fallback)
            return true
        case Self.preferredPlaylistURL:
            guard !didRecordCodecSupport else { return true } // Don't want to report to delegate twice
            didRecordCodecSupport = true
            delegate?.customResourceLoader(self, didRecordCodecSupport: .preferred)
            return true
        default:
            return false
        }
    }
}

private func fakeManifest(fallbackCodecs: String, preferredCodecs: String) -> Data {
    """
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=573600,CODECS="\(fallbackCodecs)",SCORE=0.5
\(CustomResourceLoader.fallbackPlaylistURL.absoluteString)
#EXT-X-STREAM-INF:BANDWIDTH=573600,CODECS="\(preferredCodecs)",SCORE=1.0
\(CustomResourceLoader.preferredPlaylistURL.absoluteString)
""".data(using: .utf8)!
}
