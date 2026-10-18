import SwiftUI
import AppKit

// MARK: - Toolbar Circle Button Styles

public enum ToolbarCircleButtonStyle {
    case dark
    case accent
}

/// Circular toolbar action button conforming to the native macOS / iOS design in reference images:
/// - Exact circular geometry with dark glass or electric blue accent
/// - Top specular edge stroke reflecting ambient lighting
/// - Subtle elevation drop shadow
/// - Tactile spring hover feedback
public struct ToolbarCircleButton: View {
    private let icon: String
    private let style: ToolbarCircleButtonStyle
    private let size: CGFloat
    private let iconSize: CGFloat
    private let tooltip: String?
    private let action: () -> Void

    @StateObject private var hover = HoverState()

    public init(
        icon: String,
        style: ToolbarCircleButtonStyle = .dark,
        size: CGFloat = 28,
        iconSize: CGFloat = 11,
        tooltip: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.iconSize = iconSize
        self.tooltip = tooltip
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundFill)
                    .overlay(
                        Circle().strokeBorder(strokeBorder, lineWidth: 0.6)
                    )
                    .shadow(color: shadowColor, radius: hover.isHovered ? 4 : 2.5, x: 0, y: 1.5)
                    .frame(width: size, height: size)

                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(iconForeground)
            }
            .contentShape(Circle())
            .scaleEffect(hover.isHovered ? 1.04 : 1.0)
            .animation(LiquidGlass.quickSpring, value: hover.isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hover.isHovered = hovering
        }
        .help(tooltip ?? "")
        .accessibilityLabel(tooltip ?? icon)
    }

    private var backgroundFill: AnyShapeStyle {
        switch style {
        case .dark:
            return AnyShapeStyle(
                Color(red: 24 / 255, green: 25 / 255, blue: 28 / 255)
                    .opacity(hover.isHovered ? 0.95 : 0.85)
            )
        case .accent:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0 / 255, green: 138 / 255, blue: 255 / 255),
                        Color(red: 0 / 255, green: 110 / 255, blue: 235 / 255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var strokeBorder: AnyShapeStyle {
        switch style {
        case .dark:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(hover.isHovered ? 0.28 : 0.18),
                        Color.white.opacity(0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .accent:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.45),
                        Color.white.opacity(0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var shadowColor: Color {
        switch style {
        case .dark:
            return Color.black.opacity(hover.isHovered ? 0.40 : 0.25)
        case .accent:
            return Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255).opacity(hover.isHovered ? 0.45 : 0.30)
        }
    }

    private var iconForeground: AnyShapeStyle {
        AnyShapeStyle(Color.white.opacity(0.95))
    }
}

// MARK: - Dedicated Toolbar Circle Button Specializations

/// Circular back button (`<`) matching Reference Image 4
public struct ToolbarBackButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        ToolbarCircleButton(
            icon: "chevron.left",
            style: .dark,
            size: 28,
            iconSize: 11,
            tooltip: "Back (⎋)",
            action: action
        )
    }
}

/// Circular search button (`🔍`) matching Reference Image 1
public struct ToolbarSearchButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        ToolbarCircleButton(
            icon: "magnifyingglass",
            style: .dark,
            size: 28,
            iconSize: 11,
            tooltip: "Search",
            action: action
        )
    }
}

/// Circular share button (`⎋`) matching Reference Image 2
public struct ToolbarShareButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        ToolbarCircleButton(
            icon: "square.and.arrow.up",
            style: .dark,
            size: 28,
            iconSize: 11,
            tooltip: "Share",
            action: action
        )
    }
}

/// Circular filter/sort button (`line.3.horizontal.decrease`) matching Reference Image 3 (Left)
public struct ToolbarFilterButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        ToolbarCircleButton(
            icon: "line.3.horizontal.decrease",
            style: .dark,
            size: 28,
            iconSize: 11,
            tooltip: "Filter / Sort",
            action: action
        )
    }
}

/// Circular blue checkmark button (`✓`) matching Reference Image 3 (Right)
public struct ToolbarCheckmarkButton: View {
    private let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        ToolbarCircleButton(
            icon: "checkmark",
            style: .accent,
            size: 28,
            iconSize: 12,
            tooltip: "Complete",
            action: action
        )
    }
}

