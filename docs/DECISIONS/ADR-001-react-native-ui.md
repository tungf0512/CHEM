# ADR-001: React Native owns the product UI

- Status: accepted
- Context: The older product plan includes SwiftUI language, while this task explicitly corrects the app-layer technology and asks for a bare React Native implementation translated from the HTML/CSS design references.
- Decision: Build the iPhone product interface in React Native + TypeScript and launch into the Camera screen. HTML remains design input only.
- Consequences: UI state and controls remain portable; native camera integration is an explicit typed boundary. HTML assets and the earlier product documents are preserved and unchanged. This ADR does not authorize implementing other product screens in this milestone.
