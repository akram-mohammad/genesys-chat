import XCTest
import GMSLibrary
import Alamofire
@testable import Promises

class Tests: XCTestCase {
    let queue = DispatchQueue(label: "com.genesys.gms", qos: .background, attributes: .concurrent)
    var manager: SessionManager = SessionManager.default

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
        configuration.urlCredentialStorage = nil
        manager = Alamofire.SessionManager(configuration: configuration)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Callback tests
    func testStartCallbackBadServiceName() {
        let serviceSettings: GmsServiceSettings
        let serverSettings: GmsServerSettings
        do {
            serverSettings = try GmsServerSettings(hostname: "vce-w0110.us.int.genesyslab.com", port: 8010, secureProtocol: false)
            serviceSettings = try GmsServiceSettings("Nonexistent")
        } catch {
            XCTFail("Settings initializers should not have failed")
            return
        }
        let badClient = CallbackApiClient(serviceSettings, serverSettings)
        
        let promise = badClient.startCallback(on: queue, phoneNumber: "+19059681000")
        XCTAssert(waitForPromises(timeout: 60))
        XCTAssertNil(promise.value)
        XCTAssertNotNil(promise.error)
    }
    
    func testStartCancelCallback() {
        let serviceSettings: GmsServiceSettings
        let serverSettings: GmsServerSettings
        do {
            serverSettings = try GmsServerSettings(hostname: "vce-w0110.us.int.genesyslab.com", port: 8010, secureProtocol: false)
            serviceSettings = try GmsServiceSettings("gbank-callback-gms")
        } catch {
            XCTFail("Settings initializers should not have failed")
            return
        }
        let client = CallbackApiClient(serviceSettings, serverSettings)
        var createdCallbackId: String? = nil
        var createdCallback: CallbackRecord? = nil
        let phoneNumber = "+19059681000"
        let promise = client.startCallback(on: queue, phoneNumber: phoneNumber, properties: ["_target": "Customer_Service>0"])
            .then { callbackId throws -> Promise<CallbackRecord> in
                createdCallbackId = callbackId
                return client.queryCallbackById(on: self.queue, serviceId: callbackId)
            }.then { callbackRecord throws -> Promise<String> in
                client.cancelCallback(on: self.queue, serviceId: callbackRecord.callbackId)
            }.then { callbackId throws -> Promise<CallbackRecord> in
                client.queryCallbackById(on: self.queue, serviceId: callbackId)
            }.then { callbackRecord throws -> Promise<[CallbackRecord]> in
                createdCallback = callbackRecord
                return client.queryCallback(
                    on: self.queue,
                    properties: [
                        "_customer_number": phoneNumber
                ])
        }

        XCTAssert(waitForPromises(timeout: 60))
        XCTAssertNotNil(promise.value)
        XCTAssertNil(promise.error)
        XCTAssertNotNil(createdCallbackId)
        XCTAssertNotNil(createdCallback)
        if let callbackRecord = createdCallback {
            XCTAssertFalse(callbackRecord.callbackId.isEmpty)
            XCTAssertEqual(callbackRecord.callbackState, "COMPLETED")
            XCTAssertEqual(callbackRecord.callbackReason, "CANCELLED")
        }
        if let records = promise.value {
            XCTAssertGreaterThan(records.count, 0)
            if let callbackId = createdCallbackId {
                XCTAssertNotNil(records.first(where: {$0.callbackId == callbackId}))
            }
        }
    }

    func testCancelBadCallback() {
        let serviceSettings: GmsServiceSettings
        let serverSettings: GmsServerSettings
        do {
            serverSettings = try GmsServerSettings(hostname: "vce-w0110.us.int.genesyslab.com", port: 8010, secureProtocol: false)
            serviceSettings = try GmsServiceSettings("gbank-callback-gms")
        } catch {
            XCTFail("Settings initializers should not have failed")
            return
        }
        let client = CallbackApiClient(serviceSettings, serverSettings)
        let promise = client.queryCallbackById(on: self.queue, serviceId: "bad_id")
        XCTAssert(waitForPromises(timeout: 60))
        XCTAssertNotNil(promise.error)
        XCTAssertNil(promise.value)
    }

