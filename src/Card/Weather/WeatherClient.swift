import Foundation

/// Fetches global forecasts from MET Norway while honoring the service's cache contract.
nonisolated enum WeatherClient {
    private static let endpoint = "https://api.met.no/weatherapi/locationforecast/2.0/compact"
    private static let fallbackCacheDuration: TimeInterval = 15 * 60

    static func fetch(
        latitude: Double,
        longitude: Double,
        lastModified: String?
    ) async throws -> WeatherFetchResult {
        let request = try request(
            latitude: latitude,
            longitude: longitude,
            lastModified: lastModified
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw WeatherClientError.invalidResponse
        }

        let expirationDate = expirationDate(from: response)
        let responseLastModified = response.value(forHTTPHeaderField: "Last-Modified")
            ?? lastModified

        if response.statusCode == 304 {
            return .notModified(
                expirationDate: expirationDate,
                lastModified: responseLastModified
            )
        }

        guard (200...299).contains(response.statusCode) else {
            throw WeatherClientError.serviceStatus(response.statusCode)
        }

        return .updated(
            try snapshot(from: data, expirationDate: expirationDate),
            lastModified: responseLastModified
        )
    }

    static func request(
        latitude: Double,
        longitude: Double,
        lastModified: String?
    ) throws -> URLRequest {
        var components = URLComponents(string: endpoint)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: coordinateString(latitude)),
            URLQueryItem(name: "lon", value: coordinateString(longitude))
        ]
        guard let url = components?.url else {
            throw WeatherClientError.invalidResponse
        }

        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 20
        )
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        if let lastModified {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }
        return request
    }

    static func snapshot(
        from data: Data,
        now: Date = .now,
        expirationDate: Date
    ) throws -> WeatherSnapshot {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(METWeatherResponse.self, from: data)
        let timeseries = response.properties.timeseries.sorted { $0.time < $1.time }
        guard let first = timeseries.first else {
            throw WeatherClientError.missingForecast
        }

        let current = timeseries.last(where: { $0.time <= now }) ?? first
        let horizon = current.time.addingTimeInterval(24 * 60 * 60)
        let temperatures = timeseries
            .filter { $0.time >= current.time && $0.time <= horizon }
            .map(\.data.instant.details.airTemperature)
        guard let highCelsius = temperatures.max(),
              let lowCelsius = temperatures.min() else {
            throw WeatherClientError.missingForecast
        }

        let symbolCode = current.data.next1Hours?.summary.symbolCode
            ?? current.data.next6Hours?.summary.symbolCode
            ?? current.data.next12Hours?.summary.symbolCode
            ?? "cloudy"
        let condition = visualCondition(forSymbolCode: symbolCode)
        let daylight = isDaylight(
            symbolCode: symbolCode,
            at: current.time,
            longitude: response.geometry.coordinates.first ?? 0
        )
        let unit = preferredTemperatureUnit

        return WeatherSnapshot(
            highTemperature: displayedTemperature(highCelsius, in: unit),
            lowTemperature: displayedTemperature(lowCelsius, in: unit),
            temperatureUnit: unit == .fahrenheit ? "fahrenheit" : "celsius",
            currentTemperatureCelsius: current.data.instant.details.airTemperature,
            condition: condition,
            symbolName: symbolName(for: condition, isDaylight: daylight),
            isDaylight: daylight,
            observedAt: current.time,
            expirationDate: expirationDate
        )
    }

    static func visualCondition(forSymbolCode symbolCode: String) -> WeatherCondition {
        if symbolCode.contains("thunder") {
            .storm
        } else if symbolCode.contains("snow") || symbolCode.contains("sleet") {
            .snow
        } else if symbolCode.contains("rain") || symbolCode.contains("drizzle") {
            .rain
        } else if symbolCode.contains("fog") {
            .fog
        } else if symbolCode.contains("partlycloudy") {
            .partlyCloudy
        } else if symbolCode.contains("cloudy") {
            .cloudy
        } else {
            .clear
        }
    }

    static func needsRefresh(expirationDate: Date?, now: Date = .now) -> Bool {
        guard let expirationDate else { return true }
        return expirationDate <= now
    }

    static func expirationDate(
        from response: HTTPURLResponse,
        now: Date = .now
    ) -> Date {
        guard let value = response.value(forHTTPHeaderField: "Expires"),
              let parsedDate = httpDate(value) else {
            return now.addingTimeInterval(fallbackCacheDuration)
        }
        return max(parsedDate, now.addingTimeInterval(60))
    }

    private static var userAgent: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? "1.0"
        return "Copycola/\(version) github.com/lainsce/Copycola"
    }

    private static var preferredTemperatureUnit: UnitTemperature {
        Locale.current.measurementSystem == .us ? .fahrenheit : .celsius
    }

    private static func coordinateString(_ coordinate: Double) -> String {
        let rounded = (coordinate * 10_000).rounded() / 10_000
        return String(rounded)
    }

    private static func displayedTemperature(
        _ celsius: Double,
        in unit: UnitTemperature
    ) -> Int {
        let measurement = Measurement(value: celsius, unit: UnitTemperature.celsius)
        return Int(measurement.converted(to: unit).value.rounded())
    }

    private static func symbolName(
        for condition: WeatherCondition,
        isDaylight: Bool
    ) -> String {
        switch condition {
        case .clear:
            isDaylight ? "sun.max.fill" : "moon.stars.fill"
        case .partlyCloudy:
            isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
        default:
            condition.systemImage
        }
    }

    private static func isDaylight(
        symbolCode: String,
        at date: Date,
        longitude: Double
    ) -> Bool {
        if symbolCode.hasSuffix("_day") { return true }
        if symbolCode.hasSuffix("_night") { return false }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let utcHour = Double(components.hour ?? 12) + Double(components.minute ?? 0) / 60
        let solarHour = (utcHour + longitude / 15 + 24)
            .truncatingRemainder(dividingBy: 24)
        return (6..<18).contains(solarHour)
    }

    private static func httpDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
        return formatter.date(from: value)
    }
}
