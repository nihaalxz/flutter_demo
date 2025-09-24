# Razorpay fix
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }

-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