    func testAvailabilityV1() {
        let serviceSettings: GmsServiceSettings
        let serverSettings: GmsServerSettings
        do {
            serverSettings = try GmsServerSettings(hostname: "vce-w0110.us.int.genesyslab.com", port: 8010, secureProtocol: false)
            serviceSettings = try GmsServiceSettings("gbank-callback-gms")
        } catch {
            XCTFail("Settings initializers should not have failed")
            return
        }
        let client = CallbackApiClient(serviceSettings, serverSettings)
        let promise = client.queryAvailabilityV1(on: self.queue)
        XCTAssert(waitForPromises(timeout: 60))
        XCTAssertNotNil(promise.value)
        XCTAssertNil(promise.error)
        if let slots = promise.value {
            XCTAssertGreaterThan(slots.count, 0)
            print("Slots: \(slots)")
        }
    }
    
    func testAvailablityV2() {
        let serviceSettings: GmsServiceSettings
        let serverSettings: GmsServerSettings
        do {
            serverSettings = try GmsServerSettings(hostname: "vce-w0110.us.int.genesyslab.com", port: 8010, secureProtocol: false)
            serviceSettings = try GmsServiceSettings("gbank-callback-gms")
        } catch {
            XCTFail("Settings initializers should not have failed")
            return
        }
        let client = CallbackApiClient(serviceSettings, serverSettings)
        let promise = client.queryAvailabilityV2(on: self.queue)
        XCTAssert(waitForPromises(timeout: 60))
        XCTAssertNotNil(promise.value)
        XCTAssertNil(promise.error)
        if let availability = promise.value {
            XCTAssertGreaterThan(availability.slots.count, 0)
            print("Slots: \(availability)")
        }
    }

    // MARK: - Chat V2 API tests

