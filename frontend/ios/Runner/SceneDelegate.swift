import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    for context in connectionOptions.urlContexts {
      _ = (UIApplication.shared.delegate as? AppDelegate)?.receiveIncomingBundle(context.url)
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    let remaining = Set(URLContexts.filter {
      (UIApplication.shared.delegate as? AppDelegate)?.receiveIncomingBundle($0.url) != true
    })
    if !remaining.isEmpty { super.scene(scene, openURLContexts: remaining) }
  }
}
