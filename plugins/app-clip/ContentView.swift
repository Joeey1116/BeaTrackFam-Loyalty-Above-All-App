import StoreKit
import SwiftUI

// MARK: - Model

/// One product shown in the clip. Decoded from the live storefront catalog
/// (GET https://beatrackfam.info/api/catalog); see `ClipProduct.fallback`
/// for the offline list used when the network is unavailable.
struct ClipProduct: Identifiable {
  let handle: String
  let title: String
  let collection: String
  let priceCents: Int
  let imageURL: URL?

  var id: String { handle }

  var priceText: String {
    "from $\(String(format: "%.2f", Double(priceCents) / 100.0))"
  }

  var webURL: URL {
    URL(string: "https://beatrackfam.info/products/\(handle)")!
  }

  /// Real products from the live catalog (verified Nov 10, 2026), used when
  /// the catalog fetch fails so the clip is never empty.
  static let fallback: [ClipProduct] = [
    ClipProduct(
      handle: "988-bumper-sticker",
      title: "988 Bumper Sticker",
      collection: "You Are Not Alone Collection",
      priceCents: 725,
      imageURL: nil
    ),
    ClipProduct(
      handle: "988-desk-mat",
      title: "988 Desk Mat",
      collection: "You Are Not Alone Collection",
      priceCents: 1915,
      imageURL: nil
    ),
    ClipProduct(
      handle: "988-magnetic-phone-case",
      title: "988 Magnetic Phone Case",
      collection: "You Are Not Alone Collection",
      priceCents: 1998,
      imageURL: nil
    ),
  ]
}

private struct CatalogResponse: Decodable {
  let products: [CatalogProduct]
}

private struct CatalogProduct: Decodable {
  let handle: String
  let title: String
  let collection_title: String?
  let image: String?
  let variants: [CatalogVariant]

  var cheapestPriceCents: Int? {
    variants.map(\.price_cents).min()
  }
}

private struct CatalogVariant: Decodable {
  let price_cents: Int
}

// MARK: - View

struct ContentView: View {
  /// The URL that launched this clip, if any (App Clip Code / link).
  let invocationURL: URL?

  @State private var products: [ClipProduct] = ClipProduct.fallback
  @State private var showAppStoreOverlay = false

  /// If the clip was opened from a product URL, highlight that product.
  private var invokedProduct: ClipProduct? {
    guard let path = invocationURL?.pathComponents, path.count >= 3,
      path[path.count - 2] == "products"
    else { return nil }
    let handle = path[path.count - 1]
    return products.first { $0.handle == handle }
  }

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          header
          if let invokedProduct = invokedProduct {
            invokedBanner(product: invokedProduct)
          }
          featuredSection
          actionsSection
          footer
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
      }
    }
    .preferredColorScheme(.dark)
    .task { await loadCatalog() }
    .appStoreOverlay(isPresented: $showAppStoreOverlay) {
      // Full BeaTrackFam app in the App Store (ascAppId in eas.json).
      SKOverlay.AppConfiguration(appIdentifier: "6758099740", position: .bottom)
    }
  }

  // MARK: Sections

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("APP CLIP")
        .font(.caption.weight(.bold))
        .tracking(2)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
      Text("BeaTrackFam")
        .font(.system(size: 34, weight: .black))
        .foregroundColor(.white)
      Text("Loyalty above all.")
        .font(.headline)
        .foregroundColor(.white.opacity(0.75))
      Text("You're previewing the shop — no download needed.")
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.6))
    }
  }

  private func invokedBanner(product: ClipProduct) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("You scanned for this one")
        .font(.caption.weight(.semibold))
        .foregroundColor(.white.opacity(0.6))
      Text(product.title)
        .font(.title3.weight(.bold))
        .foregroundColor(.white)
      Text(product.priceText)
        .font(.subheadline)
        .foregroundColor(.white.opacity(0.75))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(Color.white.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 14))
  }

  private var featuredSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Featured right now")
        .font(.title3.weight(.bold))
        .foregroundColor(.white)
      ForEach(products.prefix(6)) { product in
        Link(destination: product.webURL) {
          HStack(spacing: 12) {
            productThumbnail(product)
            VStack(alignment: .leading, spacing: 2) {
              Text(product.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
              Text(product.collection)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
              Text(product.priceText)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
            Image(systemName: "chevron.right")
              .foregroundColor(.white.opacity(0.4))
          }
          .padding(12)
          .background(Color.white.opacity(0.08))
          .clipShape(RoundedRectangle(cornerRadius: 14))
        }
      }
    }
  }

  private func productThumbnail(_ product: ClipProduct) -> some View {
    Group {
      if let imageURL = product.imageURL {
        AsyncImage(url: imageURL) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Color.white.opacity(0.12)
        }
      } else {
        Color.white.opacity(0.12)
          .overlay {
            Image(systemName: "bag.fill")
              .foregroundColor(.white.opacity(0.5))
          }
      }
    }
    .frame(width: 64, height: 64)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }

  private var actionsSection: some View {
    VStack(spacing: 12) {
      Button {
        showAppStoreOverlay = true
      } label: {
        Text("Get the full BeaTrackFam app")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(Color.white)
          .foregroundColor(.black)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
      Link(destination: URL(string: "https://beatrackfam.info")!) {
        Text("Continue shopping on the web")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(Color.white.opacity(0.12))
          .foregroundColor(.white)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
      Link(destination: URL(string: "beatrackfam://")!) {
        Text("Already have the app? Open it")
          .font(.subheadline.weight(.semibold))
          .foregroundColor(.white.opacity(0.7))
      }
    }
  }

  private var footer: some View {
    Text("BeaTrackFam · Community over profit — good quality at fair prices.")
      .font(.caption)
      .foregroundColor(.white.opacity(0.45))
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
  }

  // MARK: Catalog

  private func loadCatalog() async {
    guard let url = URL(string: "https://beatrackfam.info/api/catalog") else { return }
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let catalog = try JSONDecoder().decode(CatalogResponse.self, from: data)
      let loaded = catalog.products.compactMap { item -> ClipProduct? in
        guard let price = item.cheapestPriceCents else { return nil }
        return ClipProduct(
          handle: item.handle,
          title: item.title,
          collection: item.collection_title ?? "BeaTrackFam",
          priceCents: price,
          imageURL: item.image.flatMap(URL.init(string:))
        )
      }
      if !loaded.isEmpty {
        products = loaded
      }
    } catch {
      // Offline or catalog hiccup: keep the static fallback list.
    }
  }
}
