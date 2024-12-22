package com.example.ledlamp

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log

class NetworkService(context: Context) {
    private val nsdManager = context.getSystemService(Context.NSD_SERVICE) as NsdManager

    companion object {
        private const val TAG = "BONJOUR"
        private const val SERVICE_NAME = "_lamp._tcp."
    }

    private val discoveryListener = object : NsdManager.DiscoveryListener {
        override fun onServiceFound(serviceInfo: NsdServiceInfo) {
            Log.d(TAG, "Service found: $serviceInfo")
            if (serviceInfo.serviceType == SERVICE_NAME) {
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
            val host = serviceInfo.host
            val port = serviceInfo.port
            Log.d(TAG, "Host: $host, Port: $port")
        }
    }

    fun search() {
        nsdManager.discoverServices(SERVICE_NAME, NsdManager.PROTOCOL_DNS_SD, discoveryListener)
    }

    fun stop() {
        nsdManager.stopServiceDiscovery(discoveryListener)
    }
}