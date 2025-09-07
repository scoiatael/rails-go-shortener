json.extract! shortened_url, :id, :target, :slug, :created_at, :updated_at
json.url shortened_url_url(shortened_url, format: :json)
