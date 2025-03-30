import Foundation
import Combine
import AppKit
import Vision

class ActivityMonitor: ObservableObject {
    // MARK: - Published Properties
    
    @Published var keyLoggingEnabled = false {
        didSet {
            if keyLoggingEnabled {
                startKeyLogging()
            } else {
                stopKeyLogging()
            }
        }
    }
    
    @Published var screenAnalysisEnabled = false {
        didSet {
            if screenAnalysisEnabled {
                startScreenAnalysis()
            } else {
                stopScreenAnalysis()
            }
        }
    }
    
    @Published var appTrackingEnabled = false {
        didSet {
            if appTrackingEnabled {
                startAppTracking()
            } else {
                stopAppTracking()
            }
        }
    }
    
    @Published var currentActivity: Activity?
    @Published var recentActivities: [Activity] = []
    
    // MARK: - Activity Publisher
    
    let activityPublisher = PassthroughSubject<Activity, Never>()
    
    // MARK: - Private Properties
    
    // Monitors and timers
    private var keyMonitor: Any?
    private var keyGlobalMonitor: Any?
    private var screenCaptureTimer: Timer?
    private var appTrackingTimer: Timer?
    
    // Keystroke buffering properties
    private var keystrokeBuffer = ""
    private var lastKeystrokeTime: Date?
    private var keystrokeBufferTimer: Timer?
    private var currentKeyboardApp: NSRunningApplication?
    private let keystrokeBufferDelay: TimeInterval = 2.0 // seconds to wait after last keystroke
    private let maxBufferSize = 100 // max characters before forcing a publish
    
    // Processing queues
    private let activityQueue = DispatchQueue(label: "com.malgus.activityQueue", qos: .userInitiated)
    
    // Configuration
    private let privacyFilter = PrivacyFilter()
    private var cancellables = Set<AnyCancellable>()
    
    // Constants
    private let screenCaptureInterval: TimeInterval = 5.0 // seconds
    private let appTrackingInterval: TimeInterval = 1.0 // seconds
    private let activityBufferSize = 100
    
    // MARK: - Initialization
    
