import Foundation

final class APIClient: Sendable {
    private let baseURL: URL
    private let tokenProvider: @Sendable () -> String?
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        tokenProvider: @escaping @Sendable () -> String?,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL.appendingPathComponent(AppConfiguration.apiBasePath)
        self.tokenProvider = tokenProvider
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func request<T: Decodable & Sendable>(_ endpoint: APIEndpoint) async throws -> T {
        let request = try buildRequest(for: endpoint)
        let (data, response) = try await performRequest(request)
        return try decodeResponse(data: data, response: response)
    }

    func requestWithoutResponse(_ endpoint: APIEndpoint) async throws {
        let request = try buildRequest(for: endpoint)
        let (_, response) = try await performRequest(request)
        try validateResponse(response)
    }

    func uploadFile<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String
    ) async throws -> T {
        let request = try buildMultipartRequest(
            for: endpoint,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType
        )
        let (data, response) = try await performRequest(request)
        return try decodeResponse(data: data, response: response)
    }

    func uploadFileWithoutResponse(
        _ endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String
    ) async throws {
        let request = try buildMultipartRequest(
            for: endpoint,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType
        )
        let (_, response) = try await performRequest(request)
        try validateResponse(response)
    }

    // MARK: - Private Methods

    private func buildRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        )
        components?.queryItems = endpoint.queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = tokenProvider() {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
    }

    private func buildMultipartRequest(
        for endpoint: APIEndpoint,
        fileData: Data,
        fileName: String,
        mimeType: String
    ) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        )
        components?.queryItems = endpoint.queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = tokenProvider() {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        // Build multipart body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"attachment\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body
        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func decodeResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        try validateResponse(response)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown(0)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 409:
            throw APIError.conflict
        case 422:
            throw APIError.validationError("Validation failed")
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.unknown(httpResponse.statusCode)
        }
    }
}

// MARK: - AnyEncodable Helper

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self.encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
