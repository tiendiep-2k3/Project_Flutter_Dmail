import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

plugins {
    // Plugin Google Services (apply false vì sẽ apply trong app-level)
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Tuỳ chọn: thay đổi thư mục build chung cho các module
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// Task dọn dẹp
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
