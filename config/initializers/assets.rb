# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# svg-edit and MathJax are vendored as static asset trees referenced via
# `asset_path`. Rails 5's sprockets-rails 3.x raises AssetNotPrecompiled
# for asset_path lookups outside the precompile list, so list them here.
# Only the svg-edit asset is referenced via `asset_path` and lives in the
# pipeline (vendor/assets/javascripts/). MathJax and favicon.ico are
# served as static files from public/ and use `skip_pipeline: true` at
# their callsites in the layout.
Rails.application.config.assets.precompile += %w[
  svg-edit/editor/svg-editor.html
]
