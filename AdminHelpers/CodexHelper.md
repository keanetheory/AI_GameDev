# Using Codex + Obsidian as a Simple Game Dev Memory System

Think of it like this:

**Codex = your programmer.**  
**Obsidian = your notebook.**  
**The `.md` files inside your Obsidian vault = pages in that notebook.**

The person in the screenshot has told Codex:

> Whenever you work on my game, also update this particular notebook page with what you did, what changed, and what still needs doing

That means when they come back tomorrow, Codex can read the dev log instead of having to reconstruct everything from scratch.

## What this could look like for Brusskania

On your PC you might have your game here:

```text
C:\GameDev\Brusskania\
```

And an Obsidian vault here:

```text
C:\Users\Paul\Documents\Obsidian\Brusskania\
```

Inside the vault you might create:

```text
Dev Log.md
Game Vision.md
Lighthouse Opening.md
Characters.md
World.md
```

`Dev Log.md` could contain something as simple as:

```markdown
# Brusskania Dev Log

## 22 September 2026

### Worked on
- Lighthouse boat movement
- Wave timing mechanic
- Assistant torch guidance

### Decisions
- Large waves push the boat backwards
- Small waves provide forward momentum
- Assistant can highlight the safest route

### Still to do
- Prototype wave spawning
- Add rowing animation
- Test how forgiving the mechanic feels
```

Obsidian isn't doing anything clever here. It is literally just displaying that Markdown file nicely.

The clever bit is getting **Codex to update it automatically**.

## Use `AGENTS.md` as Codex's standing instructions

Inside:

```text
C:\GameDev\Brusskania\
```

create:

```text
AGENTS.md
```

and put something like this inside:

```markdown
# Brusskania development instructions

## Development log

After completing a meaningful development task, update:

C:\Users\Paul\Documents\Obsidian\Brusskania\Dev Log.md

Add:

- today's date
- what was changed
- important design or technical decisions
- files changed
- anything that still needs doing
- any bugs or unresolved questions

Keep previous entries. Never overwrite the existing development history.
```

Now Codex has standing instructions saying:

**â€œWhen I work on Brusskania, keep my diary updated too.â€**

## The easiest setup

For Brusskania, I would actually make this even simpler at first.

Put the documentation **inside your Brusskania project**:

```text
Brusskania
â”‚
â”œâ”€â”€ AGENTS.md
â”‚
â”œâ”€â”€ Source
â”œâ”€â”€ Content
â”‚
â””â”€â”€ docs
    â”œâ”€â”€ Dev Log.md
    â”œâ”€â”€ Game Vision.md
    â”œâ”€â”€ Lighthouse Opening.md
    â”œâ”€â”€ World.md
    â””â”€â”€ Technical Notes.md
```

Then tell Obsidian to open either `Brusskania` itself or the `docs` folder as a vault.

Now Codex and Obsidian are looking at **the exact same files**.

That gives you this little loop:

**You â†’ Codex:**  
> Build the first prototype of the rowing mechanic.

**Codex â†’ game:**  
Changes the code.

**Codex â†’ `Dev Log.md`:**  
Writes down what it changed.

**Tomorrow you â†’ Codex:**  
> Let's continue the rowing mechanic.

**Codex:**  
Reads the project, `AGENTS.md`, and the documentation and has a much better idea where you left off.

That's what the Discord message means by **â€œso it doesn't need to retread old ground constantly.â€**

## A better long-term structure

Rather than having **one gigantic dev log**, I'd give Codex a small set of permanent Brusskania documents:

```text
docs/
    GAME_VISION.md
    GAME_DESIGN.md
    WORLD.md
    CHARACTERS.md
    TECHNICAL.md
    DEV_LOG.md
    TODO.md
```

Then `AGENTS.md` effectively says:

> Read these before doing significant work.  
> Update whichever ones your work affects.  
> Record completed work in DEV_LOG.  
> Record outstanding tasks in TODO.

That starts turning the project into a kind of **external memory for Codex**.

## The mental model

For Brusskania, the simplest way to think about it is:

**`AGENTS.md` = Codex's instructions**  
**`docs/` = Codex's memory**  
**Obsidian = the nice interface *you* use to read and edit that memory**  
**your game files = the thing Codex is actually building**

You therefore don't really need to â€œconnect Codex to Obsidianâ€ at all.

You just arrange things so **Codex and Obsidian can both see the same Markdown files**.

If you're about to start actually building Brusskania with Codex, this is worth setting up right at the beginning rather than retrofitting it later.