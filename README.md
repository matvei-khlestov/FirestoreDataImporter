# FirestoreDataImporter

**FirestoreDataImporter** is a demo iOS application and infrastructure module designed to import structured **JSON seed data** into **Firebase Firestore** in a safe, deterministic, and production-ready way.

The project focuses on **clean architecture**, **SOLID-driven refactoring**, and a **predictable import pipeline** with dry-run support, checksum validation, and retry logic. The solution is suitable both for debug tooling and real-world administrative utilities.

<p align="center">
  <img
    width="1025"
    height="2004"
    alt="FirebaseImporter_Mockup"
    src="https://github.com/user-attachments/assets/8545a7b1-2ab4-4048-b186-662d8c93967f"
  />
</p>

## Overview

The project demonstrates how to build a robust Firestore seed data importer that:

- reads JSON files bundled with the application
- compares them against existing Firestore documents
- computes diffs (create / update / skip / delete)
- performs a **dry-run** before applying changes
- executes batched writes with retry and backoff mechanisms
- tracks import state using checksums and versioning

The architecture is intentionally split into small, well-defined components to avoid “god services” and to keep each responsibility isolated and testable.

## Core Functionality

- Importing seed JSON data into Firebase Firestore  
- Support for multiple collections (brands, categories, products)  
- Dry-run mode with a detailed diff report:
  - willCreate
  - willUpdate
  - willSkip
  - willDelete  
- Checksum-based change detection per section  
- Optional pruning of missing documents  
- Batched writes with retry and exponential backoff  
- Import markers and versioning stored locally  
- Debug UI for manual import control:
  - enable / disable importer
  - overwrite existing documents
  - bump seed version
  - reset import markers  
- Real-time import logs streamed directly to the UI  

## Architecture

- UIKit — lightweight debug UI  
- MVVM — View ↔ ViewModel separation  
- Clear orchestration layer (`FirestoreImporter`)  
- Service layer decomposed by responsibility:
  - JSON loading
  - checksum calculation
  - dry-run diff building
  - batch execution  
- Protocol-oriented design for all core abstractions  
- Dependency injection via `FactoryKit.Container`  
- No Firestore logic inside ViewModels  
- No UI logic inside services  

## Import Pipeline

1. Load seed JSON files from the app Bundle  
2. Compute SHA-256 checksums for each section  
3. Compare with stored checksums  
4. Build a dry-run report based on the current Firestore state  
5. Decide whether an import is required  
6. Execute batched upserts and deletions  
7. Persist new checksums and the seed version  

Each step is isolated into its own component and can be independently tested or replaced.

## Tech Stack

- Swift 5.9+  
- UIKit — debug UI  
- Swift Concurrency (async / await)  
- Firebase Firestore  
- FirebaseCore  
- FactoryKit — dependency injection  
- Protocol-Oriented Design  
- MVVM  
- SOLID principles  
- JSONDecoder — seed data parsing  
- SHA-256 — checksum calculation  
- Xcode + iOS Simulator  

## Project Goals

This project is **intentionally not** a generic Firestore admin panel.  
Its goal is to demonstrate:

- how to structure non-trivial infrastructure code
- how to refactor a large service into SOLID-compliant components
- how to build deterministic data import logic
- how to avoid tight coupling between UI, services, and storage
- how to design debug tooling that can evolve into production-ready solutions

## Disclaimer

This project is a demo and educational example.

It is not intended to replace Firebase Admin SDKs or production back-office tools, but rather to demonstrate **clean architecture approaches** to data import, migration, and debugging workflows in iOS applications.
