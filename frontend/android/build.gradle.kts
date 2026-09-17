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

// sqlite3_flutter_libs 0.5.42 still declares AGP 8.7.3 in its own
// buildscript. That extra download fails when Google Maven stalls; the
// app already resolves AGP 9.0.1 via pluginManagement.
subprojects {
    buildscript {
        configurations.classpath {
            resolutionStrategy.eachDependency {
                if (requested.group == "com.android.tools.build" &&
                    requested.name == "gradle"
                ) {
                    useVersion("9.0.1")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