// MARK: - Navigation Capsule Component (`[ <  > ]`) matching Reference Image 1

/// Navigation capsule button grouping back and forward navigation
public struct ToolbarNavigationCapsule: View {
    private let canGoBack: Bool
    private let canGoForward: Bool
    private let onBack: () -> Void
    private let onForward: () -> Void

    public init(
        canGoBack: Bool = true,
        canGoForward: Bool = false,
        onBack: @escaping () -> Void,
        onForward: @escaping () -> Void = {}
    ) {
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.onBack = onBack
        self.onForward = onForward
    }

    public var body: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(canGoBack ? Color.white.opacity(0.90) : Color.white.opacity(0.30))
                    .frame(width: 24, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canGoBack)
            .help("Back (⎋)")

            Divider()
                .overlay(Color.white.opacity(0.12))
                .frame(height: 12)

            Button(action: onForward) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(canGoForward ? Color.white.opacity(0.90) : Color.white.opacity(0.30))
                    .frame(width: 24, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
            .help("Forward")
        }
        .padding(.horizontal, 4)
        .frame(height: 28)
        .background(
            Capsule()
                .fill(Color(red: 24 / 255, green: 25 / 255, blue: 28 / 255).opacity(0.85))
                .overlay(
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.white.opacity(0.06)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.6
                    )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 2.5, x: 0, y: 1.5)
        )
    }
}

// MARK: - View Mode Switcher Capsule (`[ ⊞ ᨈ ]`) matching Reference Image 1

/// View mode switcher capsule displaying layout icon with disclosure chevrons
public struct ToolbarViewModeCapsule: View {
    @Binding var viewMode: LauncherViewMode
    private let onChange: (LauncherViewMode) -> Void

    public init(viewMode: Binding<LauncherViewMode>, onChange: @escaping (LauncherViewMode) -> Void = { _ in }) {
        self._viewMode = viewMode
        self.onChange = onChange
    }

    private var modeIcon: String {
        switch viewMode {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        case .columns: return "rectangle.split.3x1"
        }
    }

