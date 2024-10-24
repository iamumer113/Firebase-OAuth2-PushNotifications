//
//  NotififcationHandler.swift
//  Girl Watch Out
//
//  Created by Umar Farooq on 29/09/2024.
//

import Foundation
import Firebase
import SwiftJWT


class FirebasePushNotificationManager {
    static let shared = FirebasePushNotificationManager()

    private let projectID: String
    private let clientEmail: String
    private let privateKey: String

    private init() {
        // Initialize with your project settings
        self.projectID = "projectID"
        self.clientEmail = "firebase-adminsdk@projectName.iam.gserviceaccount.com"
        self.privateKey = """
-----BEGIN PRIVATE \n-----END PRIVATE KEY-----\n
"""
    }

    // Define the JWT payload
    struct MyClaims: Claims {
        let iss: String
        let sub: String
        let aud: String
        let exp: Date
    }

    private func generateJWTToken() -> String? {
              struct JWTClaims: Claims {
                  let iss: String
                  let scope: String
                  let aud: String
                  let iat: Date
                  let exp: Date
              }
   
              // Create the claims
              let currentTime = Date()
              let expirationTime = currentTime.addingTimeInterval(3600) // 1 hour expiration
              let claims = JWTClaims(
                  iss: clientEmail,
                  scope: "https://www.googleapis.com/auth/firebase.messaging",
                  aud: "https://oauth2.googleapis.com/token",
                  iat: currentTime,
                  exp: expirationTime
              )
   
              // Create the header and sign with the private key
              var jwt = JWT(claims: claims)
   
              // Convert private key to the correct format (remove header and footer)
              let privateKeyFormatted = privateKey
                  .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
                  .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
                  .replacingOccurrences(of: "\n", with: "")
                  .replacingOccurrences(of: "\\n", with: "")
   
              // Convert private key from base64
              guard let privateKeyData = Data(base64Encoded: privateKeyFormatted) else {
                  print("Error converting private key.")
                  return nil
              }
   
              // Create a signer using SwiftJWT's RS256 algorithm
              let signer = JWTSigner.rs256(privateKey: privateKeyData)
   
              // Sign the JWT and return the signed token
              do {
                  let signedJWT = try jwt.sign(using: signer)
                  return signedJWT
              } catch {
                  print("Failed to sign JWT: \(error)")
                  return nil
              }
          }
       

    private func getAccessToken(completion: @escaping (String?) -> Void) {
        guard let jwt = generateJWTToken() else {
            print("Failed to generate JWT.")
            completion(nil)
            return
        }

        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"
        request.httpBody = body.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error getting access token: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received.")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    completion(accessToken)
                } else {
                    print("Failed to parse JSON response.")
                    completion(nil)
                }
            } catch {
                print("Error parsing response: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }

    func sendPushNotification(to fcmToken: String, title: String, body: String) {
        getAccessToken { [weak self] accessToken in
            guard let accessToken = accessToken else {
                print("Failed to obtain access token.")
                return
            }
            self?.sendNotification(to: fcmToken, title: title, body: body, accessToken: accessToken)
        }
    }

    private func sendNotification(to fcmToken: String, title: String, body: String, accessToken: String) {
        let urlString = "https://fcm.googleapis.com/v1/projects/\(projectID)/messages:send"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let message: [String: Any] = [
            "message": [
                "token": fcmToken,
                "notification": [
                    "title": title,
                    "body": body
                ]
            ]
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error creating JSON data: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending push notification: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200 {
                    print("Successfully sent notification!")
                } else {
                    print("Failed to send notification.")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString)")
                    }
                }
            }
        }.resume()
    }
}

