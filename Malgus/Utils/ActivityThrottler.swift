//
//  ActivityThrottler.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation

class ActivityThrottler {
    private let minimumDelay: TimeInterval
    private var lastFireTime: Date?
    private var queued = false
    private let queue: DispatchQueue
    
    init(minimumDelay: TimeInterval, queue: DispatchQueue = .main) {
        self.minimumDelay = minimumDelay
        self.queue = queue
    }
    
    func execute(_ handler: @escaping () -> Void) {
        // Check if we've executed recently
        if let lastFireTime = lastFireTime {
            let elapsed = Date().timeIntervalSince(lastFireTime)
            
            if elapsed < minimumDelay {
                // Not enough time has passed, queue the execution
                if !queued {
                    queued = true
                    
                    let delay = minimumDelay - elapsed
                    queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self = self else { return }
                        
                        self.lastFireTime = Date()
                        self.queued = false
                        handler()
                    }
                }
                return
            }
        }
        
        // Enough time has passed, execute now
        lastFireTime = Date()
        handler()
    }
}