    init() {
        print("ActivityMonitor initialized")
        
        // Set up activity publisher subscription
        setupSubscriptions()
        
        // Register for permission change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(permissionStatusChanged),
            name: PermissionsManager.permissionStatusChanged,
            object: nil
        )
    }
    
    private func setupSubscriptions() {
        activityPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activity in
                guard let self = self else { return }
                
                print("Activity received: \(activity.type) from \(activity.application)")
                
                self.currentActivity = activity
                self.recentActivities.insert(activity, at: 0)
                
                // Trim the buffer to the maximum size
                if self.recentActivities.count > self.activityBufferSize {
                    self.recentActivities.removeLast()
                }
                
                // Notify the context engine about the new activity
                NotificationCenter.default.post(
                    name: .newActivityRecorded,
                    object: nil,
                    userInfo: ["activity": activity]
                )
            }
            .store(in: &cancellables)
    }
    
    @objc private func permissionStatusChanged(_ notification: Notification) {
        print("Permission status changed notification received")
        
        // If permissions have been granted, retry enabling features
        if let permissionType = notification.userInfo?["permissionType"] as? PermissionType {
            switch permissionType {
            case .inputMonitoring, .accessibility:
                if keyLoggingEnabled && keyMonitor == nil && keyGlobalMonitor == nil {
                    startKeyLogging()
                }
                
            case .screenRecording:
                if screenAnalysisEnabled && screenCaptureTimer == nil {
                    startScreenAnalysis()
                }
                
            default:
                break
            }
        }
    }
    
    // MARK: - Keystroke Monitoring with Buffering
    
    private func startKeyLogging() {
        guard keyMonitor == nil && keyGlobalMonitor == nil else {
            print("Keystroke monitoring already active")
            return
        }
        
        print("Starting keystroke monitoring with buffering...")
        
        // Check for permissions first
        if !PermissionsManager.shared.checkPermission(.inputMonitoring) {
            print("Input monitoring permission not granted. Requesting...")
            PermissionsManager.shared.requestPermission(.inputMonitoring)
            return
        }
        
        // Clear any existing buffer state
        clearKeystrokeBuffer()
        
        // Permission is granted, set up the monitors
        
        // Local monitor catches keystrokes in your app
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event // Return the event so it continues to be processed by the app
        }
        
        // Global monitor catches keystrokes in other apps
        keyGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        print("Keystroke monitoring active (both local and global)")
    }
    
    private func stopKeyLogging() {
        print("Stopping keystroke monitoring...")
        
        // Publish any remaining keystrokes in the buffer
        if !keystrokeBuffer.isEmpty {
            publishKeystrokeBuffer()
        }
        
        // Clear keystroke buffer and timer
        clearKeystrokeBuffer()
        
        // Remove the local monitor
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        
        // Remove the global monitor
        if let monitor = keyGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            keyGlobalMonitor = nil
        }
        
        print("Keystroke monitoring stopped")
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        // Get the active application
        guard let activeApp = NSWorkspace.shared.frontmostApplication else {
            print("No active application detected")
            return
        }
        
        // Skip if the application is in the privacy filter
        if privacyFilter.isAppExcluded(activeApp.bundleIdentifier ?? "") {
            print("App excluded by privacy filter: \(activeApp.bundleIdentifier ?? "unknown")")
            return
        }
        
        // Get the characters from the event
        let characters = event.characters ?? ""
        
        // Skip if no characters
        guard !characters.isEmpty else {
            return
        }
        
        // If app changed, publish what we have and reset
        if currentKeyboardApp?.bundleIdentifier != activeApp.bundleIdentifier {
            if !keystrokeBuffer.isEmpty {
                publishKeystrokeBuffer()
            }
            currentKeyboardApp = activeApp
        }
        
        // Special handling for Enter key - publish immediately
        if event.keyCode == 36 { // Return key
            // Add new line to buffer
            keystrokeBuffer += "\n"
            
            // Publish and reset
            publishKeystrokeBuffer()
            return
        }
        
        // Special handling for backspace/delete
        if event.keyCode == 51 { // Delete/Backspace key
            if !keystrokeBuffer.isEmpty {
                keystrokeBuffer.removeLast()
            }
        } else {
            // Add character to buffer
            keystrokeBuffer += characters
        }
        
        // Update last keystroke time
        lastKeystrokeTime = Date()
        
        // Reset timer
        keystrokeBufferTimer?.invalidate()
        
        // If buffer is getting large, publish immediately
        if keystrokeBuffer.count >= maxBufferSize {
            publishKeystrokeBuffer()
            return
        }
        
        // Set timer to publish after delay
        keystrokeBufferTimer = Timer.scheduledTimer(
            withTimeInterval: keystrokeBufferDelay,
            repeats: false
        ) { [weak self] _ in
            self?.publishKeystrokeBuffer()
        }
    }
    
    private func publishKeystrokeBuffer() {
        // Skip if buffer is empty
        guard !keystrokeBuffer.isEmpty, let activeApp = currentKeyboardApp ?? NSWorkspace.shared.frontmostApplication else {
            return
        }
        
        // Skip very short buffers (like single characters) unless they include newlines
        if keystrokeBuffer.count < 3 && !keystrokeBuffer.contains("\n") {
            print("Skipping very short buffer: \(keystrokeBuffer)")
            keystrokeBuffer = ""
            return
        }
        
        print("Publishing keystroke buffer: \(keystrokeBuffer)")
        
        // Create an activity from the buffer
        let activity = Activity(
            type: .keystroke,
            timestamp: lastKeystrokeTime ?? Date(),
            application: activeApp.localizedName ?? "Unknown",
            bundleIdentifier: activeApp.bundleIdentifier,
            content: privacyFilter.filterSensitiveContent(keystrokeBuffer)
        )
        
        // Reset buffer and timestamp (keep the app)
        keystrokeBuffer = ""
        lastKeystrokeTime = nil
        
        // Publish the activity
        activityQueue.async { [weak self] in
            self?.activityPublisher.send(activity)
        }
    }
    
    private func clearKeystrokeBuffer() {
        keystrokeBufferTimer?.invalidate()
        keystrokeBufferTimer = nil
        keystrokeBuffer = ""
        currentKeyboardApp = nil
        lastKeystrokeTime = nil
    }
    
    // MARK: - Screen Content Analysis
    
    private func startScreenAnalysis() {
        guard screenCaptureTimer == nil else {
            print("Screen analysis already active")
            return
        }
        
        print("Starting screen analysis...")
        
        // Check for permissions first
        if !PermissionsManager.shared.checkPermission(.screenRecording) {
            print("Screen recording permission not granted. Requesting...")
            PermissionsManager.shared.requestPermission(.screenRecording)
            return
        }
        
        // Initialize and start the timer for periodic screen capture
        screenCaptureTimer = Timer.scheduledTimer(
            withTimeInterval: screenCaptureInterval,
            repeats: true
        ) { [weak self] _ in
            self?.captureAndAnalyzeScreen()
        }
        
        // Immediately perform the first capture
        captureAndAnalyzeScreen()
        
        print("Screen analysis active")
    }
    
    private func stopScreenAnalysis() {
        screenCaptureTimer?.invalidate()
        screenCaptureTimer = nil
        print("Screen analysis stopped")
    }
    
    private func captureAndAnalyzeScreen() {
        // Get the active application
        guard let activeApp = NSWorkspace.shared.frontmostApplication else {
            print("No active application detected for screen capture")
            return
        }
        
        // Skip if the application is in the privacy filter
        if privacyFilter.isAppExcluded(activeApp.bundleIdentifier ?? "") {
            print("App excluded by privacy filter (screen): \(activeApp.bundleIdentifier ?? "unknown")")
            return
        }
        
        guard let screen = NSScreen.main,
              let cgImage = CGWindowListCreateImage(
                CGRect.null,
                .optionOnScreenOnly,
                kCGNullWindowID,
                .bestResolution
              ) else {
            print("Failed to capture screen")
            return
        }
        
        print("Screen captured successfully, performing OCR...")
        
        let nsImage = NSImage(cgImage: cgImage, size: screen.frame.size)
        
        // Perform OCR on the screen image to extract text
        performOCR(on: nsImage) { [weak self] text in
            guard let self = self, let text = text else {
                print("OCR failed or returned no text")
                return
            }
            
            // Filter sensitive content
            let filteredText = self.privacyFilter.filterSensitiveContent(text)
            
            // Create a screen content activity
            let activity = Activity(
                type: .screenContent,
                timestamp: Date(),
                application: activeApp.localizedName ?? "Unknown",
                bundleIdentifier: activeApp.bundleIdentifier,
                content: filteredText
            )
            
            print("Publishing screen content activity from \(activeApp.localizedName ?? "Unknown")")
            
            // Publish the activity
            self.activityQueue.async {
                self.activityPublisher.send(activity)
            }
        }
    }
    
    private func performOCR(on image: NSImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                print("OCR error: \(error?.localizedDescription ?? "unknown error")")
                completion(nil)
                return
            }
            
            let text = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            completion(text)
        }
        
        // Configure the text recognition request
        request.recognitionLevel = .accurate
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing OCR: \(error)")
            completion(nil)
        }
    }
    
    // MARK: - Application Tracking
    
    private func startAppTracking() {
        guard appTrackingTimer == nil else {
            print("App tracking already active")
            return
        }
        
        print("Starting application tracking...")
        
        // Check for permissions first
        if !PermissionsManager.shared.checkPermission(.accessibility) {
            print("Accessibility permission not granted. Requesting...")
            PermissionsManager.shared.requestPermission(.accessibility)
            return
        }
        
        appTrackingTimer = Timer.scheduledTimer(
            withTimeInterval: appTrackingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.trackActiveApplication()
        }
        
        // Immediately track the current application
        trackActiveApplication()
        
        print("Application tracking active")
    }
    
    private func stopAppTracking() {
        appTrackingTimer?.invalidate()
        appTrackingTimer = nil
        print("Application tracking stopped")
    }
    
    private func trackActiveApplication() {
        // Get the active application
        guard let activeApp = NSWorkspace.shared.frontmostApplication else {
            print("No active application detected for app tracking")
            return
        }
        
        // Skip if the application is in the privacy filter
        if privacyFilter.isAppExcluded(activeApp.bundleIdentifier ?? "") {
            return
        }
        
        // Create an application tracking activity
        let activity = Activity(
            type: .applicationSwitch,
            timestamp: Date(),
            application: activeApp.localizedName ?? "Unknown",
            bundleIdentifier: activeApp.bundleIdentifier,
            content: nil
        )
        
        // Only publish if the application has changed
        if currentActivity?.application != activity.application {
            print("Publishing application switch: \(activity.application)")
            
            activityQueue.async { [weak self] in
                self?.activityPublisher.send(activity)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Checks status of all monitoring systems
    func checkStatus() -> [String: Bool] {
        return [
            "keyLogging": keyMonitor != nil || keyGlobalMonitor != nil,
            "screenAnalysis": screenCaptureTimer != nil,
            "appTracking": appTrackingTimer != nil
        ]
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Clean up all monitors and timers
        stopKeyLogging()
        stopScreenAnalysis()
        stopAppTracking()
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        print("ActivityMonitor deinitialized")
    }
}
