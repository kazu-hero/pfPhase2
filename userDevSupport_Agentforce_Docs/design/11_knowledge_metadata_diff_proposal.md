# Phase 3.1-2 Knowledge Metadata Diff Proposal

## Purpose
Provide minimal and reversible metadata changes to enable Knowledge-based guidance quality improvements.

## Target Files
- `force-app/main/default/bots/UserDevSupportAgent/v1.botVersion-meta.xml`
- `force-app/main/default/genAiPlugins/p_16jdL000002lnH3_Non_Code_Development_Guidance.genAiPlugin-meta.xml`
- `force-app/main/default/genAiPlugins/p_16jdL000002lnH3_Custom_Object_Setup.genAiPlugin-meta.xml`
- `force-app/main/default/genAiPlugins/p_16jdL000002lnH3_Validation_Rule_Assistance.genAiPlugin-meta.xml`

## Proposed Diffs

### 1) Enable knowledge on BotVersion
Current:
```xml
<knowledgeActionEnabled>false</knowledgeActionEnabled>
<knowledgeFallbackEnabled>false</knowledgeFallbackEnabled>
```

Proposed:
```xml
<knowledgeActionEnabled>true</knowledgeActionEnabled>
<knowledgeFallbackEnabled>true</knowledgeFallbackEnabled>
```

Rationale:
- Keep behavior safe with fallback while knowledge source is being populated.
- Improve answer consistency for guide-type queries.

### 2) Add knowledge-priority instruction to Topic 3
Target: `Non Code Development Guidance`

Proposed instruction (new):
```xml
<genAiPluginInstructions>
    <description>When users ask implementation or setup procedures, first ground your response in approved knowledge guides (G-301, G-302, G-501). If no guide is available, provide a concise fallback and ask a clarifying question.</description>
    <developerName>knowledge_priority</developerName>
    <language xsi:nil="true"/>
    <masterLabel>knowledge_priority</masterLabel>
    <sortOrder>0</sortOrder>
</genAiPluginInstructions>
```

### 3) Add knowledge-priority instruction to Topic 4
Target: `Custom Object Setup`

Proposed instruction (new):
```xml
<genAiPluginInstructions>
    <description>For object/field setup guidance, prioritize approved knowledge guides (G-101, G-201, G-202, G-203, G-401, G-402) before generating free-form guidance.</description>
    <developerName>knowledge_priority</developerName>
    <language xsi:nil="true"/>
    <masterLabel>knowledge_priority</masterLabel>
    <sortOrder>0</sortOrder>
</genAiPluginInstructions>
```

### 4) Add knowledge-priority instruction to Topic 5
Target: `Validation Rule Assistance`

Proposed instruction (new):
```xml
<genAiPluginInstructions>
    <description>For validation rule requests, prioritize approved guide G-601 and provide formula explanations grounded in known patterns.</description>
    <developerName>knowledge_priority</developerName>
    <language xsi:nil="true"/>
    <masterLabel>knowledge_priority</masterLabel>
    <sortOrder>0</sortOrder>
</genAiPluginInstructions>
```

## Test Points (Post-change)
1. Topic 3 answers quote or follow guide steps for layout/record type/flow.
2. Topic 4 answers follow object/field/relationship guides in sequence.
3. Topic 5 answers include validation-rule guidance grounded in guide G-601.
4. If guide is missing, fallback response is still coherent and asks a clarifying question.

## Rollback
- Revert the four target files to previous commit state.

## Notes
- This is a proposal document only. No metadata changes are applied in this step.
