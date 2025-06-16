# Flutter local notifications ve Gson için ProGuard kuralları

# Gson generic types korunması için
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Gson için genel kurallar
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# Flutter local notifications için özel kurallar
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin { *; }

# FlutterLocalNotificationsPlugin ve bağımlılıkları
-keep class com.dexterous.** { *; }
-keep interface com.dexterous.** { *; }

# Gson'un kullandığı reflection sınıflarını koruma
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# Notification model sınıfları için
-keep class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Generic signature bilgilerini koruma
-keepattributes Signature, InnerClasses, EnclosingMethod

# Annotation'ları koruma
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations

# Enum sınıfları için
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Serialization için
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# AlarmManager ve bildirim servisleri için
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Activity

# Flutter plugin registration
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Play Core için ek kurallar (Flutter ile uyumluluk için)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Flutter Play Store split için
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Diğer önemli sınıflar
-dontwarn com.google.gson.**
-dontwarn sun.misc.**

# Flutter için ek güvenlik kuralları
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Android X için
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.** 