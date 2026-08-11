# ML Kit découvre ces composants par réflexion à partir du manifeste.
# R8 doit donc conserver leurs constructeurs publics sans argument.
-keep,allowoptimization,allowobfuscation class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}

# Protection explicite pour les registrars ML Kit utilisés par le scanner.
-keep,allowoptimization,allowobfuscation class com.google.mlkit.**.*Registrar {
    public <init>();
}
