import Foundation

// MARK: - Config
struct SupabaseConfig {
    static let url     = "https://ptmgoqpdbunamqsnevdn.supabase.co"
    static let anonKey = "sb_publishable_sFSM24YIYc92u41Gf7e2wg_d9yCJd7t"
}

// MARK: - Auth State
@Observable
class SupabaseAuth {
    static let shared = SupabaseAuth()

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "sb_access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "sb_access_token") }
    }

    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "sb_refresh_token") }
        set { UserDefaults.standard.set(newValue, forKey: "sb_refresh_token") }
    }

    var userId: String? {
        get { UserDefaults.standard.string(forKey: "sb_user_id") }
        set { UserDefaults.standard.set(newValue, forKey: "sb_user_id") }
    }

    var userEmail: String? {
        get { UserDefaults.standard.string(forKey: "sb_user_email") }
        set { UserDefaults.standard.set(newValue, forKey: "sb_user_email") }
    }

    var isLoggedIn: Bool { accessToken != nil && userId != nil }

    func signUp(email: String, password: String, username: String) async throws {
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["username": username]
        ]
        let response: AuthResponse = try await SupabaseClient.shared.post(
            path: "/auth/v1/signup",
            body: body,
            requiresAuth: false
        )
        saveSession(response)
    }

    func signIn(email: String, password: String) async throws {
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        let response: AuthResponse = try await SupabaseClient.shared.post(
            path: "/auth/v1/token?grant_type=password",
            body: body,
            requiresAuth: false
        )
        saveSession(response)
    }

    func signOut() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        userEmail = nil
    }

    private func saveSession(_ r: AuthResponse) {
        accessToken  = r.access_token
        refreshToken = r.refresh_token
        userId       = r.user?.id
        userEmail    = r.user?.email
    }
}

// MARK: - HTTP Client
class SupabaseClient {
    static let shared = SupabaseClient()
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    // GET — returns array
    func get<T: Decodable>(table: String, query: String = "") async throws -> [T] {
        var urlStr = "\(SupabaseConfig.url)/rest/v1/\(table)"
        if !query.isEmpty { urlStr += "?\(query)" }
        guard let url = URL(string: urlStr) else { throw SBError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        addHeaders(&req, preferReturn: nil)
        let (data, _) = try await session.data(for: req)
        return try decoder.decode([T].self, from: data)
    }

    // POST — insert single row
    func insert<T: Encodable & Decodable>(table: String, body: T) async throws -> T {
        guard let url = URL(string: "\(SupabaseConfig.url)/rest/v1/\(table)") else { throw SBError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        addHeaders(&req, preferReturn: "representation")
        req.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: req)
        try checkStatus(response)
        let arr = try decoder.decode([T].self, from: data)
        guard let first = arr.first else { throw SBError.noData }
        return first
    }

    // PATCH — update row
    func update<T: Encodable>(table: String, id: String, body: T) async throws {
        guard let url = URL(string: "\(SupabaseConfig.url)/rest/v1/\(table)?id=eq.\(id)") else { throw SBError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        addHeaders(&req, preferReturn: nil)
        req.httpBody = try encoder.encode(body)
        let (_, response) = try await session.data(for: req)
        try checkStatus(response)
    }

    // DELETE
    func delete(table: String, id: String) async throws {
        guard let url = URL(string: "\(SupabaseConfig.url)/rest/v1/\(table)?id=eq.\(id)") else { throw SBError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        addHeaders(&req, preferReturn: nil)
        let (_, response) = try await session.data(for: req)
        try checkStatus(response)
    }

    // Generic POST (for auth)
    func post<T: Decodable>(path: String, body: [String: Any], requiresAuth: Bool) async throws -> T {
        guard let url = URL(string: "\(SupabaseConfig.url)\(path)") else { throw SBError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        if requiresAuth, let token = SupabaseAuth.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: req)
        try checkStatus(response)
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Helpers
    private func addHeaders(_ req: inout URLRequest, preferReturn: String?) {
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        if let token = SupabaseAuth.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let prefer = preferReturn {
            req.setValue("return=\(prefer)", forHTTPHeaderField: "Prefer")
        }
    }

    private func checkStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode >= 400 {
            throw SBError.httpError(http.statusCode)
        }
    }
}

// MARK: - Auth Response Models
struct AuthResponse: Decodable {
    let access_token: String?
    let refresh_token: String?
    let user: SBUser?
}

struct SBUser: Decodable {
    let id: String?
    let email: String?
}

// MARK: - Errors
enum SBError: Error, LocalizedError {
    case invalidURL
    case noData
    case httpError(Int)
    case notLoggedIn

    var errorDescription: String? {
        switch self {
        case .invalidURL:      return "URL inválido"
        case .noData:          return "Sem dados"
        case .httpError(let c): return "Erro HTTP \(c)"
        case .notLoggedIn:     return "Não autenticado"
        }
    }
}
