allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set build directory for root project
rootProject.layout.buildDirectory.set(
    rootProject.layout.projectDirectory.dir("../../build")
)

subprojects {
    // Set build directory for each subproject
    layout.buildDirectory.set(
        rootProject.layout.buildDirectory.dir(project.name)
    )
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}