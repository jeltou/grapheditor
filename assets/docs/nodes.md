# Nodes

Nodes sind visuelle Bausteine mit eigener Darstellung und (optional) Ausführungslogik.

## Basistypen

### RootNode
Startknoten des Graphen (optisch hervorgehoben). Default label = Name des Graphs.

### DefaultNode
Einfacher Knoten mit `label`.

### EndNode
Stoppt die Ausführung mit `label`.

---

## Logik & Kontrolle

### DecisionNode
Trifft eine Entscheidung anhand von **Branches**:

- Reihenfolge = Priorität (first-match-wins).
- Jede Branch hat `name` und **Regeln** (AND/OR-Gruppenlogik).
- Unterstützte Operatoren: `==`, `!=`, `>`, `>=`, `<`, `<=`, `contains`, `startsWith`, `endsWith`.
- **Ports**: Für jede Branch kann eine `BranchEdge` mit `fromPort = branch.name` gelegt werden.
- Höhe passt sich dynamisch der Branch-Anzahl an.

### ContextNode
Manipuliert den Laufzeit-Context:

- Aktionen: `setValue`, `increment`, `toggleBool`, `removeKey`, `mergeObject`.
- Wird **vor** dem Verlassen des Nodes ausgeführt (`executeBefore`).

### MapperNode
Kopiert/verschiebt Werte innerhalb des Contexts (z. B. `contextdata.xyz → a.c.d`).

- **Regeln** (`rules`):
  - `from` (Quelle, Dot-Pfad)
  - `to` (Ziel, Dot-Pfad)
  - `move` (bool) – Quelle nach dem Schreiben löschen (Move statt Copy)
  - `overwrite` (bool) – vorhandenen Zielwert überschreiben (Default: `true`)
  - `skipIfNull` (bool) – Regel überspringen, wenn Quelle `null` ist (Default: `true`)
- Ausführung: **vor** dem Verlassen (wie ContextNode).
- Darstellung: kompakte Liste aller Regeln, Node-Höhe wächst mit der Anzahl Regeln.


## Berechnung & I/O
### MathNode

Berechnet einen Ausdruck und schreibt das Ergebnis in den Context.
Ausdruck: + - * / %, Klammern (), unäres Minus -x.
Variablen sind Context-Pfade (Dot-Notation), z. B. cart.total, user.age.

Beispiel: subtotal + shipping - discount
Ziel-Pfad: wohin das Resultat geschrieben wird (z. B. cart.grandTotal).
Fehler (z. B. unbekannte Variable) werden als Zahl NaN/null behandelt und nicht geschrieben.

### HttpNode

Führt einen HTTP-Request aus (asynchron) und schreibt Ergebnis/Metadaten in den Context.

Konfiguration (wichtigste Felder):

- method: GET | POST | PUT | PATCH | DELETE
- url: String, unterstützt Template-Platzhalter aus dem Context (z. B. https://api.example.com/users/{{user.id}})
- headers: Map (optional), Werte können templated sein
- query: Map (optional), wird an die URL angehängt
- body: String/Map (optional) – für POST/PUT/PATCH; kann templated sein
- timeoutMs: Zahl (optional)

