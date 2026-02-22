import Foundation

// MARK: - API Response Models

struct DexPair: Codable {
    let chainId: String
    let dexId: String
    let url: String
    let pairAddress: String
    let baseToken: DexToken
    let quoteToken: DexToken
    let priceNative: String?
    let priceUsd: String?
    let volume: DexVolume?
    let priceChange: DexPriceChange?
    let liquidity: DexLiquidity?
    let fdv: Double?
    let marketCap: Double?
}

struct DexToken: Codable {
    let address: String
    let name: String
    let symbol: String
}

struct DexVolume: Codable {
    let h24: Double?
    let h6: Double?
    let h1: Double?
    let m5: Double?
}

struct DexPriceChange: Codable {
    let h24: Double?
    let h6: Double?
    let h1: Double?
    let m5: Double?
}

struct DexLiquidity: Codable {
    let usd: Double?
    let base: Double?
    let quote: Double?
}

// MARK: - Processed Token Data

struct TokenData {
    let symbol: String
    let name: String
    let priceUsd: Double
    let volume24h: Double
    let marketCap: Double
    let priceChange24h: Double
    let liquidityUsd: Double
    let dexScreenerUrl: String
    let dexName: String
}

// MARK: - API Client

enum DexScreenerAPI {
    static let tokenAddress = "NV2RYH954cTJ3ckFUpvfqaQXU4ARqqDH3562nFSpump"
    static let apiURL = "https://api.dexscreener.com/tokens/v1/solana/\(tokenAddress)"

    enum APIError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case noPairsFound
        case invalidPrice

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API URL"
            case .networkError(let e): return "Network error: \(e.localizedDescription)"
            case .decodingError(let e): return "Decoding error: \(e.localizedDescription)"
            case .noPairsFound: return "No trading pairs found"
            case .invalidPrice: return "Invalid price data"
            }
        }
    }

    static func fetchTokenData(completion: @escaping (Result<TokenData, Error>) -> Void) {
        guard let url = URL(string: apiURL) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(APIError.networkError(error)))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.networkError(
                    NSError(domain: "DexScreener", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                )))
                return
            }

            do {
                let pairs = try JSONDecoder().decode([DexPair].self, from: data)

                guard !pairs.isEmpty else {
                    completion(.failure(APIError.noPairsFound))
                    return
                }

                // Select the pair with highest 24h volume
                let bestPair = pairs.max(by: { ($0.volume?.h24 ?? 0) < ($1.volume?.h24 ?? 0) }) ?? pairs[0]

                guard let priceStr = bestPair.priceUsd, let price = Double(priceStr) else {
                    completion(.failure(APIError.invalidPrice))
                    return
                }

                let tokenData = TokenData(
                    symbol: bestPair.baseToken.symbol,
                    name: bestPair.baseToken.name,
                    priceUsd: price,
                    volume24h: bestPair.volume?.h24 ?? 0,
                    marketCap: bestPair.marketCap ?? bestPair.fdv ?? 0,
                    priceChange24h: bestPair.priceChange?.h24 ?? 0,
                    liquidityUsd: bestPair.liquidity?.usd ?? 0,
                    dexScreenerUrl: bestPair.url,
                    dexName: bestPair.dexId
                )

                completion(.success(tokenData))
            } catch {
                completion(.failure(APIError.decodingError(error)))
            }
        }
        task.resume()
    }
}
