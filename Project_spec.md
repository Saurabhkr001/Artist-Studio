# Studio — Project Specification & Developer Reference

Last updated: August 2026
Stack: Ruby on Rails 8.1, PostgreSQL, Hotwire (Turbo + Stimulus), Tailwind CSS, Propshaft
Purpose: A private studio management app for visual artists. Owners manage artworks privately;
         a public portfolio page is shareable via a unique URL with no login required.

---

## Table of Contents

 1. Project Overview
 2. Technology Stack
 3. System Architecture
 4. Database Schema
 5. Authentication & Authorization
 6. Feature Reference
    6.1  Dashboard (Home)
    6.2  Artwork Management (CRUD)
    6.3  Tagging System
    6.4  Studio Notes - Letters to Future Me
    6.5  Artwork Detail - View on Wall
    6.6  Artwork Detail - Image Lightbox
    6.7  PDF Catalogue Export
    6.8  Analytics Dashboard
    6.9  Profile Management
    6.10 Public Portfolio Page (3 Modes)
    6.11 Portfolio Share Link (user_hash)
 7. Routing Map
 8. Key Implementation Details
 9. File Structure Reference
10. Environment & Dependencies
11. Migration History
12. Known Gotchas & Notes

---

## 1. Project Overview

This is a single-artist studio management system. Each registered user is an artist who can:

- Upload and manage paintings/artworks privately
- Attach tags, studio notes, dimensions, medium, status, and location history to each piece
- Generate a downloadable PDF catalogue of their public artworks
- Share their portfolio publicly via a unique, opaque URL (no login required for viewers)
- Preview how a painting looks on a wall: drag it around, resize it, switch wall backgrounds,
  or upload a photo of their own room

The app is multi-user at the database level (each artist registers their own account),
but each user only ever sees and manages their own artworks.

---

## 2. Technology Stack

Layer               | Technology
--------------------|------------------------------------------------------------
Framework           | Ruby on Rails 8.1
Database            | PostgreSQL
Authentication      | Devise (database_authenticatable, registerable, recoverable,
                    |   rememberable, validatable, timeoutable)
Asset Pipeline      | Propshaft
CSS                 | Tailwind CSS (tailwindcss-rails) + custom vanilla CSS per view
JavaScript          | Hotwire (Turbo + Stimulus) + vanilla JS (inline in views)
File Uploads        | Active Storage (local disk in dev, configurable for S3 in prod)
Pagination          | Pagy ~9.0
Search/Filter       | Ransack
PDF Generation      | Prawn + prawn-table + prawn-svg
Web Server          | Puma
Deployment          | Kamal (Docker-based)
Background Jobs     | Solid Queue
Caching             | Solid Cache
Fonts               | Google Fonts: Cormorant Garamond, DM Mono, Barlow Condensed, Space Grotesk

---

## 3. System Architecture

                     +-----------------------+
                     |   Browser / Client    |
                     | Hotwire Turbo + JS    |
                     +-----------+-----------+
                                 | HTTP / Turbo Streams
                     +-----------v-----------+
                     |  Puma (Rails 8.1)     |
                     |                       |
                     |  Controllers:         |
                     |  - HomeController     |
                     |  - ArtworksController |
                     |  - StudioNotesCtrl    |
                     |  - PortfolioController|
                     |  - ProfileController  |
                     |                       |
                     |  Models:              |
                     |  - User               |
                     |  - Artwork            |
                     |  - Tag / ArtworkTag   |
                     |  - StudioNote         |
                     |  - ArtworkLocation    |
                     +-----------+-----------+
                                 |
                     +-----------v-----------+
                     |  PostgreSQL Database   |
                     |  users, artworks,      |
                     |  tags, artwork_tags,   |
                     |  studio_notes,         |
                     |  artwork_locations,    |
                     |  active_storage_*      |
                     +-----------+-----------+
                                 |
                     +-----------v-----------+
                     |  Active Storage        |
                     |  Artwork images         |
                     |  User avatar            |
                     |  User cover_image       |
                     +-----------------------+

Request flow - private pages:
  Browser -> Puma -> Router -> authenticate_user! -> Controller -> Model -> DB -> View -> Browser

Request flow - public portfolio:
  Browser -> GET /:user_hash/portfolio
          -> PortfolioController#public_index
          -> User.find_by(user_hash: params[:user_hash])
          -> loads only is_public artworks
          -> renders portfolio/index.html.erb   (NO auth required)

---

## 4. Database Schema

=== users ===

