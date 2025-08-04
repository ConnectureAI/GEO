Ollama MCP Server: Full Installation & Integration Guide
Welcome! This guide will walk you through the complete process of creating, installing, and running a persistent Ollama Model Context Protocol (MCP) Server. This server will act as a bridge, allowing your Google Gemini CLI to leverage your local Ollama models for a powerful, hybrid AI workflow.

With 32GB of RAM, your system is perfectly suited to run and switch between a variety of powerful local models.

Part 1: Understanding the Architecture
Before we begin, let's visualize what we are building:

Ollama: Runs on your machine, managing and serving local LLMs (e.g., llama3, codellama).

Ollama MCP Server (This Project): A small Python server we will create. It runs locally, listens for requests, and communicates with both Ollama and the Gemini CLI.

Gemini CLI: Your command-line interface to Google's powerful models. We will configure it to be aware of our local MCP server.

The Workflow:

You give a command to the Gemini CLI.

Gemini decides if it needs a local model's help.

If so, it calls a "tool" on your local MCP Server.

Your MCP server tells Ollama to run the prompt on the specified local model.

The result is sent back to Gemini, which uses it to complete your request.

Part 2: Development & Setup
Let's build and configure the server.

Step 2.1: Install Prerequisites
First, we need to ensure all the necessary software is installed. Open your terminal and run these commands to check.

# Check for Python (should be 3.8+).
python3 --version

# Check for Ollama. If not installed, get it from https://ollama.com
ollama --version

# Check for Gemini CLI. If not installed, get it from its official GitHub page.
gemini --version

If you are missing any of these, please install them before proceeding.

Step 2.2: Set Up the Project Directory & Environment
Organization is key. Let's create a dedicated folder and a Python virtual environment.

# Create and navigate into a project folder
mkdir ~/ollama-mcp-server
cd ~/ollama-mcp-server

# Create a Python virtual environment
python3 -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Now, install the required Python libraries
pip install Flask ollama google-generativeai python-dotenv

Explanation: We've created an isolated Python environment. This prevents conflicts with other projects and keeps our dependencies clean. You will need to source venv/bin/activate every time you open a new terminal to work on this project.

Step 2.3: Create the MCP Server Python Script
This is the core of our project. Create a file named ollama_mcp_server.py and paste the following code into it. The code is heavily commented to explain what each part does.

# ollama_mcp_server.py

import os
from flask import Flask, request, jsonify
import ollama
from dotenv import load_dotenv

# --- Initialization ---
# This sets up our Flask web server.
app = Flask(__name__)
print("Ollama MCP Server: Initializing...")

# --- Helper Functions ---

def get_local_ollama_models():
    """
    This function communicates with the Ollama application to get a list
    of all the language models you have downloaded on your machine.
    It's used to dynamically tell Gemini what "tools" are available.
    """
    print("Checking for locally installed Ollama models...")
    try:
        models = [model['name'] for model in ollama.list()['models']]
        print(f"Found models: {models}")
        return models
    except Exception as e:
        print(f"Error: Could not connect to Ollama. Is it running? Details: {e}")
        return []

# --- Core MCP Endpoints ---
# The Gemini CLI will communicate with our server using these endpoints.

@app.route('/tools', methods=['GET'])
def get_tools():
    """
    This is the "discovery" endpoint.
    When Gemini CLI starts, it will call this to ask, "What can you do?".
    We will dynamically generate a list of tools based on your local models.
    """
    print("Gemini CLI is asking for available tools...")
    local_models = get_local_ollama_models()
    tools = []
    for model_name in local_models:
        # We create a user-friendly tool name from the model name.
        # e.g., "llama3:8b" becomes "use_llama3_8b"
        tool_name = "use_" + model_name.replace(":", "_").replace("-", "_")
        tools.append({
            "name": tool_name,
            "description": f"Runs a prompt on the locally hosted '{model_name}' model. Ideal for fast, private, or specialized tasks.",
            "parameters": {
                "type": "object",
                "properties": {
                    "prompt": {
                        "type": "string",
                        "description": "The prompt to send to the local Ollama model."
                    }
                },
                "required": ["prompt"]
            }
        })
    print(f"Reporting {len(tools)} tools to Gemini.")
    return jsonify(tools)