    func testChatV2FileUploadDownload() {
        let serviceSettings: GmsServiceSettings
        let serverSettings: GmsServerSettings
        do {
            serverSettings = try GmsServerSettings(hostname: "vce-w0110.us.int.genesyslab.com", port: 8010, secureProtocol: false)
            serviceSettings = try GmsServiceSettings("customer-support")
        } catch {
            XCTFail("Settings initializers should not have failed")
            return
        }
        var userSettings = GmsUserSettings()
        userSettings.firstName = "Arya"
        userSettings.lastName = "Stark"
        userSettings.nickname = "No One"
        userSettings.email = "arya.stark@faceless.com"
        let subject = "Clearing my List"
        let chatClient = ChatV2PromiseApiClient(serviceSettings: serviceSettings, serverSettings: serverSettings, userSettings: userSettings)
        var chatResponse: ChatV2Response?
        let promise = chatClient.requestChat(on: self.queue, subject: subject).then {
            response throws -> Promise<ChatV2FileLimits> in
            if let chatEnded = response.chatEnded {
                XCTAssertFalse(chatEnded)
            }
            chatResponse = response
            XCTAssertNotNil(response.chatId)
            return chatClient.getFileLimits(on: self.queue, chatId: response.chatId, userId: response.userId,
                                               alias: response.alias, secureKey: response.secureKey!)
        }
        
        XCTAssert(waitForPromises(timeout: 30))
        XCTAssertNotNil(promise.value)
        XCTAssertNil(promise.error)
        guard let fileLimits = promise.value else {
            return
        }
        print("[testChatV2FileUploadDownload] file limits = \(fileLimits)")
        let fileContent = "This is plain text.\n"
        var uploadedFileId: String? = nil
        if let response = chatResponse {
            var promise2: Promise<String>
            if fileLimits.uploadMaxFiles > 0 && !fileLimits.uploadNeedAgent {
                // TODO test file upload
                promise2 = chatClient.uploadFile(
                    on: self.queue,
                    chatId: response.chatId,
                    userId: response.userId,
                    alias: response.alias,
                    secureKey: response.secureKey!,
                    fileName: "todo.txt",
                    mimeType: "text/plain",
                    fileData: fileContent.data(using: .utf8)!,
                    fileDescription: "A plain text file"
                ).then { fileId throws -> Promise<URL> in
                    print("[testChatV2FileUploadDownload] File ID = \(fileId)")
                    uploadedFileId = fileId
                    return chatClient.downloadFile(on: self.queue,
                                                        chatId: response.chatId,
                                                        userId: response.userId,
                                                        alias: response.alias,
                                                        secureKey: response.secureKey!,
                                                        fileId: fileId)
                }.then { url throws -> Promise<ChatV2Response> in
                    print("[testChatV2FileUploadDownload] File url = \(url)")
                    do {
                        let data = try Data(contentsOf: url)
                        print("[testChatV2FileUploadDownload] File content = \(data)")
                        if let str = String(data: data, encoding: .utf8) {
                            XCTAssertEqual(str, fileContent)
                        } else {
                            XCTFail("[testChatV2FileUploadDownload] File content cannot be converted into string")
                        }
                    } catch {
                        XCTFail("[testChatV2FileUploadDownload] File content failed \(error)")
                    }
                    return chatClient.deleteFile(on: self.queue,
                                                      chatId: response.chatId,
                                                      userId: response.userId,
                                                      alias: response.alias,
                                                      secureKey: response.secureKey!,
                                                      fileId: uploadedFileId!)
                }.then { response throws -> Promise<ChatV2Response> in
                    if let chatEnded = response.chatEnded {
                        XCTAssertFalse(chatEnded)
                    }
                    return chatClient.refreshChat(on: self.queue,
                                                       chatId: response.chatId,
                                                       userId: response.userId,
                                                       alias: response.alias,
                                                       secureKey: response.secureKey!,
                                                       transcriptPosition: 1)
                }.then { refreshResponse throws -> Promise<String> in
                    if let chatEnded = refreshResponse.chatEnded {
                        XCTAssertFalse(chatEnded)
                    }
                    
                    XCTAssertNotNil(refreshResponse.messages.first(where: {
                        $0.from.nickname == userSettings.nickname! &&
                        $0.type == .fileDeleted }))
                    let encoder = JSONEncoder()
                    let json = String(data: try encoder.encode(refreshResponse.messages), encoding: .utf8)!
                    print("[testChatV2FileUploadDownload] JSON = \(json)")
                    return Promise<String>(json)
                }
            } else {
                promise2 = Promise<String>("File upload skipped")
            }
            promise2
                .then { _ throws -> Promise<ChatV2Response> in
                return chatClient.disconnect(on: self.queue, chatId: response.chatId,
                                                userId: response.userId, alias: response.alias,
                                                secureKey: response.secureKey!)
            }
                .catch { error in
                XCTFail("[testChatV2FileUploadDownload] Error thrown: \(error)")
            }
            XCTAssert(waitForPromises(timeout: 120))
            XCTAssertNotNil(promise2.value)
            XCTAssertNil(promise2.error)
        }
    }
    