Column                  | Type     | Notes
------------------------|----------|--------------------------------------------------
id                      | bigint   | Primary key
email                   | string   | Unique, not null - Devise login credential
encrypted_password      | string   | Devise bcrypt hash
name                    | string   | Display name (optional, falls back to email prefix)
artist_statement        | text     | Shown on portfolio About section
contact_email           | string   | Shown as "Enquire" mailto link on portfolio nav
achievements            | text     | Newline-separated list, parsed by achievements_list
user_hash               | string   | UNIQUE, not null - 10-char alphanumeric ID
                        |          | Used as the portfolio share URL key
reset_password_token    | string   | Devise
reset_password_sent_at  | datetime | Devise
remember_created_at     | datetime | Devise
created_at / updated_at | datetime |

user_hash details:
  Generated on before_create in User model.
  Samples randomly from [a-z A-Z 0-9] (62 chars), joins 10 characters, loops until unique.
  62^10 = ~839 trillion combinations - collision probability is negligible.
  MUST NOT be regenerated after creation as it breaks shared links.

=== artworks ===

Column                  | Type     | Notes
------------------------|----------|--------------------------------------------------
id                      | bigint   | Primary key
user_id                 | bigint   | Foreign key -> users
title                   | string   | Not null
slug                    | string   | Unique, auto-generated from title via before_validation
medium                  | string   | e.g. "Oil on canvas"
dimensions_cm           | string   | e.g. "60x80"
year_created            | integer  |
painted_on              | date     | Exact date painted
description             | text     | Artist notes
status                  | integer  | Enum: in_progress(0), available(1), sold(2),
                        |          |        gifted(3), exhibited(4), archived(5)
is_public               | boolean  | Default false. Controls portfolio visibility.
created_at / updated_at | datetime |

=== tags ===
  id, name (unique, normalized to lowercase-hyphenated)

=== artwork_tags ===
  Join table: artwork_id + tag_id (many-to-many between artworks and tags)

=== studio_notes ===

Column      | Type     | Notes
------------|----------|------------------------------------------
id          | bigint   | Primary key
artwork_id  | bigint   | Foreign key -> artworks
body        | text     | The journal entry content
written_on  | date     | Auto-set to Date.today on create

=== artwork_locations ===

Column        | Type     | Notes
--------------|----------|------------------------------------------
id            | bigint   | Primary key
artwork_id    | bigint   | Foreign key -> artworks
location_name | string   |
moved_on      | date     |
notes         | text     |

=== Active Storage tables ===
  active_storage_attachments, active_storage_blobs, active_storage_variant_records
  Rails-managed. Used for artwork images, user avatar, user cover_image.

---

## 5. Authentication & Authorization

- Gem: Devise
- Modules: database_authenticatable, registerable, recoverable, rememberable,
           validatable, timeoutable
- before_action :authenticate_user! is set in each individual controller (NOT globally
  in ApplicationController) so portfolio routes can remain public.
- Portfolio routes have NO authentication check. User is looked up by user_hash only.
- Every private data query is scoped to current_user.artworks.
  Users can NEVER read another user's artworks through controller actions.
- Sessions time out after inactivity. Duration: config.timeout_in in devise.rb initializer.

---

## 6. Feature Reference

=== 6.1 Dashboard (Home) ===

Route:  GET /  ->  HomeController#index   (auth required)
Files:  app/controllers/home_controller.rb
        app/views/home/index.html.erb

What it shows:
  - Recent artworks (last 6, ordered by created_at desc)
  - "This Day in Studio": artworks whose painted_on month+day matches today (any year)
  - Summary counts: total, available, sold, in_progress

this_day_in_studio scope (uses PostgreSQL EXTRACT):
  where(
    "EXTRACT(month FROM painted_on) = ? AND EXTRACT(day FROM painted_on) = ?",
    Date.today.month, Date.today.day
  )


=== 6.2 Artwork Management (CRUD) ===

Routes:     resources :artworks, param: :slug
Controller: app/controllers/artworks_controller.rb
Auth:       Required for all actions

SLUG GENERATION
  Runs in: before_validation :generate_slug, on: :create
  Logic:
    base = title.parameterize            # e.g. "sunset-over-the-hills"
    Loops, appending -1, -2 etc. until the candidate slug is unique.
  Slugs are NEVER regenerated after creation so URLs remain stable.

IMAGE UPLOADS
  has_many_attached :images  (Active Storage, multiple images per artwork)
  Validation: at least one image required on create
  First image = primary display; remaining = thumbnails below it
  Stored via Active Storage (local disk in dev)

