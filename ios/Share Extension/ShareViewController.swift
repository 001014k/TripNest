import UIKit
import Social

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ ShareViewController 진입됨")

        // 1. 공유된 컨텐츠가 있는지 확인하기 위해 extensionContext의 첫 번째 inputItems를 가져온다
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            print("❌ extensionContext?.inputItems.first 가 nil 이거나 NSExtensionItem 아님")
            return
        }
        print("✅ extensionItem 발견")

        // 2. extensionItem 내 attachments 배열의 첫 번째 항목(itemProvider)를 가져온다
        guard let itemProvider = extensionItem.attachments?.first else {
            print("❌ extensionItem.attachments?.first 가 nil")
            return
        }
        print("✅ itemProvider 발견")

        // 3. 공유된 아이템이 URL 타입인지 확인
        if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            print("✅ public.url 타입 아이템 존재")
            // 4. URL 타입 데이터를 비동기적으로 읽는다
            itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { (url, error) in
                if let shareURL = url as? URL {
                    print("✅ 공유된 URL: \(shareURL.absoluteString)")
                    // 5. 읽은 URL 문자열을 App Group 공유 저장소에 저장
                    self.saveAddressToAppGroup(shareURL.absoluteString)

                    // 6. UI 업데이트를 메인 스레드에서 수행 (성공 알림창 띄우기)
                    DispatchQueue.main.async {
                        self.showSuccessAlert()
                    }
                } else {
                    // URL 읽기에 실패했거나 nil인 경우 에러 로그 출력
                    print("❌ URL 변환 실패 또는 nil, error: \(error?.localizedDescription ?? "없음")")
                }
            }
        }
        // 7. 만약 URL 타입이 아니라 plain text 타입이 있는지 체크
        else if itemProvider.hasItemConformingToTypeIdentifier("public.plain-text") {
            print("✅ public.plain-text 타입 아이템 존재")
            // 8. plain text 타입 데이터를 비동기적으로 읽는다
            itemProvider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { (text, error) in
                if let shareText = text as? String {
                    print("✅ 공유된 텍스트: \(shareText)")
                    // 9. 읽은 텍스트를 App Group 공유 저장소에 저장
                    self.saveAddressToAppGroup(shareText)

                    // 10. UI 업데이트를 메인 스레드에서 수행 (성공 알림창 띄우기)
                    DispatchQueue.main.async {
                        self.showSuccessAlert()
                    }
                } else {
                    // 텍스트 읽기에 실패했거나 nil인 경우 에러 로그 출력
                    print("❌ 텍스트 변환 실패 또는 nil, error: \(error?.localizedDescription ?? "없음")")
                }
            }
        } else {
            // 11. URL, 텍스트 둘 다 아닌 경우 - 지원하지 않는 타입임을 로그로 알림
            print("⚠️ 공유된 아이템이 'public.url' 혹은 'public.plain-text' 타입이 아님")
        }
    }

    /// App Group 공유 저장소에 전달받은 주소 또는 텍스트를 저장하는 메서드
    /// - Parameter address: 저장할 문자열 (URL 또는 텍스트)
    private func saveAddressToAppGroup(_ address: String) {
        guard let sharedURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.kimmyungjong.fluttertrip")?
            .appendingPathComponent("shared_address.txt") else {
            print("❌ AppGroup 경로 생성 실패")
            return
        }

        do {
            // 기존 내용 읽기 (없으면 빈 문자열)
            let existingText = (try? String(contentsOf: sharedURL, encoding: .utf8)) ?? ""
            var newText = existingText

            // 중복 주소 추가 방지
            if !existingText.contains(address) {
                if !existingText.isEmpty {
                    newText += "\n" // 줄바꿈으로 구분
                }
                newText += address
            } else {
                print("⚠️ 중복된 주소, 추가하지 않음")
                return
            }

            // 파일에 새 내용 쓰기 (append 효과)
            try newText.write(to: sharedURL, atomically: true, encoding: .utf8)
            print("✅ 공유 주소 추가 저장 완료: \(sharedURL.path)")
            print("📄 저장된 내용: \(newText)")
        } catch {
            print("❌ 공유 주소 저장 실패: \(error)")
        }
    }

    /// 공유 성공 알림창을 띄우고, 완료 후 확장 프로그램 종료를 처리하는 메서드
    private func showSuccessAlert() {
        let alert = UIAlertController(
                title: "공유 완료",
                message: "FlutterTrip 앱에서 공유한 내용을 확인하려면 앱을 직접 실행해 주세요.",
                preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            // 확장 프로그램 종료
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