    func testChatV2() {
        let serviceSettings: GmsServiceSettings
        let serverSettings: GmsServerSettings
        do {
            serverSettings = try GmsServerSettings(hostname: "vce-w0110.us.int.genesyslab.com", port: 8010, secureProtocol: false)
            serviceSettings = try GmsServiceSettings("customer-support")
        } catch {
            XCTFail("Settings initializers should not have failed")
            return
        }
        var userSettings = GmsUserSettings()
        userSettings.firstName = "Arya"
        userSettings.lastName = "Stark"
        userSettings.nickname = "No One"
        userSettings.email = "arya.stark@faceless.com"
        let subject = "Clearing my List"
        var chatClient = ChatV2PromiseApiClient(serviceSettings: serviceSettings, serverSettings: serverSettings, userSettings: userSettings)

        let url = "http://www.google.com/"
        let customNotice = "My Custom Notice"
        let stoppedTypingMessage = "I have stopped typing"
        let message1 = "Hello World"
        let messageType1 = "text message"
        let message2 = "Winter is coming"
        
        let promise = chatClient.requestChat(on: self.queue, subject: subject).then {
            response throws -> Promise<ChatV2Response> in
            if let chatEnded = response.chatEnded {
                XCTAssertFalse(chatEnded)
            }
            XCTAssertNotNil(response.chatId)
            return chatClient.sendMessage(on: self.queue, chatId: response.chatId, userId: response.userId,
                                   alias: response.alias, secureKey: response.secureKey!,
                                   message: message1, messageType: messageType1, transcriptPosition: 1)
        }
        
        XCTAssert(waitForPromises(timeout: 30))
        XCTAssertNotNil(promise.value)
        XCTAssertNil(promise.error)
        guard let response = promise.value else {
            return
        }

        if let chatEnded = response.chatEnded {
            XCTAssertFalse(chatEnded)
        }
        XCTAssertGreaterThan(response.messages.count, 0)
        let oldNickname = chatClient.userSettings.nickname
        let fromMe = response.messages.filter({$0.from.nickname == oldNickname})
        XCTAssertNotNil(fromMe.first(where: { $0.type == ChatV2MessageType.participantJoined }))
        XCTAssertNotNil(fromMe.first(where: { $0.type == ChatV2MessageType.message && $0.text == message1 && $0.messageType == messageType1 }))

        chatClient.userSettings.nickname = "new name"
        let promise2 = chatClient.updateDisplayName(
            on: self.queue,
            chatId: response.chatId,
            userId: response.userId,
            alias: response.alias,
            secureKey: response.secureKey!).then {
                response throws -> Promise<ChatV2Response> in
                if let chatEnded = response.chatEnded {
                    XCTAssertFalse(chatEnded)
                }
                XCTAssertNotNil(response.chatId)
                return chatClient.pushUrl(on: self.queue, chatId: response.chatId, userId: response.userId,
                                                   alias: response.alias, secureKey: response.secureKey!,
                                                   url: try url.asURL())
            }.then {
                response throws -> Promise<ChatV2Response> in
                if let chatEnded = response.chatEnded {
                    XCTAssertFalse(chatEnded)
                }
                XCTAssertNotNil(response.chatId)
                return chatClient.sendCustomNotice(on: self.queue, chatId: response.chatId, userId: response.userId,
                                               alias: response.alias, secureKey: response.secureKey!,
                                               notice: customNotice)
            }.then {
                response throws -> Promise<ChatV2Response> in
                if let chatEnded = response.chatEnded {
                    XCTAssertFalse(chatEnded)
                }
                XCTAssertNotNil(response.chatId)
                return chatClient.startTyping(on: self.queue, chatId: response.chatId, userId: response.userId,
                                                   alias: response.alias, secureKey: response.secureKey!)
            }.then {
                response throws -> Promise<ChatV2Response> in
                if let chatEnded = response.chatEnded {
                    XCTAssertFalse(chatEnded)
                }
                XCTAssertNotNil(response.chatId)
                return chatClient.stopTyping(on: self.queue, chatId: response.chatId, userId: response.userId,
                                                  alias: response.alias, secureKey: response.secureKey!, message: stoppedTypingMessage)
            }.then {
                response throws -> Promise<ChatV2Response> in
                if let chatEnded = response.chatEnded {
                    XCTAssertFalse(chatEnded)
                }
                XCTAssertNotNil(response.chatId)
                return chatClient.sendMessage(on: self.queue, chatId: response.chatId, userId: response.userId,
                                                   alias: response.alias, secureKey: response.secureKey!, message: message2)
            }.then {
                response throws -> Promise<ChatV2Response> in
                if let chatEnded = response.chatEnded {
                    XCTAssertFalse(chatEnded)
                }
                XCTAssertNotNil(response.chatId)
                return chatClient.refreshChat(on: self.queue, chatId: response.chatId, userId: response.userId,
                                                   alias: response.alias, secureKey: response.secureKey!,
                                                   transcriptPosition: 1)

        }
        
        XCTAssert(waitForPromises(timeout: 30))
        XCTAssertNotNil(promise2.value)
        XCTAssertNil(promise2.error)
        guard let response2 = promise2.value else {
            return
        }
        if let chatEnded = response2.chatEnded {
            XCTAssertFalse(chatEnded)
        }
        let fromMe2 = response2.messages.filter({$0.from.nickname == chatClient.userSettings.nickname})
        XCTAssertNotNil(fromMe2.first(where: { $0.type == ChatV2MessageType.customNotice && $0.text == customNotice }))
        XCTAssertNotNil(fromMe2.first(where: { $0.type == ChatV2MessageType.nicknameUpdated }))
        XCTAssertNotNil(fromMe2.first(where: { $0.type == ChatV2MessageType.pushUrl && $0.text == url }))
        XCTAssertNotNil(fromMe2.first(where: { $0.type == ChatV2MessageType.message && $0.text == message2 }))

        let promise3 = chatClient.disconnect(on: self.queue, chatId: response.chatId, userId: response.userId,
                                             alias: response.alias, secureKey: response.secureKey!)
        XCTAssert(waitForPromises(timeout: 30))
        XCTAssertNotNil(promise3.value)
        XCTAssertNil(promise3.error)
        guard let response3 = promise3.value else {
            return
        }
        if let chatEnded = response3.chatEnded {
            XCTAssertTrue(chatEnded)
        }
    }
    
