# MCP Project - Conversational AI Flutter Application

## Project Overview

MCP Project is a Flutter-based Web application that provides a conversational AI interface. Users can interact with an AI assistant capable of performing various tasks like calculations, fetching weather information, and performing web searches. The application features a custom-designed proxy server to securely communicate with the Anthropic AI API and manage different backend functionalities through a modular "MCP Server" architecture.

## Key Features

*   **Conversational AI Interface:** Chat-based interaction with an AI assistant.
*   **Modular Tool System (MCP Servers):**
    *   **Calculator:** Perform basic arithmetic operations.
    *   **Weather Service:** Get simulated weather information for a given city.
    *   **Web Search:** Perform simulated web searches.
*   **Secure API Key Management:** A Node.js proxy server handles Anthropic API key, keeping it hidden from the client.
*   **Streaming API Responses:** Efficiently handles streaming data from the Anthropic API for real-time chat updates.
*   **Customizable UI Components:** Includes custom widgets like typing indicators and message bubbles.

## Technologies Used

**Frontend (Flutter Application):**

*   **Language:** Dart
*   **Framework:** Flutter
*   **State Management:** (Specify if you used a particular library e.g., Provider, BLoC, Riverpod, or if it's vanilla setState)
*   **Networking:** `http` / `web_socket_channel` (for communication with the proxy)
*   **Asynchronous Programming:** Futures, async/await
*   **UI Development:** Custom Widgets, Material Design
*   **Dependency Management:** Pub (`pubspec.yaml`)

**Backend (Proxy Server):**

*   **Language:** JavaScript (Node.js)
*   **Framework:** Express.js
*   **API Integration:** `axios` for making HTTP requests to the Anthropic API.
*   **Streaming:** Handling and piping `text/event-stream` responses.
*   **Error Handling:** Robust error handling for API responses, including streamed errors and GZIP decompression.
*   **Security:** CORS configuration, API key abstraction.
*   **Environment Management:** `.env` files for configuration.
*   **Dependency Management:** npm/yarn (`package.json`)

**External Services:**

*   **Anthropic API:** Powering the core conversational AI capabilities.

**Development & Version Control:**

*   **Version Control:** Git & GitHub 
*   **IDE:** Android Studio 

## Architecture Overview

The project follows a client-server architecture:

1.  **Flutter Client:** The mobile application built with Flutter, responsible for the user interface, user input, and displaying responses. It communicates with the local proxy server.
2.  **Node.js Proxy Server:** An Express.js application that acts as a secure intermediary between the Flutter client and the Anthropic API.
    *   It receives requests from the Flutter app.
    *   It securely attaches the Anthropic API key.
    *   It forwards requests to the Anthropic API.
    *   It handles streaming responses and potential errors from Anthropic, processing them before sending them back to the Flutter client.
3.  **MCP Service Layer (Flutter):** A service within the Flutter app (`mcp_service.dart`) manages connections and interactions with different "MCP Servers" (like `calculator_server.dart`, `weather_server.dart`, `web_search_server.dart`). These servers define available tools and their execution logic, allowing for a modular way to extend functionalities.

## Skills Demonstrated

*   **Full-Stack Development:** Experience in both frontend (Flutter/Dart) and backend (Node.js/Express.js) development.
*   **Mobile Application Development:** Proficient in building cross-platform mobile applications using Flutter.
*   **API Design & Integration:**
    *   Integrating with third-party APIs (Anthropic).
    *   Designing and building a proxy API layer for security and abstraction.
    *   Handling various API response types, including JSON and real-time streams.
*   **Asynchronous Programming:** Effectively managing asynchronous operations in both Dart (Futures) and JavaScript (Promises, async/await).
*   **Problem Solving:** Diagnosing and resolving complex issues related to API communication, error handling (e.g., circular JSON structures, streamed GZIP errors), and application logic.
*   **Secure Coding Practices:** Implementing API key abstraction via a proxy server.
*   **Modular Design:** Structuring code into reusable and maintainable components (e.g., Flutter widgets, MCP servers).
*   **Debugging:** Utilizing logs and debugging techniques to identify and fix issues across the stack.
*   **Version Control:** Using Git for source code management.
*   **Modern JavaScript (ES6+):** Utilizing modern JavaScript features in the Node.js backend.

## Setup & Running


**Prerequisites:**

*   Flutter SDK
*   Node.js and npm/yarn
*   An Anthropic API Key

**Backend (Proxy Server):**

1.  Navigate to the project root.
2.  Create a `.env` file with your `ANTHROPIC_API_KEY`.
3.  Run `npm install` (or `yarn install`).
4.  Run `node proxy-server.js`.

**Frontend (Flutter App):**

1.  Navigate to the project root.
2.  Run `flutter pub get`.
3.  Run `flutter run`.

---