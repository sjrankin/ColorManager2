//
//  SetupView.swift
//  ColorManager
//
//  Created by Stuart Rankin on 11/9/26.
//

import SwiftUI

/// The application settings dialog. Changes take effect, and are saved, immediately.
struct SetupView: View
{
    @Environment(\.dismiss) var Dismiss
    @Environment(AppSettings.self) var Settings
    
    var body: some View
    {
        @Bindable var BoundSettings = Settings
        VStack(spacing: 0)
        {
            Text("Setup")
                .font(.title2)
                .padding()
            Divider()
            Form
            {
                Section("Startup")
                {
#if os(macOS)
                    Toggle("Load the last color file when the app starts", isOn: $BoundSettings.LoadLastFileAtStartup)
                    LabeledContent("Last color file")
                    {
                        Text(Settings.LastFileName ?? "None yet")
                            .foregroundStyle(.secondary)
                    }
                    Button("Forget Last File", role: .destructive)
                    {
                        Settings.ForgetLastFile()
                    }
                    .disabled(!Settings.HasLastFile)
#else
                    Text("Loading a color file isn't available on this device yet, so there is no file to reload at startup.")
                        .foregroundStyle(.secondary)
#endif
                }
#if os(macOS)
                Section
                {
                    Text("When this is on, the app loads the last color file you imported instead of the built-in colors. The app keeps its own copy of that file, so changes to the original aren't picked up until you import it again.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
#endif
            }
            .formStyle(.grouped)
            Divider()
            Button("Done")
            {
                Dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .padding()
        }
        .frame(minWidth: 420, minHeight: 320)
    }
}

#Preview
{
    SetupView()
        .environment(AppSettings())
}