    class CometDelegate : ChatV2Delegate {
        let queue = DispatchQueue(label: "com.genesys.gms.cometdelegate", qos: .background, attributes: .concurrent)
        var sessionActive = false
        var messages = [ChatV2Message]()
        var client: ChatV2CometClient? = nil
        var requestChatPromise: Promise<Bool>?
        var disconnectPromise: Promise<Bool>?
        var fileLimitsPromise: Promise<ChatV2FileLimits>?
        var uploadPromises = [String:Promise<String>]()
        var downloadPromises = [String:Promise<URL>]()
        var deletePromises = [String:Promise<Bool>]()
        
        func requestChat(subject: String, userData: [String: String]) -> Promise<Bool> {
            requestChatPromise = Promise<Bool>.pending()
            client!.requestChat(on: nil, subject: subject, userData: userData)
            return requestChatPromise!
        }

        func disconnect() -> Promise<Bool> {
            disconnectPromise = Promise<Bool>.pending()
            do {
                try client!.disconnect(on: nil)
            } catch {
                disconnectPromise!.reject(error)
            }
            return disconnectPromise!
        }

        func getFileLimits(on queue: DispatchQueue) -> Promise<ChatV2FileLimits> {
            fileLimitsPromise = Promise<ChatV2FileLimits>.pending()
            do {
                try client!.getFileLimits(on: queue)
            } catch {
                fileLimitsPromise!.reject(error)
            }
            return fileLimitsPromise!
        }
        
        func uploadFile(on queue: DispatchQueue, fileURL: URL, fileDescription: String?, userData: [String:String] = [String:String]()) -> Promise<String> {
            let promise = Promise<String>.pending()
            do {
                let requestId = try client!.uploadFile(on: queue, fileURL: fileURL, fileDescription: fileDescription, userData: userData)
                self.queue.sync { uploadPromises[requestId] = promise }
            } catch {
                promise.reject(error)
            }
            return promise
        }

        func uploadFile(on queue: DispatchQueue, fileName: String, mimeType: String, fileData: Data, fileDescription: String?, userData: [String:String] = [String:String]()) -> Promise<String> {
            let promise = Promise<String>.pending()
            do {
                let requestId = try client!.uploadFile(on: queue, fileName: fileName, mimeType: mimeType, fileData: fileData, fileDescription: fileDescription, userData: userData)
                self.queue.sync { uploadPromises[requestId] = promise }
            } catch {
                promise.reject(error)
            }
            return promise
        }

        func downloadFile(on queue: DispatchQueue, fileId: String) -> Promise<URL> {
            let promise = Promise<URL>.pending()
            do {
                let requestId = try client!.downloadFile(on: queue, fileId: fileId)
                self.queue.sync { downloadPromises[requestId] = promise }
            } catch {
                promise.reject(error)
            }
            return promise
        }
        
