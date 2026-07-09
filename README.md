# NULL REMOVER

Windows reserved device names (`nul`, `con`, `prn`, `aux`, `com0–9`, `lpt0–9`) sometimes get created as real files by agents, scripts, or broken tools. Explorer often **cannot delete** them.

**Null Remover** is a single-file Windows tool that scans for these names and deletes them safely using `\\?\` extended paths.

---

## Features

- **Single file** — `Null_Remover.cmd` (launcher + PowerShell logic inside)
- **Menu UI** — scan, selective delete, bulk delete
- **Drag & drop** — drop files/folders onto the `.cmd`
- **Languages** — Turkish (default) / English (switch from menu)
- **Safe deletes** — bulk operations require typing `EVET` / `YES`
- **Full C:\ scan** or custom path (flat / recursive)
- Skips system junk (`$Recycle.Bin`, `WinSxS`, pagefile, reparse points, …)

---

## Requirements

- Windows 10 / 11
- PowerShell 5.1+ (built-in on modern Windows)
- For deep system paths: run as Administrator (optional)

---

## Quick start

1. Download [`Null_Remover.cmd`](./Null_Remover.cmd)
2. Double-click to open the menu  
   *or* drop a file/folder onto `Null_Remover.cmd`
3. Scan → review results → confirm delete

```text
git clone https://github.com/kadiratesdev/nul_file_remover.git
cd nul_file_remover
.\Null_Remover.cmd
```

---

## Menu (overview)

| Key | Action |
|-----|--------|
| **1** | Scan all of `C:\` (then delete options) |
| **2** | Scan a custom path (optional recursive) |
| **3** | Quick delete by full path |
| **4** | About / help |
| **5** | Language — Türkçe / English |
| **0** | Exit |

### After a scan

1. Delete all (confirmed bulk)
2. Selective delete (by index, ranges like `1-4`, or `a` = all)
3. Show list again
4. Save results to `Desktop\nul_scan.txt`
0. Back to main menu

### Confirmations

| Language | Type to confirm |
|----------|-----------------|
| Türkçe   | `EVET` |
| English  | `YES` |

Both words are accepted regardless of the active UI language.

---

## Drag & drop

- Drop a **reserved-name file** onto the tool → tries to delete it
- Drop a **normal folder** → scans that folder (one level) for reserved names and deletes matches

Tip: if Explorer cannot drag a `nul` file, drop the **parent folder** onto the `.cmd`.

---

## How it works

Windows treats names like `nul` as devices. Deleting them needs extended paths:

```text
\\?\C:\path\to\nul
```

The tool:

1. Walks directories with .NET `EnumerateFileSystemEntries`
2. Matches reserved names (including extension variants, e.g. `nul.txt`)
3. Deletes via `cmd` `del` / `rmdir` on the extended path, with .NET fallback

---

## Targets

| Pattern | Examples |
|---------|----------|
| `CON`, `PRN`, `AUX`, `NUL` | `nul`, `con`, `prn` |
| `COM0`–`COM9` | `com1`, `com3.log` |
| `LPT0`–`LPT9` | `lpt1`, `lpt2.bak` |

Matching is case-insensitive.

---

## Safety notes

- Deletes are **permanent** (not Recycle Bin)
- Bulk delete always asks for explicit confirmation
- `C:\` full scan can take several minutes and will skip inaccessible system areas without admin
- Do not run unattended bulk deletes on system roots unless you know what you are doing

---

## Language

Default UI language is **Turkish**.

Main menu → **[5] Dil / Language** → choose Türkçe or English.  
(Session only; restarts default to Turkish.)

---

## Project layout

```text
nul_file_remover/
├── Null_Remover.cmd   # only runtime file you need
└── README.md
```

---

## License

Use freely. No warranty — you are responsible for what you delete.

---

## Türkçe özet

Windows’ta `nul`, `con`, `prn` gibi **aygıt isimleri** bazen gerçek dosya olarak oluşur; Explorer silemez.

Bu araç:

- Tek dosya: `Null_Remover.cmd`
- Menü ile tarama / seçimli veya toplu silme
- Sürükle-bırak desteği
- Dil: **Türkçe (varsayılan)** veya English
- Toplu silmede onay: **`EVET`** (veya `YES`)

Çift tıkla çalıştır veya klasörü `.cmd` üzerine bırak.
