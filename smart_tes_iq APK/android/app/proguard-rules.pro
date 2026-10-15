# Google Mobile Ads Mediation Adapters (entry points dipanggil via reflection oleh AdMob)
-keep class com.google.ads.mediation.unity.** { *; }
-keep class com.google.ads.mediation.vungle.** { *; }

# Unity Ads Mediation (jaga WebView bridge & izinkan obfuscation class internal)
-keep,allowobfuscation class com.unity3d.ads.** { *; }
-keep,allowobfuscation class com.unity3d.services.** { *; }
-keepclassmembers class * {
    @com.unity3d.services.core.webview.bridge.WebViewExposed <methods>;
    @android.webkit.JavascriptInterface <methods>;
}
-dontwarn com.unity3d.**

# Liftoff Monetize (Vungle) Mediation (jaga Kotlinx Serialization & Protobuf)
-dontwarn com.vungle.ads.**
-keepattributes Signature,InnerClasses,EnclosingMethod,Annotation
-keepclassmembers class * {
    @kotlinx.serialization.Serializable <fields>;
}
-keepclassmembers class com.vungle.ads.** {
    public static ** Companion;
    kotlinx.serialization.KSerializer serializer(...);
}

