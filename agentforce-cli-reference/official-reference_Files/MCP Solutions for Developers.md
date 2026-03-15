# MCP Solutions for Developers

# **MCP Solutions for Developers**

Salesforce offers [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) solutions that developers can use to access Salesforce features and services through AI applications.

## **Background** 

Building custom integrations between AI applications and enterprise platforms typically requires significant development effort for each use case. [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) eliminates this complexity by providing an open standard that lets AI applications securely interact with external systems and services through pre-built connections. Instead of building custom integrations, developers can use these ready-made MCP servers to instantly connect their AI applications to Salesforce, Heroku, and MuleSoft features and services.

Here's how you interact with MCP-enabled AI solutions:

* From your AI application, ask questions or request actions related to the connected service  
* The AI application connects to the appropriate MCP server  
* The MCP server securely processes the request on the target platform  
* Data or action results return to the AI application  
* The AI application displays information or confirms completed actions

This approach transforms development by providing immediate access to enterprise data and services without the need to learn platform-specific APIs, CLIs, or authentication flows. To learn more, review this Salesforce developers blog post: [Introducing MCP Support Across Salesforce](https://developer.salesforce.com/blogs/2025/06/introducing-mcp-support-across-salesforce).

Although MCP solutions are applicable to many types of AI users, this page contains information about how developers can take advantage of MCP solutions at Salesforce.

## **Salesforce Solutions** 

The following Salesforce MCP solutions are available for developers.

| Platform | MCP Solution | Description | Sample Prompt |
| :---- | :---- | :---- | :---- |
| Heroku | [Heroku MCP Server](https://github.com/heroku/heroku-mcp-server) | Facilitates seamless interaction between LLMs and the Heroku Platform. | *List all my Heroku apps associated with the AwesomeSauce team*  *Deploy the HerokuRules project* |
| MuleSoft | [Anypoint Connector for MCP](https://docs.mulesoft.com/mcp-connector/latest/) | Connects LLM applications with your APIs using MCP Connector. | *Get a list of all approved vendors, including their product categories*  *Create a purchase order for 100 units of widgets* |
| MuleSoft | [MuleSoft MCP Server](https://docs.mulesoft.com/mulesoft-mcp-server/) | Facilitates interaction between LLMs and the MuleSoft Anypoint Platform. | *Create a Mule project that creates an order in NetSuite every time an opportunity in Salesforce is updated to stage Closed Won.*  *Deploy Mule application in current project with high security, high availability, and performance optimized settings* |
| Salesforce | [Salesforce DX MCP Server](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_mcp.htm) (Beta) | Use natural language to issue complex commands to your Salesforce orgs without writing code or queries. | *Query my DreamHouse org and show me info about my properties*  *Run agent tests in my org* |
| Salesforce | [Agentforce Vibes Extension](https://developer.salesforce.com/docs/platform/einstein-for-devs/guide/devagent-overview.html) MCP Client | Use the Salesforce DX MCP Server (Beta) from inside the Agentforce Vibes MCP client. | *Query my DreamHouse org and show me info about my properties*  *Run agent tests in my org* |
| Salesforce | [Salesforce Hosted MCP Servers](https://help.salesforce.com/s/articleView?id=platform.hosted_mcp_servers.htm&type=5) (Beta) | Enable AI assistants to securely access your Salesforce data and help with daily business tasks. | *Look at the Account object in my Salesforce org and tell me which fields are required to create an Account*  *Get all accounts from my Salesforce org that have annual revenue over 1 billion dollars* |

## **See Also** 

* *Salesforce Developers Blog*: [Introducing MCP Support Across Salesforce](https://developer.salesforce.com/blogs/2025/06/introducing-mcp-support-across-salesforce)  
* *YouTube*: [Agentforce AMA: Supercharge Development with MCP](https://www.youtube.com/watch?v=tOTC-2ygJBM)

# Agentforce Vibes Extension

# **Agentforce Vibes Extension**

The [Agentforce Vibes extension](https://developer.salesforce.com/docs/platform/einstein-for-devs/guide/einstein-overview.html) is an AI-powered developer tool that's available as an easy-to-install Visual Studio Code extension. The extension is available in the [VS Code](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-einstein-gpt) and [Open VSX](https://open-vsx.org/extension/salesforce/salesforcedx-einstein-gpt) marketplaces as a part of the [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode), [Salesforce Extension Pack (Expanded)](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode-expanded), and in the Agentforce Vibes IDE.

Agentforce Vibes

To learn more, see the [Agentforce Vibes Extension Developer Guide](https://developer.salesforce.com/docs/platform/einstein-for-devs/guide/einstein-overview.html).

