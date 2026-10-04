// swift-tools-version: 5.9
//
// The SwiftPM build of the tapture_whisper FFI plugin for iOS and macOS
// (dev-plan task 105, app-write-up section 30.4.1). tapture_whisper.podspec
// one folder up is the CocoaPods build of the same sources with the same
// settings.
//
// Sources/tapture_whisper holds only generated one-line forwarders
// (tool/whisper_vendor.dart) that include the vendored whisper.cpp and the
// shim in place: SwiftPM forbids include paths outside the target, so
// forward/ stands in for them. The definitions and flags are those
// src/CMakeLists.txt uses for Apple, plus Accelerate for vDSP only;
// test/tool/whisper_vendor_test.dart holds both manifests to that. A local
// path package may use unsafe flags.
//
// The product is dynamic so the tw_* symbols, which only Dart looks up, are
// never dead-stripped from a static archive. There are no architecture
// flags (no AVX2 on macOS x86_64), and no Metal, CoreML, BLAS or OpenMP.
import PackageDescription

let defines: [(name: String, value: String?)] = [
    ("GGML_USE_CPU", nil),
    ("GGML_USE_CPU_REPACK", nil),
    ("GGML_SCHED_MAX_COPIES", "4"),
    ("NDEBUG", nil),
    ("WHISPER_VERSION", "\"1.9.4\""),
    ("_XOPEN_SOURCE", "600"),
    ("_DARWIN_C_SOURCE", nil),
    ("TW_BUILD", nil),
    ("TW_ENGINE", "1"),
    ("GGML_USE_ACCELERATE", nil),
    ("ACCELERATE_NEW_LAPACK", nil),
    ("ACCELERATE_LAPACK_ILP64", nil),
]

let cFlags: [String] = ["-O3", "-ffunction-sections", "-fdata-sections", "-w", "-fvisibility=hidden"]
let cxxFlags: [String] = cFlags + ["-fvisibility-inlines-hidden"]

let package = Package(
    name: "tapture_whisper",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15"),
    ],
    products: [
        .library(name: "tapture-whisper", type: .dynamic, targets: ["tapture_whisper"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "tapture_whisper",
            dependencies: [],
            path: "Sources/tapture_whisper",
            publicHeadersPath: "include",
            cSettings: [CSetting.headerSearchPath("forward"), CSetting.unsafeFlags(cFlags)]
                + defines.map { CSetting.define($0.name, to: $0.value) },
            cxxSettings: [CXXSetting.headerSearchPath("forward"), CXXSetting.unsafeFlags(cxxFlags)]
                + defines.map { CXXSetting.define($0.name, to: $0.value) },
            linkerSettings: [
                .linkedFramework("Accelerate"),
            ]
        ),
    ],
    cLanguageStandard: .c11,
    cxxLanguageStandard: .cxx17
)
