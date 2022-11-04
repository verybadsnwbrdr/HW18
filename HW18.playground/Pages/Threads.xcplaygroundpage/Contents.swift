import UIKit

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
        return Chip(chipType: chipType)
    }
    
    public func sodering() {
        let soderingTime = chipType.rawValue
        sleep(UInt32(soderingTime))
    }
}

// MARK: - LIFO Storage

class MyLIFOStorage {
    private var chipStorage = [Chip]()
    private let storageSemaphore = DispatchSemaphore(value: 1)
    
    func append(new chip: Chip) {
        storageSemaphore.wait()
        chipStorage.append(chip)
        print("\(Date()) Чип \(chip.chipType.rawValue) создан. Хранилище чипов: [\(getAllChips())]")
        storageSemaphore.signal()
    }
    
    func remove() -> Chip {
        storageSemaphore.wait()
        let chip = chipStorage.removeFirst()
        print("\(Date()) Чип \(chip.chipType.rawValue) отдан на припайку. Хранилище чипов: [\(getAllChips())]")
        storageSemaphore.signal()
        return chip
    }
    
    func getAllChips() -> String {
        chipStorage.map { String($0.chipType.rawValue) }.joined(separator: ", ")
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
    
    private var chipsCounter = 0
    private let requiredNumberOfChips: Int
    
    init(storage: MyLIFOStorage, workingTime: Double, semaphore: DispatchSemaphore) {
        self.storage = storage
        self.requiredNumberOfChips = Int(workingTime / 2)
        self.semaphore = semaphore
    }
    
    override func main() {
        while true {
            guard let storage = storage, let semaphore = semaphore else { return }
            semaphore.wait()
            chipSodering(storage: storage)
            if chipsCounter == requiredNumberOfChips {
                print("SoderingThread завершён")
                cancel()
            }
        }
    }
    
    private func chipSodering(storage: MyLIFOStorage) {
        let chip = storage.remove()
        chip.sodering()
        chipsCounter += 1
        print("\n\(Date()) Чип \(chip.chipType.rawValue) припаян\n")
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
