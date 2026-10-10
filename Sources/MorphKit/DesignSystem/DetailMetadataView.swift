import SwiftUI

/// Raycast-style Detail.Metadata components (matching ui-references screenshots)
public struct DetailMetadataSection<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minWidth: 180, maxWidth: 240)
    }
}

/// Detail.Metadata.Label (Screenshot 2026-10-10 at 9.19.05 PM)
public struct DetailMetadataLabel: View {
    public let label: String
    public let value: String
    public let icon: String?

    public init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
        }
    }
}

/// Detail.Metadata.Link (Screenshot 2026-10-10 at 9.19.13 PM)
public struct DetailMetadataLink: View {
    public let label: String
    public let title: String
    public let action: () -> Void

    public init(label: String, title: String, action: @escaping () -> Void) {
        self.label = label
        self.title = title
        self.action = action
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Button(action: action) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Detail.Metadata.TagList (Screenshot 2026-10-10 at 9.19.23 PM)
public struct DetailMetadataTagList: View {
    public let label: String
    public let tags: [(text: String, color: Color)]

    public init(label: String, tags: [(text: String, color: Color)]) {
        self.label = label
        self.tags = tags
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(tags.indices, id: \.self) { i in
                    let tag = tags[i]
                    Text(tag.text)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(tag.color.opacity(0.18))
                                .overlay {
                                    Capsule()
                                        .stroke(tag.color.opacity(0.40), lineWidth: 0.8)
                                }
                        }
                        .foregroundStyle(tag.color)
                }
            }
        }
    }
}

/// Detail.Metadata.Separator (Screenshot 2026-10-10 at 9.19.33 PM)
public struct DetailMetadataSeparator: View {
    public init() {}

    public var body: some View {
        Divider()
            .overlay(.quaternary)
            .padding(.vertical, 2)
    }
}
