# ZigBlog ⚡

A blazingly fast blog application built entirely with **Zig** using only the standard library.

## Features

- 🚀 **Zero startup time** - Compiled to native machine code
- 📦 **Single binary** - No runtime dependencies (~1.3MB)
- 🔒 **Memory safe** - Zig's compile-time safety checks
- ⚡ **Fast** - Handles connections efficiently
- 🎨 **Beautiful UI** - Modern dark theme with smooth animations
- 🛠️ **Zero dependencies** - Uses only Zig's standard library

## Tech Stack

- **Zig 0.15** - Systems programming language
- **std.net** - Built-in networking primitives
- **Comptime templates** - Zero-cost HTML templating

## Project Structure

```
blog-app/
├── build.zig           # Build configuration
├── build.zig.zon       # Package manifest
├── src/
│   ├── main.zig        # Entry point & HTTP server
│   ├── models/
│   │   └── post.zig    # Blog post data model
│   ├── templates/
│   │   └── html.zig    # HTML templates
│   └── static/
│       └── css/
│           └── style.css
└── README.md
```

## Getting Started

### Prerequisites

- Zig 0.15.0 or later

### Build & Run

```bash
# Navigate to project directory
cd blog-app

# Build and run
zig build run

# Or just build
zig build

# Run the binary directly
./zig-out/bin/blog-app
```

### Access the Blog

Open your browser and navigate to:

- **Home**: http://localhost:8080
- **Posts**: http://localhost:8080/posts
- **About**: http://localhost:8080/about
- **Individual Post**: http://localhost:8080/posts/welcome-to-zig-blog

## Routes

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Home page with featured posts |
| GET | `/posts` | List all blog posts |
| GET | `/posts/:slug` | View individual post |
| GET | `/about` | About page |
| GET | `/static/css/style.css` | Stylesheet |

## Customization

### Adding New Posts

Edit `src/main.zig` and add posts using `store.addPost()`:

```zig
try store.addPost(.{
    .title = "Your Post Title",
    .slug = "your-post-slug",
    .excerpt = "A brief description...",
    .content = "<h1>Your Content</h1><p>In HTML format...</p>",
    .author = "Your Name",
    .created_at = "2026-01-05",
});
```

### Styling

Modify `src/static/css/style.css` to customize the appearance. The theme uses CSS variables for easy customization:

```css
:root {
    --accent-primary: #f7a41d;  /* Zig orange */
    --bg-primary: #0a0a0f;      /* Dark background */
    /* ... */
}
```

## Performance

- **Binary size**: ~1.3MB
- **Memory usage**: <5MB
- **Startup time**: Instant
- **Zero dependencies**: Only uses Zig standard library

## How It Works

The blog server is a simple HTTP server built with `std.net`:

1. Listens on port 8080 for TCP connections
2. Parses incoming HTTP requests manually
3. Routes requests to appropriate handlers
4. Generates HTML responses using comptime string concatenation
5. Serves static CSS embedded in the binary

## License

MIT License - Feel free to use this as a starting point for your own projects!

---

Built with ❤️ and **Zig 0.15**
