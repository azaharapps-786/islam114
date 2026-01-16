import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// --- NEW FIX FOR VOSK_FLUTTER WITHOUT afterEvaluate ---
subprojects {
    // We listen for the moment the Android plugins are applied to libraries
    plugins.withType<com.android.build.gradle.api.AndroidBasePlugin> {
        val android = project.extensions.getByType<BaseExtension>()
        // If the library (like vosk_flutter) didn't set a namespace, we set it now
        if (android.namespace == null) {
            android.namespace = project.group.toString()
        }
    }
}