# Getting started

Ein Graph besteht aus **Nodes** (Knoten) und **Edges** (Kanten). Du erstellst Knoten über den Node-Dialog, verbindest sie per Drag von Ports (kleine runde Handles) und führst den Graphen im **Runtime-Dialog** aus.

## Canvas Basics

- **Pan & Zoom**: mit Maus ziehen / Trackpad; Zoom per Mausrad (optional Strg).
- **Node hinzufügen**: Rechtsklick → *Add node here* (öffnet den Node-Dialog).
- **Node verschieben**: Node ziehen.
- **Verbinden**: An einem Port (Top/Right/Bottom/Left) ziehen → auf Zielnode loslassen.
- **Bearbeiten**: Node doppelklicken → Formular öffnet sich (Create/Edit ist zusammengeführt).
- **Löschen**
    - Node: im NodeWrapper (Hover) auf "X"
    - Edge: Edge anklicken → auf "X"

## Node-Dialog

- **Type** auswählen (z. B. *Decision Node*, *Context Node*, *Math Node*).
- Formularfelder je Typ (z. B. Branches/Regeln für Decision).
- Speichern → Node erscheint an der gewünschten Position.

## Edges

- **DefaultEdge**: normaler Fluss.
- **BranchEdge**: benannter Port (z. B. „yes“, „age>=18“). Der Name wird am Edge gerendert.

## Runtime

- Menü: *Graph* → Ausführen -> Runtime-Dialog.
- **Context JSON** links eingeben oder gespeicherte Tests laden.
- **Result JSON** rechts zeigt Ergebnis, Pfad, Steps, Context.
- **stdout** unten protokolliert die Traversal-Schritte.
- Optionen: *Max steps*, *Allow revisit*, Cancel-Button für lange Läufe.
