package de.hhn.outdoor_navigation

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.location.GnssMeasurementsEvent
import android.location.LocationManager
import android.location.OnNmeaMessageListener
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel


class GnssPlugin : FlutterPlugin, ActivityAware {
    private lateinit var gnssEventChannel: EventChannel
    private lateinit var nmeaEventChannel: EventChannel

    private var gnssEventSink: EventChannel.EventSink? = null
    private var nmeaEventSink: EventChannel.EventSink? = null


    private var context: Context? = null
    private var activity: Activity? = null
    private lateinit var locationManager: LocationManager
    private lateinit var gnssCallback: GnssMeasurementsEvent.Callback

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        gnssEventChannel = EventChannel(binding.binaryMessenger, "gnss_plugin/raw_stream")
        gnssEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                gnssEventSink = events
                startGnssListening()
            }

            override fun onCancel(arguments: Any?) {
                gnssEventSink = null
                stopGnssListening()
            }
        })

        nmeaEventChannel = EventChannel(binding.binaryMessenger, "gnss_plugin/nmea_stream")
        nmeaEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                nmeaEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                nmeaEventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopGnssListening()
        gnssEventChannel.setStreamHandler(null)
        nmeaEventChannel.setStreamHandler(null)
    }

    private fun startGnssListening() {
        val act = activity ?: return

        if (ActivityCompat.checkSelfPermission(act, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(act, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), 0)
            return
        }

        locationManager = act.getSystemService(Context.LOCATION_SERVICE) as LocationManager

        gnssCallback = object : GnssMeasurementsEvent.Callback() {
            override fun onGnssMeasurementsReceived(event: GnssMeasurementsEvent) {

                val measurements = event.measurements.map {

                    mapOf(
                        "svid" to it.svid,
                        "cn0DbHz" to it.cn0DbHz,
                        "constellationType" to it.constellationType,
                        "pseudorangeRateMetersPerSecond" to it.pseudorangeRateMetersPerSecond,
                        "accumulatedDeltaRangeMeters" to it.accumulatedDeltaRangeMeters,
                        "accumulatedDeltaRangeState" to it.accumulatedDeltaRangeState,
                        "accumulatedDeltaRangeUncertaintyMeters" to it.accumulatedDeltaRangeUncertaintyMeters,
                        "basebandCn0DbHz" to it.basebandCn0DbHz,
                        "carrierFrequencyHz" to it.carrierFrequencyHz,
                        "codeType" to it.codeType,
                        "fullInterSignalBiasNanos" to it.fullInterSignalBiasNanos,
                        "fullInterSignalBiasUncertaintyNanos" to it.fullInterSignalBiasUncertaintyNanos,
                        "multipathIndicator" to it.multipathIndicator,
                        "pseudorangeRateUncertaintyMetersPerSecond" to it.pseudorangeRateUncertaintyMetersPerSecond,
                        "receivedSvTimeNanos" to it.receivedSvTimeNanos,
                        "receivedSvTimeUncertaintyNanos" to it.receivedSvTimeUncertaintyNanos,
                        "satelliteInterSignalBiasNanos" to it.satelliteInterSignalBiasNanos,
                        "satelliteInterSignalBiasUncertaintyNanos" to it.satelliteInterSignalBiasUncertaintyNanos,
                        "snrInDb" to it.snrInDb,
                        "state" to it.state,
                        "timeOffsetNanos" to it.timeOffsetNanos,
                    )
                }

                val data = mapOf("measurements" to measurements)

                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    gnssEventSink?.success(data)
                }
            }
        }
        locationManager.addNmeaListener(nmeaListener)
        locationManager.registerGnssMeasurementsCallback(gnssCallback)

    }

    private fun stopGnssListening() {
        if (::locationManager.isInitialized && ::gnssCallback.isInitialized) {
            locationManager.unregisterGnssMeasurementsCallback(gnssCallback)
            locationManager.removeNmeaListener(nmeaListener)
        }
        gnssEventSink = null
        nmeaEventSink = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    private val nmeaListener: OnNmeaMessageListener = object : OnNmeaMessageListener {
        override fun onNmeaMessage(message: String?, timestamp: Long) {
            message?.let {
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    nmeaEventSink?.success(mapOf("timestamp" to timestamp, "message" to it))
                }
            }
        }
    }
}
