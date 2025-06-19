# macOS Startup Security Scanner

This script performs a security audit of your macOS system by analyzing applications, agents, and daemons that are configured to run automatically at startup. It is designed to help you identify suspicious or unsigned software that might have been placed on your system.

## Key Features

-   **Apple Gatekeeper Integration:** The script does not rely on static lists or manual definitions to verify software. Instead, it uses macOS's built-in security mechanism, Gatekeeper (`spctl`), to get the most accurate and trustworthy verification.
-   **Comprehensive Scanning:** It scans the following critical startup locations:
    -   `/Library/LaunchAgents` (System-wide agents for all users)
    -   `/Library/LaunchDaemons` (System-wide daemons for all users)
    -   `~/Library/LaunchAgents` (Agents specific to the current user)
    -   **User Login Items** (Startup applications defined in System Settings)
-   **Intelligent Analysis:** It intelligently interprets the results from Gatekeeper, distinguishing between standard applications, command-line helper tools, and non-application files like sockets to minimize false positives.
-   **Clear & Readable Output:** The results are presented with clear icons (`✅`, `🤔`) to indicate the status of each item, making the report easy to understand at a glance.

## How It Works

The script reads the `.plist` files located in the specified system folders. From these files, it extracts the path to the executable program that is set to run at startup. It then sends this program path to Apple Gatekeeper via the `spctl --assess` command. By interpreting Gatekeeper's response, it reports the security status of each piece of software.

## Installation and Usage

1.  Save the script to your computer as `security.sh`.
2.  Open your Terminal application and navigate to the directory where you saved the script.
3.  Make the script executable with the following command:
    ```sh
    chmod +x security.sh
    ```
4.  Run the script:
    ```sh
    ./security.sh
    ```

## Understanding the Output

Each line in the script's output describes the status of a startup item. Here is what the symbols mean:

-   `✅ Gatekeeper Approved`: This indicates that a standard `.app` application has been recognized and approved by Gatekeeper. This is the most common and secure status.
    > Example: `✅ Gatekeeper Approved: Developer ID Application: Google LLC ...`

-   `✅ Signed Helper Tool`: This indicates that the file is not a full application (`.app`) but is a command-line utility or helper tool signed by a valid developer. These files are often background components of larger applications and are considered safe.
    > Example: `✅ Signed Helper Tool: Developer ID Application: Valve Corporation ...`

-   `🤔 INFO`: This indicates that the script encountered a non-application file, such as a socket, pipe, or script. These files cannot be signed or assessed by Gatekeeper by their nature. This is not a security risk and is considered normal behavior.
    > Example: `🤔 INFO: Path is a non-executable type (e.g., socket). This is expected. ...`

-   `🚨 WARNING`: This indicates a **rare** situation where Gatekeeper has rejected a file for a serious reason, such as an invalid or broken signature. If you see this warning in your output, investigating the corresponding file is recommended.