@app.route('/run_tool', methods=['POST'])
def run_tool():
    """
    This is the "execution" endpoint.
    Gemini calls this when it wants to use one of our local model tools.
    """
    data = request.json
    tool_name = data.get('tool_name')
    params = data.get('params', {})
    prompt = params.get('prompt')

    print(f"\nReceived request from Gemini to run tool: '{tool_name}'")

    if not tool_name or not prompt:
        return jsonify({"error": "Request is missing 'tool_name' or 'prompt'"}), 400

    # Convert the tool name back into an Ollama-compatible model name.
    # e.g., "use_llama3_8b" becomes "llama3:8b"
    model_name_parts = tool_name.replace("use_", "").split("_")
    model_name = model_name_parts[0]
    if len(model_name_parts) > 1:
        model_name += ":" + "_".join(model_name_parts[1:])

    try:
        print(f"Instructing Ollama to use model: '{model_name}'...")
        # This is where we interact with Ollama.
        response = ollama.chat(
            model=model_name,
            messages=[{'role': 'user', 'content': prompt}]
        )
        result = response['message']['content']
        print("Successfully received response from local model. Sending back to Gemini.")
        return jsonify({"result": result})

    except Exception as e:
        # This handles errors, like if a model doesn't exist.
        error_message = str(e)
        print(f"Error during Ollama operation: {error_message}")
        return jsonify({"error": error_message}), 500

if __name__ == '__main__':
    # This makes the server run when you execute `python3 ollama_mcp_server.py`
    print("Starting Flask server on http://localhost:5001")
    # We use port 5001. You can change this if needed.
    app.run(port=5001, debug=False)

Step 2.4: Integrate with Gemini CLI
Now, we tell the Gemini CLI how to find and use our server.

Find your Gemini settings file. It's located in your home directory at ~/.gemini/settings.json.

Edit the file. Open it in a text editor and add the mcpServers configuration. If the file is empty, you can paste the entire block. If it already has content, just add the "mcpServers" key.

{
  "mcpServers": {
    "ollama_local_server": {
      "command": "/path/to/your/ollama-mcp-server/venv/bin/python3",
      "args": ["/path/to/your/ollama-mcp-server/ollama_mcp_server.py"],
      "probes": {
        "liveness": {
          "httpGet": {
            "path": "/tools",
            "port": 5001
          }
        }
      }
    }
  }
}

IMPORTANT: You must replace /path/to/your/ollama-mcp-server/ with the actual, absolute path to the project directory you created in Step 2.2.

Explanation:

command: We point directly to the Python executable inside our virtual environment. This is crucial.

args: We tell it which script to run.

probes: The Gemini CLI uses this to check if our server is alive and responding before it tries to use it.

Step 2.5: First Run & Test
Let's test it!

Make sure your main Ollama application is running.

Open a new terminal and activate the virtual environment: cd ~/ollama-mcp-server && source venv/bin/activate.

Run the server directly to see its output: python3 ollama_mcp_server.py. You should see messages that it's starting.

Open a separate, new terminal and run gemini.

Inside the Gemini CLI, type /mcp list. You should see ollama_local_server listed as a connected server.

Now, try using a local model! (Assuming you have llama3 pulled in Ollama).

> Use the use_llama3 tool to write a short, funny poem about a software developer and a bug.

You should see the output from your local Llama 3 model directly in the Gemini interface!

Part 3: Making the Server Persistent (Always Running)
You want the server to always be available without you having to start it manually. We can do this by creating a system service. The method depends on your operating system.

(Note: This is an advanced step. Choose the section for your OS.)

<details>
<summary><strong>For macOS (using launchd)</strong></summary>

Create a file named com.user.ollama_mcp_server.plist in ~/Library/LaunchAgents/.

Paste the following content into the file, making sure to replace the paths with your actual paths.

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.ollama_mcp_server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/your/ollama-mcp-server/venv/bin/python3</string>
        <string>/path/to/your/ollama-mcp-server/ollama_mcp_server.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/ollama_mcp_server.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/ollama_mcp_server.err</string>
