# 🎾 Administrator’s Guide: Player Quota & Season Analytics

> **Purpose**: This guide explains how to interpret and act on metrics in the **Player Quota & Season Analytics** dashboard. It covers quota fulfillment, linear vs. projected pacing, the difference between match deficits and sub Karma, and recommended administrative workflows.

---

### 1. Reading the Top KPI Summary Cards

| Card | What it Measures | Target Benchmark |
| :--- | :--- | :--- |
| **Quota Delivery Health** | % of contracted members currently projected to receive 100% of their purchased matches. | **100%**. Indicates every paid share is scheduled. |
| **Quota Deficit Alert** | Number of players currently projected to finish *below* their contracted share. | **0**. Any number $> 0$ requires admin review. |
| **Total Substitutions** | Total court slots exchanged via the Sub Board across the season. | Measures overall seasonal turnover and sub board activity. |
| **Pending Karma Favors** | Active sub requests where the applicant is returning or owed a favor. | Prioritize approving these candidates first. |

---

### 2. Decoding the Season Quota Status Badges

The **Season Quota Pace** column evaluates a player's **total season inventory** against their contract:

* 🟢 **On Track (100%)**: The player's confirmed schedule across the 24-week season matches their exact share commitment (e.g., 24 of 24 matches).
* 🔴 **$-N$ Deficit**: The player is projected to finish $N$ matches short of what they paid for (e.g., they subbed out of a slot that is still unclaimed, or gave away more matches than they picked up).
* 🟣 **+$N$ Surplus**: The player has picked up additional open sub slots beyond their contracted quota.
* ⚪ **Sub Pool**: Non-contract / waitlist players (`0S / 0D`) who have subbed or currently have a sub claim in flight. Inactive 0-share members who have never subbed and have no in-flight claims are automatically excluded from the report to keep the roster focused.

> **💡 Understanding the Progress Subtitle (e.g., "3 played • 21 upcoming")**:
> Players who have blackouts or rest weeks early in the season are **not penalized**. As long as their 24-week schedule contains all of their matches, they remain **🟢 On Track**, and the subtitle shows their exact path to completion.

---

### 3. Column-by-Column Breakdown of the Admin Player Grid

| Column | What It Displays | How It Is Calculated & What to Look For |
| :--- | :--- | :--- |
| **Contract** | `[singles]S / [doubles]D`<br>`[target] matches` | **Purchased Season Allocation**. Based on the player's contracted shares over 24 weeks (`singles_share * 24` + `doubles_share * 24`). Example: `0.38S / 0.13D` = 12 total matches (9 singles, 3 doubles). |
| **Singles (Act/Tgt)** | `[scheduled] / [target]`<br>+ blue progress bar | **Confirmed Singles vs. Contract**. Counts confirmed singles slots currently on their calendar compared to target singles matches. |
| **Doubles (Act/Tgt)** | `[scheduled] / [target]`<br>+ green progress bar | **Confirmed Doubles vs. Contract**. Counts confirmed doubles slots currently on their calendar compared to target doubles matches. |
| **Season Quota Pace** | Status Badge<br>`X played • Y upcoming` | **Inventory Fulfillment Status**. Evaluates full 24-week confirmed inventory against contract (`🟢 On Track`, `🔴 -N Deficit`, `🟣 +N Surplus`, `⚪ Sub Pool`). The subtitle shows how many games are in the book vs. scheduled in future weeks. |
| **Proj. Total** | `[scheduled] ([variance])`<br>(e.g. `11 (-1)` or `24 (0)`) | **Season-Long Match Total**. Total confirmed matches across both formats. The bracketed number shows net deviation from contract (`-1` = 1 match short, `0` = exactly on contract, `+1` = 1 bonus match). |
| **Subs (Out/In)** | `X out, Y in`<br>`Net: ±Z` | **Sub Board Turnover & Match Flow**.<br>• **Out**: Matches the player gave away or listed on the Sub Board.<br>• **In**: Matches where the player stepped in to sub for someone else.<br>• **Net**: Direct net change to their personal calendar (`In - Out`). |
| **Karma Ledger** | `Even (0)` / `+N Favors Owed`<br>`-N Favors Due`<br>+ `⭐ N Owed Pending` | **Social Favor Balance**.<br>• **+N Favors Owed**: The player has subbed for peers more times than peers have subbed for them.<br>• **-N Favors Due**: The player owes peers return favors.<br>• **⭐ Badge**: Active sub request where the applicant is returning/owed a favor. |
| **Idle Streak** | `N wks`<br>(e.g. `2 wks`) | **Maximum Scheduling Gap**. The longest consecutive stretch of season weeks with **0 scheduled matches**. Highlighted in amber if $\ge 3$ consecutive weeks to alert admins to long player droughts. |

---

### 4. Sub Turnover vs. Sub Karma (The Crucial Difference)

* **Inventory Deficit vs. Social Karma**:
  * **Quota Deficit** answers: *"Did the player lose a match on their personal calendar?"*
  * **Sub Karma** answers: *"Does this player owe another person a return favor?"*

* **Why a Player Can Show a -1 Deficit but Owe No One**:
  * If a player gives away a slot on the Sub Board, **they don't owe anyone**; they simply relinquished one of their games.
  * If they traded 1-for-1 with another member (e.g. Kyle Zola), their Karma balance is **Even (0)**.
  * If their second sub-out was claimed by a 0-share waitlist sub (who has no contract matches to trade back) or is **still sitting open on the Sub Board**, nobody owes them a match.

---

### 5. Using the Expanded Player Drawer

Click any player row to inspect their 3-column deep-dive inspection drawer:

1. **Active Scheduled Matches**: Chronological calendar of all confirmed matches (completed vs. upcoming), including court numbers and format.
2. **Sub Exchange Log**:
   * **Subbed Out**: Displays the exact date/court and shows whether the slot was **`Claimed by [Name]`** or is **`⏳ Unclaimed — listed on Sub Board`**.
   * **Subbed In**: Displays the exact date/court and who the player filled in for.
3. **Bilateral Karma Ledger**: Head-to-head favor tally (e.g., *“Owes me 1 match”* or *“Even”*).
4. **Opponent Variety & Blackout Constraints**: Count of unique opponents faced, blackout percentage, and exact blackout days and weeks.

---

### 6. Administrator Action Playbook

| Scenario | Recommended Action |
| :--- | :--- |
| **Player has a $-1$ Deficit** | Click the **`In Deficit`** filter. Expand their row and check the **Sub Exchange Log**. If their sub-out is **`⏳ Unclaimed`**, assign an eligible candidate. If it was already played, offer them an open sub slot to make up their missed match. |
| **Multiple Candidates Request a Slot** | Check for applicants flagged with **`⭐ Owed Match`**. Both manual approvals and the 24h Auto-Draft engine prioritize players owed a favor first. |
| **High Absenteeism (>25% Sub Out)** | Click the **`High Turnover`** filter. Identify players who frequently give away matches to discuss reducing their share size for the next contract season. |
| **Board / League Audit** | Click **`Export PDF`** to generate a formatted landscape executive report with KPI summaries, or **`Export CSV`** for custom spreadsheets.
| **Print Cheat Sheet** | Click **`Admin Guide`** in the top toolbar and select **`Print / Save PDF`** for a clean, printable 1-page reference.

