import Flutter
import UIKit
import AVFoundation

public class SwiftAudioplayerPlugin: NSObject, FlutterPlugin {

    private var channel: FlutterMethodChannel!
    private var mediaPlayers: Dictionary<String, AVPlayer> = [:]
    private var updateTimer: Timer?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "co.westfort.flutter/audio", binaryMessenger: registrar.messenger())
        let instance = SwiftAudioplayerPlugin(channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(_ channel: FlutterMethodChannel) {
        super.init()
        self.channel = channel

        NotificationCenter.default.addObserver(self,
                selector: #selector(onComplete),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: nil)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? Dictionary<String, Any>,
              let playerId = arguments["playerId"] as? String else {
            return
        }

        switch (call.method) {
        case "play":
            if let url = arguments["url"] as? String {
                play(playerId: playerId, url: url)
                result(true)
            }
            break
        case "pause":
            pause(playerId: playerId)
            result(true)
            break
        case "stop":
            stop(playerId: playerId)
            result(true)
            break
        case "seek":
            if let position = arguments["position"] as? Int {
                seek(playerId: playerId, seek: position)
                result(true)
            }
            break
        case "volume":
            if let vol = arguments["volume"] as? Float {
                volume(playerId: playerId, volume: vol)
                result(true)
            }
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }

    private func play(playerId: String, url: String) {
        guard let audioUrl = URL(string: url) else {
            return
        }
        var mediaPlayer = mediaPlayers[playerId]

        if mediaPlayer == nil {
            mediaPlayer = AVPlayer(url: audioUrl)
            mediaPlayers[playerId] = mediaPlayer
            sendPositionUpdates()
        }

        mediaPlayer?.play()
    }

    private func pause(playerId: String) {
        let mediaPlayer = mediaPlayers[playerId]
        mediaPlayer?.pause()
    }

    private func stop(playerId: String) {
        var mediaPlayer = mediaPlayers[playerId]
        mediaPlayer?.pause()
        mediaPlayer = nil
        mediaPlayers.removeValue(forKey: playerId)
    }

    private func seek(playerId: String, seek: Int) {
        let mediaPlayer = mediaPlayers[playerId]
        mediaPlayer?.seek(to: CMTimeMakeWithSeconds(Double(seek) * 0.001, 6000))
        channel.invokeMethod("audio.onCurrentPosition", arguments: buildArguments(playerId: playerId, value: seek))
    }

    private func volume(playerId: String, volume: Float) {
        let mediaPlayer = mediaPlayers[playerId]
        mediaPlayer?.volume = volume
    }

    private func buildArguments(playerId: String, value: Any) -> Dictionary<String, Any> {
        return [
            "playerId": playerId,
            "value": value,
        ]
    }

    private func sendPositionUpdates() {
        if updateTimer != nil {
            return
        }

        updateTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(sendUpdates), userInfo: nil, repeats: true)
    }

    private func stopPositionUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    @objc
    private func onComplete(notification: Notification) {
        for (key, mediaPlayer) in mediaPlayers {
            if let currentItem = mediaPlayer.currentItem {
                if currentItem.currentTime() >= currentItem.duration {
                    channel.invokeMethod("audio.onComplete", arguments: buildArguments(playerId: key, value: true))
                    stop(playerId: key)
                }
            }
        }
    }

    @objc
    private func sendUpdates() {
        if mediaPlayers.count == 0 {
            stopPositionUpdates()
        }

        for (key, mediaPlayer) in mediaPlayers {
            if let currentItem = mediaPlayer.currentItem {
                let duration: Int = CMTimeGetSeconds(currentItem.duration).isNaN ? 0 : Int(CMTimeGetSeconds(currentItem.duration))
                let position: Int = CMTimeGetSeconds(currentItem.currentTime()).isNaN ? 0 : Int(CMTimeGetSeconds(currentItem.currentTime()))
                channel.invokeMethod("audio.onDuration", arguments: buildArguments(playerId: key, value: duration * 1000))
                channel.invokeMethod("audio.onCurrentPosition", arguments: buildArguments(playerId: key, value: position * 1000))
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopPositionUpdates()
    }
}
