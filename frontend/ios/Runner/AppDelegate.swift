import Flutter
import UIKit
import UniformTypeIdentifiers
import AuthenticationServices

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  UIDocumentPickerDelegate, ASWebAuthenticationPresentationContextProviding
{
  private var pickResult: FlutterResult?
  private var pickingDocument = false
  private var pickingDestination = false
  private var cloudSession: ASWebAuthenticationSession?
  private let scopedFolders = ScopedFolderWriter()
  private let incomingBundles = IncomingBundles()
  private var presentationWindow: UIWindow? {
    window ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }.first { $0.isKeyWindow }
  }

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
    FlutterMethodChannel(name: "com.tapture.app/cloud", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "signIn":
          let args = call.arguments as? [String: String]
          self?.signIn(args?["authorize"], args?["redirect"], result)
        case "cancelSignIn":
          self?.cloudSession?.cancel()
          self?.cloudSession = nil
          result(nil)
        case "folderBegin", "folderAppend", "folderFinish", "folderAbort", "folderProbe":
          self?.scopedFolders.handle(call, result)
        default: result(FlutterMethodNotImplemented)
        }
      }
    let filesChannel = FlutterMethodChannel(name: "com.tapture.app/files", binaryMessenger: messenger)
    incomingBundles.attach(filesChannel)
    filesChannel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "takeIncomingBundle": result(self?.incomingBundles.take())
        case "discardIncomingBundles": self?.incomingBundles.discard(); result(nil)
        case "pickDirectory":
          self?.pickDirectory(result)
        case "pickDestinationDirectory":
          self?.pickDirectory(result, destination: true)
        case "pickDocument":
          self?.pickDocument(result)
        case "volumeStats":
          let args = call.arguments as? [String: Any]
          self?.volumeStats(args?["path"] as? String, result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  func receiveIncomingBundle(_ url: URL) -> Bool { incomingBundles.receive(url) }

  override func application(_ app: UIApplication, open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if receiveIncomingBundle(url) { return true }
    return super.application(app, open: url, options: options)
  }

  private func signIn(_ address: String?, _ redirect: String?, _ result: @escaping FlutterResult) {
    guard cloudSession == nil, let address, let url = URL(string: address),
      url.scheme == "https", let redirect, let callback = URL(string: redirect),
      callback.scheme == "tapture", callback.host == "oauth", callback.path.isEmpty
    else {
      result(FlutterError(code: "sign_in_failed", message: "Cloud sign-in could not start.", details: nil))
      return
    }
    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callback.scheme) { [weak self] returned, error in
      DispatchQueue.main.async {
        self?.cloudSession = nil
        if let returned { result(returned.absoluteString) }
        else {
          let cancelled = (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin
          result(FlutterError(code: cancelled ? "cancelled" : "sign_in_failed", message: "Cloud sign-in did not finish.", details: nil))
        }
      }
    }
    cloudSession = session
    session.presentationContextProvider = self
    session.prefersEphemeralWebBrowserSession = true
    if !session.start() {
      cloudSession = nil
      result(FlutterError(code: "sign_in_failed", message: "Cloud sign-in could not start.", details: nil))
    }
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    presentationWindow ?? ASPresentationAnchor()
  }

  /// Total, used and free bytes on the volume holding `path`: the same reply
  /// MainActivity.kt gives, since iOS forbids running `df`.
  private func volumeStats(_ path: String?, _ result: @escaping FlutterResult) {
    let target = URL(fileURLWithPath: path ?? NSHomeDirectory())
    do {
      let values = try target.resourceValues(forKeys: [
        .volumeTotalCapacityKey,
        .volumeAvailableCapacityForImportantUsageKey,
      ])
      guard let total = values.volumeTotalCapacity,
        let free = values.volumeAvailableCapacityForImportantUsage
      else {
        result(FlutterError(code: "unreadable", message: "Could not read volume stats.", details: nil))
        return
      }
      let totalBytes = Int64(total)
      result([
        "totalBytes": totalBytes,
        "freeBytes": free,
        "usedBytes": max(totalBytes - free, 0),
      ])
    } catch {
      result(FlutterError(code: "unreadable", message: "Could not read volume stats.", details: nil))
    }
  }

  private func pickDirectory(_ result: @escaping FlutterResult, destination: Bool = false) {
    if pickResult != nil {
      result(
        FlutterError(code: "busy", message: "A folder pick is already open.", details: nil)
      )
      return
    }
    pickResult = result
    pickingDocument = false
    pickingDestination = destination
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [UTType.folder],
      asCopy: false
    )
    picker.delegate = self
    picker.allowsMultipleSelection = false
    presentationWindow?.rootViewController?.present(picker, animated: true)
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
    pickingDestination = false
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [UTType.zip],
      asCopy: true
    )
    picker.delegate = self
    picker.allowsMultipleSelection = false
    presentationWindow?.rootViewController?.present(picker, animated: true)
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
    if pickingDestination, let url {
      let accessing = url.startAccessingSecurityScopedResource()
      defer { if accessing { url.stopAccessingSecurityScopedResource() } }
      do {
        let bookmark = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        let id = UUID().uuidString
        UserDefaults.standard.set(bookmark, forKey: "tapture.folder.\(id)")
        pickResult?("tapture-folder:\(id)")
      } catch {
        pickResult?(FlutterError(code: "grant_lost", message: "Could not retain access to that folder.", details: nil))
      }
      pickResult = nil
      pickingDestination = false
      return
    }
    // A security-scoped folder needs a persistent bookmark and coordinated
    // native writes. A plain path would silently lose access after restart.
    pickResult?(
      FlutterError(
        code: "unsupported",
        message: "This folder requires a supported system folder grant.",
        details: nil
      )
    )
    pickResult = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pickResult?(
      FlutterError(code: "cancelled", message: "The pick was cancelled.", details: nil)
    )
    pickResult = nil
  }
}

