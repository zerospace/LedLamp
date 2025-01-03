package com.example.ledlamp

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.SocketChannel

class NetworkService(context: Context) {
    private val _state = MutableLiveData(LampState(0f, 0f, 0f, LampState.Mode.COLOR))
    val state: LiveData<LampState>
        get() = _state

    private val nsdManager = context.getSystemService(Context.NSD_SERVICE) as NsdManager
    private var connection: SocketChannel? = null

    companion object {
        private const val TAG = "NetworkService"
    }

    private val discoveryListener = object : NsdManager.DiscoveryListener {
        override fun onServiceFound(serviceInfo: NsdServiceInfo) {
            Log.d(TAG, "Service found: $serviceInfo")
            if (serviceInfo.serviceType == LedProtocol.service) {
                nsdManager.resolveService(serviceInfo, resolveListener)
            }
        }

        override fun onServiceLost(serviceInfo: NsdServiceInfo) {
            Log.e(TAG, "Service lost: $serviceInfo")
        }

        override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
            Log.e(TAG, "Discovery failed with code = $errorCode")
            nsdManager.stopServiceDiscovery(this)
        }

        override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
            Log.e(TAG, "Stopping discovery failed with code = $errorCode")
            nsdManager.stopServiceDiscovery(this)
        }

        override fun onDiscoveryStarted(serviceType: String) {
            Log.d(TAG, "Service discovery started")
        }

        override fun onDiscoveryStopped(serviceType: String) {
            Log.d(TAG, "Service discovery stopped")
        }
    }

    private val resolveListener = object : NsdManager.ResolveListener {
        override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
            Log.e(TAG, "Resolve failed with code = $errorCode")
        }

        override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
            val host = serviceInfo.host.hostAddress ?: ""
            val port = serviceInfo.port
            establishConnection(host, port)
        }
    }

    fun search() {
        nsdManager.discoverServices(LedProtocol.service, NsdManager.PROTOCOL_DNS_SD, discoveryListener)
    }

    fun stop() {
        nsdManager.stopServiceDiscovery(discoveryListener)
    }

    suspend fun command(command: LedProtocol.Command, type: LedProtocol.MessageType = LedProtocol.MessageType.COMMAND, data: ByteArray? = null) {
        val message = LedProtocol.Message(type = type, command = command, data = data)
        val output = LedProtocol().handleOutput(message)
        connection?.write(ByteBuffer.wrap(output))
    }

    private fun establishConnection(ip: String, port: Int) {
        Log.d(TAG, "Establish connection to ${ip}:${port}")
        connection = SocketChannel.open(InetSocketAddress(ip, port))
        receiveMessageLoop()
        CoroutineScope(Dispatchers.Main).launch {
            withContext(Dispatchers.IO) {
                command(LedProtocol.Command.GET)
            }
        }
    }

    private fun receiveMessageLoop() {
        Thread {
            val buffer = ByteBuffer.allocate(65547)
            while (true) {
                buffer.clear()
                connection?.read(buffer)
                buffer.flip()
                val message = LedProtocol().handleInput(buffer)
                if (message != null) {
                    Log.d(TAG, "Received message: $message")
                    when (message.type) {
                        LedProtocol.MessageType.RESPONSE -> {
                            if (message.command == LedProtocol.Command.GET) {
                                val newState = LampState.deserialize(message.data ?: ByteArray(0))
                                _state.postValue(newState)
                            }
                        }
                        LedProtocol.MessageType.COMMAND -> Log.d(TAG, "Received command message")
                        else -> Log.d(TAG, "Received invalid message")
                    }
                }
            }
        }.start()
    }
}