// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "SleepReminder",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "SleepReminder",
            path: "Sources/SleepReminder",
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("MemberImportVisibility"),
                .enableUpcomingFeature("DisableOutwardActorInference"),
                .enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("InferSendableFromCaptures"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        )
    ]
)
