package com.example.audioplayer

import android.media.MediaPlayer
import android.os.Handler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.lang.ref.WeakReference

class AudioplayerPlugin(private var channel: MethodChannel) : MethodCallHandler, MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener {

    private val mediaPlayers = HashMap<String, MediaPlayer>()
    private val handler = Handler()
    private var positionUpdates: Runnable? = null

    init {
        this.channel.setMethodCallHandler(this)
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "co.westfort.flutter/audio")
            channel.setMethodCallHandler(AudioplayerPlugin(channel))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val playerId = call.argument<String>("playerId")

        when (call.method) {
            "play" -> {
                val url = call.argument<String>("url")
                play(playerId, url)
                result.success(true)
            }
            "pause" -> {
                pause(playerId)
                result.success(true)
            }
            "stop" -> {
                stop(playerId)
                result.success(true)
            }
            "seek" -> {
                seek(playerId, call.argument<Int>("position"))
                result.success(true)
            }
            "volume" -> {
                volume(playerId, call.argument<Float>("volume"))
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun play(playerId: String, url: String) {
        var mediaPlayer = mediaPlayers[playerId]

        if (mediaPlayer == null) {
            mediaPlayer = MediaPlayer()
            mediaPlayers[playerId] = mediaPlayer
            mediaPlayer.setOnPreparedListener(this)
            mediaPlayer.setOnCompletionListener(this)
            mediaPlayer.setDataSource(url)
            mediaPlayer.prepareAsync()
        }
        else {
            mediaPlayer.start()
        }
    }

    private fun pause(playerId: String) {
        val mediaPlayer = mediaPlayers[playerId]
        mediaPlayer?.pause()
    }

    private fun stop(playerId: String) {
        val mediaPlayer = mediaPlayers[playerId]
        if (mediaPlayer != null) {
            onCompletion(mediaPlayer)
        }
    }

    private fun seek(playerId: String, seek: Int) {
        val mediaPlayer = mediaPlayers[playerId]
        mediaPlayer?.seekTo(seek)
        channel.invokeMethod("audio.onCurrentPosition", buildArguments(playerId, seek))
    }

    private fun volume(playerId: String, volume: Float) {
        val mediaPlayer = mediaPlayers[playerId]
        mediaPlayer?.setVolume(volume, volume)
    }

    private fun removePlayer(mediaPlayer: MediaPlayer) {
        val iterator = mediaPlayers.entries.iterator()
        while (iterator.hasNext()) {
            val next = iterator.next()
            if (next.value == mediaPlayer) {
                iterator.remove()
                channel.invokeMethod("audio.onComplete", buildArguments(next.key, true))
                break
            }
        }
    }

    private fun buildArguments(playerId: String, value: Any) : HashMap<String, Any> {
        val results = HashMap<String, Any>()
        results["playerId"] = playerId
        results["value"] = value
        return results
    }

    private fun sendPositionUpdates() {
        if (positionUpdates != null) {
            return
        }

        positionUpdates = UpdateCallback(WeakReference(mediaPlayers), WeakReference(channel),
                WeakReference(handler), WeakReference(this))
        handler.post(positionUpdates)
    }

    private fun stopPositionUpdates() {
        positionUpdates = null
        handler.removeCallbacksAndMessages(null)
    }

    override fun onCompletion(mediaPlayer: MediaPlayer) {
        mediaPlayer.stop()
        mediaPlayer.reset()
        mediaPlayer.release()
        removePlayer(mediaPlayer)
    }

    override fun onPrepared(mediaPlayer: MediaPlayer) {
        mediaPlayer.start()
        sendPositionUpdates()
    }

    private class UpdateCallback(private val mediaPlayers: WeakReference<Map<String, MediaPlayer>>,
                                 private val channel: WeakReference<MethodChannel>,
                                 private val handler: WeakReference<Handler>,
                                 private val plugin: WeakReference<AudioplayerPlugin>) : Runnable {

        override fun run() {
            val mediaPlayers = mediaPlayers.get()
            val channel = channel.get()
            val handler = handler.get()
            val plugin = plugin.get()

            if (mediaPlayers == null || channel == null || handler == null || plugin == null) {
                return
            }

            if (mediaPlayers.isEmpty()) {
                plugin.stopPositionUpdates()
            }

            mediaPlayers.entries.forEach {
                val mediaPlayer = it.value
                if (mediaPlayer.isPlaying) {
                    val key = it.key
                    val duration = mediaPlayer.duration
                    val position = mediaPlayer.currentPosition
                    channel.invokeMethod("audio.onDuration", plugin.buildArguments(key, duration))
                    channel.invokeMethod("audio.onCurrentPosition", plugin.buildArguments(key, position))
                }
            }

            handler.postDelayed(this, 200)
        }
    }
}
