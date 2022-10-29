import UIKit

public struct Chip {
    private static var chipsCounter = 0
    
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }
    
    public let chipID: Int
    public let chipType: ChipType
    
    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }
        Self.chipsCounter += 1
        return Chip(chipID: Self.chipsCounter, chipType: chipType)
    }
    
    public func sodering() {
        let soderingTime = chipType.rawValue
        sleep(UInt32(soderingTime))
        print("\nЧип \(chipID) припаян\n")
    }
}

// MARK: - LIFO Storage

class MyLIFOStorage {
    private var chipStorage = [Chip]()
    private let storageSemaphore = DispatchSemaphore(value: 1)
    
    func append(new chip: Chip) {
        storageSemaphore.wait()
        chipStorage.append(chip)
        print("Чип \(chip.chipID) (задержка \(chip.chipType.rawValue)) создан, ещё чипов - \(chipStorage.count)")
        storageSemaphore.signal()
    }
    
    func remove() -> Chip {
        storageSemaphore.wait()
        let chip = chipStorage.removeFirst()
        print("Чип \(chip.chipID) отдан на припайку, ещё чипов - \(chipStorage.count)")
        storageSemaphore.signal()
        return chip
    }
}

// MARK: - Threads

class FactoryThread: Thread {
    
    private weak var storage: MyLIFOStorage?
    private weak var semaphore: DispatchSemaphore?
    
    init(storage: MyLIFOStorage, semaphore: DispatchSemaphore) {
        self.storage = storage
        self.semaphore = semaphore
    }
    
    override func main() {
        guard let storage = storage, let semaphore = semaphore else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            let chip = Chip.make()
            storage.append(new: chip)
            semaphore.signal()
        }
        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run(until: .now + 20)
    }
}

class SoderingThread: Thread {
    
    private weak var storage: MyLIFOStorage?
    private weak var semaphore: DispatchSemaphore?
    
    init(storage: MyLIFOStorage, semaphore: DispatchSemaphore) {
        self.storage = storage
        self.semaphore = semaphore
    }
    
    override func main() {
        while true {
            guard let storage = storage, let semaphore = semaphore else { return }
            semaphore.wait()
            let chip = storage.remove()
            chip.sodering()
            guard chip.chipID != 10 else { break }
        }
    }
}

// MARK: - Instances

let semaphore = DispatchSemaphore(value: 0)
let storageOfChips = MyLIFOStorage()
let factoryThread = FactoryThread(storage: storageOfChips, semaphore: semaphore)
let soderingThread = SoderingThread(storage: storageOfChips, semaphore: semaphore)

factoryThread.start()
soderingThread.start()