STATUS ENUM
  enum :status, {
    in_progress: 0, available: 1, sold: 2,
    gifted: 3, exhibited: 4, archived: 5
  }

FILTERING & SEARCH
  Ransack: full-text search on title, medium, year_created, description, status
  Status filter: params[:status]
  Tag filter:    params[:tag] with .joins(:tags).where(tags: { name: params[:tag] })
  Pagination:    Pagy, 12 per page

IS_PUBLIC FLAG
  Artworks default to is_public: false.
  Only is_public: true artworks appear on the public portfolio.
  Toggled via checkbox in the edit form.


=== 6.3 Tagging System ===

Files: app/models/tag.rb, app/models/artwork_tag.rb

Tags are global at the DB level (shared between all users) but always queried
scoped to a specific user's artworks via joins.

Tag name normalization (before_save in Tag model):
  self.name = name.downcase.strip.gsub(/\s+/, "-").gsub(/[^a-z0-9\-]/, "")
  So "Oil Painting" -> "oil-painting"

Tags saved via ArtworksController#save_tags:
  Reads params[:tag_list] (comma-separated string)
  Splits, normalizes, calls Tag.find_or_create_by for each
  Sets artwork.tags = [array of Tag objects]

Portfolio nav: live client-side tag search dropdown.
  All tags are pre-rendered in the DOM as <a> links.
  Vanilla JS filters the list by input value.
  No extra server request needed for filtering.
  Clicking a tag navigates to portfolio_path(tag: name) for server-side filtering.


=== 6.4 Studio Notes - "Letters to Future Me" ===

Route:  POST /artworks/:artwork_slug/letters  ->  StudioNotesController#create
        DELETE /letters/:id                   ->  StudioNotesController#destroy
Auth:   Required. Notes are NEVER shown on the public portfolio.

Each artwork can have multiple private journal entries.
written_on is auto-set to Date.today on create.
Notes displayed newest-first on the artwork show page.
Delete uses Turbo: data: { turbo_method: :delete, turbo_confirm: "..." }


=== 6.5 Artwork Detail - View on Wall ===

File:  app/views/artworks/show.html.erb
Type:  100% client-side - zero server involvement after page load

A full-screen <dialog> modal that composites the painting over a wall background image.
Opened via document.getElementById('wall-preview-modal').showModal()

-- Drag to reposition --
  Mouse: mousedown event -> tracks clientX/Y delta -> updates CSS transform: translate(...)
  Touch: touchstart / touchmove / touchend events
  State vars: frameOffsetX, frameOffsetY (px offsets from center of container)

-- Resize --
  Controls: range slider (min=20, max=180, step=5) + minus/plus buttons
  State var: paintingScale (float, clamped between 0.2 and 1.8)
  Applied via: transform: translate(calc(-50% + Xpx), calc(-50% + Ypx)) scale(paintingScale)
  Slider gradient, percentage label, and transform kept in sync by setPaintingScale()
  Reset button: returns frameOffsetX/Y to 0 AND paintingScale to 1.0

