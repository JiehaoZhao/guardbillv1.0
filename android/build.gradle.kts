import java.io.File
import com.android.build.gradle.LibraryExtension

val customBuildDir = File(rootProject.projectDir, "../build")
rootProject.buildDir = customBuildDir

subprojects {
    project.buildDir = File(customBuildDir, project.name)

    afterEvaluate {
        extensions.findByType(LibraryExtension::class)?.let {
            if (it.namespace == null) {
                it.namespace = project.group.toString()
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
