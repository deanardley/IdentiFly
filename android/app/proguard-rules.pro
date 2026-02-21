# Prevent R8 from stripping away TensorFlow Lite GPU delegate classes
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.support.** { *; }

# This tells R8 to ignore the specific missing "Options" class it's complaining about
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
-dontwarn org.tensorflow.lite.gpu.**

# If you use the Support Library/Task API, add these too:
-dontwarn org.tensorflow.lite.support.**