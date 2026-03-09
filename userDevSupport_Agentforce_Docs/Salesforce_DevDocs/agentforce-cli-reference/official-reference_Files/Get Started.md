# Get Started with Agentforce and AI Agents

# **Get Started with Agentforce and AI Agents**

Agentforce is the agent-driven layer of the Salesforce Platform, and it helps you deploy AI agents that work side-by-side with your employees to extend your workforce and serve customers 24/7. The Trust Layer securely connects your data with the power of large language models (LLMs). This guide provides all the information that you need to develop with Agentforce and generative AI.

## **Develop with Agentforce Agents** 

Bring the power of conversational AI to your business with Agentforce agents. Build a trusted and customizable AI assistant that empowers your users to get more done in Salesforce.

**Overview Guides**

* [Agentforce APIs and SDKs](https://developer.salesforce.com/docs/ai/agentforce/guide/get-started-agents.html): Learn how to use various APIs and SDKs to build powerful Agentforce solutions  
* [Agentforce Actions](https://developer.salesforce.com/docs/ai/agentforce/guide/get-started-actions.html): Learn how to build and enhance your Agentforce actions

**Development Tools**

* [Agent Script](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html): Learn how to use the language for building agents in Agentforce Builder  
* [Agentforce DX](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx.html): Learn how to use pro-code Agentforce tools for Salesforce CLI and VS Code

## **Develop with Models and Prompts** 

The Salesforce Platform provides you with some powerful tools to configure and use large language models (LLMs). You can also use Prompt Builder features to create, manage, and use your prompt templates.

* [Get Started with Models and Prompts](https://developer.salesforce.com/docs/ai/agentforce/guide/models-get-started.html)

## **See Also** 

* *Salesforce Help*: [Agentforce and Generative AI](https://help.salesforce.com/s/articleView?id=ai.generative_ai.htm)  
* *Salesforce Help*: [Agentforce Agents](https://help.salesforce.com/s/articleView?id=ai.copilot_intro.htm)

# Set Up Einstein Generative AI and Agentforce

# **Set Up Einstein Generative AI and Agentforce**

Provision and set up Data 360, enable Einstein Generative AI, set up the Einstein Trust Layer, and set up agents.

**Important**

Before you can set up the Einstein Trust Layer, you must configure Data 360 and enable Einstein Generative AI in your org. Data 360 is required to ensure that the Einstein Trust Layer functions correctly and protects your data.

## **Provision Data 360** 

Before turning on Einstein generative AI features, ensure that Data 360 is provisioned and set up in your org. For information on Data 360 setup, see [Turn on Data 360](https://help.salesforce.com/s/articleView?id=data.c360_a_setup_provision.htm) in Salesforce Help.

## **Turn on Einstein** 

To access Einstein generative AI features in your org, you must turn on Einstein.

* From Setup, in the Quick Find box, enter Einstein Setup and click **Einstein Setup**.  
* Enable **Turn on Einstein**.

## **Configure the Trust Layer** 

Configure the Einstein Trust Layer to align with your organizational privacy and security policies and requirements. For information on Trust Layer settings, see [Set Up Einstein Trust Layer](https://help.salesforce.com/s/articleView?id=ai.generative_ai_trust_setup.htm).

## **Add Agents** 

If you plan to use Agentforce agents, see [Set Up Agents](https://help.salesforce.com/s/articleView?id=ai.copilot_setup.htm) in Salesforce Help.

## **See Also** 

* [Scratch Org Access](https://developer.salesforce.com/docs/ai/agentforce/guide/scratch-org.html)  
* *Salesforce Help*: [Set Up Einstein Generative AI](https://help.salesforce.com/s/articleView?id=ai.generative_ai_enable.htm)

# Scratch Org Access

# **Scratch Org Access**

This guide describes the basic steps for using Salesforce CLI to create a generative AI scratch org for a Developer or Enterprise edition org.

**Note**

A scratch org is a dedicated, configurable, and short-term Salesforce environment that you can quickly spin up when starting a new project, a new feature branch, or a feature test. Scratch orgs are configured using a scratch org definition file, which lists the features and settings that mirror the customer's production org. See [Scratch Orgs](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_scratch_orgs.htm) in the Salesforce DX Developer Guide for detailed information.

* Install [Salesforce CLI](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm) on your computer.  
* Open a terminal (macos, Linux) or command prompt (Windows) and make sure that Salesforce CLI is up to date by running this command.  
* Update CLI

```
sf update
```

*   
  (Optional) [Create a Salesforce DX project](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_create_new.htm) on your computer and change to the directory.  
  If you only want to create a scratch org, then this step isn't necessary. But we recommend creating a DX project if you plan to store your org’s metadata (code and configuration), org templates, sample data, and tests in a version control system. See [Project Setup](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_workspace_setup.htm).  
* Select and enable your Dev Hub org, which must have your Data 360 licenses. See [Select and Enable a Dev Hub Org](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_setup_enable_devhub.htm) in the Salesforce DX Developer Guide for more information.  
* Log in to your Dev Hub org and allow access. In the browser window that opens, sign in to your org with your Salesforce login credentials. Click **Allow**, which allows Salesforce CLI to access to your org.  
* Allow Access

```
sf org login web --set-default-dev-hub --alias DevHub
```

*   
  Create a definition file, such as afdx-scratch-def.json. If you're using a Salesforce DX project, create the file in the config directory alongside the existing config/project-scratch-def.json file.  
  To use an Einstein Generative AI scratch org, add the Einstein1AIPlatform feature, which is supported in Developer and Enterprise editions. To automatically enable Einstein and Agentforce, turn on the agentPlatformSettings.enableAgentPlatform and einsteinGptSettings.enableEinsteinGptPlatform settings.  
* Sample Scratch Org Definition File

```
{
  "orgName": "Agentforce scratch org",
  "edition": "Developer",
  "features": ["EnableSetPasswordInApi","Einstein1AIPlatform"],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "mobileSettings": {
      "enableS1EncryptedStoragePref2": false
    },
    "agentPlatformSettings": {
      "enableAgentPlatform": true
    },
    "einsteinGptSettings" : {
      "enableEinsteinGptPlatform" : true
    }
  }
}
```

*   
  Using the scratch org definition file, create the scratch org.  
* Create Scratch Org

```
sf org create scratch --definition-file config/afdx-scratch-def.json --alias MyScratchOrg --set-default --target-dev-hub DevHub
```

*   
  Open the org.  
* Open Scratch Org

```
sf org open --target-org MyScratchOrg
```

After you open the org, you can use Salesforce generative AI features such as Agentforce, Prompt Builder, Model Builder, and the Models API. To learn more, see [Agentforce and Einstein Generative AI](https://help.salesforce.com/s/articleView?id=ai.generative_ai.htm) in Salesforce Help.

## **See Also** 

* [Set Up Einstein Generative AI and Agentforce](https://developer.salesforce.com/docs/ai/agentforce/guide/org-setup.html)  
* [AgentPlatformSettings Metadata API](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_agentplatformsettings.htm)  
* [EinsteinGptSettings Metadata API](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_einsteingptsettings.htm)

# Trust Layer

# **Trust Layer**

It’s important that your data stays safe while you innovate with new technology, such as large language models (LLMs). The Einstein Trust Layer includes protections for your data and your users when interfacing with LLMs.

* Grounding in CRM data to ensure accuracy  
* Masking of sensitive data, such as social security numbers  
* Toxicity detection on LLM generations  
* Audit trail and feedback  
* Zero data retention agreements with third-party LLM partners

Einstein trust layer

## **Zero Data Retention** 

At Salesforce, trust is our \#1 value. To keep your data secure, Salesforce has agreements in place with LLM providers, such as OpenAI. These agreements include commitments for zero data retention, allowing you to use generative AI capabilities without worrying about your private data being retained by third-party LLM providers.

## **Trusted Generative AI** 

Salesforce’s Einstein generative AI solutions are designed, developed, and delivered based on our five principles for trusted generative AI.

* **Accuracy**: We back up model responses with explanations and sources whenever possible. We recommend that a human check each model response before sharing them with end users for the majority of use cases.  
* **Safety**: We work to detect and mitigate bias, toxicity, and harmful responses from models used in our products through industry-leading detection and mitigation techniques.  
* **Transparency**: We ensure that our models and features respect data provenance and are grounded in your data whenever possible.  
* **Empowerment**: We believe our products should augment people’s capabilities and make them more efficient and purposeful in their work.  
* **Sustainability**: We strive towards building right-sized models that prioritize accuracy and reducing our carbon footprint.

## **Reviewing Generative AI Outputs** 

Generative AI is a tool that helps you be more creative, productive, and make smarter business decisions. This technology isn’t a replacement for human judgment. You’re ultimately responsible for any LLM-generated response you share with your customers. Whether text is human- or LLM-generated, your customers associate it with your organization’s brand and use it to make decisions. So it’s important to make sure that LLM-generated responses intended for external audiences are accurate and helpful, and that they and align with your company’s values, voice, and tone.

When your end users review generated responses for external audiences, focus on the accuracy and safety of the content.

* **Accuracy**: Generative AI can sometimes “hallucinate”—fabricate responses that aren’t grounded in fact or existing sources. Before you publish a response, check to make sure that key details are correct. For example, is the customer service suggestion based on an existing and up-to-date knowledge article?  
* **Bias and Toxicity**: Because AI is created by humans and trained on data created by humans, it can also contain bias against historically marginalized groups. Rarely, some responses can contain harmful language. Check your responses to make sure they’re appropriate for your customers.

If the response doesn’t meet your standards or your company’s business needs, you don’t have to use it. Some solutions allow end users to edit the response directly, and if not, it’s best to start over and generate another response.

## **Next Steps** 

* Review our [Einstein Trust Layer](https://help.salesforce.com/s/articleView?id=ai.generative_ai_trust_layer.htm) documentation in Salesforce Help.  
* Understand [Toxicity Confidence Scoring](https://developer.salesforce.com/docs/ai/agentforce/guide/models-api-toxicity-scoring.html) with the Models API.  
* Understand [Data Masking](https://developer.salesforce.com/docs/ai/agentforce/guide/models-api-data-masking.html) with the Models API.

## **See Also** 

* *Salesforce Research*: [Trusted AI](https://www.salesforceairesearch.com/trusted-ai)

