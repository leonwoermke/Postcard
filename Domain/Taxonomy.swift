import Foundation

public enum MessageKind: Equatable, Hashable, Sendable, Codable {
    case conversational

    case schedulingRequest
    case schedulingConfirmation
    case calendarInvite
    case schedulingCancellation

    case orderConfirmation
    case shippingNotification
    case deliveryConfirmation
    case returnConfirmation
    case paymentReceipt
    case paymentFailure
    case subscriptionConfirmation
    case subscriptionCancellation

    case verificationRequest
    case securityAlert
    case passwordReset

    case travelBookingConfirmation
    case travelStatusChange
    case boardingPass
    case travelReminder

    case statement
    case invoice
    case documentDelivery
    case signatureRequest
    case legalNotice

    case serviceAlert
    case activityNotification
    case developmentNotification

    case digest
    case newsletter

    case promotionalOffer
    case productAnnouncement
    case eventInvitation
    case loyaltyUpdate
    case surveyRequest
    case reEngagement

    case autoReply
    case bounceNotification
    case forwardedMessage

    case unknown
    case other(String)
}

public enum EntityKind: Equatable, Hashable, Sendable, Codable {
    case verificationCode
    case magicLink
    case passwordResetLink

    case orderIdentifier
    case trackingNumber
    case discountCode
    case invoiceReference
    case amount

    case date
    case time
    case dateTimeRange
    case meetingLink
    case calendarReference

    case bookingReference
    case flightNumber
    case boardingGate
    case seatAssignment
    case travelSegment

    case accountReference
    case transactionReference
    case documentReference
    case signatureRequestLink

    case emailAddress
    case phoneNumber
    case physicalAddress
    case personName

    case unsubscribeLink
    case primaryCTALink
    case downloadLink
    case referralLink
    case trackingLink

    case supportTicketReference
    case subscriptionReference

    case attachmentReference

    case unknown
    case other(String)
}

public enum ActionKind: Equatable, Hashable, Sendable, Codable {
    case verify
    case openMagicLink
    case resetPassword

    case respondToInvite
    case addToCalendar
    case checkIn
    case bookFollowUp

    case trackShipment
    case confirmDelivery
    case initiateReturn
    case payInvoice
    case redeemOffer

    case signDocument
    case reviewDocument
    case downloadDocument

    case reviewSecurityAlert
    case updatePaymentMethod

    case reply
    case unsubscribe

    case unknown
    case other(String)
}

public enum AttachmentKind: Equatable, Hashable, Sendable, Codable {
    case document
    case calendarInvite
    case contact
    case inlineImage
    case dataFile
    case archive
    case unsafe

    case unknown
    case other(String)
}

public enum SafetyClassification: Equatable, Hashable, Sendable, Codable {
    case safe
    case suspicious
    case unsafe
}
