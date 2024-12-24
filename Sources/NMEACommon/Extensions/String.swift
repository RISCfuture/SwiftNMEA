import Foundation

package extension StringProtocol {
    func slice(from start: Int, to end: Int) -> SubSequence {
        let start = index(startIndex, offsetBy: start),
            end = index(startIndex, offsetBy: end)
        return self[start...end]
    }

    func slice(from start: Int) -> SubSequence {
        let start = index(startIndex, offsetBy: start)
        return self[start...]
    }

    func slice(to end: Int) -> SubSequence {
        let end = index(startIndex, offsetBy: end)
        return self[...end]
    }

    func sslice(from start: Int, to end: Int) -> String {
        String(slice(from: start, to: end))
    }

    func sslice(from start: Int) -> String {
        String(slice(from: start))
    }

    func sslice(to end: Int) -> String {
        String(slice(to: end))
    }

    func char(at: Int) -> Character? {
        self[safe: index(startIndex, offsetBy: at)]
    }
}
