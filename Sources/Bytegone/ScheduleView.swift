import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var schedule: ScheduleStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header.padding(.top, 28)
                StatusCard()
                FrequencyCard()
                CategoriesCard()
                if schedule.lastRun != nil { LastRunCard() }
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 0.30, green: 0.79, blue: 0.78),
                            Color(red: 0.36, green: 0.62, blue: 1.00),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Scheduled Cleanup")
                    .font(.system(size: 22, weight: .bold))
                Text("Run cleanup automatically on a recurring schedule.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - Status card

private struct StatusCard: View {
    @EnvironmentObject var schedule: ScheduleStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill((schedule.config.enabled ? Color.green : Color.secondary).opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: schedule.config.enabled ? "play.fill" : "pause.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(schedule.config.enabled ? .green : .secondary)
                        .symbolEffect(.bounce, value: schedule.config.enabled)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.config.enabled ? "Schedule active" : "Schedule paused")
                        .font(.system(size: 14, weight: .semibold))
                    if schedule.config.enabled, let next = schedule.nextRun {
                        Text("Next run \(next.formatted(.relative(presentation: .named)))")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    } else {
                        Text("Toggle on to enable automatic cleanup")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { schedule.config.enabled },
                    set: { newValue in
                        var c = schedule.config; c.enabled = newValue
                        schedule.updateConfig(c)
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(.green)
            }

            if schedule.config.enabled, let next = schedule.nextRun {
                Divider().opacity(0.25)
                HStack(spacing: 14) {
                    InfoTile(label: "NEXT RUN", value: next.formatted(date: .abbreviated, time: .shortened), icon: "clock")
                    if schedule.isRunning {
                        InfoTile(label: "STATUS", value: "Running…", icon: "hourglass", accent: .blue)
                    }
                    Spacer()
                    Button {
                        schedule.runNow()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                            Text("Run now").font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [
                                        Color(red: 0.30, green: 0.79, blue: 0.78),
                                        Color(red: 0.36, green: 0.62, blue: 1.00),
                                    ],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(schedule.isRunning)
                }
            }
        }
        .padding(20)
        .modifier(PanelStyle(stroke: schedule.config.enabled ? .green.opacity(0.4) : .white.opacity(0.05)))
    }
}

// MARK: - Frequency / time / weekday card

private struct FrequencyCard: View {
    @EnvironmentObject var schedule: ScheduleStore

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = schedule.config.hour
                comps.minute = schedule.config.minute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newValue in
                var c = schedule.config
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                c.hour = comps.hour ?? 3
                c.minute = comps.minute ?? 0
                schedule.updateConfig(c)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Frequency & time", systemImage: "calendar")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.blue)

            HStack(spacing: 12) {
                Picker("Frequency", selection: Binding(
                    get: { schedule.config.frequency },
                    set: { newValue in
                        var c = schedule.config; c.frequency = newValue
                        schedule.updateConfig(c)
                    }
                )) {
                    ForEach(ScheduleFrequency.allCases) { f in
                        Text(f.label).tag(f)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)

                DatePicker("Time", selection: timeBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.field)
                    .frame(width: 100)

                Spacer()
            }

            if schedule.config.frequency == .weekly {
                HStack(spacing: 6) {
                    ForEach(Weekday.allCases) { day in
                        WeekdayChip(
                            day: day,
                            selected: schedule.config.weekday == day.rawValue
                        ) {
                            var c = schedule.config; c.weekday = day.rawValue
                            schedule.updateConfig(c)
                        }
                    }
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .modifier(PanelStyle())
        .animation(Theme.smooth, value: schedule.config.frequency)
    }
}

private struct WeekdayChip: View {
    let day: Weekday
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day.short)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selected ? Color.blue.opacity(0.85) : Color.primary.opacity(0.06))
                )
                .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
    }
}

// MARK: - Categories card

private struct CategoriesCard: View {
    @EnvironmentObject var schedule: ScheduleStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Included categories", systemImage: "checklist")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.purple)
                Spacer()
                Text("\(schedule.config.includedCategories.count) selected")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            ForEach(CategoryGroup.allCases, id: \.self) { group in
                Text(group.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
                    .padding(.top, 4)

                ForEach(CleanupCategory.allCases.filter { $0.group == group }) { cat in
                    CategoryToggleRow(category: cat)
                }
            }
        }
        .padding(20)
        .modifier(PanelStyle())
    }
}

private struct CategoryToggleRow: View {
    let category: CleanupCategory
    @EnvironmentObject var schedule: ScheduleStore
    @State private var hovered = false

    private var on: Bool { schedule.config.includedCategories.contains(category.rawValue) }

    var body: some View {
        Button {
            var c = schedule.config
            if on { c.includedCategories.remove(category.rawValue) }
            else  { c.includedCategories.insert(category.rawValue) }
            schedule.updateConfig(c)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(category.accent.opacity(on ? 0.85 : 0.18))
                        .frame(width: 26, height: 26)
                    Image(systemName: category.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(on ? .white : category.accent)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(category.rawValue).font(.system(size: 13, weight: on ? .semibold : .regular))
                    Text(category.hint).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(on ? category.accent : .secondary.opacity(0.5))
            }
            .padding(.horizontal, 8).padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(hovered ? Color.primary.opacity(0.05) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

// MARK: - Last run card

private struct LastRunCard: View {
    @EnvironmentObject var schedule: ScheduleStore

    var body: some View {
        if let run = schedule.lastRun {
            VStack(alignment: .leading, spacing: 12) {
                Label("Last run", systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.green)

                HStack(spacing: 14) {
                    InfoTile(label: "WHEN", value: run.date.formatted(date: .abbreviated, time: .shortened), icon: "calendar")
                    InfoTile(label: "FREED", value: formatBytes(run.freedBytes), icon: "tray.and.arrow.down.fill", accent: .green)
                    InfoTile(label: "ITEMS", value: "\(run.deletedCount)", icon: "doc.fill")
                    if run.errorCount > 0 {
                        InfoTile(label: "SKIPPED", value: "\(run.errorCount)", icon: "exclamationmark.triangle.fill", accent: .orange)
                    }
                    Spacer()
                }
            }
            .padding(20)
            .modifier(PanelStyle())
        }
    }
}

// MARK: - Helpers

private struct PanelStyle: ViewModifier {
    var stroke: Color = .white.opacity(0.06)

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
    }
}

private struct InfoTile: View {
    let label: String
    let value: String
    let icon: String
    var accent: Color = .secondary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
            }
            .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(accent)
                .monospacedDigit()
        }
    }
}
