puts "Setting up artist account..."
user = User.find_or_initialize_by(email: "aadisha@gmail.com")
user.name = "Aadisha"
user.artist_statement = "As an artist, I explore the intersection of light, emotion, and the natural world. My work is an ongoing dialogue with my surroundings, aiming to capture the ephemeral moments of beauty in everyday life. Through my paintings, I invite the viewer to pause, reflect, and find their own narrative within the textures and colors on the canvas."
if user.new_record?
  user.password = "changeme123"
  user.password_confirmation = "changeme123"
end
user.save!

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

if user.artworks.none?
  puts "Creating starter artworks..."
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
else
  puts "Artworks already exist, skipping."
end

puts "\nDone! #{user.artworks.count} artworks total."
puts "Login: #{user.email} / changeme123 (if newly created)"