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
        print("\n\(Date()) Чип \(chipID) припаян\n")
    }
}

// MARK: - LIFO Storage

class MyLIFOStorage {
    private var chipStorage = [Chip]()
    private let storageSemaphore = DispatchSemaphore(value: 1)
    
    func append(new chip: Chip) {
        storageSemaphore.wait()
        chipStorage.append(chip)
        print("\(Date()) Чип \(chip.chipID) (задержка \(chip.chipType.rawValue)) создан. Хранилище чипов: [\(getAllChips())]")
        storageSemaphore.signal()
    }
    
    func remove() -> Chip {
        storageSemaphore.wait()
        let chip = chipStorage.removeFirst()
        print("\(Date()) Чип \(chip.chipID) отдан на припайку. Хранилище чипов: [\(getAllChips())]")
        storageSemaphore.signal()
        return chip
    }
    
    func getAllChips() -> String {
        chipStorage.map { "ID: " + String($0.chipID) }.joined(separator: ", ")
    }
}

// MARK: - Threads

class FactoryThread: Thread {
    
    private weak var storage: MyLIFOStorage?
    private weak var semaphore: DispatchSemaphore?
    
    private let workingTime: Double
    
    init(storage: MyLIFOStorage, workingTime: Double, semaphore: DispatchSemaphore) {
        self.storage = storage
        self.workingTime = workingTime
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
        RunLoop.current.run(until: .now + workingTime)
        print("\nFactoryThread завершён")
        cancel()
    }
}

class SoderingThread: Thread {
    
    private weak var storage: MyLIFOStorage?
    private weak var semaphore: DispatchSemaphore?
    
    private let chipsCount: Int
    
    init(storage: MyLIFOStorage, workingTime: Double, semaphore: DispatchSemaphore) {
        self.storage = storage
        self.chipsCount = Int(workingTime / 2)
        self.semaphore = semaphore
    }
    
    override func main() {
        while true {
            guard let storage = storage, let semaphore = semaphore else { return }
            semaphore.wait()
            let chip = storage.remove()
            chip.sodering()
            if chip.chipID == chipsCount {
                print("SoderingThread завершён")
                cancel()
            }
        }
    }
}

// MARK: - Instances and Constants

print("\(Date()) Время старта программы\n")

let workingTime = 20.0
let semaphore = DispatchSemaphore(value: 0)
let storageOfChips = MyLIFOStorage()
let factoryThread = FactoryThread(storage: storageOfChips, workingTime: workingTime, semaphore: semaphore)
let soderingThread = SoderingThread(storage: storageOfChips, workingTime: workingTime, semaphore: semaphore)

factoryThread.start()
soderingThread.start()