        func deleteFile(on queue: DispatchQueue, fileId: String) -> Promise<Bool> {
            let promise = Promise<Bool>.pending()
            self.queue.sync { deletePromises[fileId] = promise }
            do {
                try client!.deleteFile(on: queue, fileId: fileId)
            } catch {
                self.queue.sync { promise.reject(error) }
            }
            return promise
        }
        
        func chatSessionActive(_ service: String, chatId: String?, userId: String?, alias: String?, secureKey: String?) {
            queue.sync {
                sessionActive = true
                if let promise = requestChatPromise, promise.isPending {
                    promise.fulfill(sessionActive)
                    requestChatPromise = nil
                }
            }
        }
        
        func chatSessionResumed(_ service: String, chatId: String?, secureKey: String?) {
            queue.sync {
                sessionActive = true
                if let promise = requestChatPromise, promise.isPending {
                    promise.fulfill(sessionActive)
                    requestChatPromise = nil
                }
            }
        }

        func chatSessionEnded(_ service: String, chatId: String?, secureKey: String?) {
            queue.sync {
                sessionActive = false
                if let promise = requestChatPromise, promise.isPending {
                    promise.fulfill(sessionActive)
                    requestChatPromise = nil
                }
                
                if let promise = disconnectPromise, promise.isPending {
                    promise.fulfill(true)
                    disconnectPromise = nil
                }
            }
        }
        
        func messageReceived(_ service: String, chatId: String?, secureKey: String?, message: ChatV2Message) {
            queue.sync {
                messages.append(message)
            }
        }
        
        func parsingError(_ service: String, message: [String: Any]) {
            queue.sync {
                if let promise = requestChatPromise, promise.isPending {
                    promise.reject(GmsApiError.invalidParameter(key: service, value: String(describing: message)))
                    requestChatPromise = nil
                }
            }
        }
        
        func errorReceived(_ service: String, chatId: String?, error: Error) {
            queue.sync {
                if let promise = requestChatPromise, promise.isPending {
                    promise.reject(error)
                    requestChatPromise = nil
                }
            }
        }
        
        func connectionError(_ client: ChatV2CometClient, error: Error?) {
            queue.sync {
                if let promise = requestChatPromise, promise.isPending {
                    if let error = error {
                        promise.reject(error)
                    } else {
                        promise.reject(GmsApiError.cometConnectFailed)
                    }
                    requestChatPromise = nil
                }
            }
        }
        
        func fileLimitsReceived(_ service: String, chatId: String?, secureKey: String?, fileLimits: ChatV2FileLimits) {
            if let promise = fileLimitsPromise {
                promise.fulfill(fileLimits)
            }
        }
        
        func fileLimitsFailed(_ service: String, chatId: String?, secureKey: String?, error: Error?) {
            if let promise = fileLimitsPromise {
                promise.reject(GmsApiError.cometFileError(error: error))
            }
        }
        
        func fileUploaded(_ service: String, chatId: String?, secureKey: String?, requestId: String, fileId: String) {
            if let promise = uploadPromises[requestId] {
                promise.fulfill(fileId)
            }
        }
        
        func fileUploadFailed(_ service: String, chatId: String?, secureKey: String?, requestId: String, error: Error?) {
            if let promise = uploadPromises[requestId] {
                promise.reject(GmsApiError.cometFileError(error: error))
            }
        }
        
        func fileDownloaded(_ service: String, chatId: String?, secureKey: String?, requestId: String, fileId: String, fileURL: URL) {
            if let promise = downloadPromises[requestId] {
                promise.fulfill(fileURL)
            }
        }
        
        func fileDownloadFailed(_ service: String, chatId: String?, secureKey: String?, requestId: String, fileId: String, error: Error?) {
            if let promise = downloadPromises[requestId] {
                promise.reject(GmsApiError.cometFileError(error: error))
            }
        }
        
        func fileDeleted(_ service: String, chatId: String?, secureKey: String?, fileId: String) {
            if let promise = deletePromises[fileId] {
                promise.fulfill(true)
            }
        }
        
        func fileDeleteFailed(_ service: String, chatId: String?, secureKey: String?, fileId: String, error: Error?) {
            if let promise = deletePromises[fileId] {
                promise.reject(GmsApiError.cometFileError(error: error))
            }
        }

