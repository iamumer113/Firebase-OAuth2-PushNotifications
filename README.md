# Firebase-OAuth2-PushNotifications
Send Firebase-OAuth2-PushNotifications with Swift For iOS
# Firebase Push Notification Manager (OAuth 2.0)

This project provides an implementation for sending Firebase push notifications directly from one iOS device to another using OAuth 2.0, without a backend server.

## Installation

1. Clone this repository:
    ```bash
    git clone https://github.com/your-username/FirebasePushNotificationManager.git
    ```

2. Add the `FirebasePushNotificationManager` class to your Xcode project.

## Usage

1. Authorize notifications and register for remote notifications as usual with Firebase Cloud Messaging (FCM).
2. Collect the APNs token and retrieve the FCM token from Firebase.
3. Use the following to send notifications from one iOS device to another:

    ```swift
    FirebasePushNotificationManager.shared.sendPushNotification(
        to: user.fcmToken,
        title: "Title",
        body: "Message."
    )
    ```

You are free to use and modify this class according to your requirements.

Make sure to replace the `projectID`, `clientEmail`, and `privateKey` inside the `FirebasePushNotificationManager` class.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
