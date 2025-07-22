import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Google Maps API Key 설정
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
      GMSServices.provideAPIKey(apiKey)
    }

    // ✅ Flutter Plugin 등록
    GeneratedPluginRegistrant.register(with: self)

    // ✅ App Group Platform Channel 설정
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.fluttertrip.appgroup", binaryMessenger: controller.binaryMessenger)

      channel.setMethodCallHandler { call, result in
        print("▶️ MethodChannel 호출: \(call.method)")  // 호출 메서드 로그 추가

        switch call.method {
        case "getSharedAddress":
          print("🔍 getSharedAddress 처리 시작")
          self.handleGetSharedAddress(result: result)
        case "clearSharedAddress":
          print("🔍 clearSharedAddress 처리 시작")
          self.handleClearSharedAddress(result: result)
        default:
          print("⚠️ 미구현 메서드 호출: \(call.method)")
          result(FlutterMethodNotImplemented)
        }
      }
    } else {
      print("❌ FlutterViewController를 찾지 못함")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ 공유 주소 읽기 메서드
  private func handleGetSharedAddress(result: FlutterResult) {
    guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.kimmyungjong.fluttertrip") else {
      print("❌ App Group 경로 가져오기 실패")
      result(nil)
      return
    }

    print("📂 App Group 경로: \(containerURL.path)") // 경로 확인용

    let fileURL = containerURL.appendingPathComponent("shared_address.txt")
    do {
      let content = try String(contentsOf: fileURL, encoding: .utf8)
      print("📤 공유 주소 반환: \(content)") // 파일 읽기 성공 로그
      result(content)
    } catch {
      print("⚠️ 공유 주소 파일 없음 또는 읽기 실패: \(error)") // 실패 로그
      result(nil)
    }
  }

  // ✅ 공유 주소 삭제 메서드
  private func handleClearSharedAddress(result: FlutterResult) {
    guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.kimmyungjong.fluttertrip") else {
      print("❌ App Group 경로 가져오기 실패")
      result(false)
      return
    }

    let fileURL = containerURL.appendingPathComponent("shared_address.txt")
    do {
      try FileManager.default.removeItem(at: fileURL)
      print("🗑️ 공유 주소 삭제 완료")
      result(true)
    } catch {
      print("⚠️ 공유 주소 삭제 실패: \(error)")
      result(false)
    }
  }
}
