# Graph Runtime

Mit der **Graph Runtime** kannst du deinen Graphen interaktiv gegen ein frei wählbares **Context-JSON** ausführen, das Ergebnis inspizieren und die Schritte im **stdout** mitlesen. Ideal zum Testen, Debuggen und Dokumentieren deines Flows.

---

## Aufbau des Dialogs

- **Saved tests**  
  Verwaltet gespeicherte Test-Kontexte:
  - **Select test**: Gespeicherten Test auswählen
  - **Load**: Lädt den ausgewählten Test in das Context-JSON
  - **Save as…**: Aktuelles Context-JSON als neuen Test speichern
  - **Overwrite**: Überschreibt den ausgewählten Test mit dem aktuellen Context-JSON
  - **Delete**: Entfernt den ausgewählten Test
- **Runtime options**
  - **Max steps**: Obergrenze an Schritten, bevor der Lauf abgebrochen wird (Schutz gegen Endlosschleifen).
  - **Allow revisit**: Erlaubt das erneute Besuchen desselben Nodes (deaktivieren = Zyklen werden erkannt und gestoppt).
- **Context JSON**  
  Linkes Editor-Pane. Hier definierst du den Start-Context (Root muss ein JSON-Objekt sein).
  - **Format**: Beautified JSON
  - **Clear**: Editor leeren
- **Result JSON**  
  Rechtes Editor-Pane. Zeigt das Ergebnis des Laufs, inklusive Stop-Grund, Statistik und finalem Context.
- **stdout**  
  Protokoll der Ausführung in Echtzeit (Nodes, Edges, Hinweise). Auto-Scrolling, zeilenbegrenzt zur Performance.

---

## Schnellstart

1. Öffne den **Graph Runtime**-Dialog.
2. Wähle einen gespeicherten Test **oder** editiere das **Context JSON**.
3. Setze bei Bedarf **Max steps** und **Allow revisit**.
4. Klicke **Run**.  
   - Während der Laufzeit kannst du mit **Stop** abbrechen.
5. Sieh dir **Result JSON** (rechts) und **stdout** (unten) an.

---

## Context JSON

Der Context ist ein freies JSON-Objekt, auf das Nodes zugreifen (z. B. `user.age`, `flags.isNew`).  
Beispiel:

```json
{
  "user": { "id": "42", "age": 19, "country": "DE" },
  "flags": { "isNew": true },
  "value": 1
}
```

**Hinweise**
- Root muss ein Objekt sein (`{ ... }`), keine Liste oder ein Skalar.
- Nutze **Format**, um ungültiges/unschönes JSON aufzuräumen.

---

## Result JSON – Felder

Beispielausgabe (gekürzt):

```json
{
  "reason": "reachedEndNode",
  "message": "Reached EndNode",
  "lastNodeId": "N123",
  "stepsTaken": 7,
  "executionTime": 2,
  "context": { "...": "finaler Kontext nach allen Mutationen" }
}
```

- **reason**: Stop-Grund (siehe Tabelle unten)
- **message**: Zusatzinfo
- **lastNodeId**: ID des zuletzt ausgeführten Nodes
- **stepsTaken**: Anzahl der Schritte
- **executionTime**: Laufzeit in Millisekunden
- **context**: Finale Context-Daten nach Abschluss der Ausführung

> Optional können (je nach Einstellung/Performance) auch **visitedNodes** und **traversedEdges** ausgegeben werden.

---

## Stop-Gründe

| Reason              | Bedeutung                                                                 |
|---------------------|---------------------------------------------------------------------------|
| `reachedEndNode`    | Ein `EndNode` wurde erreicht.                                             |
| `noOutgoingEdge`    | Vom aktuellen Node führt keine passende Kante weiter.                     |
| `cycleDetected`     | Zyklus erkannt (nur wenn **Allow revisit** ausgeschaltet ist).            |
| `startNodeNotFound` | Startknoten existiert nicht.                                              |
| `userCancelled`     | Der Lauf wurde vom Benutzer abgebrochen (Stop).                           |
| `maxStepsExceeded`  | **Max steps** erreicht – Schutz vor Endlosschleifen.                      |

---

## Wie Branches funktionieren

- **BranchEdge** verbindet einen Node über einen **Port-Namen** (z. B. Branch-Name „yes“, „no“, „>=18“).
---

## Context-Mutationen

- Das **Result JSON** enthält immer den **finalen** Context nach Abschluss des Laufs.

---

## Tipps & Troubleshooting

- **`Invalid JSON` im Context**  
  Mit **Format** bereinigen, oder Syntax prüfen (fehlende Klammern/Kommas/Anführungszeichen).
- **`noOutgoingEdge`**  
  Häufigster Grund: Decision/Branch ohne passende `BranchEdge` (Port-Name stimmt nicht) oder es fehlt eine Default-Kante.
---

## Best Practices

- **Kleine, lesbare Branch-Namen** verwenden (z. B. `yes`/`no`, `valid`/`invalid`).
- **DecisionNode**: Regeln möglichst klar formulieren; bei Mehrfach-Branches Reihenfolge beachten (first-match-wins).
- **Endknoten** setzen, um klare Terminationspunkte zu haben.
- **Tests** für typische und Edge-Cases anlegen – erspart später viel Zeit.
- **Max steps** als „Airbag“ beibehalten, besonders in frühen Entwurfsphasen.

---

