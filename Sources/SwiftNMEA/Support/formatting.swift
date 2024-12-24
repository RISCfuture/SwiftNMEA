import Foundation

let hmsFractionFormatter = {
    let f = DateFormatter()
    f.timeZone = .gmt
    f.dateFormat = "HHmmss.SS"
    return f
}()

let hhmmFormatter = {
    let f = DateFormatter()
    f.timeZone = .gmt
    f.dateFormat = "HHmm"
    return f
}()

let dateFormatter = {
    let f = DateFormatter()
    f.timeZone = .gmt
    f.dateFormat = "ddMMyyyy"
    return f
}()

let dayFormatter = {
    let f = DateFormatter()
    f.timeZone = .gmt
    f.dateFormat = "dd"
    return f
}()

let monthFormatter = {
    let f = DateFormatter()
    f.timeZone = .gmt
    f.dateFormat = "MM"
    return f
}()
