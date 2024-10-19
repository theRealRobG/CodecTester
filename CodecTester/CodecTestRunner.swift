import AVFoundation

class CodecTestRunner: NSObject, CustomResourceLoaderDelegate {
    // We keep a player around always and attached to the view to ensure that nothing strange happens to choices based
    // on the player not having a surface to render video to.
    let player = AVPlayer()

    private var resourceLoaders = [ObjectIdentifier: ResourceLoadingContext]()

    // Must override `observeValue` to listen to status changes on AVPlayerItem.
    override public func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context _: UnsafeMutableRawPointer?
    ) {
        guard
            let playerItem = object as? AVPlayerItem,
            keyPath == #keyPath(AVPlayerItem.status),
            playerItem.status == .failed
        else {
            return
        }
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        if let error = playerItem.error {
            reportErrorAndCleanUp(error)
        } else {
            reportErrorAndCleanUp(
                NSError(
                    domain: "CodecTestRunnerErrorDomain",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Player item status changed to failed but provided no error"]
                )
            )
        }
    }

    func run(
        fallbackCodecs: String,
        preferredCodecs: String,
        completion: @escaping (Result<CodecSupportDecision, Error>) -> Void
    ) {
        let resourceLoader = CustomResourceLoader(fallbackCodecs: fallbackCodecs, preferredCodecs: preferredCodecs)
        resourceLoader.delegate = self
        resourceLoaders[ObjectIdentifier(resourceLoader)] = ResourceLoadingContext(
            loader: resourceLoader,
            completion: completion
        )
        let asset = resourceLoader.newAsset()
        let item = AVPlayerItem(asset: asset)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidFailToPlayToEndTime(_:)),
            name: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: item
        )
        item.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: .new,
            context: nil
        )
        player.replaceCurrentItem(with: item)
        player.play()
    }

    func customResourceLoader(
        _ resourceLoader: CustomResourceLoader,
        didRecordCodecSupport codecSupport: CodecSupportDecision
    ) {
        let resourceLoaderId = ObjectIdentifier(resourceLoader)
        guard let context = resourceLoaders[resourceLoaderId] else { return }
        resourceLoaders.removeValue(forKey: resourceLoaderId)
        player.replaceCurrentItem(with: nil)
        context.completion(.success(codecSupport))
    }

    @objc
    func itemDidFailToPlayToEndTime(_ notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem, player.currentItem === playerItem else { return }
        NotificationCenter.default.removeObserver(
            self,
            name: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: playerItem
        )
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError {
            reportErrorAndCleanUp(error)
        } else {
            reportErrorAndCleanUp(
                NSError(
                    domain: "CodecTestRunnerErrorDomain",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to play to end time but provided no error"]
                )
            )
        }
    }

    private func reportErrorAndCleanUp(_ error: Error) {
        player.replaceCurrentItem(with: nil)
        for context in resourceLoaders.values {
            context.completion(.failure(error))
        }
        resourceLoaders.removeAll()
    }
}

extension CodecTestRunner {
    struct ResourceLoadingContext {
        let loader: CustomResourceLoader
        let completion: (Result<CodecSupportDecision, Error>) -> Void
    }
}