-- Wall switcher --
  2 preset wall background images: wall_img1.png and wall_img2.png
  Shown as small thumbnail buttons in the controls row
  Active wall highlighted with gold border (border-color: #c4933f)
  Switching: updates src of <img id="wall-bg-img">

-- Upload your own wall photo --
  HTML: <input type="file" accept="image/*"> wrapped in a styled <label>
  On file selection: URL.createObjectURL(file) creates a temporary in-memory blob URL
  The blob URL is set as the src of the wall background image
  The file is NEVER sent to the server. It exists only in browser tab memory.
  Input value is reset after selection so the same file can be re-selected.


=== 6.6 Artwork Detail - Image Lightbox ===

File: app/views/artworks/show.html.erb

A native HTML <dialog> element used as a full-screen image lightbox.
  Open:  openArtworkLightbox(url) -> sets img src -> calls dialog.showModal()
  Close: clicking backdrop (e.target === dialog element)
         OR clicking the x button (submits <form method="dialog"> inside dialog)


=== 6.7 PDF Catalogue Export ===

Route:  GET /artworks/catalogue  ->  ArtworksController#catalogue   (auth required)
Gems:   Prawn, prawn-table, prawn-svg

Generates and streams a downloadable A4 PDF of ALL public artworks.

PDF Layout:
  Cover page:
    "STUDIO CATALOGUE" header, gold divider line, year and artwork count

  Per artwork page:
    Detects image orientation using Active Storage blob metadata (width, height fields)

    Portrait layout (width <= height):
      Image on left  (52% of page width)
      Metadata in right column bounding box

    Landscape layout (width > height):
      Image full-width across top (55% of page height)
      Two-column metadata below

    Fallback (if image fails to download):
      Dark filled rectangle placeholder

    Page number at bottom-right: "n / total"

  Metadata shown: Medium, Year, Dimensions (cm), Status, Date painted, Description

Delivery:
  send_data pdf.render,
    filename: "studio_catalogue_#{Date.today.year}.pdf",
    type: "application/pdf",
    disposition: "attachment"


=== 6.8 Analytics Dashboard ===

Route:  GET /analytics  ->  HomeController#analytics   (auth required)
File:   app/views/home/analytics.html.erb

All queries scoped to current_user.artworks:
  - Total artworks count
  - Public artworks count
  - Status breakdown (each status value and its count)
  - Artworks by year:      group(:year_created).count
  - Top 6 mediums:         group(:medium).count.sort_by { |_, v| -v }.first(6)
  - Top 8 tags:            Tag.joins(:artworks)...group("tags.name").count.sort_by...first(8)
  - "This Day in Studio" count


=== 6.9 Profile Management ===

Routes:  GET  /profile/edit  ->  profile#edit    (auth required)
         PATCH /profile      ->  profile#update

Editable fields:
  name              - Display name (falls back to email prefix if blank)
  artist_statement  - Shown in portfolio About section
  contact_email     - Shown as "Enquire" mailto link in portfolio nav
  achievements      - Newline-separated, split by achievements_list method for display
  avatar            - Profile photo (Active Storage, has_one_attached)
  cover_image       - Portfolio hero background (Active Storage, has_one_attached)

Image removal:
  Separate remove_avatar and remove_cover_image boolean params in the form.
  Controller calls .purge on the attachment if the flag is true AND no new file provided.


=== 6.10 Public Portfolio Page (3 Modes) ===

Routes:
  Private (owner):  GET /portfolio               ->  portfolio#index       (auth required)
  Public (shared):  GET /:user_hash/portfolio    ->  portfolio#public_index (NO auth)

Files:
  app/views/portfolio/index.html.erb    (main file - fully self-contained HTML document)
  app/views/portfolio/_nav.html.erb     (navigation bar partial)
  app/views/portfolio/_classic.html.erb
  app/views/portfolio/_raw.html.erb
  app/views/portfolio/_creative.html.erb

The portfolio page has THREE visual modes selectable via a pill slider in the nav.
Mode is persisted in localStorage["portfolio_view_mode"].

-- CLASSIC MODE --
  Masonry CSS grid: 2 columns -> 3 columns -> 4 columns (responsive breakpoints)
  Art cards: hover reveals overlay with title / medium / status
  Hero section: artist name, discipline label, artwork stats, artist statement
  About section: achievements list
  Classic footer: three-column grid

-- STUDIO (RAW) MODE --
  Full black-and-white aesthetic
  Full-viewport hero with cover_image (CSS filter: grayscale + brightness)
  Animated hero name: clip-path reveal from right on page load
  Bento grid: varied column spans via nth-child selectors (7+5, 4+4+4, 12 span full)
  Ticker/marquee strip of text between hero and grid
  Custom dot cursor on desktop (mix-blend-mode: difference)
  Scroll-driven parallax on hero name (translateY based on window.scrollY)
  Hover: grayscale filter lifts on artwork images (filter: grayscale(0))

-- REEL (CREATIVE) MODE --
  Full-screen horizontal drag/swipe slider
  Infinite looping: on init, original slides are cloned and prepended+appended
  Physics-based easing: currentScroll += (targetScroll - currentScroll) * 0.08
  requestAnimationFrame loop for smooth rendering
  Progress bar at bottom showing relative position through the slide loop
  Touch drag support (touchstart, touchmove)

-- MODE SWITCHING MECHANISM --
  All three modes share the EXACT same HTML structure.
  CSS classes on <body> control what is visible and invisible:
    body.raw .classic-hero { display: none !important; }
    .raw-mode { display: none; }
    body.raw .raw-mode { display: block; }

  JavaScript:
    function applyMode(mode, animate) {
      document.body.classList.remove("raw", "creative", "raw-loaded", "creative-loaded");
      if (mode === "raw") document.body.classList.add("raw");
      if (mode === "creative") document.body.classList.add("creative");
      // raw-loaded and creative-loaded added in setTimeout to trigger CSS transitions
    }

-- SHARE BUTTON (in portfolio nav) --
  HTML: <a data-share-url="<%= public_portfolio_url(@user.user_hash) %>" ...>Share</a>
  The public URL is baked server-side into data-share-url.
  JS logic:
    - If navigator.share is available (mobile / Chrome 89+): uses native share sheet
    - Otherwise: navigator.clipboard.writeText(url), button briefly shows "Copied!"

-- TAG FILTERING IN PORTFOLIO --
  Tags pre-rendered as <a href="?tag=name"> links in the DOM.
  Vanilla JS dropdown filters by input value client-side (no server request for filtering).
  Clicking a tag navigates to portfolio_path(tag: name) for server-side artwork filtering.


=== 6.11 Portfolio Share Link (user_hash) ===

PROBLEM BEING SOLVED
  The /portfolio route requires the viewer to be logged in as the owner.
  We need a public, shareable URL that works for anyone.

SOLUTION
  Each User record has a unique user_hash column.
  Sharing /:user_hash/portfolio lets anyone view that user's public portfolio with no login.

COLUMN SPECS
  Column name: user_hash
  DB type:     string, NOT NULL, UNIQUE (index: index_users_on_user_hash)
  Format:      10 characters, alphanumeric only [a-z A-Z 0-9]
  Set:         on before_create callback in User model

GENERATION CODE (app/models/user.rb)
  before_create :generate_user_hash

  def generate_user_hash
    charset = [*'a'..'z', *'A'..'Z', *'0'..'9']   # 62 possible characters
    loop do
      self.user_hash = Array.new(10) { charset.sample }.join
      break unless User.exists?(user_hash: user_hash)
    end
  end

  Collision-safe due to the loop.
  62^10 = ~839 trillion possible combinations.

ROUTES
  get "/:user_hash/portfolio",       to: "portfolio#public_index", as: :public_portfolio
  get "/:user_hash/portfolio/:slug", to: "portfolio#public_show",  as: :public_portfolio_artwork

  IMPORTANT: /:user_hash is a top-level wildcard segment.
  It MUST be placed AFTER all other fixed-path routes in routes.rb.
  Otherwise routes like /credits, /profile/edit would be swallowed by the wildcard.

CONTROLLER LOOKUP (app/controllers/portfolio_controller.rb)
  def public_index
    @user = User.find_by(user_hash: params[:user_hash])
    return render plain: "Portfolio not found.", status: :not_found unless @user

    load_artworks   # scoped to @user.artworks.publicly_visible
    load_tags       # scoped to @user's public artworks
    render :index   # renders same index.html.erb as the private /portfolio route
  end

EXAMPLE URLS
  http://127.0.0.1:3000/aB3kZ9xQmR/portfolio
  http://127.0.0.1:3000/aB3kZ9xQmR/portfolio/sunset-over-the-hills

MIGRATION HISTORY FOR THIS FEATURE
  20260816000000 add_portfolio_token_to_users.rb
    - Added portfolio_token column (32-char hex at the time)
    - Back-filled all existing users with a unique hex token

  20260816010000 rename_portfolio_token_to_user_hash.rb
    - Renamed column portfolio_token -> user_hash
    - Dropped old index defensively (checking if exists first) and added new index

  20260816010100 regenerate_user_hashes_to_ten_chars.rb
    - Re-generated all existing user hashes to 10-char alphanumeric format

---

## 7. Routing Map

GET    /                                   home#index              (auth required)
GET    /analytics                          home#analytics          (auth required)
GET    /credits                            home#credits            (public)

GET    /artworks                           artworks#index          (auth required)
GET    /artworks/new                       artworks#new            (auth required)
POST   /artworks                           artworks#create         (auth required)
GET    /artworks/catalogue                 artworks#catalogue      (auth required) -> PDF
GET    /artworks/:slug                     artworks#show           (auth required)
GET    /artworks/:slug/edit                artworks#edit           (auth required)
PATCH  /artworks/:slug                     artworks#update         (auth required)
DELETE /artworks/:slug                     artworks#destroy        (auth required)

POST   /artworks/:artwork_slug/letters     studio_notes#create     (auth required)
DELETE /letters/:id                        studio_notes#destroy    (auth required, shallow)

GET    /portfolio                          portfolio#index         (auth required - owner view)
GET    /portfolio/:slug                    portfolio#show          (auth required)

GET    /:user_hash/portfolio               portfolio#public_index  (PUBLIC - no auth)
GET    /:user_hash/portfolio/:slug         portfolio#public_show   (PUBLIC - no auth)

GET    /profile/edit                       profile#edit            (auth required)
PATCH  /profile                            profile#update          (auth required)

Devise routes (auto-generated):
  GET    /users/sign_in
  POST   /users/sign_in
  DELETE /users/sign_out
  GET    /users/sign_up
  POST   /users
  GET    /users/password/new
  POST   /users/password
  GET    /users/password/edit
  PATCH  /users/password

---

## 8. Key Implementation Details

DATA SCOPING - THE SECURITY BOUNDARY
  Every private controller query starts from current_user.artworks.
  This prevents any user from accessing another user's data.

    CORRECT:  @artwork = current_user.artworks.find_by!(slug: params[:slug])
    WRONG:    @artwork = Artwork.find_by(slug: params[:slug])   <- never do this

PUBLIC PORTFOLIO DATA ISOLATION
  Uses the publicly_visible scope defined in Artwork model:
    scope :publicly_visible, -> { where(is_public: true) }
  Public controller: @artworks = @user.artworks.publicly_visible

PORTFOLIO USES layout: false
  PortfolioController sets layout false.
  portfolio/index.html.erb is a FULLY STANDALONE HTML document.
  It has its own <!DOCTYPE html>, <head>, Google Fonts links, and all CSS/JS.
  It does NOT inherit from or wrap inside application.html.erb.
  This is intentional so the public portfolio is a clean, self-contained shareable page.

PAGY PAGINATION
  Pagy::Backend included in ApplicationController.
  Usage:   @pagy, @artworks = pagy(@artworks, limit: 12)
  View:    render the pagy nav helper with @pagy instance

ACTIVE STORAGE + IMAGE METADATA
  The image_processing gem (included in Gemfile) stores image width and height in
  active_storage_blobs.metadata after upload.
  The PDF generator reads blob.metadata["width"] and blob.metadata["height"] to determine
  whether each artwork image is landscape or portrait - without decoding image bytes.

VIEW ON WALL - BROWSER MEMORY ONLY
  The "Upload ur wall" feature uses URL.createObjectURL(file) on the browser-selected File.
  The resulting blob URL is used as the image src for the wall background.
  The file is NEVER included in any HTTP request to the server.
  The blob URL is garbage collected automatically when the tab navigates or the session ends.

TURBO DELETE
  Studio note deletion:
    link_to "Remove", studio_note_path(note),
      data: { turbo_method: :delete, turbo_confirm: "Remove this letter?" }
  Turbo Drive intercepts the click and issues a DELETE request, replacing the page
  with the server response without a full browser navigation.

RANSACK SECURITY - ransackable_attributes
  Ransack will only search columns explicitly listed in self.ransackable_attributes in the model.
  This is a security requirement (prevents arbitrary column enumeration attacks).
  Currently searchable in Artwork: title, medium, year_created, description, status
  To make a new column searchable, add it to ransackable_attributes in artwork.rb.

TAG NORMALIZATION IS APPLIED TWICE
  1. In Tag model (before_save): normalizes the name when the Tag record is saved
  2. In ArtworksController#save_tags: normalizes names from tag_list param before lookup
  Both locations must stay consistent to prevent duplicate tags with different formats.

DEVISE TIMEOUTABLE
  Session timeout configured via: config.timeout_in in config/initializers/devise.rb
  Default Devise timeout: 30 minutes of inactivity.
  After timeout, user is redirected to sign-in page.

---

## 9. File Structure Reference

app/
  controllers/
    application_controller.rb     Pagy::Backend inclusion, layout_by_resource helper
    artworks_controller.rb        Full CRUD + Ransack search + PDF generation (265 lines)
    home_controller.rb            Dashboard (index) + analytics action
    portfolio_controller.rb       Private + public portfolio views, shared helpers
    profile_controller.rb         Profile edit (name, avatar, cover, etc.)
    studio_notes_controller.rb    Create + destroy for Letters to Future Me
  models/
    user.rb                       Devise config + user_hash auto-generation callback
    artwork.rb                    Slug generation, status enum, scopes, validations
    tag.rb                        Name normalization, ransackable_attributes
    artwork_tag.rb                Join table model (has_many :through)
    studio_note.rb                belongs_to :artwork, written_on date
    artwork_location.rb           Location tracking per artwork
  views/
    artworks/
      show.html.erb               Detail page: image lightbox + full View on Wall modal
      index.html.erb              Artwork grid with Ransack search and filters
      _form.html.erb              Shared form partial (create + edit)
      new.html.erb                Wraps _form for creation
      edit.html.erb               Wraps _form for editing
    portfolio/
      index.html.erb              Full portfolio page (self-contained HTML, 820+ lines)
                                  Contains all 3 modes + switching JS + mode CSS
      show.html.erb               Individual public artwork view (3 mode partials)
      _nav.html.erb               Nav bar: name, links, tag search, Share, Enquire, mode slider
      _classic.html.erb           Classic masonry grid mode content
      _raw.html.erb               Studio/raw b&w mode content
      _creative.html.erb          Reel creative slider mode content
      _show_classic.html.erb      Classic artwork detail sub-partial
      _show_raw.html.erb          Raw artwork detail sub-partial
      _show_creative.html.erb     Creative artwork detail sub-partial
    home/
      index.html.erb              Dashboard: stats, recent artworks, this day in studio
      analytics.html.erb          Analytics: counts, charts, breakdowns
      credits.html.erb            Credits page
    profile/
      edit.html.erb               Profile edit form with avatar/cover upload + removal
    layouts/
      application.html.erb        Main app layout (used by all private pages)
    devise/
      (customized Devise views for sign_in, sign_up, etc.)

config/
  routes.rb                       All route definitions
  initializers/
    devise.rb                     Session timeout, mailer, Devise module config

db/
  schema.rb                       Canonical source of truth for current DB structure
  migrate/
    20260510175716_devise_create_users.rb
    20260510175900_create_artworks.rb
    20260510180015_create_artwork_locations.rb
    20260510180023_create_studio_notes.rb
    20260510185655_create_active_storage_tables.rb
    20260516030703_add_name_to_users.rb
    20260516030918_add_profile_to_users.rb
    20260519072302_create_tags.rb
    20260519072307_create_artwork_tags.rb
    20260707200950_add_achievements_to_users.rb
    20260816000000_add_portfolio_token_to_users.rb
    20260816010000_rename_portfolio_token_to_user_hash.rb
    20260816010100_regenerate_user_hashes_to_ten_chars.rb

---

## 10. Environment & Dependencies

KEY GEMS (production-critical)

Gem                   | Purpose
----------------------|---------------------------------------------------------
devise                | Authentication: login, registration, password reset, timeout
pagy ~> 9.0           | Pagination - lightweight and fast
ransack               | Search and sort for the artwork index
prawn                 | PDF generation engine
prawn-table           | Table rendering in Prawn PDFs
prawn-svg             | SVG support in Prawn PDFs
image_processing ~> 1.2 | Active Storage image transforms + metadata extraction
pg ~> 1.5             | PostgreSQL adapter
tailwindcss-rails     | Tailwind CSS build integration
turbo-rails           | Hotwire Turbo for SPA-like navigation
stimulus-rails        | Hotwire Stimulus JS controller framework
solid_queue           | Background job processing (DB-backed)
solid_cache           | DB-backed caching
dotenv-rails ~> 3.2   | .env file loading for environment variables
kamal                 | Docker-based deployment tool

ENVIRONMENT VARIABLES (.env file)

  DATABASE_URL or DB_PASSWORD    PostgreSQL connection credentials
  SECRET_KEY_BASE                Rails session secret
  RAILS_MASTER_KEY               Key for config/credentials.yml.enc decryption
  (Cloud storage keys if using S3/GCS in production instead of local disk)

RUNNING THE APP LOCALLY

  bundle install                 Install Ruby gem dependencies
  bin/rails db:create            Create the PostgreSQL databases
  bin/rails db:migrate           Run all pending migrations
  bin/dev                        Start Puma + Tailwind CSS watcher (via Foreman, Procfile.dev)

DEVELOPMENT TOOLS

  brakeman                       Static security analysis
  bundler-audit                  Gem vulnerability scanning
  rubocop-rails-omakase          Code style enforcement
  web-console                    In-browser Rails console on error pages

---

## 11. Migration History

Migration file                                  | Date       | Description
------------------------------------------------|------------|---------------------------------------------
devise_create_users                             | 2026-05-10 | Base users table with all Devise columns
create_artworks                                 | 2026-05-10 | Artworks: title, slug, status enum, is_public
create_artwork_locations                        | 2026-05-10 | Location history per artwork
create_studio_notes                             | 2026-05-10 | Private journal notes per artwork
create_active_storage_tables                    | 2026-05-10 | Rails Active Storage infrastructure tables
add_name_to_users                               | 2026-05-16 | Display name column
add_profile_to_users                            | 2026-05-16 | artist_statement, contact_email columns
create_tags                                     | 2026-05-19 | Global normalized tags table
create_artwork_tags                             | 2026-05-19 | Join table: artwork_id + tag_id
add_achievements_to_users                       | 2026-07-07 | Achievements text column
add_portfolio_token_to_users                    | 2026-08-16 | Adds portfolio_token (32-char hex), back-fills existing users
rename_portfolio_token_to_user_hash             | 2026-08-16 | Renames column to user_hash; fixes index defensively
regenerate_user_hashes_to_ten_chars             | 2026-08-16 | Re-generates all user hashes to 10-char alphanumeric

---

## 12. Known Gotchas & Notes

ROUTE ORDERING: /:user_hash/portfolio IS A TOP-LEVEL WILDCARD
  The /:user_hash/portfolio route uses a dynamic segment at the top level of the URL.
  If this route is placed BEFORE any fixed routes like /credits, /profile/edit,
  those fixed paths will be incorrectly captured by the wildcard.
  ALWAYS keep this route near the bottom of routes.rb, after all fixed-path routes.

USER_HASH MUST NEVER BE REGENERATED
  The user_hash is used in shared links. If it changes, all previously shared links break.
  There is intentionally no UI to regenerate the user_hash.
  Treat it as a permanent identifier for the user's public portfolio.

ARTWORK SLUGS ARE PERMANENT
  Slugs are generated only on: :create. Renaming an artwork title does NOT change its slug.
  This is intentional to preserve stability of bookmarked or shared artwork URLs.
  If slug regeneration on edit is ever needed, it must be implemented carefully.

PDF GENERATION DOWNLOADS IMAGE BLOBS INTO MEMORY
  artwork.images.first.download streams image bytes from Active Storage into memory.
  For users with many artworks or very large images, this can be slow and memory-intensive.
  In production with S3 storage, the app server must have network access to the S3 bucket.
  Consider adding a background job for PDF generation if performance becomes an issue.

TAG NORMALIZATION IS APPLIED IN TWO PLACES
  Both the Tag model (before_save) and ArtworksController#save_tags normalize tag names.
  If the normalization logic ever changes, it must be updated in BOTH locations consistently.
  Failing to do so can result in duplicate tags with slightly different formats in the DB.

PORTFOLIO CONTROLLER USES layout: false
  PortfolioController sets layout false at the top of the class.
  The portfolio view is a self-contained HTML document.
  If you ever need to add a flash message or a shared nav to the portfolio page,
  you cannot use the application layout. You must add it directly to portfolio/index.html.erb.

VIEW ON WALL - BROWSER COMPATIBILITY NOTES
  <dialog> element and showModal():
    Chrome 37+, Firefox 98+, Safari 15.4+, Edge 79+. Good modern browser coverage.
  URL.createObjectURL():
    Supported in all modern browsers without issue.
  Web Share API (navigator.share):
    Supported on most mobile browsers and Chrome 89+ on desktop.
    The clipboard fallback (navigator.clipboard.writeText) handles all other browsers.
    The alert() fallback handles the rare case where clipboard API is also unavailable.

RANSACK: ransackable_attributes IS A SECURITY REQUIREMENT
  Ransack will REFUSE to search any attribute not explicitly listed in the model's
  self.ransackable_attributes method. This is intentional security behavior.
  If you add a new column to artworks that should be searchable, add it to this method.
  Current searchable attributes: title, medium, year_created, description, status

DEVISE TIMEOUTABLE - SESSION EXPIRY
  The session timeout duration is set via config.timeout_in in devise.rb initializer.
  The default if not set is around 30 minutes of inactivity.
  After expiry, the next request redirects the user to the sign-in page.
  This affects only the private routes; public portfolio routes have no session requirement.

TAGS ARE GLOBAL IN THE DATABASE
  The tags table contains tags from ALL users, not per-user tags.
  This means if two users both use the tag "portrait", they share the same Tag record.
  This is fine because all tag-to-artwork associations go through artwork_tags,
  and all artwork queries are scoped to a specific user's artworks.
  The public portfolio tag filter: @all_tags is scoped via:
    Tag.joins(:artworks).where(artworks: { user_id: @user.id, is_public: true })
  So users only see their own tags in their portfolio even though tags are global.