        var first: ChatV2Message? {
            return queue.sync { () -> ChatV2Message? in
                if !messages.isEmpty {
                    return messages.removeFirst()
                } else {
                    return nil
                }
            }
        }
    }
    
    /// Chat V2 Comet API
    func testChatV2Comet() {
        let serviceSettings: GmsServiceSettings
        let serverSettings: GmsServerSettings
        do {
            serverSettings = try GmsServerSettings(hostname: "vce-w0110.us.int.genesyslab.com", port: 8010, secureProtocol: false)
            serviceSettings = try GmsServiceSettings("customer-support")
        } catch {
            XCTFail("Settings initializers should not have failed")
            return
        }
        var userSettings = GmsUserSettings()
        userSettings.firstName = "Arya"
        userSettings.lastName = "Stark"
        let originalNickname = "No One"
        let newNickname = "A girl"
        userSettings.nickname = "No One"
        userSettings.email = "arya.stark@faceless.com"
        let subject = "Clearing my List"

        let url = "http://www.google.com/"
        let customNotice = "My Custom Notice"
        let stoppedTypingMessage = "I have stopped typing"
        let message1 = "Hello World"
        let messageType1 = "text message"
        let message2 = "Winter is coming"
        
        let delegate = CometDelegate()
        let client = ChatV2CometClient(serviceSettings: serviceSettings, serverSettings: serverSettings, userSettings: userSettings, delegate: delegate)
        delegate.client = client
        
        let promise = delegate.requestChat(subject: subject, userData: [String: String]())
        XCTAssert(waitForPromises(timeout: 30))
        XCTAssertNotNil(promise.value)
        XCTAssert(promise.value ?? false, "[testChatV2Comet] Expect to connect successfully")
        XCTAssertNil(promise.error)
        
        // chat cannot start
        if promise.error == nil {
            return
        }
        
        // send messages
        do {
            try client.sendMessage(on: nil, message: message1, messageType: messageType1)
            try client.customNotice(on: nil, message: customNotice)
            try client.startTyping(on: nil)
            try client.stopTyping(on: nil, message: stoppedTypingMessage)
            try client.sendMessage(on: nil, message: message2)
            try client.pushUrl(on: nil, url: url.asURL())
            try client.updateNickname(on: nil, nickname: newNickname)
        } catch {
            XCTFail(String(describing: error))
            return
        }
        
        let promise2 = delegate.disconnect()
        XCTAssert(waitForPromises(timeout: 30))
        XCTAssertNotNil(promise2.value)
        XCTAssert(promise2.value ?? false, "[testChatV2Comet] Expect to disconnect successfully")
        XCTAssertNil(promise2.error)
        
        var messages = [ChatV2MessageType:[ChatV2Message]]()
        while let message = delegate.first,
            (message.from.nickname == originalNickname ||
                message.from.nickname == newNickname) {
            if messages[message.type] == nil {
                messages[message.type] = [message]
            } else {
                messages[message.type]!.append(message)
            }
        }
        
        // we expect at least one each of these messages from ourselves
        let expectedTypes: [ChatV2MessageType] = [.participantJoined,
                                                  .typingStarted,
                                                  .pushUrl,
                                                  .customNotice,
                                                  .message,
                                                  .nicknameUpdated,
                                                  .typingStopped]
        for t in expectedTypes {
            XCTAssertNotNil(messages[t])
            if let msgs = messages[t] {
                XCTAssertFalse(msgs.isEmpty, "[testChatV2Comet] Expect at least one message of type \(t)")
            }
        }
        
        if let msgs = messages[.message] {
            XCTAssertEqual(msgs.count, 2, "[testChatV2Comet] Expect at least 2 \"message\" type messages")
            XCTAssert(msgs.contains{ $0.text == message1 && $0.messageType == messageType1 })
            XCTAssert(msgs.contains{ $0.text == message2 })
        }
    }

