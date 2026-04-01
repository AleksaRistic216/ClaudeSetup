# Global Claude Code Instructions

These instructions apply to all projects on this machine.

## Before Starting Work

- Always check if there are docs within the repo (e.g., `docs/`, `README.md`, wiki files) and read relevant ones before starting work on a task.

## Commit Style

- Use present tense ("Add" not "Added")
- Keep commit messages under 50 characters
- Don't add "written by claude code" or similar attribution

## C# Conventions

- One type per file — do not define multiple classes, records, interfaces, enums, or structs in a single file

## Entity Framework Core

- Always use the `dotnet ef` CLI tool to create and update migrations — never write or edit migration files manually

## Stopping Processes

- When asked to stop or kill specific apps (e.g. backend, frontend), only stop those processes — do not kill browsers or other applications that may be using them
