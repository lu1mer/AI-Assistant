import Foundation

enum AIServiceError: String, Error, Codable, Sendable, Equatable, LocalizedError {
    case offline, timeout, rateLimited, unauthorized, unavailable, invalidResponse
    case interrupted, contextTooLong, rejected, missingKey, unknown

    var errorDescription: String? {
        switch self {
        case .offline: "Нет подключения к интернету. Проверьте сеть и повторите отправку."
        case .timeout: "Сервис не успел ответить. Попробуйте ещё раз."
        case .rateLimited: "Лимит запросов исчерпан. Подождите немного и повторите."
        case .unauthorized: "Сервис не принял ключ доступа. Требуется обновление ключа приложения."
        case .unavailable: "AI-сервис временно недоступен. Попробуйте позже."
        case .invalidResponse: "Получен некорректный ответ. Попробуйте ещё раз."
        case .interrupted: "Соединение прервалось до завершения ответа. Можно повторить запрос."
        case .contextTooLong: "Диалог слишком большой для сервиса. Начните новый чат."
        case .rejected: "Сервис отклонил запрос. Попробуйте изменить сообщение."
        case .missingKey: "Ключ AI-сервиса ещё не добавлен в эту сборку."
        case .unknown: "Не удалось получить ответ. Попробуйте ещё раз."
        }
    }

    var canRetry: Bool {
        ![.missingKey, .unauthorized, .contextTooLong, .rejected].contains(self)
    }

    static func http(_ status: Int) -> Self {
        switch status {
        case 401, 403: .unauthorized
        case 408, 504: .timeout
        case 402, 429: .rateLimited
        case 413: .contextTooLong
        case 400, 404, 422: .rejected
        case 500...599: .unavailable
        default: .invalidResponse
        }
    }

    static func map(_ error: Error) -> Self {
        if let known = error as? Self { return known }
        guard let network = error as? URLError else { return .unknown }
        switch network.code {
        case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff: return .offline
        case .timedOut: return .timeout
        case .networkConnectionLost: return .interrupted
        case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed: return .unavailable
        default: return .unknown
        }
    }
}