    public var body: some View {
        Menu {
            Section("View Content As") {
                Button {
                    viewMode = .grid
                    onChange(.grid)
                } label: {
                    HStack {
                        Text("Grid")
                        if viewMode == .grid {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    viewMode = .list
                    onChange(.list)
                } label: {
                    HStack {
                        Text("List")
                        if viewMode == .list {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    viewMode = .columns
                    onChange(.columns)
                } label: {
                    HStack {
                        Text("Columns")
                        if viewMode == .columns {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: modeIcon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.90))

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            .padding(.horizontal, 9)
            .frame(height: 28)
            .background(
                Capsule()
                    .fill(Color(red: 24 / 255, green: 25 / 255, blue: 28 / 255).opacity(0.85))
                    .overlay(
                        Capsule().strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), Color.white.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.6
                        )
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 2.5, x: 0, y: 1.5)
            )
            .contentShape(Capsule())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .menuOrder(.fixed)
        .fixedSize()
        .help("View Options (Grid, List, Columns)")
    }
}

// MARK: - Grouped Action Capsule (`[ ☵ ᨈ  ⎋  🏷  ••• ᨈ ]`) matching Reference Image 1

/// Segmented action pill containing Sort, Share, Tag, and More options
public struct ToolbarGroupedActionCapsule: View {
    private let onSortMenu: AnyView
    private let onShare: () -> Void
    private let onTag: () -> Void
    private let onMoreMenu: AnyView

    public init<SortContent: View, MoreContent: View>(
        @ViewBuilder sortMenu: () -> SortContent,
        onShare: @escaping () -> Void,
        onTag: @escaping () -> Void = {},
        @ViewBuilder moreMenu: () -> MoreContent
    ) {
        self.onSortMenu = AnyView(sortMenu())
        self.onShare = onShare
        self.onTag = onTag
        self.onMoreMenu = AnyView(moreMenu())
    }

    public var body: some View {
        HStack(spacing: 0) {
            // 1. Sort / Filter Menu with chevron
            Menu {
                onSortMenu
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 10.5, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                .foregroundStyle(Color.white.opacity(0.90))
                .padding(.horizontal, 7)
                .frame(height: 28)
                .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .menuOrder(.fixed)
            .help("Filter & Sort Options")

            Divider()
                .overlay(Color.white.opacity(0.12))
                .frame(height: 12)

            // 2. Share Button
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.90))
                    .frame(width: 26, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Share or Open Files")

            Divider()
                .overlay(Color.white.opacity(0.12))
                .frame(height: 12)

            // 3. Tag Button
            Button(action: onTag) {
                Image(systemName: "tag")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.90))
                    .frame(width: 26, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Category Tags")

            Divider()
                .overlay(Color.white.opacity(0.12))
                .frame(height: 12)

            // 4. More Options (•••) Menu with chevron
            Menu {
                onMoreMenu
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 10.5, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                .foregroundStyle(Color.white.opacity(0.90))
                .padding(.horizontal, 7)
                .frame(height: 28)
                .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .menuOrder(.fixed)
            .help("More Actions & Preferences")
        }
        .padding(.horizontal, 4)
        .frame(height: 28)
        .background(
            Capsule()
                .fill(Color(red: 24 / 255, green: 25 / 255, blue: 28 / 255).opacity(0.85))
                .overlay(
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.white.opacity(0.06)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.6
                    )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 2.5, x: 0, y: 1.5)
        )
        .fixedSize()
    }
}

// MARK: - Multi-Action Capsule (`[ ☵   🗑   + ]`) matching Reference Image 5

/// Action pill grouping Filter/Sort, Trash/Clear, and Add/New
public struct ToolbarMultiActionCapsule: View {
    private let onFilter: () -> Void
    private let onDelete: () -> Void
    private let onAdd: () -> Void
    private let isDeleteEnabled: Bool

    public init(
        isDeleteEnabled: Bool = true,
        onFilter: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onAdd: @escaping () -> Void
    ) {
        self.isDeleteEnabled = isDeleteEnabled
        self.onFilter = onFilter
        self.onDelete = onDelete
        self.onAdd = onAdd
    }

    public var body: some View {
        HStack(spacing: 16) {
            // 1. Filter
            Button(action: onFilter) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .frame(width: 22, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Filter / Sort")

            // 2. Trash / Clear
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isDeleteEnabled ? Color.white.opacity(0.92) : Color.white.opacity(0.35))
                    .frame(width: 22, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!isDeleteEnabled)
            .help("Clear All (⎋)")

            // 3. Add / New
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .frame(width: 22, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Add Files / Browse (⌘O)")
        }
        .padding(.horizontal, 16)
        .frame(height: 32)
        .background(
            Capsule()
                .fill(Color(red: 22 / 255, green: 23 / 255, blue: 26 / 255).opacity(0.92))
                .overlay(
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.white.opacity(0.06)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.6
                    )
                )
                .shadow(color: Color.black.opacity(0.30), radius: 3, x: 0, y: 1.5)
        )
        .fixedSize()
    }
}

// MARK: - Pill Button (`[ Edit ]`) matching Reference Image 2

/// Capsule pill button for primary or contextual action
public struct ToolbarPillButton: View {
    private let title: String
    private let icon: String?
    private let action: () -> Void

    @StateObject private var hover = HoverState()

    public init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(Color.white.opacity(0.92))
            .padding(.horizontal, 13)
            .frame(height: 28)
            .background(
                Capsule()
                    .fill(Color(red: 24 / 255, green: 25 / 255, blue: 28 / 255).opacity(hover.isHovered ? 0.95 : 0.85))
                    .overlay(
                        Capsule().strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(hover.isHovered ? 0.28 : 0.18), Color.white.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.6
                        )
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 2.5, x: 0, y: 1.5)
            )
            .contentShape(Capsule())
            .scaleEffect(hover.isHovered ? 1.02 : 1.0)
            .animation(LiquidGlass.quickSpring, value: hover.isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hover.isHovered = hovering
        }
    }
}