    /// Chat V2 Comet API
    func testChatV2CometFileUploadDownload() {
        let serviceSettings: GmsServiceSettings
        let serverSettings: GmsServerSettings
        do {
            serverSettings = try GmsServerSettings(hostname: "vce-w0110.us.int.genesyslab.com", port: 8010, secureProtocol: false)
            serviceSettings = try GmsServiceSettings("customer-support")
        } catch {
            XCTFail("Settings initializers should not have failed")
            return
        }
        var userSettings = GmsUserSettings()
        userSettings.firstName = "Arya"
        userSettings.lastName = "Stark"
        let originalNickname = "No One"
        let newNickname = "A girl"
        userSettings.nickname = "No One"
        userSettings.email = "arya.stark@faceless.com"
        let subject = "Clearing my List"
        
        let delegate = CometDelegate()
        let client = ChatV2CometClient(serviceSettings: serviceSettings, serverSettings: serverSettings, userSettings: userSettings, delegate: delegate)
        delegate.client = client
        
        let promise = delegate.requestChat(subject: subject, userData: [String: String]())
        
        XCTAssert(waitForPromises(timeout: 30))
        XCTAssertNotNil(promise.value)
        XCTAssert(promise.value ?? false)
        XCTAssertNil(promise.error)
        
        // chat cannot start
        if promise.error == nil {
            return
        }
        let promise2 = delegate.getFileLimits(on: self.queue)
        XCTAssert(waitForPromises(timeout: 30))
        XCTAssertNotNil(promise2.value)
        XCTAssertNil(promise2.error)
        guard let fileLimits = promise2.value else {
            return
        }

        print("[testChatV2CometFileUploadDownload] file limits = \(fileLimits)")
        let fileContent = "This is plain text.\n"
        var uploadedFileId: String? = nil
        
        if fileLimits.uploadMaxFiles > 0 && !fileLimits.uploadNeedAgent {
            // TODO test file upload
            let promise3 = delegate.uploadFile(
                on: self.queue,
                fileName: "todo.txt",
                mimeType: "text/plain",
                fileData: fileContent.data(using: .utf8)!,
                fileDescription: "A plain text file"
                ).then { fileId throws -> Promise<URL> in
                    print("[testChatV2CometFileUploadDownload] File ID = \(fileId)")
                    uploadedFileId = fileId
                    return delegate.downloadFile(on: self.queue,
                                                   fileId: fileId)
                }.then { url throws -> Promise<Bool> in
                    print("[testChatV2CometFileUploadDownload] File url = \(url)")
                    do {
                        let data = try Data(contentsOf: url)
                        print("[testChatV2CometFileUploadDownload] File content = \(data)")
                        if let str = String(data: data, encoding: .utf8) {
                            XCTAssertEqual(str, fileContent)
                        } else {
                            XCTFail("[testChatV2CometFileUploadDownload] File content cannot be converted into string")
                        }
                    } catch {
                        XCTFail("[testChatV2CometFileUploadDownload] File content failed \(error)")
                    }
                    return delegate.deleteFile(on: self.queue,
                                                 fileId: uploadedFileId!)
                }.then { response -> Promise<Bool> in
                    delegate.disconnect()
                }
            XCTAssert(waitForPromises(timeout: 120))
            XCTAssertNotNil(promise3.value)
            XCTAssertNil(promise3.error)
            XCTAssertTrue(promise3.value!)
        } else {
            print("[testChatV2CometFileUploadDownload] File upload and download skipped")
        }
        
        var messages = [ChatV2MessageType:[ChatV2Message]]()
        while let message = delegate.first,
            (message.from.nickname == originalNickname ||
                message.from.nickname == newNickname) {
                    if messages[message.type] == nil {
                        messages[message.type] = [message]
                    } else {
                        messages[message.type]!.append(message)
                    }
        }
        
        // we expect at least one each of these messages from ourselves
        let expectedTypes: [ChatV2MessageType] = [.fileUploaded,
                                                  .fileDeleted]
        for t in expectedTypes {
            XCTAssertNotNil(messages[t])
            if let msgs = messages[t] {
                XCTAssertFalse(msgs.isEmpty, "[testChatV2Comet] Expect at least one message of type \(t)")
            }
        }
    }
}
