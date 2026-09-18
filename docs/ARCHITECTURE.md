# AUREN Architecture

## Layers
- `app/` — product UI and navigation
- `core/` — shared models, configuration and utilities
- `features/` — feature modules
- `services/` — Firebase, AI Gateway and other integrations

## AI Gateway
The application must not couple product code directly to a single model provider. Provider routing, fallback, cost controls and credentials belong behind the gateway.

## Data boundaries
Personal memory, messages and sensitive user data should have explicit access boundaries and auditability.

## First feature modules
- Authentication
- Home / Smart Timeline
- Messenger
- Personal AI
- Action Center
