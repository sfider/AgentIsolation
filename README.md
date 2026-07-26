# Introduction

This repository contains instructions and resources for setting up a more secure environment for running llm agents on a Windows Home desktop.

The idea is that a llm agent should have reasonably limited priviliges on the system it's running on. An agent might have, better or worse, built-in security measures, including things like:

- read/write/run permissions,
- sandboxing.

However, as these are often governed by the process running the agent, they can be disabled from within the process:
- by the user by mistake,
- by the agent in some cases.

Setting a more secure OS level environment adds an additional layer of protection that the agent or its process should have no influence on.

# Contents

## GENERAL_SETUP.md

- This is the initial, agent agnostic, setup.
- There are four levels to the setup.
- Even using only the first level will give you an additonal layer of protection.

> [!NOTE]
> The setup should be agent agnostic, but it was developed and tested for Claude Code

## CLAUDE_SETUP.md

- This is an additional setup for Claude Code agent.

## claude/

- Folder with sample `settings.json` and hooks
