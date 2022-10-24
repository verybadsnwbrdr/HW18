import UIKit
import Foundation

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }
    
    public let chipType: ChipType
    
    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }
        print("Chip created")
        return Chip(chipType: chipType)
    }
    
    public func sodering() {
        let soderingTime = chipType.rawValue
        sleep(UInt32(soderingTime))
        print("Sodering!")
    }
}

// MARK: - LIFO Storage

struct MyLIFOStorage {
    private var chipStorage = [Chip]()
    private let semaphore = DispatchSemaphore(value: 1)
    
    mutating func append(new chip: Chip) {
        semaphore.wait()
        chipStorage.append(chip)
        semaphore.signal()
    }
    
    mutating func remove() -> Chip {
        semaphore.wait()
        let chip = chipStorage.removeFirst()
        semaphore.signal()
        return chip
    }
    
    func isEmpty() -> Bool {
        chipStorage.isEmpty
    }
}

var storageOfChips = MyLIFOStorage()

// MARK: - Threads

class FactoryThread: Thread {
    override func main() {
        let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            let chip = Chip.make()
            storageOfChips.append(new: chip)
        }
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run(until: .now + 20)
    }
}

class SoderingThread: Thread {
    override func main() {
        for _ in 0...10 {
            while storageOfChips.isEmpty() {
                
            }
            storageOfChips.remove().sodering()
        }
    }
}

// MARK: - Instances

let factoryThread = FactoryThread()
let soderingThread = SoderingThread()

factoryThread.start()
soderingThread.start()

