
import XCTest
@testable import ForageSDK

struct Event {
    let message: String
}

protocol SentryClient {
    func capture(event: Event)
}
class MockSentryClient: SentryClient {
    var capturedEvents: [Event] = []
    
    func capture(event: Event) {
        capturedEvents.append(event)
    }
}

class EventLogger {
    private let sentryClient: SentryClient
    
    init(sentryClient: SentryClient) {
        self.sentryClient = sentryClient
    }
    
    func logEvent(message: String) {
        let event = Event(message: message)
        sentryClient.capture(event: event)
    }
}

final class ForageSentryTest: XCTestCase {
    var forageMocks: ForageMocks!
    
    override func setUp() {
        ForageSDK.setup(ForageSDK.Config(environment: .sandbox))
        ForageSDK.shared.service = nil
        forageMocks = ForageMocks()
    }

    func testEventLoggerSendsToSentry() {
        let mockClient = MockSentryClient()
        let eventLogger = EventLogger(sentryClient: mockClient)
        
        eventLogger.logEvent(message: "Test message")
        
        XCTAssertEqual(mockClient.capturedEvents.count, 1, "Event should be captured")
        XCTAssertEqual(mockClient.capturedEvents.first?.message, "Test message")
    }
}