/// User-opened files are copied in bounded chunks before Dart inspects them.
/// The main-thread queue holds at most two files; source files remain untouched.
private final class IncomingBundles {
  private let io = DispatchQueue(label: "com.tapture.app.incoming", qos: .utility)
  private var channel: FlutterMethodChannel?
  private var pending = [[String: Any]]()
  private var outstanding = 0
  private let generationLock = NSLock()
  private var generation = 0
  private enum CopyError: Error, Equatable { case tooLarge, unreadable }

  func attach(_ channel: FlutterMethodChannel) { self.channel = channel }

  func receive(_ url: URL) -> Bool {
    guard url.isFileURL, ["zip", "tapture"].contains(url.pathExtension.lowercased()) else { return false }
    guard outstanding < 2 else {
      channel?.invokeMethod("incomingBundleAvailable", arguments: ["error": "busy"])
      return true
    }
    outstanding += 1
    let receivedGeneration = currentGeneration()
    io.async {
      let target = FileManager.default.temporaryDirectory.appendingPathComponent("incoming-bundles", isDirectory: true)
        .appendingPathComponent("incoming-\(UUID().uuidString).zip")
      let accessing = url.startAccessingSecurityScopedResource()
      defer { if accessing { url.stopAccessingSecurityScopedResource() } }
      let payload: [String: Any]
      do {
        guard accessing || url.path.hasPrefix(NSHomeDirectory() + "/") else { throw CopyError.unreadable }
        let declared = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        if let declared, declared > 4_000_000_000 { throw CopyError.tooLarge }
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard FileManager.default.createFile(atPath: target.path, contents: nil) else { throw CopyError.unreadable }
        var count = 0
        var coordinationError: NSError?
        var copyError: Error?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { source in
          do { count = try self.copy(source, to: target, generation: receivedGeneration) }
          catch { copyError = error }
        }
        if let coordinationError { throw coordinationError }
        if let copyError { throw copyError }
        payload = ["path": target.path, "name": url.lastPathComponent, "byteLength": count]
      } catch {
        try? FileManager.default.removeItem(at: target)
        payload = ["error": (error as? CopyError) == .tooLarge ? "too_large" : "unreadable"]
      }
      DispatchQueue.main.async {
        guard receivedGeneration == self.currentGeneration() else {
          try? FileManager.default.removeItem(at: target)
          return
        }
        let notify = self.pending.isEmpty
        self.pending.append(payload)
        if notify { self.channel?.invokeMethod("incomingBundleAvailable", arguments: nil) }
      }
    }
    return true
  }

  func take() -> [String: Any]? {
    guard !pending.isEmpty else { return nil }
    outstanding -= 1
    return pending.removeFirst()
  }

  func discard() {
    generationLock.lock()
    generation += 1
    generationLock.unlock()
    for item in pending {
      if let path = item["path"] as? String { try? FileManager.default.removeItem(atPath: path) }
    }
    pending.removeAll()
    outstanding = 0
  }

  private func currentGeneration() -> Int {
    generationLock.lock()
    defer { generationLock.unlock() }
    return generation
  }

  private func copy(_ source: URL, to target: URL, generation receivedGeneration: Int) throws -> Int {
    let input = try FileHandle(forReadingFrom: source)
    defer { try? input.close() }
    let output = try FileHandle(forWritingTo: target)
    defer { try? output.close() }
    var count = 0
    while let bytes = try autoreleasepool(invoking: { try input.read(upToCount: 64 * 1024) }), !bytes.isEmpty {
      guard receivedGeneration == currentGeneration() else { throw CopyError.unreadable }
      count += bytes.count
      if count > 4_000_000_000 { throw CopyError.tooLarge }
      try output.write(contentsOf: bytes)
    }
    try output.synchronize()
    return count
  }
}

/// All scoped writes run on one native queue and hold access until publication
/// or cleanup. Temporary files use generated names; existing targets are preserved.
private final class ScopedFolderWriter {
  private struct Write {
    let folder: URL
    let temporary: URL
    let name: String
    let stream: FileHandle
    let accessing: Bool
  }
  private let queue = DispatchQueue(label: "com.tapture.app.folder-writes", qos: .utility)
  private var writes = [String: Write]()
  private enum WriteError: Error, Equatable { case invalid, grantLost, exists }

