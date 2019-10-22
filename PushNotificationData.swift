import Foundation

// MARK: - PushNotificationData
class PushNotificationData: Codable {
    let date, messageBody, mobileNumber, id: String?
    let title, type, messageTemplate, transactionId: String?

    enum CodingKeys: String, CodingKey {
        case date, messageBody, mobileNumber, id, title, type, messageTemplate
        case transactionId
    }

    init(date: String, messageBody: String, mobileNumber: String, id: String, title: String, type: String, messageTemplate: String, transactionId: String) {
        self.date = date
        self.messageBody = messageBody
        self.mobileNumber = mobileNumber
        self.id = id
        self.title = title
        self.type = type
        self.messageTemplate = messageTemplate
        self.transactionId = transactionId
    }
    
    init(dictionary: [String:Any]) {
      // set the Optional ones
      self.date = dictionary["date"] as? String
      self.messageBody = dictionary["messageBody"] as? String
      self.mobileNumber = dictionary["mobileNumber"] as? String
      self.id = dictionary["id"] as? String
      self.title = dictionary["title"] as? String
      self.type = dictionary["type"] as? String
      self.messageTemplate = dictionary["messageTemplate"] as? String
      self.transactionId = dictionary["transactionId"] as? String
    }
}

