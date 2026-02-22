import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var refreshTimer: Timer?
    private var lastTokenData: TokenData?
    private var isLoading = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
            button.title = "Punch | Loading..."
        }

        buildMenu()
        fetchData()
        startTimer()
    }

    // MARK: - Timer

    private func startTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.fetchData()
        }
    }

    // MARK: - Data Fetching

    private func fetchData() {
        guard !isLoading else { return }
        isLoading = true

        DexScreenerAPI.fetchTokenData { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                switch result {
                case .success(let data):
                    self.lastTokenData = data
                    self.updateStatusBar(with: data)
                    self.buildMenu()
                case .failure(let error):
                    // Keep last data on error, only update if no data yet
                    if self.lastTokenData == nil {
                        self.statusItem.button?.title = "Punch | Error"
                    }
                    print("Fetch error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - UI Updates

    private func updateStatusBar(with data: TokenData) {
        let mcap = Formatters.formatCompactCurrency(data.marketCap)
        statusItem.button?.title = "Punch | MCap \(mcap)"
    }

    private func buildMenu() {
        let menu = NSMenu()

        if let data = lastTokenData {
            let priceItem = NSMenuItem(title: "Price: \(Formatters.formatPrice(data.priceUsd))", action: nil, keyEquivalent: "")
            priceItem.isEnabled = false
            menu.addItem(priceItem)

            let volItem = NSMenuItem(title: "24h Volume: \(Formatters.formatCompactCurrency(data.volume24h))", action: nil, keyEquivalent: "")
            volItem.isEnabled = false
            menu.addItem(volItem)

            let mcapItem = NSMenuItem(title: "Market Cap: \(Formatters.formatCompactCurrency(data.marketCap))", action: nil, keyEquivalent: "")
            mcapItem.isEnabled = false
            menu.addItem(mcapItem)

            let changeStr = Formatters.formatPercent(data.priceChange24h)
            let changeItem = NSMenuItem(title: "24h Change: \(changeStr)", action: nil, keyEquivalent: "")
            changeItem.isEnabled = false
            menu.addItem(changeItem)

            let liqItem = NSMenuItem(title: "Liquidity: \(Formatters.formatCompactCurrency(data.liquidityUsd))", action: nil, keyEquivalent: "")
            liqItem.isEnabled = false
            menu.addItem(liqItem)

            let dexItem = NSMenuItem(title: "DEX: \(data.dexName)", action: nil, keyEquivalent: "")
            dexItem.isEnabled = false
            menu.addItem(dexItem)
        } else {
            let loadingItem = NSMenuItem(title: "Loading data...", action: nil, keyEquivalent: "")
            loadingItem.isEnabled = false
            menu.addItem(loadingItem)
        }

        menu.addItem(NSMenuItem.separator())

        let dexLink = NSMenuItem(title: "Open on DexScreener", action: #selector(openDexScreener), keyEquivalent: "o")
        dexLink.keyEquivalentModifierMask = .command
        dexLink.target = self
        menu.addItem(dexLink)

        menu.addItem(NSMenuItem.separator())

        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.keyEquivalentModifierMask = .command
        refreshItem.target = self
        menu.addItem(refreshItem)

        let quitItem = NSMenuItem(title: "Quit Punch", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func openDexScreener() {
        let urlStr = lastTokenData?.dexScreenerUrl
            ?? "https://dexscreener.com/solana/\(DexScreenerAPI.tokenAddress)"
        if let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func refreshNow() {
        fetchData()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
