allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as? com.android.build.gradle.BaseExtension
            if (android != null) {
                // Force a consistent compile SDK version to avoid AAPT errors in older plugins
                android.compileSdkVersion(36)
                
                if (android.namespace == null) {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestText = manifestFile.readText()
                        val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestText)
                        if (packageMatch != null) {
                            android.namespace = packageMatch.groupValues[1]
                        }
                    }
                    
                    // Fallback for known problematic plugins if discovery fails
                    if (android.namespace == null) {
                        if (project.name.contains("ota_update")) {
                            android.namespace = "sk.fourq.ota_update"
                        } else if (project.name.contains("rdservice")) {
                            android.namespace = "com.madali.rdservice"
                        }
                    }
                }
            }
        }
    }
}

subprojects {
    afterEvaluate {
        configurations.all {
            resolutionStrategy {
                force("androidx.core:core:1.13.0")
                force("androidx.core:core-ktx:1.13.0")
            }
        }
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
