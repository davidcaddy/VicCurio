//
//  MuseumWebView.swift
//  VicCurio
//
//  In-app web view for viewing museum records.
//

import SwiftUI
import WebKit

struct MuseumWebView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            WebViewRepresentable(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Museums Victoria")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(item: url)
                    }
                }
        }
    }
}

// MARK: - WebView Representable

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed
    }
}

#Preview {
    MuseumWebView(url: URL(string: "https://collections.museumsvictoria.com.au")!)
}
