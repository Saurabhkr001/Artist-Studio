puts "Clearing existing data..."
StudioNote.destroy_all
ArtworkLocation.destroy_all
Artwork.destroy_all
User.destroy_all

puts "Creating artist account..."
user = User.create!(
  name: "Aadisha",
  email: "aadisha@gmail.com",    # ← replace with his real email
  password: "123456789",                # ← he changes this on first login
  password_confirmation: "changeme123",
  artist_statement: "As an artist, I explore the intersection of light, emotion, and the natural world. My work is an ongoing dialogue with my surroundings, aiming to capture the ephemeral moments of beauty in everyday life. Through my paintings, I invite the viewer to pause, reflect, and find their own narrative within the textures and colors on the canvas."
)

puts "Creating artworks..."

artworks = [
  {
    title: "Painting One",
    medium: "Oil on canvas",
    dimensions_cm: "60 × 80",
    year_created: 2023,
    painted_on: Date.new(2023, 3, 15),
    description: "Add description here.",
    status: :available,
    is_public: true
  },
  {
    title: "Painting Two",
    medium: "Acrylic on board",
    dimensions_cm: "40 × 50",
    year_created: 2022,
    painted_on: Date.new(2022, 7, 10),
    description: "Add description here.",
    status: :sold,
    is_public: true
  },
  {
    title: "Painting Three",
    medium: "Watercolour",
    dimensions_cm: "30 × 40",
    year_created: 2024,
    painted_on: Date.new(2024, 1, 20),
    description: "Add description here.",
    status: :in_progress,
    is_public: false
  }
  # Add more here — copy the block above for each painting
]

artworks.each do |attrs|
  artwork = user.artworks.new(attrs)
  # Images: attach like this once you have files ready:
  # artwork.images.attach(
  #   io: File.open(Rails.root.join("db/seeds/images/painting_one.jpg")),
  #   filename: "painting_one.jpg",
  #   content_type: "image/jpeg"
  # )
  artwork.save!
  puts "  ✓ #{artwork.title}"
end

puts "\nDone! #{Artwork.count} artworks created."
puts "Login: #{user.email} / changeme123"
