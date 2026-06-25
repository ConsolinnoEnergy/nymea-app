package io.guh.nymeaapp;

import java.io.File;

import android.util.Log;
import android.content.Intent;
import android.content.Context;
import android.os.Bundle;
import android.os.Build;
import android.telephony.TelephonyManager;
import android.provider.Settings;
import android.provider.Settings.Secure;
import android.os.Vibrator;
import android.net.Uri;
import android.content.res.Configuration;
import android.content.IntentFilter;
import android.content.BroadcastReceiver;
import android.location.LocationManager;
import androidx.core.content.FileProvider;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.graphics.Insets;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.res.Resources;

import org.qtproject.qt.android.bindings.QtActivity;

public class NymeaAppActivity extends QtActivity
{
    private static final String TAG = "nymea-app: NymeaAppActivity";
    private static final String ESUI_1369_BUILD_MARKER = "[ESUI-1369] android-system-bar-cache-marker-v3";
    private static Context context = null;
    private boolean mDecorFitsSystemWindows = false;

    private static native void darkModeEnabledChangedJNI();
    private static native void notificationActionReceivedJNI(String data);
    private static native void locationServicesEnabledChangedJNI();

    private BroadcastReceiver m_gpsSwitchStateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            Log.i(TAG, "**** Intent received!!!" + intent.getAction());
            if (LocationManager.MODE_CHANGED_ACTION.equals(intent.getAction())) {
                locationServicesEnabledChangedJNI();
            }
        }
    };

    @Override
    public void onCreate(Bundle savedInstanceState) {
        Log.w(TAG, ESUI_1369_BUILD_MARKER + " onCreate: SDK_INT=" + Build.VERSION.SDK_INT);
        int themeId = resolveStyleResource("NormalTheme");
        if (themeId != 0) {
            setTheme(themeId);
            Log.w(TAG, ESUI_1369_BUILD_MARKER + " onCreate: applied NormalTheme (id=" + themeId + ")");
        } else {
            Log.w(TAG, "NormalTheme style missing, falling back to system theme");
            setTheme(android.R.style.Theme_DeviceDefault_DayNight);
        }
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT == 35) {
            // On API 35, opt out of edge-to-edge enforcement (still supported on this version).
            // PlatformHelper.topPadding() will return 0 since the system handles insets.
            WindowCompat.setDecorFitsSystemWindows(getWindow(), true);
            mDecorFitsSystemWindows = true;
            Log.w(TAG, ESUI_1369_BUILD_MARKER + " onCreate: API 35 - opted out of edge-to-edge");
        }
        // On API 36+, setDecorFitsSystemWindows(true) is ignored - edge-to-edge is mandatory.
        // mDecorFitsSystemWindows stays false so topPadding() reads the actual insets.
        Log.w(TAG, ESUI_1369_BUILD_MARKER + " onCreate: mDecorFitsSystemWindows=" + mDecorFitsSystemWindows
                + " darkModeEnabled=" + darkModeEnabled());
        this.context = getApplicationContext();
    }

    public void onNewIntent (Intent intent) {
        Log.d(TAG, "New intent: " + intent);
        String notificationData = intent.getStringExtra("notificationData");
        if (notificationData != null) {
            Log.d(TAG, "Intent data: " + notificationData);
            notificationActionReceivedJNI(notificationData);
        }
    }

    @Override
    public void onResume() {
        super.onResume();

        IntentFilter filter = new IntentFilter(LocationManager.MODE_CHANGED_ACTION);
        // filter.addAction(Intent.ACTION_PROVIDER_CHANGED);
        registerReceiver(m_gpsSwitchStateReceiver, filter);
    }

    @Override
    public void onPause() {
        super.onPause();
        unregisterReceiver(m_gpsSwitchStateReceiver);
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        NymeaAppActivity.darkModeEnabledChangedJNI();
    }

    public String notificationData() {
        return getIntent().getStringExtra("notificationData");
    }

    public static Context getAppContext() {
        return NymeaAppActivity.context;
    }

    public String deviceSerial()
    {
        return Secure.getString(getApplicationContext().getContentResolver(), Secure.ANDROID_ID);
    }

    public static String deviceManufacturer()
    {
        return Build.MANUFACTURER;
    }

    public static String deviceModel()
    {
        return Build.MODEL;
    }

    public static String device()
    {
        return Build.DEVICE;
    }

    public void vibrate(int duration)
    {
        Vibrator v = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);
        v.vibrate(duration);
    }

    public void shareFile(String fileName) {
        Intent sendIntent = new Intent();
        sendIntent.setAction(Intent.ACTION_SEND);
        sendIntent.setType("text/plain");
        Uri uri = FileProvider.getUriForFile(getApplicationContext(), getPackageName() + ".fileprovider", new File(fileName));
        sendIntent.putExtra(Intent.EXTRA_STREAM, uri);
        if (sendIntent.resolveActivity(getPackageManager()) != null) {
            startActivity(sendIntent);
        } else {
            Log.d(TAG, "Intent not resolved");
        }
    }

    public boolean darkModeEnabled() {
        return (getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES;
    }

    public boolean locationServicesEnabled() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // This is a new method provided in API 28
            LocationManager lm = (LocationManager) getApplicationContext().getSystemService(Context.LOCATION_SERVICE);
            return lm.isLocationEnabled();
        }

        // This was deprecated in API 28
        int mode = Settings.Secure.getInt(getApplicationContext().getContentResolver(), Settings.Secure.LOCATION_MODE, Settings.Secure.LOCATION_MODE_OFF);
        return (mode != Settings.Secure.LOCATION_MODE_OFF);
    }

    public int topPadding() {
        if (mDecorFitsSystemWindows || Build.VERSION.SDK_INT < 35) {
            return 0;
        }

        WindowInsets windowInsets = getWindow().getDecorView().getRootWindowInsets();

        if (windowInsets == null) {
            return 0;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Insets insets = windowInsets.getInsets(WindowInsets.Type.statusBars() | WindowInsets.Type.displayCutout());
            return insets != null ? insets.top : 0;
        }

        return windowInsets.getStableInsetTop();
    }

    public int bottomPadding() {
        if (mDecorFitsSystemWindows || Build.VERSION.SDK_INT < 35) {
            return 0;
        }

        WindowInsets windowInsets = getWindow().getDecorView().getRootWindowInsets();
        if (windowInsets == null) {
            return 0;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Insets insets = windowInsets.getInsets(WindowInsets.Type.navigationBars() | WindowInsets.Type.displayCutout());
            return insets != null ? insets.bottom : 0;
        }

        return windowInsets.getStableInsetBottom();
    }

    public int leftPadding() {
        if (mDecorFitsSystemWindows || Build.VERSION.SDK_INT < 35) {
            return 0;
        }

        WindowInsets windowInsets = getWindow().getDecorView().getRootWindowInsets();
        if (windowInsets == null) {
            return 0;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Insets insets = windowInsets.getInsets(WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
            return insets != null ? insets.left : 0;
        }

        return windowInsets.getStableInsetLeft();
    }

    public int rightPadding() {
        if (mDecorFitsSystemWindows || Build.VERSION.SDK_INT < 35) {
            return 0;
        }

        WindowInsets windowInsets = getWindow().getDecorView().getRootWindowInsets();
        if (windowInsets == null) {
            return 0;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Insets insets = windowInsets.getInsets(WindowInsets.Type.systemBars() | WindowInsets.Type.displayCutout());
            return insets != null ? insets.right : 0;
        }

        return windowInsets.getStableInsetRight();
    }

    /**
     * Tells Android whether the status bar icons (clock, signal, battery)
     * should be drawn dark (true) or light (false). Pass `true` when the
     * area behind the status bar is light, `false` when it is dark.
     *
     * No-op below API 23 (M); WindowInsetsControllerCompat falls back to
     * legacy SystemUiVisibility flags up to that point.
     */
    public void setLightStatusBar(final boolean darkIcons) {
        Log.w(TAG, ESUI_1369_BUILD_MARKER + " setLightStatusBar: darkIcons=" + darkIcons
                + " SDK_INT=" + Build.VERSION.SDK_INT
                + " darkModeEnabled=" + darkModeEnabled());
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Window window = getWindow();
                View decorView = window.getDecorView();
                WindowInsetsControllerCompat controller =
                        WindowCompat.getInsetsController(window, decorView);
                if (controller != null) {
                    controller.setAppearanceLightStatusBars(darkIcons);
                    Log.w(TAG, ESUI_1369_BUILD_MARKER + " setLightStatusBar: applied darkIcons=" + darkIcons);
                } else {
                    Log.w(TAG, ESUI_1369_BUILD_MARKER + " setLightStatusBar: WindowInsetsControllerCompat is null");
                }
            }
        });
    }

    /**
     * Tells Android whether the navigation/gesture bar icons should be
     * drawn dark (true) or light (false). Pass `true` when the area
     * behind the navigation bar is light, `false` when it is dark.
     *
     * No-op below API 26 (O); WindowInsetsControllerCompat handles
     * the version check internally.
     */
    public void setLightNavigationBar(final boolean darkIcons) {
        Log.w(TAG, ESUI_1369_BUILD_MARKER + " setLightNavigationBar: darkIcons=" + darkIcons
                + " SDK_INT=" + Build.VERSION.SDK_INT
                + " darkModeEnabled=" + darkModeEnabled());
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Window window = getWindow();
                View decorView = window.getDecorView();
                WindowInsetsControllerCompat controller =
                        WindowCompat.getInsetsController(window, decorView);
                if (controller != null) {
                    controller.setAppearanceLightNavigationBars(darkIcons);
                    Log.w(TAG, ESUI_1369_BUILD_MARKER + " setLightNavigationBar: applied darkIcons=" + darkIcons);
                } else {
                    Log.w(TAG, ESUI_1369_BUILD_MARKER + " setLightNavigationBar: WindowInsetsControllerCompat is null");
                }
            }
        });
    }

    private void logStaticInitClassesMetadata() {
        try {
            ApplicationInfo appInfo = getPackageManager().getApplicationInfo(getPackageName(), PackageManager.GET_META_DATA);
            if (appInfo.metaData == null || !appInfo.metaData.containsKey("android.app.static_init_classes")) {
                 Log.w(TAG, "No android.app.static_init_classes meta-data present in the manifest");
                 return;
            }

            Object value = appInfo.metaData.get("android.app.static_init_classes");
            if (!(value instanceof Integer)) {
            Log.w(TAG, "android.app.static_init_classes meta-data is not a resource reference: " + value);
            return;
            }

            int resId = (Integer) value;
            if (resId == 0) {
            Log.e(TAG, "android.app.static_init_classes meta-data resolves to resource id 0");
            return;
            }

            try {
             String resName = getResources().getResourceName(resId);
             String resValue = getResources().getString(resId);
             Log.i(TAG, "android.app.static_init_classes -> " + resName + " = " + resValue);
            } catch (Resources.NotFoundException notFoundException) {
             Log.e(TAG, "android.app.static_init_classes references missing resource 0x" + Integer.toHexString(resId), notFoundException);
            }
        } catch (PackageManager.NameNotFoundException exception) {
            Log.e(TAG, "Failed to inspect android.app.static_init_classes meta-data", exception);
        }
    }

    private int resolveStyleResource(String resourceName) {
        // Resolve app resources dynamically to support branded package names.
        return getResources().getIdentifier(resourceName, "style", getPackageName());
    }
}
