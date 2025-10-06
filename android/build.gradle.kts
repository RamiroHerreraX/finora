plugins {
    // Android y Kotlin, no especificamos versión, Flutter maneja la versión correcta
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false

    // Plugin de Google Services para Firebase
    id("com.google.gms.google-services") version "4.4.3" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Cambiar la carpeta de build para todo el proyecto
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Tarea para limpiar el build
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