  func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    queue.async { [self] in
      do {
        let value: Any?
        switch call.method {
        case "folderBegin": value = try begin(args["folder"] as? String, args["name"] as? String)
        case "folderAppend":
          guard let bytes = args["bytes"] as? FlutterStandardTypedData, bytes.data.count <= 64 * 1024 else { throw WriteError.invalid }
          let writing = try write(args["session"] as? String)
          try writing.stream.write(contentsOf: bytes.data)
          value = nil
        case "folderFinish": value = try finish(args["session"] as? String)
        case "folderAbort": try abort(args["session"] as? String); value = nil
        case "folderProbe":
          let id = try begin(args["folder"] as? String, "tapture-probe-\(UUID().uuidString)")
          let writing = writes[id]!
          let accessing = writing.folder.startAccessingSecurityScopedResource()
          defer { if accessing { writing.folder.stopAccessingSecurityScopedResource() } }
          do {
            try writing.stream.write(contentsOf: Data([111, 107]))
            let published = URL(string: try finish(id))!
            try coordinate(writing.folder) { _ in try FileManager.default.removeItem(at: published) }
          }
          catch { try? abort(id); throw error }
          value = nil
        default: throw WriteError.invalid
        }
        DispatchQueue.main.async { result(value) }
      } catch {
        let code = (error as? WriteError) == .grantLost ? "grant_lost" : "write_failed"
        DispatchQueue.main.async { result(FlutterError(code: code, message: "Could not write to the chosen folder.", details: nil)) }
      }
    }
  }

  private func begin(_ grant: String?, _ name: String?) throws -> String {
    guard let grant, grant.hasPrefix("tapture-folder:"), let name, !name.isEmpty,
      name != ".", name != "..", !name.contains("/"), !name.contains("\\"),
      let bookmark = UserDefaults.standard.data(forKey: "tapture.folder.\(grant.dropFirst("tapture-folder:".count))")
    else { throw WriteError.grantLost }
    var stale = false
    let folder: URL
    do { folder = try URL(resolvingBookmarkData: bookmark, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &stale) }
    catch { throw WriteError.grantLost }
    let accessing = folder.startAccessingSecurityScopedResource()
    guard accessing || folder.path.hasPrefix(NSHomeDirectory() + "/") else { throw WriteError.grantLost }
    var retained = false
    defer { if !retained && accessing { folder.stopAccessingSecurityScopedResource() } }
    if stale {
      let fresh = try folder.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
      UserDefaults.standard.set(fresh, forKey: "tapture.folder.\(grant.dropFirst("tapture-folder:".count))")
    }
    let temporary = folder.appendingPathComponent(".tapture-\(UUID().uuidString).partial")
    try coordinate(folder) { resolved in
      guard !FileManager.default.fileExists(atPath: resolved.appendingPathComponent(name).path) else { throw WriteError.exists }
      guard FileManager.default.createFile(atPath: temporary.path, contents: nil) else { throw WriteError.invalid }
    }
    let stream: FileHandle
    do { stream = try FileHandle(forWritingTo: temporary) }
    catch { try? FileManager.default.removeItem(at: temporary); throw error }
    let id = UUID().uuidString
    writes[id] = Write(folder: folder, temporary: temporary, name: name, stream: stream, accessing: accessing)
    retained = true
    return id
  }

  private func write(_ id: String?) throws -> Write {
    guard let id, let writing = writes[id] else { throw WriteError.invalid }
    return writing
  }

  private func finish(_ id: String?) throws -> String {
    let writing = try write(id)
    try writing.stream.synchronize()
    try writing.stream.close()
    var published = writing.folder.appendingPathComponent(writing.name)
    try coordinate(writing.folder) { folder in
      published = folder.appendingPathComponent(writing.name)
      guard !FileManager.default.fileExists(atPath: published.path) else { throw WriteError.exists }
      try FileManager.default.moveItem(at: writing.temporary, to: published)
    }
    writes.removeValue(forKey: id!)
    if writing.accessing { writing.folder.stopAccessingSecurityScopedResource() }
    return published.absoluteString
  }

  private func abort(_ id: String?) throws {
    guard let id, let writing = writes.removeValue(forKey: id) else { return }
    defer { if writing.accessing { writing.folder.stopAccessingSecurityScopedResource() } }
    try? writing.stream.close()
    try coordinate(writing.folder) { _ in
      if FileManager.default.fileExists(atPath: writing.temporary.path) { try FileManager.default.removeItem(at: writing.temporary) }
    }
  }

  private func coordinate(_ folder: URL, work: (URL) throws -> Void) throws {
    let coordinator = NSFileCoordinator()
    var coordinationError: NSError?
    var operationError: Error?
    coordinator.coordinate(writingItemAt: folder, options: .forMerging, error: &coordinationError) { url in
      do { try work(url) } catch { operationError = error }
    }
    if let coordinationError { throw coordinationError }
    if let operationError { throw operationError }
  }
}
