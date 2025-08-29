# Nodes

Nodes sind visuelle Bausteine mit eigener Darstellung und (optional) Ausführungslogik.

## Basistypen

### RootNode

Startknoten des Graphen (optisch hervorgehoben). Default label = Name des Graphs

### DefaultNode

Einfacher Knoten mit `label`.

### EndNode

Stoppt die Ausführung mit `label`.

### DecisionNode

Trifft eine Entscheidung anhand von **Branches**:

- Reihenfolge = Priorität (first-match-wins).
- Jede Branch hat `name` und **Regeln** (AND/OR Gruppenlogik).
- Unterstützte Operatoren: `==`, `!=`, `>`, `>=`, `<`, `<=`, `contains`, `startsWith`, `endsWith`.
- **Ports**: Für jede Branch kann eine `BranchEdge` mit `fromPort = branch.name` gelegt werden.
- Höhe passt sich dynamisch der Branch-Anzahl an.

### ContextNode

Manipuliert den Laufzeit-Context:

- Aktionen: `setValue`, `increment`, `toggleBool`, `removeKey`, `mergeObject`.
- Wird **vor** dem Verlassen des Nodes ausgeführt (executeBefore).

### MathNode

Berechnet einen Ausdruck und schreibt das Ergebnis ins Laufzeit-Context

- Ausdruck  `+ - * / %`, `()`, **unäres Minus** `-x`.
- Variablen sind **Context-Pfade** (dot-notation), z. B. `cart.total`, `user.age`.
- Beispiel:  
  `subtotal + shipping - discount`
- Ziel-Pfad: wohin das Resultat geschrieben wird (z. B. `cart.grandTotal`).