</dict>
</plist>

Load and start the service:

launchctl load ~/Library/LaunchAgents/com.user.ollama_mcp_server.plist
launchctl start com.user.ollama_mcp_server

This service will now start automatically every time you log in.

</details>

<details>
<summary><strong>For Linux (using systemd)</strong></summary>

Create a file named ollama_mcp.service in ~/.config/systemd/user/.

Paste the following content, replacing the paths and your username.

[Unit]
Description=Ollama MCP Server

[Service]
ExecStart=/path/to/your/ollama-mcp-server/venv/bin/python3 /path/to/your/ollama-mcp-server/ollama_mcp_server.py
Restart=always
User=your_username

[Install]
WantedBy=default.target

Enable and start the service:

systemctl --user enable ollama_mcp.service
systemctl --user start ollama_mcp.service

This service will now start automatically.

</details>

<details>
<summary><strong>For Windows (using Task Scheduler)</strong></summary>

Create a .bat file (e.g., start_ollama_mcp.bat) with the command:

@echo off
C:\path\to\your\ollama-mcp-server\venv\Scripts\python.exe C:\path\to\your\ollama-mcp-server\ollama_mcp_server.py

Replace the paths with your actual Windows paths.

Open Task Scheduler.

Click Create Basic Task....

Give it a name like "Ollama MCP Server".

Set the trigger to "When I log on".

Set the action to "Start a program".

For the program/script, browse to the start_ollama_mcp.bat file you just created.

Finish the wizard. The server will now run automatically when you log in.

</details>

Part 4: Innovative Ways to Use Your Hybrid System
Now for the fun part! With this setup, you can orchestrate complex tasks between local and cloud models.

1. The "Draft & Refine" Coding Workflow
Goal: Quickly generate boilerplate code locally, then have Gemini perfect it.

Prompt:

> Use the use_codellama_7b tool to generate a Python class for a basic Redis cache manager. Then, review the generated code, add type hinting, comprehensive docstrings, and include error handling for connection failures.

Why it's innovative: You get the speed of local generation for the bulk of the code, saving API costs and time. Gemini then applies its superior understanding of best practices, libraries, and documentation standards—a task it excels at.

2. The "Local Brainstorm, Cloud Research" Content Workflow
Goal: Generate a wide range of creative ideas locally, then use Gemini's web search to validate and expand on the best one.

Prompt:

> Use the use_llama3_8b tool to brainstorm 10 catchy, one-sentence slogans for a new brand of eco-friendly coffee. After you have the list, pick the top slogan and use your web search tool to see if any other brands are using similar phrasing.

Why it's innovative: Local models are excellent for divergent, creative thinking without censorship or guardrails. Once you have the raw ideas, Gemini can perform the convergent task of research and analysis using its built-in tools.

3. The "Data Summary and Visualization Plan" Workflow
Goal: Quickly summarize a local data file and then create a strategic plan for visualizing it.

Prompt (after using /path to point Gemini to your project):

> Use the use_mistral tool to read the attached CSV file (@sales_data.csv) and provide a three-sentence summary of its contents. Then, based on the column names, suggest three different types of charts that would be effective for visualizing this data in a business report and explain why.

Why it's innovative: You keep your potentially sensitive data entirely local for the initial summary. Then, you leverage Gemini's analytical and presentation skills to plan the next steps, without it needing to process the raw data itself.

4. The "Learning and Explanation" Workflow
Goal: Get a fast, concise definition from a local model, then ask Gemini for a deep, analogical explanation.

Prompt:

> First, use the use_llama3_8b tool to define "quantum entanglement" in a single sentence. Then, explain it to me like I'm a 12-year-old, using an analogy involving a pair of magic coins.

Why it's innovative: This creates a layered learning experience. You get the quick, factual definition instantly from your local model, followed by the nuanced, high-quality explanation that frontier models like Gemini are known for.

Enjoy your new, powerful, and private hybrid AI development environment!