package de.hhn.outdoor_navigation

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.location.GnssClock
import android.location.GnssMeasurement
import android.location.GnssMeasurementsEvent
import android.location.LocationManager
import android.location.OnNmeaMessageListener
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel

private const val CLIGHT = 299792458.0
private const val GPS_WEEK_SECS = 604800


class GnssPlugin : FlutterPlugin, ActivityAware {
    private lateinit var androidRawEventChannel: EventChannel
    private var androidRawEventSink: EventChannel.EventSink? = null

    private lateinit var nmeaEventChannel: EventChannel
    private var nmeaEventSink: EventChannel.EventSink? = null




    private var context: Context? = null
    private var activity: Activity? = null
    private lateinit var locationManager: LocationManager

    private lateinit var gnssCallback: GnssMeasurementsEvent.Callback

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        androidRawEventChannel = EventChannel(binding.binaryMessenger, "gnss_plugin/raw_stream")
        androidRawEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                androidRawEventSink = events
                startGnssListening()
            }

            override fun onCancel(arguments: Any?) {
                androidRawEventSink = null
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
        androidRawEventChannel.setStreamHandler(null)
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
                if (androidRawEventSink == null) return

                val clock: GnssClock = event.clock
                val measurements: Collection<GnssMeasurement> = event.measurements

                if (!clock.hasFullBiasNanos()) {
                    Log.w("GnssPlugin", "No FullBiasNanos, cannot calculate pseudoranges.")
                    return
                }

                val validMeasurements = measurements.filter {
                    it.hasCarrierFrequencyHz() && (it.state and GnssMeasurement.STATE_TOW_DECODED) != 0
                }
                val count = validMeasurements.size
                if (count == 0) return

                val svids = IntArray(count)
                val constellationTypes = IntArray(count)
                val cn0DbHzs = DoubleArray(count)
                val carrierFrequenciesHz = DoubleArray(count)
                val adrMeters = DoubleArray(count)
                val adrStates = IntArray(count)
                val pratesMps = DoubleArray(count)
                val pseudoranges = DoubleArray(count)

                val rxGpsTimeNanos =
                    clock.timeNanos - (clock.fullBiasNanos + (clock.biasNanos ?: 0.0))

                val rxTowNanos = rxGpsTimeNanos % (GPS_WEEK_SECS * 1_000_000_000L)

                validMeasurements.forEachIndexed { i, m ->
                    val txTowNanos = m.receivedSvTimeNanos

                    var prNanos = rxTowNanos - txTowNanos

                    prNanos -= m.timeOffsetNanos

                    val weekInNanos = GPS_WEEK_SECS * 1_000_000_000L
                    if (prNanos > weekInNanos / 2.0) {
                        prNanos -= weekInNanos
                    } else if (prNanos < -weekInNanos / 2.0) {
                        prNanos += weekInNanos
                    }

                    pseudoranges[i] = prNanos * 1e-9 * CLIGHT

                    svids[i] = m.svid
                    constellationTypes[i] = m.constellationType
                    cn0DbHzs[i] = m.cn0DbHz.toDouble()
                    carrierFrequenciesHz[i] = m.carrierFrequencyHz.toDouble()
                    adrMeters[i] = m.accumulatedDeltaRangeMeters
                    adrStates[i] = m.accumulatedDeltaRangeState
                    pratesMps[i] = m.pseudorangeRateMetersPerSecond
                }

                val absoluteGpsTimeNanos: Long = clock.timeNanos - clock.fullBiasNanos

                val data = mapOf<String, Any>(
                    "gpsTimeNanos" to absoluteGpsTimeNanos,
                    "svids" to svids,
                    "constellationTypes" to constellationTypes,
                    "cn0DbHzs" to cn0DbHzs,
                    "carrierFrequenciesHz" to carrierFrequenciesHz,
                    "accumulatedDeltaRangeMeters" to adrMeters,
                    "accumulatedDeltaRangeStates" to adrStates,
                    "pseudorangeRateMetersPerSecond" to pratesMps,
                    "pseudoranges" to pseudoranges
                )

                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    androidRawEventSink?.success(data)
                }
            }
        }
            locationManager.registerGnssMeasurementsCallback(gnssCallback)
    }

    private fun stopGnssListening() {
        if (::locationManager.isInitialized && ::gnssCallback.isInitialized) {
            locationManager.unregisterGnssMeasurementsCallback(gnssCallback)
            locationManager.removeNmeaListener(nmeaListener)
        }
        androidRawEventSink = null
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
