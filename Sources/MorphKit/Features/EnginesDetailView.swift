import SwiftUI
import AppKit

@MainActor
public final class EnginesViewModel: ObservableObject {
    public static let shared = EnginesViewModel()

    @Published public var engines: [EngineInfo] = []
    @Published public var isLoading: Bool = false
    @Published public var copiedEngineId: String? = nil

    public init() {
        Task {
            await refresh()
        }
    }

    public func refresh() async {
        isLoading = true
        engines = await EngineManager.shared.allEngines()
        isLoading = false
    }
}

public struct EnginesDetailView: View {
    @ObservedObject public var model: EnginesViewModel

    public init(model: EnginesViewModel = EnginesViewModel.shared) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header Description Card
            VStack(alignment: .leading, spacing: 6) {
                Text("Conversion Engines & Modular Tools")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)

                Text("Morph uses native Apple frameworks for zero-download offline conversions, and automatically connects to modular tools (FFmpeg, LibreOffice, Pandoc) when installed on your Mac.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.70))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    }
            )

            if model.isLoading && model.engines.isEmpty {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text("Scanning system for conversion tools...")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.vertical, 16)
            } else {
                // Section 1: Built-in Native Engines
                VStack(alignment: .leading, spacing: 10) {
                    Text("BUILT-IN NATIVE ENGINES (100% OFFLINE)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.50))

                    ForEach(model.engines.filter { $0.isNative }) { engine in
                        engineRow(engine)
                    }
                }

                // Section 2: External Modular Engines
                VStack(alignment: .leading, spacing: 10) {
                    Text("EXTERNAL MODULAR TOOLS (FILEE ENGINE ARCHITECTURE)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.50))
                        .padding(.top, 8)

                    ForEach(model.engines.filter { !$0.isNative }) { engine in
                        engineRow(engine)
                    }
                }
            }
        }
        .task {
            await model.refresh()
        }
    }

    private func engineRow(_ engine: EngineInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(engine.isAvailable ? Color.green.opacity(0.16) : Color.white.opacity(0.06))
                        .frame(width: 36, height: 36)

                    Image(systemName: iconForEngine(engine))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(engine.isAvailable ? Color.green : Color.white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(engine.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white)

                        // Status Badge
                        if engine.isNative {
                            statusBadge(text: "Built-in", color: .cyan)
                        } else if engine.isAvailable {
                            statusBadge(text: "Installed", color: .green)
                        } else {
                            statusBadge(text: "Not Installed", color: .orange)
                        }
                    }

                    Text(engine.description)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.65))

                    if let path = engine.path {
                        Text(path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.40))
                            .lineLimit(1)
                    }

                    if let ver = engine.version, !ver.isEmpty {
                        Text(ver.prefix(60))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Copy Homebrew command if missing
                if let cmd = engine.installCommand, !engine.isAvailable {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(cmd, forType: .string)
                        model.copiedEngineId = engine.id
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if model.copiedEngineId == engine.id {
                                model.copiedEngineId = nil
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: model.copiedEngineId == engine.id ? "checkmark" : "doc.on.doc")
                            Text(model.copiedEngineId == engine.id ? "Copied" : "Copy Install")
                        }
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                        .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                }
        )
    }

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.20)))
            .foregroundStyle(color)
    }

    private func iconForEngine(_ engine: EngineInfo) -> String {
        switch engine.id {
        case "engine.vision": return "text.viewfinder"
        case "engine.imageio": return "photo"
        case "engine.pdfkit": return "doc.richtext"
        case "engine.iconutil": return "app.dashed"
        case "engine.data": return "curlybraces"
        case "engine.coreimage": return "qrcode"
        case "engine.ffmpeg": return "play.rectangle.fill"
        case "engine.libreoffice": return "doc.text.fill"
        case "engine.pandoc": return "doc.badge.gearshape"
        case "engine.exiftool": return "info.circle"
        case "engine.whisper": return "waveform"
        default: return "cpu"
        }
    }
}
