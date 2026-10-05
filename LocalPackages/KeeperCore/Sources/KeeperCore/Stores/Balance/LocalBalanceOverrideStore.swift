import BigInt
import Foundation

public final class LocalBalanceOverrideStore {
    public static let shared = LocalBalanceOverrideStore()

    public var onChange: (() -> Void)?

    private let userDefaultsKey = "TKLocalBalanceOverrides"
    private var overrides: [String: Decimal] = [:]

    private init() {
        load()
    }

    public func override(for identifier: String) -> Decimal? {
        return overrides[identifier]
    }

    public func setOverride(_ amount: Decimal, for identifier: String) {
        overrides[identifier] = amount
        save()
        onChange?()
    }

    public func removeOverride(for identifier: String) {
        overrides.removeValue(forKey: identifier)
        save()
        onChange?()
    }

    public func removeAll() {
        overrides.removeAll()
        save()
        onChange?()
    }

    private func save() {
        let stringDict = overrides.mapValues { $0.description }
        UserDefaults.standard.set(stringDict, forKey: userDefaultsKey)
    }

    private func load() {
        guard let stringDict = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] else {
            return
        }
        var loaded: [String: Decimal] = [:]
        for (key, val) in stringDict {
            if let decimal = Decimal(string: val) {
                loaded[key] = decimal
            }
        }
        self.overrides = loaded
    }
}

public extension Decimal {
    func toBigUInt(fractionalDigits: Int) -> BigUInt {
        let multiplier = Decimal(sign: .plus, exponent: fractionalDigits, significand: 1)
        let scaled = self * multiplier
        let stringValue = NSDecimalNumber(decimal: scaled).stringValue
        let integerPart = stringValue.components(separatedBy: ".").first ?? "0"
        return BigUInt(integerPart) ?? 0
    }

    func toUInt64(fractionalDigits: Int) -> UInt64 {
        let bigUInt = toBigUInt(fractionalDigits: fractionalDigits)
        return UInt64(min(bigUInt, BigUInt(UInt64.max)))
    }
}
