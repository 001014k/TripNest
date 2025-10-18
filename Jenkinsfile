pipeline {
    agent any


    environment {
        FLUTTER_HOME = "/Users/gimmyeongjong/flutter" //
        PATH = "$FLUTTER_HOME/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    }
    stages {
        // 1️⃣ 코드 가져오기
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/001014k/TripNest.git',
                    credentialsId: 'github-token'
            }
        }

        // ⚡ 환경 확인 스테이지 추가
            stage('Check Environment') {
                steps {
                    sh 'echo $PATH'
                    sh 'which flutter'
                    sh 'which sh'
                    sh 'flutter --version'
                }
            }

        // 2️⃣ Flutter 의존성 설치
        stage('Dependencies') {
            steps {
                sh 'flutter pub get'
            }
        }

        // 3️⃣ 코드 분석
        stage('Analyze') {
            steps {
                sh 'flutter analyze --no-fatal-warnings || true'
            }
        }

        // 4️⃣ Android APK 빌드
        /* stage('Build Android APK') {
            steps {
                sh 'flutter build apk --release --target-platform=android-arm64'
            }
        } */

        // 5️⃣ iOS 빌드 준비
        stage('iOS Setup') {
            steps {
                sh '''
                    cd ios
                    pod install
                '''
            }
        }

        // 6️⃣ iOS 빌드
        stage('Build iOS') {
            steps {
                sh 'flutter build ios --release --no-codesign'
            }
        }

        // 7️⃣ iOS TestFlight 배포 (Fastlane 사용)
        stage('Distribute iOS') {
            steps {
                sh '''
                    cd ios
                    fastlane beta
                '''
            }
        }

        // 8️⃣ 빌드 결과 아카이브
        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: '''
                    build/app/outputs/flutter-apk/app-release.apk,
                    build/ios/iphoneos/Runner.app
                ''', fingerprint: true
            }
        }
    }

    post {
        success {
            echo '✅ Android + iOS build and iOS TestFlight deploy succeeded!'
        }
        failure {
            echo '❌ Build or deploy failed!'
        }
    }
}
