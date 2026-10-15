# Google Mobile Ads & Mediation Adapters
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.mediation.** { *; }

# Unity Ads Mediation
-keep class com.unity3d.ads.** { *; }
-keep class com.unity3d.services.** { *; }
-dontwarn com.unity3d.**

# Liftoff Monetize (Vungle) Mediation
-keep class com.vungle.ads.** { *; }
-dontwarn com.vungle.ads.**
-keepattributes Signature,InnerClasses,EnclosingMethod,Annotation
-keepclassmembers class * {
    @kotlinx.serialization.Serializable <fields>;
}
