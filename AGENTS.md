# Repository Agent Guide

## What This Repo Is

`cardano-rdf` owns generic Cardano RDF vocabulary, graph extraction,
serialisation, packaged views, and export tooling. Transaction RDF is the
first surface, but the repository is intentionally broader than transaction
graphs.

## How To Work Here

- Read `.specify/memory/constitution.md` before planning or editing.
- Use Spec Kit for feature work: specify, plan, tasks, then implement.
- Use `just` recipes for local work once the Haskell/Nix scaffold exists.
- Do not delete old `cardano-tx-tools` source during migration unless the user
  explicitly approves a separate deletion plan.
- Do not populate secrets from an agent session. Leave exact `gh secret set`
  commands for the operator instead.

## Skills

Activatable procedures live under `skills/` when present. Load the one whose
description matches your task.

## First-Run Setup

No operator-specific local config is required for the repository bootstrap.
Networked fetchers or hosted services may add a first-run skill later.
