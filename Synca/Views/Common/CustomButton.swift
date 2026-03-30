import SwiftUI

// MARK: - Primary Action Button
struct PrimaryButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color,
                                color.opacity(0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.4), radius: 10, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Icon Button
struct IconButton: View {
    let icon: String
    let label: String
    let color: Color
    let width: CGFloat?
    let action: () -> Void

    init(icon: String, label: String, color: Color, width: CGFloat? = 64, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.color = color
        self.width = width
        self.action = action
    }

    var body: some View {
        let referenceWidth = width ?? 56
        let iconSize: CGFloat = referenceWidth < 50 ? 16 : (referenceWidth < 60 ? 18 : 20)
        let labelSize: CGFloat = referenceWidth < 50 ? 8 : (referenceWidth < 60 ? 9 : 10)
        let buttonHeight: CGFloat = referenceWidth < 50 ? 54 : 56

        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .semibold))
                Text(label)
                    .font(.system(size: labelSize, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(width: width)
            .frame(height: buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(color.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
