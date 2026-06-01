<div align="center">

# 🎨 The Studio

**A private art inventory & public portfolio manager — built as a birthday gift.**

*Ruby on Rails · PostgreSQL · Hotwire · Tailwind CSS*

---

</div>

## What is this?

The Studio is a full-stack Rails application built as a birthday gift for a fine artist. It gives a working artist everything they need to manage their body of work privately and present it publicly — without paying for Squarespace, fumbling with spreadsheets, or assembling gallery submissions by hand.

## Features

### Private Studio (authenticated)
- **Artwork CRUD** — add, edit, delete paintings with multi-image uploads
- **Status tracking** — `in_progress`, `available`, `sold`, `gifted`, `exhibited`, `archived`
- **Tag system** — tag artworks by medium, genre, technique; filter by `#tag`
- **Search & filter** — search by title, medium, year; filter by status or tag
- **This Day in Your Studio** — surfaces past work painted on today's date each year
- **Letters to Future Me** — private notes attached to individual artworks
- **PDF Catalogue export** — one-click gallery-submission-ready PDF with cover page
- **Analytics dashboard** — status breakdown, works by year, medium distribution, tag cloud
- **Artist profile** — name, statement, contact email, profile photo, cover image

### Public Portfolio (unauthenticated)
Three switchable display modes — toggled with one button, preference saved to `localStorage`:

| Mode | Description |
|------|-------------|
| **Classic** | Dark gallery aesthetic. Masonry grid, hover overlays, filter bar |
| **Raw** | Black & white motion graphics. Bento grid, marquee strips, custom cursor |
| **Exhibition** | Full-screen smooth slider. Cinematic, draggable, keyboard navigable |

- Artist name, statement, and contact info on the portfolio
- Round profile photo + cover image hero background
- Tag and status filtering
- Enquiry email link
- Mobile and iOS optimised across all three modes

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Ruby on Rails 8.1 |
| Database | PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS v4 |
| Auth | Devise |
| File Storage | Active Storage (local dev, S3/Cloudflare R2 in production) |
| Image Processing | image_processing + libvips |
| Pagination | Pagy |
| Search | Ransack |
| PDF Generation | Prawn |
| Deployment | Fly.io / Render |

---

## Architecture

```
app/
├── controllers/
│   ├── artworks_controller.rb     # CRUD + PDF catalogue export
│   ├── portfolio_controller.rb    # Public portfolio (no auth)
│   ├── home_controller.rb         # Dashboard + analytics + credits
│   ├── profile_controller.rb      # Artist profile edit
│   └── studio_notes_controller.rb # Letters to Future Me
├── models/
│   ├── artwork.rb                 # Core model — enum status, tags, slugs
│   ├── tag.rb                     # Tagging system
│   ├── artwork_tag.rb             # Join table
│   ├── artwork_location.rb        # Physical location log
│   ├── studio_note.rb             # Letters to Future Me
│   └── user.rb                    # Devise + avatar + cover_image
├── views/
│   ├── artworks/                  # Admin artwork views
│   ├── portfolio/                 # Public portfolio (Classic/Raw/Exhibition)
│   ├── home/                      # Dashboard, analytics, credits
│   ├── profile/                   # Profile edit
│   └── devise/                    # Styled login/signup (lamp effect)
└── assets/
    └── tailwind/application.css   # Tailwind v4 theme tokens
```

---

## Getting Started

### Prerequisites

- Ruby 3.2+
- Rails 8.1
- PostgreSQL 12+
- libvips (for image processing)

```bash
# macOS
brew install vips

# Ubuntu / WSL
sudo apt install libvips-tools
```

### Setup

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/studio-app.git
cd studio-app

# Install dependencies
bundle install

# Configure database
# Edit config/database.yml with your Postgres credentials

# Create and migrate
rails db:create
rails db:migrate

# Start the server
./bin/dev
```

Visit `http://localhost:3000` and sign up.

### Environment Variables

For production, set these:

```bash
DATABASE_URL=postgres://...
DB_USERNAME=your_db_user
DB_PASSWORD=your_db_password

# Active Storage — S3 or Cloudflare R2
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_BUCKET=...
AWS_REGION=...
```

---

## Seeding Real Artworks

To pre-load the app with paintings before gifting:

1. Place painting images in `db/seeds/images/`
2. Edit `db/seeds.rb` with titles, mediums, and dates
3. Uncomment the image attachment blocks
4. Run `rails db:seed`

---

## Deployment

### Fly.io

```bash
fly launch
fly postgres create
fly secrets set DATABASE_URL=...
fly deploy
```

### Render

Connect your GitHub repo at [render.com](https://render.com), set environment variables, deploy.

### Domain Setup

Both the greeting site and the studio app share one domain:

| App | URL |
|-----|-----|
| Greeting site (App 1) | `hisname.art` |
| Studio app (App 2) | `studio.hisname.art` |

---

## Easter Eggs

This app was built with intention and a comfortable level of teasing.

- `/credits` — a cinematic credit roll. Find it through the footer.
- Empty states across the app contain thinly veiled roasts.
- The `who made this?` footer link leads somewhere worth clicking.

---

## Project Structure

This is **App 2** of a two-part birthday gift:

**App 1 — The Greeting** (`hisname.art`)
A static scroll-driven site telling the story of a friendship — childhood, painting together, the divergence, the gift. Built in plain HTML/CSS/JS. Ends with a button: *"Enter your studio →"*

**App 2 — The Studio** (`studio.hisname.art`)
This app. The actual gift.

---

## Screenshots

> *Coming soon — will be added after the birthday reveal.*

---

## License

Private. Built for one person specifically.

That said — if you're reading this and want to build something similar for someone you care about, take whatever's useful.

---

<div align="center">

Built with love, questionable taste, and way too many commits.

*[who made this?](http://localhost:3000/credits)*

</div># Art-Studio
