import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  UIDocumentPickerDelegate
{
  private var pickResult: FlutterResult?
  private var pickingDocument = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.pluginRegistry.registrar(
      forPlugin: "tapture.files"
    )?.messenger()
    guard let messenger else {
      return
    }
    FlutterMethodChannel(name: "com.tapture.app/files", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "pickDirectory":
          self?.pickDirectory(result)
        case "pickDocument":
          self?.pickDocument(result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private func pickDirectory(_ result: @escaping FlutterResult) {
    if pickResult != nil {
      result(
        FlutterError(code: "busy", message: "A folder pick is already open.", details: nil)
      )
      return
    }
    pickResult = result
    pickingDocument = false
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [UTType.folder],
      asCopy: false
    )
    picker.delegate = self
    picker.allowsMultipleSelection = false
    window?.rootViewController?.present(picker, animated: true)
  }

  /// One ZIP, copied into the app's sandbox so Dart reads a plain file.
  private func pickDocument(_ result: @escaping FlutterResult) {
    if pickResult != nil {
      result(
        FlutterError(code: "busy", message: "A file pick is already open.", details: nil)
      )
      return
    }
    pickResult = result
    pickingDocument = true
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [UTType.zip],
      asCopy: true
    )
    picker.delegate = self
    picker.allowsMultipleSelection = false
    window?.rootViewController?.present(picker, animated: true)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    let url = urls.first
    if pickingDocument {
      let size = (try? url?.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
      pickResult?(
        url.map { ["path": $0.path, "name": $0.lastPathComponent, "byteLength": size] }
      )
      pickResult = nil
      return
    }
    _ = url?.startAccessingSecurityScopedResource()
    pickResult?(url?.path)
    pickResult = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pickResult?(
      FlutterError(code: "cancelled", message: "The pick was cancelled.", details: nil)
    )
    pickResult = nil
  }
}
